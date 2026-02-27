import SwiftUI

/// Day and date header view for dashboard
/// Matches Figma design: 28px bold day, 14px bold date
struct DateHeaderView: View {
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
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text(fullDate)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
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
