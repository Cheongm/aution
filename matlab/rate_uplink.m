function r = rate_uplink(B, P, h, h_interferers, N0)
% RATE_UPLINK Compute uplink data rate using Shannon formula
%
% Inputs:
%   B             - Allocated bandwidth [Hz]
%   P             - Transmit power of serving cell [W]
%   h             - Channel gain from serving cell (dimensionless)
%   h_interferers - Vector of channel gains from interfering cells (dimensionless)
%   N0            - Noise power spectral density [W/Hz]
%
% Output:
%   r             - Uplink rate [bit/s]
%
% Formula (Eq. 1):
%   r = B * log2(1 + (P*h) / (sum(P_i*h_i) + N0*B))
%
% For single-cell scenario, interference term is zero.

if nargin < 4 || isempty(h_interferers)
    h_interferers = [];
end

% Interference term (assuming same power P for all cells)
interference = P * sum(h_interferers);

% Noise term
noise = N0 * B;

% SINR
sinr = (P * h) / (interference + noise);

% Shannon rate
r = B * log2(1 + sinr);  % [bit/s]

end
