function bundle = minimal_bundle_rt(user, cfg, channel_gain, available, bh_latency)
%MINIMAL_BUNDLE_RT Search the minimal feasible RT resource bundle.
%   bundle = MINIMAL_BUNDLE_RT(user, cfg, channel_gain, available, bh_latency)
%   returns the smallest combination of bandwidth B [Hz], DU compute rate
%   f_du [cycles/s], and CU compute rate f_cu [cycles/s] that allows the RT
%   user to satisfy its end-to-end latency budget under DU-first preference
%   and backhaul latency threshold Gamma_bh. The search exhausts the discrete
%   candidate sets specified in cfg.Search and picks the bundle achieving the
%   minimum weighted sum score while meeting t_tot <= user.deadline.
%
%   Inputs:
%     user         struct with fields:
%                  - d_bits [bit] : task size
%                  - f_req [cycles]
%                  - deadline [s]
%                  - theta_du, theta_cu (fractions in [0,1])
%                  - parallel_mode (logical) : true if DU/CU execute in parallel
%     cfg          configuration struct; must contain:
%                  - Search.bandwidths_Hz
%                  - Search.du_rates
%                  - Search.cu_rates
%                  - Search.weight_bandwidth
%                  - Search.weight_du
%                  - Search.weight_cu
%                  - Noise.N0_W_Hz
%                  - Radio.P_tx_W
%                  - Radio.interference_W
%                  - Gamma_bh [s]
%     channel_gain instantaneous channel gain h (dimensionless)
%     available    struct with fields ru_max [Hz], du_max [cycles/s],
%                  cu_max [cycles/s] representing remaining reserved capacity.
%     bh_latency   RU->DU plus DU->CU baseline latency [s].
%
%   Output:
%     bundle struct containing:
%       - feasible (logical)
%       - B_Hz, f_du, f_cu (allocated resources)
%       - latency struct with fields tx, du, cu, total [s]
%       - score (weighted objective value)
%
%   If no candidate satisfies the latency constraint or available capacity,
%   the function marks feasible=false and returns zeros.

arguments
    user struct
    cfg struct
    channel_gain (1,1) double {mustBeNonnegative}
    available struct
    bh_latency (1,1) double {mustBeNonnegative}
end

bundle = struct('feasible', false, 'B_Hz', 0, 'f_du', 0, 'f_cu', 0, ...
    'latency', struct('tx', NaN, 'du', NaN, 'cu', NaN, 'total', NaN), ...
    'score', inf);

% Enforce backhaul constraint: if latency exceeds threshold, forbid CU usage.
theta_du = user.theta_du;
theta_cu = user.theta_cu;
if bh_latency > cfg.Gamma_bh
    theta_cu = 0;
    theta_du = 1;
end

bandwidth_grid = cfg.Search.bandwidths_Hz(:);
du_grid = cfg.Search.du_rates(:);
cu_grid = cfg.Search.cu_rates(:);

for b = 1:numel(bandwidth_grid)
    B = bandwidth_grid(b);
    if B > available.ru_max
        continue;
    end

    % Compute radio rate given the candidate bandwidth.
    r = rate_uplink(B, cfg.Radio.P_tx_W, channel_gain, ...
        cfg.Radio.interference_W, cfg.Noise.N0_W_Hz);
    if r <= 0
        continue;
    end

    t_tx = user.d_bits / r;

    for d = 1:numel(du_grid)
        f_du = du_grid(d);

        if theta_du > 0
            if available.du_max <= 0 || f_du > available.du_max || f_du <= 0
                continue;
            end
            t_du = (theta_du * user.f_req) / f_du;
        else
            f_du = 0;
            t_du = 0;
        end

        for c = 1:numel(cu_grid)
            f_cu = cu_grid(c);
            if theta_cu > 0
                if available.cu_max <= 0 || f_cu > available.cu_max || f_cu <= 0
                    continue;
                end
                t_cu_compute = (theta_cu * user.f_req) / f_cu;
            else
                f_cu = 0;
                t_cu_compute = 0;
            end

            t_cu = bh_latency + t_cu_compute;

            if user.parallel_mode
                t_tot = total_latency(t_tx, t_du, t_cu, "parallel");
            else
                t_tot = total_latency(t_tx, t_du, t_cu, "sequential");
            end

            if t_tot > user.deadline
                continue;
            end

            score = cfg.Search.weight_bandwidth * (B / max(cfg.Capacity.RU_Hz, eps)) + ...
                cfg.Search.weight_du * (f_du / max(cfg.Capacity.DU_cycles, eps)) + ...
                cfg.Search.weight_cu * (f_cu / max(cfg.Capacity.CU_cycles, eps));

            if score < bundle.score
                bundle.feasible = true;
                bundle.B_Hz = B;
                bundle.f_du = f_du;
                bundle.f_cu = f_cu;
                bundle.latency = struct('tx', t_tx, 'du', t_du, 'cu', t_cu, 'total', t_tot);
                bundle.score = score;
            end
        end
    end
end

if ~bundle.feasible
    bundle.latency = struct('tx', NaN, 'du', NaN, 'cu', NaN, 'total', NaN);
end
end
