import Foundation

/// Per-user calibrated factor weights for multi-factor stress scoring.
/// Stored in PersonalBaseline; falls back to defaults when uncalibrated.
struct FactorWeights: Codable, Sendable {
    var hrv: Double
    var heartRate: Double
    var sleep: Double
    var activity: Double
    var recovery: Double

    static let defaults = FactorWeights(
        hrv: 0.40, heartRate: 0.15, sleep: 0.20, activity: 0.15, recovery: 0.10
    )

    var total: Double { hrv + heartRate + sleep + activity + recovery }
}
