function save_csv(filepath, slots, results)
%SAVE_CSV Persist slot-level KPI results to a CSV file.
%   SAVE_CSV(filepath, slots, results) writes the metrics in the struct
%   array `results` to disk. The CSV columns follow the mandated order:
%     slot, miss_rt, avg_rt_lat, util_ru, util_du, util_cu, cost_sp, jain_nrt
%   Units: miss_rt (dimensionless), avg_rt_lat [s], utilization (fraction),
%   cost_sp [currency], jain_nrt (dimensionless fairness).

arguments
    filepath (1,1) string
    slots (:,1) double
    results (:,1) struct
end

out_dir = fileparts(filepath);
if ~isempty(out_dir) && ~exist(out_dir, 'dir') %#ok<EXIST>
    mkdir(out_dir);
end

tbl = table(slots(:), [results.miss_rt_rate]', [results.avg_rt_latency]', ...
    [results.util_ru]', [results.util_du]', [results.util_cu]', ...
    [results.cost_sp]', [results.jain_nrt]', ...
    'VariableNames', {'slot','miss_rt','avg_rt_lat','util_ru','util_du','util_cu','cost_sp','jain_nrt'});

writetable(tbl, filepath);
end
