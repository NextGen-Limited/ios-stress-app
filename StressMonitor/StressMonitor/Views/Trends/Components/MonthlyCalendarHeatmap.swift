import SwiftUI

/// Full-month calendar heatmap for the Trends tab.
///
/// Renders the current month as a weekday-leading grid (Sun-anchored). Each day
/// that has measurements is filled with its stress-tier color; empty future
/// days stay neutral. Today is outlined with the Ripple accent ring.
struct MonthlyCalendarHeatmap: View {
    let dailyLevels: [Date: Double]
    var monthDate: Date = Date()

    private let calendar = Calendar.current

    private var monthSymbol: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthDate)
    }

    /// First-of-month at midnight, anchored for all math.
    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        return calendar.date(from: components) ?? monthDate
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    /// Number of leading empty cells before day 1 (0 = Sunday).
    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return weekday - 1
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var dayWidth: CGFloat { 38 }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            weekdayLabels
            grid
        }
        .padding(18)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly stress calendar for \(monthSymbol).")
    }

    private var header: some View {
        Text(monthSymbol)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color.Wellness.adaptivePrimaryText)
    }

    private var weekdayLabels: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<totalCells, id: \.self) { index in
                cell(at: index)
            }
        }
    }

    private var weekdaySymbols: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }

    private var totalCells: Int {
        leadingBlanks + daysInMonth
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        if index < leadingBlanks {
            Color.clear.frame(height: dayWidth)
        } else {
            let day = index - leadingBlanks + 1
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let level = dailyLevels[calendar.startOfDay(for: date)]
            let tier = level.map { StressTier.from(level: $0) }

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tier?.color.opacity(0.85) ?? Color.Wellness.adaptiveSecondaryText.opacity(0.10))

                Text("\(day)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(tier == nil ? Color.Wellness.adaptiveSecondaryText : .white)
            }
            .frame(height: dayWidth)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isToday ? HomeCharacterDesignTokens.Ripple.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .accessibilityLabel(accessibilityLabel(for: day, tier: tier, isToday: isToday))
        }
    }

    private func accessibilityLabel(for day: Int, tier: StressTier?, isToday: Bool) -> String {
        var parts = ["Day \(day)"]
        if isToday { parts.append("today") }
        if let tier { parts.append(tier.label) } else { parts.append("no data") }
        return parts.joined(separator: ", ")
    }
}

#Preview("MonthlyCalendarHeatmap") {
    let now = Date()
    let cal = Calendar.current
    var levels: [Date: Double] = [:]
    for offset in 0..<20 {
        if let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: now)) {
            levels[cal.startOfDay(for: date)] = Double.random(in: 10...85)
        }
    }
    return VStack {
        MonthlyCalendarHeatmap(dailyLevels: levels)
        Spacer()
    }
    .padding()
}
