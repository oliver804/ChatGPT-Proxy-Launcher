# GitHub 发布指南

**中文** | [English](RELEASING.en.md)

## 首次发布

1. 在 GitHub 创建你自己的空仓库。此项目不预设远端地址或 GitHub 账号。
2. 检查 `git status` 与待提交文件，确认只包含源码和项目文档。不要上传整个工作目录。
3. 原作者的公开提交身份使用 `Oliver <oliver804x@gmail.com>`。其他贡献者使用各自愿意公开的姓名和邮箱；不复用 Oliver 身份。
4. 将本地仓库关联到你实际创建的远端，再推送 `main`。
5. 在 GitHub Actions 中确认 CI 成功，手动检查发布内容。
6. 给经审核的提交打标签 `v1.0.0`，然后将该标签推送到远端。

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

只上传 `dist/1.0.0/` 中以下三个文件：

- `ChatGPT-Proxy-Launcher-1.0.0-arm64.dmg`
- `ChatGPT-Proxy-Launcher-1.0.0-source.zip`
- `SHA256SUMS.txt`

校验文件使用相对文件名。在产物目录运行 `shasum -a 256 -c SHA256SUMS.txt` 可验证完整性。应用内包含作者信息与许可证；默认签名为 ad-hoc，未公证。

## 后续版本

修改 `VERSION`，同步 README 中的版本/下载示例、`CHANGELOG.md` 和安全支持版本。安装包名称、应用版本和校验文件由脚本自动生成。不要使用旧工作目录中的历史 DMG，也不要手动更改已发布版本的二进制文件。

## 隐私复核

- 阅读源码检查结果，人工确认新增文档与图片不含私人或组织信息。
- 检查 Git 的作者/提交者身份，不发布含个人身份或凭据的历史。
- 默认导出的源码 ZIP 不含 Git 历史和本地配置。
- 不上传原始诊断报告、屏幕截图、签名证书、配置备份或构建缓存。
- 工作流尚未在你的 GitHub 仓库执行前，不能把本地通过视为远端 CI 已通过。
