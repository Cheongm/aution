%RUN_DEMO Main entry point to simulate RIPP-DR and TQDO schedulers.
%   This script generates a reproducible user population and executes both
%   algorithms over T slots, storing per-slot KPIs, plots, and CSV exports.

rng(42, 'twister');

Config = struct();
Config.T = 50;                    % number of slots
Config.num_users = 25;            % total users (RT + NRT)
Config.Slot.duration_s = 0.01;    % slot duration [s] used for reporting

% Output configuration
Config.Output.dir = fullfile(pwd, 'matlab');

% Radio front-haul parameters
Config.Radio.P_tx_W = 5;                  % transmit power [W]
Config.Radio.interference_W = 1e-9;       % aggregate interference [W]
Config.Noise.N0_W_Hz = 1e-20;             % noise PSD [W/Hz]
Config.Radio.channel_scale = 1.0;         % Rayleigh scale for |h|

% Backhaul latency threshold and baseline
Config.Network.bh_latency_mean_s = 2e-3;  % mean RU->DU+DU->CU latency [s]
Config.Network.bh_latency_jitter_s = 0.5e-3; % jitter around the mean [s]
Config.Gamma_bh = 5e-3;                   % admissible threshold [s]

% Resource capacities (per slot)
Config.Capacity.RU_Hz = 20e6;             % RU bandwidth [Hz]
Config.Capacity.DU_cycles = 6e11;         % DU compute budget [cycles/s]
Config.Capacity.CU_cycles = 8e11;         % CU compute budget [cycles/s]

% Reserve ratios for RIPP-DR
Config.Reserve.rho_rt = struct('RU', 0.10, 'DU', 0.15, 'CU', 0.15);

% Token policy for TQDO
Config.Token.rt_fraction = struct('RU', 0.12, 'DU', 0.18, 'CU', 0.18);
Config.Token.allow_buyback = true;
Config.Token.downgrade_weight = 0.5;

% Search grid for minimal RT bundle
Config.Search.bandwidths_Hz = [2e6, 4e6, 6e6, 8e6, 10e6];
Config.Search.du_rates = [1e10, 2e10, 3e10, 4e10];
Config.Search.cu_rates = [0, 5e9, 1e10, 2e10];
Config.Search.weight_bandwidth = 1.0;
Config.Search.weight_du = 0.6;
Config.Search.weight_cu = 0.6;

% Pricing (currency per native unit)
Config.Prices.ru = 2e-6;
Config.Prices.du = 5e-12;
Config.Prices.cu = 7e-12;

% User population settings
Config.Users.rt_fraction = 0.4;
Config.Users.d_bits_rt_range = [0.8e6, 2.0e6];      % [bit]
Config.Users.d_bits_nrt_range = [1.0e6, 4.0e6];     % [bit]
Config.Users.f_req_rt_range = [4e9, 1.2e10];        % [cycles]
Config.Users.f_req_nrt_range = [6e9, 2.5e10];       % [cycles]
Config.Users.deadline_range = [5e-3, 1.2e-2];       % [s]
Config.Users.tiers = [1, 1.5, 2];                   % subscription multiplier
Config.Users.theta_rt = [0.8, 0.2];                 % DU-first split
Config.Users.theta_nrt = [0.6, 0.4];
Config.Users.parallel_rt = false;
Config.Users.parallel_nrt = true;

users = gen_users(Config.num_users, Config);

slots = (1:Config.T)';
ripp_results(Config.T,1) = struct();
tqdo_results(Config.T,1) = struct();

for t = 1:Config.T
    u_rand = max(rand(Config.num_users, 1), realmin);
    h = Config.Radio.channel_scale * sqrt(-2 * log(u_rand));
    capacities = struct('ru_Hz', Config.Capacity.RU_Hz, ...
                        'du_cycles', Config.Capacity.DU_cycles, ...
                        'cu_cycles', Config.Capacity.CU_cycles);
    prices = Config.Prices;
    bh_latency = max(Config.Network.bh_latency_mean_s + ...
        Config.Network.bh_latency_jitter_s * (rand() - 0.5), 0);

    slot_info = struct('channel_gains', h, ...
        'capacities', capacities, ...
        'prices', prices, ...
        'bh_latency_s', bh_latency);

    ripp_results(t) = ripp_dr_slot(users, Config, slot_info);
    tqdo_results(t) = tqdo_slot(users, Config, slot_info);
end

plot_results(Config, slots, ripp_results, tqdo_results);

save_csv(fullfile(Config.Output.dir, 'ripp_dr_results.csv'), slots, ripp_results);
save_csv(fullfile(Config.Output.dir, 'tqdo_results.csv'), slots, tqdo_results);

disp('Simulation complete. Results saved to PNG and CSV files.');
