import SwiftUI

/// HRV trend line chart with a dashed reference line at the personal baseline
/// (default 52 ms) and a glowing endpoint halo in the Ripple accent tint.
///
/// Draws directly with Path so it carries no Charts framework dependency.
/// Y-axis auto-scales to the data range with a small padding band; if all data
/// is missing the chart shows an empty-state message instead of a flat line.
struct HRVTrendChart: View {
    let dataPoints: [ChartDataPoint]
    var referenceValue: Double = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if dataPoints.isEmpty {
                emptyState
            } else {
                chart
                footer
            }
        }
        .padding(18)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("HRV trend chart. Reference line at \(Int(referenceValue)) milliseconds.")
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HRV Trend")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Last 7 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Text("\(Int(referenceValue)) ms")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: - Chart

    private var chart: some View {
        GeometryReader { proxy in
            let layout = ChartLayout(
                points: dataPoints,
                reference: referenceValue,
                size: proxy.size
            )
            ZStack {
                referenceLine(layout: layout)
                trendLine(layout: layout)
                if let endpoint = layout.endpoint {
                    endpointHalo(at: endpoint)
                }
            }
        }
        .frame(height: 160)
    }

    private func referenceLine(layout: ChartLayout) -> some View {
        Path { path in
            let y = layout.y(for: referenceValue)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: layout.size.width, y: y))
        }
        .stroke(
            HomeCharacterDesignTokens.Ripple.primary.opacity(0.55),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    private func trendLine(layout: ChartLayout) -> some View {
        Path { path in
            let pts = layout.pointCoordinates
            guard let first = pts.first else { return }
            path.move(to: first)
            for point in pts.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(HomeCharacterDesignTokens.Ripple.deep, lineWidth: 2.5)
    }

    private func endpointHalo(at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(HomeCharacterDesignTokens.Ripple.primary.opacity(0.25))
                .frame(width: 22, height: 22)
                .blur(radius: 3)
            Circle()
                .fill(HomeCharacterDesignTokens.Ripple.primary)
                .frame(width: 8, height: 8)
        }
        .position(point)
    }

    // MARK: - Footer / Empty

    private var footer: some View {
        let avg = dataPoints.map { $0.value }.reduce(0, +) / Double(max(1, dataPoints.count))
        return HStack(spacing: 16) {
            statTile(title: "Average", value: "\(Int(avg))", unit: "ms")
            statTile(title: "Reference", value: "\(Int(referenceValue))", unit: "ms")
            Spacer(minLength: 0)
        }
    }

    private func statTile(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text(unit)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.4))
            Text("Need more data")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            Text("Measure for 7 days to see your HRV trend")
                .font(.system(size: 12))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}

// MARK: - Chart Layout

private struct ChartLayout {
    let points: [ChartDataPoint]
    let reference: Double
    let size: CGSize

    /// Y-domain padded so the line never touches the top/bottom edge.
    private var yDomain: ClosedRange<Double> {
        guard let minVal = points.map({ $0.value }).min(),
              let maxVal = points.map({ $0.value }).max() else {
            return 0...100
        }
        let lower = min(minVal, reference) - 5
        let upper = max(maxVal, reference) + 5
        return lower...upper
    }

    private var xStep: CGFloat {
        guard points.count > 1 else { return size.width }
        return size.width / CGFloat(points.count - 1)
    }

    func y(for value: Double) -> CGFloat {
        let domain = yDomain
        let span = max(domain.upperBound - domain.lowerBound, 1)
        let normalized = (value - domain.lowerBound) / span
        return size.height - CGFloat(normalized) * size.height
    }

    var pointCoordinates: [CGPoint] {
        points.enumerated().map { index, point in
            CGPoint(x: CGFloat(index) * xStep, y: y(for: point.value))
        }
    }

    var endpoint: CGPoint? {
        pointCoordinates.last
    }
}

#Preview("HRVTrendChart") {
    let now = Date()
    let cal = Calendar.current
    let values: [Double] = [48, 52, 49, 55, 60, 58, 62]
    let points = values.enumerated().map { index, value in
        ChartDataPoint(date: cal.date(byAdding: .day, value: -(6 - index), to: now) ?? now, value: value)
    }
    return VStack {
        HRVTrendChart(dataPoints: points, referenceValue: 52)
        Spacer()
    }
    .padding()
}
