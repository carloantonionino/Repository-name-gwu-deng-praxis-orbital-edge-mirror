%% OPS-SAT 44878 historical ACE geometry (v02; NASA OMNI / SatNOGS / OPSSAT-AD)
% THIS IS HISTORICAL ORBIT GEOMETRY, NOT A SUBSTITUTE FOR THE LOCKED DES.
% The uploaded source is a 9-element-set CelesTrak-style 3LE text file.
% Source of orbit input: user-supplied sat000044878.txt (archived 2022 TLE).
% Source of station IDs / witnesses: qualified ACE v9 2022-01-28 cohort.
% Stations without a direct recorded station ID remain excluded by default.
% SGP4 visibility is a prediction; test it against observed radio reception.
% Tested in this package: static input integrity/checksums; requires user's
% licensed MATLAB installation to execute satelliteScenario/SGP4 functions.

clearvars -except ans
here = fileparts(mfilename('fullpath'));
if strlength(string(here))==0, here=pwd; end
cd(here);
includeEA6TCcandidate = false;  % Only turn on after historical site verification.
archiveFile = fullfile(here,'sat000044878.txt');
assert(isfile(archiveFile), 'Missing original archived TLE sat000044878.txt.');
assert(~isempty(which('satelliteScenario')), ...
    'satelliteScenario unavailable. Check: ver; which satelliteScenario -all; licenses.');

stations = readtable(fullfile(here,'Ground_Site_Evidence_v01.csv'),TextType='string');
witness = readtable(fullfile(here,'ACE_Observer_Witnesses_100_v01.csv'),TextType='string');
assert(height(witness)==100,'Expected the frozen 100-observation ACE cohort.');
assert(all(str2double(string(witness.sat_norad))==44878),'A non-OPS-SAT NORAD ID was encountered.');
assert(all(ismember(witness.observer_raw,stations.observer_raw)), ...
    'One or more station/observer names do not match the frozen evidence table.');

% Fixed ACE window: source/working-envelope from ACE v9, not a free-running
% or current-orbit visualization.
startUTC=datetime(2022,1,28,17,42,49,'TimeZone','UTC');
endUTC=datetime(2022,1,28,17,54,19,'TimeZone','UTC');
midUTC=startUTC+(endUTC-startUTC)/2;

% Parse all historical sets (name line + L1 + L2), verify NORAD and TLE checksums.
raw=regexp(fileread(archiveFile),'\r\n|\r|\n','split');
epochPosix=[]; goodL1={}; goodL2={};
for k=1:(numel(raw)-1)
    l1=raw{k}; l2=raw{k+1};
    if numel(l1)~=69 || numel(l2)~=69, continue; end
    if ~startsWith(string(l1),'1 44878U 19092F') || ...
       ~startsWith(string(l2),'2 44878'), continue; end
    assert(tleChecksum(l1) && tleChecksum(l2),'Bad TLE checksum in archived record.');
    yy=str2double(l1(19:20)); doy=str2double(l1(21:32));
    assert(isfinite(yy) && isfinite(doy),'Unparseable TLE epoch.');
    if yy<57, yr=2000+yy; else, yr=1900+yy; end
    ep=datetime(yr,1,1,'TimeZone','UTC') + days(doy-1);
    epochPosix(end+1,1)=posixtime(ep); %#ok<SAGROW>
    goodL1{end+1,1}=l1; %#ok<SAGROW>
    goodL2{end+1,1}=l2; %#ok<SAGROW>
end
assert(numel(epochPosix)==9, ...
    'Archive has a different count of valid TLE pairs than the verified nine.');
[ageSec,pick]=min(abs(epochPosix-posixtime(midUTC)));
assert(ageSec <= 3*86400,'No historic TLE epoch within 3 days of the ACE midpoint.');
chosen=datetime(epochPosix(pick),'ConvertFrom','posixtime','TimeZone','UTC');
chosen.Format='yyyy-MM-dd HH:mm:ss.SSS Z';
fprintf('ACE source witnesses: %d; all OPS-SAT (44878).\n',height(witness));
fprintf('TLE sets checked: %d. Selected epoch UTC: %s\n',numel(epochPosix),char(chosen));
fprintf('Epoch separation: %.3f hours from ACE midpoint.\n',ageSec/3600);

