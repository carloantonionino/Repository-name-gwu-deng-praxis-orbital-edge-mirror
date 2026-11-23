function [T, runs] = des_replicate(M, rawMb, groundMean, edgeMean, outFraction, keepRuns)
%DES_REPLICATE  Run every replication and summarise each one.
%   runs holds the per entity results, one column per replication, which the
%   histogram and the regression check need.

if nargin < 6
    keepRuns = 0;
end

R = M.cfg.replications;
n = M.cfg.entities;

names = {'gMean','gMedian','gP90','gWait','gRecov','gAffected','gDeliv','gWithin','gLast', ...
         'eMean','eMedian','eP90','eWait','eRecov','eAffected','eDeliv','eWithin','eLast'};
for k = 1:numel(names)
    T.(names{k}) = zeros(R, 1);
end
T.rep = (1:R)';

runs.gLatency = zeros(n, R);
runs.eLatency = zeros(n, R);
runs.gWait    = zeros(n, R);
runs.eWait    = zeros(n, R);
runs.gWithin  = zeros(n, R);
runs.eWithin  = zeros(n, R);
runs.gDeliv   = zeros(n, R);
runs.eDeliv   = zeros(n, R);

for r = 1:R
    [G, E] = des_run_rep(M, r, rawMb, groundMean, edgeMean, outFraction);
    gs = des_rep_stats(G);
    es = des_rep_stats(E);

    T.gMean(r)     = gs.mean;     T.eMean(r)     = es.mean;
    T.gMedian(r)   = gs.median;   T.eMedian(r)   = es.median;
    T.gP90(r)      = gs.p90;      T.eP90(r)      = es.p90;
    T.gWait(r)     = gs.wait;     T.eWait(r)     = es.wait;
    T.gRecov(r)    = gs.recov;    T.eRecov(r)    = es.recov;
    T.gAffected(r) = gs.affected; T.eAffected(r) = es.affected;
    T.gDeliv(r)    = gs.deliv;    T.eDeliv(r)    = es.deliv;
    T.gWithin(r)   = gs.within;   T.eWithin(r)   = es.within;
    T.gLast(r)     = gs.last;     T.eLast(r)     = es.last;

    if keepRuns
        runs.gLatency(:, r) = G.latency;
        runs.eLatency(:, r) = E.latency;
        runs.gWait(:, r)    = G.wait;
        runs.eWait(:, r)    = E.wait;
        runs.gWithin(:, r)  = G.within;
        runs.eWithin(:, r)  = E.within;
        runs.gDeliv(:, r)   = G.delivered;
        runs.eDeliv(:, r)   = E.delivered;
    end
end
end
