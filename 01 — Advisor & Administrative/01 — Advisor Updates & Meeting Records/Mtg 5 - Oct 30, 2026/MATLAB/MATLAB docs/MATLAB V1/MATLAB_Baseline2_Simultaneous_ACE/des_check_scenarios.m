function [checks, maxErr] = des_check_scenarios(dataDir, M, S, checks, maxErr)
%DES_CHECK_SCENARIOS  Regress every scenario and replication against Excel.

tol = 1e-6;
fid = fopen(fullfile(dataDir, 'expected_scenarios.csv'), 'r');
if fid < 0
    error('des:file', 'Cannot open expected_scenarios.csv.');
end
fgetl(fid);
C = textscan(fid, '%s%f%f%f%f%f%f%f', 'Delimiter', ',');
fclose(fid);

names = C{1}; reps = C{2};
expG = C{3}; expE = C{4}; expGd = C{5}; expEd = C{6}; expGn = C{7}; expEn = C{8};

err = 0;
identical = 0;
for k = 1:numel(names)
    j = find(strcmp(S.name, names{k}), 1);
    if isempty(j)
        error('des:scenario', 'Scenario %s is missing from scenarios.csv.', names{k});
    end
    [G, E] = des_run_rep(M, reps(k), S.rawMb(j), S.gMeanIn(j), S.eMeanIn(j), S.fraction(j));
    err = max([err, abs(mean(G.latency) - expG(k)), abs(mean(E.latency) - expE(k)), ...
               abs(mean(G.within) - expGd(k)), abs(mean(E.within) - expEd(k)), ...
               abs(mean(G.delivered) - expGn(k)), abs(mean(E.delivered) - expEn(k))]);
    if strcmp(names{k}, 'IDENTICAL')
        identical = max(identical, abs(mean(G.latency) - mean(E.latency)));
    end
end

checks(end+1, :) = {'Five scenarios, every replication', err, err <= tol};
maxErr = max(maxErr, err);
checks(end+1, :) = {'Identical architectures return zero', identical, identical == 0};
maxErr = max(maxErr, identical);
end
