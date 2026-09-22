## 中文

为兼容的 Electron 版 ChatGPT 单独配置 HTTP 代理。支持地址和端口设置、正常启停、代理检查、菜单栏快捷操作，以及关闭主窗口后隐藏 Dock 图标。

- 适用 Apple Silicon、macOS 13+；界面为中文，文档为中英文。
- 下载 arm64 DMG，拖入 Applications 安装。
- 安装包使用 ad-hoc 签名，未经过 Apple Developer ID 签名或公证。
- 校验下载完整性：将三个附件放在同一目录，运行 `shasum -a 256 -c SHA256SUMS.txt`。
- 不修改系统代理或 DNS，不保证语音、WebRTC、UDP 和所有子进程经过代理。

## English

Configure an HTTP proxy for compatible Electron versions of ChatGPT. Includes proxy settings, graceful start/stop, diagnostics, menu bar access, and Dock hiding when the main window closes.

- Apple Silicon, macOS 13+; Chinese interface with Chinese and English documentation.
- Download the arm64 DMG and drag the app to Applications.
- Ad-hoc signed; not Developer ID signed or notarized by Apple.
- To verify downloads, place all three attachments together and run `shasum -a 256 -c SHA256SUMS.txt`.
- Does not change system proxy or DNS. Voice, WebRTC, UDP, and all child processes are not guaranteed to use the proxy.

Author / 作者：Oliver · oliver804x@gmail.com

MIT License. Independent project; not affiliated with OpenAI. / 独立项目，与 OpenAI 无隶属关系。
