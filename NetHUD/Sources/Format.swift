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
}
