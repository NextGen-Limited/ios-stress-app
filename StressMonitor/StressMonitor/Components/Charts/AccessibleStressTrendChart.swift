import SwiftUI
import Charts

// MARK: - Accessible Stress Trend Chart

/// Line chart with VoiceOver data table alternative
/// Implements WCAG 2.1 AA accessibility requirements for data visualization
struct AccessibleStressTrendChart: View {
    let data: [StressMeasurement]
    let timeRange: TimeRange
    @AccessibilityFocusState private var isChartFocused: Bool
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled

    enum TimeRange: String, CaseIterable {
        case day = "24H"
        case week = "7D"
        case month = "4W"

        var description: String {
            switch self {
            case .day: return "24 hours"
            case .week: return "7 days"
            case .month: return "4 weeks"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            chartHeader

            if data.isEmpty {
                emptyState
            } else {
                if voiceOverEnabled {
                    dataTableView
                } else {
                    visualChartView
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }

    // MARK: - Chart Header

    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Stress Trend")
                .font(Typography.headline)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            if let stats = calculateStats() {
                HStack(spacing: DesignTokens.Spacing.md) {
                    statLabel(title: "Avg", value: "\(Int(stats.average))")
                    statLabel(title: "Min", value: "\(Int(stats.min))")
                    statLabel(title: "Max", value: "\(Int(stats.max))")
                }
                .font(Typography.caption1)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func statLabel(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    // MARK: - Visual Chart

    @ViewBuilder
    private var visualChartView: some View {
        Chart(data) { measurement in
            LineMark(
                x: .value("Time", measurement.timestamp),
                y: .value("Stress", measurement.stressLevel)
            )
            .foregroundStyle(Color.Wellness.calmBlue)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Time", measurement.timestamp),
                y: .value("Stress", measurement.stressLevel)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.Wellness.calmBlue.opacity(0.3),
                        Color.Wellness.calmBlue.opacity(0.1),
                        Color.Wellness.calmBlue.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 200)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.hour().minute())
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 25)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel()
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Data Table (VoiceOver Alternative)

    @ViewBuilder
    private var dataTableView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Stress Measurements")
                .font(Typography.callout)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(data) { measurement in
                        dataTableRow(measurement)
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Stress trend data table")
        .accessibilityHint("Shows \(data.count) measurements over \(timeRange.description)")
    }

    private func dataTableRow(_ measurement: StressMeasurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)

                Text(measurement.category.rawValue.capitalized)
                    .font(Typography.caption2)
                    .foregroundStyle(measurement.category.color)
            }

            Spacer()

            Text("\(Int(measurement.stressLevel))")
                .font(Typography.callout)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(Color.Wellness.background)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(measurement.timestamp.formatted(.dateTime.month().day().hour().minute())), \(Int(measurement.stressLevel)) stress level, \(measurement.category.rawValue)")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No data available")
                .font(Typography.callout)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No stress trend data available for \(timeRange.description)")
    }

    // MARK: - Statistics

    private func calculateStats() -> (average: Double, min: Double, max: Double)? {
        guard !data.isEmpty else { return nil }

        let levels = data.map { $0.stressLevel }
        let sum = levels.reduce(0, +)
        let average = sum / Double(levels.count)
        let min = levels.min() ?? 0
        let max = levels.max() ?? 0

        return (average, min, max)
    }
}

// MARK: - Preview

#Preview("With Data") {
    let measurements = (0..<20).map { i in
        StressMeasurement(
            timestamp: Calendar.current.date(byAdding: .hour, value: -i, to: Date())!,
            stressLevel: Double.random(in: 20...80),
            hrv: 50,
            restingHeartRate: 70
        )
    }

    AccessibleStressTrendChart(
        data: measurements,
        timeRange: .day
    )
    .padding()
    .background(Color.Wellness.background)
}

#Preview("Empty State") {
    AccessibleStressTrendChart(
        data: [],
        timeRange: .week
    )
    .padding()
    .background(Color.Wellness.background)
}

#Preview("VoiceOver Mode") {
    let measurements = (0..<5).map { i in
        StressMeasurement(
            timestamp: Calendar.current.date(byAdding: .hour, value: -i, to: Date())!,
            stressLevel: Double.random(in: 20...80),
            hrv: 50,
            restingHeartRate: 70
        )
    }

    AccessibleStressTrendChart(
        data: measurements,
        timeRange: .day
    )
    .padding()
    .background(Color.Wellness.background)
}
