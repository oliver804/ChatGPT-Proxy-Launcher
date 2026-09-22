#!/usr/bin/env python3
"""Conservative release checks; do not print matching credentials or personal data."""
import argparse
import re
import subprocess
import sys
from pathlib import Path
from project_files import ROOT, source_files

PATTERNS = {
    'personal home path': re.compile(rb'/(?:Users|home)/[A-Za-z0-9_.-]+/'),
    'machine temporary path': re.compile(rb'/(?:private/)?var/folders/[A-Za-z0-9_-]+/'),
    'private key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'access token': re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}|sk-[A-Za-z0-9_-]{24,})'),
    'authenticated URL': re.compile(rb'https?://[^\s/<>"\x00]+:[^\s/<>"\x00]+@'),
    'private IPv4': re.compile(rb'\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})\b'),
}
EMAIL = re.compile(rb'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b')
APPROVED_EMAIL = b'oliver804x@gmail.com'


def inspect(paths, root):
    failures = []
    for path in paths:
        if path.is_symlink():
            failures.append((str(path.relative_to(root)), 'unexpected symlink'))
            continue
        data = path.read_bytes()
        label = str(path.relative_to(root))
        for name, pattern in PATTERNS.items():
            if pattern.search(data):
                failures.append((label, name))
        if any(match != APPROVED_EMAIL for match in EMAIL.findall(data)):
            failures.append((label, 'unapproved email address'))
    return failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bundle', type=Path)
    args = parser.parse_args()
    if args.bundle:
        root = args.bundle.resolve()
        paths = sorted(path for path in root.rglob('*') if path.is_file())
        if not paths:
            raise SystemExit('Bundle is missing or empty')
        failures = inspect(paths, root)
    else:
        paths = source_files()
        failures = inspect(paths, ROOT)
        # A tracked file outside the export boundary must be reviewed before publication.
        if (ROOT / '.git').exists():
            tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).split(b'\0')
            allowed = {str(path.relative_to(ROOT)) for path in paths}
            for entry in tracked:
                if entry and entry.decode() not in allowed:
                    failures.append((entry.decode(), 'tracked file outside source allowlist'))
    for path, reason in failures:
        print(f'FAIL: {path}: {reason}', file=sys.stderr)
    if failures:
        return 1
    print(f'PASS: privacy patterns checked in {len(paths)} files; only the approved author email is allowed.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
