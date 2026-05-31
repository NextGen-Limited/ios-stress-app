import Foundation

// MARK: - Main Stress Calculator (watchOS)
/// Mirrors iPhone StressCalculator — sigmoid-based HRV (70%) + HR (30%) algorithm.
///
/// Note: Apple HealthKit provides SDNN-based HRV (.heartRateVariabilitySDNN), not RMSSD.
/// Baseline normalization compensates for the SDNN/RMSSD difference at the individual level.
final class StressCalculator: StressAlgorithmServiceProtocol {

    private let baseline: PersonalBaseline
    private let baselineCalculator = BaselineCalculator()

    init(baseline: PersonalBaseline = PersonalBaseline()) {
        self.baseline = baseline
    }

    // MARK: - StressAlgorithmServiceProtocol

    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        let normalizedHRV = normalizeHRV(hrv, baseline: baseline.baselineHRV)
        let normalizedHR = normalizeHeartRate(heartRate, resting: baseline.restingHeartRate)

        let hrvComponent = calculateHRVComponent(normalizedHRV)
        let hrComponent = calculateHRComponent(normalizedHR)

        let stressLevel = (hrvComponent * 0.7) + (hrComponent * 0.3)
        let clampedLevel = max(0, min(100, stressLevel * 100))
        let category = StressResult.category(for: clampedLevel)
        let confidence = calculateConfidence(hrv: hrv, heartRate: heartRate, samples: 1, lastReadingDate: nil)

        return StressResult(
            level: clampedLevel,
            category: category,
            confidence: confidence,
            hrv: hrv,
            heartRate: heartRate,
            timestamp: Date()
        )
    }

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int, lastReadingDate: Date?) -> Double {
        var confidence = 1.0

        if hrv < 20 {
            confidence *= max(0.3, hrv / 20.0)
        }

        if heartRate < 50 || heartRate > 160 {
            let deviation = heartRate < 50 ? (50 - heartRate) / 50 : (heartRate - 160) / 160
            confidence *= max(0.4, 1.0 - deviation)
        }

        let sampleFactor = min(1.0, Double(samples) / 10.0)
        confidence *= (0.7 + sampleFactor * 0.3)

        if let lastDate = lastReadingDate {
            let minutesAgo = Date().timeIntervalSince(lastDate) / 60.0
            let recencyFactor = max(0.3, 1.0 - (minutesAgo / 120.0))
            confidence *= recencyFactor
        }

        return max(0.0, min(1.0, confidence))
    }

    // MARK: - Private Helpers

    private func normalizeHRV(_ hrv: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        let hour = Calendar.current.component(.hour, from: Date())
        let adjustment = baselineCalculator.circadianAdjustment(
            for: hour,
            userHourlyBaseline: self.baseline.hourlyHRVBaseline,
            globalBaseline: baseline
        )
        let adjustedBaseline = max(1, baseline * adjustment)
        return (adjustedBaseline - hrv) / adjustedBaseline
    }

    private func normalizeHeartRate(_ heartRate: Double, resting: Double) -> Double {
        guard resting > 0 else { return 0 }
        return (heartRate - resting) / resting
    }

    private func sigmoid(_ x: Double, k: Double, x0: Double) -> Double {
        1.0 / (1.0 + exp(-k * (x - x0)))
    }

    private func calculateHRVComponent(_ normalizedHRV: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHRV))
        return sigmoid(clamped, k: 4.0, x0: 0.5)
    }

    private func calculateHRComponent(_ normalizedHR: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHR))
        return sigmoid(clamped, k: 3.0, x0: 0.3)
    }
}

extension StressCalculator: @unchecked Sendable {}
