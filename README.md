# NetHUD

A tiny macOS menu bar app that shows live network speeds:

```
↑12 KB/s ↓1.2 MB/s
```

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Live upload/download speeds** in the menu bar, always visible
- **Primary-interface tracking** — follows the default route (`en0` on Wi-Fi,
  `utun*` when a VPN is up), so traffic is never double-counted across tunnels
- **Per-interface breakdown** and session totals one click away
- Configurable refresh rate (0.5s / 1s / 2s)
- Reads byte counters via `getifaddrs()` — no permissions, no network extension,
  no third-party dependencies

## Screenshot

<!-- TODO: replace with a real screenshot of the menu bar + dropdown.
     Save it as Docs/screenshot.png and it will render automatically. -->

![NetHUD screenshot](Docs/screenshot.png)

## Install

### Homebrew

```bash
brew install --cask <your-github-username>/tap/nethud
```

### From a release

Download `NetHUD.zip` from the [Releases](../../releases) page, unzip, and drag
`NetHUD.app` to `/Applications`.

> The app is not notarized, so macOS shows an "unidentified developer" warning
> on first launch. Right-click the app → **Open** → **Open** to approve it once.
> If you install via Homebrew, this step is skipped.

### Build from source

```bash
xcodegen generate          # requires: brew install xcodegen
xcodebuild -project NetHUD.xcodeproj -scheme NetHUD -configuration Release \
  -derivedDataPath build SYMROOT=build/Release build
cp -R build/Release/Release/NetHUD.app /Applications/
```

Or open `NetHUD.xcodeproj` in Xcode and press Cmd+R.

Start at login: System Settings → General → Login Items → add `NetHUD.app`.

## Privacy

NetHUD collects nothing, sends nothing, and phones nobody. It reads interface
byte counters from the operating system and renders them locally. That's the
whole app.

## Requirements

- macOS 13 Ventura or later
- Xcode 14+ only if building from source

## License

[MIT](LICENSE) © 2026 hamza
