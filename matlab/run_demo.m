%% run_demo.m
% Main simulation script for wireless network with RIPP-DR and TQDO algorithms
%
% Generates users, runs T time slots, compares two algorithms:
% - RIPP-DR: Reputation-Indexed Posted-Price with Deadlines & Reservations
% - TQDO: Token-SLA with Dual-Queue Deterministic Orchestrator
%
% Outputs:
% - Three PNG plots: miss_rt.png, util.png, cost.png
% - Two CSV files: ripp_dr_results.csv, tqdo_results.csv

clear; close all; clc;

%% Fixed Random Seed for Reproducibility
rng(42, 'twister');

%% Configuration Parameters
Config = struct();

% ========== Simulation Parameters ==========
Config.T = 50;  % Number of time slots
Config.N_rt = 10;   % Number of RT users
Config.N_nrt = 15;  % Number of NRT users

% ========== Physical Layer Parameters ==========
Config.P = 1.0;           % Transmit power [W]
Config.N0 = 1e-9;         % Noise PSD [W/Hz]
Config.t_bh = 0.002;      % Backhaul/midhaul latency [s] (2 ms)
Config.Gamma_bh = 0.005;  % Backhaul threshold [s] (5 ms)

% ========== Resource Capacity (per slot) ==========
Config.C_ru = 20e6;       % RU capacity [Hz] (20 MHz)
Config.C_du = 10e9;       % DU capacity [cycles/s] (10 GHz)
Config.C_cu = 20e9;       % CU capacity [cycles/s] (20 GHz)

% ========== User Traffic Parameters ==========
% RT users: smaller tasks, tight deadlines
Config.d_bits_rt_range = [1e6, 5e6];        % [1, 5] Mbits
Config.f_req_rt_range = [1e8, 5e8];         % [100, 500] Mcycles
Config.deadline_rt_range = [0.01, 0.05];    % [10, 50] ms

% NRT users: larger tasks, no deadlines
Config.d_bits_nrt_range = [5e6, 20e6];      % [5, 20] Mbits
Config.f_req_nrt_range = [5e8, 2e9];        % [500, 2000] Mcycles

% Channel gain range (log-normal fading, dimensionless)
Config.channel_gain_range = [0.1, 1.0];

% ========== Pricing Parameters ==========
Config.price_ru = 1e-6;   % [currency/Hz] 
Config.price_du = 5e-10;  % [currency/(cycles/s)]
Config.price_cu = 3e-10;  % [currency/(cycles/s)]

% ========== RIPP-DR Parameters ==========
% RT reserve ratios (default from paper)
Config.rho_rt_ru = 0.10;  % 10% reserved for RT
Config.rho_rt_du = 0.15;  % 15% reserved for RT
Config.rho_rt_cu = 0.15;  % 15% reserved for RT

% ========== TQDO Parameters ==========
% Token ratios (similar to RIPP-DR reserves)
Config.token_rt_ru = 0.10;
Config.token_rt_du = 0.15;
Config.token_rt_cu = 0.15;

% Buyback parameters
Config.allow_buyback = true;
Config.buyback_threshold = 10;  % Max buyback cost [currency]

% ========== Processing Mode ==========
Config.latency_mode = 'parallel';  % 'serial' or 'parallel'

% ========== Search Configuration for Minimal Bundle ==========
% Create search grids (coarse for efficiency)
Config.search_config.B_grid = linspace(0.5e6, 10e6, 15);     % [0.5, 10] MHz
Config.search_config.f_du_grid = linspace(0.5e9, 5e9, 15);   % [0.5, 5] GHz
Config.search_config.f_cu_grid = linspace(0.5e9, 8e9, 15);   % [0.5, 8] GHz

%% Generate Users
fprintf('===== Wireless Network Simulation =====\n');
fprintf('Generating users...\n');
users = gen_users(Config.N_rt, Config.N_nrt, Config);
fprintf('Generated %d RT users and %d NRT users.\n', Config.N_rt, Config.N_nrt);

%% Initialize Results Storage
results_ripp = cell(Config.T, 1);
results_tqdo = cell(Config.T, 1);

%% Run Time-Slot Simulation
fprintf('\nRunning simulation for %d time slots...\n', Config.T);

