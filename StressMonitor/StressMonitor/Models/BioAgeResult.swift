import Foundation

// MARK: - BioAgeResult

/// Estimated biological age derived from HRV (RMSSD/SDNN), resting heart rate,
/// and sleep quality. Lower than chronological age = healthier physiological state.
struct BioAgeResult: Identifiable, Codable, Sendable {
    let id: UUID
    /// Estimated biological age in years
    let estimatedAge: Int
    /// User's actual chronological age in years
    let chronologicalAge: Int
    /// estimatedAge - chronologicalAge. Negative = biologically younger (better)
    let difference: Int
    /// Direction of change from previous calculation
    let trend: BioAgeTrend
    /// Relative confidence in the estimate (0–1)
    let confidence: Double

    init(
        estimatedAge: Int,
        chronologicalAge: Int,
        trend: BioAgeTrend = .stable,
        confidence: Double = 0.5
    ) {
        self.id = UUID()
        self.estimatedAge = estimatedAge
        self.chronologicalAge = chronologicalAge
        self.difference = estimatedAge - chronologicalAge
        self.trend = trend
        self.confidence = confidence
    }
}

// MARK: - BioAgeTrend

enum BioAgeTrend: String, Codable, Sendable, CaseIterable {
    case improving
    case declining
    case stable

    var label: String {
        switch self {
        case .improving: return "Getting younger"
        case .declining: return "Aging faster"
        case .stable: return "Holding steady"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right.circle.fill"
        case .declining: return "arrow.up.right.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
}

// MARK: - Character Expression

extension BioAgeResult {

    /// Character-based expression for the bio age — never shows raw sub-scores.
    /// Celebratory when biologically younger, encouraging when older.
    var characterExpression: String {
        switch difference {
        case ...(-10):
            return "Your body feels a decade younger! Incredible vitality."
        case -9 ... -5:
            return "Your body is thriving — years younger than your passport says."
        case -4 ... -1:
            return "You're aging beautifully — a touch younger than your years."
        case 0:
            return "Your body matches your years — balanced and steady."
        case 1 ... 4:
            return "A little wear showing — small habits can turn this around."
        case 5 ... 9:
            return "Your body feels a few years older — recovery will help."
        default:
            return "Time to prioritize recovery — your body needs care."
        }
    }

    /// Short label for the difference (e.g. "5 years younger")
    var differenceLabel: String {
        let abs = abs(difference)
        let unit = abs == 1 ? "year" : "years"
        if difference < 0 {
            return "\(abs) \(unit) younger"
        } else if difference > 0 {
            return "\(abs) \(unit) older"
        }
        return "On par"
    }

    /// Whether the result is worth celebrating
    var isCelebratory: Bool {
        difference < -2
    }
}
