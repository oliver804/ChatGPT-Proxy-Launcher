# Publishing on GitHub

[中文](RELEASING.md) | **English**

## First release

1. Create an empty repository under your own GitHub account. No remote URL or GitHub account is hard-coded.
2. Inspect `git status` and the staged files. Include source and documentation only, not the whole working directory.
3. The original author's public commit identity is `Oliver <oliver804x@gmail.com>`. Contributors should use their own public identity, not Oliver's.
4. Add the remote URL of the repository you created and push `main`.
5. Confirm GitHub Actions CI passes and review the release contents.
6. Tag the reviewed commit `v1.4.0` and push that tag.

A `v*` tag runs the release workflow: validate the tag against `VERSION`, run source and core checks, build and verify both the macOS DMG and Windows installer, export clean source, and create a **draft GitHub Release** with attachments. Review the draft and files before clicking Publish release. The workflow uses the repository's temporary `GITHUB_TOKEN`; never commit personal tokens.

To explicitly request public publication, use an annotated tag with a standalone `Publish-Release: true` line in its message. The workflow publishes only after every check passes and all assets are uploaded. Tags without that marker remain draft-only.

## Local release files

```sh
make check
make test
make integration
make ui
make dmg
make verify
```

Upload these four files from `dist/1.4.0/`:

- `Local-Route-Launcher-1.4.0-arm64.dmg`
- `Local-Route-Launcher-1.4.0-windows-x64-setup.exe`
- `Local-Route-Launcher-1.4.0-source.zip`
- `SHA256SUMS.txt`

The checksum file uses relative filenames. Run `shasum -a 256 -c SHA256SUMS.txt` inside that directory to verify integrity. The app includes credits and its license. Default packages are ad-hoc signed, not notarized.

## Subsequent releases

Update `VERSION`, README version/download examples, and `CHANGELOG.md`; review the security support policy. Scripts generate app versions, release filenames, and checksums. Do not reuse old DMGs or silently replace binaries of an existing published version.

## Privacy review

- Review automated checks and manually inspect new documents and images for private or organizational information.
- Inspect Git author and committer identities; do not publish private identities or credentials in history.
- The exported source ZIP excludes Git history and local settings.
- Do not upload raw diagnostics, desktop screenshots, signing certificates, configuration backups, or build caches.
- Local checks do not prove remote CI has passed; verify the workflow after pushing to your repository.

## Website (GitHub Pages)

Website sources live in `site/`, with a Chinese homepage and an English page under `en/`. Run `make site` to build and check `build/site/`; preview locally with `python3 -m http.server 4173 --directory build/site`. The build copies only explicitly listed pages and reviewed images, never the repository root.

For the first deployment, a repository administrator must select **GitHub Actions** under **Settings → Pages → Build and deployment → Source**. Then push website changes, or use **Actions → Website → Run workflow**. The workflow checks both locales, assets, download versions, and privacy before deploying only the website files. Pull requests run build checks without deploying.

The website is hosted at `https://oliver804.github.io/Local-Route-Launcher/`, with English under `en/`. When releasing a new version, update the download links and version copy in both pages; `make site` checks download links against `VERSION`. Website deployments do not change app releases or tags.

### Search engines and sharing metadata

The build generates `sitemap.xml` with both pages and reciprocal language links. Each page includes its own title, description, canonical URL, sharing preview, and software structured data. Update `softwareVersion` and `downloadUrl` when releasing a new version. Do not add unsubstantiated ratings or reviews; structured data does not guarantee search rich results.

Create a URL-prefix property with the full website URL in Google Search Console, and add the same site in Bing Webmaster Tools. Verify ownership with the public HTML verification tags supplied by each service, then submit `https://oliver804.github.io/Local-Route-Launcher/sitemap.xml`. Keep verification tags in place. They are not account passwords or API access tokens; never commit those credentials.

A `robots.txt` under the project path would not control crawling, so this build does not generate one. If crawl rules need changing, the site owner must maintain `/robots.txt` at the host root. The sitemap does not fabricate `lastmod` dates from deployment times. Check crawl and indexing status in each console after submission; successful submission guarantees neither indexing nor ranking.

## Windows and cross-platform releases

On Windows x64, install .NET SDK 10.0.402 and Inno Setup 6, then run:

```powershell
./scripts/build-windows.ps1 -Test
```

The script creates a self-contained EXE installer and tests per-user installation, an isolated fixture, eighteen localized theme renders, tray lifecycle and uninstall. It does not test a real signed-in ChatGPT account. CI uses Windows Server runners; release compatibility with Windows 10/11 target packages still depends on their installation and Electron support. Inno Setup's installer wizard uses English; the application itself supports nine languages.

After both platform jobs pass, the release workflow assembles the reviewed assets, generates a combined checksum manifest and creates a draft. Only annotated tags containing `Publish-Release: true` trigger public publication. Previously published assets are retained. Windows uninstall preserves user settings. Quit the launcher from its tray before upgrading or uninstalling. Confirm both platform builds, release assembly and website checks before declaring a release complete.

Do not claim Windows Authenticode signing or notarization: current Windows packages are unsigned. Bundled .NET notices must accompany the self-contained runtime. Source ZIPs exclude all .NET bin/obj output and local test results.
