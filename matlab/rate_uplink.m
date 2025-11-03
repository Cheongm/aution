function r = rate_uplink(B, P_tx, h, interference, N0)
%RATE_UPLINK Compute single-user uplink data rate using Shannon capacity.
%   r = RATE_UPLINK(B, P_tx, h, interference, N0) returns the achievable
%   rate r [bit/s] for a user served with bandwidth B [Hz], cell transmit
%   power P_tx [W], instantaneous channel gain h (dimensionless), aggregate
%   interference power interference [W], and noise power spectral density
%   N0 [W/Hz]. The computation assumes a flat channel over the allocated
%   bandwidth and uses the classical Shannon formula:
%
%       r = B * log2(1 + (P_tx * h) / (interference + N0 * B)).
%
%   Inputs may be scalars or vectors of matching size. Negative or zero B
%   entries are clipped to zero rate. No external toolboxes are required.

arguments
    B (:,1) double
    P_tx (1,1) double {mustBeNonnegative}
    h (:,1) double {mustBeNonnegative}
    interference (:,1) double {mustBeNonnegative}
    N0 (1,1) double {mustBeNonnegative}
end

% Ensure column vectors for broadcasting and guard against floating errors.
B = max(B, 0);
signal_power = P_tx * h;
denom = interference + N0 .* B;

% Avoid divide-by-zero by enforcing a tiny floor on denominator.
denom = max(denom, eps);

snr = signal_power ./ denom;
r = B .* log2(1 + snr);

% Numerical cleanliness: replace any NaN from degenerate inputs with zero.
r(~isfinite(r)) = 0;
end
