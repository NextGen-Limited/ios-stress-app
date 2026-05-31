import Foundation

// MARK: - Main Stress Calculator
/// Combines HRV (70%) and heart rate (30%) via sigmoid transforms.
///
/// Note: Apple HealthKit provides SDNN-based HRV (.heartRateVariabilitySDNN), not RMSSD.
/// SDNN runs slightly higher than RMSSD but remains a reliable relative stress indicator
/// when normalized against a personal baseline. Baseline normalization compensates for
/// the SDNN/RMSSD difference at the individual level.
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

        // 70% HRV, 30% HR
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

        // Gradual HRV penalty (hrv<20ms → proportional reduction, min 0.3)
        if hrv < 20 {
            confidence *= max(0.3, hrv / 20.0)
        }

        // Gradual extreme HR penalty (outside 50-160 bpm range)
        if heartRate < 50 || heartRate > 160 {
            let deviation = heartRate < 50 ? (50 - heartRate) / 50 : (heartRate - 160) / 160
            confidence *= max(0.4, 1.0 - deviation)
        }

        // Sample count factor: 10+ samples → max confidence
        let sampleFactor = min(1.0, Double(samples) / 10.0)
        confidence *= (0.7 + sampleFactor * 0.3)

        // Recency: confidence decays linearly for stale data (120 min → 0.3x)
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
        // Extract ALL data from baseline FIRST to avoid actor boundary issues
        // with Dictionary (reference type with COW) inside PersonalBaseline
        // This matches the pattern in HRVStressFactor.calculate()
        let baselineHRV = self.baseline.baselineHRV
        let hourlyBaseline = self.baseline.hourlyHRVBaseline  // Local copy before any cross-actor call
        let adjustment = baselineCalculator.circadianAdjustment(
            for: hour,
            userHourlyBaseline: hourlyBaseline,
            globalBaseline: baselineHRV
        )
        let adjustedBaseline = max(1, baseline * adjustment)
        return (adjustedBaseline - hrv) / adjustedBaseline
    }

    private func normalizeHeartRate(_ heartRate: Double, resting: Double) -> Double {
        guard resting > 0 else { return 0 }
        return (heartRate - resting) / resting
    }

    /// Sigmoid: S-curve mapping input to [0,1]. k=steepness, x0=midpoint.
    private func sigmoid(_ x: Double, k: Double, x0: Double) -> Double {
        1.0 / (1.0 + exp(-k * (x - x0)))
    }

    /// Replaces pow(normalizedHRV, 0.8) — steepness 4, midpoint 0.5
    private func calculateHRVComponent(_ normalizedHRV: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHRV))
        return sigmoid(clamped, k: 4.0, x0: 0.5)
    }

    /// Replaces atan(normalizedHR * 2) / (π/2) — lower midpoint (0.3) since small elevation matters
    private func calculateHRComponent(_ normalizedHR: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHR))
        return sigmoid(clamped, k: 3.0, x0: 0.3)
    }
}

// MARK: - Thread Safety
// Safe Sendable: all stored properties are `let` (immutable)
// - baseline: PersonalBaseline is Sendable struct
// - baselineCalculator: BaselineCalculator is Sendable class
extension StressCalculator: Sendable {}
