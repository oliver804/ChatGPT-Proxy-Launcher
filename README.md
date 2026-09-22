# ChatGPT Proxy Launcher

**中文** | [English](README.en.md)

一个轻量的原生 macOS 启动器，为兼容的 ChatGPT 桌面应用单独配置 HTTP 代理，无需开启 TUN，也不修改系统代理或 DNS。

**版本：1.0.0 · Apple Silicon · macOS 13+ · MIT License**

## 功能

- 配置并保存代理地址和端口，默认 `127.0.0.1:7890`。
- 携带代理参数启动 ChatGPT；请求正常退出，不强制终止。
- 分别检查代理隧道、实际启动参数和 TCP 连接。
- 菜单栏快捷操作；关闭主窗口后隐藏 Dock 图标，重新打开时恢复。
- 浅色 / 深色外观，统一的应用图标。

## 安装与使用

1. 从本项目 GitHub **Releases** 下载 `ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg`。
2. 打开 DMG，将 **ChatGPT Proxy Launcher** 拖到 **Applications**。
3. 保持 Clash Verge 等 HTTP 代理程序运行，确认其混合端口可用。
4. 在启动器中填写地址与端口，点击“保存设置”。
5. 完全退出已经运行的 ChatGPT，再从启动器点击“启动 ChatGPT”。
6. 点击“查看代理情况”，按需打开详细报告。

代理程序可以关闭 TUN 和系统代理功能，保留其本地混合端口服务。此工具不会替你更改其他代理程序的设置。从 Dock 直接启动 ChatGPT，不会自动附带启动器保存的代理参数。

本项目的默认安装包使用 **ad-hoc 本地签名，未经过 Apple Developer ID 签名或公证**。如 macOS 阻止打开，请核对下载来源，再在“系统设置 → 隐私与安全性”中允许打开。无需关闭 SIP 或系统安全检查。

更新时先从菜单栏退出启动器，再替换应用。无需停止 ChatGPT；已有代理设置会保留。

## 兼容范围与限制

| 项目 | 支持情况 |
| --- | --- |
| 系统 | Apple Silicon，macOS 13 及以上 |
| ChatGPT | 可识别的 Electron 版本；不支持旧版原生应用 |
| 代理 | 无需认证的 HTTP 代理 / Clash 混合端口，支持 IP、域名、IPv6 |
| 网络协议 | Chromium HTTP、HTTPS、WebSocket；禁用 QUIC |
| 界面语言 | 中文；项目文档提供中文与英文 |

此工具不是强制接管全部流量的网络扩展。语音、WebRTC、UDP，以及不识别代理环境变量的子进程不保证经过代理。ChatGPT 或 Electron 更新后，代理行为可能变化。

## 如何理解检查结果

- **代理连通**：启动器经指定代理建立 CONNECT 隧道并获得 TLS 网站响应；HTTP 403 不等于聊天或账号可用。
- **启动参数**：ChatGPT 主进程携带与当前配置匹配的代理参数。
- **实际连接**：快照中观察到应用或其子进程到该代理的 TCP 连接。

一次快照不能证明全部流量都走代理，未观察到连接也不代表直连。域名地址可能无法与连接快照中的数字 IP 匹配。更改配置后需要重启 ChatGPT。

## 隐私

无账号登录、遥测、分析 SDK 或自动上传诊断功能。设置仅保存在本机 macOS 用户偏好中。检查代理时会经配置的代理向 `https://chatgpt.com/` 发起不携带账号信息的 HEAD 请求。

详细报告在本地显示 PID、端点和连接信息。分享前请删除私人路径、内部域名和 IP、公司信息、账号信息或令牌。参见[隐私说明](docs/PRIVACY.md)。

## 开发与构建

需要 Apple Silicon Mac、Xcode Command Line Tools（或 Xcode，Swift 5.9+）与 Python 3。无第三方运行时依赖。

```sh
make check       # 源码隐私检查与 shell 语法检查
make test        # 核心行为测试
make build       # 构建应用
make dmg         # 构建 DMG、纯净源码 ZIP 和校验文件
make verify      # 挂载并验证 DMG、签名及系统图标
```

构建产物：

- `build/release/ChatGPT Proxy Launcher.app`
- `dist/1.0.0/ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg`
- `dist/1.0.0/ChatGPT-Proxy-Launcher-1.0.0-source.zip`
- `dist/1.0.0/SHA256SUMS.txt`

`make integration` 与 `make ui` 需要已登录的 macOS 图形会话；前者仅启动独立测试应用，后者只操作测试窗口。`make previews` 使用模拟状态生成本地界面预览。不要发布真实诊断输出。

[`VERSION`](VERSION) 是构建版本的唯一来源。构建时自动写入应用元数据与安装包名称。源码包只包含明确允许的项目文件，排除 IDE 配置、历史安装包、本机记录和 Git 元数据。

## 项目结构

```text
Sources/       SwiftUI 界面、应用控制、代理与状态检测
Resources/     应用元数据、作者信息、中英文安装说明
Tests/         核心、启动集成、Dock 生命周期与预览工具
scripts/       构建、检查、打包与源码导出
.github/       CI、Release 工作流与 Issue / PR 模板
docs/          架构、隐私与发布说明
```

[贡献指南](CONTRIBUTING.md) · [安全问题](SECURITY.md) · [发布指南](docs/RELEASING.md) · [架构说明](docs/ARCHITECTURE.md) · [更新日志](CHANGELOG.md)

## 作者与许可证

**Oliver** · [oliver804x@gmail.com](mailto:oliver804x@gmail.com)

项目代码使用 [MIT License](LICENSE)。这是独立项目，与 OpenAI 无隶属关系。ChatGPT 等名称属于其各自权利人；Apple 平台符号与框架遵循各自条款，参见[第三方说明](THIRD_PARTY_NOTICES.md)。
