OPS-SAT / ACE MATLAB RECEPTION INTEGRATION v05
Prepared November 11, 2026

START HERE
1. Download OPS_SAT_ACE_Reception_Integration_v05_2026-11-11.zip.
2. Extract the entire ZIP to a new local folder. Keep inputs/, reference/,
   validation/ and tools/ alongside the MATLAB .m files.
3. In MATLAB R2024b or newer, open that folder and run:
       RUN_RECEPTION_CHECK_v05
   satelliteScenario and SGP4 functionality must be available.
4. Outputs go into a new timestamped subfolder of outputs/. The command
   prints its exact location and stores it in results_v05.output_dir.

WHAT IS INTEGRATED
The new MATLAB entry point loads the original 100-row qualified ACE witness
register, original witness mapping, selected 50-reception crosswalk, separate
100-frame provider extract and historical observation conflicts. It checks
entity/source-row identities, timestamps, observer/source matches, frame IDs,
and the 100 ACE -> 50 reception relationship before propagation.

Nothing is appended to or deleted from the frozen ACE cohort. No locked DES
service times, outages, link capacities, processing delays or queue logic are
modified. This is the next reception-evidence/geometry integration.

The raw evidence and independent reconciliation remain in the Praxis Drive:
https://drive.google.com/drive/folders/1vS9WF7N0SEqsI8RiFzKI3ryKjyTkkIqr
https://drive.google.com/drive/folders/1KvK7mblIp36CN9xu-cUeKtYxBGkDJo5-

VISIBILITY CHECK
The same historical OPS-SAT TLE is propagated using MATLAB satelliteScenario
with SGP4. accessStatus is evaluated at each exact recorded reception time,
not at its related ACE telemetry time and not from a screenshot or pass bound.

42 explicit configurations yield 585 reception/configuration checks:
- Network sites: embedded historical client position, observation API fields
  and unchanged v01 profile coordinates; each at 0/5/10 degree masks.
- SiDS sites: original Maidenhead cell center/four corners at assumed
  sea-level altitude and 0/10 degree masks.
- SiDS nominal two-decimal provider coordinates are checked separately.
  They are not an exact site fix or an uncertainty bound. For the unmatched
  reception, this is the shared observer location from later returned frames.

Network masks are sensitivity assumptions; no historic horizon-mask
calibration is claimed. Earlier v01 masks remain included as cases.

EXPLICIT FLAGS
- provider_match_missing_v05: true on ACE entities 1 and 2. Their original
  EU1XX reception at 2022-01-28 17:42:49 UTC is retained, even though absent
  from the provider's later-starting extract.
- site_metadata_conflict_v05: true on the 10 ACE rows supported by the five
  selected Network receptions. Four differing location/elevation fields are
  retained in the conflict table; no field silently replaces another.
- reception_geometry_status_v05: inside all, sensitive to the tested
  assumptions, or outside all. SiDS grid and provider-coordinate statuses are
  also shown separately. A metadata-only run records NOT_RUN.
- Frame-ID matching remains metadata reconciliation, not an independently
  authenticated comparison of returned payload bytes.

MATLAB OUTPUTS (only created by an actual local run)
MATLAB_Selected_50_Reception_Check_v05.csv
MATLAB_ACE_100_With_Reception_Check_v05.csv
MATLAB_Unmatched_Reception_Flags_v05.csv
MATLAB_Site_Metadata_Conflicts_v05.csv
MATLAB_Visibility_Cases_v05.csv (geometry run only)
MATLAB_Run_Summary_v05.json

A separate timestamped output folder avoids presenting old geometry as the
result of a later metadata-only run. User-supplied OutputDir should also be a
fresh directory.

TESTING STATUS AT DELIVERY
- Source data integrity/population checks: PASS.
- MATLAB static parser/lint, all three .m files: PASS.
- Independent Python SGP4 geometry: 585 checks, 42 configurations.
  42/50 receptions are inside all tested assumptions; 8/50 are sensitive;
  none is outside every tested case. These map to 84/100 and 16/100 ACE rows.
  The SiDS grid-only split reproduces the earlier 74/16/0 ACE-row pattern.
- Native MATLAB execution and included MATLAB unit tests: NOT RUN here;
  this runtime has no licensed MATLAB. No cloud output is labeled as a
  successful MATLAB run.

The Python reference uses SGP4 2.25 and WGS84 site geometry. TEME to pseudo-
Earth-fixed conversion uses Vallado GMST, UTC as UT1 and zero polar motion.
It is an approximate independent comparison, not MATLAB's frame conversion.
Two test cases lie within 0.05 degree of a mask; tiny implementation differences
may affect those cases. The MATLAB run reports reference disagreements for
review rather than silently forcing agreement.

Optional base-MATLAB data/negative tests (do not need satelliteScenario):
    runtests('test_praxis_reception_v05.m')

Optional metadata-only integration:
    r = praxis_ops_sat_reception_validation_v05('RunGeometry',false);

PROVENANCE / LIMITS
Original input files were copied byte-for-byte into this version. The input
manifest provides SHA256 hashes. The old v02/v03/v04 packages remain unchanged.
Independent results are under reference/, never under outputs/.
No packet-loss rate, actual throughput, continuous link availability, solar
weather effect or orbital-edge performance is inferred from geometric access.

Data attribution: SatNOGS Network / SatNOGS DB, Libre Space Foundation.
Provider extract/clarification: Alfredos (fredy) Damkalis.
Source-derived tables: CC BY-SA 4.0 per provider correspondence.
https://creativecommons.org/licenses/by-sa/4.0/

MATLAB API references:
https://www.mathworks.com/help/satcom/ref/matlabshared.satellitescenario.access.accessstatus.html
https://www.mathworks.com/help/aerotbx/ug/matlabshared.satellitescenario.satellitescenario.groundstation.html
https://www.mathworks.com/help/aerotbx/ug/matlabshared.satellitescenario.satellitescenario.satellite.html

