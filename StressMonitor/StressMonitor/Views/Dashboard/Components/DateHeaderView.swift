import SwiftUI

/// Day and date header view for the Home tab.
/// Settings is reachable from the dedicated Settings tab, so the header
/// no longer renders an in-card gear button.
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("StressMonitor")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(dayName)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(fullDate)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("StressMonitor. \(dayName), \(fullDate).")
    }
}

#Preview("DateHeaderView") {
    VStack {
        DateHeaderView()
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
