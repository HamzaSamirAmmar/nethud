# Changelog

All notable changes to NetHUD are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org).

## [2.0.1] — 2026-09-25

### Fixed
- Close popover on unfocus (clicking outside, switching applications, or deactivation), matching macOS Control Center and Wi-Fi behavior
- Ensure the popover always reopens to a fresh dashboard rather than retaining previous subscreen navigation (such as Settings)

## [2.0.0] — 2026-09-24

### Added
- Redesigned popover: instrument panel, live traffic graph, and Settings screen
- Five menu bar themes with live previews in Settings
- Configurable update intervals (0.5s / 1s / 2s)

## [1.0.1] — 2026-09-23

### Fixed
- Menu bar label no longer shifts as traffic values change — speeds now render
  in fixed-width fields with a fully monospaced font, so neighboring menu bar
  items (clock, Control Center) stay perfectly still

## [1.0.0] — 2026-09-23

### Added
- Live upload/download speeds in the macOS menu bar
- Five menu bar themes: Classic, Compact, Vivid, Vivid Compact, and Zen
  (download-only) — remembered across launches
- Primary-interface tracking (default route) — Wi-Fi and VPN aware, no double counting
- Per-interface breakdown, session totals, and a refresh-rate picker (0.5s / 1s / 2s)
- Wrap-aware 32-bit interface counter handling (4 GB rollover, interface resets)
- Clean re-baseline after system wake — no speed spikes after sleep
- Runs as a menu bar agent (`LSUIElement`) — no Dock icon
- Built-in "Start at Login" toggle (`SMAppService`, macOS 13+)
- App icon and version footer in the dropdown
