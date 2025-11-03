function [bundle, feasible] = minimal_bundle_rt(user, P, N0, t_bh, ...
    Gamma_bh, mode, search_config)
% MINIMAL_BUNDLE_RT Find minimal resource bundle for RT user to meet deadline
%
% Inputs:
%   user          - User struct with fields: d_bits, f_req, deadline, 
%                   theta_du, theta_cu, h
%   P             - Transmit power [W]
%   N0            - Noise PSD [W/Hz]
%   t_bh          - Backhaul/midhaul latency [s]
%   Gamma_bh      - Backhaul threshold [s] (if t_bh > Gamma_bh, no CU offload)
%   mode          - 'serial' or 'parallel'
%   search_config - Struct with grid search parameters:
%                     .B_grid    - Bandwidth search points [Hz]
%                     .f_du_grid - DU compute search points [cycles/s]
%                     .f_cu_grid - CU compute search points [cycles/s]
%
% Outputs:
%   bundle        - Struct with fields:
%                     .B      - Bandwidth allocation [Hz]
%                     .f_du   - DU compute allocation [cycles/s]
%                     .f_cu   - CU compute allocation [cycles/s]
%   feasible      - Boolean indicating if solution found

% Initialize
bundle.B = 0;
bundle.f_du = 0;
bundle.f_cu = 0;
feasible = false;

% Check backhaul constraint: if t_bh > Gamma_bh, disable CU
use_cu = (t_bh <= Gamma_bh) && (user.theta_cu > 0);

% Grid search for minimal bundle
% We search over B, f_du, f_cu to minimize total resource cost
% Metric: weighted sum of normalized resources
min_cost = inf;

for B = search_config.B_grid
    % Compute uplink rate
    r = rate_uplink(B, P, user.h, [], N0);
    
    for f_du = search_config.f_du_grid
        
        if use_cu
            f_cu_search = search_config.f_cu_grid;
        else
            f_cu_search = 0;  % No CU
        end
        
        for f_cu = f_cu_search
            % Compute total latency
            [t_tot, ~, ~, ~] = total_latency(user.d_bits, r, ...
                user.theta_du, user.theta_cu, user.f_req, ...
                f_du, f_cu, t_bh, mode);
            
            % Check deadline constraint
            if t_tot <= user.deadline
                % Compute cost (simple sum, normalized to similar scales)
                % Normalize: B in MHz, f in GHz
                cost = B/1e6 + f_du/1e9 + f_cu/1e9;
                
                if cost < min_cost
                    min_cost = cost;
                    bundle.B = B;
                    bundle.f_du = f_du;
                    bundle.f_cu = f_cu;
                    feasible = true;
                end
            end
        end
    end
end

end
