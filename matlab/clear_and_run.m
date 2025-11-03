%% clear_and_run.m
% Clear all MATLAB caches and run the simulation
% Use this if you get "cellfun" errors

fprintf('========================================\n');
fprintf('  Clearing MATLAB Cache\n');
fprintf('========================================\n\n');

% Step 1: Clear workspace
fprintf('1. Clearing workspace...\n');
clear all
close all
clc

% Step 2: Clear function cache
fprintf('2. Clearing function cache...\n');
clear functions

% Step 3: Rehash toolbox cache
fprintf('3. Rehashing toolbox cache...\n');
rehash toolboxcache

% Step 4: Verify we're in the right directory
fprintf('4. Checking current directory...\n');
current_dir = pwd;
fprintf('   Current: %s\n', current_dir);

if ~contains(current_dir, 'workspace') || ~contains(current_dir, 'matlab')
    warning('You may not be in the correct directory!');
    fprintf('   Expected: ...\\workspace\\matlab\n');
    fprintf('   Please run: cd YOUR_PATH\\workspace\\matlab\n\n');
    return;
end

% Step 5: Check for run_demo.m
fprintf('5. Checking for run_demo.m...\n');
if ~exist('run_demo.m', 'file')
    error('run_demo.m not found in current directory!');
end

% Step 6: Verify the fixed version
fprintf('6. Verifying run_demo.m is the fixed version...\n');
fid = fopen('run_demo.m', 'r');
content = fread(fid, '*char')';
fclose(fid);

if contains(content, 'cellfun(@(x) x.miss_rt')
    error('ERROR: You are using the OLD version of run_demo.m!\n       Please reload the file from the repository.');
end

if contains(content, 'miss_rt_vals = zeros(Config.T, 1)')
    fprintf('   ✅ Correct version detected!\n');
else
    warning('   ⚠️  Version unclear, but will try to run...\n');
end

fprintf('\n========================================\n');
fprintf('  Starting Simulation\n');
fprintf('========================================\n\n');

% Step 7: Run the simulation
run_demo

fprintf('\n========================================\n');
fprintf('  ✅ Simulation Completed!\n');
fprintf('========================================\n');
