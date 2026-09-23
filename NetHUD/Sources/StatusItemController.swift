import AppKit
import Combine
import SwiftUI

/// Owns the menu bar item via AppKit's `NSStatusItem`.
///
/// SwiftUI's `MenuBarExtra` label ignores custom colors and mis-renders
/// conditional stacks, so the live label is an attributed string on the
/// status item's button — the approach colored menu bar apps rely on.
/// The dropdown remains SwiftUI, shown in a popover on click.
final class StatusItemController: NSObject {
    private let monitor: TrafficMonitor
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellable: AnyCancellable?

    init(monitor: TrafficMonitor) {
        self.monitor = monitor
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(monitor: monitor))

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        cancellable = monitor.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderTitle() }

        renderTitle()
    }

    // MARK: - Title rendering

    private func renderTitle() {
        guard let button = statusItem.button else { return }

        let theme = monitor.theme
        let compact = theme.isCompact
        let upload = "↑" + (compact ? Format.speedCompact(monitor.upSpeed) : Format.speed(monitor.upSpeed))
        let download = "↓" + (compact ? Format.speedCompact(monitor.downSpeed) : Format.speed(monitor.downSpeed))

        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let title = NSMutableAttributedString()

        if theme.showsUpload {
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

        button.attributedTitle = title
    }

    // MARK: - Popover

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let view = popover.contentViewController?.view {
                view.layoutSubtreeIfNeeded()
                popover.contentSize = view.fittingSize
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
