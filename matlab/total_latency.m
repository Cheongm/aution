function t_total = total_latency(t_tx, t_du, t_cu, mode)
%TOTAL_LATENCY Compose end-to-end latency across radio and compute stages.
%   t_total = TOTAL_LATENCY(t_tx, t_du, t_cu, mode) combines the radio
%   transmission latency t_tx [s], DU compute latency t_du [s], and CU path
%   latency t_cu [s] according to the execution mode:
%     - 'sequential' : total = t_tx + t_du + t_cu (default)
%     - 'parallel'   : total = t_tx + max(t_du, t_cu)
%   Inputs can be scalars or vectors; the output matches the broadcasted size.

arguments
    t_tx (:,1) double {mustBeNonnegative}
    t_du (:,1) double {mustBeNonnegative}
    t_cu (:,1) double {mustBeNonnegative}
    mode (1,1) string {mustBeMember(mode,["sequential","parallel"])} = "sequential"
end

switch mode
    case "parallel"
        t_total = t_tx + max(t_du, t_cu);
    otherwise % sequential
        t_total = t_tx + t_du + t_cu;
end
end
