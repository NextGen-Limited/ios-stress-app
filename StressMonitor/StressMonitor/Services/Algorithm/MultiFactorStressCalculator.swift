import Foundation

// MARK: - MultiFactorStressCalculator

/// Orchestrates all stress factors, normalizes weights across available factors,
/// and produces a composite StressResult with per-factor breakdown.
final class MultiFactorStressCalculator: StressAlgorithmServiceProtocol {

    private let factors: [any StressFactor]
    private let fallback: StressCalculator

    private let calibratedWeights: FactorWeights?

    init(factors: [any StressFactor]? = nil, baseline: PersonalBaseline = PersonalBaseline(),
         calibratedWeights: FactorWeights? = nil) {
        self.factors = factors ?? [
            HRVStressFactor(),
            HeartRateStressFactor(),
            SleepStressFactor(),
            ActivityStressFactor(),
            RecoveryStressFactor()
        ]
        self.fallback = StressCalculator(baseline: baseline)
        self.calibratedWeights = calibratedWeights ?? baseline.factorWeights
    }

    // MARK: - StressAlgorithmServiceProtocol

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

        guard !results.isEmpty else {
            throw StressError.noData
        }

        let available = results.reduce(0.0) { $0 + effectiveWeight(for: $1.factor) }
        let totalWeight = factors.reduce(0.0) { $0 + effectiveWeight(for: $1) }

        // Weighted combination with normalized weights
        let compositeScore = results.reduce(0.0) { sum, item in
            sum + item.result.value * (effectiveWeight(for: item.factor) / available)
        }

        let level = max(0, min(100, compositeScore * 100))
        let category = StressResult.category(for: level)

        let dataCompleteness = available / totalWeight
        let avgConfidence = results.reduce(0.0) { $0 + $1.result.confidence } / Double(results.count)
        let confidence = dataCompleteness * 0.4 + avgConfidence * 0.6

        let breakdown = FactorBreakdown(
            hrvComponent: results.first { $0.factor.id == "hrv" }?.result.value,
            hrComponent: results.first { $0.factor.id == "heartRate" }?.result.value,
            sleepComponent: results.first { $0.factor.id == "sleep" }?.result.value,
            activityComponent: results.first { $0.factor.id == "activity" }?.result.value,
            recoveryComponent: results.first { $0.factor.id == "recovery" }?.result.value,
            dataCompleteness: dataCompleteness
        )

        return StressResult(
            level: level,
            category: category,
            confidence: confidence,
            hrv: context.hrv ?? 0,
            heartRate: context.heartRate ?? 0,
            timestamp: context.timestamp,
            factorBreakdown: breakdown
        )
    }
    // MARK: - Private

    private func effectiveWeight(for factor: any StressFactor) -> Double {
        guard let weights = calibratedWeights else { return factor.weight }
        switch factor.id {
        case "hrv": return weights.hrv
        case "heartRate": return weights.heartRate
        case "sleep": return weights.sleep
        case "activity": return weights.activity
        case "recovery": return weights.recovery
        default: return factor.weight
        }
    }
}

extension MultiFactorStressCalculator: @unchecked Sendable {}
