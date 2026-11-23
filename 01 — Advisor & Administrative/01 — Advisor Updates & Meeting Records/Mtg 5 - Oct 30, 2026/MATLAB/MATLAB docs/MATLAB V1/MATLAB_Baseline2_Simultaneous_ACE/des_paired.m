function P = des_paired(T, alpha)
%DES_PAIRED  Paired difference across replications, with a 95 percent interval.
%   Latency is ground minus edge. Availability is edge minus ground.

latDiff = T.gMean - T.eMean;
avDiff  = T.eWithin - T.gWithin;

n  = numel(latDiff);
df = n - 1;
P.n = n;
P.tcrit = des_tcrit(alpha, df);

P.latMean = mean(latDiff);
P.latSd   = std(latDiff);
P.latSe   = P.latSd / sqrt(n);
P.latHalf = P.tcrit * P.latSe;
P.latLow  = P.latMean - P.latHalf;
P.latHigh = P.latMean + P.latHalf;
P.latReading = des_reading(P.latLow, P.latHigh);

P.avMean = mean(avDiff);
P.avSd   = std(avDiff);
P.avSe   = P.avSd / sqrt(n);
P.avHalf = P.tcrit * P.avSe;
P.avLow  = P.avMean - P.avHalf;
P.avHigh = P.avMean + P.avHalf;
P.avReading = des_reading(P.avLow, P.avHigh);

P.gDelivShare = mean(T.gDeliv);
P.eDelivShare = mean(T.eDeliv);
P.gRecovery   = mean(T.gRecov);
P.eRecovery   = mean(T.eRecov);
end

% ------------------------------------------------------------------------
function r = des_reading(lo, hi)
if lo > 0
    r = 'Interval lies above zero in this demonstration';
elseif hi < 0
    r = 'Interval lies below zero in this demonstration';
else
    r = 'Insufficient evidence: the interval includes zero';
end
end
