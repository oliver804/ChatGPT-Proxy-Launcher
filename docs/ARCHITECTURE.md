# 架构

**中文** | [English](ARCHITECTURE.en.md)

- `ProxyCore.swift`：校验地址和端口；构建进程级参数与环境变量；执行代理探测；解析进程树及连接快照。用户输入通过独立参数传给子进程，不经过 shell 插值。
- `LauncherModel.swift`：共享状态和用户偏好；借助 Launch Services 启动应用，通过正常退出请求停止应用。主窗口和菜单栏使用同一个实例，定时刷新仅检查本地运行状态。
- `LauncherApp.swift`：SwiftUI 主窗口、菜单栏面板与 Dock 显示生命周期。仅跟踪主窗口关闭事件，菜单栏面板或报告关闭不会隐藏 Dock。
- `BrandMark.swift`：共享图标源；界面和 ICNS 构建均使用同一个组件。

启动时传入 Chromium `--proxy-server`，同时为支持的子进程设置 HTTP/HTTPS/ALL_PROXY 与大小写兼容变量。localhost 保留直连，避免影响本地工具。环境变量不是对子进程全部流量的强制约束。

构建使用 `VERSION` 生成应用版本；应用元数据保留兼容的偏好域。发布包使用干净的临时目录，带中英文安装说明与 MIT 许可证。构建参数映射源文件路径，避免把开发者目录写入可执行文件。

CI 执行源码检查、核心测试、构建和安装包结构校验。没有图形会话的环境跳过系统图标服务检查，但仍校验图标声明和 ICNS 解码。发布前可在本地图形会话中执行完整 `make verify`、`make integration` 和 `make ui`。
