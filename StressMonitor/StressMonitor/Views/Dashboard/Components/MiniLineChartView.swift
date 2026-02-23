import SwiftUI

/// Simple mini line chart for metric cards
struct MiniLineChartView: View {
    let dataPoints: [Double]
    let color: Color
    var showGradient: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showGradient {
                    // Gradient fill under the line
                    pathForFill(in: geometry.size)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Line
                pathForLine(in: geometry.size)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 40)
    }

    // MARK: - Path Generation

    private func pathForLine(in size: CGSize) -> Path {
        var path = Path()
        guard !dataPoints.isEmpty else { return path }

        // Guard against single data point (division by zero)
        guard dataPoints.count > 1 else {
            // Draw a single dot for single data point
            let x = size.width / 2
            let y = size.height / 2
            path.addEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
            return path
        }

        let stepX = size.width / CGFloat(dataPoints.count - 1)
        let minValue = dataPoints.min() ?? 0
        let maxValue = dataPoints.max() ?? 1
        let range = max(maxValue - minValue, 1)

        for (index, value) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let normalizedY = (value - minValue) / range
            let y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1)

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

    private func pathForFill(in size: CGSize) -> Path {
        var path = pathForLine(in: size)

        // Close the path to create a fill area
        guard dataPoints.count > 1 else { return path }

        let stepX = size.width / CGFloat(dataPoints.count - 1)
        let lastX = CGFloat(dataPoints.count - 1) * stepX

        path.addLine(to: CGPoint(x: lastX, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        return path
    }
}

#Preview("Mini Line Chart") {
    VStack(spacing: 20) {
        MiniLineChartView(
            dataPoints: [45, 52, 48, 55, 50, 58, 62],
            color: .hrvAccent
        )
        .frame(width: 100, height: 40)

        MiniLineChartView(
            dataPoints: [72, 68, 70, 65, 68, 72, 70],
            color: .heartRateAccent
        )
        .frame(width: 100, height: 40)

        MiniLineChartView(
            dataPoints: [20, 35, 28, 42, 38, 45, 52],
            color: .stressMild
        )
        .frame(width: 100, height: 40)
    }
    .padding()
    .background(Color.oledCardBackground)
}
