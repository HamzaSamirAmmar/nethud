# Changelog

All notable changes to NetHUD are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org).

## [1.0.0] — 2026-09-23

### Added
- Live upload/download speeds in the macOS menu bar
- Primary-interface tracking (default route) — Wi-Fi and VPN aware, no double counting
- Per-interface breakdown, session totals, and a refresh-rate picker (0.5s / 1s / 2s)
- Wrap-aware 32-bit interface counter handling (4 GB rollover, interface resets)
- Runs as a menu bar agent (`LSUIElement`) — no Dock icon
- App icon and version footer in the dropdown
