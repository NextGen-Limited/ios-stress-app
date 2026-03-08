import SwiftUI

/// Day and date header view for dashboard with settings icon
/// Matches Figma design: 28px bold day, 14px date, gear icon on right
struct DateHeaderView: View {
    private let date: Date
    var onSettingsTapped: (() -> Void)?

    init(date: Date = Date(), onSettingsTapped: (() -> Void)? = nil) {
        self.date = date
        self.onSettingsTapped = onSettingsTapped
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(fullDate)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }

            Spacer()

            Button(action: {
                onSettingsTapped?()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 23))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            .accessibilityLabel("Settings")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayName), \(fullDate). Settings button")
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
