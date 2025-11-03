function save_csv(results_ripp, results_tqdo, T)
% SAVE_CSV Save simulation results to CSV files
%
% Inputs:
%   results_ripp - Cell array of RIPP-DR results for each slot
%   results_tqdo - Cell array of TQDO results for each slot
%   T            - Number of time slots
%
% Outputs:
%   Two CSV files: ripp_dr_results.csv, tqdo_results.csv
%   Columns: slot, miss_rt, avg_rt_lat, util_ru, util_du, util_cu, cost_sp, jain_nrt

% Prepare data matrices
data_ripp = zeros(T, 8);
data_tqdo = zeros(T, 8);

for t = 1:T
    % RIPP-DR
    data_ripp(t, 1) = t;  % slot
    data_ripp(t, 2) = results_ripp{t}.miss_rt;
    data_ripp(t, 3) = results_ripp{t}.avg_lat_rt;
    data_ripp(t, 4) = results_ripp{t}.util_ru;
    data_ripp(t, 5) = results_ripp{t}.util_du;
    data_ripp(t, 6) = results_ripp{t}.util_cu;
    data_ripp(t, 7) = results_ripp{t}.cost_sp;
    data_ripp(t, 8) = results_ripp{t}.jain_nrt;
    
    % TQDO
    data_tqdo(t, 1) = t;  % slot
    data_tqdo(t, 2) = results_tqdo{t}.miss_rt;
    data_tqdo(t, 3) = results_tqdo{t}.avg_lat_rt;
    data_tqdo(t, 4) = results_tqdo{t}.util_ru;
    data_tqdo(t, 5) = results_tqdo{t}.util_du;
    data_tqdo(t, 6) = results_tqdo{t}.util_cu;
    data_tqdo(t, 7) = results_tqdo{t}.cost_sp;
    data_tqdo(t, 8) = results_tqdo{t}.jain_nrt;
end

% Create header
header = 'slot,miss_rt,avg_rt_lat,util_ru,util_du,util_cu,cost_sp,jain_nrt';

% Write RIPP-DR results
fid = fopen('ripp_dr_results.csv', 'w');
fprintf(fid, '%s\n', header);
for t = 1:T
    fprintf(fid, '%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
        data_ripp(t, 1), data_ripp(t, 2), data_ripp(t, 3), ...
        data_ripp(t, 4), data_ripp(t, 5), data_ripp(t, 6), ...
        data_ripp(t, 7), data_ripp(t, 8));
end
fclose(fid);

% Write TQDO results
fid = fopen('tqdo_results.csv', 'w');
fprintf(fid, '%s\n', header);
for t = 1:T
    fprintf(fid, '%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
        data_tqdo(t, 1), data_tqdo(t, 2), data_tqdo(t, 3), ...
        data_tqdo(t, 4), data_tqdo(t, 5), data_tqdo(t, 6), ...
        data_tqdo(t, 7), data_tqdo(t, 8));
end
fclose(fid);

fprintf('CSV files saved: ripp_dr_results.csv, tqdo_results.csv\n');

end
