# OPS-SAT ACE observer qualification — November 8, 2026

The CSV `OPS_SAT_ACE_100_Witness_Qualification_Register_v01.csv` joins exactly 100 qualified `ace_provenance.csv` records to the original 2022 SatNOGS DB archived telemetry JSON using the recorded 1-based `witness_json_row` index and verified witness timestamps.

- 10 `app_source=network` frames: station ID and observation ID recorded (4 ESA Academy ESTEC 839, 6 DL5FAB 2504). MATLAB v02 reports geometry agreement for these.
- 90 `app_source=sids` frames: 46 `EA6TC-JM19jn`; 44 `EU1XX-KO33ru`. The archive supplies observer string, 6-character Maidenhead grid, timestamp and frame, but no observation ID or station ID. Do not assign one by inference.
- `frame_sha256` is a fingerprint of the ASCII hexadecimal frame field, not a checksum of the full JSON entry or proof of RF decode validity.

## Qualification gates

1. Use Maidenhead grid **cell center plus bounds** only for provisional site geometry. Save the original grid, center coordinate, cell size, and confidence.
2. Compute 2022-01-28 access windows against the same 44878 historical TLE; compare all 90 witness timestamps with predicted visibility, including grid-cell corner sensitivity. Label as grid-based evidence, not verified station coordinates.
3. Seek original 2022 receiver-location evidence for EA6TC and EU1XX, through historical station records and/or observer contact, rather than inventing network station IDs.
4. For RF metrics, retrieve source-linked SatNOGS Network observations only where there are authentic observation IDs, check radio artifacts and calibrated units. SiDS decoded frame presence provides successful reception events, **not** total attempted transmissions, packet-loss rate, calibrated RSSI, bit rate, or continuous service availability.
5. Preserve read-only original archives and save a separate geometry experiment; do not replace the validated 600-up/120-down DES baseline.
