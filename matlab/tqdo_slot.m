function result = tqdo_slot(users, config, slot_params)
% TQDO_SLOT Execute TQDO algorithm for one time slot
%
% Algorithm: Token-SLA with Dual-Queue Deterministic Orchestrator
% - RT: EDF + token check + optional buyback
% - NRT: Weighted round-robin on elastic tokens
%
% Inputs:
%   users       - Struct array of users (from gen_users)
%   config      - Configuration struct with token budgets
%   slot_params - Struct with per-slot parameters:
%                   .P, .N0, .t_bh, .Gamma_bh, .prices
%
% Output:
%   result      - Struct with same fields as ripp_dr_slot

N = length(users);

% Initialize allocations
alloc_B = zeros(N, 1);
alloc_f_du = zeros(N, 1);
alloc_f_cu = zeros(N, 1);
served = false(N, 1);
latencies = nan(N, 1);

% Separate RT and NRT users
rt_idx = find(strcmp({users.type}, 'RT'));
nrt_idx = find(strcmp({users.type}, 'NRT'));

% Token budgets (similar to reserved capacity)
token_ru_rt = config.token_rt_ru * config.C_ru;
token_du_rt = config.token_rt_du * config.C_du;
token_cu_rt = config.token_rt_cu * config.C_cu;

token_ru_nrt = config.C_ru - token_ru_rt;
token_du_nrt = config.C_du - token_du_rt;
token_cu_nrt = config.C_cu - token_cu_rt;

% Remaining tokens
rem_ru_rt = token_ru_rt;
rem_du_rt = token_du_rt;
rem_cu_rt = token_cu_rt;

buyback_cost = 0;  % Track buyback cost

%% RT Scheduling: EDF + token check + buyback
if ~isempty(rt_idx)
    % Sort by deadline (EDF)
    deadlines = [users(rt_idx).deadline];
    [~, sort_order] = sort(deadlines);
    rt_idx_sorted = rt_idx(sort_order);
    
    for i = 1:length(rt_idx_sorted)
        u = rt_idx_sorted(i);
        
        % Find minimal bundle
        [bundle, feasible] = minimal_bundle_rt(users(u), ...
            slot_params.P, slot_params.N0, slot_params.t_bh, ...
            slot_params.Gamma_bh, config.latency_mode, config.search_config);
        
        if feasible
            % Check token availability
            gap_ru = max(0, bundle.B - rem_ru_rt);
            gap_du = max(0, bundle.f_du - rem_du_rt);
            gap_cu = max(0, bundle.f_cu - rem_cu_rt);
            
            token_sufficient = (gap_ru == 0) && (gap_du == 0) && (gap_cu == 0);
            
            if ~token_sufficient && config.allow_buyback
                % Attempt buyback at posted price
                buyback = slot_params.prices.ru * gap_ru + ...
                          slot_params.prices.du * gap_du + ...
                          slot_params.prices.cu * gap_cu;
                
                % Simple policy: allow buyback if < threshold
                if buyback < config.buyback_threshold
                    % Grant with buyback
                    alloc_B(u) = bundle.B;
                    alloc_f_du(u) = bundle.f_du;
                    alloc_f_cu(u) = bundle.f_cu;
                    served(u) = true;
                    buyback_cost = buyback_cost + buyback;
                    
                    % Deduct available tokens (borrow from NRT)
                    rem_ru_rt = max(0, rem_ru_rt - bundle.B);
                    rem_du_rt = max(0, rem_du_rt - bundle.f_du);
                    rem_cu_rt = max(0, rem_cu_rt - bundle.f_cu);
                    
                    % Compute latency
                    r = rate_uplink(bundle.B, slot_params.P, users(u).h, [], slot_params.N0);
                    [t_tot, ~, ~, ~] = total_latency(users(u).d_bits, r, ...
                        users(u).theta_du, users(u).theta_cu, users(u).f_req, ...
                        bundle.f_du, bundle.f_cu, slot_params.t_bh, config.latency_mode);
                    latencies(u) = t_tot;
                end
                % Else: downgrade to NRT (not served as RT)
            elseif token_sufficient
                % Grant from RT tokens
                alloc_B(u) = bundle.B;
                alloc_f_du(u) = bundle.f_du;
                alloc_f_cu(u) = bundle.f_cu;
                served(u) = true;
                
                rem_ru_rt = rem_ru_rt - bundle.B;
                rem_du_rt = rem_du_rt - bundle.f_du;
                rem_cu_rt = rem_cu_rt - bundle.f_cu;
                
                % Compute latency
                r = rate_uplink(bundle.B, slot_params.P, users(u).h, [], slot_params.N0);
                [t_tot, ~, ~, ~] = total_latency(users(u).d_bits, r, ...
                    users(u).theta_du, users(u).theta_cu, users(u).f_req, ...
                    bundle.f_du, bundle.f_cu, slot_params.t_bh, config.latency_mode);
                latencies(u) = t_tot;
            end
            % Else: insufficient tokens, no buyback allowed -> not served
        end
    end
