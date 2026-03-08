import SwiftUI

// MARK: - Curved Bottom Background

/// Black curved background creating "cutout" effect for dashboard
struct CurvedBottomBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let cutoutRadius = width * 0.4
                let cutoutCenterY = height * 0.35

                // Start from bottom-left
                path.move(to: CGPoint(x: 0, y: height))

                // Bottom edge to bottom-right
                path.addLine(to: CGPoint(x: width, y: height))

                // Right edge up
                path.addLine(to: CGPoint(x: width, y: 0))

                // Top edge to start of curve
                path.addLine(to: CGPoint(x: width * 0.6, y: 0))

                // Curve down to create cutout
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.4, y: 0),
                    control: CGPoint(x: width * 0.5, y: cutoutCenterY)
                )

                // Close path
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.closeSubpath()
            }
            .fill(Color.black)
        }
    }
}

// MARK: - Preview

#Preview {
    CurvedBottomBackground()
        .frame(height: 300)
}
