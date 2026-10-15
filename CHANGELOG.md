# Changelog / 更新日志

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
