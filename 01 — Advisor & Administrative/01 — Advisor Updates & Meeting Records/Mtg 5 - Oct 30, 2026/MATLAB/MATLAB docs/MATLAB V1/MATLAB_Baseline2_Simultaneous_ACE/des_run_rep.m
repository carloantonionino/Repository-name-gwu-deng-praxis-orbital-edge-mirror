function [G, E] = des_run_rep(M, rep, rawMb, groundMean, edgeMean, outFraction)
%DES_RUN_REP  One replication of both architectures over the ACE cohort.
%
%   Ground: arrive, wait for the link, downlink the full volume, process on
%           the ground, deliver.
%   Edge:   arrive, process onboard, downlink the reduced volume, deliver.
%
%   Both paths see the same arrivals, the same service draws and the same
%   link schedule. Queues are first come first served with one server each.

cfg = M.cfg;
n   = cfg.entities;
c   = M.cohort;

arrival = c.arrival;
rate    = c.rate;
prop    = c.prop;

raw  = repmat(rawMb,      n, 1);
frac = repmat(outFraction, n, 1);
gm   = repmat(groundMean,  n, 1);
em   = repmat(edgeMean,    n, 1);

% ---- seeded service draws, identical to the workbook Arrivals sheet
u = zeros(n, 1);
x = mod(cfg.a * (cfg.seed + 1000 * rep), cfg.m);
for i = 1:n
    if i > 1
        x = mod(cfg.a * x, cfg.m);
    end
    u(i) = max(x, 1) / cfg.m;
end

gProc = -gm .* log(u);
eProc = -em .* log(u);
gTx   = raw .* 8 ./ rate + prop;
eTx   = raw .* frac .* 8 ./ rate + prop;

G = des_blank(n);
E = des_blank(n);

% ---- ground path
linkFree = 0;
procFree = 0;
for i = 1:n
    earliest  = max(arrival(i), linkFree);
    linkStart = des_link_start(earliest, gTx(i), cfg);
    linkDone  = linkStart + gTx(i);
    linkFree  = linkDone;

    procStart = max(linkDone, procFree);
    delivered = procStart + gProc(i);
    procFree  = delivered;

    G.latency(i)   = delivered - arrival(i);
    G.recovery(i)  = linkStart - earliest;
    G.wait(i)      = (earliest - arrival(i)) + (linkStart - earliest) + (procStart - linkDone);
    G.done(i)      = delivered;
    G.delivered(i) = ~(gTx(i) > cfg.up || G.latency(i) > cfg.stale);
    G.within(i)    = G.delivered(i) && G.latency(i) <= cfg.deadline;
end

% ---- edge path
linkFree = 0;
procFree = 0;
for i = 1:n
    procStart = max(arrival(i), procFree);
    procDone  = procStart + eProc(i);
    procFree  = procDone;

    earliest  = max(procDone, linkFree);
    linkStart = des_link_start(earliest, eTx(i), cfg);
    delivered = linkStart + eTx(i);
    linkFree  = delivered;

    E.latency(i)   = delivered - arrival(i);
    E.recovery(i)  = linkStart - earliest;
    E.wait(i)      = (procStart - arrival(i)) + (earliest - procDone) + (linkStart - earliest);
    E.done(i)      = delivered;
    E.delivered(i) = ~(eTx(i) > cfg.up || E.latency(i) > cfg.stale);
    E.within(i)    = E.delivered(i) && E.latency(i) <= cfg.deadline;
end
end

% ------------------------------------------------------------------------
function s = des_blank(n)
z = zeros(n, 1);
s = struct('latency', z, 'wait', z, 'recovery', z, 'done', z, ...
           'delivered', z, 'within', z);
end

% ------------------------------------------------------------------------
function t = des_link_start(earliest, tx, cfg)
%DES_LINK_START  A transmission may only start inside an up window and must
%   fit in what is left of it, otherwise it waits for the next window.

phase = mod(earliest - cfg.offset, cfg.cycle);
if phase < cfg.up
    if cfg.up - phase >= tx
        t = earliest;
    else
        t = earliest + (cfg.up - phase) + cfg.down;
    end
else
    t = earliest + (cfg.cycle - phase);
end
end
