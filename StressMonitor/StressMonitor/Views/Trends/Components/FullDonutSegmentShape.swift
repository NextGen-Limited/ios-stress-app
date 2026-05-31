import SwiftUI

/// Draws a ring arc segment for a full 360° donut chart.
/// Degrees are in 0–360 range where 0° = top, 90° = right, 180° = bottom, 270° = left.
struct FullDonutSegmentShape: Shape {
    let startDeg: Double
    let endDeg: Double
    let ringWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius - ringWidth

        // Convert to standard coords where top = -90°
        let startAngle = Angle.degrees(startDeg - 90)
        let endAngle = Angle.degrees(endDeg - 90)

        path.addArc(center: center, radius: outerRadius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
