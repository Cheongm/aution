function plot_results(results_ripp, results_tqdo, T)
% PLOT_RESULTS Generate comparison plots for RIPP-DR and TQDO algorithms
%
% Inputs:
%   results_ripp - Cell array of RIPP-DR results for each slot
%   results_tqdo - Cell array of TQDO results for each slot
%   T            - Number of time slots
%
% Outputs:
%   Three PNG files: miss_rt.png, util.png, cost.png

% Extract metrics from results
miss_rt_ripp = zeros(T, 1);
miss_rt_tqdo = zeros(T, 1);
avg_lat_ripp = zeros(T, 1);
avg_lat_tqdo = zeros(T, 1);
util_ru_ripp = zeros(T, 1);
util_du_ripp = zeros(T, 1);
util_cu_ripp = zeros(T, 1);
util_ru_tqdo = zeros(T, 1);
util_du_tqdo = zeros(T, 1);
util_cu_tqdo = zeros(T, 1);
cost_ripp = zeros(T, 1);
cost_tqdo = zeros(T, 1);

for t = 1:T
    miss_rt_ripp(t) = results_ripp{t}.miss_rt;
    miss_rt_tqdo(t) = results_tqdo{t}.miss_rt;
    avg_lat_ripp(t) = results_ripp{t}.avg_lat_rt;
    avg_lat_tqdo(t) = results_tqdo{t}.avg_lat_rt;
    util_ru_ripp(t) = results_ripp{t}.util_ru;
    util_du_ripp(t) = results_ripp{t}.util_du;
    util_cu_ripp(t) = results_ripp{t}.util_cu;
    util_ru_tqdo(t) = results_tqdo{t}.util_ru;
    util_du_tqdo(t) = results_tqdo{t}.util_du;
    util_cu_tqdo(t) = results_tqdo{t}.util_cu;
    cost_ripp(t) = results_ripp{t}.cost_sp;
    cost_tqdo(t) = results_tqdo{t}.cost_sp;
end

%% Figure 1: RT Miss Rate
figure('Position', [100, 100, 800, 400]);
plot(1:T, miss_rt_ripp, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
hold on;
plot(1:T, miss_rt_tqdo, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('Time Slot', 'FontSize', 12);
ylabel('RT Deadline Miss Rate', 'FontSize', 12);
title('RT Deadline Miss Rate Comparison', 'FontSize', 14, 'FontWeight', 'bold');
legend('RIPP-DR', 'TQDO', 'Location', 'best');
ylim([0, 1]);
saveas(gcf, 'miss_rt.png');
close(gcf);

%% Figure 2: Resource Utilization
figure('Position', [100, 100, 1200, 400]);

% RU utilization
subplot(1, 3, 1);
plot(1:T, util_ru_ripp, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
hold on;
plot(1:T, util_ru_tqdo, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('Time Slot', 'FontSize', 11);
ylabel('Utilization', 'FontSize', 11);
title('RU Utilization', 'FontSize', 12, 'FontWeight', 'bold');
legend('RIPP-DR', 'TQDO', 'Location', 'best');
ylim([0, 1]);

% DU utilization
subplot(1, 3, 2);
plot(1:T, util_du_ripp, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
hold on;
plot(1:T, util_du_tqdo, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('Time Slot', 'FontSize', 11);
ylabel('Utilization', 'FontSize', 11);
title('DU Utilization', 'FontSize', 12, 'FontWeight', 'bold');
legend('RIPP-DR', 'TQDO', 'Location', 'best');
ylim([0, 1]);

% CU utilization
subplot(1, 3, 3);
plot(1:T, util_cu_ripp, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
hold on;
plot(1:T, util_cu_tqdo, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('Time Slot', 'FontSize', 11);
ylabel('Utilization', 'FontSize', 11);
title('CU Utilization', 'FontSize', 12, 'FontWeight', 'bold');
legend('RIPP-DR', 'TQDO', 'Location', 'best');
ylim([0, 1]);

saveas(gcf, 'util.png');
close(gcf);

%% Figure 3: SP Cost
figure('Position', [100, 100, 800, 400]);
plot(1:T, cost_ripp, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
hold on;
plot(1:T, cost_tqdo, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('Time Slot', 'FontSize', 12);
ylabel('SP Cost [currency]', 'FontSize', 12);
title('Service Provider Cost Comparison', 'FontSize', 14, 'FontWeight', 'bold');
legend('RIPP-DR', 'TQDO', 'Location', 'best');
saveas(gcf, 'cost.png');
close(gcf);

fprintf('Plots saved: miss_rt.png, util.png, cost.png\n');

end
