import AppKit
import SwiftUI

// MARK: - Colors

extension Color {
    /// A color that resolves per appearance (light / dark popover).
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Palette from the app icon: a dark gauge with a neon cyan-blue down arrow
/// and a neon green up arrow.
enum Brand {
    /// Download — the icon's cyan-blue.
    static let download = Color(hex: 0x2EA8FF)
    /// Upload — the icon's green.
    static let upload = Color(hex: 0x34D46A)

    /// Readable variants for text on the regular popover background.
    static let downloadText = Color(light: NSColor(srgbRed: 0.02, green: 0.44, blue: 0.85, alpha: 1),
                                    dark: NSColor(srgbRed: 0.35, green: 0.72, blue: 1.0, alpha: 1))
    static let uploadText = Color(light: NSColor(srgbRed: 0.08, green: 0.55, blue: 0.24, alpha: 1),
                                  dark: NSColor(srgbRed: 0.36, green: 0.86, blue: 0.50, alpha: 1))

    /// The instrument panel (hero card) — the icon's dark gauge face.
    static let panelTop = Color(hex: 0x141B24)
    static let panelBottom = Color(hex: 0x0B1016)
}

// MARK: - Screen chrome

/// Title bar for secondary screens: back chevron, centered title.
struct ScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(IconButtonStyle())
                .keyboardShortcut(.cancelAction)
                .help("Back")
                .accessibilityLabel("Back")

                Spacer()
            }
        }
    }
}

/// Small caps section title.
struct SectionTitle: View {
    let title: String
    var systemImage: String?

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }
}

/// Grouped form section in the style of System Settings.
struct FormSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: title, systemImage: systemImage)
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .groupedBackground()
        }
    }
}

/// One form row: label (with optional caption) leading, control trailing.
struct FormRow<Control: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            control
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

/// Divider between form rows, inset like native grouped lists.
struct FormDivider: View {
    var body: some View {
        Divider().padding(.leading, 10)
    }
}

extension View {
    /// Rounded, lightly filled container used by every grouped surface.
    func groupedBackground(cornerRadius: CGFloat = 10) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Buttons & interaction

/// Borderless icon button with a soft circular hover state.
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconButtonBody(configuration: configuration)
    }

    private struct IconButtonBody: View {
        let configuration: Configuration
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(Color.primary.opacity(
                        configuration.isPressed ? 0.14 : (isHovered && isEnabled ? 0.08 : 0)
                    ))
                )
                .contentShape(Circle())
                .onHover { isHovered = $0 }
        }
    }
}

/// Small capsule text button, e.g. "Reset".
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PillBody(configuration: configuration)
    }

    private struct PillBody: View {
        let configuration: Configuration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(Color.primary.opacity(
                        configuration.isPressed ? 0.14 : (isHovered ? 0.10 : 0.06)
                    ))
                )
                .contentShape(Capsule())
                .onHover { isHovered = $0 }
        }
    }
}
