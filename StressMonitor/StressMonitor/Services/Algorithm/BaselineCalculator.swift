import Foundation

enum BaselineCalculatorError: Error, LocalizedError {
    case insufficientSamples
    case noValidData

    var errorDescription: String? {
        switch self {
        case .insufficientSamples: return "Need at least 30 samples for baseline calculation"
        case .noValidData: return "No valid measurements available"
        }
    }
}

final class BaselineCalculator: Sendable {

    private let minimumSampleCount: Int
    private let timeWindowDays: Int

    init(minimumSampleCount: Int = 30, timeWindowDays: Int = 30) {
        self.minimumSampleCount = minimumSampleCount
        self.timeWindowDays = timeWindowDays
    }

    func calculateBaseline(from measurements: [HRVMeasurement]) async throws -> PersonalBaseline {
        let filtered = filterOutliers(measurements)

        try validateSampleCount(filtered.count)

        guard !filtered.isEmpty else {
            throw BaselineCalculatorError.noValidData
        }

        let avgHRV = filtered.reduce(0) { $0 + $1.value } / Double(filtered.count)

        return PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: avgHRV,
            lastUpdated: Date()
        )
    }

    func calculateRestingHeartRate(from samples: [HeartRateSample]) -> Double {
        guard samples.count >= 10 else { return 60 }

        let sorted = samples.map { $0.value }.sorted()
        let percentileIndex = Int(Double(sorted.count) * 0.1)
        return sorted[percentileIndex]
    }

    func shouldUpdateBaseline(lastUpdate: Date, samples: Int) -> Bool {
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdate, to: Date()).day ?? 0
        return daysSinceUpdate >= 7 || samples >= 10
    }

    private func validateSampleCount(_ count: Int) throws {
        guard count >= minimumSampleCount else {
            throw BaselineCalculatorError.insufficientSamples
        }
    }

    func filterOutliers(_ measurements: [HRVMeasurement]) -> [HRVMeasurement] {
        guard measurements.count >= 4 else { return measurements }

        let sorted = measurements.map { $0.value }.sorted()
        let q1Index = sorted.count / 4
        let q3Index = (sorted.count * 3) / 4

        let q1 = sorted[q1Index]
        let q3 = sorted[q3Index]
        let iqr = q3 - q1

        let lowerBound = q1 - (1.5 * iqr)
        let upperBound = q3 + (1.5 * iqr)

        return measurements.filter { $0.value >= lowerBound && $0.value <= upperBound }
    }
}
