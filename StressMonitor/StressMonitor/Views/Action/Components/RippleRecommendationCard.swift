import SwiftUI

/// Hero recommendation card for the Action tab — matches `05-action.html` §2.
///
/// Editorial type-led layout: Ripple 84px character + voice line with inline
/// accent highlight + inline CTA pill. Ripple-blue tint border ties the card
/// to the active companion.
struct RippleRecommendationCard: View {
    let stressLevel: Double?
    var ctaTitle: String = "Start Box Breath"
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Eyebrow: "Ripple · your companion" + status dot
            HStack {
                Text("Ripple")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.08)
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                + Text(" · your companion")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .tracking(0.08)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                Spacer(minLength: 0)

                Circle()
                    .fill(Color(hex: "#34C759"))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color(hex: "#34C759").opacity(0.18), radius: 3)
            }
            .textCase(.uppercase)

            // Grid: Ripple 84px + voice + CTA
            HStack(alignment: .center, spacing: 14) {
                RippleCharacterView(mood: RippleMood.from(stressLevel: stressLevel ?? 0), size: 84)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    Text(voiceLine)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)

                    Button {
                        HapticManager.shared.buttonPress()
                        onCTA?()
                    } label: {
                        HStack(spacing: 6) {
                            Text(ctaTitle)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(HomeCharacterDesignTokens.Ripple.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.32), lineWidth: 1)
        )
    }

    /// Voice line matching the HTML editorial style with accent highlight.
    private var voiceLine: AttributedString {
        let level = stressLevel ?? 0
        let hrv = hrvValue(for: level)

        var text = AttributedString("HRV held at ")
        var accent = AttributedString("\(Int(hrv)) ms")
        accent.foregroundColor = HomeCharacterDesignTokens.Ripple.primary
        text += accent

        let suffix = recommendationSuffix(for: level)
        text += AttributedString(suffix)

        return text
    }

    /// Derive a plausible HRV ms from the stress level (inverse).
    private func hrvValue(for level: Double) -> Double {
        // Higher stress → lower HRV. Baseline ~52ms at mild (42).
        max(20, 70 - level * 0.4)
    }

    private func recommendationSuffix(for level: Double) -> String {
        switch level {
        case ..<25:
            return " all morning. You're settled — a slow breath keeps you here."
        case 25..<50:
            return " all morning. A 2-minute Box Breath keeps your parasympathetic tone primed."
        case 50..<75:
            return " this hour. Stress is climbing — let's bring it down with a quick reset."
        default:
            return " right now. High stress detected. Box breathing first, then move."
        }
    }
}

#Preview("RippleRecommendationCard") {
    VStack {
        RippleRecommendationCard(stressLevel: 42)
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
