# 隐私说明

**中文** | [English](PRIVACY.en.md)

## 本地保存的数据

界面语言、代理地址、端口和所选应用路径保存于 macOS 用户偏好域 `local.chatgpt-proxy-launcher`。启动器不读取或保存 ChatGPT 密码、Cookie、令牌或聊天记录。

## 网络请求

启动器在启动前或用户点击检查时，通过配置的代理向 `https://chatgpt.com/` 发起 HEAD 请求，以检查 CONNECT 隧道和 TLS。该请求不附带 ChatGPT 账号凭据，网站仍会看到代理出口 IP 等正常网络请求信息。

ChatGPT 自身及代理服务的数据处理由对应软件决定。启动器不包含遥测、分析 SDK、自动上传或自动更新服务。

## 诊断报告

启动器只读检查应用进程、启动参数及已建立的 TCP 连接。详细报告在本地显示进程 ID、端点及诊断信息；复制报告只写入本机剪贴板。报告可能包含内部网络信息，公开前请脱敏。

## 开源发布范围

作者公开身份仅为 Oliver 和 oliver804x@gmail.com。源码导出采用文件白名单；排除本地 IDE 配置、构建缓存、旧安装包、真实日志、系统截图与 Git 元数据。发布流程对源码和应用文件扫描私人路径、访问令牌、认证 URL、私钥、内部 IPv4 地址和非指定邮箱。

这些检查只覆盖已知模式，无法识别全部敏感内容。新增文件仍需人工审查，尤其是截图、日志、证书与组织资料。仓库不提供任何公司归属信息。

1.1.0 更名后保留历史偏好设置域，使原配置继续可用。切换界面语言不会修改或保存网络设置。

## Windows 本地配置与检查

Windows 将语言、外观、地址、端口及应用路径保存到 `%LOCALAPPDATA%\LocalRouteLauncher\settings.json`，不读取账号、Cookie 或聊天记录。卸载保留此文件，可自行删除。启动时仅向子进程传入配置；只有点击连接检查才发送经代理的 HEAD 请求。自动检测查询当前用户已安装的应用包，进程检查读取 Windows 进程列表并在本机筛选所选应用及子进程；报告不包含其他应用的进程清单。TCP 连接由系统 API 读取，不抓取通信内容，也不自动上传。系统代理、DNS、注册表网络配置均不修改。

## 官网访问统计

项目官网的中文和英文页面使用 Google Analytics 4（衡量 ID：`G-QVHYT7RFW9`）分析访问情况。官网加载 Google 提供的 `gtag.js`，向 Google 发送页面浏览等访问数据，可包含页面地址、来源、浏览器和设备信息；Google Analytics 使用第一方 Cookie 区分访客与会话。实际启用的增强型衡量事件和数据保留期限以该 Analytics 资源设置为准。

这些统计仅用于官网，不集成到 macOS 或 Windows 启动器中，也不读取应用中的代理配置、账号或聊天记录。浏览器限制、内容拦截工具或网络不可达可能阻止统计。有关 Google 的数据处理，请参阅 [Google 隐私政策](https://policies.google.com/privacy) 和 [Google Analytics Cookie 说明](https://support.google.com/analytics/answer/11397207?hl=zh-Hans)。

### Microsoft Clarity

官网同时使用 Microsoft Clarity（项目 ID：`z0krfkfwwu`），独立于 Google Analytics 加载，用于分析访客行为和改进页面体验。Clarity 将页面及交互数据（例如浏览、点击、滚动，以及浏览器和设备信息）发送给 Microsoft，生成热力图和会话回放。它可能使用第一方、第三方 Cookie 及其他跟踪技术；实际采集受项目设置、同意状态、浏览器和网络条件影响，不保证在所有地区均可访问。

会话回放重建的是官网页面交互，不是录制电脑屏幕；不会访问启动器内的代理配置或 ChatGPT 对话。本次接入未添加自定义用户身份标识，也未覆盖 Clarity 的默认遮罩设置。Microsoft 的数据处理和使用方式见 [Microsoft 隐私声明](https://privacy.microsoft.com/privacystatement)，另见 [Clarity 隐私信息](https://clarity.microsoft.com/privacy)。

v1.4.0：Antigravity App / IDE 的无凭据 HEAD 探测目标为 `https://antigravity.google/`。每个应用配置独立保存在本机；不修改目标应用配置、不提交 AI 提示词。
