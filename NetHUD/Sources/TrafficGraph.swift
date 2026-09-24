import SwiftUI

/// Mirrored live graph: download fills upward from the center line, upload
/// downward. Each half scales to its own peak, so a trickle of upload stays
/// visible next to a saturated download.
struct TrafficGraph: View {
    let samples: [TrafficSample]
    /// Number of slots across the width; the newest sample sits at the
    /// trailing edge and history scrolls in from the leading edge.
    let capacity: Int

    /// Scale floor so idle background chatter doesn't fill the graph.
    private static let minimumScale: Double = 32 * 1024

    var body: some View {
        let downScale = max(samples.map(\.down).max() ?? 0, Self.minimumScale) * 1.08
        let upScale = max(samples.map(\.up).max() ?? 0, Self.minimumScale) * 1.08
        let down = samples.map { $0.down / downScale }
        let up = samples.map { $0.up / upScale }

        ZStack {
            // Download (upper half)
            GraphShape(values: down, capacity: capacity, upward: true, closed: true)
                .fill(LinearGradient(
                    colors: [Brand.download.opacity(0.55), Brand.download.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .center
                ))
            GraphShape(values: down, capacity: capacity, upward: true, closed: false)
                .stroke(Brand.download, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .shadow(color: Brand.download.opacity(0.6), radius: 3)

            // Upload (lower half)
            GraphShape(values: up, capacity: capacity, upward: false, closed: true)
                .fill(LinearGradient(
                    colors: [Brand.upload.opacity(0.04), Brand.upload.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                ))
            GraphShape(values: up, capacity: capacity, upward: false, closed: false)
                .stroke(Brand.upload, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .shadow(color: Brand.upload.opacity(0.6), radius: 3)

            // Center axis
            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(height: 1)
        }
        .environment(\.layoutDirection, .leftToRight) // time always flows left → right
        .accessibilityHidden(true)
    }
}

/// One half of the mirrored graph as a smoothed polyline (or closed area).
private struct GraphShape: Shape {
    /// Normalized 0...1 values, oldest first.
    let values: [Double]
    let capacity: Int
    let upward: Bool
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }

        let mid = rect.midY
        let amplitude = rect.height / 2 - 2
        let step = rect.width / CGFloat(max(capacity - 1, 1))
        let firstX = rect.maxX - CGFloat(values.count - 1) * step

        let points: [CGPoint] = values.enumerated().map { index, value in
            let clamped = CGFloat(min(max(value, 0), 1))
            let offset = clamped * amplitude
            return CGPoint(x: firstX + CGFloat(index) * step, y: upward ? mid - offset : mid + offset)
        }

        if closed {
            path.move(to: CGPoint(x: points[0].x, y: mid))
            path.addLine(to: points[0])
        } else {
            path.move(to: points[0])
        }

        // Midpoint quadratic smoothing: soft curves that never overshoot.
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: midpoint, control: previous)
        }
        path.addLine(to: points[points.count - 1])

        if closed {
            path.addLine(to: CGPoint(x: points[points.count - 1].x, y: mid))
            path.closeSubpath()
        }
        return path
    }
}
