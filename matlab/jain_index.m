function J = jain_index(x)
%JAIN_INDEX Compute Jain's fairness index for non-negative allocations.
%   J = JAIN_INDEX(x) returns the fairness index in [0,1] for the elements
%   of vector x, where x represents per-user throughputs or resource shares
%   (e.g., bit/s, Hz, cycles/s). A perfectly fair allocation yields J = 1,
%   while highly skewed allocations approach J = 0. For empty inputs or when
%   the vector sums to zero, the function returns J = 0 by convention.

arguments
    x (:,1) double {mustBeNonnegative}
end

if isempty(x)
    J = 0;
    return;
end

total = sum(x);
if total <= 0
    J = 0;
    return;
end

J = (total ^ 2) / (numel(x) * sum(x .^ 2));
end
