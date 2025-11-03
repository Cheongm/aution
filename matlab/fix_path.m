%% fix_path.m
% Fix MATLAB path conflicts before running simulation
%
% This script ensures only the current directory functions are used

fprintf('========================================\n');
fprintf('  MATLAB Path Cleanup\n');
fprintf('========================================\n\n');

% Get current directory
current_dir = pwd;
fprintf('Current directory: %s\n\n', current_dir);

% List of functions to check
funcs = {'settle_cost', 'rate_uplink', 'total_latency', 'jain_index', ...
         'gen_users', 'minimal_bundle_rt', 'ripp_dr_slot', 'tqdo_slot', ...
         'plot_results', 'save_csv'};

conflicts_found = false;

fprintf('Checking for path conflicts...\n');
for i = 1:length(funcs)
    fname = funcs{i};
    locations = which(fname, '-all');
    
    if length(locations) > 1
        conflicts_found = true;
        fprintf('\n??  CONFLICT: %s found in multiple locations:\n', fname);
        for j = 1:length(locations)
            fprintf('   %d. %s\n', j, locations{j});
        end
    elseif length(locations) == 1
        if ~contains(locations{1}, current_dir)
            conflicts_found = true;
            fprintf('\n??  WARNING: %s found in different directory:\n', fname);
            fprintf('   Current: %s\n', current_dir);
            fprintf('   Found:   %s\n', locations{1});
        end
    end
end

if conflicts_found
    fprintf('\n========================================\n');
    fprintf('??  PATH CONFLICTS DETECTED!\n');
    fprintf('========================================\n\n');
    fprintf('SOLUTION 1: Clear conflicting paths\n');
    fprintf('Run this command to remove old paths:\n');
    fprintf('>> restoredefaultpath\n');
    fprintf('>> addpath(''%s'')\n', current_dir);
    fprintf('>> savepath\n\n');
    
    fprintf('SOLUTION 2: Run from correct directory\n');
    fprintf('Make sure you are in /workspace/matlab:\n');
    fprintf('>> cd /workspace/matlab\n');
    fprintf('>> run_demo\n\n');
    
    fprintf('SOLUTION 3: Use full path\n');
    fprintf('>> addpath(''%s'')\n', current_dir);
    fprintf('>> cd ''%s''\n', current_dir);
    fprintf('>> run_demo\n\n');
else
    fprintf('\n========================================\n');
    fprintf('? No path conflicts detected!\n');
    fprintf('========================================\n\n');
    fprintf('You can now safely run:\n');
    fprintf('>> run_demo\n\n');
end

% Show current path priority
fprintf('Current MATLAB search path (first 5 entries):\n');
p = path;
paths = strsplit(p, pathsep);
for i = 1:min(5, length(paths))
    fprintf('  %d. %s\n', i, paths{i});
end
fprintf('\n');
