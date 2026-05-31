import SwiftUI
import Charts

/// Full-featured Stress History Timeline with Activity Correlation.
/// Replaces the placeholder HistoryView. Provides day/week/month timeline,
/// stress-over-time chart with workout markers, daily summaries, and
/// correlation insights.
struct StressHistoryView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var activityManager = ActivityManager()

    @State private var selectedRange: HistoryTimeRange = .week
    @State private var selectedDay: DailyStressSummary?
    @State private var showingDetail = false

    // MARK: - Time Range

    enum HistoryTimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"

        var days: Int {
            switch self {
            case .day:   return 1
            case .week:  return 7
            case .month: return 30
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Time range picker
                    rangePicker

                    // Stress timeline chart with activity markers
                    StressTimelineChartView(
                        readings: filteredReadings,
                        workouts: filteredWorkouts,
                        timeRange: selectedRange
                    )

                    // Activity correlation summary
                    if !activityManager.correlations.isEmpty {
                        CorrelationInsightsView(
                            correlations: activityManager.correlations
                        )
                    }

                    // Daily summaries
                    DailySummariesListView(
                        summaries: filteredSummaries,
                        selectedDay: $selectedDay,
                        showingDetail: $showingDetail
                    )
                }
                .padding()
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(activityManager.isLoading)
                }
            }
            .task {
                await loadHistory()
            }
            .sheet(isPresented: $showingDetail) {
                if let day = selectedDay {
                    DayDetailView(summary: day)
                }
            }
        }
    }

    // MARK: - Subviews

    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(HistoryTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Filtered Data

    private var filteredReadings: [StressReading] {
        let cutoff = cutoffDate
        return healthManager.recentReadings.filter { $0.timestamp >= cutoff }
    }

    private var filteredWorkouts: [ActivityWorkout] {
        let cutoff = cutoffDate
        return activityManager.workouts.filter { $0.startDate >= cutoff }
    }

    private var filteredSummaries: [DailyStressSummary] {
        let count = selectedRange.days
        return Array(activityManager.dailySummaries.prefix(count))
    }

    private var cutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
    }

    // MARK: - Actions

    private func loadHistory() async {
        activityManager.historyDays = selectedRange.days
        let hrvPairs = healthManager.recentReadings.map {
            (timestamp: $0.timestamp, value: $0.hrv)
        }
        await activityManager.fetchHistory(
            stressReadings: healthManager.recentReadings,
            hrvByTimestamp: hrvPairs
        )
    }

    private func refresh() {
        Task { await loadHistory() }
    }
}

// MARK: - Stress Timeline Chart

/// Line chart of stress over time with workout activity markers overlaid.
struct StressTimelineChartView: View {
    let readings: [StressReading]
    let workouts: [ActivityWorkout]
    let timeRange: StressHistoryView.HistoryTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stress Timeline")
                    .font(.headline)
                Spacer()
                Text("\(readings.count) readings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if readings.isEmpty {
                emptyChart
            } else {
                chart
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .blue, label: "Stress Level")
                LegendItem(color: .green, label: "Workouts")
                LegendItem(color: .red.opacity(0.3), label: "High Zone")
            }
            .font(.caption2)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var chart: some View {
        Chart {
            // Stress zone background
            RuleMark(y: .value("High", 0.8))
                .foregroundStyle(.red.opacity(0.08))
            RuleMark(y: .value("Moderate", 0.6))
                .foregroundStyle(.orange.opacity(0.06))

            // Stress area + line
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("Stress", reading.level)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Time", reading.timestamp),
                    yStart: .value("Min", 0),
                    yEnd: .value("Stress", reading.level)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.25), .blue.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Workout activity markers (vertical range marks)
            ForEach(workouts) { workout in
                RectangleMark(
                    xStart: .value("Start", workout.startDate),
                    xEnd: .value("End", workout.endDate)
                )
                .foregroundStyle(.green.opacity(0.15))

                PointMark(
                    x: .value("Time", workout.startDate),
                    y: .value("Stress", 0.02)
                )
                .symbol {
                    Image(systemName: workout.icon)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: xAxisStride) { value in
                AxisGridLine()
                AxisValueLabel(format: xAxisFormat)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 0.2, 0.4, 0.6, 0.8, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v * 100))%")
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No stress data for this period")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start monitoring to build your history")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Axis Helpers

    private var xAxisStride: Calendar.Component {
        switch timeRange {
        case .day:   return .hour
        case .week:  return .day
        case .month: return .weekOfYear
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch timeRange {
        case .day:
            return .dateTime.hour(.defaultDigits(amPM: .omitted))
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.month(.abbreviated).day()
        }
    }
}

// MARK: - Correlation Insights

/// Horizontal scroll of activity-stress correlation cards.
struct CorrelationInsightsView: View {
    let correlations: [StressActivityCorrelation]

    private var relievingCount: Int {
        correlations.filter(\.isStressRelieving).count
    }

