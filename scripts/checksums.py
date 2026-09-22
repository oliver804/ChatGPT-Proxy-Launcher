#!/usr/bin/env python3
import hashlib
import sys
from project_files import ROOT, version

release = ROOT / 'dist' / version()
names = [f'ChatGPT-Proxy-Launcher-{version()}-arm64.dmg', f'ChatGPT-Proxy-Launcher-{version()}-source.zip']
text = ''.join(f'{hashlib.sha256((release / name).read_bytes()).hexdigest()}  {name}\n' for name in names)
manifest = release / 'SHA256SUMS.txt'
if '--verify' in sys.argv:
    if manifest.read_text() != text:
        raise SystemExit('Checksum mismatch')
    print('PASS: release checksums')
else:
    manifest.write_text(text)
    print('Wrote release checksums (filenames only; no local paths).')
