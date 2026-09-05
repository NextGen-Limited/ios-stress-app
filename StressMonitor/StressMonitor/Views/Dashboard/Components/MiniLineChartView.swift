import Charts
import SwiftUI

/// Mini line chart for metric cards using SwiftUI Charts
struct MiniLineChartView: View {
    let dataPoints: [Double]
    let color: Color
    var showGradient: Bool = true
    var metricName: String = "Metric"

    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if showGradient {
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .frame(height: 40)
        }
        .accessibilityChart(
            description: "\(metricName) trend",
            summary: accessibilityTrendSummary,
            points: accessibilityPoints
        )
    }

    // MARK: - Accessibility Series (D-09)

    /// Index-only series carries no dates — the period restates the point
    /// count and each point its position.
    private var accessibilityTrendSummary: String {
        guard !dataPoints.isEmpty else { return "No data yet" }
        return VoiceOverLabels.trendSummary(
            metric: metricName,
            values: dataPoints,
            period: "\(dataPoints.count) points"
        )
    }

    private var accessibilityPoints: [String] {
        dataPoints.enumerated().map { index, value in
            VoiceOverLabels.chartPoint(dateText: "Point \(index + 1)", valueText: "\(Int(value))")
        }
    }
}

#Preview("Mini Line Chart") {
    VStack(spacing: 20) {
        MiniLineChartView(
            dataPoints: [45, 52, 48, 55, 50, 58, 62],
            color: .hrvAccent
        )
        .frame(width: 100)

        MiniLineChartView(
            dataPoints: [72, 68, 70, 65, 68, 72, 70],
            color: .heartRateAccent
        )
        .frame(width: 100)

        MiniLineChartView(
            dataPoints: [20, 35, 28, 42, 38, 45, 52],
            color: .stressMild
        )
        .frame(width: 100)
    }
    .padding()
    .background(Color.oledCardBackground)
}
