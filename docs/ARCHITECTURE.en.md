# Architecture

[中文](ARCHITECTURE.md) | **English**

- `ProxyCore.swift`: validates endpoints, builds process-scoped arguments and environment variables, probes the proxy, and parses process trees and socket snapshots. User input is passed as separate process arguments, never shell-interpolated.
- `LauncherModel.swift`: shared state and preferences; launches through Launch Services and requests graceful termination. The main window and menu panel share one instance; periodic refresh only checks local running state.
- `LauncherApp.swift`: SwiftUI window, menu panel, and Dock visibility lifecycle. Only main-window closure hides the Dock icon, not panel or report dismissal.
- `BrandMark.swift`: the shared artwork used by the UI and generated ICNS icon.

Launches use Chromium's `--proxy-server` plus HTTP/HTTPS/ALL_PROXY environment variables for compatible child processes. Localhost bypasses the proxy to keep local tools working. Environment variables do not force every child process to use a proxy.

Builds generate version metadata from `VERSION` and preserve the compatible preferences domain. Fresh packaging directories contain bilingual installation instructions and the MIT license. Compiler path mapping avoids embedding developer directories in the executable.

CI runs source checks, core tests, builds, and package validation. Without a graphical session, system icon-service validation is skipped while icon declaration and ICNS decoding checks remain enabled. Run full `make verify`, `make integration`, and `make ui` in a local graphical session before publishing.
