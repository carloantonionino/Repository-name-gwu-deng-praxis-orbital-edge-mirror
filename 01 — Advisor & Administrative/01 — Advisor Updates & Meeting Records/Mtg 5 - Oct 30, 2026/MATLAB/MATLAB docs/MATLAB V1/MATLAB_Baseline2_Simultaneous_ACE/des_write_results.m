function des_write_results(outDir, T, P, S, B)
%DES_WRITE_RESULTS  Write the MATLAB results as CSV files for review.

f = fopen(fullfile(outDir, 'results_replications.csv'), 'w');
fprintf(f, ['rep,g_mean_s,g_median_s,g_p90_s,g_wait_s,g_recovery_s,g_affected,' ...
            'g_delivered,g_within,g_last_s,e_mean_s,e_median_s,e_p90_s,e_wait_s,' ...
            'e_recovery_s,e_affected,e_delivered,e_within,e_last_s,latency_benefit_s\n']);
for r = 1:numel(T.rep)
    fprintf(f, '%d,%.10f,%.10f,%.10f,%.10f,%.10f,%d,%.10f,%.10f,%.10f,', ...
        T.rep(r), T.gMean(r), T.gMedian(r), T.gP90(r), T.gWait(r), T.gRecov(r), ...
        T.gAffected(r), T.gDeliv(r), T.gWithin(r), T.gLast(r));
    fprintf(f, '%.10f,%.10f,%.10f,%.10f,%.10f,%d,%.10f,%.10f,%.10f,%.10f\n', ...
        T.eMean(r), T.eMedian(r), T.eP90(r), T.eWait(r), T.eRecov(r), T.eAffected(r), ...
        T.eDeliv(r), T.eWithin(r), T.eLast(r), T.gMean(r) - T.eMean(r));
end
fclose(f);

f = fopen(fullfile(outDir, 'results_comparison.csv'), 'w');
fprintf(f, 'metric,value\n');
rows = {'replications', P.n; 'latency_mean_difference_s', P.latMean; ...
        'latency_sd_s', P.latSd; 'latency_se_s', P.latSe; 't_critical', P.tcrit; ...
        'latency_ci_low_s', P.latLow; 'latency_ci_high_s', P.latHigh; ...
        'availability_mean_difference', P.avMean; 'availability_ci_low', P.avLow; ...
        'availability_ci_high', P.avHigh; 'ground_delivered_share', P.gDelivShare; ...
        'edge_delivered_share', P.eDelivShare; 'ground_recovery_wait_s', P.gRecovery; ...
        'edge_recovery_wait_s', P.eRecovery};
for i = 1:size(rows, 1)
    fprintf(f, '%s,%.10f\n', rows{i,1}, rows{i,2});
end
fprintf(f, 'latency_reading,%s\n', P.latReading);
fprintf(f, 'availability_reading,%s\n', P.avReading);
fclose(f);

f = fopen(fullfile(outDir, 'results_scenarios.csv'), 'w');
fprintf(f, 'case,raw_mb,ground_mean_in_s,edge_mean_in_s,output_fraction,');
fprintf(f, 'ground_mean_latency_s,edge_mean_latency_s,difference_s,ground_within,edge_within\n');
for j = 1:numel(S.name)
    fprintf(f, '%s,%.6f,%.6f,%.6f,%.6f,%.10f,%.10f,%.10f,%.10f,%.10f\n', ...
        S.name{j}, S.rawMb(j), S.gMeanIn(j), S.eMeanIn(j), S.fraction(j), ...
        S.gMean(j), S.eMean(j), S.gMean(j) - S.eMean(j), S.gWithin(j), S.eWithin(j));
end
fclose(f);

f = fopen(fullfile(outDir, 'results_bins.csv'), 'w');
fprintf(f, 'bin_from_s,bin_to_s,ground_count,edge_count\n');
for i = 1:numel(B.ground)
    if isinf(B.to(i))
        fprintf(f, '%d,,%d,%d\n', B.from(i), B.ground(i), B.edge(i));
    else
        fprintf(f, '%d,%d,%d,%d\n', B.from(i), B.to(i), B.ground(i), B.edge(i));
    end
end
fclose(f);
end
