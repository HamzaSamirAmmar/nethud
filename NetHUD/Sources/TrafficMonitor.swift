import Foundation

struct InterfaceSpeed: Identifiable, Equatable {
    let name: String
    let displayName: String
    let isPrimary: Bool
    let down: Double // bytes per second
    let up: Double // bytes per second

    var id: String { name }
}

/// Polls per-interface byte counters via `getifaddrs` and publishes live speeds.
///
/// The menu bar shows the traffic of the *primary* interface (the one owning the
/// default route). This avoids double counting when a VPN is active, since the
/// same payload then crosses both `utun*` and the physical `en*` interface.
final class TrafficMonitor: ObservableObject {

    // MARK: - Published state

    @Published private(set) var downSpeed: Double = 0
    @Published private(set) var upSpeed: Double = 0
    @Published private(set) var interfaces: [InterfaceSpeed] = []
    @Published private(set) var sessionDownloaded: UInt64 = 0
    @Published private(set) var sessionUploaded: UInt64 = 0

    @Published var refreshInterval: TimeInterval = 1.0 {
        didSet {
            guard oldValue != refreshInterval else { return }
            restartTimer()
        }
    }

    @Published var theme: MenuBarTheme = .classic {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: MenuBarTheme.storageKey) }
    }

    // MARK: - Private state

    private var timer: Timer?
    private var lastCounters: [String: (in: UInt64, out: UInt64)]?
    private var lastSampleDate: Date?
    private var primaryInterface: String?
    private var primaryInterfaceRefreshedAt = Date.distantPast

    /// Loopback / peer-to-peer interfaces we never want to count.
    private static let excludedInterfaces: Set<String> = [
        "lo0", "awdl0", "awdl1", "llw0", "llw1", "anpi0", "anpi1",
    ]

    /// Darwin interface counters are 32-bit; they wrap at 4 GB.
    private let counterWrap = UInt64(UInt32.max) + 1

    // MARK: - Lifecycle

    init() {
        if let stored = UserDefaults.standard.string(forKey: MenuBarTheme.storageKey),
           let restored = MenuBarTheme(rawValue: stored) {
            theme = restored
        }
        sample() // establish the baseline so the first tick already has a delta
        restartTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.sample()
        }
    }

    // MARK: - Sampling

    private func sample() {
        let now = Date()
        refreshPrimaryInterface()
        let counters = readCounters()

        guard let previous = lastCounters, let lastDate = lastSampleDate else {
            lastCounters = counters
            lastSampleDate = now
            return
        }

        let elapsed = max(now.timeIntervalSince(lastDate), 0.05)

        var rows: [InterfaceSpeed] = []
        var primaryDown = 0.0
        var primaryUp = 0.0

        for (name, current) in counters {
            guard let previousCounters = previous[name] else { continue }

            let inDelta = delta(current: current.in, previous: previousCounters.in)
            let outDelta = delta(current: current.out, previous: previousCounters.out)

            let down = Double(inDelta) / elapsed
            let up = Double(outDelta) / elapsed
            let isPrimary = (name == primaryInterface)

            if isPrimary {
                primaryDown = down
                primaryUp = up
            }

            rows.append(InterfaceSpeed(
                name: name,
                displayName: Self.displayName(for: name),
                isPrimary: isPrimary,
                down: down,
                up: up
            ))
        }

        // No default route (offline), or the primary interface vanished this
        // sample: fall back to the busiest interface so the menu bar still
        // shows something meaningful.
        if !rows.contains(where: \.isPrimary), let busiest = rows.max(by: { ($0.down + $0.up) < ($1.down + $1.up) }) {
            primaryDown = busiest.down
            primaryUp = busiest.up
            if let index = rows.firstIndex(where: { $0.name == busiest.name }) {
                rows[index] = InterfaceSpeed(
                    name: busiest.name,
                    displayName: busiest.displayName,
                    isPrimary: true,
                    down: busiest.down,
                    up: busiest.up
                )
            }
        }

        downSpeed = primaryDown
        upSpeed = primaryUp
        sessionDownloaded &+= UInt64(primaryDown * elapsed)
        sessionUploaded &+= UInt64(primaryUp * elapsed)
        interfaces = rows.sorted { ($0.down + $0.up) > ($1.down + $1.up) }

        lastCounters = counters
        lastSampleDate = now
    }

    // MARK: - Interface counters

    private func readCounters() -> [String: (in: UInt64, out: UInt64)] {
        var result: [String: (in: UInt64, out: UInt64)] = [:]

        var ifaddrsPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPointer) == 0, let first = ifaddrsPointer else { return result }
        defer { freeifaddrs(ifaddrsPointer) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }

            guard let sockaddrPointer = current.pointee.ifa_addr else { continue }
            guard sockaddrPointer.pointee.sa_family == sa_family_t(AF_LINK) else { continue }
            guard let dataPointer = current.pointee.ifa_data else { continue }

            let name = String(cString: current.pointee.ifa_name)
            guard !Self.excludedInterfaces.contains(name) else { continue }

            let ifData = dataPointer.assumingMemoryBound(to: if_data.self).pointee
            result[name] = (in: UInt64(ifData.ifi_ibytes), out: UInt64(ifData.ifi_obytes))
        }
        return result
    }

    /// Wrap-aware delta for 32-bit counters, with reset detection.
    private func delta(current: UInt64, previous: UInt64) -> UInt64 {
        if current >= previous { return current - previous }
        let wrapped = (counterWrap - previous) + current
        // A "wrapped" value larger than half the counter space is almost
        // certainly an interface reset (e.g. VPN reconnected), not a wrap.
        return wrapped <= counterWrap / 2 ? wrapped : current
    }

    // MARK: - Primary interface (default route)

    private func refreshPrimaryInterface() {
        guard Date().timeIntervalSince(primaryInterfaceRefreshedAt) > 15 else { return }
        primaryInterfaceRefreshedAt = Date()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/route")
        process.arguments = ["-n", "get", "default"]
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

        do {
            try process.run()
            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0,
                  let output = String(data: data, encoding: .utf8) else {
                primaryInterface = nil
                return
            }

            for line in output.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let range = trimmed.range(of: "interface:") {
                    let candidate = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    primaryInterface = candidate.isEmpty ? nil : candidate
                }
            }
        } catch {
            primaryInterface = nil
        }
    }

    // MARK: - Naming

    private static func displayName(for interface: String) -> String {
        if interface == "en0" { return "Wi-Fi" }
        if interface.hasPrefix("utun") { return "VPN" }
        if interface.hasPrefix("en") { return "Ethernet" }
        if interface.hasPrefix("bridge") { return "Bridge" }
        return interface
    }
}
