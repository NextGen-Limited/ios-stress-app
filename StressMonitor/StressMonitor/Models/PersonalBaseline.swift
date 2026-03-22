import Foundation

struct PersonalBaseline: Codable, Sendable {
    var restingHeartRate: Double
    var baselineHRV: Double
    var lastUpdated: Date

    // MARK: - Phase 5: Per-user calibration (optional — backward compatible)
    var factorWeights: FactorWeights?
    var hourlyHRVBaseline: [Int: Double]?
    var calibrationDate: Date?

    init(restingHeartRate: Double = 60.0, baselineHRV: Double = 50.0, lastUpdated: Date = Date()) {
        self.restingHeartRate = restingHeartRate
        self.baselineHRV = baselineHRV
        self.lastUpdated = lastUpdated
    }
}
