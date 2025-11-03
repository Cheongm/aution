function [cost_sp, usage] = settle_cost(alloc_B, alloc_f_du, alloc_f_cu, price_ru, price_du, price_cu)
% SETTLE_COST Compute SP cost based on pay-as-you-use pricing (Eq. 21)
%
% Inputs:
%   alloc_B     - Vector of RU (bandwidth) allocations to users [Hz]
%   alloc_f_du  - Vector of DU compute allocations to users [cycles/s]
%   alloc_f_cu  - Vector of CU compute allocations to users [cycles/s]
%   price_ru    - Unit price for RU [currency/Hz]
%   price_du    - Unit price for DU [currency/(cycles/s)]
%   price_cu    - Unit price for CU [currency/(cycles/s)]
%
% Outputs:
%   cost_sp     - Total SP cost for this slot [currency]
%   usage       - Struct with fields:
%                   .ru  - Total RU usage [Hz]
%                   .du  - Total DU usage [cycles/s]
%                   .cu  - Total CU usage [cycles/s]

% Total usage
usage.ru = sum(alloc_B);
usage.du = sum(alloc_f_du);
usage.cu = sum(alloc_f_cu);

% Total cost (Eq. 21)
cost_sp = price_ru * usage.ru + price_du * usage.du + price_cu * usage.cu;

end