% Derived, named three-line subset for MATLAB. Never overwrite original.
selectedFile=fullfile(here,'OPS_SAT_44878_SELECTED_2022-01-28.tle');
fid=fopen(selectedFile,'w');assert(fid>0,'Cannot create selected TLE.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%-24s\r\n%s\r\n%s\r\n','OPS-SAT',goodL1{pick},goodL2{pick});
clear cleanup

% Recreate historical orbit via SGP4. One spacecraft only, not a constellation.
sc=satelliteScenario(startUTC,endUTC,1);
sat=satellite(sc,selectedFile,'Name','OPS-SAT / NORAD 44878', ...
    'OrbitPropagator','sgp4');

% Only these SatNOGS IDs occur in the witness JSON. Current station-site
% coordinates are not proof of station location/configuration in 2022.
comparison=cell(0,5);
for k=1:height(stations)
    rr=stations(k,:);
    include=(str2double(string(rr.geometry_use_default))==1);
    if includeEA6TCcandidate && string(rr.public_profile_station_id)=='1560'
        include=true;
    end
    if ~include
        fprintf('Excluded unverified site: %s\n',char(rr.matlab_name));
        continue;
    end
    if ~isfinite(str2double(string(rr.altitude_m))) || ...
       ~isfinite(str2double(string(rr.min_elevation_deg)))
        fprintf('No altitude/elevation mask for: %s\n',char(rr.matlab_name));
        continue;
    end
    gs=groundStation(sc,str2double(string(rr.lat_deg)), ...
        str2double(string(rr.lon_deg)), ...
        'Altitude',str2double(string(rr.altitude_m)), ...
        'MinElevationAngle',str2double(string(rr.min_elevation_deg)), ...
        'Name',char(rr.matlab_name));
    a=access(sat,gs);
    ti=accessIntervals(a);
    outName=fullfile(here,sprintf('Access_Station_%s_v02.csv', ...
        char(string(rr.public_profile_station_id))));
    writetable(ti,outName);
    fprintf('%s: %d predicted geometric access interval(s).\n', ...
        char(rr.matlab_name),height(ti));

    % Compare ONLY recorded IDs. 90 source rows have null station IDs;
    % do not falsely turn matching callsigns into fully verified stations.
    sid = str2double(string(rr.source_station_id));
    if ~isfinite(sid), continue; end
    wID=str2double(string(witness.source_station_id));
    indices=find(wID==sid);
    for j=reshape(indices,1,[])
        utcString=erase(string(witness.comm_witness_utc(j)),'Z');
        t=datetime(utcString,'InputFormat','yyyy-MM-dd''T''HH:mm:ss', ...
            'TimeZone','UTC');
        status='OUTSIDE_PREDICTED_ACCESS';
        if height(ti)>0
            starts=ti.StartTime; ends=ti.EndTime;
            if isempty(starts.TimeZone), starts.TimeZone='UTC'; end
            if isempty(ends.TimeZone), ends.TimeZone='UTC'; end
            if any(t>=starts & t<=ends), status='WITHIN_PREDICTED_ACCESS'; end
        end
        comparison(end+1,:)={double(witness.entity(j)),char(rr.matlab_name), ...
            char(witness.comm_witness_utc(j)),sid,status}; %#ok<AGROW>
    end
end
if isempty(comparison)
    warning('No ID-verified site observations found for geometry comparison.');
else
    names={'entity','station_name','radio_witness_utc','recorded_station_id','geometry_status'};
    results=cell2table(comparison,'VariableNames',names);
    writetable(results,fullfile(here,'ID_Verified_Reception_Geometry_Check_v02.csv'));
    fprintf('Compared %d source-ID-verified receptions with predicted visibility.\n', ...
        height(results));
    fprintf('DO NOT infer that contact opportunity proves received packets or RF capacity.\n');
end
satelliteScenarioViewer(sc);
play(sc);

function tf=tleChecksum(line)
if numel(line)~=69, tf=false;return; end
s=0;
for ix=1:68
    c=line(ix);
    if c>='0' && c<='9'
        s=s+(double(c)-double('0'));
    elseif c=='-'
        s=s+1;
    end
end
tf=(mod(s,10)==str2double(line(69)));
end
