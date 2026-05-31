import Foundation

struct HeartRateStressFactor: StressFactor {
    let id = "heartRate"
    let weight = 0.15

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let heartRate = context.heartRate else { return nil }
        let resting = context.baseline.restingHeartRate
        guard resting > 0 else { return nil }

        let normalized = (heartRate - resting) / resting
        let clamped = max(0, min(2.0, normalized))
        let value = 1.0 / (1.0 + exp(-3.0 * (clamped - 0.3)))

        return FactorResult(value: value, confidence: 1.0, metadata: ["heartRate": heartRate])
    }
}
