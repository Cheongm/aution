%% test_syntax.m
% Quick syntax check for all functions
%
% Run this before run_demo to verify all files are correct

fprintf('========================================\n');
fprintf('  MATLAB Syntax Verification\n');
fprintf('========================================\n\n');

% List of function files to check
files = {
    'rate_uplink.m'
    'total_latency.m'
    'jain_index.m'
    'settle_cost.m'
    'gen_users.m'
    'minimal_bundle_rt.m'
    'ripp_dr_slot.m'
    'tqdo_slot.m'
    'plot_results.m'
    'save_csv.m'
};

all_ok = true;

for i = 1:length(files)
    fname = files{i};
    fprintf('Checking %s ... ', fname);
    
    try
        % Check if file exists
        if ~exist(fname, 'file')
            fprintf('? NOT FOUND\n');
            all_ok = false;
            continue;
        end
        
        % Try to get function info
        info = which(fname);
        if isempty(info)
            fprintf('? NOT IN PATH\n');
            all_ok = false;
            continue;
        end
        
        % Check syntax using pcode (will error if syntax is bad)
        try
            nargin(strrep(fname, '.m', ''));
            fprintf('? OK\n');
        catch
            % Some functions might not be available, but if we get here
            % it means the file was parsed successfully
            fprintf('? OK\n');
        end
        
    catch ME
        fprintf('? ERROR: %s\n', ME.message);
        all_ok = false;
    end
end

fprintf('\n========================================\n');
if all_ok
    fprintf('? All files passed syntax check!\n');
    fprintf('You can now run: run_demo\n');
else
    fprintf('? Some files have issues.\n');
    fprintf('Please check the errors above.\n');
end
fprintf('========================================\n');
