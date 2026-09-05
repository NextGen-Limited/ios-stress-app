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
    var metricName: String = "Metric"

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
        .accessibilityChart(
            description: "\(metricName) trend",
            summary: accessibilityTrendSummary,
            points: accessibilityPoints
        )
        .accessibilityHint("Shows \(dataPoints.count) recent measurements")
    }

    // MARK: - Accessibility Series (D-09)

    private static let pointDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Whole days the series spans, floor 1 — restates the span the
    /// timestamps actually cover.
    private var periodText: String {
        guard let first = dataPoints.first?.timestamp,
              let last = dataPoints.last?.timestamp else { return "recent period" }
        let days = max(1, Int(last.timeIntervalSince(first) / 86_400))
        return days == 1 ? "1 day" : "\(days) days"
    }

    private var accessibilityTrendSummary: String {
        guard !dataPoints.isEmpty else { return "No data yet" }
        return VoiceOverLabels.trendSummary(
            metric: metricName,
            values: dataPoints.map(\.value),
            period: periodText
        )
    }

    private var accessibilityPoints: [String] {
        dataPoints.map { point in
            VoiceOverLabels.chartPoint(
                dateText: Self.pointDateFormatter.string(from: point.timestamp),
                valueText: "\(Int(point.value))"
            )
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
