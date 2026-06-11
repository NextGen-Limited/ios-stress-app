import SwiftUI

/// Day and date header view for dashboard with settings icon.
/// Redesigned for Home tab to match Ripple concept styling.
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

            Button(action: {
                onSettingsTapped?()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                    .frame(width: 42, height: 42)
                    .background(HomeCharacterDesignTokens.Ripple.light.opacity(0.42), in: Circle())
                    .overlay(Circle().stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.24), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("StressMonitor. \(dayName), \(fullDate). Settings button")
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
