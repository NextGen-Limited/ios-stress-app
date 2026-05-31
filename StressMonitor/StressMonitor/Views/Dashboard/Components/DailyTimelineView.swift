import SwiftUI

/// Weekly stress timeline showing 7-day × 7-time-slot dot matrix
/// Matches Figma design with pastel colored dots arranged in grid
struct DailyTimelineView: View {
    let measurements: [StressMeasurement]

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let timeBlockCount = 7       // 3-hour blocks per day
    private let dotSize: CGFloat = 19
    private let hSpacing: CGFloat = 22
    private let vSpacing: CGFloat = 24
    private let dayLabelWidth: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            dotGrid
        }
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Text("Daily Timeline")
                .font(Typography.title2)
                .fontWeight(.bold)

            Spacer()

            Text("Last 7 days")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Dot Grid Layout

    private var dotGrid: some View {
        HStack(alignment: .center, spacing: hSpacing) {
            // Day label column
            VStack(alignment: .leading, spacing: vSpacing) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#363636"))
                        .frame(width: dayLabelWidth, alignment: .leading)
                }
            }

            // Time slot columns (7 blocks × 7 days)
            ForEach(0..<timeBlockCount, id: \.self) { blockIndex in
                VStack(spacing: vSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        Circle()
                            .fill(dotColor(dayIndex: dayIndex, blockIndex: blockIndex))
                            .frame(width: dotSize, height: dotSize)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Data Mapping

    /// Returns average stress level for a specific day (0=Mon) and 3-hour block (0–6)
    private func stressLevel(dayIndex: Int, blockIndex: Int) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let hoursPerBlock = 24 / timeBlockCount  // 3 hours per block

        // dayIndex 0=Mon. Today = dayIndex matching weekday.
        // Compute offset: days ago from today
        let todayWeekday = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon...7=Sat
        let todayDayIndex = (todayWeekday + 5) % 7  // convert to 0=Mon
        let dayOffset = dayIndex - todayDayIndex     // negative = past days

        guard let dayStart = calendar.date(
                  byAdding: .day, value: dayOffset,
                  to: calendar.startOfDay(for: now)),
              let blockStart = calendar.date(
                  byAdding: .hour, value: blockIndex * hoursPerBlock,
                  to: dayStart),
              let blockEnd = calendar.date(
                  byAdding: .hour, value: hoursPerBlock,
                  to: blockStart)
        else { return nil }

        let filtered = measurements.filter {
            $0.timestamp >= blockStart && $0.timestamp < blockEnd
        }
        guard !filtered.isEmpty else { return nil }
        return filtered.map(\.stressLevel).reduce(0, +) / Double(filtered.count)
    }

    // MARK: - Color Helpers

    private func dotColor(dayIndex: Int, blockIndex: Int) -> Color {
        guard let level = stressLevel(dayIndex: dayIndex, blockIndex: blockIndex) else {
            return Color.secondary.opacity(0.15)  // No data: gray
        }
        return Color.stressColor(for: level)
    }

    private var accessibilityLabel: String {
        guard !measurements.isEmpty else {
            return "Daily timeline: No measurements for the past 7 days"
        }
        let avg = measurements.map(\.stressLevel).reduce(0, +) / Double(measurements.count)
        return "Daily timeline: Last 7 days, average stress \(Int(avg)) percent"
    }
}

// MARK: - Preview

#Preview("Weekly - Empty") {
    DailyTimelineView(measurements: [])
        .padding()
        .background(Color.backgroundLight)
}

#Preview("Weekly - With Data") {
    let measurements = (0..<20).map { i in
        StressMeasurement(
            timestamp: Calendar.current.date(
                byAdding: .hour, value: -(i * 8), to: Date()) ?? Date(),
            stressLevel: Double.random(in: 10...90),
            hrv: 50,
            restingHeartRate: 65,
            confidences: [0.8]
        )
    }
    return DailyTimelineView(measurements: measurements)
        .padding()
        .background(Color.backgroundLight)
}
