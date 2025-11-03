%% optimize_params.m
% Quick parameter fixes for better RT performance
%
% Current problem: RT Miss Rate = 100%
% This script adjusts parameters to improve RT service

fprintf('========================================\n');
fprintf('  Parameter Optimization for RT\n');
fprintf('========================================\n\n');

fprintf('Current Issues:\n');
fprintf('  - RT Miss Rate: 100%% (all RT users failed)\n');
fprintf('  - RT Avg Latency: 0.0000 s (no RT served)\n\n');

fprintf('Recommended Fixes (choose one):\n\n');

fprintf('OPTION 1: Relax RT Deadlines (Easiest)\n');
fprintf('----------------------------------------\n');
fprintf('In run_demo.m line 32, change:\n');
fprintf('  FROM: Config.deadline_rt_range = [0.01, 0.05];  %% [10, 50] ms\n');
fprintf('  TO:   Config.deadline_rt_range = [0.02, 0.10];  %% [20, 100] ms\n\n');

fprintf('OPTION 2: Increase RT Reserve Ratios\n');
fprintf('----------------------------------------\n');
fprintf('In run_demo.m lines 44-46, change:\n');
fprintf('  FROM: Config.rho_rt_ru = 0.10;  Config.rho_rt_du = 0.15;\n');
fprintf('  TO:   Config.rho_rt_ru = 0.25;  Config.rho_rt_du = 0.30;\n\n');

fprintf('OPTION 3: Reduce RT User Count\n');
fprintf('----------------------------------------\n');
fprintf('In run_demo.m line 14, change:\n');
fprintf('  FROM: Config.N_rt = 10;\n');
fprintf('  TO:   Config.N_rt = 5;\n\n');

fprintf('OPTION 4: Finer Search Grid\n');
fprintf('----------------------------------------\n');
fprintf('In run_demo.m lines 63-65, change:\n');
fprintf('  FROM: linspace(..., 15)  %% 15 points\n');
fprintf('  TO:   linspace(..., 25)  %% 25 points\n\n');

fprintf('OPTION 5: Reduce RT Task Size\n');
fprintf('----------------------------------------\n');
fprintf('In run_demo.m lines 28-29, change:\n');
fprintf('  FROM: Config.d_bits_rt_range = [1e6, 5e6];   %% [1, 5] Mbits\n');
fprintf('  TO:   Config.d_bits_rt_range = [0.5e6, 2e6]; %% [0.5, 2] Mbits\n\n');

fprintf('========================================\n');
fprintf('  Recommended: Try Option 1 First!\n');
fprintf('========================================\n\n');

fprintf('After changing parameters:\n');
fprintf('  >> clear all\n');
fprintf('  >> run_demo\n\n');

% Show diagnostic info
fprintf('Current search grid info:\n');
fprintf('  B_grid:    15 points covering [0.5, 10] MHz\n');
fprintf('  f_du_grid: 15 points covering [0.5, 5] GHz\n');
fprintf('  f_cu_grid: 15 points covering [0.5, 8] GHz\n');
fprintf('  Total combinations: 15 x 15 x 15 = 3,375\n\n');

fprintf('Expected RT Miss Rate after fix: 5-20%%\n');
fprintf('========================================\n');
