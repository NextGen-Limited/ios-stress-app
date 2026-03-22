import Foundation

// MARK: - HeartRateStressFactor

/// Heart rate stress factor (weight: 0.15).
/// Uses sigmoid normalization with lower midpoint (0.3) — small HR elevations matter more.
/// Returns nil if heart rate is unavailable in context.
struct HeartRateStressFactor: StressFactor {
    let id = "heartRate"
    let weight = 0.15

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let heartRate = context.heartRate else { return nil }

        let resting = context.baseline.restingHeartRate
        guard resting > 0 else { return nil }

        let normalized = (heartRate - resting) / resting
        let clamped = max(0, min(2.0, normalized))
        let value = sigmoid(clamped, k: 3.0, x0: 0.3)

        let confidence = calculateConfidence(heartRate: heartRate)

        return FactorResult(
            value: value,
            confidence: confidence,
            metadata: ["heartRate": heartRate, "restingHR": resting, "normalized": normalized]
        )
    }

    private func sigmoid(_ x: Double, k: Double, x0: Double) -> Double {
        1.0 / (1.0 + exp(-k * (x - x0)))
    }

    private func calculateConfidence(heartRate: Double) -> Double {
        guard heartRate < 50 || heartRate > 160 else { return 1.0 }
        let deviation = heartRate < 50 ? (50 - heartRate) / 50 : (heartRate - 160) / 160
        return max(0.4, 1.0 - deviation)
    }
}
