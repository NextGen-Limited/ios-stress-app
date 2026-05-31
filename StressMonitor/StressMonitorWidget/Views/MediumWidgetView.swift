import SwiftUI
import Charts

/// Medium widget view (32x16 modules)
/// Displays stress level, HRV trend chart, and quick stats
@available(iOS 17.0, *)
public struct MediumWidgetView: View {

    let entry: StressEntry

    public init(entry: StressEntry) {
        self.entry = entry
    }

    public var body: some View {
        HStack(spacing: 0) {
            if entry.isPlaceholder {
                placeholderView
            } else if let stress = entry.latestStress {
                stressContent(stress: stress)
            } else {
                emptyStateView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Stress Content

    @ViewBuilder
    private func stressContent(stress: StressData) -> some View {
        // Left side: Current stress
        VStack(alignment: .leading, spacing: 6) {
            // Category icon
            Image(systemName: stress.stressCategory.icon)
                .font(.system(size: 16))
                .foregroundColor(colorForLevel(stress.level))
                .frame(width: 28, height: 28)
                .background(colorForLevel(stress.level).opacity(0.15))
                .cornerRadius(6)

            // Stress level
            Text("\(Int(stress.level))")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Category label
            Text(stress.stressCategory.displayName.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            Spacer()

            // HRV and HR
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text("\(Int(stress.hrv))ms")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                    Text("\(Int(stress.heartRate))bpm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
        .padding(.vertical, 12)

        Divider()
            .frame(width: 1)

        // Right side: HRV trend
        VStack(alignment: .trailing, spacing: 6) {
            Text("HRV Trend")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if entry.history.count >= 2 {
                HRVTrendChart(data: entry.history.prefix(8).reversed())
                    .frame(height: 50)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 50)
                    .overlay(
                        Image(systemName: "chart.line.flattrend")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    )
            }

            // Trend indicator
            HStack(spacing: 2) {
                Image(systemName: entry.trend.icon)
                    .font(.system(size: 8))
                Text(trendText)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(Color(hex: entry.trend.color))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)

                Text("--")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)

                Text("LOADING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()
            }

            Divider()
                .frame(width: 1)

            VStack(alignment: .trailing, spacing: 6) {
                Text("HRV Trend")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 50)

                Spacer()
            }
        }
        .padding(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                Text("No Data")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text("Open app to take your first measurement")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()
            }

            Spacer()
        }
        .padding(12)
    }

    // MARK: - Helpers

    private func colorForLevel(_ level: Double) -> Color {
        switch level {
        case 0...25: return Color(hex: "#34C759")
        case 26...50: return Color(hex: "#007AFF")
        case 51...75: return Color(hex: "#FFD60A")
        case 76...100: return Color(hex: "#FF9500")
        default: return .secondary
        }
    }

    private var trendText: String {
        switch entry.trend {
        case .increasing: return "Rising"
        case .stable: return "Stable"
        case .decreasing: return "Falling"
        }
    }
}

// MARK: - HRV Trend Chart

@available(iOS 17.0, *)
struct HRVTrendChart: View {
    let data: [StressData]

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("HRV", item.hrv)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#34C759"),
                            Color(hex: "#007AFF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.clear)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    MediumWidgetView(entry: StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 42,
            category: "mild",
            hrv: 52,
            heartRate: 72,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [
            StressData(level: 35, category: "mild", hrv: 55, heartRate: 68, confidence: 0.85, timestamp: Date().addingTimeInterval(-4 * 3600)),
            StressData(level: 45, category: "mild", hrv: 48, heartRate: 75, confidence: 0.8, timestamp: Date().addingTimeInterval(-2 * 3600)),
            StressData(level: 42, category: "mild", hrv: 52, heartRate: 72, confidence: 0.85, timestamp: Date()),
        ],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    ))
} timeline: {
    StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 42,
            category: "mild",
            hrv: 52,
            heartRate: 72,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [
            StressData(level: 35, category: "mild", hrv: 55, heartRate: 68, confidence: 0.85, timestamp: Date().addingTimeInterval(-4 * 3600)),
            StressData(level: 45, category: "mild", hrv: 48, heartRate: 75, confidence: 0.8, timestamp: Date().addingTimeInterval(-2 * 3600)),
            StressData(level: 42, category: "mild", hrv: 52, heartRate: 72, confidence: 0.85, timestamp: Date()),
        ],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    )
}
