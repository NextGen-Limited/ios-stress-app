import SwiftUI

/// Large SF Pro Rounded phase word (e.g. "INHALE") with a countdown number below.
///
/// Matches the `.breath-instruction` block from `08-breathing-active.html`:
/// white text sitting inside the solid core circle of the breathing arena.
struct PhaseLabel: View {
    let phase: BoxBreathingPhase
    let secondsRemaining: Int
    var tint: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(phase.displayWord)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .tracking(0.04 * 24)
                .foregroundStyle(tint)
            Text("\(secondsRemaining)")
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.displayWord), \(secondsRemaining) seconds remaining")
    }
}

extension BoxBreathingPhase {
    /// Uppercase display word for the breathing arena center.
    var displayWord: String {
        switch self {
        case .inhale:  return "INHALE"
        case .holdIn:  return "HOLD"
        case .exhale:  return "EXHALE"
        case .holdOut: return "HOLD"
        }
    }
}

#Preview("PhaseLabel") {
    HStack(spacing: 32) {
        PhaseLabel(phase: .inhale, secondsRemaining: 3)
        PhaseLabel(phase: .holdIn, secondsRemaining: 2)
        PhaseLabel(phase: .exhale, secondsRemaining: 4)
        PhaseLabel(phase: .holdOut, secondsRemaining: 1)
    }
    .padding(40)
    .background(Color(hex: "#0288D1"))
}
