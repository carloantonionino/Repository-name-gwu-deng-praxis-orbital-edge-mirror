SATNOGS / OPS-SAT RECEPTION RECONCILIATION
Archive and analysis date: November 11, 2026
Historical window: January 28, 2022
============================================================

RESULT
49 of the original 50 distinct selected receptions match Fredy's returned
100-frame extract by exact reception timestamp, observer and source route.
All five selected Network receptions also match their authentic observation
and station IDs. These 49 receptions support 98 of the existing 100 ACE rows.

One selected reception is absent from the returned extract:
EU1XX-KO33ru, 2022-01-28 17:42:49 UTC, original JSON row 203,
supporting ACE entities 1 and 2. It remains present in the original archive.
The returned extract starts 30 seconds later, at 17:43:19 UTC.
This absence is NOT evidence of packet loss or a reason to delete the ACE rows.

The returned extract also has 51 frame records outside the original selected
reception set. They remain a separate broader extract; they have not been
appended to the ACE cohort or used to change the existing model.

THREE DIFFERENT RECORD POPULATIONS
- 100 ACE telemetry rows: the existing qualified analysis cohort.
- 50 distinct reception witnesses: each supports two ACE rows.
- 100 emailed frames: a broader provider extract, with 49 witnesses in common.

JOIN METHOD AND INTEGRITY
The original witness register links to the preserved 560-record source JSON
by a 1-based row number. Each of the 100 ACE links was checked against the
recorded timestamp, observer and saved ASCII-hex-frame SHA256 fingerprint.
The independent 100-row witness CSV was also cross-checked.

Each selected reception was then joined to Fredy's CSV by exact UTC reception
time, source route and observer name. Only a terminal Maidenhead grid was
removed from the archival observer name. Network observation IDs were
also checked; station IDs and reception bounds were validated against the
retrieved observations. All 49 matches were unique. No integrity errors.

This is a METADATA reconciliation. Returned payload byte identity has not
been independently checked: the telemetry API request returned HTTP 401.
No private location was inferred, and no SiDS observer was assigned an
invented Network station ID.

TWO NETWORK OBSERVATIONS RETRIEVED
- Observation 5369438; station 2504, DL5FAB:
  17:45:19-17:51:22 UTC; 18 returned frames, 3 selected receptions,
  6 linked ACE rows.
- Observation 5375671; station 839, ESA Academy @ESTEC:
  17:43:16-17:52:31 UTC; 18 returned frames, 2 selected receptions,
  4 linked ACE rows.

Both API records identify OPS-SAT / NORAD 44878 and status 'good'.
Each includes 18 demodulated-payload links, a waterfall link, archived-audio
link, receiver/client metadata and the historical TLE. The artifact URLs
were catalogued; image/audio/payload bytes were not downloaded.
The configured 9600 baud value is a radio setting, not measured throughput.
These observation intervals are scheduled recording bounds, not proof of
continuous successful service or computed geometric access.

LOCATION DIFFERENCES PRESERVED
DL5FAB: observation latitude 49.8590291 versus embedded-client 49.859291.
ESTEC: observation position 52.217 / 4.423 versus embedded-client
52.2174381 / 4.4228758. Observation altitude 5 m versus client elevation 1 m.
Fredy's Network CSV positions agree with embedded-client latitude/longitude.
No input was silently overwritten. Assess these differences when selecting
geometry inputs; retain the original values and provenance.

RESEARCH USE
These records strengthen historical successful-reception evidence and source
traceability. They do not supply total transmissions attempted, measured
packet-loss rate, continuous availability, calibrated RF quality, complete
end-to-end processing latency, or experimental evidence for an orbital-edge
architecture. Keep modeled communications assumptions explicit.

WHERE THE FILES BELONG
Original correspondence and raw CSV:
https://drive.google.com/drive/folders/1vS9WF7N0SEqsI8RiFzKI3ryKjyTkkIqr
Derived reconciliation:
https://drive.google.com/drive/folders/1KvK7mblIp36CN9xu-cUeKtYxBGkDJo5-
Raw Network observation JSON:
https://drive.google.com/drive/folders/1NgOhr-vk56f_qcMYo3N9cY5X8ynRvf66

DELIVERABLES
Selected_50_Receptions_Crosswalk_2026-11-11.csv: one row per selected reception.
Returned_100_Frames_Reconciliation_2026-11-11.csv: all returned frame IDs.
ACE_100_Row_Reception_Map_2026-11-11.csv: one row per existing ACE entity.
Unmatched_Selected_Receptions_2026-11-11.csv: explicit unmatched record.
Network_Observation_Summary_2026-11-11.csv: receiver/observation summaries.
Network_Observation_Metadata_Differences_2026-11-11.csv: unresolved differences.
Network_Observation_Artifact_Links_2026-11-11.csv: 40 referenced artifact URLs.
Reconciliation_Summary_2026-11-11.json: machine-readable counts and checks.
SOURCE_PROVENANCE_2026-11-11.json: source URLs, dates, hashes and license.
reconcile_satnogs.py: repeatable reconciliation using preserved inputs.
SatNOGS_Reconciliation_2026-11-11.zip: complete reproducibility package.

DATA ATTRIBUTION
SatNOGS Network / SatNOGS DB, Libre Space Foundation. Provider extract and
clarification: Alfredos (fredy) Damkalis. Public data license: CC BY-SA 4.0,
as stated in his reply: https://creativecommons.org/licenses/by-sa/4.0/
Our crosswalks and source-derived summaries retain that attribution/license.
Private correspondence is retained as research provenance, not relabeled
as public CC-licensed content.

REPRODUCTION
Unzip the complete package and run: python3 reconcile_satnogs.py
Uses only Python's standard library. Original source files are not modified.
