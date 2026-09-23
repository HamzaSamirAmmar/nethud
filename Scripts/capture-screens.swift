// capture-screens.swift — regenerates the README screenshots (Docs/*.png)
// by rendering the real app views offscreen with live traffic.
//
// Run from the repo root:
//   swiftc -O NetHUD/Sources/Format.swift NetHUD/Sources/Theme.swift \
//     NetHUD/Sources/TrafficMonitor.swift NetHUD/Sources/LoginItemManager.swift \
//     NetHUD/Sources/MenuBarView.swift Scripts/capture-screens.swift \
//     -o /tmp/nethud-shot && /tmp/nethud-shot

import AppKit
import SwiftUI

// Compiled together with the app's real sources (Format, Theme,
// TrafficMonitor, MenuBarView) to capture genuine UI rendering offscreen.

let app = NSApplication.shared

// MARK: - Real traffic load so the numbers look alive

let loadURLs = [
    "https://speed.cloudflare.com/__down?bytes=60000000",
    "https://proof.ovh.net/files/10MbDat.dat",
]

let loadThread = Thread {
    for url in loadURLs {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = ["-o", "/dev/null", "-s", "--max-time", "20", url]
        try? process.run()
    }
    Thread.sleep(forTimeInterval: 22)
}
loadThread.start()

let monitor = TrafficMonitor()
print("sampling with live load…")
// Service the main run loop so the monitor's timers actually fire.
var deadline = Date().addingTimeInterval(12)
while Date() < deadline {
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))
}

// MARK: - Rendering helpers

func bitmap(width: CGFloat, height: CGFloat) -> (NSBitmapImageRep, NSGraphicsContext) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * 2), pixelsHigh: Int(height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    return (rep, context)
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    let png = rep.representation(using: .png, properties: [:])!
    let url = URL(fileURLWithPath: "Docs").appendingPathComponent(name)
    try! FileManager.default.createDirectory(at: URL(fileURLWithPath: "Docs"), withIntermediateDirectories: true)
    try! png.write(to: url)
    print("wrote Docs/\(name)")
}

// MARK: - Menu bar label strips (real attributed-title rendering)

func renderLabel(into context: NSGraphicsContext) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let theme = monitor.theme
    let compact = theme.isCompact
    let upload = "↑" + (compact ? Format.speedCompactFixed(monitor.upSpeed) : Format.speedFixed(monitor.upSpeed))
    let download = "↓" + (compact ? Format.speedCompactFixed(monitor.downSpeed) : Format.speedFixed(monitor.downSpeed))
    let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    let title = NSMutableAttributedString()
    title.append(NSAttributedString(string: upload, attributes: [.font: font, .foregroundColor: ThemePalette.upload]))
    title.append(NSAttributedString(string: " ", attributes: [.font: font]))
    title.append(NSAttributedString(string: download, attributes: [.font: font, .foregroundColor: ThemePalette.download]))
    // menu bar height ~24pt with 4pt vertical centering
    title.draw(at: NSPoint(x: 12, y: 4))
    NSGraphicsContext.restoreGraphicsState()
}

func menuBarStrip(background: NSColor, name: String) {
    let (rep, context) = bitmap(width: 640, height: 24)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    background.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 640, height: 24)).fill()
    NSGraphicsContext.restoreGraphicsState()
    renderLabel(into: context)
    save(rep, name)
}

menuBarStrip(background: NSColor(calibratedWhite: 0.92, alpha: 1), name: "menubar-light.png")
menuBarStrip(background: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1), name: "menubar-dark.png")

// MARK: - Dropdown (real MenuBarView)

let hosting = NSHostingView(rootView: MenuBarView(monitor: monitor))
let fitting = hosting.fittingSize
let dropdownWidth: CGFloat = 340
let dropdownHeight = max(fitting.height, 380)
hosting.setFrameSize(NSSize(width: dropdownWidth, height: dropdownHeight))
hosting.layoutSubtreeIfNeeded()

let (drep, dcontext) = bitmap(width: dropdownWidth + 24, height: dropdownHeight + 24)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = dcontext

// Popover chrome: light card with rounded corners + soft shadow
let shadow = NSShadow()
shadow.shadowBlurRadius = 18
shadow.shadowOffset = NSSize(width: 0, height: -6)
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
let card = NSBezierPath(roundedRect: NSRect(x: 12, y: 12, width: dropdownWidth, height: dropdownHeight), xRadius: 12, yRadius: 12)
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
shadow.set()
card.fill()
NSGraphicsContext.restoreGraphicsState()

// Render the SwiftUI content on top
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = dcontext
let transform = NSAffineTransform()
transform.scale(by: 2)
transform.concat()
NSGraphicsContext.current?.cgContext.translateBy(x: 12, y: 12)
hosting.cacheDisplay(in: NSRect(x: 0, y: 0, width: dropdownWidth, height: dropdownHeight), to: drep)
NSGraphicsContext.restoreGraphicsState()
save(drep, "dropdown.png")

print("up=\(Format.speed(monitor.upSpeed)) down=\(Format.speed(monitor.downSpeed))")
exit(0)
