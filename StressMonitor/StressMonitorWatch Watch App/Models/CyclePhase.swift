import Foundation

// MARK: - CyclePhase

/// Four canonical menstrual cycle phases aligned to a typical 28-day
/// reference cycle. Day ranges are approximate and used only for
/// predictive UI; actual logged data overrides them.
enum CyclePhase: String, CaseIterable, Codable, Sendable {
    case menstrual
    case follicular
    case ovulation
    case luteal

    /// Capitalised display name.
    var displayName: String {
        switch self {
        case .menstrual:  return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation:  return "Ovulation"
        case .luteal:     return "Luteal"
        }
    }

    /// SF Symbol used as the phase icon.
    var icon: String {
        switch self {
        case .menstrual:  return "drop.fill"
        case .follicular: return "leaf.fill"
        case .ovulation:  return "sparkle"
        case .luteal:     return "moon.fill"
        }
    }

    /// Short, plain-language note on how this phase tends to affect stress.
    var stressCorrelation: String {
        switch self {
        case .menstrual:
            return "Lower energy and mood dips can amplify perceived stress."
        case .follicular:
            return "Rising estrogen typically supports resilience and focus."
        case .ovulation:
            return "Peak energy may buffer stress; motivation tends to climb."
        case .luteal:
            return "PMS window: stress sensitivity often increases."
        }
    }

    /// Approximate day range within a 28-day reference cycle (1-indexed).
    var dayRange: ClosedRange<Int> {
        switch self {
        case .menstrual:  return 1...5
        case .follicular: return 6...13
        case .ovulation:  return 14...16
        case .luteal:     return 17...28
        }
    }

    /// Resolve a phase for a 1-indexed day-of-cycle using the reference ranges.
    static func phase(forDay day: Int) -> CyclePhase {
        switch day {
        case CyclePhase.menstrual.dayRange:  return .menstrual
        case CyclePhase.follicular.dayRange: return .follicular
        case CyclePhase.ovulation.dayRange:  return .ovulation
        default:                              return .luteal
        }
    }
}

// MARK: - CycleData

/// Snapshot of the user's current cycle state.
struct CycleData: Sendable {
    let currentPhase: CyclePhase
    let dayOfCycle: Int
    let cycleLength: Int
    let nextPrediction: Date?
}
