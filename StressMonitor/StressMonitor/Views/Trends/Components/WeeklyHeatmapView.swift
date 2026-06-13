import SwiftUI
import SwiftData

/// 5-Tier Heatmap — rounded square cells coloured by Ripple stress tier.
///
/// No numeric values in cells — colour *is* the indicator.
/// Includes a gradient legend strip from calm (blue) to overwhelmed (red).
struct WeeklyHeatmapView: View {
    let measurements: [StressMeasurement]

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 4
    private let blockCount = 8 // time blocks per day (3-hour intervals)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily Timeline")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("Last 7 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }

            // Heatmap grid
            HStack(alignment: .top, spacing: cellSpacing) {
                // Day label column
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(days, id: \.self) { _ in
                        Color.clear
                            .frame(width: 1, height: cellSize)
                    }
                }

                // Cell columns (8 time blocks × 7 days)
                ForEach(0..<blockCount, id: \.self) { block in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(colorFor(day: dayIndex, block: block))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }

            // Time-of-day labels
            HStack {
                Text("12am")
                Spacer()
                Text("12pm")
                Spacer()
                Text("11pm")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.white.opacity(0.3))

            // Gradient legend strip
            legendStrip
        }
        .trendsGlassCard()
    }

    // MARK: - Legend

    private var legendStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(TrendsPalette.tierGradient)
                .frame(height: 8)

            HStack {
                Text("Calm")
                Spacer()
                Text("Overwhelmed")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Cell Colour

    private func colorFor(day: Int, block: Int) -> Color {
        guard let stressLevel = stressLevelFor(day: day, block: block) else {
            return Color.white.opacity(0.06) // empty cell
        }
        return StressTier.from(level: stressLevel).color.opacity(0.85)
    }

    /// Maps a day index (0=Mon) and block index (0–7) to an average stress level.
    private func stressLevelFor(day: Int, block: Int) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let hoursPerBlock = 24 / blockCount
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

// MARK: - Preview

struct WeeklyHeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyHeatmapView(measurements: [])
            .padding()
            .background(TrendsPalette.darkCanvas)
    }
}
