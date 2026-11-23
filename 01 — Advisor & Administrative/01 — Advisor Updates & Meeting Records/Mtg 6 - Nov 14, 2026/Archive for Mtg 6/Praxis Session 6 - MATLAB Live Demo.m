%% 1. Set the controlled local folders (run this section first)
root = fullfile('C:\Users\carlo\OneDrive\Desktop\AA GWU PRAXIS', ...
    'PRIME','Mtg 5 - Oct 30, 2026','MATLAB docs','MATLAB V1');
v05Dir = fullfile(root,'OPS_SAT_ACE_Reception_Integration_v05');
v07Dir = fullfile(root,'Blooms v2');
desDir = fullfile(root,'MATLAB_Baseline2_Simultaneous_ACE');
verifiedDir = fullfile(v05Dir,'outputs','20261111_205348_198');
assert(isfolder(verifiedDir),'Frozen v05 output folder not found.');
assert(isfile(fullfile(v07Dir,'praxis_ops_sat_viewer_v07.m')), ...
    'v07 visualizer not found in Blooms v2.');
assert(isfile(fullfile(desDir,'run_all.m')), ...
    'Baseline 2 program not found.');
addpath(v07Dir,desDir);
fprintf('Controlled folders located. No geometry rerun performed.\n');

%% 2. Open the frozen v05 run summary (no recalculation)
S = jsondecode(fileread(fullfile(verifiedDir,'MATLAB_Run_Summary_v05.json')));
fprintf('Receptions: %d | provider matches: %d | sensitive: %d\n', ...
    S.distinct_selected_receptions,S.matched_selected_receptions, ...
    S.distinct_receptions_sensitive);
fprintf('Geometry checks: %d | MATLAB/Python disagreements: %d\n', ...
    S.configuration_checks,S.reference_disagreements);
disp(S.caution);

%% 3. Inspect the evidence exceptions and the SiDS grid cases
R = readtable(fullfile(verifiedDir, ...
    'MATLAB_Selected_50_Reception_Check_v05.csv'),'TextType','string');
assert(height(R)==50,'Expected 50 selected reception records.');
sensitive = contains(string(R.geometry_status),'SENSITIVE');
disp(R(sensitive,{'observer_as_recorded','reception_utc', ...
    'configuration_tests','configuration_tests_inside'}));
D = readtable(fullfile(verifiedDir, ...
    'MATLAB_Site_Metadata_Conflicts_v05.csv'),'TextType','string');
U = readtable(fullfile(verifiedDir, ...
    'MATLAB_Unmatched_Reception_Flags_v05.csv'),'TextType','string');
fprintf('Sensitive receptions: %d | conflicting fields: %d\n', ...
    nnz(sensitive),height(D));
fprintf('Affected Network receptions: %d | unmatched receptions: %d\n', ...
    nnz(R.site_metadata_conflict),height(U));
allGrid = string(R.source_route)=="sids" & ...
    string(R.grid_geometry_status)=="INSIDE_ALL_TESTED_ASSUMPTIONS";
fprintf('SiDS grid receptions inside all tested cases: %d\n',nnz(allGrid));
disp(D);       % Keep BOTH versions of differing metadata.
disp(U(:,{'observer_as_recorded','reception_utc','ace_entities'}));

%% 4. Open the actual January 2022 orbit visualization
v = praxis_ops_sat_viewer_v07('speed',2, ...
    'blooms','satellite','packageDir',v05Dir);
disp(v.rfFacts);  % Example radio power is assumed, NOT measured.
assert(strcmpi(v.sourceOutput,fullfile(verifiedDir, ...
    'MATLAB_Selected_50_Reception_Check_v05.csv')), ...
    'v07 selected a different v05 output. Check before presenting.');
% Leave the 3D viewer open. Camera can be set manually for Europe.

%% 5. Open the geometry evidence figure, separately
praxis_ops_sat_evidence_v06(v);
% This figure shows recorded reception times and geometry sensitivity,
% NOT received signal strength or packet loss.

%% 6. Re-run the original small Ground-versus-Edge DES demonstration
results = run_all('figures',0);  % 100 observations x 10 replications
fprintf('Ground mean: %.3f seconds\n',mean(results.replications.gMean));
fprintf('Edge mean:   %.3f seconds\n',mean(results.replications.eMean));
fprintf('Ground minus Edge: %.3f seconds\n',results.paired.latMean);
fprintf('95%% interval: %.3f to %.3f seconds\n', ...
    results.paired.latLow,results.paired.latHigh);
disp(results.scenarios.name); % Show that some scenarios favor Ground.

%% OPTIONAL 7. Display the SimEvents diagram (not a validation claim)
seDir = fullfile(desDir,'simevents');
if isfile(fullfile(seDir,'ACE_GroundVsEdge.slx'))
    addpath(seDir);
    open_system(fullfile(seDir,'ACE_GroundVsEdge.slx'));
else
    disp('SimEvents model unavailable at expected path; skip.');
end

%% OPTIONAL 8. FIRST test of the separate 2023 storm-context model
% ONLY after confirming the Storm v1 package is extracted locally.
% Storm rateFactor=0.5 is an ASSUMPTION, not measured 2023 radio loss.
stormDir = fullfile(root,'Storm v1');
if isfile(fullfile(stormDir,'RUN_G4_COMPARE_v01.m'))
    addpath(stormDir);
    rStorm = RUN_G4_COMPARE_v01('baselineDir',desDir, ...
        'reps',10,'rateFactor',0.5);
    disp(rStorm.table);
else
    disp('Storm v1 package not found; leave experiment for next session.');
end
