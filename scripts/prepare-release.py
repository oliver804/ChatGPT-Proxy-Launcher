#!/usr/bin/env python3
"""Assemble only the three expected, separately validated platform/source assets."""
import hashlib
import shutil
from project_files import ROOT, version

v = version()
expected = {f'Local-Route-Launcher-{v}-arm64.dmg',
            f'Local-Route-Launcher-{v}-windows-x64-setup.exe',
            f'Local-Route-Launcher-{v}-source.zip'}
source = ROOT / 'build/release-assets'
files = [p for p in source.rglob('*') if p.is_file()]
assert len(files) == 3 and {p.name for p in files} == expected, 'Missing, duplicate, or unexpected release asset'
output = ROOT / 'build/release-ready'
if output.exists():
    shutil.rmtree(output)
output.mkdir()
checksums = []
for path in sorted(files, key=lambda p: p.name):
    assert not path.is_symlink() and path.stat().st_size > 1024, 'Invalid release asset'
    shutil.copyfile(path, output / path.name)
    checksums.append(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n')
(output / 'SHA256SUMS.txt').write_text(''.join(checksums))
print('PASS: macOS DMG, Windows installer, source ZIP and combined SHA-256 manifest')
