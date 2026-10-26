## Local Route Launcher 1.3.0 — nine languages, native macOS menu icon

### 中文

- macOS 与 Windows 支持九种界面语言：简体中文、繁體中文、English、Русский、فارسی、Беларуская、Español、العربية、Português。选择会保存，窗口、菜单栏或托盘及连接报告同步切换。
- 恢复 1.0.0 使用的 macOS 原生菜单栏符号，保持原有比例，自动适配浅色、深色和点击高亮状态。
- 简繁体识别优先尊重系统指定的文字脚本，阿拉伯语和波斯语采用从右向左布局。
- Windows 操作期间保护语言、主题和网络设置，操作完成或失败后保留未保存输入。安装向导保持原有语言。

### English

- Nine interface languages on macOS and Windows, with persistent selection and translated windows, menu bar or tray, notices and diagnostic reports.
- Restored the native macOS menu bar symbol used in 1.0.0, preserving its proportions and automatic light, dark and highlighted appearance handling.
- Chinese language detection respects explicit script preferences. Arabic and Persian use right-to-left layouts.
- Windows protects settings during operations and preserves unsaved input after success or failure. Installer wizards retain their existing language.

**Compatibility:** macOS 13+ on Apple Silicon, or Windows 10 22H2 / Windows 11 x64, with a detectable Electron-based ChatGPT app. Older native builds, Intel Macs, Windows ARM64, and some restricted Store packages are unsupported.

**Verification:** macOS language, diagnostics, native icon rendering, Dock lifecycle, integration and DMG checks; Windows core, busy-state, installer fixture and localized UI checks. The isolated fixture does not validate a signed-in ChatGPT account or every target-app version.

**Distribution:** macOS builds are ad-hoc signed but not notarized; Windows installers are unsigned and may trigger SmartScreen. Check release origin and SHA-256 hashes. Keep system protections enabled.

[中文介绍](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.md) · [English article](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.en.md)

Independent project, not affiliated with or endorsed by OpenAI. ChatGPT identifies compatibility only. Use authorized networks and services under applicable laws and terms. The launcher includes no proxy service; connection checks are snapshots, not proof of complete routing or account access.
