# GitHub 发布指南

**中文** | [English](RELEASING.en.md)

## 首次发布

1. 在 GitHub 创建你自己的空仓库。此项目不预设远端地址或 GitHub 账号。
2. 检查 `git status` 与待提交文件，确认只包含源码和项目文档。不要上传整个工作目录。
3. 原作者的公开提交身份使用 `Oliver <oliver804x@gmail.com>`。其他贡献者使用各自愿意公开的姓名和邮箱；不复用 Oliver 身份。
4. 将本地仓库关联到你实际创建的远端，再推送 `main`。
5. 在 GitHub Actions 中确认 CI 成功，手动检查发布内容。
6. 给经审核的提交打标签 `v1.4.0`，然后将该标签推送到远端。

`v*` 标签会运行 Release 工作流：检查标签与 `VERSION` 一致、执行源码与核心检查、构建并验证 DMG、导出纯净源码包，最后创建带附件的 **草稿 Release**。在 GitHub 检查草稿说明和文件后，再手动点击 Publish release。工作流使用当前仓库的临时 `GITHUB_TOKEN`，无需把个人令牌写入项目。

需要直接正式发布时，可使用附注标签，并在标签说明中单独添加一行 `Publish-Release: true`。工作流只在所有检查通过、附件上传完成后发布。没有这行标记的标签仍只生成草稿。

## 本地发布产物

```sh
make check
make test
make integration
make ui
make dmg
make verify
```

只上传 `dist/1.4.0/` 中以下四个文件：

- `Local-Route-Launcher-1.4.0-arm64.dmg`
- `Local-Route-Launcher-1.4.0-windows-x64-setup.exe`
- `Local-Route-Launcher-1.4.0-source.zip`
- `SHA256SUMS.txt`

校验文件使用相对文件名。在产物目录运行 `shasum -a 256 -c SHA256SUMS.txt` 可验证完整性。应用内包含作者信息与许可证；默认签名为 ad-hoc，未公证。

## 后续版本

修改 `VERSION`，同步 README 中的版本/下载示例与 `CHANGELOG.md`，并检查安全支持政策。安装包名称、应用版本和校验文件由脚本自动生成。不要使用旧工作目录中的历史 DMG，也不要手动更改已发布版本的二进制文件。

## 隐私复核

- 阅读源码检查结果，人工确认新增文档与图片不含私人或组织信息。
- 检查 Git 的作者/提交者身份，不发布含个人身份或凭据的历史。
- 默认导出的源码 ZIP 不含 Git 历史和本地配置。
- 不上传原始诊断报告、屏幕截图、签名证书、配置备份或构建缓存。
- 工作流尚未在你的 GitHub 仓库执行前，不能把本地通过视为远端 CI 已通过。

## 官网（GitHub Pages）

官网源码位于 `site/`，包含中英文首页及 `blog/` 下的双语版本文章。运行 `make site` 生成并检查 `build/site/`；可用 `python3 -m http.server 4173 --directory build/site` 本地预览。构建只复制明确列出的网页和已审核图片，不发布仓库根目录。

首次部署需由仓库管理员在 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。随后推送网站修改，或在 **Actions → Website → Run workflow** 手动触发。工作流检查双语链接、资源、下载版本和隐私后，仅部署网站文件。PR 只构建检查，不部署。

官网地址为 `https://oliver804.github.io/Local-Route-Launcher/`，英文版为其 `en/` 子路径。更新版本时同步两种语言的安装包链接和版本文案；`make site` 会核验下载链接与 `VERSION` 一致。官网发布不修改应用 Release 或标签。

### 搜索引擎与分享信息

构建会生成 `sitemap.xml`，列出中英文首页、双语版本文章及对应语言链接。两页包含独立的标题、描述、规范网址、分享预览和软件结构化数据；更新版本时同步其中的 `softwareVersion` 和 `downloadUrl`。不添加未经证实的评分或评论，结构化数据不代表一定获得搜索富媒体结果。

在 Google Search Console 使用官网完整地址创建“网址前缀”资源，在 Bing Webmaster Tools 添加同一站点。使用各平台提供的公开 HTML 验证标签完成所有权验证，再提交 `https://oliver804.github.io/Local-Route-Launcher/sitemap.xml`。验证标签需要持续保留；它们不是账号密码或 API 访问令牌，后两者不得写入源码。

项目子路径下的 `robots.txt` 不会控制抓取，因此不在此处生成。需要修改抓取规则时，应由站点所有者维护主机根路径 `/robots.txt`。网站地图不使用部署时间伪造 `lastmod`。提交后在各平台检查抓取与收录状态；成功提交不保证收录或排名。

## Windows 构建与跨平台发布

在 Windows x64 安装 .NET SDK 10.0.402 与 Inno Setup 6，然后执行：

```powershell
./scripts/build-windows.ps1 -Test
```

脚本构建自带运行环境的 EXE 安装包，检查当前用户安装、隔离测试应用的启动与连接、十八种语言/外观组合、窗口隐藏/恢复及卸载。Windows CI 使用 Windows Server，不验证真实 ChatGPT 登录账号或全部应用安装版本。安装向导为英文，应用界面支持九种语言。

Windows 与 macOS 构建通过后，Release 工作流收集产物并生成统一校验清单，再创建草稿。只有带 `Publish-Release: true` 标记的注解 tag 才会自动公开发布。旧版本附件保持不变。Windows 本地配置在卸载后保留；退出托盘中的启动器后再升级或卸载。发布前核对两个平台构建、发布及官网任务均通过。

Windows 安装包尚未进行 Authenticode 签名，不应宣称已签名。安装目录保留随运行库分发的 .NET 许可与第三方声明。源码包排除 bin/obj、测试日志及本地配置。
