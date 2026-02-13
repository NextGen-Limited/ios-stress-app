import SwiftUI
import Charts

// MARK: - Sparkline Chart

/// Mini trend chart for quick stats cards
/// Shows last 7 data points in compact 60x120pt format
/// Full Reduce Motion support with static chart
struct SparklineChart: View {
    let data: [DataPoint]
    let tintColor: Color
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    struct DataPoint: Identifiable {
        let id = UUID()
        let value: Double
        let timestamp: Date
    }

    var body: some View {
        Group {
            if data.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .frame(width: 120, height: 60)
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(tintColor)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        tintColor.opacity(0.3),
                        tintColor.opacity(0.1),
                        tintColor.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yAxisDomain())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trend chart")
        .accessibilityValue(trendDescription)
        .accessibilityHint("Shows \(data.count) recent measurements")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Rectangle()
            .fill(.clear)
            .overlay(
                Image(systemName: "chart.line.flattrend.xyaxis")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            )
            .accessibilityLabel("No trend data available")
    }

    // MARK: - Helpers

    private func yAxisDomain() -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }

        let values = data.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 100

        let padding = (max - min) * 0.2
        return (min - padding)...(max + padding)
    }

    private var trendDescription: String {
        guard data.count >= 2 else { return "Insufficient data" }

        let firstValue = data.first?.value ?? 0
        let lastValue = data.last?.value ?? 0
        let change = lastValue - firstValue

        if change > 5 {
            return "Trending up by \(Int(abs(change))) points"
        } else if change < -5 {
            return "Trending down by \(Int(abs(change))) points"
        } else {
            return "Stable trend"
        }
    }
}

// MARK: - Preview

#Preview("Upward Trend") {
    VStack(spacing: 16) {
        let data = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double(30 + i * 5),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }

        SparklineChart(data: data, tintColor: .green)
            .padding()
            .background(Color.Wellness.surface)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.Wellness.background)
}

#Preview("Downward Trend") {
    VStack(spacing: 16) {
        let data = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double(70 - i * 5),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }

        SparklineChart(data: data, tintColor: .red)
            .padding()
            .background(Color.Wellness.surface)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.Wellness.background)
}

#Preview("Empty") {
    SparklineChart(data: [], tintColor: .blue)
        .padding()
        .background(Color.Wellness.surface)
        .cornerRadius(12)
        .padding()
        .background(Color.Wellness.background)
}

#Preview("Reduce Motion") {
    VStack(spacing: 16) {
        let data = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double.random(in: 40...80),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }

        SparklineChart(data: data, tintColor: .blue)
            .padding()
            .background(Color.Wellness.surface)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.Wellness.background)
}
