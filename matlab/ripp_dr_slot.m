function result = ripp_dr_slot(users, config, slot_params)
% RIPP_DR_SLOT Execute RIPP-DR algorithm for one time slot
%
% Algorithm: Reputation-Indexed Posted-Price with Deadlines & Reservations
% - Split capacity into RT-reserved pool and NRT-elastic pool
% - RT: EDF scheduling with minimal-necessary grants
% - NRT: Weighted round-robin
%
% Inputs:
%   users       - Struct array of users (from gen_users)
%   config      - Configuration struct with capacity and reserve ratios
%   slot_params - Struct with per-slot parameters:
%                   .P, .N0, .t_bh, .Gamma_bh, .prices
%
% Output:
%   result      - Struct with fields:
%                   .alloc_B     - Bandwidth allocations [Hz]
%                   .alloc_f_du  - DU allocations [cycles/s]
%                   .alloc_f_cu  - CU allocations [cycles/s]
%                   .served      - Boolean vector of served users
%                   .latencies   - Actual latencies for RT users [s]
%                   .miss_rt     - RT deadline miss rate
%                   .avg_lat_rt  - Average RT latency [s]
%                   .util_ru     - RU utilization ratio
%                   .util_du     - DU utilization ratio
%                   .util_cu     - CU utilization ratio
%                   .cost_sp     - SP cost [currency]
%                   .jain_nrt    - NRT fairness (Jain index)

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

% Reserve capacity split (Eq. from Algorithm 1)
C_ru_rt = config.rho_rt_ru * config.C_ru;
C_du_rt = config.rho_rt_du * config.C_du;
C_cu_rt = config.rho_rt_cu * config.C_cu;

C_ru_el = config.C_ru - C_ru_rt;
C_du_el = config.C_du - C_du_rt;
C_cu_el = config.C_cu - C_cu_rt;

% Remaining capacities
rem_ru_rt = C_ru_rt;
rem_du_rt = C_du_rt;
rem_cu_rt = C_cu_rt;

%% RT Scheduling: EDF with minimal-necessary grants
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
        
        % Check if resources available in reserved pool
        if feasible && bundle.B <= rem_ru_rt && ...
                bundle.f_du <= rem_du_rt && bundle.f_cu <= rem_cu_rt
            % Grant resources
            alloc_B(u) = bundle.B;
            alloc_f_du(u) = bundle.f_du;
            alloc_f_cu(u) = bundle.f_cu;
            served(u) = true;
            
            % Compute actual latency
            r = rate_uplink(bundle.B, slot_params.P, users(u).h, [], slot_params.N0);
            [t_tot, ~, ~, ~] = total_latency(users(u).d_bits, r, ...
                users(u).theta_du, users(u).theta_cu, users(u).f_req, ...
                bundle.f_du, bundle.f_cu, slot_params.t_bh, config.latency_mode);
            latencies(u) = t_tot;
            
            % Deduct from reserved pool
            rem_ru_rt = rem_ru_rt - bundle.B;
            rem_du_rt = rem_du_rt - bundle.f_du;
            rem_cu_rt = rem_cu_rt - bundle.f_cu;
        end
    end
end

%% NRT Scheduling: Weighted round-robin on elastic pool
if ~isempty(nrt_idx)
    % Compute weights based on subscription tier
    weights = zeros(length(nrt_idx), 1);
    for i = 1:length(nrt_idx)
        u = nrt_idx(i);
        weights(i) = users(u).tier;  % Higher tier = higher weight
    end
    
    % Normalize weights
    weight_sum = sum(weights);
    if weight_sum > 0
        weights = weights / weight_sum;
    else
        weights = ones(length(nrt_idx), 1) / length(nrt_idx);
    end
    
    % Allocate elastic pool proportionally
    for i = 1:length(nrt_idx)
        u = nrt_idx(i);
        
        % Proportional share
        share_ru = weights(i) * C_ru_el;
        share_du = weights(i) * C_du_el;
        share_cu = weights(i) * C_cu_el;
        
        % Allocate (simple version: give proportional share)
        alloc_B(u) = min(share_ru, config.C_ru);  % Cap at total capacity
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
    
    % Miss: not served OR latency > deadline
    misses = ~rt_served | (rt_lats > rt_deadlines);
    result.miss_rt = sum(misses) / length(rt_idx);
    
    % Average RT latency (only for served users)
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

% Cost
[cost_sp, ~] = settle_cost(alloc_B, alloc_f_du, alloc_f_cu, ...
    slot_params.prices.ru, slot_params.prices.du, slot_params.prices.cu);
result.cost_sp = cost_sp;

% NRT fairness (Jain index)
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
