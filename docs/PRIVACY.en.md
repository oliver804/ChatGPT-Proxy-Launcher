# Privacy

[中文](PRIVACY.md) | **English**

## Local preferences

The interface language, proxy host, port, and selected application path are stored in the macOS preferences domain `local.chatgpt-proxy-launcher`. The launcher does not read or store ChatGPT passwords, cookies, tokens, or chat history.

## Network requests

Before launch or when a user requests a check, the launcher sends a HEAD request to `https://chatgpt.com/` through the configured proxy to verify CONNECT and TLS. It sends no ChatGPT account credentials. The website still receives ordinary request information such as the proxy's exit IP address.

ChatGPT and the proxy service handle their own data. The launcher has no telemetry, analytics SDK, automatic upload, download, or installation service.

## Diagnostics

The launcher reads application processes, launch arguments, and established TCP connections. Reports show process IDs, endpoints, and diagnostic details locally; copying a report only writes to the local clipboard. Review and redact internal network information before publishing reports.

## Publication boundary

The author's public identity is limited to Oliver and oliver804x@gmail.com. Source exports use an explicit allowlist and exclude IDE settings, build caches, old installers, real logs, desktop screenshots, and Git metadata. Release checks scan source and app files for private paths, access tokens, authenticated URLs, private keys, internal IPv4 addresses, and unapproved email addresses.

These checks cover known patterns, not every kind of sensitive information. Manually review new files, particularly screenshots, logs, certificates, and organizational material. No company affiliation is provided by this repository.

The historical preferences domain is retained across the 1.1.0 rename so existing settings continue to work. Changing the interface language does not change or save network settings.

## Windows settings and checks

Windows stores language, theme, host, port and selected executable in `%LOCALAPPDATA%\LocalRouteLauncher\settings.json`. Uninstall preserves this file; you may delete it separately. Launch only passes child-process settings; the proxy HEAD request occurs when you choose Check connection. Discovery queries current-user installed packages. Process inspection reads the Windows process list locally and filters reports to the selected app and descendants. TCP inspection uses the system API, without capturing traffic contents or uploading reports. Account data, cookies and chats are not read. System proxy, DNS and network registry settings are not changed.

## Website analytics

The Chinese and English project website pages use Google Analytics 4 (measurement ID: `G-QVHYT7RFW9`) to understand website visits. The website loads Google's `gtag.js` and sends visit data, such as page views, to Google. This may include page URLs, referring sources, browser and device information. Google Analytics uses first-party cookies to distinguish visitors and sessions. Enabled enhanced measurement events and data retention depend on the Analytics property's settings.

Analytics applies only to the website. It is not included in the macOS or Windows launcher and does not read in-app proxy settings, account details or conversations. Browser restrictions, content blockers or network availability may prevent measurement. See [Google's Privacy Policy](https://policies.google.com/privacy) and [Google Analytics cookie usage](https://support.google.com/analytics/answer/11397207?hl=en) for Google's data handling.

### Microsoft Clarity

The website also loads Microsoft Clarity (project ID: `z0krfkfwwu`) independently of Google Analytics to understand visitor behavior and improve the site. Clarity sends page and interaction data, such as views, clicks, scrolling, browser and device information, to Microsoft for heatmaps and session replay. It may use first-party and third-party cookies and other tracking technologies. Collection depends on project settings, consent status, browser and network conditions; availability in every region is not guaranteed.

Session replay reconstructs interactions with the website rather than recording the computer screen. It does not access launcher proxy settings or ChatGPT conversations. This integration adds no custom user identifiers and does not override Clarity's default masking settings. See the [Microsoft Privacy Statement](https://privacy.microsoft.com/privacystatement) and [Clarity privacy information](https://clarity.microsoft.com/privacy) for Microsoft's data handling and use.

v1.4.0: Antigravity App / IDE use a credential-free HEAD probe to `https://antigravity.google/`. Each app profile stays local. The launcher does not edit target-app settings or submit AI prompts.


## Launcher update checks (1.4.0)

By default, the launcher checks GitHub for a stable release once at startup. Existing startup-check preferences are preserved. Requests go to `api.github.com/repos/oliver804/Local-Route-Launcher/releases/latest` using the system network route, not a selected target app’s proxy profile. GitHub receives ordinary request metadata such as the exit IP and launcher User-Agent, but no proxy address, application path, diagnostic report, account or chat data. Offline checks do not block app launching. Nothing is automatically downloaded or installed. Only clicking the update badge opens the matching GitHub installer download in your browser; you run the installer yourself.
