# Session 6 — working advisor-update deck

**Google Drive ASOT:** https://docs.google.com/presentation/d/18mxwjsyiptRFnyYVw5FtNMWQHkFbHsPx/edit

- Title: `GWU Dr Hao - Session 6 - Nov 14, 2026 - v01 Working Advisor Update.pptx`
- Prepared 30 October 2026 from the Session 5 v19 layout; do not treat this as a post-November-14 actual-results report.
- 26 slides; original GWU style, 5-slide advisor structure and supporting appendices preserved. Gantts have current **gold Nov 14** and proposed **red Dec 05** vertical markers; planned tasks are visibly marked as planned.
- Exact bytes: **17,984,795**; SHA-256 **a752f3110cb12d021567e43f91b3921c433366094c3be282e15dfc3e0799207b**.
- This PPTX is mirrored losslessly as 15 consecutive base64 text segments to avoid the connected GitHub binary upload limit. It can be reconstructed using Python 3 after checkout:

```python
from pathlib import Path
import base64, hashlib
parts=sorted(Path('.').glob('s6_v01.pptx.part*.b64'))
assert len(parts)==15
data=base64.b64decode(''.join(x.read_text('ascii') for x in parts),validate=True)
assert len(data)==17984795
assert hashlib.sha256(data).hexdigest()=='a752f3110cb12d021567e43f91b3921c433366094c3be282e15dfc3e0799207b'
Path('GWU Dr Hao - Session 6 - Nov 14, 2026 - v01 Working Advisor Update.pptx').write_bytes(data)
print('Verified exact Drive baseline')
```

**Configuration authority:** Google Drive controls; GitHub mirrors. Record and incorporate Dr Hao's Oct 30 feedback after it is actually received. Do not retroactively label planned November milestones completed.
