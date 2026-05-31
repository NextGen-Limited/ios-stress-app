import Foundation

// MARK: - FactorCalibrator

/// Derives per-user factor weights from historical stress measurements.
/// Requires at least 30 samples; falls back to defaults below that threshold.
final class FactorCalibrator: Sendable {

    /// Adjust factor weights based on variance contribution of each component.
    /// Weights are clamped to ±25% of defaults to prevent overfitting.
    func calibrate(from measurements: [StressMeasurement]) -> FactorWeights {
        guard measurements.count >= 30 else { return .defaults }

        let hrv = varianceContribution(measurements.compactMap(\.hrvComponent))
        let hr = varianceContribution(measurements.compactMap(\.hrComponent))
        let sleep = varianceContribution(measurements.compactMap(\.sleepComponent))
        let activity = varianceContribution(measurements.compactMap(\.activityComponent))
        let recovery = varianceContribution(measurements.compactMap(\.recoveryComponent))

        let total = hrv + hr + sleep + activity + recovery
        guard total > 0 else { return .defaults }

        return FactorWeights(
            hrv: clamp(hrv / total, default: 0.40),
            heartRate: clamp(hr / total, default: 0.15),
            sleep: clamp(sleep / total, default: 0.20),
            activity: clamp(activity / total, default: 0.15),
            recovery: clamp(recovery / total, default: 0.10)
        )
    }

    /// Compute per-hour HRV averages from measurement history.
    /// Hours with <5 samples are omitted — caller falls back to global baseline.
    func calculateHourlyBaseline(from measurements: [StressMeasurement]) -> [Int: Double] {
        var groups: [Int: [Double]] = [:]
        for m in measurements {
            let hour = Calendar.current.component(.hour, from: m.timestamp)
            groups[hour, default: []].append(m.hrv)
        }
        return groups.compactMapValues { values in
            values.count >= 5 ? values.reduce(0, +) / Double(values.count) : nil
        }
    }

    // MARK: - Private

    private func varianceContribution(_ values: [Double]) -> Double {
        guard values.count >= 10 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    }

    private func clamp(_ calculated: Double, default d: Double) -> Double {
        max(d * 0.75, min(d * 1.25, calculated))
    }
}
