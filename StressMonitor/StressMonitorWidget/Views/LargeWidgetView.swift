import SwiftUI
import Charts

/// Large widget view (32x32 modules)
/// Displays full stress history, trends, and personalized recommendations
@available(iOS 17.0, *)
public struct LargeWidgetView: View {

    let entry: StressEntry

    public init(entry: StressEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        VStack(spacing: 0) {
            // Header with current stress
            headerSection(stress: stress)

            Divider()

            // History chart
            if entry.history.count >= 2 {
                historyChartSection
            }

            Divider()

            // Quick stats
            quickStatsSection(stress: stress)

            Divider()

            // Recommendations
            recommendationsSection
        }
    }

    // MARK: - Header Section

    private func headerSection(stress: StressData) -> some View {
        HStack(spacing: 12) {
            // Stress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: stress.level / 100)
                    .stroke(
                        colorForLevel(stress.level),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(stress.level))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(stress.stressCategory.displayName.uppercased())
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.3)
                }
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                // Category with icon
                HStack(spacing: 4) {
                    Image(systemName: stress.stressCategory.icon)
                        .font(.system(size: 12))
                        .foregroundColor(colorForLevel(stress.level))

                    Text("Stress Level")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // HRV and Heart Rate
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                        Text("\(Int(stress.hrv))ms")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 3) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                        Text("\(Int(stress.heartRate))bpm")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                // Trend
                HStack(spacing: 3) {
                    Image(systemName: entry.trend.icon)
                        .font(.system(size: 8))
                    Text("Trend: \(trendText)")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: entry.trend.color))
            }

            Spacer()

            // Link to app
            Link(destination: URL(string: "stressmonitor://dashboard")!) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(12)
    }

    // MARK: - History Chart Section

    private var historyChartSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stress History")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            StressHistoryChart(data: entry.history.prefix(12).reversed())
                .frame(height: 70)
        }
        .padding(12)
    }

    // MARK: - Quick Stats Section

    private func quickStatsSection(stress: StressData) -> some View {
        HStack(spacing: 0) {
            // Average
            statItem(
                icon: "chart.bar.fill",
                title: "Average",
                value: "\(Int(entry.averageStress))",
                color: .blue
            )

            Divider()
                .frame(width: 1)

            // Best
            if let best = entry.history.min(by: { $0.level < $1.level }) {
                statItem(
                    icon: "arrow.down.right",
                    title: "Best",
                    value: "\(Int(best.level))",
                    color: .green
                )
            }

            Divider()
                .frame(width: 1)

            // Readings count
            statItem(
                icon: "calendar",
                title: "Readings",
                value: "\(entry.history.count)",
                color: .purple
            )
        }
        .frame(height: 50)
    }

    private func statItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)

                Text("Insight")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()
            }

            Text(recommendationText)
                .font(.system(size: 10))
                .foregroundColor(.primary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                    .frame(width: 64, height: 64)

                Image(systemName: "waveform.path")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }

            Text("Loading...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("Please wait while we load your stress data")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("No Data Available")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Text("Open the Stress Monitor app to take your first measurement and start tracking your stress levels.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Link(destination: URL(string: "stressmonitor://dashboard")!) {
                Text("Open App")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

    private var recommendationText: String {
        guard let stress = entry.latestStress else {
            return "Start tracking your stress to receive personalized insights."
        }

        switch stress.stressCategory {
        case .relaxed:
            return "You're doing great! Your stress levels are in a healthy range. Keep up with your current routine."
        case .mild:
            return "Mild stress detected. Consider taking short breaks throughout the day and practicing deep breathing."
        case .moderate:
            return "Moderate stress levels. Try a 5-minute breathing exercise or a short walk to help reduce stress."
        case .high:
            return "High stress detected. Consider stepping away, practicing mindfulness, or engaging in physical activity."
        }
    }
}

// MARK: - Stress History Chart

@available(iOS 17.0, *)
struct StressHistoryChart: View {
    let data: [StressData]

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                AreaMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Stress", item.level)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#007AFF").opacity(0.3),
                            Color(hex: "#007AFF").opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Stress", item.level)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color(hex: "#007AFF"))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview(as: .systemLarge) {
    LargeWidgetView(entry: StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 38,
            category: "mild",
            hrv: 54,
            heartRate: 70,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [
            StressData(level: 25, category: "relaxed", hrv: 65, heartRate: 62, confidence: 0.9, timestamp: Date().addingTimeInterval(-12 * 3600)),
            StressData(level: 40, category: "mild", hrv: 52, heartRate: 70, confidence: 0.85, timestamp: Date().addingTimeInterval(-10 * 3600)),
            StressData(level: 55, category: "moderate", hrv: 42, heartRate: 78, confidence: 0.8, timestamp: Date().addingTimeInterval(-8 * 3600)),
            StressData(level: 35, category: "mild", hrv: 58, heartRate: 65, confidence: 0.85, timestamp: Date().addingTimeInterval(-6 * 3600)),
            StressData(level: 30, category: "relaxed", hrv: 62, heartRate: 64, confidence: 0.88, timestamp: Date().addingTimeInterval(-4 * 3600)),
            StressData(level: 45, category: "mild", hrv: 50, heartRate: 72, confidence: 0.82, timestamp: Date().addingTimeInterval(-2 * 3600)),
            StressData(level: 38, category: "mild", hrv: 54, heartRate: 70, confidence: 0.85, timestamp: Date()),
        ],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    ))
} timeline: {
    StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 38,
            category: "mild",
            hrv: 54,
            heartRate: 70,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [
            StressData(level: 25, category: "relaxed", hrv: 65, heartRate: 62, confidence: 0.9, timestamp: Date().addingTimeInterval(-12 * 3600)),
            StressData(level: 40, category: "mild", hrv: 52, heartRate: 70, confidence: 0.85, timestamp: Date().addingTimeInterval(-10 * 3600)),
            StressData(level: 55, category: "moderate", hrv: 42, heartRate: 78, confidence: 0.8, timestamp: Date().addingTimeInterval(-8 * 3600)),
            StressData(level: 35, category: "mild", hrv: 58, heartRate: 65, confidence: 0.85, timestamp: Date().addingTimeInterval(-6 * 3600)),
            StressData(level: 30, category: "relaxed", hrv: 62, heartRate: 64, confidence: 0.88, timestamp: Date().addingTimeInterval(-4 * 3600)),
            StressData(level: 45, category: "mild", hrv: 50, heartRate: 72, confidence: 0.82, timestamp: Date().addingTimeInterval(-2 * 3600)),
            StressData(level: 38, category: "mild", hrv: 54, heartRate: 70, confidence: 0.85, timestamp: Date()),
        ],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    )
}
