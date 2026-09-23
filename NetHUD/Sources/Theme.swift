import AppKit

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
    static let upload = NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1)
    static let download = NSColor(calibratedRed: 0.04, green: 0.52, blue: 1.0, alpha: 1)
}
