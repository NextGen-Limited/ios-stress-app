import Foundation

/// Describes which factors contributed to the current stress calculation
/// and the overall reliability of the composite score.
struct DataQualityInfo: Sendable {
    let activeFactors: [String]
    let missingFactors: [String]
    let dataCompleteness: Double
    let isCalibrated: Bool
    let lastCalibrationDate: Date?

    var qualityLevel: QualityLevel {
        switch dataCompleteness {
        case 0.8...1.0: return .excellent
        case 0.5..<0.8: return .good
        case 0.3..<0.5: return .limited
        default: return .minimal
        }
    }

    enum QualityLevel: String {
        case excellent
        case good
        case limited
        case minimal
    }
}

extension DataQualityInfo {
    init(from breakdown: FactorBreakdown, baseline: PersonalBaseline) {
        var active: [String] = []
        var missing: [String] = []

        let factorMap: [(id: String, value: Double?)] = [
            ("hrv", breakdown.hrvComponent),
            ("heartRate", breakdown.hrComponent),
            ("sleep", breakdown.sleepComponent),
            ("activity", breakdown.activityComponent),
            ("recovery", breakdown.recoveryComponent)
        ]

        for (id, value) in factorMap {
            if value != nil { active.append(id) } else { missing.append(id) }
        }

        self.init(
            activeFactors: active,
            missingFactors: missing,
            dataCompleteness: breakdown.dataCompleteness,
            isCalibrated: baseline.calibrationDate != nil,
            lastCalibrationDate: baseline.calibrationDate
        )
    }
}
