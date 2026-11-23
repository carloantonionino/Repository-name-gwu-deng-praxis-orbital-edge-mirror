% Run from the extracted v05 package. Existing ACE/DES files are unchanged.
here = fileparts(mfilename('fullpath'));
addpath(here);
results_v05 = praxis_ops_sat_reception_validation_v05('ShowViewer',false);

