import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: TrafficMonitor
    var onDismiss: () -> Void

    /// Mirrors the login item so the switch redraws after toggling.
    @State private var startsAtLogin = LoginItemManager.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScreenHeader(title: "Settings", onBack: onDismiss)

            themeSection
            refreshSection
            generalSection
            aboutSection
        }
    }

    // MARK: - Menu bar theme

    /// Every theme rendered live with the current speeds — the preview *is*
    /// the choice, so names like "Vivid Compact" never need explaining.
    private var themeSection: some View {
        FormSection(title: "Menu Bar", systemImage: "menubar.rectangle") {
            ForEach(Array(MenuBarTheme.allCases.enumerated()), id: \.element) { index, theme in
                if index > 0 { FormDivider() }
                themeRow(theme)
            }
        }
    }

    private func themeRow(_ theme: MenuBarTheme) -> some View {
        let isSelected = monitor.theme == theme

        return Button {
            withAnimation(.easeOut(duration: 0.12)) {
                monitor.theme = theme
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Brand.downloadText) : AnyShapeStyle(.tertiary))

                Text(theme.displayName)
                    .fontWeight(isSelected ? .medium : .regular)

                Spacer(minLength: 6)

                MenuBarPreview(theme: theme, up: monitor.upSpeed, down: monitor.downSpeed)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Refresh

    private var refreshSection: some View {
        FormSection(title: "Updates", systemImage: "timer") {
            FormRow(title: "Refresh every", subtitle: "Faster is smoother; slower saves energy") {
                Picker("", selection: $monitor.refreshInterval) {
                    ForEach(TrafficMonitor.refreshIntervals, id: \.self) { interval in
                        Text(interval < 1 ? "0.5s" : "\(Int(interval))s").tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        FormSection(title: "General", systemImage: "gearshape") {
            FormRow(title: "Start at Login") {
                Toggle("", isOn: $startsAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                    .onChange(of: startsAtLogin) { enabled in
                        LoginItemManager.setEnabled(enabled)
                        // Reflect the real state if registration failed.
                        startsAtLogin = LoginItemManager.isEnabled
                    }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 38, height: 38)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("NetHUD")
                        .font(.headline)
                    Text("Version \(Self.versionString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit NetHUD")
                }
                .controlSize(.small)
                .help("Quit NetHUD (⌘Q)")
            }

            Label("Reads interface counters locally — no permissions, no network access.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .groupedBackground()
    }

    private static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}

/// A sliver of menu bar rendering one theme with live values — built from the
/// same segments as the real status item.
struct MenuBarPreview: View {
    let theme: MenuBarTheme
    let up: Double
    let down: Double

    var body: some View {
        let segments = MenuBarTitle.segments(theme: theme, up: up, down: down)

        HStack(spacing: 0) {
            if let upload = segments.upload {
                Text(upload + " ")
                    .foregroundColor(theme.isColored ? Color(nsColor: ThemePalette.upload) : nil)
            }
            Text(segments.download)
                .foregroundColor(theme.isColored ? Color(nsColor: ThemePalette.download) : nil)
        }
        .font(.system(size: 11, design: .monospaced))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.bar)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}
