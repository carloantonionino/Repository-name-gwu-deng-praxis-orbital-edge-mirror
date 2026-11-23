function p = des_percentile(v, q)
%DES_PERCENTILE  Linear interpolated percentile, matching Excel PERCENTILE.INC.
%   Written out rather than calling prctile so no toolbox is needed.

v = sort(v(:));
n = numel(v);
k = q * (n - 1) + 1;
lo = floor(k);
hi = min(lo + 1, n);
p = v(lo) + (k - lo) * (v(hi) - v(lo));
end
