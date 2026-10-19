# Local Route Launcher 新增 Windows 版：下载安装即可使用

之前做了一个 macOS 小工具 **Local Route Launcher**，为兼容的 ChatGPT 桌面应用保存独立的网络启动配置，减少反复修改系统设置的麻烦。现在，**v1.2.0 新增 Windows 版**。

## 这次更新

- **Windows 安装包**：运行 EXE 即可为当前用户安装，内置运行环境，无需开发工具。
- **中英文切换**：支持简体中文、English，以及深浅外观。
- **系统托盘**：启动、停止和检查连接，关闭主窗口后仍可访问。
- **本地连接检查**：查看连通性、启动参数和应用 TCP 连接快照。
- **继续支持 macOS**：保留 DMG 下载与菜单栏操作。

安装后，填写已有本地服务的地址和端口，保存设置；完全退出 ChatGPT，再通过启动器打开。Windows 会尝试查找已安装的兼容应用，也可以手动选择 `ChatGPT.exe`。

## 使用前了解

支持 **Windows 10 22H2 / Windows 11 x64** 与 **Apple Silicon、macOS 13+**。需要可识别的 Electron 版 ChatGPT；旧原生版本、Intel Mac、Windows ARM64 暂不支持。受限制的商店安装包可能无法直接启动。

工具不提供网络接入服务，不修改系统 DNS，也不保证所有组件遵循启动配置。连接检查仅为快照。Windows 自动化验证使用隔离测试应用，不代表已验证全部 ChatGPT 版本与账号场景。

Windows 安装包暂未签名，macOS 版本未公证。请核对官方发布来源及 SHA-256，保持系统安全功能开启。

[下载 v1.2.0](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.2.0) · [GitHub 源码](https://github.com/oliver804/ChatGPT-Proxy-Launcher) · [项目官网](https://oliver804.github.io/ChatGPT-Proxy-Launcher/)

项目采用 MIT 许可证，欢迎提交兼容性反馈和改进建议。

*作者：Oliver。独立项目，与 OpenAI 无隶属或背书关系。ChatGPT 商标仅用于说明兼容性。请仅用于有权访问的网络和服务，遵守适用法律与服务条款。本文使用 AI 辅助起草。*
