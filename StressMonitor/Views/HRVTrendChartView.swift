import SwiftUI
import Charts

/// HRV trend chart using Swift Charts.
/// Displays HRV values over time with color-coded stress zones,
/// a moving average line, and interactive tooltips.
struct HRVTrendChartView: View {
    let hrvData: [Double]
    let stressScores: [(timestamp: Date, score: Double)]

    @State private var selectedPoint: ChartDataPoint?
    @State private var chartRange: ChartTimeRange = .sixHours

    // MARK: - Types

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let hrv: Double
        let stressScore: Double
    }

    enum ChartTimeRange: String, CaseIterable {
        case oneHour = "1H"
        case sixHours = "6H"
        case twelveHours = "12H"
        case twentyFourHours = "24H"

        var hours: Int {
            switch self {
            case .oneHour: return 1
            case .sixHours: return 6
            case .twelveHours: return 12
            case .twentyFourHours: return 24
            }
        }
    }

    // MARK: - Computed Data

    private var chartData: [ChartDataPoint] {
        // Generate timestamps for data points
        let now = Date()
        let interval: TimeInterval = 60 * 5 // 5-minute intervals

        return hrvData.enumerated().map { index, hrv in
            let timestamp = now.addingTimeInterval(-Double(hrvData.count - 1 - index) * interval)
            let stressScore = stressScores.count > index ? stressScores[index].score : 0
            return ChartDataPoint(timestamp: timestamp, hrv: hrv, stressScore: stressScore)
        }
    }

    private var filteredData: [ChartDataPoint] {
        let cutoff = Date().addingTimeInterval(-Double(chartRange.hours) * 3600)
        return chartData.filter { $0.timestamp >= cutoff }
    }

    private var movingAverage: [(timestamp: Date, avg: Double)] {
        let window = 5
        guard filteredData.count >= window else { return [] }

        var result: [(Date, Double)] = []
        for i in (window - 1)..<filteredData.count {
            let slice = filteredData[(i - window + 1)...i]
            let avg = slice.map(\.hrv).reduce(0, +) / Double(window)
            result.append((filteredData[i].timestamp, avg))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            header

            // Chart
            if filteredData.isEmpty {
                emptyState
            } else {
                chart
            }

            // Legend
            legend
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HRV Trend")
                    .font(.headline)

                if let last = filteredData.last {
                    Text("Latest: \(String(format: "%.0f", last.hrv)) ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Time range picker
            Picker("Range", selection: $chartRange) {
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Stress zone backgrounds
            RuleMark(y: .value("High", 80))
                .foregroundStyle(.red.opacity(0.1))
                .lineStyle(StrokeStyle(lineWidth: 0))

            RuleMark(y: .value("Moderate", 50))
                .foregroundStyle(.yellow.opacity(0.1))
                .lineStyle(StrokeStyle(lineWidth: 0))

            // HRV data points
            ForEach(filteredData) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("HRV", point.hrv)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Time", point.timestamp),
                    yStart: .value("Min", 0),
                    yEnd: .value("HRV", point.hrv)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Moving average line
            ForEach(movingAverage.indices, id: \.self) { index in
                let point = movingAverage[index]
                LineMark(
                    x: .value("Time", point.0),
                    y: .value("Average", point.1)
                )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
            }

            // Selected point highlight
            if let selected = selectedPoint {
                PointMark(
                    x: .value("Time", selected.timestamp),
                    y: .value("HRV", selected.hrv)
                )
                .foregroundStyle(.blue)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: 0...120)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: chartRange.hours <= 6 ? 1 : 3)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
            }
        }
        .chartYAxis {
            AxisMarks(values: [20, 40, 60, 80, 100]) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            if let timestamp: Date = proxy.value(atX: location.x) {
                                selectedPoint = filteredData.min(by: {
                                    abs($0.timestamp.timeIntervalSince(timestamp)) <
                                    abs($1.timestamp.timeIntervalSince(timestamp))
                                })
                            }
                        case .ended:
                            selectedPoint = nil
                        }
                    }
            }
        }
        .frame(height: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No HRV data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Start monitoring to see your HRV trend")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            LegendItem(color: .blue, label: "HRV (ms)")
            LegendItem(color: .orange, label: "Moving Avg", isDashed: true)
            LegendItem(color: .red.opacity(0.3), label: "High Stress Zone")
        }
        .font(.caption2)
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if isDashed {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 16, height: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                            .foregroundColor(color)
                    )
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 16, height: 3)
            }

            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stress Score Chart

/// Compact stress score trend chart.
struct StressScoreChartView: View {
    let scores: [(timestamp: Date, score: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stress Score Trend")
                .font(.headline)

            if scores.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(scores, id: \.timestamp) { point in
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Score", point.score * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .yellow, .red].map { $0.opacity(0.4) },
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Score", point.score * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYScale(domain: 0...100)
                .chartXAxis { AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                }}
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 100)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HRVTrendChartView(
                hrvData: [45, 50, 42, 55, 48, 60, 52, 47, 58, 44, 51, 49],
                stressScores: stride(from: 0, to: 12, by: 1).map { i in
                    (Date().addingTimeInterval(-Double(i) * 300), Double.random(in: 0.2...0.7))
                }
            )

            StressScoreChartView(
                scores: stride(from: 0, to: 20, by: 1).map { i in
                    (Date().addingTimeInterval(-Double(i) * 300), Double.random(in: 0.1...0.8))
                }
            )
        }
        .padding()
    }
}
