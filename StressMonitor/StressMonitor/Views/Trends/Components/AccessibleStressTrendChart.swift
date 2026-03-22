import Charts
import SwiftUI

/// Accessible stress trend chart with time range selection and VoiceOver data table
struct AccessibleStressTrendChart: View {

    // MARK: - Time Range

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

        var hoursBack: Int {
            switch self {
            case .day: return 24
            case .week: return 168
            case .month: return 672
            }
        }
    }

    // MARK: - Properties

    let measurements: [StressMeasurement]

    @State private var selectedRange: TimeRange = .day
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed

    private var filteredMeasurements: [StressMeasurement] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -selectedRange.hoursBack, to: Date()) ?? .distantPast
        return measurements.filter { $0.timestamp >= cutoff }.sorted { $0.timestamp < $1.timestamp }
    }

    private var average: Double {
        guard !filteredMeasurements.isEmpty else { return 0 }
        return filteredMeasurements.map(\.stressLevel).reduce(0, +) / Double(filteredMeasurements.count)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            chartContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Stress trend chart for \(selectedRange.description)")
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Text("Stress Trend")
                .font(.headline)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Spacer()

            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }

    private var chartContent: some View {
        Group {
            if filteredMeasurements.isEmpty {
                emptyState
            } else {
                trendChart
            }
        }
    }

    private var emptyState: some View {
        Text("No data for \(selectedRange.description)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
            .multilineTextAlignment(.center)
    }

    private var trendChart: some View {
        Chart(filteredMeasurements) { measurement in
            if reduceMotion {
                PointMark(
                    x: .value("Time", measurement.timestamp),
                    y: .value("Stress", measurement.stressLevel)
                )
                .foregroundStyle(Color.stressColor(for: measurement.category))
            } else {
                LineMark(
                    x: .value("Time", measurement.timestamp),
                    y: .value("Stress", measurement.stressLevel)
                )
                .foregroundStyle(Color.stressColor(for: measurement.category))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                AreaMark(
                    x: .value("Time", measurement.timestamp),
                    y: .value("Stress", measurement.stressLevel)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.hour())
                    .font(.caption2)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text("\(intVal)")
                            .font(.caption2)
                            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    }
                }
            }
        }
        .frame(height: 160)
        .accessibilityHidden(true)
        .overlay(alignment: .topTrailing) {
            Text("Avg \(Int(average))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(4)
        }
    }
}

// MARK: - Preview

#Preview {
    AccessibleStressTrendChart(measurements: [])
        .padding()
}
