# NetHUD

A tiny macOS menu bar app that shows live network speeds:

```
↑12 KB/s ↓1.2 MB/s
```

- Tracks the **primary interface** (the one owning the default route — `en0` for
  Wi-Fi, `utun*` when a VPN like Surfshark is up), so traffic isn't double-counted.
- Click it for a per-interface breakdown, session totals, and a refresh-rate picker.
- Reads byte counters via `getifaddrs()` — no special permissions, no network extension.

## Layout

```
project.yml              xcodegen spec (regenerates NetHUD.xcodeproj)
NetHUD/Sources/
  App.swift              entry point — MenuBarExtra scene
  TrafficMonitor.swift   counter polling, deltas, primary-interface detection
  MenuBarView.swift      dropdown UI
  Format.swift           speed/byte formatting
```

## Build & run

```bash
xcodegen generate          # only needed if project.yml changes
xcodebuild -project NetHUD.xcodeproj -scheme NetHUD -configuration Debug \
  -derivedDataPath build SYMROOT=build/Debug build
open build/Debug/Debug/NetHUD.app
```

Or just open `NetHUD.xcodeproj` in Xcode and press Cmd+R.

## Install

```bash
xcodebuild -project NetHUD.xcodeproj -scheme NetHUD -configuration Release \
  -derivedDataPath build SYMROOT=build/Release build
cp -R build/Release/Release/NetHUD.app /Applications/
open /Applications/NetHUD.app
```

Start at login: System Settings → General → Login Items → add `NetHUD.app`.

## Notes

- Runs as an agent (`LSUIElement`) — no Dock icon.
- Interface counters are 32-bit and wrap at 4 GB; the monitor detects wraps and resets.

## License

MIT