end

%% NRT Scheduling: Weighted round-robin
if ~isempty(nrt_idx)
    % Compute weights
    weights = zeros(length(nrt_idx), 1);
    for i = 1:length(nrt_idx)
        u = nrt_idx(i);
        weights(i) = users(u).tier;
    end
    
    % Normalize weights
    weight_sum = sum(weights);
    if weight_sum > 0
        weights = weights / weight_sum;
    else
        weights = ones(length(nrt_idx), 1) / length(nrt_idx);
    end
    
    % Allocate NRT tokens proportionally
    for i = 1:length(nrt_idx)
        u = nrt_idx(i);
        
        share_ru = weights(i) * token_ru_nrt;
        share_du = weights(i) * token_du_nrt;
        share_cu = weights(i) * token_cu_nrt;
        
        alloc_B(u) = min(share_ru, config.C_ru);
        alloc_f_du(u) = min(share_du, config.C_du);
        alloc_f_cu(u) = min(share_cu, config.C_cu);
        served(u) = true;
    end
end

%% Compute metrics
% RT miss rate
if ~isempty(rt_idx)
    rt_served = served(rt_idx);
    rt_lats = latencies(rt_idx);
    rt_deadlines = [users(rt_idx).deadline];
    
    misses = ~rt_served | (rt_lats > rt_deadlines);
    result.miss_rt = sum(misses) / length(rt_idx);
    
    served_lats = rt_lats(rt_served & ~isnan(rt_lats));
    if ~isempty(served_lats)
        result.avg_lat_rt = mean(served_lats);
    else
        result.avg_lat_rt = 0;
    end
else
    result.miss_rt = 0;
    result.avg_lat_rt = 0;
end

% Utilization
result.util_ru = sum(alloc_B) / config.C_ru;
result.util_du = sum(alloc_f_du) / config.C_du;
result.util_cu = sum(alloc_f_cu) / config.C_cu;

% Cost (including buyback)
[cost_sp, ~] = settle_cost(alloc_B, alloc_f_du, alloc_f_cu, ...
    slot_params.prices.ru, slot_params.prices.du, slot_params.prices.cu);
result.cost_sp = cost_sp + buyback_cost;

% NRT fairness
if ~isempty(nrt_idx)
    nrt_total_alloc = alloc_B(nrt_idx) + alloc_f_du(nrt_idx) + alloc_f_cu(nrt_idx);
    result.jain_nrt = jain_index(nrt_total_alloc);
else
    result.jain_nrt = 1;
end

% Store allocations
result.alloc_B = alloc_B;
result.alloc_f_du = alloc_f_du;
result.alloc_f_cu = alloc_f_cu;
result.served = served;
result.latencies = latencies;

end
