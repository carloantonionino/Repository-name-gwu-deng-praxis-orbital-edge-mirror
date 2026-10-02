# GWU D.Eng. Praxis — Modeling Orbital Edge Processing

**Public research repository for verification, reproducibility, continuity, and configuration control.**

This repository is the public GitHub mirror of Carlo Antonio Nino's George Washington University Doctor of Engineering (D.Eng.) Praxis research project:

> **Modeling Orbital Edge Processing in Degraded Communications**

## Purpose

This repository provides an independent public copy of the Praxis research structure and supporting artifacts so that reviewers, collaborators, and future researchers can inspect the work without depending on a single cloud provider.

The working research environment is maintained in Google Drive. GitHub serves as a second cloud repository with version history, stable public references, and reproducibility-oriented organization.

## Research scope

The Praxis compares:

- **Architecture A — Ground-centric processing**
- **Architecture B — Bounded orbital edge processing**

using discrete-event simulation (DES) to examine performance under normal, degraded, intermittent/outage, and surge conditions.

Primary measures include end-to-end latency, service availability, downtime/recovery, packet loss, queue delay, throughput, bandwidth demand, dropped/stale observations, processing delay, and event-to-decision timing.

## Repository architecture

```text
00 — README & Governance/
00A — Registers & Configuration Control/
01 — Advisor & Administrative/
02 — Literature & Chapter 2/
03 — Data Sources — Raw/
04 — Data Normalization & Fusion/
05 — DES Models & Experiments/
06 — MATLAB & SimEvents/
07 — Figures, OV-1 & Visuals/
08 — Peer Review Red Cell/
09 — Outputs, Results & Validation/
10 — Final Praxis Deliverables/
ARCHIVE — SUPERSEDED WORKING COPIES/
```

Empty research branches are preserved with placeholder files so the GitHub structure remains congruent with the working repository.

## Provenance and mirroring

- **Primary working repository:** Google Drive
- **Public continuity / verification repository:** this GitHub repository
- Source artifacts retain their original filenames wherever practical.
- Superseded versions are retained when they provide configuration-history value.
- Third-party artifacts remain subject to their original copyright and licensing terms.
- Public availability of a source does not by itself imply a grant of redistribution rights.

## Data handling

This repository is intended for public, unclassified, non-proprietary academic research. Restricted, proprietary, classified, or sensitive personal information is outside the intended scope of the repository.

## Configuration-control principle

Changes committed here provide a public history of the research baseline. Where the Google Drive working copy and GitHub differ temporarily, the most recent configuration-controlled research artifact should be identified through the register/version naming and commit history.

## Author

**Carlo Antonio Nino**  
Doctor of Engineering (D.Eng.), Systems Engineering  
The George Washington University

Advisor: **Dr. Hanson Hao**

---

Repository initialized: 2026-10-02.
