import Foundation

// MARK: - HRVStressFactor

/// HRV-based stress factor (weight: 0.40).
/// Uses sigmoid normalization against personal baseline.
/// Returns nil if HRV is unavailable in context.
struct HRVStressFactor: StressFactor {
    let id = "hrv"
    let weight = 0.40

    private let baselineCalculator = BaselineCalculator()

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let hrv = context.hrv else { return nil }

        let baseline = context.baseline.baselineHRV
        guard baseline > 0 else { return nil }

        let hour = Calendar.current.component(.hour, from: context.timestamp)
        let adjustment = baselineCalculator.circadianAdjustment(
            for: hour,
            userHourlyBaseline: context.baseline.hourlyHRVBaseline,
            globalBaseline: baseline
        )
        let adjustedBaseline = max(1, baseline * adjustment)
        let normalized = (adjustedBaseline - hrv) / adjustedBaseline
        let clamped = max(0, min(2.0, normalized))
        let value = sigmoid(clamped, k: 4.0, x0: 0.5)

        let confidence = calculateConfidence(hrv: hrv, lastReadingDate: context.lastReadingDate)

        return FactorResult(
            value: value,
            confidence: confidence,
            metadata: [
                "hrv": hrv,
                "baseline": baseline,
                "adjustedBaseline": adjustedBaseline,
                "normalized": normalized
            ]
        )
    }

    private func sigmoid(_ x: Double, k: Double, x0: Double) -> Double {
        1.0 / (1.0 + exp(-k * (x - x0)))
    }

    private func calculateConfidence(hrv: Double, lastReadingDate: Date?) -> Double {
        var confidence = 1.0

        if hrv < 20 {
            confidence *= max(0.3, hrv / 20.0)
        }

        if let lastDate = lastReadingDate {
            let minutesAgo = Date().timeIntervalSince(lastDate) / 60.0
            confidence *= max(0.3, 1.0 - (minutesAgo / 120.0))
        }

        return max(0.0, min(1.0, confidence))
    }
}
