import SwiftUI

/// Active-companion banner showing the currently selected Ripple character with a "Switch" link
/// to the character collection.
struct CompanionBanner: View {
    var companionName: String
    var companionSubtitle: String
    var mood: RippleMood = .serene
    var onSwitch: (() -> Void)? = nil

    var body: some View {
        SettingsCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HomeCharacterDesignTokens.Ripple.primary.opacity(0.14))
                    StressBuddyIllustration(mood: mood, size: 44)
                }
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("ACTIVE COMPANION")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                    HStack(spacing: 6) {
                        Text(companionName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                        if !companionSubtitle.isEmpty {
                            Text("· \(companionSubtitle)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        }
                    }
                }

                Spacer(minLength: 8)

                Button {
                    HapticManager.shared.buttonPress()
                    onSwitch?()
                } label: {
                    Text("Switch")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                }
                .accessibilityLabel("Switch active companion")
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    CompanionBanner(companionName: "Ripple", companionSubtitle: "Water Otter")
        .padding()
        .background(Color.appBackground)
}
