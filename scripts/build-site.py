#!/usr/bin/env python3
"""Build only reviewed public website files, independently of the app bundle."""
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'build' / 'site'
SITE_FILES = ('index.html', 'en/index.html', 'style.css', 'app.js', 'assets/icon.png')
BASE_URL = 'https://oliver804.github.io/Local-Route-Launcher/'


def write_sitemap():
    namespace = 'http://www.sitemaps.org/schemas/sitemap/0.9'
    xhtml = 'http://www.w3.org/1999/xhtml'
    ET.register_namespace('', namespace)
    ET.register_namespace('xhtml', xhtml)
    root = ET.Element(f'{{{namespace}}}urlset')
    locales = {'zh-CN': BASE_URL, 'en': BASE_URL + 'en/', 'x-default': BASE_URL}
    for url in (BASE_URL, BASE_URL + 'en/'):
        entry = ET.SubElement(root, f'{{{namespace}}}url')
        ET.SubElement(entry, f'{{{namespace}}}loc').text = url
        for language, href in locales.items():
            ET.SubElement(entry, f'{{{xhtml}}}link',
                          rel='alternate', hreflang=language, href=href)
    # Omit lastmod instead of inventing a modification date at each deployment.
    ET.indent(root)
    ET.ElementTree(root).write(OUTPUT / 'sitemap.xml', encoding='utf-8', xml_declaration=True)


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
    for theme in ('dark', 'light', 'dark.en', 'light.en'):
        shutil.copyfile(ROOT / 'docs' / 'images' / f'preview-{theme}.png',
                        OUTPUT / 'assets' / f'preview-{theme}.png')
    for theme in ('dark', 'light', 'dark.en', 'light.en'):
        shutil.copyfile(ROOT / 'docs' / 'images' / f'windows-{theme}.png',
                        OUTPUT / 'assets' / f'windows-{theme}.png')
    (OUTPUT / '.nojekyll').touch()
    write_sitemap()
    print('Website built in build/site')


if __name__ == '__main__':
    main()
