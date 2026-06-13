import SwiftUI

/// Ripple Speech Bubble — replaces the old cat mascot.
///
/// Shows the Ripple character with a dynamic message based on the stress trend:
/// lower stress this week → positive message; higher → gentle nudge.
/// Glass card style on the dark canvas.
struct MascotSpeechBubbleView: View {
    let message: String
    var tier: StressTier = .good
    var size: CGFloat = 52

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Ripple character face
            RippleMoodFace(tier: tier, size: size, glow: true)

            VStack(alignment: .leading, spacing: 0) {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                Text("— Ripple")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(TrendsPalette.rippleBlue)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TrendsPalette.darkCard.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(TrendsPalette.darkCard.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Dynamic message helper

extension MascotSpeechBubbleView {
    /// Builds a conversational message based on whether stress improved or worsened.
    static func message(stressTrendingDown: Bool, hasData: Bool) -> String {
        guard hasData else {
            return "Hi! I'm Ripple 💧 Keep checking in and I'll show you how your week is going."
        }
        if stressTrendingDown {
            return "Your stress is easing this week — Ripple is floating peacefully. Keep it up! 💙"
        } else {
            return "Things feel a bit heavier lately. A few deep breaths could help Ripple calm down. 🌊"
        }
    }
}

// MARK: - Preview

struct MascotSpeechBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            MascotSpeechBubbleView(
                message: MascotSpeechBubbleView.message(stressTrendingDown: true, hasData: true),
                tier: .good
            )
            MascotSpeechBubbleView(
                message: MascotSpeechBubbleView.message(stressTrendingDown: false, hasData: true),
                tier: .stressed
            )
        }
        .padding()
        .background(TrendsPalette.darkCanvas)
    }
}
