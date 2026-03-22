import Foundation

enum StressError: Error {
    case noData
}

final class MultiFactorStressCalculator: StressAlgorithmServiceProtocol {

    private let factors: [any StressFactor]
    private let fallback: StressCalculator
    private let calibratedWeights: FactorWeights?

    init(factors: [any StressFactor]? = nil, baseline: PersonalBaseline = PersonalBaseline(),
         calibratedWeights: FactorWeights? = nil) {
        self.factors = factors ?? [
            HRVStressFactor(), HeartRateStressFactor(), SleepStressFactor(),
            ActivityStressFactor(), RecoveryStressFactor()
        ]
        self.fallback = StressCalculator(baseline: baseline)
        self.calibratedWeights = calibratedWeights ?? baseline.factorWeights
    }

    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        try await fallback.calculateStress(hrv: hrv, heartRate: heartRate)
    }

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int, lastReadingDate: Date?) -> Double {
        fallback.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples, lastReadingDate: lastReadingDate)
    }

    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult {
        var results: [(factor: any StressFactor, result: FactorResult)] = []
        for factor in factors {
            if let result = try await factor.calculate(context: context) {
                results.append((factor, result))
            }
        }
        guard !results.isEmpty else { throw StressError.noData }

        let availableWeight = results.reduce(0.0) { $0 + effectiveWeight(for: $1.factor) }
        let totalWeight = factors.reduce(0.0) { $0 + effectiveWeight(for: $1) }
        let compositeScore = results.reduce(0.0) { $0 + $1.result.value * (effectiveWeight(for: $1.factor) / availableWeight) }

        let level = max(0, min(100, compositeScore * 100))
        let dataCompleteness = availableWeight / totalWeight
        let avgConfidence = results.reduce(0.0) { $0 + $1.result.confidence } / Double(results.count)

        let breakdown = FactorBreakdown(
            hrvComponent: results.first { $0.factor.id == "hrv" }?.result.value,
            hrComponent: results.first { $0.factor.id == "heartRate" }?.result.value,
            sleepComponent: results.first { $0.factor.id == "sleep" }?.result.value,
            activityComponent: results.first { $0.factor.id == "activity" }?.result.value,
            recoveryComponent: results.first { $0.factor.id == "recovery" }?.result.value,
            dataCompleteness: dataCompleteness
        )

        return StressResult(
            level: level, category: StressResult.category(for: level),
            confidence: dataCompleteness * 0.4 + avgConfidence * 0.6,
            hrv: context.hrv ?? 0, heartRate: context.heartRate ?? 0,
            timestamp: context.timestamp, factorBreakdown: breakdown
        )
    }

    private func effectiveWeight(for factor: any StressFactor) -> Double {
        guard let calibratedWeights else { return factor.weight }
        switch factor.id {
        case "hrv": return calibratedWeights.hrv
        case "heartRate": return calibratedWeights.heartRate
        case "sleep": return calibratedWeights.sleep
        case "activity": return calibratedWeights.activity
        case "recovery": return calibratedWeights.recovery
        default: return factor.weight
        }
    }
}

extension MultiFactorStressCalculator: @unchecked Sendable {}
