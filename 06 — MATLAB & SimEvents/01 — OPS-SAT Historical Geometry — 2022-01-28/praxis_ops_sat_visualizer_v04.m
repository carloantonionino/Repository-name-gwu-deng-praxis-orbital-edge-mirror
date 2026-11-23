function results = praxis_ops_sat_visualizer_v04()
% PRAXIS_OPS_SAT_VISUALIZER_V04 - OPS-SAT ACE geometry dashboard (08 Nov 2026)
% One historical spacecraft, NORAD 44878. Four observer identities.
% Historical TLE near 2022-01-28. Verified Network sites and two approximate
% SiDS six-character Maidenhead grid centers are displayed differently.
%
% Does not estimate received signal strength, packet loss, link throughput,
% propagation-time measurements, solar-weather causation or DES latency.
% Does not change the original 600-s up / 120-s down validated DES baseline.
%
% Requires the *locally produced* v03 CSV, never synthesizes pass results.
% MATLAB R2026a Aerospace Toolbox satelliteScenario required.

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end

registerFile = fullfile(here, 'OPS_SAT_ACE_100_Witness_Qualification_Register_v01.csv');
resultFile = fullfile(here, 'SiDS_90_Geometry_Sensitivity_v03.csv');
tleFile = fullfile(here, 'OPS_SAT_44878_SELECTED_2022-01-28.tle');
siteFile = fullfile(here, 'Ground_Site_Evidence_v01.csv');
if ~isfile(siteFile)
    siteFile = fullfile(fileparts(here), 'Ground_Site_Evidence_v01.csv');
end
netFile = fullfile(fileparts(here), 'ID_Verified_Reception_Geometry_Check_v02.csv');

assert(isfile(registerFile), 'Missing 100-witness source register in v04 folder.');
assert(isfile(resultFile), ['Missing the v03 results CSV. Run ' ...
    'praxis_check_90_sids_v03 first; do NOT substitute an expected CSV.']);
assert(isfile(tleFile), 'Missing the historical 2022 OPS-SAT TLE.');
rawTLE = fileread(tleFile);
assert(contains(rawTLE,'1 44878U 19092F') && contains(rawTLE,'2 44878'), ...
    'TLE identity changed: expected original OPS-SAT NORAD 44878, 2019-092F.');
assert(isfile(siteFile), 'Missing v02 Ground_Site_Evidence_v01.csv.');
assert(~isempty(which('satelliteScenario')), 'satelliteScenario unavailable. Check Aerospace Toolbox.');

W = readtable(registerFile, 'TextType', 'string');
R = readtable(resultFile, 'TextType', 'string');
S = readtable(siteFile, 'TextType', 'string');
assert(height(W) == 100 && numel(unique(W.ace_entity)) == 100, ...
    'Frozen input must have exactly 100 unique ACE entities.');
assert(all(str2double(string(W.norad_cat_id)) == 44878), 'Unexpected NORAD ID.');
routes = lower(strtrim(W.source_route));
assert(nnz(routes == "sids") == 90 && nnz(routes == "network") == 10, ...
    'Expected 90 SiDS and 10 Network ACE rows.');
assert(height(R) == 90 && numel(unique(R.ace_entity)) == 90, ...
    'v03 result must have exactly 90 unique entity IDs.');
[member, rr] = ismember(W.ace_entity(routes == "sids"), R.ace_entity);
assert(all(member), 'Not all 90 SiDS source entities match v03 results.');
assert(all(W.radio_witness_utc(routes == "sids") == R.radio_witness_utc(rr)), ...
    'v03 output timestamps disagree with original SatNOGS source register.');

% Keep verified IDs separate from provisional grid-based geometry.
status = repmat("NETWORK_RESULT_NOT_PRESENT", 100, 1);
sidsIdx = find(routes == "sids");
status(sidsIdx) = string(R.geometry_classification(rr));
networkIdx = find(routes == "network");
if isfile(netFile)
    N = readtable(netFile, 'TextType', 'string');
    assert(height(N) == 10, 'Network v02 CSV must have 10 ACE rows.');
    [present, ni] = ismember(W.ace_entity(networkIdx), N.entity);
    assert(all(present), 'Network v02 CSV entity IDs fail to match the cohort.');
    status(networkIdx) = string(N.geometry_status(ni));
else
    warning(['ID_Verified_Reception_Geometry_Check_v02.csv not found in parent. ' ...
        'Network status will be recorded as unknown, not as PASS.']);
end

nRobust = nnz(status == "INSIDE_ALL_ASSUMPTIONS");
nSensitive = nnz(status == "SENSITIVE_TO_GRID_OR_MASK");
nOutside = nnz(status == "OUTSIDE_ALL_ASSUMPTIONS");
n0 = nnz(ismember(lower(string(R.center_mask0_within)),["true" "1"]));
n10 = nnz(ismember(lower(string(R.center_mask10_within)),["true" "1"]));
assert(nRobust + nSensitive + nOutside == 90, ...
    'Unrecognized or missing v03 geometry classification; check output CSV.');
