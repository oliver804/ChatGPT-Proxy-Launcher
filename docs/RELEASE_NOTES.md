## Local Route Launcher 1.4.0 — multi-app profiles and a compact interface

正式发布 / Stable release · 2026-10-30。

### 中文

- 新增 ChatGPT、Antigravity App、Antigravity IDE 独立配置与启动入口，保留已有 ChatGPT 设置。
- 主窗口保留三张功能卡片，语言、外观与 GitHub 入口收至右上角；菜单栏/托盘采用紧凑布局。
- 支持九种语言、跟随系统、浅色/深色主题。修复 macOS 缩放/全屏按钮，并保留严格对称的应用图标及原生菜单栏图标。
- 仅在发现可下载的稳定新版时，版本旁显示“有更新”。点击直接下载当前平台安装包，再运行安装包完成更新；无中间弹窗，没有新版时不显示按钮。更新检查仅针对启动器，网络不可用不影响使用。
- 区分代理连通、启动参数、实际连接与已识别后台服务的连接观察，提供本地详细报告。
- 仓库已更名为 `oliver804/Local-Route-Launcher`，应用内及文档链接同步更新。

### English

- Separate ChatGPT, Antigravity App and Antigravity IDE profiles, preserving existing ChatGPT preferences.
- Original three-card main view, compact menu/tray panel and shared language, appearance and GitHub icons at the upper right.
- Nine languages, system/light/dark appearance, working macOS zoom/fullscreen, symmetric app artwork and the native menu-bar symbol.
- The version-adjacent badge appears only when a newer stable launcher release has an installer for this platform. Clicking downloads that installer directly in your browser, without an intermediate panel. Run the downloaded installer to finish updating. No badge is shown otherwise; offline checks do not interrupt use.
- Separate observations for proxy reachability, launch arguments, connections and recognized background services, with local reports.
- Repository links now use `oliver804/Local-Route-Launcher`.

**Compatibility:** macOS 13+ on Apple Silicon, or Windows 10 22H2 / Windows 11 x64. Target apps must be compatible installed builds. Unsupported native builds and restricted Store packages may reject direct launch.

**Validation limits:** Isolated process/connection tests do not establish signed-in account compatibility, model access or complete traffic routing. Antigravity background services require validation with real requests in your environment.

**Distribution:** macOS builds are ad-hoc signed, not notarized; Windows installers are unsigned. Verify release origin and SHA-256 hashes and keep system protections enabled.

**Privacy:** Optional startup update checks send ordinary request metadata to GitHub. They do not include proxy profiles, app paths, reports, accounts or chats. See [privacy details](PRIVACY.en.md).

Independent project, not affiliated with or endorsed by OpenAI or Google. ChatGPT and Antigravity identify compatibility only; trademarks belong to their owners. Use authorized networks and services in accordance with applicable laws and terms. No proxy service is included.
