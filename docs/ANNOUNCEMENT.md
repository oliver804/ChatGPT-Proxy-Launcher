# 开源一个 macOS 小工具：Local Route Launcher

在 Mac 上同时运行多个需要不同网络配置的应用时，反复调整系统设置容易影响其他程序。我做了一个免费开源小工具 **Local Route Launcher**，在本机保存网络启动配置，并在启动兼容的 ChatGPT 桌面应用时传入。

项目使用 SwiftUI + AppKit 开发，采用 MIT 许可证。它不提供网络接入服务，也不修改系统代理或 DNS，适合已具备合法、授权网络环境的用户。

## 可以做什么

- 保存本地服务的地址和端口。
- 按配置启动 ChatGPT，或请求应用正常退出。
- 检查连通性、启动参数及 TCP 连接快照。
- 通过菜单栏操作，关闭主窗口后自动隐藏 Dock 图标。
- **简体中文与 English 即时切换**，自动记住选择，支持浅色和深色外观。

## 适用范围

当前 **v1.1.0** 面向 Apple Silicon、macOS 13 及以上系统，支持可识别的 Electron 版 ChatGPT；旧版原生应用和 Intel Mac 暂不支持。

连接检查只反映检查时的状态，不能证明全部流量都使用了配置。语音、WebRTC、UDP 等流量不在保证范围内。系统自带菜单和对话框可能跟随 macOS 的语言。

发布包尚未经过 Apple 公证。安装前请核对源码、发布页面和系统提示。

## 项目地址

[GitHub 源码](https://github.com/oliver804/ChatGPT-Proxy-Launcher) · [项目官网](https://oliver804.github.io/ChatGPT-Proxy-Launcher/) · [下载 v1.1.0](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.1.0)

欢迎提交兼容性反馈、问题报告和改进建议。

*作者：Oliver。独立项目，与 OpenAI 无隶属或背书关系。ChatGPT 是 OpenAI 的商标，仅用于说明兼容性。请仅用于有权访问的网络和服务，并遵守适用法律及服务条款。本文使用 AI 辅助起草。*
