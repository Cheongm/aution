function users = gen_users(num_users, cfg)
%GEN_USERS Generate RT and NRT user profiles for the simulator.
%   users = GEN_USERS(num_users, cfg) creates a struct array describing the
%   traffic demands and control parameters of each user. The configuration
%   struct must provide the statistical ranges for task size [bit], compute
%   demand [cycles], deadlines [s], subscription tiers (dimensionless), and
%   DU/CU offloading ratios. All random draws use the global RNG state.
%
%   Required cfg fields:
%     cfg.Users.rt_fraction           fraction of RT users in (0,1)
%     cfg.Users.d_bits_rt_range       [min,max] bits
%     cfg.Users.d_bits_nrt_range      [min,max] bits
%     cfg.Users.f_req_rt_range        [min,max] cycles
%     cfg.Users.f_req_nrt_range       [min,max] cycles
%     cfg.Users.deadline_range        [min,max] seconds (for RT)
%     cfg.Users.tiers                 vector of subscription tiers
%     cfg.Users.theta_rt              [theta_du, theta_cu]
%     cfg.Users.theta_nrt             [theta_du, theta_cu]
%     cfg.Users.parallel_rt           logical flag for RT execution mode
%     cfg.Users.parallel_nrt          logical flag for NRT execution mode

arguments
    num_users (1,1) double {mustBeInteger, mustBePositive}
    cfg struct
end

num_rt = max(1, round(cfg.Users.rt_fraction * num_users));
num_nrt = num_users - num_rt;

users = repmat(struct( ...
    'id', 0, ...
    'is_rt', false, ...
    'd_bits', 0.0, ...
    'f_req', 0.0, ...
    'deadline', inf, ...
    'tier', 1, ...
    'theta_du', 1.0, ...
    'theta_cu', 0.0, ...
    'parallel_mode', false, ...
    'deficit_credit', 1.0, ...
    'nrt_weight', 1.0), num_users, 1);

tier_values = cfg.Users.tiers(:);
num_tiers = numel(tier_values);

for u = 1:num_users
    users(u).id = u;
    tier_idx = randi(num_tiers);
    users(u).tier = tier_values(tier_idx);
    users(u).deficit_credit = 1.0; % initial credit, can be updated by schedulers
end

% Assign RT users first.
for idx = 1:num_rt
    u = idx;
    users(u).is_rt = true;
    users(u).d_bits = uniform_draw(cfg.Users.d_bits_rt_range);
    users(u).f_req = uniform_draw(cfg.Users.f_req_rt_range);
    users(u).deadline = uniform_draw(cfg.Users.deadline_range);
    users(u).theta_du = cfg.Users.theta_rt(1);
    users(u).theta_cu = cfg.Users.theta_rt(2);
    users(u).parallel_mode = cfg.Users.parallel_rt;
    users(u).nrt_weight = 0; % not used for RT fairness
end

% Remaining are NRT users.
for k = 1:num_nrt
    u = num_rt + k;
    users(u).is_rt = false;
    users(u).d_bits = uniform_draw(cfg.Users.d_bits_nrt_range);
    users(u).f_req = uniform_draw(cfg.Users.f_req_nrt_range);
    users(u).deadline = inf; % no hard deadline for NRT
    users(u).theta_du = cfg.Users.theta_nrt(1);
    users(u).theta_cu = cfg.Users.theta_nrt(2);
    users(u).parallel_mode = cfg.Users.parallel_nrt;
    users(u).nrt_weight = users(u).tier * users(u).deficit_credit;
end
end

function val = uniform_draw(range_vec)
val = range_vec(1) + (range_vec(2) - range_vec(1)) * rand();
end
