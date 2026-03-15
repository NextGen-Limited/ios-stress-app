import SwiftUI

/// Horizontal week calendar strip for Home dashboard
/// Figma specs: 358pt width, 51pt height, 13.067pt gap between days
/// Selected: teal (#85c9c9) bg, white text
struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)?

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToSunday = (weekday == 1) ? 0 : (weekday - 1)
        let sunday = calendar.date(byAdding: .day, value: -daysToSunday, to: today) ?? today
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: sunday)
        }
    }

    var body: some View {
        HStack(spacing: 13.067) {
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
        .frame(width: 358, height: 51)
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
            Text(dayNumber)
                .font(.custom("Roboto-Bold", size: 14))
                .foregroundStyle(isSelected ? .white : Color(hex: "101223"))

            Text(dayAbbreviation)
                .font(.custom("Roboto-Medium", size: 12.13))
                .foregroundStyle(isSelected ? .white : Color(hex: "777986"))
        }
        .frame(width: 21.467, height: 32.267)
        .padding(9.333)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentTeal)
                }
            }
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayAbbreviation) \(dayNumber)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("WeekCalendarStrip") {
    @Previewable @State var selectedDate = Date()

    VStack {
        WeekCalendarStrip(selectedDate: $selectedDate)
        Spacer()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
