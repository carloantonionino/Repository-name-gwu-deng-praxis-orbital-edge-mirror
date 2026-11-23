function s = des_rep_stats(D)
%DES_REP_STATS  Summarise one architecture over one replication.

affected = D.recovery > 0;
s.mean     = mean(D.latency);
s.median   = median(D.latency);
s.p90      = des_percentile(D.latency, 0.9);
s.wait     = mean(D.wait);
if any(affected)
    s.recov = mean(D.recovery(affected));
else
    s.recov = 0;
end
s.affected = sum(affected);
s.deliv    = mean(D.delivered);
s.within   = mean(D.within);
s.last     = max(D.done);
end
