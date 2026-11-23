function results = run_all(varargin)
%RUN_ALL  MATLAB Baseline 2: reproduce the Simultaneous OPS-SAT ACE Excel model.
%
%   run_all                 reproduce the workbook and run every regression check
%   run_all('reps', 50)     same model, more replications (scaling demonstration)
%   run_all('figures', 0)   skip the figure export
%
%   Runs in core MATLAB. No toolboxes are required.
%
%   Model: the same 100 synchronized ACE observations run through a ground
%   centric path and a bounded orbital edge path under an identical link
%   schedule. Arrival times are replayed from the telemetry offsets. Only the
%   service times are random, from the seeded generator the workbook uses.
%
%   Source of truth: Work v9 Simultaneous OPS-SAT ACE, ASOT locked v03.
%   Regression tolerance: 1e-6 absolute, as set on the Validation tab.

here = fileparts(mfilename('fullpath'));
addpath(here);
dataDir = fullfile(here, 'data');
outDir  = fullfile(here, 'output');
if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end

opt.reps = [];
opt.figures = 1;
for k = 1:2:numel(varargin)
    opt.(lower(varargin{k})) = varargin{k+1};
end
scaling = ~isempty(opt.reps);

fprintf('\n============================================================\n');
fprintf(' MATLAB Baseline 2  -  Simultaneous OPS-SAT ACE\n');
fprintf(' Ground centric vs bounded orbital edge\n');
fprintf(' MATLAB release: %s\n', version('-release'));
fprintf('============================================================\n\n');

% ---------------------------------------------------------------- inputs
M = des_load(dataDir);
if scaling
    M.cfg.replications = opt.reps;
    fprintf('Scaling run: %d replications. The workbook uses 10.\n', opt.reps);
    fprintf('Regression checks are skipped because the run differs from the baseline.\n\n');
end
fprintf('Cohort        : %d observations, arrival span %.0f s\n', ...
    M.cfg.entities, max(M.cohort.arrival) - min(M.cohort.arrival));
fprintf('Replications  : %d\n', M.cfg.replications);
fprintf('Link schedule : %.0f s up, %.0f s down\n', M.cfg.up, M.cfg.down);
fprintf('Deadline      : %.0f s    Staleness limit: %.0f s\n\n', M.cfg.deadline, M.cfg.stale);

% ------------------------------------------------------------ primary run
[T, runs] = des_replicate(M, M.cfg.rawMb, M.cfg.groundMean, M.cfg.edgeMean, ...
                          M.cfg.outFraction, 1);
P = des_paired(T, M.cfg.alpha);

fprintf('--- PRIMARY RESULT -----------------------------------------\n');
fprintf('  Mean latency       Ground %10.3f s    Edge %10.3f s\n', mean(T.gMean), mean(T.eMean));
fprintf('  Median latency     Ground %10.3f s    Edge %10.3f s\n', mean(T.gMedian), mean(T.eMedian));
fprintf('  P90 latency        Ground %10.3f s    Edge %10.3f s\n', mean(T.gP90), mean(T.eP90));
fprintf('  Queueing delay     Ground %10.3f s    Edge %10.3f s\n', mean(T.gWait), mean(T.eWait));
fprintf('  Within deadline    Ground %9.1f %%     Edge %9.1f %%\n', ...
    100*mean(T.gWithin), 100*mean(T.eWithin));
fprintf('  Stale or dropped   Ground %9.1f %%     Edge %9.1f %%\n', ...
    100*(1-mean(T.gDeliv)), 100*(1-mean(T.eDeliv)));
fprintf('  Paired latency difference, ground minus edge: %.3f s\n', P.latMean);
fprintf('  95%% interval %.3f to %.3f s   (t = %.6f, n = %d)\n', ...
    P.latLow, P.latHigh, P.tcrit, P.n);
fprintf('  Reading: %s\n', P.latReading);
fprintf('  SIMULATION OUTPUT. Assumption conditioned, not a measurement.\n\n');

% -------------------------------------------------------------- scenarios
S = des_scenarios(M, dataDir);
fprintf('--- SCENARIO SWEEP -----------------------------------------\n');
fprintf('  %-16s %14s %14s %14s\n', 'Case', 'Ground mean s', 'Edge mean s', 'Difference s');
for i = 1:numel(S.name)
    fprintf('  %-16s %14.3f %14.3f %14.3f\n', S.name{i}, S.gMean(i), S.eMean(i), ...
        S.gMean(i) - S.eMean(i));
end
fprintf('  Edge is slower in %d of %d cases. The identical case must read 0.000.\n\n', ...
    sum((S.gMean - S.eMean) < 0), numel(S.name));

% ------------------------------------------------------------- histogram
B = des_bins(M, runs, 200);

% ------------------------------------------------------------- regression
checks = {};
maxErr = NaN;
if ~scaling
    [checks, maxErr] = des_regression(M, dataDir, T, runs, P);
    [checks, maxErr] = des_check_scenarios(dataDir, M, S, checks, maxErr);
    [checks, maxErr] = des_check_bins(dataDir, B, checks, maxErr);

    fprintf('--- REGRESSION AGAINST THE EXCEL WORKBOOK ------------------\n');
    fprintf('  %-42s %12s  %s\n', 'Check', 'Max error', 'Result');
    nfail = 0;
    for i = 1:size(checks, 1)
        if checks{i,3}
            verdict = 'PASS';
        else
            verdict = 'FAIL';
            nfail = nfail + 1;
        end
        fprintf('  %-42s %12.3e  %s\n', checks{i,1}, checks{i,2}, verdict);
    end
    fprintf('\n  Tolerance 1e-06 absolute. Largest error anywhere: %.3e\n', maxErr);
    if nfail == 0
        fprintf('  ALL CHECKS PASSED. MATLAB reproduces the workbook.\n\n');
    else
        fprintf('  %d CHECK(S) FAILED. Do not use these results yet.\n\n', nfail);
    end
end

% ------------------------------------------------------------------ output
des_write_results(outDir, T, P, S, B);
if opt.figures
    des_figures(M, T, P, S, B, outDir);
end
fprintf('Results and figures written to:\n  %s\n\n', outDir);

results = struct('config', M.cfg, 'replications', T, 'paired', P, ...
                 'scenarios', S, 'bins', B, 'checks', {checks});
end
