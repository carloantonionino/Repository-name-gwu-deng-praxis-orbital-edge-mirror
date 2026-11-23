function [checks, maxErr] = des_check_bins(dataDir, B, checks, maxErr)
%DES_CHECK_BINS  Regress the histogram counts against the workbook.

X = des_read_numeric(fullfile(dataDir, 'expected_bins.csv'), 4);
err = max(max(abs(B.ground - X(:,3))), max(abs(B.edge - X(:,4))));
checks(end+1, :) = {'Histogram bin counts', err, err == 0};
maxErr = max(maxErr, err);
end
