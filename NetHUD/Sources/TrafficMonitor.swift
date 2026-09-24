import AppKit
import Foundation

struct InterfaceSpeed: Identifiable, Equatable {
    let name: String
    let displayName: String
    let isPrimary: Bool
    let down: Double // bytes per second
    let up: Double // bytes per second

    var id: String { name }

    /// SF Symbol for the interface kind.
    var symbolName: String {
        if name == "en0" { return "wifi" }
        if name.hasPrefix("utun") { return "lock.shield" }
        if name.hasPrefix("en") { return "cable.connector" }
        if name.hasPrefix("bridge") { return "point.3.connected.trianglepath.dotted" }
        return "network"
    }
}

/// One point of the live graph.
struct TrafficSample: Equatable {
    let down: Double // bytes per second
    let up: Double // bytes per second
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
    @Published private(set) var sessionStart = Date()
    @Published private(set) var peakDown: Double = 0
    @Published private(set) var peakUp: Double = 0

    /// Primary-interface speeds over the last `graphWindow` seconds, oldest first.
    @Published private(set) var history: [TrafficSample] = []

    /// False when the Mac has no default route (no network at all).
    @Published private(set) var isOnline = true

    /// Seconds of history the graph shows, independent of refresh rate.
    static let graphWindow: TimeInterval = 60

    static let refreshIntervalKey = "refreshInterval"
    static let refreshIntervals: [TimeInterval] = [0.5, 1, 2]

    @Published var refreshInterval: TimeInterval = 1.0 {
        didSet {
            guard oldValue != refreshInterval else { return }
            UserDefaults.standard.set(refreshInterval, forKey: Self.refreshIntervalKey)
            trimHistory()
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
    private var wakeObserver: NSObjectProtocol?

    /// `/sbin/route` runs off the main thread so its ~5–20 ms never hitches the UI.
    private let routeQueue = DispatchQueue(label: "personal.hamza.nethud.route", qos: .utility)

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
        let storedInterval = UserDefaults.standard.double(forKey: Self.refreshIntervalKey)
        if Self.refreshIntervals.contains(storedInterval) {
            refreshInterval = storedInterval
        }

        // Re-baseline after the Mac wakes so the first post-sleep sample
        // doesn't spread traffic across the whole sleep window.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebaseline()
        }

        sample() // establish the baseline so the first tick already has a delta
        restartTimer()
    }

    deinit {
        timer?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    /// Drops the previous sample so the next tick starts from a clean baseline.
    private func rebaseline() {
        lastCounters = nil
        lastSampleDate = nil
        sample()
    }

    /// Zeroes the session totals and peaks, starting a new session now.
    func resetSession() {
        sessionDownloaded = 0
        sessionUploaded = 0
        peakDown = 0
        peakUp = 0
        sessionStart = Date()
    }

    private var historyCapacity: Int {
        max(Int((Self.graphWindow / refreshInterval).rounded()), 2)
    }

    private func trimHistory() {
        if history.count > historyCapacity {
            history.removeFirst(history.count - historyCapacity)
        }
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
        peakDown = max(peakDown, primaryDown)
        peakUp = max(peakUp, primaryUp)
        history.append(TrafficSample(down: primaryDown, up: primaryUp))
        trimHistory()
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

        routeQueue.async { [weak self] in
            var found: String?

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

                if process.terminationStatus == 0,
                   let output = String(data: data, encoding: .utf8) {
                    for line in output.split(separator: "\n") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if let range = trimmed.range(of: "interface:") {
                            let candidate = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                            found = candidate.isEmpty ? nil : candidate
                        }
                    }
                }
            } catch {
                found = nil
            }

            DispatchQueue.main.async {
                self?.primaryInterface = found
                if self?.isOnline != (found != nil) {
                    self?.isOnline = found != nil
                }
            }
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
