# Architecture

[中文](ARCHITECTURE.md) | **English**

- `ProxyCore.swift`: validates endpoints, builds process-scoped arguments and environment variables, probes the proxy, and parses process trees and socket snapshots. User input is passed as separate process arguments, never shell-interpolated.
- `LauncherModel.swift`: shared state and preferences; launches through Launch Services and requests graceful termination. The main window and menu panel share one instance; periodic refresh only checks local running state.
- `LauncherApp.swift`: SwiftUI window, menu panel, and Dock visibility lifecycle. Only main-window closure hides the Dock icon, not panel or report dismissal.
- `BrandMark.swift`: the shared artwork used by the UI and generated ICNS icon.

Launches use Chromium's `--proxy-server` plus HTTP/HTTPS/ALL_PROXY environment variables for compatible child processes. Localhost bypasses the proxy to keep local tools working. Environment variables do not force every child process to use a proxy.

Builds generate version metadata from `VERSION` and preserve the compatible preferences domain. Fresh packaging directories contain bilingual installation instructions and the MIT license. Compiler path mapping avoids embedding developer directories in the executable.

CI runs source checks, core tests, builds, and package validation. Without a graphical session, system icon-service validation is skipped while icon declaration and ICNS decoding checks remain enabled. Run full `make verify`, `make integration`, and `make ui` in a local graphical session before publishing.

## Interface language

`Sources/Localization.swift` contains the Chinese / English catalog. First launch follows the system language (Chinese or English fallback), then saves an explicit choice in `interfaceLanguage`. SwiftUI observes the model language; background checks receive an immutable language snapshot. Switching is disabled while an operation runs and clears stale diagnostic text, without saving network edits. System-owned dialogs may retain the macOS language.

## Windows implementation / Windows 实现

- `Windows/Core`: endpoint validation, case-insensitive child environment, atomic JSON preferences, proxy probe and process-family filtering. Tests run without WPF or a live account.
- `Windows/App`: WPF interface, bilingual strings, WinForms notification-area icon, fixed PowerShell/CIM process queries and native PID-scoped TCP tables. Executable paths and user settings are never interpolated into shell scripts. Only the selected app is asked to close; production operations never force-kill ChatGPT.
- `Windows/Fixture`: isolated test application named ChatGPT.exe, built only for validation and never bundled in release installers.
- `scripts/build-windows.ps1`: generates the shared ICO, publishes self-contained .NET, includes runtime notices and builds a per-user Inno Setup installer.
- `scripts/test-windows.ps1`: installs to a path containing spaces, tests the installed executable with the fixture, renders both languages/themes, checks close/reopen behavior and uninstalls.

Windows 设置保存在用户本地应用数据目录；不需要管理员权限，不注册系统服务，不自动开机启动。安装包与应用图标均来自已审阅的原创品牌图。关闭窗口隐藏任务栏入口，托盘仍可恢复窗口；退出启动器不结束目标应用。当前测试不覆盖真实 ChatGPT 账号或所有商店安装版本。
