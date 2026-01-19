import SwiftUI

struct LineChartView: View {
    let dataPoints: [ChartDataPoint]
    let accentColor: Color
    let showGrid: Bool

    @State private var selectedPoint: ChartDataPoint?
    @State private var touchLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showGrid {
                    drawGrid(in: geometry.size)
                }

                drawAreaFill(in: geometry.size)
                drawLine(in: geometry.size)

                if selectedPoint != nil {
                    drawSelectionIndicator(in: geometry.size)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchLocation = value.location
                        selectedPoint = findNearestPoint(to: value.location, in: geometry.size)
                    }
                    .onEnded { _ in }
            )
        }
    }

    private func drawGrid(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<5) { index in
                let y = CGFloat(index) / 4 * size.height
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            }
        }
    }

    private func normalize(point: ChartDataPoint, in size: CGSize) -> CGPoint {
        guard let minValue = dataPoints.map({ $0.value }).min(),
              let maxValue = dataPoints.map({ $0.value }).max(),
              !dataPoints.isEmpty else { return .zero }

        let x = CGFloat(dataPoints.firstIndex(of: point) ?? 0) / CGFloat(dataPoints.count - 1) * size.width

        let valueRange = maxValue - minValue
        let normalizedValue = (point.value - minValue) / (valueRange == 0 ? 1 : valueRange)
        let y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1)

        return CGPoint(x: x, y: y)
    }

    private func drawLine(in size: CGSize) -> some View {
        Path { path in
            guard let first = dataPoints.first else { return }
            let start = normalize(point: first, in: size)
            path.move(to: start)

            for point in dataPoints.dropFirst() {
                let normalized = normalize(point: point, in: size)
                path.addLine(to: normalized)
            }
        }
        .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func drawAreaFill(in size: CGSize) -> some View {
        Path { path in
            guard let first = dataPoints.first else { return }
            let start = normalize(point: first, in: size)
            path.move(to: start)

            for point in dataPoints.dropFirst() {
                let normalized = normalize(point: point, in: size)
                path.addLine(to: normalized)
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [accentColor.opacity(0.3), accentColor.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func drawSelectionIndicator(in size: CGSize) -> some View {
        Group {
            if let point = selectedPoint, let location = normalizeOptional(point: point, in: size) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 12, height: 12)
                    .position(location)

                Circle()
                    .stroke(accentColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
        }
    }

    private func findNearestPoint(to location: CGPoint, in size: CGSize) -> ChartDataPoint? {
        dataPoints.min { point1, point2 in
            let loc1 = normalize(point: point1, in: size)
            let loc2 = normalize(point: point2, in: size)
            let dist1 = hypot(loc1.x - location.x, loc1.y - location.y)
            let dist2 = hypot(loc2.x - location.x, loc2.y - location.y)
            return dist1 < dist2
        }
    }

    private func normalizeOptional(point: ChartDataPoint?, in size: CGSize) -> CGPoint? {
        guard let point = point else { return nil }
        return normalize(point: point, in: size)
    }
}
