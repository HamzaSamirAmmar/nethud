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
        let hosting = NSHostingController(rootView: MenuBarView(monitor: monitor))
        // Track SwiftUI's size so the popover grows/shrinks between the
        // dashboard and Settings instead of clipping.
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting

        if let button = statusItem.button {
            button.setAccessibilityLabel("NetHUD network speeds")
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

        button.attributedTitle = MenuBarTitle.make(
            theme: monitor.theme,
            up: monitor.upSpeed,
            down: monitor.downSpeed
        )
        button.toolTip = monitor.isOnline
            ? "NetHUD — ↓ \(Format.speed(monitor.downSpeed))  ↑ \(Format.speed(monitor.upSpeed))"
            : "NetHUD — offline"
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
