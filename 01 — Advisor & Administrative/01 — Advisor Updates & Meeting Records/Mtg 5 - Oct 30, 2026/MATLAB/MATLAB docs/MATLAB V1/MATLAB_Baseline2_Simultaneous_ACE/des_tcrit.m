function t = des_tcrit(alpha, df)
%DES_TCRIT  Two sided t critical value without the Statistics Toolbox.
%   Uses the inverse regularised incomplete beta. If betaincinv is not
%   available, falls back to bisection on betainc, which is always present.

x = [];
try
    x = betaincinv(alpha, df/2, 0.5);
catch
    x = [];
end

if isempty(x) || ~isfinite(x) || x <= 0 || x >= 1
    lo = eps;
    hi = 1 - eps;
    for i = 1:200
        mid = 0.5 * (lo + hi);
        if betainc(mid, df/2, 0.5) < alpha
            lo = mid;
        else
            hi = mid;
        end
    end
    x = 0.5 * (lo + hi);
end

t = sqrt(df * (1 - x) / x);
end
