function nFail = build_ace_model(modelName)
%BUILD_ACE_MODEL  Construct the SimEvents Ground vs Edge model for R2026b.
%
%   build_ace_model                 builds ACE_GroundVsEdge.slx
%   build_ace_model('MyName')       builds MyName.slx
%
%   Run des_export_for_simulink first so the workspace values exist.
%
%   Built from the library actually present on this machine:
%     library   sldelib
%     blocks    Entity Generator, Entity Queue, Entity Server,
%               Entity Terminator, MATLAB Discrete-Event System
%
%   Topology, two independent paths over the same arrivals and link rules:
%
%     GROUND  generator -> queue -> link -> queue -> ground compute
%             -> recorder -> terminator
%     EDGE    generator -> queue -> onboard compute -> queue -> link
%             -> recorder -> terminator
%
%   Ground transmits the full volume then processes on the ground. Edge
%   processes onboard first, which reduces the volume, then transmits.
%
%   Every step prints PASS or FAIL. A failure names the block and the reason.

if nargin < 1 || isempty(modelName)
    modelName = 'ACE_GroundVsEdge';
end

here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fileparts(here));

% The MATLAB Discrete-Event System block name contains a real line break.
DES_BLOCK = ['sldelib/MATLAB' newline 'Discrete-Event System'];

fprintf('\n============================================================\n');
fprintf(' BUILDING %s\n', modelName);
fprintf(' Release %s, library sldelib\n', version('-release'));
fprintf('============================================================\n\n');

nFail = 0;

% ---------------------------------------------------------- 0. preconditions
fprintf('0. CHECKS\n');
nFail = nFail + step('Workspace prepared',            @checkWorkspace);
nFail = nFail + step('sldelib loads',                 @() load_system('sldelib'));
nFail = nFail + step('LinkWindowServer on the path',  @() checkClass('LinkWindowServer'));
nFail = nFail + step('LatencyRecorderGround on the path', @() checkClass('LatencyRecorderGround'));
nFail = nFail + step('LatencyRecorderEdge on the path',   @() checkClass('LatencyRecorderEdge'));
nFail = nFail + step('se_log on the path',            @() checkFile('se_log'));
fprintf('\n');

% ------------------------------------------------------------- 1. entity bus
fprintf('1. ENTITY DEFINITION\n');
nFail = nFail + step('Create the AceObs entity bus', @makeBus);
fprintf('\n');

% --------------------------------------------------------------- 2. model
fprintf('2. MODEL\n');
nFail = nFail + step('Create a clean model', @() makeModel(modelName));
fprintf('\n');

% -------------------------------------------------------------- 3. blocks
fprintf('3. BLOCKS\n');
specs = {
    'sldelib/Entity Generator',  'GenGround',     [ 40  40]
    'sldelib/Entity Queue',      'QueueLinkG',    [180  40]
    DES_BLOCK,                   'LinkGround',    [320  40]
    'sldelib/Entity Queue',      'QueueProcG',    [460  40]
    'sldelib/Entity Server',     'GroundCompute', [600  40]
    DES_BLOCK,                   'RecordGround',  [740  40]
    'sldelib/Entity Terminator', 'TermGround',    [880  40]
    'sldelib/Entity Generator',  'GenEdge',       [ 40 220]
    'sldelib/Entity Queue',      'QueueProcE',    [180 220]
    'sldelib/Entity Server',     'EdgeCompute',   [320 220]
    'sldelib/Entity Queue',      'QueueLinkE',    [460 220]
    DES_BLOCK,                   'LinkEdge',      [600 220]
    DES_BLOCK,                   'RecordEdge',    [740 220]
    'sldelib/Entity Terminator', 'TermEdge',      [880 220]
    };
for i = 1:size(specs, 1)
    nFail = nFail + step(['Add ' specs{i,2}], ...
        @() addBlockAt(modelName, specs{i,1}, specs{i,2}, specs{i,3}));
end
fprintf('\n');

