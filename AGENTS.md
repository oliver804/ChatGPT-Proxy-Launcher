# Project conventions for contributors and coding agents

## Brand icon: preserve bilateral symmetry

The app's white route glyph MUST remain strictly left/right symmetric. This is an explicit user requirement, confirmed during the 1.4.0 UI review on 2026-10-30. Do not replace it with an asymmetric interpretation or independently adjust the two branches for optical balance.

- Canonical artwork: `Sources/BrandMark.swift`, `RouteGlyph` and `BrandMark`.
- The symmetry axis is normalized `x = 0.50`; mirror the same branch coordinates using `direction = -1, +1`.
- Both arrow tips must have the same height (`y = 0.16`), reflected horizontal positions (`x = 0.12 / 0.88`), equal arrowhead lengths, matching curves and identical stroke widths/caps/joins. The stem stays centered.
- Scale uniformly. Never stretch one dimension, skew the glyph, or hand-edit separate raster variants.
- App UI, menu panel branding, macOS Finder/Dock/DMG and Windows icons must use exports of the same artwork. `site/assets/icon.png` is the shared raster source for Windows packaging; regenerate it when the canonical artwork changes.
- The macOS **system menu bar status icon** is intentionally the native template SF Symbol `arrow.triangle.branch`. Preserve native proportions, template rendering and adaptation to dark/light/highlighted backgrounds; do not replace it with a colored app icon or stretch it.
- Existing regression coverage is in `Tests/MenuBarIconTests.swift`: mirrored silhouette comparison plus native status-icon appearance checks. Do not weaken or remove the symmetry assertion to accommodate a changed drawing.
- For icon changes, run `make ui` in an interactive macOS session, then build/verify the package with `make dmg verify`. Review small (16/32 px) and large icons plus light/dark main-window and menu-panel previews. CI compiles the native rendering tests; local GUI execution is still required.

## Design proposals versus implementation

When a user requests only a mockup or says “先不要做”, keep proposed UI changes out of production app code and release packages. Record accepted constraints separately; a mockup is not approval to ship its layout.

## Accepted 1.4 UI baseline

The user approved implementation on 2026-10-30. Read [docs/UI-DESIGN-1.4.md](docs/UI-DESIGN-1.4.md) before changing window layout, menu/tray UI, footer copy, localization or update checks. Preserve the three-card right pane, compact two-line idle footer, shared icon-only header controls and quiet launcher-only updates. The repository is now `oliver804/Local-Route-Launcher`; do not reintroduce the old repository URL or change legacy settings keys merely to match its name.

The final 2026-10-30 correction requires a single 48-point header, exact Lucide languages/sun-moon icons, 380-point menu panel, no bottom action/result row, and an update badge only when a matching newer installer is available. Clicking the badge directly downloads the installer; do not restore the superseded update popup. See the design baseline for measurements.
