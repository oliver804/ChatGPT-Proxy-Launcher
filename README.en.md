<h1 align="center">ChatGPT Proxy Launcher</h1>
<p align="center">A native macOS launcher for a dedicated ChatGPT proxy connection</p>

<p align="center">
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.0.0"><img src="https://img.shields.io/badge/version-1.0.0-168570" alt="Version 1.0.0"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-333333" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-333333" alt="Apple Silicon arm64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License"></a>
</p>
<p align="center">
  <a href="README.md">简体中文</a> · <b>English</b><br>
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.0.0">Download</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#faq">FAQ</a> ·
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/issues">Report an issue</a>
</p>

## About

If you use a proxy tool such as Clash Verge and want ChatGPT to use its local proxy without enabling TUN or affecting other networking tools, this launcher lets you configure a dedicated proxy entry point for ChatGPT.

It uses application-supported launch arguments and environment variables, without changing system proxy or DNS settings. Built with SwiftUI + AppKit, with no third-party runtime dependencies.

## Features

- **Dedicated proxy**: save a host and port; supports HTTP proxies and Clash mixed ports without authentication.
- **Start and stop**: launch ChatGPT with proxy settings or request a graceful shutdown.
- **Connection checks**: inspect proxy connectivity, actual launch arguments, and application TCP connections.
- **Menu bar controls**: start, stop, and check status; closing the main window hides the Dock icon.
- **Native interface**: light and dark appearance; Chinese UI with Chinese and English documentation.

## Download and install

| Version | Requirements | Download |
| --- | --- | --- |
| **v1.0.0** | Apple Silicon · macOS 13+ | [Download DMG](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/download/v1.0.0/ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg) |

Open the DMG and drag **ChatGPT Proxy Launcher** to **Applications**. The [release page](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.0.0) also provides a source archive and SHA-256 checksums.

> Only detectable **Electron versions of ChatGPT** are supported. Older native versions and Intel Macs are unsupported by the current release.

## Quick start

1. Keep your proxy app, such as Clash Verge, running with its HTTP / mixed port available.
2. Enter the host and port, such as `127.0.0.1` and `7890`, then click **保存设置** (Save settings).
3. Fully quit any running ChatGPT instance, then click **启动 ChatGPT** (Start ChatGPT).
4. Click **查看代理情况** (Check proxy status) and open the detailed report if needed.

**Restart ChatGPT after changing settings, and use the launcher for future launches.** Opening ChatGPT directly from the Dock does not automatically apply the proxy settings saved here.

Controls remain accessible from the menu bar after closing the main window. Quitting the launcher does not stop a running ChatGPT instance.

## FAQ

<details>
<summary><b>What if macOS blocks the app on first launch?</b></summary>

Current builds use an ad-hoc signature and are not Developer ID signed or notarized by Apple. After verifying that the download came from this project's release page, allow it in **System Settings → Privacy & Security**. There is no need to disable SIP or system security checks.

</details>

<details>
<summary><b>Do I still need TUN? Does all traffic use the proxy?</b></summary>

Compatible ChatGPT apps can use the local proxy port without TUN or system proxy settings. Your proxy app must remain running; the launcher does not change its configuration.

The proxy primarily covers Chromium HTTP, HTTPS, and WebSocket requests, with QUIC disabled. Voice, WebRTC, UDP, and child processes that ignore proxy environment variables are not guaranteed to use it. Behavior may also change with ChatGPT or Electron updates.

</details>

<details>
<summary><b>How should I interpret connection checks?</b></summary>

| Check | Meaning |
| --- | --- |
| Proxy connectivity | A CONNECT tunnel was established and a TLS website response received through the configured proxy |
| Launch arguments | The ChatGPT main process carries proxy arguments matching the current settings |
| Observed connections | A snapshot shows TCP connections from the app or its children to the proxy |

HTTP 403 indicates a response during the tunnel and TLS check, not working chat or account access. A snapshot cannot prove all traffic uses the proxy, and the absence of a connection does not prove direct access. Proxy hostnames may not match numeric IP addresses in socket snapshots.

</details>

<details>
<summary><b>How do I update the app?</b></summary>

Quit the launcher from its menu bar panel, then replace the app in Applications with the new version. Existing proxy settings are preserved, and ChatGPT can keep running.

</details>

## Development

Requires an Apple Silicon Mac, Xcode Command Line Tools (Swift 5.9+), and Python 3.

```sh
make check       # Privacy and script checks
make test        # Core tests
make build       # Build the app
make dmg         # Create DMG, source ZIP, and checksums
make verify      # Validate the package, signature, and icon
```

The app is written to `build/release/`, and release files to `dist/1.0.0/`. [`VERSION`](VERSION) is the single build-version source.

`make integration` and `make ui` require a logged-in macOS graphical session and only operate dedicated test apps and windows. `make previews` renders previews using sample data.

[Issues](https://github.com/oliver804/ChatGPT-Proxy-Launcher/issues) and PRs are welcome. See [Contributing](CONTRIBUTING.md), [Architecture](docs/ARCHITECTURE.en.md), and [Releasing](docs/RELEASING.en.md) for development details.

## Privacy and license

No login, telemetry, or automatic uploads; settings stay on your Mac. Connection checks send a HEAD request to `chatgpt.com` through the configured proxy without account credentials. Reports are displayed locally; remove private paths, internal addresses, and other sensitive details before sharing. [Privacy](docs/PRIVACY.en.md) · [Security](SECURITY.md)

**Author: Oliver** · [oliver804x@gmail.com](mailto:oliver804x@gmail.com)<br>
**License: [MIT](LICENSE)** · [Changelog](CHANGELOG.md)

An independent open-source project, not affiliated with OpenAI. ChatGPT and other names belong to their respective owners. See [Third-party notices](THIRD_PARTY_NOTICES.md).