% ---------------------------------------------------------- 4. block setup
fprintf('4. BLOCK SETTINGS\n');
nFail = nFail + step('Ground generator',      @() setGenerator(modelName, 'GenGround', 'ground'));
nFail = nFail + step('Edge generator',        @() setGenerator(modelName, 'GenEdge',   'edge'));
nFail = nFail + step('Ground queues',         @() setQueues(modelName, {'QueueLinkG', 'QueueProcG'}));
nFail = nFail + step('Edge queues',           @() setQueues(modelName, {'QueueProcE', 'QueueLinkE'}));
nFail = nFail + step('Ground compute server', @() setServer(modelName, 'GroundCompute'));
nFail = nFail + step('Edge compute server',   @() setServer(modelName, 'EdgeCompute'));
nFail = nFail + step('Ground link block',     @() setSystemBlock(modelName, 'LinkGround', 'LinkWindowServer'));
nFail = nFail + step('Edge link block',       @() setSystemBlock(modelName, 'LinkEdge',   'LinkWindowServer'));
nFail = nFail + step('Ground recorder',       @() setSystemBlock(modelName, 'RecordGround', 'LatencyRecorderGround'));
nFail = nFail + step('Edge recorder',         @() setSystemBlock(modelName, 'RecordEdge',   'LatencyRecorderEdge'));
fprintf('\n');

% -------------------------------------------------------------- 5. wiring
fprintf('5. PORT SURVEY\n');
refreshDiagram(modelName);
reportPorts(modelName, {'GenGround','QueueLinkG','LinkGround','QueueProcG', ...
                        'GroundCompute','RecordGround','TermGround', ...
                        'GenEdge','QueueProcE','EdgeCompute','QueueLinkE', ...
                        'LinkEdge','RecordEdge','TermEdge'});
fprintf('\n');

fprintf('6. CONNECTIONS\n');
groundChain = {'GenGround', 'QueueLinkG', 'LinkGround', 'QueueProcG', ...
               'GroundCompute', 'RecordGround', 'TermGround'};
edgeChain   = {'GenEdge', 'QueueProcE', 'EdgeCompute', 'QueueLinkE', ...
               'LinkEdge', 'RecordEdge', 'TermEdge'};
nFail = nFail + step('Ground path wiring', @() chain(modelName, groundChain));
nFail = nFail + step('Edge path wiring',   @() chain(modelName, edgeChain));
fprintf('\n');

% ------------------------------------------------------ 6. model settings
fprintf('7. SIMULATION SETTINGS\n');
nFail = nFail + step('Stop time and solver', @() setModelParams(modelName));
fprintf('\n');

% ----------------------------------------------------------------- 7. save
fprintf('8. SAVE\n');
target = fullfile(here, [modelName '.slx']);
nFail = nFail + step('Save the model', @() save_system(modelName, target));
fprintf('\n');

% --------------------------------------------------------------- summary
fprintf('============================================================\n');
if nFail == 0
    fprintf(' BUILD COMPLETE. No failures.\n');
    fprintf(' Saved to: %s\n\n', target);
else
    fprintf(' BUILD HAD %d FAILURE(S).\n\n', nFail);
    fprintf(' Send back everything printed above. Each failure names the\n');
    fprintf(' block and the reason, which is enough to correct it.\n\n');
end
end

% ======================================================================
% helpers
% ======================================================================

function failed = step(label, fn)
%STEP  Run one build step and report it. Returns 1 on failure, 0 on success.
try
    fn();
    fprintf('  %-44s PASS\n', label);
    failed = 0;
catch ME
    fprintf('  %-44s FAIL\n', label);
    fprintf('      %s\n', ME.message);
    if ~isempty(ME.identifier)
        fprintf('      identifier: %s\n', ME.identifier);
    end
    failed = 1;
end
end

% ----------------------------------------------------------------------
function checkWorkspace()
needed = {'seArrivalTimes', 'seInterArrival', 'seGroundProc', 'seEdgeProc', ...
          'seGroundTx', 'seEdgeTx', 'seLinkUp', 'seLinkDown', 'seCycleOffset', ...
          'seStopTime', 'seEntityCount'};
