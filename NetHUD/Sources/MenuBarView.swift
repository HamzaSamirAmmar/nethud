import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: TrafficMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Divider()

            interfaceSection

            Divider()

            HStack {
                Text("Session")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("↓ \(Format.bytes(monitor.sessionDownloaded))    ↑ \(Format.bytes(monitor.sessionUploaded))")
                    .monospacedDigit()
            }
            .font(.callout)

            Divider()

            Picker("Refresh every", selection: $monitor.refreshInterval) {
                Text("0.5s").tag(TimeInterval(0.5))
                Text("1s").tag(TimeInterval(1))
                Text("2s").tag(TimeInterval(2))
            }
            .pickerStyle(.segmented)

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit NetHUD")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .padding(.top, 2)

            Text("NetHUD \(Self.versionString)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .padding(16)
    }

    private static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 24) {
            speedColumn(
                title: "Download",
                icon: "arrow.down.circle.fill",
                tint: .blue,
                value: monitor.downSpeed
            )
            speedColumn(
                title: "Upload",
                icon: "arrow.up.circle.fill",
                tint: .green,
                value: monitor.upSpeed
            )
            Spacer()
        }
    }

    private func speedColumn(title: String, icon: String, tint: Color, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Format.speed(value))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    private var interfaceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interfaces")
                .font(.caption)
                .foregroundStyle(.secondary)

            let visible = monitor.interfaces.filter { $0.isPrimary || ($0.down + $0.up) > 1 }

            if visible.isEmpty {
                Text("No traffic")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(visible) { row in
                    HStack {
                        HStack(spacing: 4) {
                            Text(row.displayName)
                            if row.isPrimary {
                                Text(row.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("↓ \(Format.speed(row.down))   ↑ \(Format.speed(row.up))")
                            .monospacedDigit()
                    }
                    .font(.callout)
                }
            }
        }
    }
}
