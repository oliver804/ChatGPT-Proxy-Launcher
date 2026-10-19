# Privacy

[中文](PRIVACY.md) | **English**

## Local preferences

The interface language, proxy host, port, and selected application path are stored in the macOS preferences domain `local.chatgpt-proxy-launcher`. The launcher does not read or store ChatGPT passwords, cookies, tokens, or chat history.

## Network requests

Before launch or when a user requests a check, the launcher sends a HEAD request to `https://chatgpt.com/` through the configured proxy to verify CONNECT and TLS. It sends no ChatGPT account credentials. The website still receives ordinary request information such as the proxy's exit IP address.

ChatGPT and the proxy service handle their own data. The launcher has no telemetry, analytics SDK, automatic upload, or update service.

## Diagnostics

The launcher reads application processes, launch arguments, and established TCP connections. Reports show process IDs, endpoints, and diagnostic details locally; copying a report only writes to the local clipboard. Review and redact internal network information before publishing reports.

## Publication boundary

The author's public identity is limited to Oliver and oliver804x@gmail.com. Source exports use an explicit allowlist and exclude IDE settings, build caches, old installers, real logs, desktop screenshots, and Git metadata. Release checks scan source and app files for private paths, access tokens, authenticated URLs, private keys, internal IPv4 addresses, and unapproved email addresses.

These checks cover known patterns, not every kind of sensitive information. Manually review new files, particularly screenshots, logs, certificates, and organizational material. No company affiliation is provided by this repository.

The historical preferences domain is retained across the 1.1.0 rename so existing settings continue to work. Changing the interface language does not change or save network settings.

## Windows settings and checks

Windows stores language, theme, host, port and selected executable in `%LOCALAPPDATA%\LocalRouteLauncher\settings.json`. Uninstall preserves this file; you may delete it separately. Launch only passes child-process settings; the proxy HEAD request occurs when you choose Check connection. Discovery queries current-user installed packages. Process inspection reads the Windows process list locally and filters reports to the selected app and descendants. TCP inspection uses the system API, without capturing traffic contents or uploading reports. Account data, cookies and chats are not read. System proxy, DNS and network registry settings are not changed.
