# Changelog

All notable changes to omarchy-arrange-monitor. Versions follow [Semantic Versioning](https://semver.org/).
Versions before the release of 2026-09-30 were assigned retroactively from the commit history.

## 2.0.0 – 2026-09-30

### Changed

- **Breaking:** renamed to fit the naming of the other widget clones (`omarchy-<feature>-<widget>`): repository `omarchy-display-arrange` → `omarchy-arrange-monitor`, plugin id `omarchy_plus_display-arrange` → `omarchy_plus_arrange.monitor`, display name "Display Arrange" → "Display (Arrange)". GitHub redirects the old repository URL, but an installed copy keeps the old id: remove it and install again (see README, *Migrating from omarchy-display-arrange*).
- Author set to "Claude Code / Thomas Alt"; README: Related and Changelog sections; this CHANGELOG.

## 1.1.1 – 2026-09-30

### Fixed

- Arranging reset the internal display to mode `preferred` and dropped its color-management preset (e.g. `cm = "dp3"`), at runtime and in the rules persisted to `monitors.lua`. Both displays now keep mode, scale and preset; the persisted internal rule never takes over a runtime-only resolution. `arrange.sh` gained `--dry-run`.

## 1.1.0 – 2026-09-30

### Added

- **Display Resolution** section below the brightness slider: one-click switch between configurable sizes (default 3840×2160 at scale 1.5, 2560×1440 and 1920×1080 at 1), runtime only, keeping position and color preset.

## 1.0.0 – 2026-09-07

### Added

- Initial release: brightness slider plus Left/Top/Right arrangement for a laptop + one external monitor, persisted to `monitors.lua`. Plugin id `omarchy_plus_display-arrange`.
- README disclaimer on how the plugin was built (2026-09-08).
