#!/usr/bin/env python3
"""Build only reviewed public website files, independently of the app bundle."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'build' / 'site'
SITE_FILES = ('index.html', 'en/index.html', 'style.css', 'app.js', 'assets/icon.png')


def main():
    if OUTPUT.is_symlink():
        raise SystemExit('Website output must not be a symlink')
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    for name in SITE_FILES:
        source = ROOT / 'site' / name
        if source.is_symlink():
            raise SystemExit(f'Unexpected symlink: site/{name}')
        target = OUTPUT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    for theme in ('dark', 'light'):
        shutil.copyfile(ROOT / 'docs' / 'images' / f'preview-{theme}.png',
                        OUTPUT / 'assets' / f'preview-{theme}.png')
    (OUTPUT / '.nojekyll').touch()
    print('Website built in build/site')


if __name__ == '__main__':
    main()
