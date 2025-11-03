function [total_cost, detail] = settle_cost(usage, prices)
%SETTLE_COST Compute SP pay-as-you-use cost across resource types.
%   [total_cost, detail] = SETTLE_COST(usage, prices) evaluates the payment
%   in "currency" units required from the service provider given measured
%   resource usage and per-unit prices. The inputs are structs with fields:
%     usage.ru_Hz        [Hz]
%     usage.du_cycles    [cycles/s]
%     usage.cu_cycles    [cycles/s]
%     prices.ru          [currency/Hz]
%     prices.du          [currency/(cycles/s)]
%     prices.cu          [currency/(cycles/s)]
%   The function assumes missing fields are zero-rated.

arguments
    usage struct
    prices struct
end

ru_use = getfield_with_default(usage, 'ru_Hz', 0); %#ok<GFLD>
du_use = getfield_with_default(usage, 'du_cycles', 0);
cu_use = getfield_with_default(usage, 'cu_cycles', 0);

price_ru = getfield_with_default(prices, 'ru', 0);
price_du = getfield_with_default(prices, 'du', 0);
price_cu = getfield_with_default(prices, 'cu', 0);

ru_cost = ru_use * price_ru;
du_cost = du_use * price_du;
cu_cost = cu_use * price_cu;

total_cost = ru_cost + du_cost + cu_cost;

detail = struct('ru', ru_cost, 'du', du_cost, 'cu', cu_cost, ...
    'usage_ru_Hz', ru_use, 'usage_du_cycles', du_use, 'usage_cu_cycles', cu_use);
end

function value = getfield_with_default(S, name, default)
if isfield(S, name)
    value = S.(name);
else
    value = default;
end
end
