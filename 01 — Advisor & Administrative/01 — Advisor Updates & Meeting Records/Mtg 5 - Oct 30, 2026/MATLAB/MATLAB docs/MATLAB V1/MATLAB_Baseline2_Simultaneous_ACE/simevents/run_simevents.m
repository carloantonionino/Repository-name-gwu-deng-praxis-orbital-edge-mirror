function run_simevents(rep)
%RUN_SIMEVENTS  Build, simulate and check the SimEvents model end to end.
%
%   run_simevents          replication 1
%   run_simevents(3)       replication 3
%
%   This is the one command for stage 2. It prepares the inputs, builds the
%   model, runs it, and checks the result against the verified MATLAB engine
%   which already reproduces the Excel workbook to 9e-13.

if nargin < 1 || isempty(rep)
    rep = 1;
end

here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fileparts(here));
cd(here);

modelName = 'ACE_GroundVsEdge';

fprintf('\n############################################################\n');
fprintf('# SIMEVENTS STAGE 2, replication %d\n', rep);
fprintf('############################################################\n');

% 1. inputs
des_export_for_simulink(rep);
se_log('reset');

% 2. build
build_ace_model(modelName);

% 3. simulate
fprintf('SIMULATING\n');
fprintf('------------------------------------------------------------\n');
try
    sim(modelName);
    fprintf('  Simulation finished.\n');
catch ME
    fprintf('  SIMULATION FAILED. Full cause tree:\n\n');
    se_report_error(ME);
    fprintf('\n  Send everything above back.\n\n');
    return
end

se_log('report');

% 4. regression
g = se_log('get', 'ground');
e = se_log('get', 'edge');
des_simevents_regression(g, e, rep);
end
