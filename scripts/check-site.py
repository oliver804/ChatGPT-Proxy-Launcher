#!/usr/bin/env python3
"""Validate both locales, deployed paths and release links without dependencies."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / 'build' / 'site'
VERSION = (ROOT / 'VERSION').read_text().strip()
BASE_URL = 'https://oliver804.github.io/ChatGPT-Proxy-Launcher/'
LOCALES = {'zh-CN': BASE_URL, 'en': BASE_URL + 'en/', 'x-default': BASE_URL}
ANALYTICS_SCRIPT = 'https://www.googletagmanager.com/gtag/js?id=G-QVHYT7RFW9'


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids = set()
        self.links = []
        self.locale = None
        self.h1_count = 0
        self.downloads = []
        self.meta = {}
        self.alternates = {}
        self.canonical = None
        self.structured_data = []
        self.json_buffer = None
        self.title = ''
        self.in_title = False
        self.analytics_count = 0
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
        if tag == 'title':
            self.in_title = True
        if tag == 'meta':
            self.meta[attrs.get('name', attrs.get('property'))] = attrs.get('content', '')
        if tag == 'link' and attrs.get('rel') == 'canonical':
            self.canonical = attrs['href']
        if tag == 'link' and attrs.get('rel') == 'alternate':
            self.alternates[attrs.get('hreflang')] = attrs['href']
        if tag == 'script' and attrs.get('type') == 'application/ld+json':
            self.json_buffer = ''
        if tag == 'img':
            assert 'alt' in attrs, 'Image has no alt attribute'
        for key in ('href', 'src', 'data-dark', 'data-light'):
            if key in attrs:
                self.links.append(attrs[key])
        if tag == 'a' and attrs.get('href', '').endswith(('.dmg', '.exe')):
            self.downloads.append(attrs['href'])
        if tag in ('script', 'img') or (tag == 'link' and attrs.get('rel') == 'stylesheet'):
            target = attrs.get('src', attrs.get('href', ''))
            if tag == 'script' and target == ANALYTICS_SCRIPT:
                assert 'async' in attrs, 'Analytics must load asynchronously'
                self.analytics_count += 1
            else:
                assert not urlsplit(target).netloc, 'Only the approved Google tag may load externally'

    def handle_data(self, data):
        if self.in_title:
            self.title += data
        if self.json_buffer is not None:
            self.json_buffer += data

    def handle_endtag(self, tag):
        if tag == 'title':
            self.in_title = False
        if tag == 'script' and self.json_buffer is not None:
            self.structured_data.append(json.loads(self.json_buffer))
            self.json_buffer = None


def main():
    pages = {path.resolve(): Page(path) for path in SITE.rglob('*.html')}
    assert len(pages) == 2, 'Expected Chinese and English pages'
    assert {p.locale for p in pages.values()} == {'zh-CN', 'en'}
    release = f'https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/download/v{VERSION}/Local-Route-Launcher-{VERSION}-arm64.dmg'
    windows_release = f'https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/download/v{VERSION}/Local-Route-Launcher-{VERSION}-windows-x64-setup.exe'
    for path, page in pages.items():
        assert page.h1_count == 1, 'Expected one primary heading'
        assert page.analytics_count == 1, 'Expected one Google tag per page'
        assert path.read_text().count("gtag('config', 'G-QVHYT7RFW9');") == 1, 'Missing or duplicate Analytics configuration'
        assert len(page.downloads) == 4 and set(page.downloads) == {release, windows_release}, 'Wrong release link'
        assert page.canonical == LOCALES[page.locale], 'Incorrect canonical URL'
        assert page.alternates == LOCALES, 'Incomplete reciprocal language links'
        assert page.meta.get('description'), 'Missing search description'
        assert all(term in page.title for term in ('ChatGPT', 'Windows', 'macOS', 'Local Route Launcher')), 'Search title does not identify the app and supported platforms'
        assert page.meta.get('og:title') == page.title, 'Search and sharing titles differ'
        assert page.meta.get('og:description') == page.meta['description'], 'Search and sharing descriptions differ'
        for verification in ('google-site-verification', 'msvalidate.01', 'baidu-site-verification', 'sogou_site_verification'):
            assert page.meta.get(verification), f'Missing ownership verification: {verification}'
        assert 'noindex' not in page.meta.get('robots', '').lower(), 'Page excludes search indexing'
        assert page.meta.get('og:url') == page.canonical, 'Share URL differs from canonical'
        assert page.meta.get('og:title') and page.meta.get('og:description'), 'Missing share metadata'
        image = page.meta.get('og:image', '')
        assert image.startswith(BASE_URL) and (SITE / image.removeprefix(BASE_URL)).is_file(), 'Missing share image'
        assert len(page.structured_data) == 1, 'Expected one application description'
        app = page.structured_data[0]
        assert app['@type'] == 'SoftwareApplication' and app['name'] == 'Local Route Launcher'
        assert app['softwareVersion'] == VERSION and set(app['downloadUrl']) == {release, windows_release}, 'Stale app schema'
        assert app['url'] == page.canonical and app['offers']['price'] == 0
        assert app['description'] == page.meta['description'], 'App description differs from page metadata'
        assert len(app['operatingSystem']) == 2 and app['featureList'] and app['softwareRequirements'], 'Missing app compatibility or features'
        assert app['releaseNotes'].endswith(f'/releases/tag/v{VERSION}'), 'Stale release notes link'
        assert len(app['screenshot']) == 2, 'Expected macOS and Windows screenshots'
        for screenshot in app['screenshot']:
            assert screenshot.startswith(BASE_URL) and (SITE / screenshot.removeprefix(BASE_URL)).is_file(), 'Missing app screenshot'
        assert 'aggregateRating' not in app and 'review' not in app, 'Do not invent ratings or reviews'
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
        print(f'PASS: {path.relative_to(SITE.resolve())}: links, assets, locale, downloads and SEO metadata')
    ns = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9', 'x': 'http://www.w3.org/1999/xhtml'}
    entries = ET.parse(SITE / 'sitemap.xml').getroot().findall('s:url', ns)
    assert len(entries) == 2 and {e.findtext('s:loc', namespaces=ns) for e in entries} == set(LOCALES.values())
    for entry in entries:
        alternates = {link.attrib['hreflang']: link.attrib['href'] for link in entry.findall('x:link', ns)}
        assert alternates == LOCALES, 'Sitemap language links differ from pages'
    expected = {'index.html', 'en/index.html', 'style.css', 'app.js', '.nojekyll',
                'sitemap.xml', 'assets/icon.png', 'assets/preview-dark.png', 'assets/preview-light.png', 'assets/preview-dark.en.png', 'assets/preview-light.en.png', 'assets/windows-dark.png', 'assets/windows-light.png', 'assets/windows-dark.en.png', 'assets/windows-light.en.png'}
    actual = {str(p.relative_to(SITE)) for p in SITE.rglob('*') if p.is_file()}
    assert actual == expected, 'Unexpected or missing deployed files'
    print('PASS: bilingual sitemap and deployment allowlist (fifteen public files)')


if __name__ == '__main__':
    main()
