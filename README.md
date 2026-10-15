<h1 align="center">Local Route Launcher</h1>
<p align="center">管理应用启动网络配置的原生 macOS 工具</p>

<p align="center">
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.1.0"><img src="https://img.shields.io/badge/version-1.1.0-168570" alt="Version 1.1.0"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-333333" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-333333" alt="Apple Silicon arm64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License"></a>
</p>
<p align="center">
  <b>简体中文</b> · <a href="README.en.md">English</a><br>
  <a href="https://oliver804.github.io/ChatGPT-Proxy-Launcher/">官网</a> ·
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.1.0">下载安装</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#常见问题">常见问题</a> ·
  <a href="https://github.com/oliver804/ChatGPT-Proxy-Launcher/issues">反馈问题</a>
</p>

## Preview

<table>
  <tr>
    <th width="50%">Dark</th>
    <th width="50%">Light</th>
  </tr>
  <tr>
    <td><a href="docs/images/preview-dark.png"><img src="docs/images/preview-dark.png" alt="深色模式" width="100%"></a></td>
    <td><a href="docs/images/preview-light.png"><img src="docs/images/preview-light.png" alt="浅色模式" width="100%"></a></td>
  </tr>
</table>

<sub>v1.1.0 界面，使用示例诊断数据渲染。应用内可切换简体中文和 English。</sub>

## 简介

Local Route Launcher 保存本地 HTTP 代理设置，并在启动兼容的 Electron 版 ChatGPT 时传入配置。它使用你已运行的代理，不提供网络接入或代理服务。

它通过应用支持的启动参数与环境变量设置代理，不修改系统代理或 DNS。使用 SwiftUI + AppKit 开发，无第三方运行时依赖。

## 功能

- **独立代理**：保存地址与端口，支持无需认证的 HTTP 代理和 兼容的混合代理端口。
- **启动与停止**：携带代理配置启动 ChatGPT，也可请求其正常退出。
- **连接检查**：查看代理连通性、实际启动参数和应用 TCP 连接。
- **菜单栏操作**：随时启动、停止或查看状态；关闭主窗口后隐藏 Dock 图标。
- **原生界面**：支持浅色、深色外观；中英文界面即时切换并记住选择，中英文项目文档。

## 下载与安装

| 版本 | 运行环境 | 下载 |
| --- | --- | --- |
| **v1.1.0** | Apple Silicon · macOS 13+ | [下载 DMG](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/download/v1.1.0/Local-Route-Launcher-1.1.0-arm64.dmg) |

打开 DMG，将 **Local Route Launcher** 拖入 **Applications（应用程序）**。[发布页面](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.1.0)同时提供源码包和 SHA-256 校验文件。

> 仅支持可识别的 **Electron 版 ChatGPT**，不支持旧版原生应用；当前安装包不支持 Intel Mac。

## 快速开始

1. 保持你有权使用的本地 HTTP 代理运行；在启动器语言菜单中选择 **简体中文** 或 **English**。
2. 在启动器填写代理地址与端口，例如 `127.0.0.1` 和 `7890`，点击 **保存设置**。
3. 完全退出已经运行的 ChatGPT，再点击 **启动 ChatGPT**。
4. 点击 **查看代理情况** 检查连接，按需打开详细报告。

**修改配置后需要重启 ChatGPT，后续也请通过启动器打开。** 从 Dock 直接打开 ChatGPT，不会自动附带这里保存的代理配置。

关闭主窗口后，仍可从菜单栏操作。退出启动器不会停止已运行的 ChatGPT。

## 常见问题

<details>
<summary><b>首次打开被 macOS 拦截怎么办？</b></summary>

当前安装包使用 ad-hoc 本地签名，尚未经过 Apple Developer ID 签名或公证。确认来自本项目发布页面后，可在 **系统设置 → 隐私与安全性** 中允许打开，无需关闭 SIP 或系统安全检查。

</details>

<details>
<summary><b>启动器提供代理服务吗？所有流量都会走代理吗？</b></summary>

启动器需要现有的本地 HTTP 代理。它向兼容应用传入配置，不修改系统代理或 DNS，也不保证每个组件都遵循这些设置。

主要覆盖 Chromium 的 HTTP、HTTPS 和 WebSocket 请求，并禁用 QUIC。语音、WebRTC、UDP，以及不识别代理环境变量的子进程不保证经过代理；ChatGPT 或 Electron 更新后，代理行为也可能变化。

</details>

<details>
<summary><b>如何理解连接检查结果？</b></summary>

| 检查项 | 含义 |
| --- | --- |
| 代理连通 | 经指定代理建立 CONNECT 隧道并获得 TLS 网站响应 |
| 启动参数 | ChatGPT 主进程携带与当前配置匹配的代理参数 |
| 实际连接 | 快照中观察到应用或子进程到代理的 TCP 连接 |

HTTP 403 只能说明隧道与 TLS 检查取得了响应，不代表聊天或账号可用。连接检查是即时快照，不能证明全部流量都经过代理；没有观察到连接也不代表直连。域名代理地址可能无法与快照中的数字 IP 匹配。

</details>

<details>
<summary><b>如何更新应用？</b></summary>

从菜单栏退出旧启动器，再安装 **Local Route Launcher.app**。从 v1.0.0 升级时，确认新版本正常后移除旧启动器应用，避免同时运行两份。保留原偏好设置标识，因此原配置可继续使用，ChatGPT 无需停止。语言切换即时生效；macOS 自带菜单和系统对话框可能跟随系统语言。

</details>

## 开发与构建

需要 Apple Silicon Mac、Xcode Command Line Tools（Swift 5.9+）和 Python 3。

```sh
make check       # 隐私与脚本检查
make test        # 核心测试
make build       # 构建应用
make dmg         # 生成 DMG、源码 ZIP 和校验文件
make verify      # 验证安装包、签名与图标
```

应用输出到 `build/release/`，发布文件输出到 `dist/1.1.0/`。[`VERSION`](VERSION) 是构建版本的唯一来源。

`make integration`、`make ui` 需要已登录的 macOS 图形会话，仅操作独立测试应用与窗口；`make previews` 可生成模拟数据界面预览。

欢迎提交 [Issue](https://github.com/oliver804/ChatGPT-Proxy-Launcher/issues) 或 PR。开发细节参见[贡献指南](CONTRIBUTING.md)、[架构说明](docs/ARCHITECTURE.md)和[发布指南](docs/RELEASING.md)。

## 隐私与许可证

无账号登录、遥测或自动上传；配置保存在本机。连接检查会经指定代理向 `chatgpt.com` 发起不携带账号凭据的 HEAD 请求。诊断报告在本地显示，分享前请移除私人路径、内部地址等敏感信息。[隐私说明](docs/PRIVACY.md) · [安全问题](SECURITY.md)

**作者：Oliver** · [oliver804x@gmail.com](mailto:oliver804x@gmail.com)<br>
**许可证：[MIT](LICENSE)** · [更新日志](CHANGELOG.md)

独立项目，与 OpenAI 无隶属、赞助或背书关系。ChatGPT 是 OpenAI 的商标，仅用于说明兼容性。请仅用于有权访问的网络和服务，并遵守适用法律及服务条款。[使用边界](docs/USAGE.md) · [第三方说明](THIRD_PARTY_NOTICES.md) · [项目介绍](docs/ANNOUNCEMENT.md)。

为保持已有链接有效，仓库网址保持不变；应用对外名称为 **Local Route Launcher**。