nNetworkOK = nnz(status == "WITHIN_PREDICTED_ACCESS");
nNetworkOther = 10 - nNetworkOK;
if nRobust ~= 74 || nSensitive ~= 16 || nOutside ~= 0
    warning('Current v03 counts differ from the screenshot baseline 74/16/0. Investigate before reporting.');
end

% One ACE row may share a SatNOGS reception/frame with another ACE row.
% Source-row identity is retained; these are not 100 independent RF events.
[uSourceRows, first] = unique(W.source_json_row_1based, 'stable');
nUniqueRadio = numel(uSourceRows);
nUniqueSiDS = numel(unique(W.source_json_row_1based(routes == "sids")));
nUniqueNetwork = numel(unique(W.source_json_row_1based(routes == "network")));
assert(nUniqueRadio == 50 && nUniqueSiDS == 45 && nUniqueNetwork == 5, ...
    'Unique 2022 radio witness count differs from source-controlled 50/45/5.');

% Export a reconciled table; never overwrite the historical source CSVs.
results = W;
results.geometry_classification_v04 = status;
results.geometry_evidence_tier = repmat("SiDS: provisional grid / assumed mask", 100, 1);
results.geometry_evidence_tier(networkIdx) = "Network: recorded station ID / published current profile";
outFile = fullfile(here, 'ACE_100_Geometry_Classification_v04.csv');
writetable(results, outFile);

fprintf('\n==========================================================\n');
fprintf('OPS-SAT 44878 | ACE historical geometry visualizer v04\n');
fprintf('One satellite; %d ACE rows; %d distinct radio records\n', height(W), nUniqueRadio);
fprintf('Network: 10 ACE rows from %d distinct receptions: %d within geometry; %d other\n', ...
    nUniqueNetwork, nNetworkOK, nNetworkOther);
fprintf('SiDS: 90 ACE rows from %d distinct receptions\n', nUniqueSiDS);
fprintf('Per-record SiDS: %d robust / %d sensitive / %d outside all\n', ...
    nRobust/2, nSensitive/2, nOutside/2);
% Prior audit established each distinct SiDS record is paired with 2 ACE rows;
% check the mapping below rather than silently assuming independence.
for sourceRow = unique(W.source_json_row_1based(routes == "sids"))'
    ixSource = W.source_json_row_1based == sourceRow;
    assert(nnz(ixSource) == 2 && numel(unique(status(ixSource))) == 1, ...
        'SiDS reception-to-ACE mapping no longer has two concordant rows.');
end
fprintf('0-degree grid center: %d/90 within predicted access\n', n0);
fprintf('10-degree grid center: %d/90 within predicted access\n', n10);
fprintf('All 10 sensitivity assumptions: %d robust, %d sensitive, %d outside all\n', ...
    nRobust, nSensitive, nOutside);
fprintf('Exported: %s\n', outFile);
fprintf('CAUTION: Geometry is not a measured link budget, radio outage, or latency.\n');
fprintf('==========================================================\n\n');

% =========================================================== 3D VISUALIZER
startUTC = datetime(2022,1,28,17,42,49,'TimeZone','UTC');
endUTC   = datetime(2022,1,28,17,54,19,'TimeZone','UTC');
sc = satelliteScenario(startUTC,endUTC,1);
sat = satellite(sc,tleFile,'Name','OPS-SAT 44878 (historical TLE)', ...
    'OrbitPropagator','sgp4');
sat.MarkerColor = [0.19 0.83 0.99];
sat.MarkerSize = 10;

siteNames = ["ESA ESTEC [ID839]"; "DL5FAB [ID2504]"; ...
    "EA6TC [JM19jn PROVISIONAL]"; "EU1XX [KO33ru PROVISIONAL]"];
lat = zeros(4,1); lon = zeros(4,1);
alt = zeros(4,1); minEl = zeros(4,1);
stationId = [839;2504];
for k = 1:2
    idNum = str2double(string(S.public_profile_station_id));
    j = find(idNum == stationId(k),1);
    assert(~isempty(j),'Verified station ID %d is missing from station evidence CSV.',stationId(k));
    lat(k) = str2double(string(S.lat_deg(j)));
    lon(k) = str2double(string(S.lon_deg(j)));
    alt(k) = str2double(string(S.altitude_m(j)));
    minEl(k) = str2double(string(S.min_elevation_deg(j)));
