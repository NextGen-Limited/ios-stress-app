import Foundation

protocol StressAlgorithmServiceProtocol: Sendable {
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int, lastReadingDate: Date?) -> Double
    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult
}

extension StressAlgorithmServiceProtocol {
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples, lastReadingDate: nil)
    }

    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult {
        try await calculateStress(hrv: context.hrv ?? 0, heartRate: context.heartRate ?? 0)
    }
}
