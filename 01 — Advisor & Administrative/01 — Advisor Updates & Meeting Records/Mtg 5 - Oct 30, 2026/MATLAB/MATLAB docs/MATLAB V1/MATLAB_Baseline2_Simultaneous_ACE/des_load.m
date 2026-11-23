function M = des_load(dataDir)
%DES_LOAD  Read the settings, the ACE cohort and the scenario list.

S = des_read_keyvalue(fullfile(dataDir, 'settings.csv'));
C = des_read_numeric(fullfile(dataDir, 'ace_cohort.csv'), 8);

cfg.entities     = S.entities_per_rep;
cfg.replications = S.replications;
cfg.window       = S.assessment_window_s;
cfg.seed         = S.seed_processing;
cfg.a            = S.lcg_a;
cfg.m            = S.lcg_m;
cfg.up           = S.link_up_s;
cfg.down         = S.link_down_s;
cfg.offset       = S.cycle_offset_s;
cfg.cycle        = S.link_up_s + S.link_down_s;
cfg.deadline     = S.deadline_s;
cfg.stale        = S.staleness_s;
cfg.alpha        = S.alpha;
cfg.rawMb        = S.observation_mb;
cfg.groundMean   = S.ground_mean_s;
cfg.edgeMean     = S.edge_mean_s;
cfg.outFraction  = S.output_fraction;

cohort.entity   = C(:,1);
cohort.arrival  = C(:,2);
cohort.rate     = C(:,3);
cohort.prop     = C(:,4);
cohort.rawMb    = C(:,5);
cohort.fraction = C(:,6);
cohort.gMean    = C(:,7);
cohort.eMean    = C(:,8);

if numel(cohort.entity) ~= cfg.entities
    error('des:cohort', 'Cohort has %d rows but settings expect %d.', ...
        numel(cohort.entity), cfg.entities);
end

M = struct('cfg', cfg, 'cohort', cohort, 'settings', S);
end