end
[lat(3),lon(3)] = gridCenter6("JM19jn");
[lat(4),lon(4)] = gridCenter6("KO33ru");
% No demonstrated historic mask or precise ground elevation for SiDS.
% The 10-degree values below are DISPLAY ASSUMPTIONS, not verified metadata.
alt(3:4) = 0;
minEl(3:4) = 10;

siteColors = [0.20 0.84 0.53; 0.20 0.84 0.53; ...
              1.00 0.65 0.19; 1.00 0.65 0.19];
G = cell(4,1); A = cell(4,1);
for k = 1:4
    G{k} = groundStation(sc,lat(k),lon(k), ...
        'Altitude',alt(k),'MinElevationAngle',minEl(k), ...
        'Name',char(siteNames(k)));
    G{k}.MarkerColor = siteColors(k,:);
    G{k}.MarkerSize = 9;
    A{k} = access(sat,G{k});
    A{k}.LineColor = siteColors(k,:);
    A{k}.LineWidth = 2;
    t = accessIntervals(A{k});
    nameForFile = sprintf('v04_access_site_%d',k);
    writetable(t,fullfile(here,[nameForFile '.csv']));
    fprintf('%s: %d predicted access interval(s), threshold %.1f deg.\n', ...
        char(siteNames(k)),height(t),minEl(k));
end
viewer = satelliteScenarioViewer(sc);
show(sat);
for k = 1:4
    show(G{k});
    show(A{k});
end
% Orbital ground track highlights the same one spacecraft (not a constellation).
try
    groundTrack(sat,'LeadTime',600,'TrailTime',600);
catch err
    fprintf('Ground-track display skipped: %s\n',err.message);
end
play(sc);

% ============================================================ EVIDENCE FIGURE
fig = figure('Name','OPS-SAT ACE historical geometry evidence v04', ...
    'Color',[0.09 0.15 0.24],'Position',[90 80 1050 700]);
tiledlayout(fig,2,1,'Padding','compact','TileSpacing','compact');
ax1 = nexttile;
counts = [nNetworkOK nRobust nSensitive nOutside];
b = bar(ax1,counts,'FaceColor','flat');
b.CData = [0.20 0.84 0.53; 0.24 0.74 0.96; 1.00 0.65 0.19; 0.94 0.33 0.36];
set(ax1,'XTickLabel',{'Network: access','SiDS: robust','SiDS: sensitive','SiDS: outside'});
ylabel(ax1,'ACE rows');
title(ax1,'Geometry classification by source tier (not RF performance)');
grid(ax1,'on');
ax2 = nexttile;
allTime = datetime(W.radio_witness_utc,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
labels = ["ESA Academy @ESTEC"; "DL5FAB VHF/UHF"; "EA6TC"; "EU1XX"];
labelsY = zeros(height(W),1);
for k = 1:numel(labels)
    labelsY(W.callsign == labels(k)) = k;
end
assert(all(labelsY>0),'Unexpected callsign in the frozen ACE register.');
firstRow = first(:);
for k = 1:4
    mask = labelsY(firstRow) == k;
    scatter(ax2,allTime(firstRow(mask)),labelsY(firstRow(mask)),40, ...
        'MarkerFaceColor',siteColors(k,:), ...
        'MarkerEdgeColor','none');
    hold(ax2,'on');
end
set(ax2,'YTick',1:4,'YTickLabel',{'ESTEC (ID839)','DL5FAB (ID2504)', ...
    'EA6TC grid center','EU1XX grid center'},'YLim',[.5 4.5]);
xlabel(ax2,'Original radio reception UTC, January 28, 2022');
title(ax2,sprintf('%d distinct reception records underlying %d ACE telemetry rows', ...
    nUniqueRadio,height(W)));
grid(ax2,'on');
try
    exportgraphics(fig,fullfile(here,'ACE_100_Reception_Timeline_v04.png'),'Resolution',180);
catch err
    fprintf('PNG export skipped: %s\n',err.message);
end
fprintf('Viewer colors: GREEN = recorded Network station ID; AMBER = SiDS grid estimate.\n');
fprintf('See ACE_100_Geometry_Classification_v04.csv for row-level status.\n');
end

function [lat,lon] = gridCenter6(grid)
% Six-character Maidenhead locator, using midpoint of its 1/24 by 1/12 deg cell.
g = upper(char(grid));
assert(numel(g)==6 && all(g(1:2)>='A' & g(1:2)<='R') && ...
    all(g(3:4)>='0' & g(3:4)<='9') && ...
    all(g(5:6)>='A' & g(5:6)<='X'), 'Invalid Maidenhead locator');
lon = -180 + (double(g(1))-double('A'))*20 + ...
    str2double(g(3))*2 + (double(g(5))-double('A'))/12 + 1/24;
lat = -90 + (double(g(2))-double('A'))*10 + ...
    str2double(g(4)) + (double(g(6))-double('A'))/24 + 1/48;
end
