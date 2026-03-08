import SwiftUI

/// Horizontal week calendar for date selection in Trends view
/// Figma: 7-day horizontal strip with day numbers above abbreviations
/// States: Selected (teal bg), Today (dashed border), Default
struct HorizontalWeekCalendarView: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)?

    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current

    private var weekStartDate: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Friday is weekday 6 in Gregorian calendar
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
            // Horizontal week days - 7 days starting from Friday
            HStack(spacing: 13) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        selectDate(date)
                    }
                }
            }

            // "Jump to today" link
            if !isCurrentWeek {
                Button(action: goToToday) {
                    Text("Jump to today")
                        .font(.custom("Lato-Bold", size: 13))
                        .foregroundColor(.accentTeal)
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 16)
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
        VStack(spacing: 2.8) {
            // Day number
            Text(dayNumber)
                .font(.custom("Lato-Bold", size: 14))
                .foregroundColor(isSelected ? .white : Color(hex: "101223"))

            // Day abbreviation
            Text(dayAbbreviation)
                .font(.custom("Lato-Regular", size: 12.13))
                .foregroundColor(isSelected ? .white : Color(hex: "777986"))
        }
        .frame(width: 21.47, height: 32.27)
        .padding(9.33)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentTeal)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                        )
                        .foregroundColor(Color.accentTeal)
                }
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("HorizontalWeekCalendarView") {
    @Previewable @State var selectedDate = Date()

    HorizontalWeekCalendarView(selectedDate: $selectedDate)
        .padding()
        .background(Color.backgroundLight)
}
