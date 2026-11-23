function result = praxis_ops_sat_reception_validation_v05(varargin)
% Match the frozen ACE inputs to provider frames and check historical geometry.
% Does not change DES throughput, outage, processing or latency assumptions.
% RunGeometry=false writes metadata flags only and NEVER labels geometry PASS.
% Supported target: MATLAB R2024b or newer with satelliteScenario available.
here = fileparts(mfilename('fullpath'));
p = inputParser;
addParameter(p, 'InputDir', fullfile(here, 'inputs'), @(x) ischar(x) || isstring(x));
runLabel = char(datetime('now','TimeZone','UTC','Format','yyyyMMdd_HHmmss_SSS'));
addParameter(p, 'OutputDir', fullfile(here, 'outputs',runLabel), @(x) ischar(x) || isstring(x));
addParameter(p, 'RunGeometry', true, @(x) islogical(x) && isscalar(x));
addParameter(p, 'ShowViewer', false, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
inDir = char(p.Results.InputDir);
outDir = char(p.Results.OutputDir);
if ~isfolder(outDir), mkdir(outDir); end
timerID = tic;
W = readStrings(fullfile(inDir, 'OPS_SAT_ACE_100_Witness_Qualification_Register_v01.csv'));
A = readStrings(fullfile(inDir, 'ACE_Observer_Witnesses_100_v01.csv'));
C = readStrings(fullfile(inDir, 'Selected_50_Receptions_Crosswalk_2026-11-11.csv'));
M = readStrings(fullfile(inDir, 'ACE_100_Row_Reception_Map_2026-11-11.csv'));
D = readStrings(fullfile(inDir, 'Network_Observation_Metadata_Differences_2026-11-11.csv'));
F = readStrings(fullfile(inDir, 'Returned_100_Frames_Reconciliation_2026-11-11.csv'));
K = readStrings(fullfile(inDir, 'Visibility_Configurations_v05.csv'));
require(height(W)==100 && numel(unique(W.ace_entity))==100, 'Expected 100 unique ACE entities.');
require(all(W.norad_cat_id=="44878"), 'Wrong spacecraft in ACE inputs.');
require(height(A)==100 && height(M)==100 && height(C)==50 && height(F)==100, 'Record populations changed.');
require(numel(unique(F.("Frame ID")))==100, 'Returned frame IDs are duplicated.');
require(numel(unique(C.source_json_row_1based))==50, 'Selected reception identities are duplicated.');
require(all(str2double(C.ace_row_count)==2), 'Expected two ACE rows per selected reception.');
require(all(ismember(C.match_status, ["MATCHED_METADATA","NOT_IN_RETURNED_EXTRACT"])), 'Unexpected match status.');
[found, ci] = ismember(W.source_json_row_1based, C.source_json_row_1based);
require(all(found), 'ACE-to-reception mapping incomplete.');
[found, mi] = ismember(W.ace_entity, M.ace_entity);
require(all(found) && numel(unique(M.ace_entity))==100, 'ACE map entity IDs disagree.');
[found, ai] = ismember(W.ace_entity, A.entity);
require(all(found) && numel(unique(A.entity))==100, 'Original witness entity IDs disagree.');
require(all(W.source_json_row_1based==M.source_json_row_1based(mi)), 'ACE source-row IDs disagree.');
require(all(W.source_json_row_1based==A.json_row_1_based(ai)), 'Original witness source-row IDs disagree.');
require(all(parseUTC(W.radio_witness_utc)==parseUTC(C.reception_utc(ci))), 'Reception timestamps disagree.');
require(all(parseUTC(W.radio_witness_utc)==parseUTC(A.comm_witness_utc(ai))), 'Original witness timestamps disagree.');
require(all(parseUTC(W.radio_witness_utc)==parseUTC(M.reception_utc(mi))), 'ACE map reception timestamps disagree.');
require(all(W.observer_as_recorded==C.observer_as_recorded(ci)), 'Observer identity disagreement.');
require(all(W.source_route==C.source_route(ci)), 'Source route disagreement.');
require(all(M.returned_frame_id(mi)==C.returned_frame_id(ci)), 'Frame-ID crosswalk disagreement.');
require(all(M.match_status(mi)==C.match_status(ci)), 'Match status crosswalk disagreement.');
require(sum(C.match_status=="MATCHED_METADATA")==49, 'Expected 49 metadata matches.');
require(sum(C.match_status=="NOT_IN_RETURNED_EXTRACT")==1, 'Expected one retained unmatched reception.');
require(all(ismember(C.returned_frame_id(C.match_status=="MATCHED_METADATA"), F.("Frame ID"))), 'Matched frame absent from returned file.');
require(numel(unique(K.config_id))==height(K), 'Visibility configuration IDs duplicated.');
require(all(ismember(K.observer_match_name,C.observer_match_name)), 'Configuration observer not in selected cohort.');
require(all(isfinite(str2double(K.lat_deg))) && all(isfinite(str2double(K.lon_deg))), 'Invalid site coordinates.');
require(all(str2double(K.min_elevation_deg)>=0 & str2double(K.min_elevation_deg)<90), 'Invalid elevation mask.');

C.provider_match_missing = C.match_status=="NOT_IN_RETURNED_EXTRACT";
C.historical_reception_in_original_archive = true(height(C),1);
C.site_metadata_conflict = C.original_observation_id~="" & ismember(C.original_observation_id,D.observation_id);
C.geometry_status = repmat("NOT_RUN",height(C),1);
C.grid_geometry_status = repmat("NOT_APPLICABLE",height(C),1);
C.provider_coordinate_status = repmat("NOT_APPLICABLE",height(C),1);
C.configuration_tests = zeros(height(C),1);
C.configuration_tests_inside = zeros(height(C),1);
C.visibility_sensitive_to_site_or_mask = false(height(C),1);
C.geometry_evidence = repmat("SiDS declared grid / rounded provider position; assumed altitude and masks",height(C),1);
C.geometry_evidence(C.source_route=="network") = "Historical Network observation / client fields; mask assumptions explicitly tested";
summary = struct('archive_date','2026-11-11','matlab_release',version('-release'), ...
    'matlab_version',version,'ace_rows',height(W),'distinct_selected_receptions',height(C), ...
    'returned_frames',height(F),'matched_selected_receptions',49, ...
    'unmatched_selected_receptions',1,'matched_ace_rows',sum(~C.provider_match_missing(ci)), ...
    'metadata_conflict_receptions',sum(C.site_metadata_conflict), ...
    'metadata_conflict_ace_rows',sum(C.site_metadata_conflict(ci)), ...
    'geometry_execution_status','NOT_REQUESTED','geometry_method','MATLAB satelliteScenario SGP4; exact-time accessStatus', ...
    'reference_disagreements',NaN,'runtime_seconds',NaN);
summary.caution = ['Successful historical receptions and conditional geometry only. ' ...
    'No inferred packet-loss rate, link capacity, continuous availability or edge-processing performance.'];
result = struct();
if p.Results.RunGeometry
    summary.geometry_execution_status = 'NOT_RUN';
    if isempty(which('satelliteScenario'))
        summary.geometry_execution_status = 'MATLAB_TOOLBOX_UNAVAILABLE';
        writeResults(outDir,W,C,ci,D,summary);
        error('Praxis:ToolboxUnavailable', 'satelliteScenario unavailable; metadata saved, geometry NOT run.');
    end
    tleFile = fullfile(inDir,'OPS_SAT_44878_SELECTED_2022-01-28.tle');
    require(isfile(tleFile), 'Historical TLE is missing.');
    tleText = fileread(tleFile);
    require(contains(tleText,'1 44878U 19092F') && contains(tleText,'2 44878'), 'Wrong TLE spacecraft.');
    tleLines = regexp(strtrim(tleText),'\r\n|\n|\r','split');
    l1 = tleLines{find(startsWith(string(tleLines),'1 '),1)};
    l2 = tleLines{find(startsWith(string(tleLines),'2 '),1)};
    require(tleChecksum(l1) && tleChecksum(l2), 'Historical TLE checksum failed.');
    require(strcmp(l1(19:32),'22028.45452475'), 'Selected historical TLE epoch changed.');
    times = parseUTC(C.reception_utc);
    startUTC = datetime(2022,1,28,17,42,49,'TimeZone','UTC');
    endUTC = datetime(2022,1,28,17,54,19,'TimeZone','UTC');
    require(all(times>=startUTC & times<=endUTC), 'Reception outside frozen historical window.');
    sc = satelliteScenario(startUTC,endUTC,1);
    sat = satellite(sc,tleFile,'Name','OPS-SAT 44878 historical', 'OrbitPropagator','sgp4');
    rows = cell(0,12);
    try
        for k = 1:height(K)
            gs = groundStation(sc,str2double(K.lat_deg(k)),str2double(K.lon_deg(k)), ...
                'Altitude',str2double(K.altitude_m(k)), ...
                'MinElevationAngle',str2double(K.min_elevation_deg(k)), ...
                'Name',char(K.config_id(k)));
            ac = access(sat,gs);
            ix = find(C.observer_match_name==K.observer_match_name(k));
            for j = reshape(ix,1,[])
                within = logical(accessStatus(ac,times(j)));
                require(isscalar(within), 'Expected one access status at one reception time.');
                rows(end+1,:) = {str2double(C.source_json_row_1based(j)), ...
                    char(C.observer_match_name(j)),char(C.reception_utc(j)), ...
                    char(K.config_id(k)),char(K.case_group(k)), ...
                    str2double(K.lat_deg(k)),str2double(K.lon_deg(k)), ...
                    str2double(K.altitude_m(k)),str2double(K.min_elevation_deg(k)), ...
                    within,char(K.evidence_class(k)),char(K.assumption_note(k))}; %#ok<AGROW>
            end
        end
    catch err
        summary.geometry_execution_status = 'FAILED';
        summary.error_identifier = err.identifier;
        summary.error_message = err.message;
        writeResults(outDir,W,C,ci,D,summary);
        rethrow(err);
    end
    names = {'source_json_row_1based','observer','reception_utc','config_id','case_group', ...
        'lat_deg','lon_deg','altitude_m','min_elevation_deg','within_access','evidence_class','assumption_note'};
    G = cell2table(rows,'VariableNames',names);
    for j = 1:height(C)
        ix = G.source_json_row_1based==str2double(C.source_json_row_1based(j));
        pass = G.within_access(ix);
        C.configuration_tests(j) = numel(pass);
        C.configuration_tests_inside(j) = nnz(pass);
        C.geometry_status(j) = classify(pass);
        C.visibility_sensitive_to_site_or_mask(j) = any(pass) && ~all(pass);
        grid = ix & string(G.case_group)=="sids_grid";
        provider = ix & string(G.case_group)=="sids_provider_nominal";
        if any(grid), C.grid_geometry_status(j) = classify(G.within_access(grid)); end
        if any(provider), C.provider_coordinate_status(j) = classify(G.within_access(provider)); end
    end
    refFile = fullfile(here,'reference','SGP4_Reference_Visibility_2026-11-11.csv');
    if isfile(refFile)
        R = readStrings(refFile);
        rkey = R.config_id+"|"+R.source_json_row_1based;
        gkey = string(G.config_id)+"|"+string(G.source_json_row_1based);
        [hasRef,ri] = ismember(gkey,rkey);
        require(all(hasRef) && height(G)==height(R), 'Reference configurations do not match MATLAB cases.');
        refStatus = ismember(lower(R.within_access(ri)),["true","1"]);
        G.reference_disagreement = G.within_access~=refStatus;
        summary.reference_disagreements = nnz(G.reference_disagreement);
        if summary.reference_disagreements>0
            warning('Praxis:ReferenceDifference', '%d geometry cases differ from approximate Python SGP4 reference; inspect margins.',summary.reference_disagreements);
        end
    end
    writetable(G,fullfile(outDir,'MATLAB_Visibility_Cases_v05.csv'));
    summary.geometry_execution_status = 'COMPLETED';
    summary.distinct_receptions_inside_all_tested = nnz(C.geometry_status=="INSIDE_ALL_TESTED_ASSUMPTIONS");
    summary.distinct_receptions_sensitive = nnz(C.geometry_status=="SENSITIVE_TO_TESTED_ASSUMPTIONS");
    summary.distinct_receptions_outside_all_tested = nnz(C.geometry_status=="OUTSIDE_ALL_TESTED_ASSUMPTIONS");
    summary.sids_grid_receptions_inside_all = nnz(C.grid_geometry_status=="INSIDE_ALL_TESTED_ASSUMPTIONS");
    summary.configuration_checks = height(G);
    result.geometry = G;
    result.scenario = sc;
    if p.Results.ShowViewer, satelliteScenarioViewer(sc); end
end
summary.runtime_seconds = toc(timerID);
writeResults(outDir,W,C,ci,D,summary);
result.receptions = C;
result.summary = summary;
result.output_dir = outDir;
fprintf('\nOPS-SAT reception validation v05\n');
fprintf('100 ACE rows | 50 selected receptions | 100 separate provider frames\n');
fprintf('Provider metadata matches: %d/50; unmatched retained: %d\n',summary.matched_selected_receptions,summary.unmatched_selected_receptions);
fprintf('Site metadata conflicts flagged on %d receptions / %d ACE rows\n',summary.metadata_conflict_receptions,summary.metadata_conflict_ace_rows);
fprintf('Geometry execution: %s\nOutput directory: %s\n',summary.geometry_execution_status,outDir);
end

function T = readStrings(path)
assert(isfile(path),'Praxis:InputMissing','Missing input: %s',path);
opts = detectImportOptions(path,'TextType','string','VariableNamingRule','preserve');
opts = setvartype(opts,opts.VariableNames,'string');
T = readtable(path,opts);
for k = 1:width(T)
    v = T.(k);
    v(ismissing(v)) = "";
    T.(k) = v;
end
end

function t = parseUTC(s)
s = erase(replace(string(s)," ","T"),"Z");
t = datetime(s,'InputFormat','yyyy-MM-dd''T''HH:mm:ss','TimeZone','UTC');
require(all(~isnat(t)), 'Unparseable UTC timestamp.');
end

function s = classify(x)
require(~isempty(x), 'No visibility configurations for a selected reception.');
if all(x), s = "INSIDE_ALL_TESTED_ASSUMPTIONS";
elseif any(x), s = "SENSITIVE_TO_TESTED_ASSUMPTIONS";
else, s = "OUTSIDE_ALL_TESTED_ASSUMPTIONS";
end
end

function writeResults(outDir,W,C,ci,D,summary)
E = W;
E.returned_frame_id_v05 = C.returned_frame_id(ci);
E.provider_match_missing_v05 = C.provider_match_missing(ci);
E.site_metadata_conflict_v05 = C.site_metadata_conflict(ci);
E.reception_geometry_status_v05 = C.geometry_status(ci);
E.grid_geometry_status_v05 = C.grid_geometry_status(ci);
E.provider_coordinate_status_v05 = C.provider_coordinate_status(ci);
E.geometry_evidence_v05 = C.geometry_evidence(ci);
writetable(C,fullfile(outDir,'MATLAB_Selected_50_Reception_Check_v05.csv'));
writetable(E,fullfile(outDir,'MATLAB_ACE_100_With_Reception_Check_v05.csv'));
writetable(C(C.provider_match_missing,:),fullfile(outDir,'MATLAB_Unmatched_Reception_Flags_v05.csv'));
writetable(D,fullfile(outDir,'MATLAB_Site_Metadata_Conflicts_v05.csv'));
fid = fopen(fullfile(outDir,'MATLAB_Run_Summary_v05.json'),'w');
assert(fid>0,'Praxis:OutputWrite','Cannot write run summary.');
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
end

function require(tf,msg)
assert(all(tf(:)),'Praxis:InputIntegrity','%s',msg);
end

function tf = tleChecksum(line)
tf = false;
if numel(line)~=69, return; end
s = 0;
for k = 1:68
    c = line(k);
    if c>='0' && c<='9', s = s + double(c)-double('0');
    elseif c=='-', s = s+1;
    end
end
tf = mod(s,10)==str2double(line(69));
end

