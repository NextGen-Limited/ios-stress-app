import Charts
import SwiftUI

/// Compact sparkline chart for displaying short data series in metric cards
struct SparklineChart: View {

    // MARK: - Data Point

    struct DataPoint: Identifiable {
        let id = UUID()
        let value: Double
        let timestamp: Date
    }

    // MARK: - Properties

    let dataPoints: [DataPoint]
    var color: Color = .accentColor
    var lineWidth: CGFloat = 2

    // MARK: - Computed

    private var yDomain: ClosedRange<Double> {
        guard !dataPoints.isEmpty else { return 0...100 }
        let values = dataPoints.map(\.value)
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let range = max - min
        let padding = range * 0.2
        return (min - padding)...(max + padding)
    }

    private var trendChange: Double {
        guard let first = dataPoints.first?.value, let last = dataPoints.last?.value else { return 0 }
        return last - first
    }

    // MARK: - Body

    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 120, height: 60)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Shows \(dataPoints.count) recent measurements")
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let change = abs(trendChange)
        if trendChange > 5 {
            return "Trending up by \(Int(change)) points"
        } else if trendChange < -5 {
            return "Trending down by \(Int(change)) points"
        } else {
            return "Stable trend"
        }
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let points = (0..<7).map { i in
        SparklineChart.DataPoint(
            value: Double(30 + i * 5),
            timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: now)!
        )
    }

    return SparklineChart(dataPoints: points, color: .accentColor)
        .padding()
}
