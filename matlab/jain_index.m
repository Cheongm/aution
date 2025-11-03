function J = jain_index(allocations)
% JAIN_INDEX Compute Jain's fairness index
%
% Input:
%   allocations - Vector of resource allocations to users (any unit)
%
% Output:
%   J           - Jain's fairness index (0 to 1, 1 = perfectly fair)
%
% Formula: J = (sum(x_i))^2 / (n * sum(x_i^2))

allocations = allocations(:);  % Ensure column vector
n = length(allocations);

if n == 0
    J = 1;  % Edge case: no users
    return;
end

sum_x = sum(allocations);
sum_x2 = sum(allocations.^2);

if sum_x2 == 0
    J = 1;  % All zero allocations
else
    J = (sum_x^2) / (n * sum_x2);
end

end
