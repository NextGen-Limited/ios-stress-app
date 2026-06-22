import SwiftUI

/// Hero showing the Ripple character's transformation from stressed (worried)
/// to calm (serene). Demonstrates the paywall's core promise visually using
/// the procedural SwiftUI character views — no countdown timer (HIG-compliant).
struct RippleTransformationHero: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                transformationStage(mood: .worried, label: "Stressed")

                // Arrow indicating the transformation
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.iapHeaderTeal)
                    .accessibilityHidden(true)

                transformationStage(mood: .serene, label: "Calm")
            }
            .frame(maxWidth: .infinity)

            Text("From frazzled to focused — in 2 minutes.")
                .font(Typography.iapHeroSubtitle)
                .foregroundStyle(Color.iapTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    HomeCharacterDesignTokens.Ripple.light.opacity(0.22),
                    Color.iapCardBackground.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.iapHeaderTeal.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ripple transforms from stressed to calm in two minutes.")
    }

    private func transformationStage(mood: RippleMood, label: String) -> some View {
        VStack(spacing: 6) {
            RippleCharacterView(mood: mood, size: 96)
            Text(label)
                .font(Typography.iapPillLabel)
                .foregroundStyle(Color.iapTextSecondary)
        }
    }
}

#Preview {
    RippleTransformationHero()
        .padding()
        .background(Color.iapWarmBackground)
}
