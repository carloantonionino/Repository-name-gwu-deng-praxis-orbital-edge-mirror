function B = des_bins(M, runs, width)
%DES_BINS  Common bins for the ground and edge latency histogram.
%   Twelve bins of the given width plus one overflow bin, matching the
%   workbook Latency_Bins tab.

nbins = 12;
g = runs.gLatency(:);
e = runs.eLatency(:);

B.width = width;
B.from  = (0:nbins)' * width;
B.to    = [((1:nbins)' * width); Inf];
B.label = cell(nbins + 1, 1);
B.ground = zeros(nbins + 1, 1);
B.edge   = zeros(nbins + 1, 1);

for i = 1:nbins
    B.ground(i) = sum(g >= B.from(i) & g < B.to(i));
    B.edge(i)   = sum(e >= B.from(i) & e < B.to(i));
    B.label{i}  = sprintf('%d-%d', B.from(i), B.to(i));
end
B.ground(nbins+1) = sum(g >= B.from(nbins+1));
B.edge(nbins+1)   = sum(e >= B.from(nbins+1));
B.label{nbins+1}  = sprintf('>%d', B.from(nbins+1));

B.n = numel(g);
B.gMean = mean(g);
B.eMean = mean(e);
B.gMedian = median(g);
B.eMedian = median(e);
end
