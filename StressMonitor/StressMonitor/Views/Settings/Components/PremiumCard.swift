import SwiftUI

/// Widget setup card for Settings screen
struct PremiumCard: View {
    var body: some View {
        SettingsCard {
            HStack(spacing: 23) {
                Image("premium-star")
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set widget now!")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(-0.27)
                        .foregroundColor(.premiumGold)

                    Text("Widgets that nudge you with insights")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(-0.195)
                        .foregroundColor(.textDescriptive)
                }

                Spacer()
            }
            .padding(.horizontal, 5)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Set widget now. Widgets that nudge you with insights.")
        }
    }
}

#Preview {
    PremiumCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}
