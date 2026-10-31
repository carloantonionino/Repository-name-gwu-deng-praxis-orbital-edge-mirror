# Session 6 v04 — Execution Gantts and 20,000-run plan
Original: `GWU Dr Hao - Session 6 - Nov 14, 2026 - v04 Execution Gantts 20000 Runs.pptx`
Author: Carlo Antonio Nino
Authority: https://drive.google.com/file/d/16bP0D-gvW-nNBJBbqTyydqsBaPUIFGYz/view
Baseline: v03 preserved. This is a newly revised 32-slide version, not the submitted Session 5 package.

- 14 Nov GOLD Session 6; 05 Dec RED next advisor gate; no Nov 28 review due to Thanksgiving.
- Decomposes Dr Hao's two directed requests: Chapter 2 concision and concurrent MATLAB methodology.
- Adds planned interface build (App Designer/Live Script), input/seed manifest, 100-case smoke, 1,000-run pilot, and 20,000 architecture executions (10,000 matched Ground/Edge scenarios). These are NOT claimed as completed.
- Restores/preserves ACE simultaneity Venn and original presentation styling.
- Clarifies that 91 means counted Chapter 2 bibliography entries, not 91 verified in-text citations. A/C/E denote source data domains.
- Report PDF copied to Session 6 folder and also retained in central Report Cards archive.

## Binary reconstruction
The GitHub connector required lossless Base64 text segments. Concatenate in ascending part order:
```bash
cat s6_v04.pptx.part{00..15}.b64 | base64 --decode > "GWU Dr Hao - Session 6 - Nov 14, 2026 - v04 Execution Gantts 20000 Runs.pptx"
sha256sum "GWU Dr Hao - Session 6 - Nov 14, 2026 - v04 Execution Gantts 20000 Runs.pptx"
```
Expected SHA-256: `b5f9db160e4084a03ebde37d25f7cc0b61d985d512375863dea5b90623e282c3`
Expected bytes: `18072844`. Part count: 16; parts 00..14 are 1,600,000 text characters each; part 15 is 97,128 characters.
