## Local Route Launcher 1.2.0 — Windows + macOS

### 中文

- 新增 **Windows x64 EXE 安装包**，为当前用户安装，内置 .NET 运行库，无需另外安装开发工具。
- Windows 支持 **简体中文 / English**、浅色 / 深色 / 系统外观、系统托盘、应用选择与自动检测、启动 / 正常退出，以及分项连接检查。
- 关闭 Windows 主窗口后隐藏任务栏入口，托盘继续可用；退出启动器不会结束 ChatGPT。
- 保留 **macOS Apple Silicon DMG**；跨平台应用、安装包和官网共用原创路线图标。
- 更新双语 README、官网、博客稿、隐私与兼容性说明。Release 同时提供两个平台安装包、源码 ZIP 和统一 SHA-256 校验清单。

**要求：**macOS 13+ / Apple Silicon，或 Windows 10 22H2 / Windows 11 x64。仅支持可识别的 Electron 版 ChatGPT；旧原生版本、Intel Mac 和 Windows ARM64 不在本次支持范围。受限制的 Microsoft Store 安装包可能不允许直接启动。

**安装：**Mac 打开 DMG 后拖入应用程序；Windows 运行 `windows-x64-setup.exe`。升级/卸载前从菜单栏或托盘退出启动器。Windows 卸载默认保留 `%LOCALAPPDATA%\LocalRouteLauncher\settings.json`。

**验证范围：**Windows 使用安装后的程序和隔离测试应用验证参数与环境变量、进程识别、TCP 快照、重复启动保护和正常关闭，并检查四种语言/外观组合、隐藏/恢复窗口、安装和卸载。这不等于已验证真实登录账号或所有 ChatGPT 版本；Windows CI 运行于 Windows Server。

### English

- Added a **self-contained Windows x64 installer**. Installs for the current user with the .NET runtime included.
- Added **English / Simplified Chinese**, light / dark / system appearance, system tray controls, app selection and discovery, launch / graceful close, and separate connection checks on Windows.
- Closing the window hides its taskbar entry; quitting the launcher leaves ChatGPT running.
- Retained the **macOS Apple Silicon DMG**, with shared original route artwork across platforms and the website.
- Updated the bilingual website, README, announcement articles, privacy and compatibility notes. Includes both installers, source ZIP and a combined SHA-256 manifest.

**Requirements:** macOS 13+ on Apple Silicon, or Windows 10 22H2 / Windows 11 x64. Requires a detectable Electron-based ChatGPT app. Older native builds, Intel Macs and Windows ARM64 are unsupported. Restricted Store packages may not permit direct launch.

**Validation:** the installed Windows app is exercised against an isolated fixture for argv/environment propagation, process inspection, TCP snapshots, duplicate rejection and graceful shutdown. UI checks cover four language/theme combinations and close/reopen behavior, plus installer/uninstaller checks. This does not verify a signed-in ChatGPT account or every target version. Windows CI runs on Windows Server.

**Signing:** Windows builds are not Authenticode-signed and may trigger SmartScreen. macOS builds are ad-hoc signed, not Developer ID signed or notarized. Verify origin and checksums; do not disable system protections. The Windows installer wizard uses English; the application is bilingual.

[中文介绍](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.md) · [English article](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.en.md)

Independent project, not affiliated with or endorsed by OpenAI. ChatGPT is a trademark of OpenAI, used only to identify compatibility. Use authorized networks and services under applicable laws and service terms. No proxy service is provided. Connection snapshots cannot guarantee complete routing; voice, WebRTC, UDP and some child processes may not follow the settings.