missing = {};
for i = 1:numel(needed)
    if evalin('base', sprintf('~exist(''%s'',''var'')', needed{i}))
        missing{end+1} = needed{i}; %#ok<AGROW>
    end
end
if ~isempty(missing)
    error('build:workspace', ...
        'Missing workspace values: %s. Run des_export_for_simulink first.', ...
        strjoin(missing, ', '));
end
end

% ----------------------------------------------------------------------
function checkClass(name)
if exist(name, 'class') ~= 8 && exist(name, 'file') ~= 2
    error('build:class', '%s.m is not on the MATLAB path.', name);
end
end

% ----------------------------------------------------------------------
function checkFile(name)
if exist(name, 'file') ~= 2
    error('build:file', '%s.m is not on the MATLAB path.', name);
end
end

% ----------------------------------------------------------------------
function makeBus()
fields = {'arrTime', 'procTime', 'txTime', 'linkWait', 'linkStart', ...
          'linkDone', 'latency'};
elems = Simulink.BusElement.empty(0, 1);
for i = 1:numel(fields)
    e = Simulink.BusElement;
    e.Name = fields{i};
    e.DataType = 'double';
    e.Dimensions = 1;
    e.Complexity = 'real';
    elems(i, 1) = e;
end
bus = Simulink.Bus;
bus.Elements = elems;
assignin('base', 'AceObs', bus);
end

% ----------------------------------------------------------------------
function makeModel(modelName)
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
load_system(modelName);
end

% ----------------------------------------------------------------------
function addBlockAt(modelName, src, name, pos)
dest = [modelName '/' name];
add_block(src, dest, 'Position', [pos(1) pos(2) pos(1)+100 pos(2)+70]);
end

% ----------------------------------------------------------------------
function setGenerator(modelName, blockName, pathName)
%SETGENERATOR  Configure one Entity Generator.
%
%   The arrival gaps and the per entity attributes are written into the
%   block actions as literal numbers. Block actions are compiled with
%   MATLAB Coder, which does not support evalin or calls out to ordinary
%   functions, so nothing is looked up at run time.

b = [modelName '/' blockName];

n    = evalin('base', 'seEntityCount');
gaps = evalin('base', 'seInterArrival');
arr  = evalin('base', 'seArrivalTimes');
if strcmpi(pathName, 'ground')
    proc = evalin('base', 'seGroundProc');
    tx   = evalin('base', 'seGroundTx');
else
    proc = evalin('base', 'seEdgeProc');
    tx   = evalin('base', 'seEdgeTx');
end

