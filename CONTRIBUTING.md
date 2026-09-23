# Contributing to NetHUD

Thanks for your interest! NetHUD is a small app with a deliberately tiny scope,
so before opening a PR for a new feature, please open an issue first to discuss it.

## Development setup

```bash
git clone https://github.com/HamzaSamirAmmar/nethud.git
cd nethud
xcodegen generate          # regenerates NetHUD.xcodeproj (requires: brew install xcodegen)
open NetHUD.xcodeproj      # then Cmd+R
```

Requirements: macOS 13+, Xcode 14+.

## Guidelines

- Keep the app small and dependency-free — no third-party packages.
- Match the existing Swift style; no formatting pipeline is configured.
- Bug fixes and small improvements: just open a PR describing the change.
- If you bump `MARKETING_VERSION` in `project.yml`, add a `CHANGELOG.md` entry.

## Releasing (maintainers)

1. Update `MARKETING_VERSION` + `CHANGELOG.md`
2. `git tag vX.Y.Z && git push --tags` — CI builds and publishes the Release
3. Update the Homebrew cask with the new version + SHA256
