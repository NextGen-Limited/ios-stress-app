import SwiftUI

/// Hero recommendation card for the Action tab.
///
/// Shows a focused Ripple character plus a one-line recommendation derived from
/// the user's current stress level, with an inline CTA (default: Box Breathing)
/// ringed in the Ripple accent tint.
struct RippleRecommendationCard: View {
    let stressLevel: Double?
    var ctaTitle: String = "Try Box Breathing"
    var onCTA: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RippleCharacterView(mood: RippleMood.from(stressLevel: stressLevel ?? 0), size: 84)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Button {
                    HapticManager.shared.buttonPress()
                    onCTA?()
                } label: {
                    Text(ctaTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: HomeCharacterDesignTokens.Ripple.deep.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    /// Maps a stress level to a short, actionable recommendation line.
    private var recommendation: String {
        let level = stressLevel ?? 0
        switch level {
        case 0..<25:
            return "You're settled. A slow breath keeps you here."
        case 25..<50:
            return "Mild tension rising — a 2-minute reset helps."
        case 50..<75:
            return "Stress is climbing. Let's bring it down now."
        case 75...:
            return "High stress detected. Box breathing first, then move."
        default:
            return "Check in with a breath whenever you're ready."
        }
    }
}

#Preview("RippleRecommendationCard") {
    VStack {
        RippleRecommendationCard(stressLevel: 62)
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