    private var inducingCount: Int {
        correlations.filter(\.isStressInducing).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity Insights")
                    .font(.headline)
                Spacer()
                Text("\(correlations.count) activities analyzed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Summary stats
            HStack(spacing: 12) {
                InsightStatBadge(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    count: relievingCount,
                    label: "Reduced Stress"
                )
                InsightStatBadge(
                    icon: "arrow.up.circle.fill",
                    color: .red,
                    count: inducingCount,
                    label: "Increased Stress"
                )
                InsightStatBadge(
                    icon: "minus.circle.fill",
                    color: .gray,
                    count: correlations.count - relievingCount - inducingCount,
                    label: "Neutral"
                )
            }

            // Correlation cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(correlations.prefix(10)) { correlation in
                        CorrelationCardView(correlation: correlation)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Correlation Card

struct CorrelationCardView: View {
    let correlation: StressActivityCorrelation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Activity header
            HStack(spacing: 6) {
                Image(systemName: correlation.workout.icon)
                    .font(.caption)
                    .foregroundColor(.green)
                Text(correlation.workout.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(correlation.workout.startDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Stress change indicator
            HStack(spacing: 4) {
                Image(systemName: correlation.trendIcon)
                    .font(.caption)
                    .foregroundColor(correlation.isStressRelieving ? .green :
                                     correlation.isStressInducing ? .red : .gray)
                Text(String(format: "%+.0f%%", correlation.stressChange * 100))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(correlation.isStressRelieving ? .green :
                                     correlation.isStressInducing ? .red : .gray)
            }

            // Before/After comparison
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Before")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", correlation.stressBefore * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("After")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", correlation.stressAfter * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(correlation.isStressRelieving ? .green :
                                         correlation.isStressInducing ? .red : .primary)
                }
            }

            // Duration
            Text(formatDuration(correlation.workout.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
    }
}

// MARK: - Insight Stat Badge

struct InsightStatBadge: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Daily Summaries List

struct DailySummariesListView: View {
    let summaries: [DailyStressSummary]
    @Binding var selectedDay: DailyStressSummary?
    @Binding var showingDetail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Summary")
                .font(.headline)

            if summaries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No daily data yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(summaries) { summary in
                    Button {
                        selectedDay = summary
                        showingDetail = true
                    } label: {
                        DailySummaryRow(summary: summary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Daily Summary Row

struct DailySummaryRow: View {
    let summary: DailyStressSummary

    var body: some View {
        HStack(spacing: 12) {
            // Date column
            VStack(alignment: .center, spacing: 2) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(dayNumber)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
            }
            .frame(width: 44)

            Divider()
                .frame(height: 36)

            // Stress summary
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(stressColor)
                        .frame(width: 8, height: 8)
                    Text(summary.stressCategory.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(String(format: "%.0f%%", summary.averageStress * 100))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Label(
                        String(format: "%.0f ms", summary.averageHRV),
                        systemImage: "waveform.path.ecg"
                    )
                    .font(.caption2)
                    .foregroundColor(.blue)

                    if summary.readingCount > 0 {
                        Text("\(summary.readingCount) readings")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Activity indicators
            VStack(alignment: .trailing, spacing: 4) {
                if summary.workoutCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(summary.workoutCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(summary.totalWorkoutMinutes)m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Correlation indicator
                if let best = bestCorrelation {
                    HStack(spacing: 3) {
                        Image(systemName: best.trendIcon)
                            .font(.caption2)
                        Text(String(format: "%+.0f%%", best.stressChange * 100))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(best.isStressRelieving ? .green :
                                     best.isStressInducing ? .red : .gray)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: summary.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: summary.date)
    }

    private var stressColor: Color {
        switch summary.stressCategory {
        case .resting:  return .green
        case .low:      return .blue
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }

    private var bestCorrelation: StressActivityCorrelation? {
        summary.correlations.min(by: { $0.stressChange < $1.stressChange })
    }
}

// MARK: - Day Detail Sheet

struct DayDetailView: View {
    let summary: DailyStressSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stress stats card
                    statsCard

                    // Workouts list
                    if !summary.workouts.isEmpty {
                        workoutsCard
                    }

                    // Correlations
                    if !summary.correlations.isEmpty {
                        dayCorrelationsCard
                    }
                }
                .padding()
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: summary.date)
    }

    private var statsCard: some View {
        VStack(spacing: 12) {
            Text("Stress Overview")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(
                    label: "Average",
                    value: String(format: "%.0f%%", summary.averageStress * 100),
                    color: stressColor
                )
                StatBox(
                    label: "Peak",
                    value: String(format: "%.0f%%", summary.peakStress * 100),
                    color: .orange
                )
                StatBox(
                    label: "Lowest",
                    value: String(format: "%.0f%%", summary.lowestStress * 100),
                    color: .green
                )
                StatBox(
                    label: "Avg HRV",
                    value: String(format: "%.0f ms", summary.averageHRV),
                    color: .blue
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var stressColor: Color {
        switch summary.stressCategory {
        case .resting:  return .green
        case .low:      return .blue
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }

    private var workoutsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities")
                .font(.headline)

            ForEach(summary.workouts) { workout in
                HStack(spacing: 12) {
                    Image(systemName: workout.icon)
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(workout.startDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDuration(workout.duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let cal = workout.calories {
                            Text("\(Int(cal)) kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var dayCorrelationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity-Stress Correlations")
                .font(.headline)

            ForEach(summary.correlations) { correlation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: correlation.workout.icon)
                            .foregroundColor(.green)
                        Text(correlation.workout.displayName)
                            .fontWeight(.medium)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: correlation.trendIcon)
                            Text(String(format: "%+.0f%%", correlation.stressChange * 100))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(
                            correlation.isStressRelieving ? .green :
                            correlation.isStressInducing ? .red : .gray
                        )
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Before: \(String(format: "%.0f%%", correlation.stressBefore * 100))")
                                .font(.caption)
                            Text("HRV: \(String(format: "%.0f ms", correlation.hrvBefore))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading) {
                            Text("After: \(String(format: "%.0f%%", correlation.stressAfter * 100))")
                                .font(.caption)
                            Text("HRV: \(String(format: "%.0f ms", correlation.hrvAfter))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(correlation.trendDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    StressHistoryView()
        .environmentObject(HealthKitManager())
}
