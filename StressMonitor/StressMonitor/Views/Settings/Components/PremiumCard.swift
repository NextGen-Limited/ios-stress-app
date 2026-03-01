import SwiftUI

/// Premium upgrade card for Settings screen
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
                    Text("Premium")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.premiumGold)

                    Text("Upgrade to unlock all features")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textDescriptive)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Premium upgrade. Unlock all features.")
        }
    }
}

#Preview {
    PremiumCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}
