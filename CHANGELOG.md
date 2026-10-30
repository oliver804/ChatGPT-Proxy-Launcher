# Changelog / 更新日志

## 1.4.0 — In development / 开发测试中

- Apply the accepted compact layout: shared language/appearance/GitHub icons at the top right, original three-card content, two-line idle footer, and a compact menu/tray panel.
- Add optional startup and manual stable-release checks for the launcher, with a quiet new-version indicator, offline retry and browser download links; no automatic downloads or installation.
- Preserve symmetric artwork, native macOS menu icon appearance, zoom/fullscreen and close-to-menu behavior.
- Record the UI baseline and icon constraints; migrate project links to `oliver804/Local-Route-Launcher` while retaining existing app settings.
- 按已确认设计收紧主窗口及菜单栏/托盘布局，保留三张卡片与两行底部说明；新增启动器稳定版检查与静默提示，无自动下载安装。

- Added separate ChatGPT, Antigravity App and Antigravity IDE profiles and launch controls on macOS / Windows; existing ChatGPT preferences are retained.
- Added a multi-app sidebar and menu bar / tray controls, global nine-language selection and Follow system.
- Added target-specific probes and separate observations for recognized language-server descendants; connection snapshots do not establish full model or account access.
- Expanded migration, profile isolation, language, target validation and installed-app smoke coverage. Existing icon and Dock lifecycle behavior is retained.


## 1.3.0 — 2026-10-26

- Add seven interface languages to macOS and Windows: Traditional Chinese, Russian, Persian, Belarusian, Spanish, Arabic and Portuguese, alongside English and Simplified Chinese.
- Persist language preferences, respect explicit Chinese scripts, and support right-to-left layouts for Arabic and Persian. Declare all nine languages in the macOS bundle.
- Restore the native macOS menu bar symbol used in 1.0.0, with automatic light, dark and highlighted appearance handling.
- Protect Windows settings during operations and preserve unsaved input after success or failure.
- Expand localization, menu icon, window lifecycle and installer checks; update website and bilingual documentation. Installer wizards retain their existing language.

## 1.2.0 — 2026-10-19

- Windows x64 self-contained installer with bilingual WPF interface, themes, system tray, app discovery, process-scoped proxy launch, graceful stop and local diagnostics.
- Added Windows core, integration-fixture, UI and installer/uninstaller checks; release publication waits for both platform builds.
- Shared original icon artwork; updated website download choices, bilingual docs and announcement articles.
- Windows installer is unsigned. Actual ChatGPT account compatibility is not covered by the isolated CI fixture; restricted Store packages may reject direct launch.


## 1.1.0

- Rename the public application and release packages to Local Route Launcher; keep existing repository links and preference storage compatible.
  对外名称与发布包更名为 Local Route Launcher，保留现有仓库链接和偏好设置兼容性。
- Add immediate, persistent English / Simplified Chinese switching for launcher UI, menu panel, validation, and reports.
  主窗口、菜单栏、校验提示和诊断报告支持中英文即时切换并保存选择。
- Refresh bilingual previews and documentation; clarify independent branding, authorized use, compatibility, and diagnostic limits.
  更新双语预览及文档，明确独立品牌、授权使用、兼容性及诊断边界。

## 1.0.0

Initial public release / 首个开源版本。

- Per-launch HTTP proxy settings for compatible Electron versions of ChatGPT.
  为兼容的 Electron 版 ChatGPT 单独设置启动代理。
- Start, gracefully stop, and inspect proxy configuration and TCP connections.
  启动、正常停止应用，并检查代理参数和 TCP 连接。
- Menu bar access; hide the Dock icon when the main window is closed.
  支持菜单栏操作；关闭主窗口时隐藏 Dock 图标。
- Light and dark appearance with a shared application icon.
  适配浅色与深色外观，统一应用图标。
- Chinese and English documentation, source checks, and DMG packaging.
  中英文文档、源码检查与 DMG 打包流程。
