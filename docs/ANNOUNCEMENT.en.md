# Local Route Launcher: app-specific launch settings for macOS

I wanted a simpler way to launch a compatible ChatGPT installation with a local HTTP proxy while leaving my Mac’s system proxy and DNS settings alone. Switching system-wide settings was inconvenient when other applications needed different configurations.

I built **Local Route Launcher**, a free, MIT-licensed utility written in SwiftUI and AppKit. It saves a proxy host and port, then passes that configuration to the target application when it starts. It uses a proxy you already run; it does not provide a proxy service.

## What it does

- Saves local HTTP proxy settings and launches a compatible application with them.
- Starts ChatGPT or requests a graceful shutdown.
- Checks proxy connectivity, launch arguments, and observed TCP connections.
- Provides menu bar controls, light and dark appearances, and instant **English / Simplified Chinese** switching. Your language choice is remembered.

The launcher does not change system proxy or DNS settings. Its language controls are available in both the main window and menu panel.

## Compatibility and limits

Version **1.1.0** targets **Apple Silicon Macs running macOS 13 or later**, with detectable **Electron-based ChatGPT installations**. Older native builds and Intel Macs are not supported. Check the compatibility notes before downloading.

Connection checks are snapshots, not proof that every request uses the proxy. Voice, WebRTC, UDP, and some child-process traffic are outside the routing guarantees. Application updates may affect compatibility. macOS-owned menus and dialogs may follow the system language.

Release builds are ad-hoc signed and are not notarized by Apple. Source code and release checksums are available for inspection.

## Try it or review the code

[GitHub repository](https://github.com/oliver804/ChatGPT-Proxy-Launcher) · [English website](https://oliver804.github.io/ChatGPT-Proxy-Launcher/en/) · [Download v1.1.0](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.1.0)

I’d welcome compatibility reports, code reviews, and suggestions for improving the interface.

This is an independent project, not affiliated with or endorsed by OpenAI. ChatGPT is a trademark of OpenAI and is mentioned only to identify compatibility. Use only networks and services you are authorized to access, in accordance with applicable laws and service terms.

— Oliver

*Writing disclosure: this article was drafted with AI assistance.*
