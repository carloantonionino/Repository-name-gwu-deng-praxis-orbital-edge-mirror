function R = des_simevents_regression(groundLatency, edgeLatency, rep)
%DES_SIMEVENTS_REGRESSION  Check a SimEvents run against the verified engine.
%
%   R = des_simevents_regression(groundLatency, edgeLatency)
%   R = des_simevents_regression(groundLatency, edgeLatency, rep)
%
%   groundLatency and edgeLatency are vectors of end to end latency, one value
%   per observation, logged from the SimEvents model in entity order.
%
%   The engine this compares against already reproduces the Excel workbook to
%   9e-13, so passing here means the SimEvents model matches Excel too.
%
%   Example, after simulating:
%       out = sim('ACE_GroundVsEdge');
%       g = out.logsout.getElement('GroundLatency').Values.Data;
%       e = out.logsout.getElement('EdgeLatency').Values.Data;
%       des_simevents_regression(g, e)

if nargin < 3 || isempty(rep)
    rep = 1;
end
tol = 1e-6;

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root);
M = des_load(fullfile(root, 'data'));
[G, E] = des_run_rep(M, rep, M.cfg.rawMb, M.cfg.groundMean, M.cfg.edgeMean, ...
                     M.cfg.outFraction);

g = groundLatency(:);
e = edgeLatency(:);

fprintf('\n--- SIMEVENTS vs VERIFIED ENGINE ---------------------------\n');
fprintf('  Replication %d, tolerance %.0e absolute\n\n', rep, tol);

R.ok = true;

if numel(g) ~= numel(G.latency)
    fprintf('  Ground entity count  %d from the model, %d expected   FAIL\n', ...
        numel(g), numel(G.latency));
    fprintf('\n  The model did not produce one result per observation.\n');
    fprintf('  Check that the stop time is long enough for the queue to drain.\n');
    fprintf('  The suggested stop time is printed by des_export_for_simulink.\n\n');
    R.ok = false;
    return
end
if numel(e) ~= numel(E.latency)
    fprintf('  Edge entity count    %d from the model, %d expected   FAIL\n', ...
        numel(e), numel(E.latency));
    R.ok = false;
    return
end

R.groundError = max(abs(g - G.latency));
R.edgeError   = max(abs(e - E.latency));
R.maxError    = max(R.groundError, R.edgeError);

report('Ground latency, every observation', R.groundError, tol);
report('Edge latency, every observation',   R.edgeError,   tol);

fprintf('\n  Mean latency   model ground %.4f s   engine %.4f s\n', mean(g), mean(G.latency));
fprintf('  Mean latency   model edge   %.4f s   engine %.4f s\n', mean(e), mean(E.latency));
fprintf('  Largest error anywhere: %.3e\n', R.maxError);

R.ok = R.maxError <= tol;
if R.ok
    fprintf('  PASS. The SimEvents model reproduces the Excel baseline.\n\n');
else
    fprintf('  FAIL. Do not use these results yet.\n\n');
    worst = find(abs(g - G.latency) > tol, 1);
    if ~isempty(worst)
        fprintf('  First ground mismatch is observation %d:\n', worst);
        fprintf('    model %.6f s, engine %.6f s, difference %.3e\n', ...
            g(worst), G.latency(worst), g(worst) - G.latency(worst));
        fprintf('  If the difference is close to a whole contact window, the link\n');
        fprintf('  gate is the cause. Check UpWindow, DownWindow and CycleOffset\n');
        fprintf('  on the LinkWindowServer block.\n\n');
    end
end
end

% ------------------------------------------------------------------------
function report(name, err, tol)
if err <= tol
    verdict = 'PASS';
else
    verdict = 'FAIL';
end
fprintf('  %-38s %12.3e  %s\n', name, err, verdict);
end
