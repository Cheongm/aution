function users = gen_users(N_rt, N_nrt, config)
% GEN_USERS Generate user profiles for RT and NRT traffic
%
% Inputs:
%   N_rt    - Number of real-time users
%   N_nrt   - Number of non-real-time users
%   config  - Configuration struct with fields:
%               .d_bits_rt_range   - [min, max] input size for RT [bits]
%               .d_bits_nrt_range  - [min, max] input size for NRT [bits]
%               .f_req_rt_range    - [min, max] compute demand for RT [cycles]
%               .f_req_nrt_range   - [min, max] compute demand for NRT [cycles]
%               .deadline_rt_range - [min, max] deadline for RT [s]
%               .channel_gain_range- [min, max] channel gain (dimensionless)
%
% Output:
%   users   - Struct array with fields for each user:
%               .type       - 'RT' or 'NRT'
%               .d_bits     - Input data size [bits]
%               .f_req      - Compute demand [cycles]
%               .deadline   - Latency budget [s] (RT only, NRT = inf)
%               .theta_du   - DU processing fraction (dimensionless, 0-1)
%               .theta_cu   - CU processing fraction (dimensionless, 0-1)
%               .tier       - Subscription tier (1=basic, 2=premium, 3=platinum)
%               .h          - Channel gain (dimensionless)

N_total = N_rt + N_nrt;
users = struct('type', cell(1, N_total), ...
               'd_bits', [], ...
               'f_req', [], ...
               'deadline', [], ...
               'theta_du', [], ...
               'theta_cu', [], ...
               'tier', [], ...
               'h', []);

% Generate RT users
for i = 1:N_rt
    users(i).type = 'RT';
    users(i).d_bits = config.d_bits_rt_range(1) + ...
        (config.d_bits_rt_range(2) - config.d_bits_rt_range(1)) * rand();
    users(i).f_req = config.f_req_rt_range(1) + ...
        (config.f_req_rt_range(2) - config.f_req_rt_range(1)) * rand();
    users(i).deadline = config.deadline_rt_range(1) + ...
        (config.deadline_rt_range(2) - config.deadline_rt_range(1)) * rand();
    
    % DU-first strategy for RT: favor DU processing
    users(i).theta_du = 0.6 + 0.3 * rand();  % 60%-90% at DU
    users(i).theta_cu = 1 - users(i).theta_du;
    
    users(i).tier = randi([1, 3]);  % Random tier
    users(i).h = config.channel_gain_range(1) + ...
        (config.channel_gain_range(2) - config.channel_gain_range(1)) * rand();
end

% Generate NRT users
for i = 1:N_nrt
    idx = N_rt + i;
    users(idx).type = 'NRT';
    users(idx).d_bits = config.d_bits_nrt_range(1) + ...
        (config.d_bits_nrt_range(2) - config.d_bits_nrt_range(1)) * rand();
    users(idx).f_req = config.f_req_nrt_range(1) + ...
        (config.f_req_nrt_range(2) - config.f_req_nrt_range(1)) * rand();
    users(idx).deadline = inf;  % No deadline for NRT
    
    % Flexible split for NRT
    users(idx).theta_du = rand();
    users(idx).theta_cu = 1 - users(idx).theta_du;
    
    users(idx).tier = randi([1, 3]);  % Random tier
    users(idx).h = config.channel_gain_range(1) + ...
        (config.channel_gain_range(2) - config.channel_gain_range(1)) * rand();
end

end
