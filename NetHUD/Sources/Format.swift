import Foundation

enum Format {

    /// Human-readable rate, e.g. "12.3 KB/s" or "1.2 MB/s".
    static func speed(_ bytesPerSecond: Double) -> String {
        switch bytesPerSecond {
        case ..<1024:
            return String(format: "%.0f B/s", bytesPerSecond)
        case ..<1_048_576:
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        case ..<1_073_741_824:
            return String(format: "%.2f MB/s", bytesPerSecond / 1_048_576)
        default:
            return String(format: "%.2f GB/s", bytesPerSecond / 1_073_741_824)
        }
    }

    /// `speed(_:)` split into number and unit, for large readouts where the
    /// unit is set smaller than the value.
    static func speedParts(_ bytesPerSecond: Double) -> (value: String, unit: String) {
        let full = speed(bytesPerSecond)
        guard let space = full.lastIndex(of: " ") else { return (full, "") }
        return (String(full[..<space]), String(full[full.index(after: space)...]))
    }

    /// Session length, e.g. "2h 05m", "12m", "<1m".
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(minutes)m" }
        return String(format: "%dh %02dm", minutes / 60, minutes % 60)
    }

    /// Human-readable total, e.g. "1.2 GB" or "834 MB" (decimal units).
    static func bytes(_ total: UInt64) -> String {
        let kb: UInt64 = 1_000
        let mb: UInt64 = 1_000_000
        let gb: UInt64 = 1_000_000_000

        switch total {
        case ..<kb:
            return "\(total) B"
        case ..<mb:
            return String(format: "%.0f KB", Double(total) / Double(kb))
        case ..<gb:
            return String(format: "%.1f MB", Double(total) / Double(mb))
        default:
            return String(format: "%.2f GB", Double(total) / Double(gb))
        }
    }

    /// Compact rate for the menu bar, e.g. "12.3K" or "1.2M".
    static func speedCompact(_ bytesPerSecond: Double) -> String {
        switch bytesPerSecond {
        case ..<1024:
            return String(format: "%.0fB", bytesPerSecond)
        case ..<1_048_576:
            return String(format: "%.1fK", bytesPerSecond / 1024)
        case ..<1_073_741_824:
            return String(format: "%.1fM", bytesPerSecond / 1_048_576)
        default:
            return String(format: "%.2fG", bytesPerSecond / 1_073_741_824)
        }
    }

    /// Fixed-width rate: **always exactly 9 characters** (" 999 B/s",
    /// " 12.3 KB/s", "1.24 MB/s"). Pair with a monospaced font so the
    /// menu bar item never changes width and never shoves neighbors around.
    static func speedFixed(_ bytesPerSecond: Double) -> String {
        let parts = Self.compactValueAndUnit(bytesPerSecond)
        return padLeft(parts.value, to: 4) + " " + padRight(parts.unit, to: 4)
    }

    /// Fixed-width compact rate: **always exactly 5 characters**
    /// ("9999B", "12.3K", "1.24M").
    static func speedCompactFixed(_ bytesPerSecond: Double) -> String {
        let parts = Self.compactValueAndUnit(bytesPerSecond)
        return padLeft(parts.value, to: 4) + String(parts.unit.prefix(1))
    }

    /// Value scaled to at most 4 characters plus its unit family
    /// (B/s, KB/s, MB/s, GB/s).
    private static func compactValueAndUnit(_ bytesPerSecond: Double) -> (value: String, unit: String) {
        switch bytesPerSecond {
        case ..<1024:
            return (String(format: "%.0f", bytesPerSecond), "B/s")
        case ..<1_048_576:
            let kb = bytesPerSecond / 1024
            return (kb < 10 ? String(format: "%.2f", kb) : kb < 100 ? String(format: "%.1f", kb) : String(format: "%.0f", kb), "KB/s")
        case ..<1_073_741_824:
            let mb = bytesPerSecond / 1_048_576
            return (mb < 10 ? String(format: "%.2f", mb) : mb < 100 ? String(format: "%.1f", mb) : String(format: "%.0f", mb), "MB/s")
        default:
            let gb = bytesPerSecond / 1_073_741_824
            return (gb < 10 ? String(format: "%.2f", gb) : gb < 100 ? String(format: "%.1f", gb) : String(format: "%.0f", gb), "GB/s")
        }
    }

    private static func padLeft(_ string: String, to width: Int) -> String {
        string.count >= width ? string : String(repeating: " ", count: width - string.count) + string
    }

    private static func padRight(_ string: String, to width: Int) -> String {
        string.count >= width ? string : string + String(repeating: " ", count: width - string.count)
    }
}
