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

/// Builds the status item title. Shared by the real menu bar item and the
/// theme previews in Settings, so the preview is pixel-for-pixel the real thing.
enum MenuBarTitle {
    /// The raw text segments: upload (nil when the theme hides it) and download.
    static func segments(theme: MenuBarTheme, up: Double, down: Double) -> (upload: String?, download: String) {
        let compact = theme.isCompact
        let upload = "↑" + (compact ? Format.speedCompactFixed(up) : Format.speedFixed(up))
        let download = "↓" + (compact ? Format.speedCompactFixed(down) : Format.speedFixed(down))
        return (theme.showsUpload ? upload : nil, download)
    }

    static func make(theme: MenuBarTheme, up: Double, down: Double, fontSize: CGFloat = NSFont.systemFontSize) -> NSAttributedString {
        let (upload, download) = segments(theme: theme, up: up, down: down)

        // Fully monospaced font + fixed-width fields → the item's width
        // never changes, so menu bar neighbors never shift around.
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let title = NSMutableAttributedString()

        if let upload {
            title.append(NSAttributedString(string: upload, attributes: [.font: font]))
            if theme.isColored {
                title.addAttribute(.foregroundColor, value: ThemePalette.upload,
                                   range: NSRange(location: 0, length: upload.count))
            }
            title.append(NSAttributedString(string: " ", attributes: [.font: font]))
        }

        let downloadStart = title.length
        title.append(NSAttributedString(string: download, attributes: [.font: font]))
        if theme.isColored {
            title.addAttribute(.foregroundColor, value: ThemePalette.download,
                               range: NSRange(location: downloadStart, length: download.count))
        }
        return title
    }
}
