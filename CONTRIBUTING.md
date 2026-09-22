# Contributing / 贡献指南

**中文**

欢迎通过 Issue 描述问题或建议，通过 Pull Request 提交改进。界面当前为中文；请同步更新受影响的中英文文档。

1. 使用自己的 GitHub 账号 Fork 项目并创建主题分支。
2. 保持修改聚焦，不改变系统代理、DNS、TUN 或其他应用的配置。
3. 运行 `make check` 和 `make test`；构建变更还需执行 `make dmg` 与 `make verify`。
4. 修改应用生命周期时运行 `make integration` / `make ui`；需要已登录的 macOS 图形会话。
5. PR 中描述问题、改动和实际验证结果。未执行的检查请明确标注。

不要提交构建目录、IDE 设置、真实连接报告、个人路径、令牌、证书、公司资料或账户信息。截图应仅包含演示内容。公开提交前确认 Git 作者姓名和邮箱是你愿意公开的信息；仓库内的 Oliver 身份仅供原作者使用。

提交的代码应为你有权贡献的内容，并适用项目的 [MIT License](LICENSE)。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

**English**

Use issues for bug reports or suggestions, and pull requests for improvements. The interface is currently Chinese; update affected Chinese and English documentation together.

1. Fork using your own GitHub account and create a focused branch.
2. Keep changes scoped; do not change system proxy, DNS, TUN, or other applications' settings.
3. Run `make check` and `make test`. Build changes also require `make dmg` and `make verify`.
4. Run `make integration` / `make ui` for application lifecycle changes in a logged-in macOS graphical session.
5. Describe the problem, changes, and actual verification in the PR. Identify checks you did not run.

Do not commit build output, IDE settings, live connection reports, personal paths, tokens, certificates, company material, or account data. Screenshots should contain sample content only. Confirm your Git author name and email are suitable for publication; Oliver's identity is for the original author only.

Contribute only material you have the right to provide under the project's [MIT License](LICENSE). Report security issues privately as described in [SECURITY.md](SECURITY.md).
