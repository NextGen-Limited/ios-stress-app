import SwiftUI

/// Premium upgrade card for Settings screen
struct PremiumCard: View {
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
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
                            .tracking(-0.27)
                            .foregroundColor(.premiumGold)

                        Text("Unlock advanced features")
                            .font(.system(size: 13, weight: .regular))
                            .tracking(-0.195)
                            .foregroundColor(.textDescriptive)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.premiumGold)
                }
                .padding(.horizontal, 5)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Premium. Unlock advanced features.")
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}
