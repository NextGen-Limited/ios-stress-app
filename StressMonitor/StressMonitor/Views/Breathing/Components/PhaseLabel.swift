import SwiftUI

/// Large phase title ("INHALE") with a seconds countdown ("4s").
///
/// Designed for the active breathing session — uses SF Pro Rounded at title scale
/// with the phase's accent color.
struct PhaseLabel: View {
    let phase: BoxBreathingPhase
    var secondsRemaining: Int
    var tint: Color = HomeCharacterDesignTokens.Ripple.primary

    var body: some View {
        VStack(spacing: 4) {
            Text(phase.label.uppercased())
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(tint)
                .contentTransition(.opacity)

            Text("\(secondsRemaining)s")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.label), \(secondsRemaining) seconds remaining")
    }
}

#Preview {
    VStack(spacing: 24) {
        PhaseLabel(phase: .inhale, secondsRemaining: 4)
        PhaseLabel(phase: .exhale, secondsRemaining: 2, tint: HomeCharacterDesignTokens.Blossom.accent)
    }
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}
