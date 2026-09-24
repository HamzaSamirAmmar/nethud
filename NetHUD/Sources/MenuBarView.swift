import SwiftUI

enum ActiveScreen {
    case dashboard
    case settings
}

struct MenuBarView: View {
    @ObservedObject var monitor: TrafficMonitor
    @State private var activeScreen: ActiveScreen

    init(monitor: TrafficMonitor, initialScreen: ActiveScreen = .dashboard) {
        self.monitor = monitor
        _activeScreen = State(initialValue: initialScreen)
    }

    var body: some View {
        Group {
            switch activeScreen {
            case .dashboard:
                dashboard
                    .transition(.opacity)
            case .settings:
                SettingsView(monitor: monitor) {
                    navigate(to: .dashboard)
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .frame(width: 340)
        .tint(Brand.downloadText)
        .background {
            // ⌘Q quits from anywhere in the popover (there's no Dock icon).
            Button("Quit NetHUD") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    private func navigate(to screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.18)) {
            activeScreen = screen
        }
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            instrumentPanel
            interfaceSection
            sessionSection
        }
    }

    // MARK: Header

    private var primary: InterfaceSpeed? {
        monitor.interfaces.first(where: \.isPrimary)
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                Circle()
                    .fill(monitor.isOnline ? Brand.upload : Color.secondary)
                    .frame(width: 7, height: 7)
                    .shadow(color: monitor.isOnline ? Brand.upload.opacity(0.7) : .clear, radius: 3)

                if monitor.isOnline, let primary {
                    Text(primary.displayName)
                        .font(.headline)
                    Text(primary.name)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else {
                    Text(monitor.isOnline ? "Connected" : "Offline")
                        .font(.headline)
                }
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                navigate(to: .settings)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(IconButtonStyle())
            .keyboardShortcut(",", modifiers: .command)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
    }

    // MARK: Instrument panel (hero)

    /// Dark gauge-face card, echoing the app icon: the two live speeds over
    /// a mirrored 60-second graph.
    private var instrumentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                speedReadout(
                    title: "Download",
                    arrow: "arrow.down",
                    color: Brand.download,
                    value: monitor.downSpeed
                )
                Spacer()
                speedReadout(
                    title: "Upload",
                    arrow: "arrow.up",
                    color: Brand.upload,
                    value: monitor.upSpeed,
                    trailing: true
                )
            }

            TrafficGraph(
                samples: monitor.history,
                capacity: Int((TrafficMonitor.graphWindow / monitor.refreshInterval).rounded())
            )
            .frame(height: 84)

            HStack {
                Text("\(Int(TrafficMonitor.graphWindow))s ago")
                Spacer()
                Text("Peak  ")
                    + Text("↓ \(Format.speed(monitor.peakDown))").foregroundColor(Brand.download)
                    + Text("   ")
                    + Text("↑ \(Format.speed(monitor.peakUp))").foregroundColor(Brand.upload)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(14)
        .background(
            ZStack {
                LinearGradient(colors: [Brand.panelTop, Brand.panelBottom], startPoint: .top, endPoint: .bottom)
                RadialGradient(
                    colors: [Brand.download.opacity(0.14), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 220
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.09), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        .environment(\.colorScheme, .dark)
    }

    private func speedReadout(title: String, arrow: String, color: Color, value: Double, trailing: Bool = false) -> some View {
        let parts = Format.speedParts(value)
        return VStack(alignment: trailing ? .trailing : .leading, spacing: 1) {
            Label(title.uppercased(), systemImage: arrow)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .tracking(0.6)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(parts.value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(parts.unit)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(Format.speed(value))")
    }

    // MARK: Interfaces

    private var interfaceSection: some View {
        let visible = monitor.interfaces.filter { $0.isPrimary || ($0.down + $0.up) > 1 }

        return VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "Interfaces")

            VStack(spacing: 0) {
                if visible.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "network.slash")
                        Text("No active interfaces")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { FormDivider() }
                        interfaceRow(row)
                    }
                }
            }
            .groupedBackground()
        }
    }

    private func interfaceRow(_ row: InterfaceSpeed) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.symbolName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(row.isPrimary ? AnyShapeStyle(Brand.downloadText) : AnyShapeStyle(.secondary))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 0) {
                Text(row.displayName)
                    .fontWeight(row.isPrimary ? .medium : .regular)
                Text(row.name)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 6)

            rateColumn(arrow: "↓", value: row.down, color: Brand.downloadText)
            rateColumn(arrow: "↑", value: row.up, color: Brand.uploadText)
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .help(row.isPrimary ? "Default route — this interface drives the menu bar" : "")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.displayName)\(row.isPrimary ? ", primary" : ""), download \(Format.speed(row.down)), upload \(Format.speed(row.up))")
    }

    private func rateColumn(arrow: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(arrow)
                .foregroundStyle(color)
            Text(Format.speed(value))
                .monospacedDigit()
        }
        .font(.caption)
        .frame(width: 84, alignment: .trailing)
    }

    // MARK: Session

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionTitle(title: "This Session · \(Format.duration(Date().timeIntervalSince(monitor.sessionStart)))")
                Spacer()
                Button("Reset") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        monitor.resetSession()
                    }
                }
                .buttonStyle(PillButtonStyle())
                .help("Zero the session totals and peaks")
            }

            HStack(spacing: 0) {
                totalTile(title: "Downloaded", arrow: "arrow.down", color: Brand.downloadText, bytes: monitor.sessionDownloaded)
                Divider().padding(.vertical, 8)
                totalTile(title: "Uploaded", arrow: "arrow.up", color: Brand.uploadText, bytes: monitor.sessionUploaded)
            }
            .groupedBackground()
        }
    }

    private func totalTile(title: String, arrow: String, color: Color, bytes: UInt64) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: arrow)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Format.bytes(bytes))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }
}
