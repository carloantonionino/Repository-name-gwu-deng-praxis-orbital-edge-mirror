# Session 5 current controlled baseline — 30 October 2026

**Source of truth:** Google Drive Session 5, https://drive.google.com/drive/folders/1Hh3ui0klWv9KbdVMbRJOPcJs4bAw8gTp

**Submitted files from GWU to Dr. Hanson Hao on 30 Oct 2026:**

1. `(draft) Chapter 2 - Literature Review - Nino v11 - Oct 28.docx` — stored as a normal DOCX in this Meeting 5 directory; SHA256 `ef08d321545ad9c072db499e346713cd3e264a207a43b40958e18d9b3a68e5ad`; 96,484 bytes.
2. `GWU Dr Hao - Session 5 - Oct 30, 2026 - v19 final.pptx` — 18,351,255 bytes; SHA256 `ef0f860ab7e604b381fdd2e5cf9faa76b369e6e79624c4d546e3e986f72c1a12`; 26 slides.

GitHub connector transfer does not accept a single 18.35 MB PPTX payload, so the **unmodified original PPTX bytes** are preserved as sixteen consecutive base64 TEXT segments in this folder. Concatenate in numeric order, base64-decode, and verify checksum. This is a **lossless segmented mirror**, not a smaller or modified PowerPoint. Do not open a `.part*.b64` file as a PPTX.

Reconstruct on a machine with Python 3 by running in this directory:

```python
from pathlib import Path
import base64, hashlib
parts = sorted(Path('.').glob('v19.pptx.part*.b64'))
assert len(parts) == 16, f'Expected 16 parts; found {len(parts)}'
data = base64.b64decode(''.join(p.read_text('ascii') for p in parts),validate=True)
assert len(data)==18351255
assert hashlib.sha256(data).hexdigest()=='ef0f860ab7e604b381fdd2e5cf9faa76b369e6e79624c4d546e3e986f72c1a12'
Path('GWU Dr Hao - Session 5 - Oct 30, 2026 - v19 final.pptx').write_bytes(data)
print('Exact Drive baseline reconstructed')
```

Previous v15 and older v11 files remain in this repository only as historical snapshots, **not** current Session 5 working baselines. All further changes must originate in the Green Drive and be mirrored with verification.
