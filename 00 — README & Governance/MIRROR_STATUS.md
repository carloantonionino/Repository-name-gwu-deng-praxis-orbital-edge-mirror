# Mirror Status

Last initial synchronization pass: **2026-10-02**

## Status

The public GitHub repository is initialized and the Green Praxis directory architecture has been reproduced, including the numbered 00–10 branches, configuration-control area, advisor meeting folders, raw-data branches, DES lineage, figures, peer-review, results, final-deliverables, and archive branches.

Core research artifacts already mirrored include:

- Current AIS and International/Domestic Research Data configuration-control registers
- Current Chapter 2 draft
- 03 Oct 2026 advisor update and advisor working package
- SatNOGS raw JSON
- NASA OMNI environmental raw text + format definition
- OPS-SAT AI/ML package metadata, notebooks, and dataset.csv
- CINC environmental archives transferred within connector limits
- A-C-E DES workbook lineage, including original baseline, A/C/E data fits, hybrid prototype, qualified COMM fit, dashboard, and presentation snapshot
- Current normalization/fusion workbooks
- Peer Review Red Cell register
- Current OV-1, hypothesis, and data-fusion visual artifacts

## Large raw artifacts pending direct/LFS transfer

The following source artifacts are valid GitHub-size files but exceeded the current ChatGPT cross-service connector handoff envelope during this pass:

- `analysis_data_Osnabrück.csv` — approximately 22.3 MB
- `segments.csv` — approximately 19.0 MB
- `coe-us.team-probing.c013252.20250727.warts.gz` — approximately 8.7 MB

These should be transferred through a direct Git/Git LFS workflow rather than the connector's base64/HTTP handoff.

## Mirror principle

Google Drive remains the active collaboration/working environment. This GitHub repository is the independent public continuity, configuration-control, verification, and reproducibility repository.

The structure is intentionally preserved even when a branch is currently empty.
