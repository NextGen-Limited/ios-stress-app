import SwiftUI

/// Stress Dots Calendar — horizontal week strip with colored stress-tier dots.
///
/// Each day gets a colored dot indicating stress tier.
/// Selected day = blue gradient background.
/// Today = dashed border.
/// Uses Ripple blue accent (#4FC3F7) instead of teal.
struct HorizontalWeekCalendarView: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)?
    /// Optional day → tier mapping for stress dots.
    var dailyTiers: [Date: StressTier] = [:]

    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current

    private var weekStartDate: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToFriday = (weekday >= 6) ? (weekday - 6) : (weekday - 6 + 7)
        let friday = calendar.date(byAdding: .day, value: -daysToFriday, to: today) ?? today
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: friday) ?? friday
    }

    private var weekDates: [Date] {
        (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)
        }
    }

    private var isCurrentWeek: Bool {
        weekOffset == 0
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 13) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        tier: tierFor(date)
                    )
                    .onTapGesture {
                        selectDate(date)
                    }
                }
            }

            if !isCurrentWeek {
                Button(action: goToToday) {
                    Text("Jump to today")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(TrendsPalette.rippleBlue)
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 16)
    }

    private func tierFor(_ date: Date) -> StressTier? {
        let key = calendar.startOfDay(for: date)
        return dailyTiers[key]
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.25)) {
            weekOffset = 0
            selectedDate = calendar.startOfDay(for: Date())
            onDateSelected?(selectedDate)
        }
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        onDateSelected?(date)
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    var tier: StressTier?

    private let calendar = Calendar.current

    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }

    private var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.9))

            // Day abbreviation
            Text(dayAbbreviation)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))

            // Stress tier dot
            Circle()
                .fill(tier?.color ?? .clear)
                .frame(width: 6, height: 6)
        }
        .frame(width: 38, height: 50)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [TrendsPalette.rippleBlue, TrendsPalette.rippleBlue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                }
            }
        )
        .overlay(
            Group {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
                        .foregroundColor(TrendsPalette.rippleBlue)
                }
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

struct HorizontalWeekCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalWeekCalendarView(
            selectedDate: .constant(Date()),
            dailyTiers: [
                Calendar.current.startOfDay(for: Date()): .good,
                Calendar.current.date(byAdding: .day, value: -1, to: Date())!: .stressed
            ]
        )
        .padding()
        .background(TrendsPalette.darkCanvas)
    }
}
