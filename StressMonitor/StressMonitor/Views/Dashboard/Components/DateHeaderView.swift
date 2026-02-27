import SwiftUI

/// Day and date header view for dashboard
struct DateHeaderView: View {
    private let calendar = Calendar.current
    private let date: Date

    init(date: Date = Date()) {
        self.date = date
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color.Wellness.adaptivePrimaryText)

            Text(fullDate)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color.Wellness.adaptivePrimaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayName), \(fullDate)")
    }
}

#Preview("DateHeaderView") {
    VStack {
        DateHeaderView()
        Spacer()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
