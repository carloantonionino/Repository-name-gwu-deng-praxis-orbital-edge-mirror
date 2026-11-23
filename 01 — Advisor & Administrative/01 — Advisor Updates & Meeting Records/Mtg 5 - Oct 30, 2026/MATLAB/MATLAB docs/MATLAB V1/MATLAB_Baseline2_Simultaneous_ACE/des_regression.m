function [checks, maxErr] = des_regression(M, dataDir, T, runs, P)
%DES_REGRESSION  Compare the MATLAB results with the Excel workbook values.
%   Tolerance is 1e-6 absolute, as set on the workbook Validation tab.

tol = 1e-6;
checks = {};
maxErr = 0;

% ---- per entity results, 100 observations by 10 replications
X = des_read_numeric(fullfile(dataDir, 'expected_runs.csv'), 10);
n = M.cfg.entities;
R = M.cfg.replications;
eG = zeros(n, R); eE = zeros(n, R);
eGw = zeros(n, R); eEw = zeros(n, R);
eGd = zeros(n, R); eEd = zeros(n, R);
for k = 1:size(X, 1)
    r = X(k, 1); i = X(k, 2);
    eG(i, r)  = X(k, 3);  eGw(i, r) = X(k, 4);
    eGd(i, r) = X(k, 6);  eE(i, r)  = X(k, 7);
    eEw(i, r) = X(k, 8);  eEd(i, r) = X(k, 10);
end
[checks, maxErr] = add(checks, maxErr, tol, 'Ground latency, every entity', ...
    max(max(abs(runs.gLatency - eG))));
[checks, maxErr] = add(checks, maxErr, tol, 'Edge latency, every entity', ...
    max(max(abs(runs.eLatency - eE))));
[checks, maxErr] = add(checks, maxErr, tol, 'Queueing delay, both paths', ...
    max(max(max(abs(runs.gWait - eGw))), max(max(abs(runs.eWait - eEw)))));
[checks, maxErr] = add(checks, maxErr, tol, 'Deadline flags, both paths', ...
    max(max(max(abs(runs.gWithin - eGd))), max(max(abs(runs.eWithin - eEd)))));

% ---- per replication summary
Y = des_read_numeric(fullfile(dataDir, 'expected_replications.csv'), 26);
cols = {'gMean',3; 'gMedian',4; 'gP90',5; 'gWait',6; 'gRecov',7; 'gAffected',8; ...
        'gDeliv',9; 'gWithin',10; 'gLast',11; 'eMean',13; 'eMedian',14; 'eP90',15; ...
        'eWait',16; 'eRecov',17; 'eAffected',18; 'eDeliv',19; 'eWithin',20; 'eLast',21};
err = 0;
for k = 1:size(cols, 1)
    err = max(err, max(abs(T.(cols{k,1}) - Y(:, cols{k,2}))));
end
[checks, maxErr] = add(checks, maxErr, tol, 'Per replication statistics', err);

% ---- paired comparison
C = des_read_keyvalue(fullfile(dataDir, 'expected_comparison.csv'));
err = max([abs(P.latMean - C.lat_mean_diff), abs(P.latSd - C.lat_sd), ...
           abs(P.latSe - C.lat_se), abs(P.latLow - C.lat_ci_low), ...
           abs(P.latHigh - C.lat_ci_high), abs(P.avMean - C.av_mean_diff), ...
           abs(P.avLow - C.av_ci_low), abs(P.avHigh - C.av_ci_high), ...
           abs(P.gDelivShare - C.g_delivered_share), abs(P.eDelivShare - C.e_delivered_share), ...
           abs(P.gRecovery - C.g_recovery_s), abs(P.eRecovery - C.e_recovery_s)]);
[checks, maxErr] = add(checks, maxErr, tol, 'Paired difference and intervals', err);
[checks, maxErr] = add(checks, maxErr, tol, 'Two sided t critical value', ...
    abs(P.tcrit - C.lat_tcrit));
end

% ------------------------------------------------------------------------
function [checks, maxErr] = add(checks, maxErr, tol, name, err)
checks(end+1, :) = {name, err, err <= tol};
maxErr = max(maxErr, err);
end
