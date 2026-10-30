# 1.4 UI and interaction baseline / 界面设计记忆

Accepted by Oliver on 2026-10-30. This is the implementation baseline, not a future redesign proposal. Keep the existing three-card content and symmetric brand artwork when making later changes.

## Main window / 主窗口

- Header: native window controls remain functional (close, minimize, zoom/fullscreen). Language, appearance and GitHub are **icon-only** controls at the upper right, with localized tooltips and accessible names.
- Sidebar: brand, three app entries (ChatGPT, Antigravity App, Antigravity IDE), individual running states. Bottom: launcher version and quiet update indicator. No stacked language/appearance selectors at the bottom.
- Right: selected app name, tagline and installed target version where available. Preserve three rounded cards: launch/stop with route and running state; proxy settings with path/choose; connection checks with three result tiles, details and the actual backend observations.
- Do not replace the cards with a flat layout. Use consistent spacing, green accents, readable dark/light surfaces and restrained secondary text.
- Idle footer: two compact lines only. macOS: “关闭窗口后仍可从菜单栏访问。” / “独立项目，与 OpenAI / Google 无隶属或背书关系；商标归各自权利人所有。” Windows uses system tray wording. Show actual errors, progress and action feedback when needed; do not hide actionable messages to achieve the two-line idle appearance.

## Menu / tray panel / 菜单栏与托盘

- Compact brand at top left; language, appearance and GitHub icons at top right.
- Three compact app rows: app name, saved/active endpoint, running status and start/stop action.
- Footer: version/update entry, open main window and quit. Windows also keeps the native right-click tray menu as an accessible fallback.
- Language and appearance preferences are global and persistent, shared with the main window. Retain nine languages, system language selection, RTL layout for Persian/Arabic, and LTR network addresses and paths.

## Launcher updates / 启动器更新

- Only Local Route Launcher updates, not ChatGPT or Antigravity updates.
- Check the repository's stable GitHub Release at startup when enabled; allow manual checks and disabling startup checks.
- A newer version produces a quiet version-adjacent indicator, never an unsolicited modal or automatic download/install.
- An explicitly opened panel shows current/latest version, automatic-check preference, manual check/retry and release notes/download link.
- Offline, invalid response and rate limit failures do not interrupt launching apps. No fake version data. The v1.4.1 shown in the design proposal was illustrative only.
- Compare numeric stable semantic versions, exclude drafts/prereleases, validate release links against the repository, use timeouts and avoid overlapping requests. No update network requests in previews/smoke tests.

## Brand and repository / 图标与仓库

- Follow the strict bilateral symmetry rules in [AGENTS.md](../AGENTS.md). Do not redesign the glyph during UI changes.
- Repository: https://github.com/oliver804/Local-Route-Launcher
- Preserve existing app identity and settings migration keys; a repository rename is not permission to break installed profiles.

## Validation / 验收

Review main/menu in light/dark modes, all languages including RTL, controls with keyboard/accessibility names, persisted preferences and drafts, update success/failure/version cases, close-to-menu/tray, fullscreen/zoom, and original icon symmetry. macOS GUI tests require an interactive session; Windows behavior must be validated in Windows CI, not inferred from a cross-build.


## Reviewed implementation references / 实现参考

These are app-rendered previews with sample diagnostic data, not evidence of live traffic. The update panel intentionally shows the unchecked state rather than an invented release.

- [Main window / 主窗口](images/preview-dark.png)
- [Compact menu / 紧凑菜单](images/ui-menu-dark.png)
- [Update panel / 更新面板](images/ui-updates-dark.png)
