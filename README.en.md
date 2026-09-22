# ChatGPT Proxy Launcher

[中文](README.md) | **English**

A lightweight native macOS launcher that configures an HTTP proxy for compatible ChatGPT desktop applications. It does not require TUN mode or change system proxy or DNS settings.

**Version 1.0.0 · Apple Silicon · macOS 13+ · MIT License**

## Features

- Save a proxy host and port; defaults to `127.0.0.1:7890`.
- Launch ChatGPT with proxy settings and request a graceful shutdown.
- Inspect the proxy tunnel, actual launch arguments, and TCP connections separately.
- Access controls from the menu bar. Closing the main window hides the Dock icon; reopening restores it.
- Light and dark appearance with a consistent application icon.

## Install and use

1. Download `ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg` from this repository's GitHub **Releases**.
2. Open the DMG and drag **ChatGPT Proxy Launcher** to **Applications**.
3. Keep an HTTP proxy such as Clash Verge running with its mixed port available.
4. Enter the proxy host and port in the launcher, then click **保存设置** (Save settings).
5. Fully quit any running ChatGPT instance, then click **启动 ChatGPT** (Start ChatGPT).
6. Click **查看代理情况** (Check proxy status) to inspect the connection.

You may disable TUN and system proxy features in your proxy application while retaining its local mixed-port service. The launcher does not change those settings for you. Starting ChatGPT directly from the Dock does not automatically apply the proxy settings saved here.

Default builds use an **ad-hoc signature and are not Developer ID signed or notarized by Apple**. If macOS blocks the app, verify the download source and allow it in **System Settings → Privacy & Security**. Disabling SIP or system security checks is unnecessary.

To update, quit the launcher from its menu bar panel, then replace the application. ChatGPT can keep running and existing settings are preserved.

## Compatibility and limitations

| Item | Support |
| --- | --- |
| Platform | Apple Silicon, macOS 13 or later |
| ChatGPT | Detectable Electron versions; older native versions are unsupported |
| Proxy | HTTP / Clash mixed port without authentication; IP addresses, hostnames and IPv6 |
| Protocols | Chromium HTTP, HTTPS and WebSocket; QUIC is disabled |
| Interface language | Chinese; documentation is available in Chinese and English |

This is not a network extension that forces all application traffic through a proxy. Voice, WebRTC, UDP, and child processes that ignore proxy environment variables are not guaranteed to use the proxy. Behavior may change with ChatGPT or Electron updates.

## Understanding diagnostics

- **Proxy connectivity**: the launcher establishes a CONNECT tunnel and receives a TLS website response. HTTP 403 does not mean chat or account access works.
- **Launch arguments**: the running ChatGPT main process carries the expected proxy argument.
- **Observed connections**: a snapshot shows TCP connections from the application or its children to the proxy.

A single snapshot does not prove all traffic uses the proxy, and the absence of a connection does not prove direct access. Hostnames may not match numeric IP addresses in socket snapshots. Restart ChatGPT after changing proxy settings.

## Privacy

No login, telemetry, analytics SDK, or automatic diagnostic upload. Preferences remain in the local macOS user settings. A proxy check sends an unauthenticated HEAD request to `https://chatgpt.com/` through the configured proxy.

Reports display process IDs, endpoints and connections locally. Remove private paths, internal hostnames and IP addresses, company information, account details and tokens before sharing. See [Privacy](docs/PRIVACY.en.md).

## Development and builds

Requires an Apple Silicon Mac, Xcode Command Line Tools (or Xcode, Swift 5.9+), and Python 3. No third-party runtime dependencies.

```sh
make check       # Source privacy and shell syntax checks
make test        # Core behavior tests
make build       # Build the app bundle
make dmg         # Build DMG, clean source ZIP, and checksums
make verify      # Mount and validate DMG, signature, and system icon lookup
```

Outputs:

- `build/release/ChatGPT Proxy Launcher.app`
- `dist/1.0.0/ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg`
- `dist/1.0.0/ChatGPT-Proxy-Launcher-1.0.0-source.zip`
- `dist/1.0.0/SHA256SUMS.txt`

`make integration` and `make ui` require a logged-in macOS graphical session. They only launch a dedicated fixture application or operate test windows. `make previews` renders local UI previews using sample state. Do not publish real diagnostic output.

[`VERSION`](VERSION) is the single build-version source. The build writes it into application metadata and release filenames. Source exports use an explicit file allowlist and exclude IDE settings, old installers, local records, and Git metadata.

## Layout

```text
Sources/       SwiftUI views, application control, proxy and process inspection
Resources/     Application metadata, credits, bilingual installation instructions
Tests/         Core, launch integration, Dock lifecycle, and preview tools
scripts/       Build, checks, packaging, and source export
.github/       CI, release workflows, and issue / PR templates
docs/          Architecture, privacy, and release guides
```

[Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Releasing](docs/RELEASING.en.md) · [Architecture](docs/ARCHITECTURE.en.md) · [Changelog](CHANGELOG.md)

## Author and license

**Oliver** · [oliver804x@gmail.com](mailto:oliver804x@gmail.com)

Project code is licensed under the [MIT License](LICENSE). This independent project is not affiliated with OpenAI. ChatGPT and other names belong to their respective owners; Apple platform symbols and frameworks remain subject to their own terms. See [Third-party notices](THIRD_PARTY_NOTICES.md).
