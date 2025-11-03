function [t_tot, t_tran, t_du, t_cu] = total_latency(d_bits, r_uplink, ...
    theta_du, theta_cu, f_req, f_du_alloc, f_cu_alloc, t_bh, mode)
% TOTAL_LATENCY Compute end-to-end latency for a task
%
% Inputs:
%   d_bits      - Input data size [bits]
%   r_uplink    - Uplink rate [bit/s]
%   theta_du    - Fraction of task processed at DU (dimensionless, 0-1)
%   theta_cu    - Fraction of task processed at CU (dimensionless, 0-1)
%   f_req       - Total compute demand [cycles]
%   f_du_alloc  - Allocated DU compute rate [cycles/s]
%   f_cu_alloc  - Allocated CU compute rate [cycles/s]
%   t_bh        - Backhaul/midhaul latency [s]
%   mode        - 'serial' or 'parallel' processing mode
%
% Outputs:
%   t_tot       - Total end-to-end latency [s]
%   t_tran      - Transmission latency [s]
%   t_du        - DU computation latency [s]
%   t_cu        - CU computation + backhaul latency [s]

if nargin < 9
    mode = 'serial';  % default mode
end

% Transmission time
if r_uplink > 0
    t_tran = d_bits / r_uplink;
else
    t_tran = inf;
end

% DU computation time
if theta_du > 0 && f_du_alloc > 0
    t_du = (theta_du * f_req) / f_du_alloc;
elseif theta_du > 0 && f_du_alloc == 0
    t_du = inf;
else
    t_du = 0;
end

% CU computation + backhaul time
if theta_cu > 0 && f_cu_alloc > 0
    t_cu = t_bh + (theta_cu * f_req) / f_cu_alloc;
elseif theta_cu > 0 && f_cu_alloc == 0
    t_cu = inf;
else
    t_cu = t_bh;  % Only backhaul if CU used but no compute
    if theta_cu == 0
        t_cu = 0;  % No CU at all
    end
end

% Total latency based on mode
if strcmpi(mode, 'parallel')
    % Parallel: transmission + max(DU, CU)
    t_tot = t_tran + max(t_du, t_cu);
else
    % Serial: transmission + DU + CU
    t_tot = t_tran + t_du + t_cu;
end

end
