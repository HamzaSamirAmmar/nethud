import AppKit
import Combine
import SwiftUI

/// Owns the menu bar item via AppKit's `NSStatusItem`.
///
/// SwiftUI's `MenuBarExtra` label ignores custom colors and mis-renders
/// conditional stacks, so the live label is an attributed string on the
/// status item's button — the approach colored menu bar apps rely on.
/// The dropdown remains SwiftUI, shown in a popover on click.
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let monitor: TrafficMonitor
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellable: AnyCancellable?
    private var globalEventMonitor: Any?
    private var resignKeyObserver: NSObjectProtocol?
    private var resignActiveObserver: NSObjectProtocol?
    private var lastCloseTime: TimeInterval = 0

    init(monitor: TrafficMonitor) {
        self.monitor = monitor
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.delegate = self
        resetContent()

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

    deinit {
        tearDownEventMonitors()
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

    // MARK: - Content Management

    private func resetContent() {
        let hosting = NSHostingController(rootView: MenuBarView(monitor: monitor))
        // Track SwiftUI's size so the popover grows/shrinks between the
        // dashboard and Settings instead of clipping.
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
    }

    // MARK: - Popover

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastCloseTime < 0.2 {
                return
            }
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        if let view = popover.contentViewController?.view {
            view.layoutSubtreeIfNeeded()
            popover.contentSize = view.fittingSize
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        setupEventMonitors()
    }

    @objc private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
        if popover.isShown {
            popover.close()
        }
    }

    // MARK: - Event Monitors (Unfocus dismissal)

    private func setupEventMonitors() {
        tearDownEventMonitors()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover()
            }
        }

        if let window = popover.contentViewController?.view.window {
            resignKeyObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.closePopover()
            }
        }

        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func tearDownEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let observer = resignKeyObserver {
            NotificationCenter.default.removeObserver(observer)
            resignKeyObserver = nil
        }
        if let observer = resignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            resignActiveObserver = nil
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        lastCloseTime = ProcessInfo.processInfo.systemUptime
        tearDownEventMonitors()
        resetContent()
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        true
    }
}
