function slot_out = tqdo_slot(users, cfg, slot)
%TQDO_SLOT Execute one slot of the TQDO scheduler with token logic.
%   slot_out = TQDO_SLOT(users, cfg, slot) runs EDF scheduling with token
%   checks for RT users and weighted sharing for NRT users. The slot struct
%   follows the same layout as RIPP-DR: channel_gains, capacities, prices,
%   and bh_latency_s. Tokens for RT/NRT pools are derived from cfg.Token.

arguments
    users (:,1) struct
    cfg struct
    slot struct
end

cap = slot.capacities;

rt_tokens = struct('ru', cfg.Token.rt_fraction.RU * cap.ru_Hz, ...
                   'du', cfg.Token.rt_fraction.DU * cap.du_cycles, ...
                   'cu', cfg.Token.rt_fraction.CU * cap.cu_cycles);

nrt_tokens = struct('ru', cap.ru_Hz - rt_tokens.ru, ...
                    'du', cap.du_cycles - rt_tokens.du, ...
                    'cu', cap.cu_cycles - rt_tokens.cu);

rt_usage = struct('ru', 0.0, 'du', 0.0, 'cu', 0.0);
nrt_usage = struct('ru', 0.0, 'du', 0.0, 'cu', 0.0);

channel = slot.channel_gains(:);
rt_idx = find([users.is_rt]);
nrt_idx = find(~[users.is_rt]);
degraded_idx = [];

rt_served_lat = [];
rt_missed = 0;

if ~isempty(rt_idx)
    [~, order] = sort([users(rt_idx).deadline]);
    rt_idx = rt_idx(order);
    for k = 1:numel(rt_idx)
        u = rt_idx(k);
        % Search using the full physical capacity to see feasibility.
        bundle = minimal_bundle_rt(users(u), cfg, channel(u), ...
            struct('ru_max', cap.ru_Hz, 'du_max', cap.du_cycles, 'cu_max', cap.cu_cycles), ...
            slot.bh_latency_s);

        if ~bundle.feasible
            rt_missed = rt_missed + 1;
            degraded_idx(end+1,1) = u; %#ok<AGROW>
            continue;
        end

        [can_allocate, rt_tokens, nrt_tokens] = allocate_with_tokens(bundle, rt_tokens, nrt_tokens, cfg.Token.allow_buyback);
        if can_allocate
            rt_usage.ru = rt_usage.ru + bundle.B_Hz;
            rt_usage.du = rt_usage.du + bundle.f_du;
            rt_usage.cu = rt_usage.cu + bundle.f_cu;
            rt_served_lat(end+1,1) = bundle.latency.total; %#ok<AGROW>
        else
            rt_missed = rt_missed + 1;
            degraded_idx(end+1,1) = u; %#ok<AGROW>
        end
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

% NRT pool plus remaining tokens (including after buybacks).
elastic_ru = max(nrt_tokens.ru, 0);
elastic_du = max(nrt_tokens.du, 0);
elastic_cu = max(nrt_tokens.cu, 0);

% Append degraded RT users to NRT scheduling set.
all_nrt_idx = [nrt_idx(:); degraded_idx(:)];
nrt_throughputs = [];

if ~isempty(all_nrt_idx)
    weights = zeros(numel(all_nrt_idx),1);
    base_weights = [users(all_nrt_idx).nrt_weight]';
    weights(:) = base_weights;

    % Degraded RT users receive an optional boost weight.
    for i = 1:numel(all_nrt_idx)
        if users(all_nrt_idx(i)).is_rt
            weights(i) = cfg.Token.downgrade_weight;
        end
    end

    if all(weights <= 0)
        weights = ones(size(weights));
    end
    weights = weights ./ sum(weights);

    for i = 1:numel(all_nrt_idx)
        u = all_nrt_idx(i);
        share = weights(i);
        B = share * elastic_ru;
        f_du = share * elastic_du * double(users(u).theta_du > 0);
        f_cu = share * elastic_cu * double(users(u).theta_cu > 0);

        nrt_usage.ru = nrt_usage.ru + B;
        nrt_usage.du = nrt_usage.du + f_du;
        nrt_usage.cu = nrt_usage.cu + f_cu;

        r = rate_uplink(B, cfg.Radio.P_tx_W, channel(u), ...
            cfg.Radio.interference_W, cfg.Noise.N0_W_Hz);
        nrt_throughputs(end+1,1) = r; %#ok<AGROW>
    end
end

total_ru = min(cap.ru_Hz, rt_usage.ru + nrt_usage.ru);
total_du = min(cap.du_cycles, rt_usage.du + nrt_usage.du);
total_cu = min(cap.cu_cycles, rt_usage.cu + nrt_usage.cu);

usage_struct = struct('ru_Hz', total_ru, 'du_cycles', total_du, 'cu_cycles', total_cu);
[cost_sp, cost_detail] = settle_cost(usage_struct, slot.prices);

slot_out = struct(...
    'miss_rt_rate', miss_rt_rate, ...
    'avg_rt_latency', avg_rt_latency, ...
    'util_ru', total_ru / cap.ru_Hz, ...
    'util_du', total_du / cap.du_cycles, ...
    'util_cu', total_cu / cap.cu_cycles, ...
    'cost_sp', cost_sp, ...
    'cost_detail', cost_detail, ...
    'usage', usage_struct, ...
    'jain_nrt', jain_index(nrt_throughputs), ...
    'rt_served_lat', rt_served_lat, ...
    'rt_served', numel(rt_served_lat), ...
    'rt_total', num_rt);
end

function [can_allocate, rt_tokens, nrt_tokens] = allocate_with_tokens(bundle, rt_tokens, nrt_tokens, allow_buyback)
needed_ru = bundle.B_Hz;
needed_du = bundle.f_du;
needed_cu = bundle.f_cu;

def_ru = max(needed_ru - rt_tokens.ru, 0);
def_du = max(needed_du - rt_tokens.du, 0);
def_cu = max(needed_cu - rt_tokens.cu, 0);

if def_ru <= 0 && def_du <= 0 && def_cu <= 0
    can_allocate = true;
    rt_tokens.ru = rt_tokens.ru - needed_ru;
    rt_tokens.du = rt_tokens.du - needed_du;
    rt_tokens.cu = rt_tokens.cu - needed_cu;
    return;
end

if ~allow_buyback
    can_allocate = false;
    return;
end

if def_ru > nrt_tokens.ru || def_du > nrt_tokens.du || def_cu > nrt_tokens.cu
    can_allocate = false;
    return;
end

nrt_tokens.ru = nrt_tokens.ru - def_ru;
nrt_tokens.du = nrt_tokens.du - def_du;
nrt_tokens.cu = nrt_tokens.cu - def_cu;

rt_tokens.ru = rt_tokens.ru + def_ru - needed_ru;
rt_tokens.du = rt_tokens.du + def_du - needed_du;
rt_tokens.cu = rt_tokens.cu + def_cu - needed_cu;

can_allocate = true;
end
