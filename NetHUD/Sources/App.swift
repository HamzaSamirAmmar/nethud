import SwiftUI

@main
struct NetHUDApp: App {
    @StateObject private var monitor = TrafficMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
                .frame(minWidth: 320)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
