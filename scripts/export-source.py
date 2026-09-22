#!/usr/bin/env python3
"""Build a reviewed source archive without local settings, Git metadata or build output."""
import subprocess
import sys
import zipfile
from project_files import ROOT, source_files, version

subprocess.run([sys.executable, str(ROOT / 'scripts/privacy-check.py')], check=True, cwd=ROOT)
release = ROOT / 'dist' / version()
release.mkdir(parents=True, exist_ok=True)
prefix = f'ChatGPT-Proxy-Launcher-{version()}'
archive = release / f'{prefix}-source.zip'
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
    for path in source_files():
        info = zipfile.ZipInfo(f'{prefix}/{path.relative_to(ROOT).as_posix()}', date_time=(2026, 1, 1, 0, 0, 0))
        info.create_system = 3
        info.external_attr = 0o100644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        output.writestr(info, path.read_bytes())
print(f'Exported dist/{version()}/{archive.name}')
