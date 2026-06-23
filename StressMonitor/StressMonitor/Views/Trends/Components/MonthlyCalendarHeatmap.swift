import SwiftUI

/// Monthly calendar heatmap matching `06-trends.html` section 4.
///
/// Renders a full month as a Monday-anchored 7-column grid of circular cells.
/// Each day that has stress data is filled with its stress-tier color
/// (Relaxed / Mild / Moderate / High). Today is outlined with the accent ring.
/// Future days are dimmed. Empty leading/trailing cells are transparent.
struct MonthlyCalendarHeatmap: View {
    /// Maps start-of-day → average stress level (0–100).
    let dailyLevels: [Date: Double]
    var monthDate: Date = Date()

    private let calendar = Calendar.current

    // MARK: - Month Math

    private var monthSymbol: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthDate)
    }

    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        return calendar.date(from: components) ?? monthDate
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    /// Monday = 0, Sunday = 6 (Calendar weekday is 1=Sun … 7=Sat).
    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday + 5) % 7
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var totalCells: Int {
        let raw = leadingBlanks + daysInMonth
        // Pad to a full week so trailing days render.
        let remainder = raw % 7
        return remainder == 0 ? raw : raw + (7 - remainder)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthSymbol)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Spacer()
                Text("daily score")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
            }

            weekdayHeader

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<totalCells, id: \.self) { index in
                    cell(at: index)
                }
            }

            legend
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly stress calendar for \(monthSymbol).")
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.55))
                    .tracking(0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
            }
        }
    }

    // MARK: - Cell

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        if index < leadingBlanks || index >= leadingBlanks + daysInMonth {
            // Leading/trailing empty cell — transparent.
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        } else {
            let day = index - leadingBlanks + 1
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isFuture = date > today
            let level = dailyLevels[calendar.startOfDay(for: date)]
            let tier = level.map { stressTier(for: $0) }

            ZStack {
                Circle()
                    .fill(cellBackground(tier: tier, isFuture: isFuture))

                Text("\(day)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(cellTextColor(tier: tier, isFuture: isFuture))
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Circle()
                    .stroke(
                        isToday ? Color(hex: "#0288D1") : Color.clear,
                        lineWidth: 2
                    )
            )
            .accessibilityLabel(accessibilityLabel(for: day, tier: tier, isToday: isToday, isFuture: isFuture))
        }
    }

    // MARK: - Tier Helpers (4-band, matching CSS)

    /// Maps a 0–100 stress level to the 4-tier system used by the HTML
    /// (Relaxed / Mild / Moderate / High). Different from StressTier's
    /// 5-band system — the calendar uses simpler 4-step grouping.
    private func stressTier(for level: Double) -> StressCategory {
        switch level {
        case ..<25:   return .relaxed
        case ..<50:   return .mild
        case ..<75:   return .moderate
        default:      return .high
        }
    }

    private func cellBackground(tier: StressCategory?, isFuture: Bool) -> Color {
        if isFuture {
            return Color.Wellness.adaptiveSecondaryText.opacity(0.04)
        }
        if let tier {
            return tier.color
        }
        return Color.Wellness.adaptiveSecondaryText.opacity(0.06)
    }

    private func cellTextColor(tier: StressCategory?, isFuture: Bool) -> Color {
        if isFuture {
            return Color.Wellness.adaptiveSecondaryText.opacity(0.32)
        }
        if let tier {
            // Moderate is yellow → use dark text for contrast.
            return tier == .moderate ? Color.black.opacity(0.55) : Color.white
        }
        return Color.black.opacity(0.55)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 10) {
            legendDot(color: StressCategory.relaxed.color, label: "Relaxed")
            legendDot(color: StressCategory.mild.color, label: "Mild")
            legendDot(color: StressCategory.moderate.color, label: "Moderate")
            legendDot(color: StressCategory.high.color, label: "High")
            legendDot(color: Color.Wellness.adaptiveSecondaryText.opacity(0.18), label: "Upcoming")
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
        }
    }

    // MARK: - Accessibility

    private func accessibilityLabel(
        for day: Int,
        tier: StressCategory?,
        isToday: Bool,
        isFuture: Bool
    ) -> String {
        var parts = ["Day \(day)"]
        if isToday { parts.append("today") }
        if isFuture { parts.append("upcoming") }
        if let tier { parts.append("\(tier.rawValue) stress") } else { parts.append("no data") }
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
    .background(Color.Wellness.adaptiveBackground)
}
