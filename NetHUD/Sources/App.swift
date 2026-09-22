import SwiftUI

@main
struct NetHUDApp: App {
    @StateObject private var monitor = TrafficMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
                .frame(minWidth: 320)
        } label: {
            Text("↑\(Format.speed(monitor.upSpeed)) ↓\(Format.speed(monitor.downSpeed))")
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