for t = 1:Config.T
    if mod(t, 10) == 0
        fprintf('  Slot %d/%d\n', t, Config.T);
    end
    
    % Update channel gains (time-varying)
    for u = 1:length(users)
        % Simple time-varying channel: add random fluctuation
        h_base = users(u).h;
        users(u).h = h_base * (0.8 + 0.4 * rand());  % ?20% variation
    end
    
    % Slot parameters
    slot_params = struct();
    slot_params.P = Config.P;
    slot_params.N0 = Config.N0;
    slot_params.t_bh = Config.t_bh;
    slot_params.Gamma_bh = Config.Gamma_bh;
    slot_params.prices.ru = Config.price_ru;
    slot_params.prices.du = Config.price_du;
    slot_params.prices.cu = Config.price_cu;
    
    %% Execute RIPP-DR Algorithm
    results_ripp{t} = ripp_dr_slot(users, Config, slot_params);
    
    %% Execute TQDO Algorithm
    results_tqdo{t} = tqdo_slot(users, Config, slot_params);
end

fprintf('Simulation completed.\n');

%% Compute Summary Statistics
fprintf('\n===== Summary Statistics =====\n');

% RIPP-DR
miss_rt_ripp = mean(cellfun(@(x) x.miss_rt, results_ripp));
avg_lat_ripp = mean(cellfun(@(x) x.avg_lat_rt, results_ripp));
avg_util_ru_ripp = mean(cellfun(@(x) x.util_ru, results_ripp));
avg_util_du_ripp = mean(cellfun(@(x) x.util_du, results_ripp));
avg_util_cu_ripp = mean(cellfun(@(x) x.util_cu, results_ripp));
avg_cost_ripp = mean(cellfun(@(x) x.cost_sp, results_ripp));
avg_jain_ripp = mean(cellfun(@(x) x.jain_nrt, results_ripp));

fprintf('RIPP-DR:\n');
fprintf('  RT Miss Rate:       %.2f%%\n', miss_rt_ripp * 100);
fprintf('  RT Avg Latency:     %.4f s\n', avg_lat_ripp);
fprintf('  RU Utilization:     %.2f%%\n', avg_util_ru_ripp * 100);
fprintf('  DU Utilization:     %.2f%%\n', avg_util_du_ripp * 100);
fprintf('  CU Utilization:     %.2f%%\n', avg_util_cu_ripp * 100);
fprintf('  Avg SP Cost:        %.4f currency/slot\n', avg_cost_ripp);
fprintf('  NRT Jain Index:     %.4f\n', avg_jain_ripp);

% TQDO
miss_rt_tqdo = mean(cellfun(@(x) x.miss_rt, results_tqdo));
avg_lat_tqdo = mean(cellfun(@(x) x.avg_lat_rt, results_tqdo));
avg_util_ru_tqdo = mean(cellfun(@(x) x.util_ru, results_tqdo));
avg_util_du_tqdo = mean(cellfun(@(x) x.util_du, results_tqdo));
avg_util_cu_tqdo = mean(cellfun(@(x) x.util_cu, results_tqdo));
avg_cost_tqdo = mean(cellfun(@(x) x.cost_sp, results_tqdo));
avg_jain_tqdo = mean(cellfun(@(x) x.jain_nrt, results_tqdo));

fprintf('\nTQDO:\n');
fprintf('  RT Miss Rate:       %.2f%%\n', miss_rt_tqdo * 100);
fprintf('  RT Avg Latency:     %.4f s\n', avg_lat_tqdo);
fprintf('  RU Utilization:     %.2f%%\n', avg_util_ru_tqdo * 100);
fprintf('  DU Utilization:     %.2f%%\n', avg_util_du_tqdo * 100);
fprintf('  CU Utilization:     %.2f%%\n', avg_util_cu_tqdo * 100);
fprintf('  Avg SP Cost:        %.4f currency/slot\n', avg_cost_tqdo);
fprintf('  NRT Jain Index:     %.4f\n', avg_jain_tqdo);

%% Generate Plots
fprintf('\n===== Generating Plots =====\n');
plot_results(results_ripp, results_tqdo, Config.T);

%% Save CSV Files
fprintf('\n===== Saving CSV Files =====\n');
save_csv(results_ripp, results_tqdo, Config.T);

fprintf('\n===== Simulation Complete =====\n');
fprintf('Outputs generated in current directory:\n');
fprintf('  - miss_rt.png\n');
fprintf('  - util.png\n');
fprintf('  - cost.png\n');
fprintf('  - ripp_dr_results.csv\n');
fprintf('  - tqdo_results.csv\n');
