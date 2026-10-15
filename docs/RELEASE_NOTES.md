## Local Route Launcher 1.1.0

### 中文

- 应用对外名称改为 **Local Route Launcher**，更新应用、DMG、官网和文档品牌；现有仓库网址保持不变。
- 主窗口和菜单栏新增 **简体中文 / English** 切换，选择即时生效并保存。覆盖启动器按钮、状态、校验提示和诊断报告；系统自带菜单及对话框可能跟随 macOS 语言。
- 更新双语预览、博客稿、使用边界与隐私说明；明确兼容性、独立项目身份和连接快照的限制。

**升级：**先从菜单栏退出旧启动器，再安装 `Local Route Launcher.app`。从 v1.0.0 升级时，确认新版本正常后移除旧启动器应用，避免同时运行两份。保留原偏好设置标识，原地址、端口和应用路径可继续使用。

**要求：**Apple Silicon、macOS 13+，可识别的 Electron 版 ChatGPT。不支持 Intel 或旧版原生 ChatGPT。安装包使用 ad-hoc 签名，未经过 Apple Developer ID 签名或公证。

### English

- Renamed the public app to **Local Route Launcher**, including the app bundle, DMG, website, and documentation. Existing repository URLs are retained.
- Added instant, persistent **English / Simplified Chinese** switching in the main window and menu panel. Covers launcher controls, status, validation messages, and diagnostic reports; macOS-owned menus and dialogs may follow the system language.
- Updated bilingual previews, announcement articles, usage boundaries, and privacy documentation, with explicit compatibility and diagnostic limitations.

**Upgrading:** quit the old launcher from its menu bar panel, then install `Local Route Launcher.app`. When upgrading from v1.0.0, verify the new app and remove the old launcher app; do not run both copies. The preferences identifier is retained, preserving saved host, port, and application path.

**Requirements:** Apple Silicon, macOS 13+, and a detectable Electron version of ChatGPT. Intel and older native ChatGPT apps are unsupported. Binaries are ad-hoc signed, not Developer ID signed or notarized by Apple.

[English introduction](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.en.md) · [中文介绍](https://github.com/oliver804/ChatGPT-Proxy-Launcher/blob/main/docs/ANNOUNCEMENT.md)

Independent project, not affiliated with or endorsed by OpenAI. ChatGPT is a trademark of OpenAI, used only to identify compatibility. Use only authorized networks and services under applicable laws and service terms. Connection snapshots do not guarantee all traffic uses the configured proxy; voice, WebRTC, UDP, and some child processes are outside that guarantee.
