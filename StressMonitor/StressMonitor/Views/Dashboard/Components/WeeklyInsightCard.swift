import SwiftUI

/// Weekly average comparison card showing current week vs last week
struct WeeklyInsightCard: View {
    let currentWeekAvg: Double
    let lastWeekAvg: Double
    let startDate: Date
    let endDate: Date

    private var trend: TrendDirection {
        if currentWeekAvg < lastWeekAvg - 2 { return .improved }
        if currentWeekAvg > lastWeekAvg + 2 { return .increased }
        return .stable
    }

    private var trendColor: Color {
        switch trend {
        case .improved: return .stressRelaxed
        case .increased: return .stressHigh
        case .stable: return .stressMild
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improved: return "arrow.down.right"
        case .increased: return "arrow.up.right"
        case .stable: return "arrow.right"
        }
    }

    private var trendText: String {
        switch trend {
        case .improved: return "Lower than last week"
        case .increased: return "Higher than last week"
        case .stable: return "Similar to last week"
        }
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private var differenceText: String {
        let diff = abs(currentWeekAvg - lastWeekAvg)
        let sign = currentWeekAvg > lastWeekAvg ? "+" : "-"
        return "\(sign)\(Int(diff))"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Calendar icon
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(Color.oledTextSecondary)
                .frame(width: 36, height: 36)
                .background(Color.oledCardSecondary)
                .cornerRadius(10)

            // Date range info
            VStack(alignment: .leading, spacing: 2) {
                Text("Weekly Average")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundColor(Color.oledTextSecondary)
            }

            Spacer()

            // Trend indicator
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.caption2)
                    Text(differenceText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(trendColor)

                Text(trendText)
                    .font(.caption2)
                    .foregroundColor(Color.oledTextSecondary)
            }
        }
        .padding(16)
        .background(Color.oledCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly average: \(Int(currentWeekAvg)), \(trendText)")
    }

    // MARK: - Trend Direction

    private enum TrendDirection {
        case improved
        case increased
        case stable
    }
}

// MARK: - Preview

#Preview("Weekly Insight Card") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            WeeklyInsightCard(
                currentWeekAvg: 32,
                lastWeekAvg: 38,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                endDate: Date()
            )

            WeeklyInsightCard(
                currentWeekAvg: 45,
                lastWeekAvg: 38,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                endDate: Date()
            )

            WeeklyInsightCard(
                currentWeekAvg: 38,
                lastWeekAvg: 37,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                endDate: Date()
            )
        }
        .padding()
    }
}
