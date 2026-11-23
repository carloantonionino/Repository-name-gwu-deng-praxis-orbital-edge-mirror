function S = des_load_scenarios(dataDir)
%DES_LOAD_SCENARIOS  Read the five controlled cases from the Sensitivity tab.

fid = fopen(fullfile(dataDir, 'scenarios.csv'), 'r');
if fid < 0
    error('des:file', 'Cannot open scenarios.csv. Keep the data folder beside the code.');
end
fgetl(fid);
C = textscan(fid, '%s%f%f%f%f', 'Delimiter', ',');
fclose(fid);
S.name     = C{1};
S.rawMb    = C{2};
S.gMeanIn  = C{3};
S.eMeanIn  = C{4};
S.fraction = C{5};
end
