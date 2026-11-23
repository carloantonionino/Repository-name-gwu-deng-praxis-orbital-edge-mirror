function S = des_scenarios(M, dataDir)
%DES_SCENARIOS  Run the five controlled cases from the workbook Sensitivity tab.

S = des_load_scenarios(dataDir);
k = numel(S.name);
S.gMean   = zeros(k, 1);
S.eMean   = zeros(k, 1);
S.gWithin = zeros(k, 1);
S.eWithin = zeros(k, 1);
S.gDeliv  = zeros(k, 1);
S.eDeliv  = zeros(k, 1);
S.perRepG = zeros(M.cfg.replications, k);
S.perRepE = zeros(M.cfg.replications, k);

for j = 1:k
    T = des_replicate(M, S.rawMb(j), S.gMeanIn(j), S.eMeanIn(j), S.fraction(j), 0);
    S.gMean(j)   = mean(T.gMean);
    S.eMean(j)   = mean(T.eMean);
    S.gWithin(j) = mean(T.gWithin);
    S.eWithin(j) = mean(T.eWithin);
    S.gDeliv(j)  = mean(T.gDeliv);
    S.eDeliv(j)  = mean(T.eDeliv);
    S.perRepG(:, j) = T.gMean;
    S.perRepE(:, j) = T.eMean;
end
end
