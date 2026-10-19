# 架构

**中文** | [English](ARCHITECTURE.en.md)

- `ProxyCore.swift`：校验地址和端口；构建进程级参数与环境变量；执行代理探测；解析进程树及连接快照。用户输入通过独立参数传给子进程，不经过 shell 插值。
- `LauncherModel.swift`：共享状态和用户偏好；借助 Launch Services 启动应用，通过正常退出请求停止应用。主窗口和菜单栏使用同一个实例，定时刷新仅检查本地运行状态。
- `LauncherApp.swift`：SwiftUI 主窗口、菜单栏面板与 Dock 显示生命周期。仅跟踪主窗口关闭事件，菜单栏面板或报告关闭不会隐藏 Dock。
- `BrandMark.swift`：共享图标源；界面和 ICNS 构建均使用同一个组件。

启动时传入 Chromium `--proxy-server`，同时为支持的子进程设置 HTTP/HTTPS/ALL_PROXY 与大小写兼容变量。localhost 保留直连，避免影响本地工具。环境变量不是对子进程全部流量的强制约束。

构建使用 `VERSION` 生成应用版本；应用元数据保留兼容的偏好域。发布包使用干净的临时目录，带中英文安装说明与 MIT 许可证。构建参数映射源文件路径，避免把开发者目录写入可执行文件。

CI 执行源码检查、核心测试、构建和安装包结构校验。没有图形会话的环境跳过系统图标服务检查，但仍校验图标声明和 ICNS 解码。发布前可在本地图形会话中执行完整 `make verify`、`make integration` 和 `make ui`。

## 界面语言

`Sources/Localization.swift` 维护中英文文案。首次启动跟随系统语言，非中文环境回退英文；明确选择后保存到 `interfaceLanguage`。SwiftUI 观察模型语言，后台检查接收不可变语言快照。操作期间禁用切换，切换后清空旧语言诊断文本，不保存网络编辑。系统对话框可能保持 macOS 语言。

## Windows implementation / Windows 实现

- `Windows/Core`: endpoint validation, case-insensitive child environment, atomic JSON preferences, proxy probe and process-family filtering. Tests run without WPF or a live account.
- `Windows/App`: WPF interface, bilingual strings, WinForms notification-area icon, fixed PowerShell/CIM process queries and native PID-scoped TCP tables. Executable paths and user settings are never interpolated into shell scripts. Only the selected app is asked to close; production operations never force-kill ChatGPT.
- `Windows/Fixture`: isolated test application named ChatGPT.exe, built only for validation and never bundled in release installers.
- `scripts/build-windows.ps1`: generates the shared ICO, publishes self-contained .NET, includes runtime notices and builds a per-user Inno Setup installer.
- `scripts/test-windows.ps1`: installs to a path containing spaces, tests the installed executable with the fixture, renders both languages/themes, checks close/reopen behavior and uninstalls.

Windows 设置保存在用户本地应用数据目录；不需要管理员权限，不注册系统服务，不自动开机启动。安装包与应用图标均来自已审阅的原创品牌图。关闭窗口隐藏任务栏入口，托盘仍可恢复窗口；退出启动器不结束目标应用。当前测试不覆盖真实 ChatGPT 账号或所有商店安装版本。
