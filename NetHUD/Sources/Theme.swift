import SwiftUI

enum MenuBarTheme: String, CaseIterable, Identifiable {
    case classic
    case compact
    case vivid
    case vividCompact
    case zen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .compact: return "Compact"
        case .vivid: return "Vivid"
        case .vividCompact: return "Vivid Compact"
        case .zen: return "Zen"
        }
    }

    /// Short units ("↑12K ↓1.2M") instead of full ones ("↑12 KB/s ↓1.2 MB/s").
    var isCompact: Bool { self == .compact || self == .vividCompact }

    /// Colored arrows (green up / blue down) instead of system color.
    var isColored: Bool { self == .vivid || self == .vividCompact }

    /// Zen shows download only.
    var showsUpload: Bool { self != .zen }

    static let storageKey = "menuBarTheme"
}

/// Palette shared with the app icon: green up arrow, blue down arrow.
enum ThemePalette {
    static let upload = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let download = Color(red: 0.04, green: 0.52, blue: 1.0)
}

private extension View {
    /// Applies the style only when a color is present (nil keeps system color).
    @ViewBuilder
    func optionalForegroundStyle(_ color: Color?) -> some View {
        if let color {
            foregroundStyle(color)
        } else {
            self
        }
    }
}

/// The live label shown in the macOS menu bar, rendered per theme.
struct MenuBarLabel: View {
    @ObservedObject var monitor: TrafficMonitor

    private var uploadColor: Color? {
        monitor.theme.isColored ? ThemePalette.upload : nil
    }

    private var downloadColor: Color? {
        monitor.theme.isColored ? ThemePalette.download : nil
    }

    var body: some View {
        let compact = monitor.theme.isCompact
        let upload = compact ? Format.speedCompact(monitor.upSpeed) : Format.speed(monitor.upSpeed)
        let download = compact ? Format.speedCompact(monitor.downSpeed) : Format.speed(monitor.downSpeed)

        HStack(spacing: 4) {
            if monitor.theme.showsUpload {
                Text("↑\(upload)")
                    .optionalForegroundStyle(uploadColor)
            }
            Text("↓\(download)")
                .optionalForegroundStyle(downloadColor)
        }
        .monospacedDigit()
    }
}
