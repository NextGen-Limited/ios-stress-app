import Foundation

// MARK: - Main Stress Calculator
/// Implements the stress algorithm combining HRV (70%) and heart rate (30%)
final class StressCalculator: StressAlgorithmServiceProtocol {

    // MARK: - Properties
    private let baseline: PersonalBaseline

    // MARK: - Initialization
    init(baseline: PersonalBaseline = PersonalBaseline()) {
        self.baseline = baseline
    }

    // MARK: - StressAlgorithmServiceProtocol
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        // Calculate normalized values
        let normalizedHRV = normalizeHRV(hrv, baseline: baseline.baselineHRV)
        let normalizedHR = normalizeHeartRate(heartRate, resting: baseline.restingHeartRate)

        // Calculate components
        let hrvComponent = calculateHRVComponent(normalizedHRV)
        let hrComponent = calculateHRComponent(normalizedHR)

        // Combine components (70% HRV, 30% HR)
        let stressLevel = (hrvComponent * 0.7) + (hrComponent * 0.3)

        // Clamp to 0-100 range
        let clampedLevel = max(0, min(100, stressLevel))

        // Determine category
        let category = StressResult.category(for: clampedLevel)

        // Calculate confidence (default samples for now)
        let confidence = calculateConfidence(hrv: hrv, heartRate: heartRate, samples: 1)

        return StressResult(
            level: clampedLevel,
            category: category,
            confidence: confidence,
            hrv: hrv,
            heartRate: heartRate,
            timestamp: Date()
        )
    }

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        var confidence = 1.0

        // Reduce confidence for low HRV readings
        if hrv < 20 {
            confidence *= 0.5
        }

        // Reduce confidence for extreme heart rates
        if heartRate < 40 || heartRate > 180 {
            confidence *= 0.6
        }

        // Adjust based on sample count (more samples = higher confidence)
        let sampleMultiplier = min(1.0, Double(samples) / 10.0)
        confidence *= (0.7 + (sampleMultiplier * 0.3))

        return max(0.0, min(1.0, confidence))
    }

    // MARK: - Private Helper Methods
    /// Normalizes HRV value relative to baseline
    /// Returns: (Baseline - HRV) / Baseline
    private func normalizeHRV(_ hrv: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return (baseline - hrv) / baseline
    }

    /// Normalizes heart rate value relative to resting heart rate
    /// Returns: (HR - Resting HR) / Resting HR
    private func normalizeHeartRate(_ heartRate: Double, resting: Double) -> Double {
        guard resting > 0 else { return 0 }
        return (heartRate - resting) / resting
    }

    /// Calculates HRV component using power function
    /// Returns: Normalized HRV ^ 0.8
    private func calculateHRVComponent(_ normalizedHRV: Double) -> Double {
        // Ensure non-negative for power operation
        let value = max(0, normalizedHRV)
        return pow(value, 0.8) * 100
    }

    /// Calculates heart rate component using atan function
    /// Returns: atan(Normalized HR * 2) / (π/2)
    private func calculateHRComponent(_ normalizedHR: Double) -> Double {
        let scaled = normalizedHR * 2
        let atanValue = atan(scaled)
        let result = atanValue / (.pi / 2)

        // Convert to 0-100 scale
        return max(0, result) * 100
    }
}

// MARK: - Thread Safety
extension StressCalculator: @unchecked Sendable {}
