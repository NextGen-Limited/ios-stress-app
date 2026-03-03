import SwiftUI
import SwiftData

/// Weekly stress heatmap using circular dots (8 time blocks per day) — matches Figma Daily Timeline
struct WeeklyHeatmapView: View {
    let measurements: [StressMeasurement]

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 4
    private let blockCount = 8 // time blocks per day (3-hour intervals)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Timeline")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("Last 7 days")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                // Day label column (full 3-letter abbreviations)
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(height: cellSize)
                    }
                }

                // Dot columns (8 time blocks × 7 days)
                ForEach(0..<blockCount, id: \.self) { block in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            Circle()
                                .fill(colorFor(day: dayIndex, block: block))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }

    private func colorFor(day: Int, block: Int) -> Color {
        guard let stressLevel = stressLevelFor(day: day, block: block) else {
            return Color.secondary.opacity(0.15)
        }
        return Color.stressColor(for: stressLevel)
    }

    /// Maps a day index (0=Mon) and block index (0–7) to an average stress level
    private func stressLevelFor(day: Int, block: Int) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let hoursPerBlock = 24 / blockCount
        // day 0 = Mon (offset from Sun=6), compute actual offset from today
        let dayOffset = -(6 - day)

        guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)),
              let blockStart = calendar.date(byAdding: .hour, value: block * hoursPerBlock, to: dayStart),
              let blockEnd = calendar.date(byAdding: .hour, value: hoursPerBlock, to: blockStart) else {
            return nil
        }

        let blockMeasurements = measurements.filter { $0.timestamp >= blockStart && $0.timestamp < blockEnd }
        guard !blockMeasurements.isEmpty else { return nil }
        return blockMeasurements.map { $0.stressLevel }.reduce(0, +) / Double(blockMeasurements.count)
    }
}

#Preview {
    WeeklyHeatmapView(measurements: [])
        .padding()
        .background(Color.backgroundLight)
}
