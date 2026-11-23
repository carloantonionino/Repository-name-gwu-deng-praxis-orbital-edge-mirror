function tests = test_praxis_reception_v05
% Requires MATLAB base functions only; no satellite toolbox for these tests.
tests = functiontests(localfunctions);
end

function testMetadataMappingAndFlags(testCase)
here = fileparts(mfilename('fullpath'));
out = tempname;
cleaner = onCleanup(@() removeTemp(out)); %#ok<NASGU>
r = praxis_ops_sat_reception_validation_v05('RunGeometry',false,'OutputDir',out);
verifyEqual(testCase,r.summary.ace_rows,100);
verifyEqual(testCase,r.summary.distinct_selected_receptions,50);
verifyEqual(testCase,r.summary.matched_ace_rows,98);
verifyEqual(testCase,nnz(r.receptions.provider_match_missing),1);
verifyEqual(testCase,nnz(r.receptions.site_metadata_conflict),5);
verifyEqual(testCase,string(r.summary.geometry_execution_status),"NOT_REQUESTED");
verifyTrue(testCase,all(r.receptions.geometry_status=="NOT_RUN"));
verifyEqual(testCase,r.receptions.source_json_row_1based(r.receptions.provider_match_missing),"203");
verifyTrue(testCase,isfile(fullfile(out,'MATLAB_ACE_100_With_Reception_Check_v05.csv')));
verifyFalse(testCase,isfile(fullfile(out,'MATLAB_Visibility_Cases_v05.csv')));
end

function testRejectsAlteredTimestamp(testCase)
here = fileparts(mfilename('fullpath'));
root = tempname;
mkdir(root);
copyfile(fullfile(here,'inputs'),fullfile(root,'inputs'));
cleaner = onCleanup(@() removeTemp(root)); %#ok<NASGU>
f = fullfile(root,'inputs','Selected_50_Receptions_Crosswalk_2026-11-11.csv');
s = fileread(f);
s = strrep(s,'2022-01-28T17:42:49Z','2022-01-28T17:42:48Z');
fid = fopen(f,'w'); fprintf(fid,'%s',s); fclose(fid);
verifyError(testCase,@() praxis_ops_sat_reception_validation_v05('RunGeometry',false, ...
    'InputDir',fullfile(root,'inputs'),'OutputDir',fullfile(root,'out')),'Praxis:InputIntegrity');
end

function testRejectsLostACEEntity(testCase)
here = fileparts(mfilename('fullpath'));
root = tempname;
mkdir(root);
copyfile(fullfile(here,'inputs'),fullfile(root,'inputs'));
cleaner = onCleanup(@() removeTemp(root)); %#ok<NASGU>
f = fullfile(root,'inputs','ACE_100_Row_Reception_Map_2026-11-11.csv');
s = fileread(f);
s = regexprep(s,'(?m)^100,','999,');
fid = fopen(f,'w'); fprintf(fid,'%s',s); fclose(fid);
verifyError(testCase,@() praxis_ops_sat_reception_validation_v05('RunGeometry',false, ...
    'InputDir',fullfile(root,'inputs'),'OutputDir',fullfile(root,'out')),'Praxis:InputIntegrity');
end

function removeTemp(p)
if isfolder(p), rmdir(p,'s'); end
end

