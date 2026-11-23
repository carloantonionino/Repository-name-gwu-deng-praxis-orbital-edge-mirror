function S = des_export_for_simulink(rep, varargin)
%DES_EXPORT_FOR_SIMULINK  Prepare the base workspace for the SimEvents model.
%
%   des_export_for_simulink            replication 1, primary settings
%   des_export_for_simulink(3)         replication 3
%   S = des_export_for_simulink(1)     also return the struct
%
%   This puts every value the SimEvents model needs into the base workspace,
%   so the blocks can reference them by name. Run it once before you open or
%   simulate the model.
%
%   Why the service times are precomputed here and not drawn inside SimEvents:
%   the workbook uses a Park-Miller stream with a fixed seed rule. SimEvents
%   random sources will not reproduce that stream, so the draws are made here
%   with the verified engine and attached to each entity as an attribute.
%   The queueing itself is still done by SimEvents.
%
%   Variables written to the base workspace:
%     seArrivalTimes     arrival time of each observation (s)
%     seInterArrival     gaps between arrivals, for the Entity Generator (s)
%     seGroundProc       ground processing time per entity (s)
%     seEdgeProc         onboard processing time per entity (s)
%     seGroundTx         ground transmission time per entity (s)
%     seEdgeTx           edge transmission time per entity (s)
%     seEntityCount      number of entities
%     seLinkUp           link up window (s)
%     seLinkDown         link down window (s)
%     seCycleOffset      cycle offset (s)
%     seStopTime         a safe simulation stop time (s)
%     seExpectedGround   expected ground latency per entity, from the engine
%     seExpectedEdge     expected edge latency per entity, from the engine

if nargin < 1 || isempty(rep)
    rep = 1;
end

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root);
dataDir = fullfile(root, 'data');

M = des_load(dataDir);

p.rawmb       = M.cfg.rawMb;
p.groundmean  = M.cfg.groundMean;
p.edgemean    = M.cfg.edgeMean;
p.outfraction = M.cfg.outFraction;
for k = 1:2:numel(varargin)
    p.(lower(varargin{k})) = varargin{k+1};
end

n = M.cfg.entities;
c = M.cohort;

% ---- the same seeded stream the workbook uses
u = zeros(n, 1);
x = mod(M.cfg.a * (M.cfg.seed + 1000 * rep), M.cfg.m);
for i = 1:n
    if i > 1
        x = mod(M.cfg.a * x, M.cfg.m);
    end
    u(i) = max(x, 1) / M.cfg.m;
end

S.arrival    = c.arrival;
S.interArr   = [c.arrival(1); diff(c.arrival)];
S.groundProc = -p.groundmean .* log(u);
S.edgeProc   = -p.edgemean   .* log(u);
S.groundTx   = p.rawmb .* 8 ./ c.rate + c.prop;
S.edgeTx     = p.rawmb .* p.outfraction .* 8 ./ c.rate + c.prop;
S.n          = n;
S.linkUp     = M.cfg.up;
S.linkDown   = M.cfg.down;
S.offset     = M.cfg.offset;
S.deadline   = M.cfg.deadline;
S.stale      = M.cfg.stale;
S.rep        = rep;

% ---- expected answers from the verified engine, for the regression check
[G, E] = des_run_rep(M, rep, p.rawmb, p.groundmean, p.edgemean, p.outfraction);
S.expectedGround = G.latency;
S.expectedEdge   = E.latency;
S.expectedGroundDone = G.done;
S.expectedEdgeDone   = E.done;

% a stop time comfortably past the last modelled delivery
S.stopTime = ceil(max([G.done; E.done]) * 1.25 / 100) * 100;

assignin('base', 'seArrivalTimes',   S.arrival);
assignin('base', 'seInterArrival',   S.interArr);
assignin('base', 'seGroundProc',     S.groundProc);
assignin('base', 'seEdgeProc',       S.edgeProc);
assignin('base', 'seGroundTx',       S.groundTx);
assignin('base', 'seEdgeTx',         S.edgeTx);
assignin('base', 'seEntityCount',    S.n);
assignin('base', 'seLinkUp',         S.linkUp);
assignin('base', 'seLinkDown',       S.linkDown);
assignin('base', 'seCycleOffset',    S.offset);
assignin('base', 'seStopTime',       S.stopTime);
assignin('base', 'seExpectedGround', S.expectedGround);
assignin('base', 'seExpectedEdge',   S.expectedEdge);

fprintf('\nSimEvents inputs prepared for replication %d.\n', rep);
fprintf('  Entities            : %d\n', S.n);
fprintf('  Arrival span        : %.0f s\n', max(S.arrival) - min(S.arrival));
fprintf('  Ground transmit time: %.3f s each\n', S.groundTx(1));
fprintf('  Edge transmit time  : %.3f s each\n', S.edgeTx(1));
fprintf('  Link schedule       : %.0f s up, %.0f s down, offset %.0f s\n', ...
    S.linkUp, S.linkDown, S.offset);
fprintf('  Suggested stop time : %.0f s\n', S.stopTime);
fprintf('  Expected mean latency, ground %.3f s, edge %.3f s\n', ...
    mean(S.expectedGround), mean(S.expectedEdge));
fprintf('\nBase workspace variables are set. You can now simulate the model.\n\n');
end
