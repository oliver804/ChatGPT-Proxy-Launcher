#!/usr/bin/env python3
"""Validate both locales, deployed paths and release links without dependencies."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / 'build' / 'site'
VERSION = (ROOT / 'VERSION').read_text().strip()


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids = set()
        self.links = []
        self.locale = None
        self.h1_count = 0
        self.downloads = []
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            assert attrs['id'] not in self.ids, f'Duplicate ID in {self.path.name}'
            self.ids.add(attrs['id'])
        if tag == 'html':
            self.locale = attrs.get('lang')
        if tag == 'h1':
            self.h1_count += 1
        if tag == 'img':
            assert 'alt' in attrs, 'Image has no alt attribute'
        for key in ('href', 'src', 'data-dark', 'data-light'):
            if key in attrs:
                self.links.append(attrs[key])
        if tag == 'a' and attrs.get('href', '').endswith('.dmg'):
            self.downloads.append(attrs['href'])
        if tag in ('script', 'img') or (tag == 'link' and attrs.get('rel') == 'stylesheet'):
            target = attrs.get('src', attrs.get('href', ''))
            assert not urlsplit(target).netloc, 'Assets must be self-hosted'


def main():
    pages = {path.resolve(): Page(path) for path in SITE.rglob('*.html')}
    assert len(pages) == 2, 'Expected Chinese and English pages'
    assert {p.locale for p in pages.values()} == {'zh-CN', 'en'}
    release = f'https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/download/v{VERSION}/ChatGPT-Proxy-Launcher-{VERSION}-arm64.dmg'
    for path, page in pages.items():
        assert page.h1_count == 1, 'Expected one primary heading'
        assert len(page.downloads) == 2 and set(page.downloads) == {release}, 'Wrong release link'
        for link in page.links:
            parsed = urlsplit(link)
            if parsed.scheme or parsed.netloc:
                assert parsed.scheme in ('https', 'mailto'), f'Unexpected link scheme: {parsed.scheme}'
                continue
            assert not parsed.path.startswith('/'), 'Use relative paths for GitHub project Pages'
            target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
            assert target.is_relative_to(SITE.resolve()), 'Link escapes public site'
            if target.is_dir():
                target /= 'index.html'
            assert target.is_file(), f'Missing local target: {link}'
            if parsed.fragment:
                assert target in pages and unquote(parsed.fragment) in pages[target].ids, f'Missing anchor: {link}'
        print(f'PASS: {path.relative_to(SITE.resolve())}: links, assets, anchors, locale and downloads')
    expected = {'index.html', 'en/index.html', 'style.css', 'app.js', '.nojekyll',
                'assets/icon.png', 'assets/preview-dark.png', 'assets/preview-light.png'}
    actual = {str(p.relative_to(SITE)) for p in SITE.rglob('*') if p.is_file()}
    assert actual == expected, 'Unexpected or missing deployed files'
    print('PASS: deployment contains only the eight public website files')


if __name__ == '__main__':
    main()
