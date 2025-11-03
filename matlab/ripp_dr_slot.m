function slot_out = ripp_dr_slot(users, cfg, slot)
%RIPP_DR_SLOT Execute one slot of the RIPP-DR scheduler.
%   slot_out = RIPP_DR_SLOT(users, cfg, slot) applies RT reservation and
%   EDF scheduling followed by NRT weighted sharing. The struct `slot` must
%   provide:
%     slot.channel_gains  [num_users x 1] instantaneous h values
%     slot.capacities     struct with fields ru_Hz, du_cycles, cu_cycles
%     slot.prices         struct with fields ru, du, cu (currency per unit)
%     slot.bh_latency_s   scalar RU->DU plus DU->CU latency [s]
%   The output contains per-slot KPIs and resource usage statistics.

arguments
    users (:,1) struct
    cfg struct
    slot struct
end

num_users = numel(users);
channel = slot.channel_gains(:);
cap = slot.capacities;

rho = cfg.Reserve.rho_rt;
reserve = struct('ru', rho.RU * cap.ru_Hz, ...
                 'du', rho.DU * cap.du_cycles, ...
                 'cu', rho.CU * cap.cu_cycles);

elastic_base = struct('ru', (1 - rho.RU) * cap.ru_Hz, ...
                      'du', (1 - rho.DU) * cap.du_cycles, ...
                      'cu', (1 - rho.CU) * cap.cu_cycles);

rt_idx = find([users.is_rt]);
nrt_idx = find(~[users.is_rt]);

rt_usage = struct('ru', 0.0, 'du', 0.0, 'cu', 0.0);
elastic_usage = struct('ru', 0.0, 'du', 0.0, 'cu', 0.0);

rt_served_lat = [];
rt_missed = 0;

if ~isempty(rt_idx)
    [~, order] = sort([users(rt_idx).deadline]); % EDF ordering
    rt_idx = rt_idx(order);
    for k = 1:numel(rt_idx)
        u = rt_idx(k);
        available = struct('ru_max', reserve.ru - rt_usage.ru, ...
                           'du_max', reserve.du - rt_usage.du, ...
                           'cu_max', reserve.cu - rt_usage.cu);
        bundle = minimal_bundle_rt(users(u), cfg, channel(u), available, slot.bh_latency_s);
        if ~bundle.feasible
            rt_missed = rt_missed + 1;
            continue;
        end

        rt_usage.ru = rt_usage.ru + bundle.B_Hz;
        rt_usage.du = rt_usage.du + bundle.f_du;
        rt_usage.cu = rt_usage.cu + bundle.f_cu;
        rt_served_lat(end+1,1) = bundle.latency.total; %#ok<AGROW>
    end
end

num_rt = numel(rt_idx);
if num_rt == 0
    miss_rt_rate = 0;
else
    miss_rt_rate = rt_missed / num_rt;
end

avg_rt_latency = 0;
if ~isempty(rt_served_lat)
    avg_rt_latency = mean(rt_served_lat);
end

unused_rt = struct('ru', max(reserve.ru - rt_usage.ru, 0), ...
                   'du', max(reserve.du - rt_usage.du, 0), ...
                   'cu', max(reserve.cu - rt_usage.cu, 0));

elastic_headroom = struct('ru', elastic_base.ru + unused_rt.ru, ...
                          'du', elastic_base.du + unused_rt.du, ...
                          'cu', elastic_base.cu + unused_rt.cu);

nrt_throughputs = [];

if ~isempty(nrt_idx)
    weights = [users(nrt_idx).nrt_weight]';
    if all(weights <= 0)
        weights = ones(size(weights));
    end
    weights = weights ./ sum(weights);

    for i = 1:numel(nrt_idx)
        u = nrt_idx(i);
        share = weights(i);
        B = share * elastic_headroom.ru;
        f_du = share * elastic_headroom.du * double(users(u).theta_du > 0);
        f_cu = share * elastic_headroom.cu * double(users(u).theta_cu > 0);

        elastic_usage.ru = elastic_usage.ru + B;
        elastic_usage.du = elastic_usage.du + f_du;
        elastic_usage.cu = elastic_usage.cu + f_cu;

        r = rate_uplink(B, cfg.Radio.P_tx_W, channel(u), ...
            cfg.Radio.interference_W, cfg.Noise.N0_W_Hz);
        nrt_throughputs(end+1,1) = r; %#ok<AGROW>
    end
end

total_ru = min(cap.ru_Hz, rt_usage.ru + elastic_usage.ru);
total_du = min(cap.du_cycles, rt_usage.du + elastic_usage.du);
total_cu = min(cap.cu_cycles, rt_usage.cu + elastic_usage.cu);

util_ru = total_ru / cap.ru_Hz;
util_du = total_du / cap.du_cycles;
util_cu = total_cu / cap.cu_cycles;

usage_struct = struct('ru_Hz', total_ru, 'du_cycles', total_du, 'cu_cycles', total_cu);
[cost_sp, cost_detail] = settle_cost(usage_struct, slot.prices);

jain_nrt = jain_index(nrt_throughputs);

slot_out = struct(...
    'miss_rt_rate', miss_rt_rate, ...
    'avg_rt_latency', avg_rt_latency, ...
    'util_ru', util_ru, ...
    'util_du', util_du, ...
    'util_cu', util_cu, ...
    'cost_sp', cost_sp, ...
    'cost_detail', cost_detail, ...
    'usage', usage_struct, ...
    'jain_nrt', jain_nrt, ...
    'rt_served_lat', rt_served_lat, ...
    'rt_served', numel(rt_served_lat), ...
    'rt_total', num_rt);
end
