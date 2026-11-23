function result = praxis_check_90_sids_v03()
% OPS-SAT 44878 historical geometry: provisional validation of 90 SiDS witnesses.
% Inputs: original qualified ACE 100-row register + historical selected OPS-SAT TLE.
% This does NOT estimate real link throughput, RSSI, loss, or weather causation.
% Grid is an approximate observer location, not a validated station ID.
% Test 5 geographic locations (center and 4 corners) at 0 and 10 degree masks.
% Neither mask is a documented 2022 antenna setting. Results are sensitivities.
here=fileparts(mfilename('fullpath'));
cd(here);
inputFile=fullfile(here,'OPS_SAT_ACE_100_Witness_Qualification_Register_v01.csv');
tleFile=fullfile(here,'OPS_SAT_44878_SELECTED_2022-01-28.tle');
assert(isfile(inputFile),'Missing 100-witness register alongside script.');
assert(isfile(tleFile),'Missing selected historical OPS-SAT TLE alongside script.');
assert(~isempty(which('satelliteScenario')),'satelliteScenario is unavailable.');
W=readtable(inputFile,'TextType','string');
assert(height(W)==100,'Expected exactly 100 frozen ACE witnesses.');
assert(all(W.norad_cat_id==44878),'Unexpected spacecraft NORAD ID.');
route=lower(strtrim(W.source_route));
assert(sum(route=="sids")==90 && sum(route=="network")==10,...
    'The archived 90 SiDS / 10 Network source split has changed.');
idx=find(route=="sids");
studyStart=datetime(2022,1,28,17,42,49,'TimeZone','UTC');
studyEnd=datetime(2022,1,28,17,54,19,'TimeZone','UTC');
sc=satelliteScenario(studyStart,studyEnd,1);
sat=satellite(sc,tleFile,'Name','OPS-SAT 44878','OrbitPropagator','sgp4');
names=["EA6TC";"EU1XX"];
grids=["JM19jn";"KO33ru"];
% Two assumed elevation masks. Sensitivity analyses, NOT 2022 receiver facts.
masks=[0 10];
stationCache=cell(numel(names),5,numel(masks));
for i=1:numel(names)
    [cLat,cLon,halfLat,halfLon]=maidenhead6(grids(i));
    locations=[cLat,cLon;...
        cLat-halfLat,cLon-halfLon;...
        cLat-halfLat,cLon+halfLon;...
        cLat+halfLat,cLon-halfLon;...
        cLat+halfLat,cLon+halfLon];
    for j=1:5
        for k=1:numel(masks)
            gs=groundStation(sc,locations(j,1),locations(j,2),...
                'Altitude',0,'MinElevationAngle',masks(k),...
                'Name',sprintf('%s grid p%d elev%d',char(names(i)),j,masks(k)));
            a=access(sat,gs);
            stationCache{i,j,k}=accessIntervals(a);
        end
    end
end

center0=false(numel(idx),1);
center10=false(numel(idx),1);
testedCount=zeros(numel(idx),1);
classification=strings(numel(idx),1);
for row=1:numel(idx)
    w=W(idx(row),:);
    station=find(names==string(w.callsign),1);
    assert(~isempty(station),'Unexpected SiDS observer identity.');
    assert(string(w.maidenhead_grid)==grids(station),'Grid identity mismatch.');
    t=datetime(string(w.radio_witness_utc),...
        'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
    assert(t>=studyStart && t<=studyEnd,'Witness outside configured window.');
    present=false(5,numel(masks));
    for j=1:5
        for k=1:numel(masks)
            intervals=stationCache{station,j,k};
            if ~isempty(intervals) && height(intervals)>0
                starts=intervals.StartTime;
                ends=intervals.EndTime;
                if isempty(starts.TimeZone),starts.TimeZone='UTC';end
                if isempty(ends.TimeZone),ends.TimeZone='UTC';end
                present(j,k)=any(t>=starts & t<=ends);
            end
        end
    end
    center0(row)=present(1,1);
    center10(row)=present(1,2);
    testedCount(row)=nnz(present);
    if testedCount(row)==numel(present)
        classification(row)="INSIDE_ALL_ASSUMPTIONS";
    elseif testedCount(row)==0
        classification(row)="OUTSIDE_ALL_ASSUMPTIONS";
    else
        classification(row)="SENSITIVE_TO_GRID_OR_MASK";
    end
end
result=table(W.ace_entity(idx),W.callsign(idx),W.maidenhead_grid(idx),...
    W.radio_witness_utc(idx),center0,center10,testedCount,classification,...
    'VariableNames',{'ace_entity','callsign','maidenhead_grid',...
    'radio_witness_utc','center_mask0_within','center_mask10_within',...
    'passes_out_of_10_assumptions','geometry_classification'});
out=fullfile(here,'SiDS_90_Geometry_Sensitivity_v03.csv');
writetable(result,out);
fprintf('\nOPS-SAT 44878 | Historical SiDS witness geometry (provisional)\n');
fprintf('Historical ACE cohort: 100 | SiDS: 90 | Network: 10\n');
fprintf('Checked: %d witnesses x 10 grid/mask assumptions\n',height(result));
fprintf('Center, mask 0 deg: %d/%d within access\n',nnz(center0),height(result));
fprintf('Center, mask 10 deg: %d/%d within access\n',nnz(center10),height(result));
fprintf('Inside all: %d | Sensitive: %d | Outside all: %d\n',...
    nnz(classification=="INSIDE_ALL_ASSUMPTIONS"),...
    nnz(classification=="SENSITIVE_TO_GRID_OR_MASK"),...
    nnz(classification=="OUTSIDE_ALL_ASSUMPTIONS"));
fprintf('Saved: %s\n',out);
fprintf('CAUTION: These are conditional geometry checks, not radio performance measures.\n');
end

function [lat,lon,halfLat,halfLon]=maidenhead6(grid)
g=upper(char(grid));
assert(numel(g)==6,'Expected 6-character Maidenhead grid.');
assert(all(g(1:2)>='A' & g(1:2)<='R'),'Invalid field letters.');
assert(all(g(3:4)>='0' & g(3:4)<='9'),'Invalid square digits.');
assert(all(g(5:6)>='A' & g(5:6)<='X'),'Invalid subsquare letters.');
% Each 6-character subsquare spans 1/12 degree lon, 1/24 degree lat.
lon0=-180+(double(g(1))-double('A'))*20 + ...
    str2double(g(3))*2+(double(g(5))-double('A'))/12;
lat0=-90+(double(g(2))-double('A'))*10 + ...
    str2double(g(4))+(double(g(6))-double('A'))/24;
halfLon=1/24;halfLat=1/48;
lon=lon0+halfLon;lat=lat0+halfLat;
end
