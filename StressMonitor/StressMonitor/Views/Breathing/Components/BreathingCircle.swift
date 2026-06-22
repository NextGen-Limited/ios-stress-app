import SwiftUI

/// Animated breathing orb with concentric aura arcs.
///
/// The central circle scales 0.6 (exhale) ↔ 1.0 (inhale) with a 4-second ease in/out
/// driven by the supplied `BreathingPhase`. Three outer aura arcs fade outwards and
/// pulse with the same cycle.
///
/// When `accessibilityReduceMotion` is enabled, the orb holds a static 0.8 scale and
/// the aura is rendered without animation so motion-sensitive users still see a
/// calm, stationary guide.
struct BreathingCircle: View {
    let phase: BoxBreathingPhase
    var size: CGFloat = 200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    private var phaseColor: Color {
        switch phase {
        case .inhale:  return HomeCharacterDesignTokens.Ripple.primary
        case .holdIn:  return HomeCharacterDesignTokens.Ripple.mid
        case .exhale:  return HomeCharacterDesignTokens.Blossom.accent
        case .holdOut: return HomeCharacterDesignTokens.Ripple.light
        }
    }

    private var targetScale: CGFloat {
        guard !reduceMotion else { return 0.8 }
        switch phase {
        case .inhale:  return animate ? 1.0 : 0.7
        case .holdIn:  return 1.0
        case .exhale:  return animate ? 0.6 : 0.9
        case .holdOut: return 0.6
        }
    }

    var body: some View {
        ZStack {
            auraArc(radius: size * 0.5, opacity: 0.10)
            auraArc(radius: size * 0.42, opacity: 0.16)
            auraArc(radius: size * 0.34, opacity: 0.22)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [phaseColor.opacity(0.85), phaseColor.opacity(0.45)],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.25
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .overlay(
                    Circle()
                        .stroke(phaseColor.opacity(0.55), lineWidth: 2)
                        .frame(width: size * 0.5, height: size * 0.5)
                )
                .scaleEffect(targetScale)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing guide, \(phase.label)")
        .onAppear { beginCycle() }
        .onChange(of: phase) { beginCycle() }
    }

    private func auraArc(radius: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(phaseColor.opacity(opacity), lineWidth: 2)
            .frame(width: radius * 2, height: radius * 2)
            .scaleEffect(reduceMotion ? 0.9 : (animate ? 1.0 : 0.85))
            .opacity(reduceMotion ? opacity : (animate ? opacity * 0.4 : opacity))
    }

    private func beginCycle() {
        guard !reduceMotion else { return }
        animate = false
        withAnimation(.easeInOut(duration: 4)) {
            animate = true
        }
    }
}

/// Four-phase box-breathing cycle (4-4-4-4).
enum BoxBreathingPhase: String, CaseIterable, Sendable {
    case inhale, holdIn, exhale, holdOut

    var label: String {
        switch self {
        case .inhale:  return "Inhale"
        case .holdIn:  return "Hold"
        case .exhale:  return "Exhale"
        case .holdOut: return "Hold"
        }
    }

    var instruction: String {
        switch self {
        case .inhale:  return "Breathe in through your nose"
        case .holdIn:  return "Gently hold"
        case .exhale:  return "Breathe out through your mouth"
        case .holdOut: return "Hold empty"
        }
    }

    var durationSeconds: Int { 4 }
}

#Preview {
    VStack(spacing: 24) {
        BreathingCircle(phase: .inhale, size: 180)
        BreathingCircle(phase: .exhale, size: 140)
    }
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}
