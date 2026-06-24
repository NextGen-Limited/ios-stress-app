import SwiftUI

/// Animated breathing arena with three concentric rings matching the
/// `.breath-arena` from `08-breathing-active.html`.
///
/// - r1: outer aura (100% width, radial gradient, scale 0.85 ↔ 1.05)
/// - r2: mid aura (70% width, radial gradient, scale 0.85 ↔ 1.10)
/// - r3: solid core (42% width, linear gradient #4FC3F7 → #0288D1, scale 0.85 ↔ 1.15)
///
/// All rings scale over a 4-second easeInOut per phase, synced to the
/// 4-4-4-4 box-breathing cycle. When `accessibilityReduceMotion` is enabled,
/// the rings hold static mid-scale positions and no animation runs.
struct BreathingCircle: View {
    let phase: BoxBreathingPhase
    var size: CGFloat = 280

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    // Design tokens from HTML
    private let auraColor = Color(hex: "#4FC3F7")
    private let coreGradientTop = Color(hex: "#4FC3F7")
    private let coreGradientBottom = Color(hex: "#0288D1")

    /// Target scale for the core (r3) per phase — 0.85 (contracted) ↔ 1.15 (expanded)
    private var coreScale: CGFloat {
        guard !reduceMotion else { return 0.95 }
        switch phase {
        case .inhale:  return animate ? 1.15 : 0.85
        case .holdIn:  return 1.15
        case .exhale:  return animate ? 0.85 : 1.15
        case .holdOut: return 0.85
        }
    }

    /// Target scale for mid aura (r2)
    private var midScale: CGFloat {
        guard !reduceMotion else { return 0.95 }
        switch phase {
        case .inhale:  return animate ? 1.10 : 0.85
        case .holdIn:  return 1.10
        case .exhale:  return animate ? 0.85 : 1.10
        case .holdOut: return 0.85
        }
    }

    /// Target scale for outer aura (r1)
    private var outerScale: CGFloat {
        guard !reduceMotion else { return 0.95 }
        switch phase {
        case .inhale:  return animate ? 1.05 : 0.85
        case .holdIn:  return 1.05
        case .exhale:  return animate ? 0.85 : 1.05
        case .holdOut: return 0.85
        }
    }

    var body: some View {
        ZStack {
            // r1 — outer aura (100% width, radial gradient)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [auraColor.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(outerScale)

            // r2 — mid aura (70% width)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [auraColor.opacity(0.30), Color.clear],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.35
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .scaleEffect(midScale)

            // r3 — solid core (42% width, linear gradient, shadow)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [coreGradientTop, coreGradientBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.42, height: size * 0.42)
                .shadow(color: auraColor.opacity(0.5), radius: 25, x: 0, y: 10)
                .scaleEffect(coreScale)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing guide, \(phase.label)")
        .onAppear { beginCycle() }
        .onChange(of: phase) { _, _ in beginCycle() }
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
        BreathingCircle(phase: .inhale, size: 280)
        BreathingCircle(phase: .exhale, size: 200)
    }
    .padding()
    .background(Color(hex: "#ECF8FE"))
}