% 17 significant digits round trips a double exactly.
gapsLit = mat2str(gaps(:)', 17);
arrLit  = mat2str(arr(:)',  17);
procLit = mat2str(proc(:)', 17);
txLit   = mat2str(tx(:)',   17);

iatAction = sprintf([ ...
    'persistent j\n' ...
    'if isempty(j)\n' ...
    '    j = 0;\n' ...
    'end\n' ...
    'j = j + 1;\n' ...
    'gaps = %s;\n' ...
    'if j <= %d\n' ...
    '    dt = gaps(j);\n' ...
    'else\n' ...
    '    dt = 1e12;\n' ...
    'end\n'], gapsLit, n);

genAction = sprintf([ ...
    'persistent k\n' ...
    'if isempty(k)\n' ...
    '    k = 0;\n' ...
    'end\n' ...
    'k = k + 1;\n' ...
    'arrV  = %s;\n' ...
    'procV = %s;\n' ...
    'txV   = %s;\n' ...
    'if k <= %d\n' ...
    '    entity.arrTime  = arrV(k);\n' ...
    '    entity.procTime = procV(k);\n' ...
    '    entity.txTime   = txV(k);\n' ...
    'end\n'], arrLit, procLit, txLit, n);

set_param(b, 'GenerationMethod', 'Time-based');
set_param(b, 'GenerateEntityAtSimulationStart', 'off');
set_param(b, 'EntityType', 'Bus object');
set_param(b, 'EntityTypeName', 'AceObs');
set_param(b, 'TimeSource', 'MATLAB action');
set_param(b, 'IntergenerationTimeAction', iatAction);
set_param(b, 'GenerateAction', genAction);
end

% ----------------------------------------------------------------------
function setQueues(modelName, names)
for i = 1:numel(names)
    b = [modelName '/' names{i}];
    set_param(b, 'Capacity', '1000');
    set_param(b, 'QueueType', 'FIFO');
end
end

% ----------------------------------------------------------------------
function setServer(modelName, blockName)
b = [modelName '/' blockName];
set_param(b, 'Capacity', '1');
set_param(b, 'ServiceTimeSource', 'Attribute');
set_param(b, 'ServiceTimeAttributeName', 'procTime');
end

% ----------------------------------------------------------------------
function setSystemBlock(modelName, blockName, systemSpec)
b = [modelName '/' blockName];
set_param(b, 'System', systemSpec);
end

% ----------------------------------------------------------------------
function chain(modelName, names)
%CHAIN  Wire blocks in order using port handles.
%   Entity ports are not addressed like ordinary signal ports, so handles
%   are used instead of 'Block/1' strings.
for i = 1:numel(names)-1
    srcH = outPortHandle(modelName, names{i});
    dstH = inPortHandle(modelName, names{i+1});
    add_line(modelName, srcH, dstH, 'autorouting', 'on');
end
end

% ----------------------------------------------------------------------
function h = outPortHandle(modelName, blockName)
p = get_param([modelName '/' blockName], 'PortHandles');
h = firstHandle(p, {'Outport', 'LConn', 'RConn'});
if isempty(h)
    error('build:port', 'No usable output port found on %s. Fields: %s', ...
        blockName, strjoin(fieldnames(p)', ', '));
end
end

% ----------------------------------------------------------------------
function h = inPortHandle(modelName, blockName)
p = get_param([modelName '/' blockName], 'PortHandles');
h = firstHandle(p, {'Inport', 'LConn', 'RConn'});
if isempty(h)
    error('build:port', 'No usable input port found on %s. Fields: %s', ...
        blockName, strjoin(fieldnames(p)', ', '));
end
end

% ----------------------------------------------------------------------
function h = firstHandle(p, preferred)
h = [];
for i = 1:numel(preferred)
    if isfield(p, preferred{i}) && ~isempty(p.(preferred{i}))
        v = p.(preferred{i});
        h = v(1);
        return
    end
end
% fall back to any field that holds a handle
f = fieldnames(p);
for i = 1:numel(f)
    v = p.(f{i});
    if ~isempty(v)
        h = v(1);
        return
    end
end
end

% ----------------------------------------------------------------------
function refreshDiagram(modelName)
%REFRESHDIAGRAM  Force Simulink to work out the ports of the System blocks.
try
    set_param(modelName, 'SimulationCommand', 'update');
catch
    % an update can fail while the model is still unwired; the port survey
    % below will show whether the ports exist anyway
end
end

% ----------------------------------------------------------------------
function reportPorts(modelName, names)
%REPORTPORTS  Print the ports each block actually has.
for i = 1:numel(names)
    try
        p = get_param([modelName '/' names{i}], 'PortHandles');
        f = fieldnames(p);
        parts = {};
        for j = 1:numel(f)
            n = numel(p.(f{j}));
            if n > 0
                parts{end+1} = sprintf('%s=%d', f{j}, n); %#ok<AGROW>
            end
        end
        if isempty(parts)
            fprintf('  %-16s NO PORTS\n', names{i});
        else
            fprintf('  %-16s %s\n', names{i}, strjoin(parts, '  '));
        end
    catch ME
        fprintf('  %-16s could not read ports: %s\n', names{i}, ME.message);
    end
end
end

% ----------------------------------------------------------------------
function setModelParams(modelName)
stop = evalin('base', 'seStopTime');
set_param(modelName, 'StopTime', num2str(stop));
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'VariableStepDiscrete');
end
