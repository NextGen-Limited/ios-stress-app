import Foundation

protocol StressAlgorithmServiceProtocol: Sendable {
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int, lastReadingDate: Date?) -> Double
    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult
}

extension StressAlgorithmServiceProtocol {
    /// Backward-compatible overload — forwards with nil lastReadingDate
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples, lastReadingDate: nil)
    }

    /// Default implementation — concrete types override for real confidence scoring
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int, lastReadingDate: Date?) -> Double {
        1.0
    }

    /// Default multi-factor implementation — delegates to legacy 2-factor method
    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult {
        try await calculateStress(hrv: context.hrv ?? 0, heartRate: context.heartRate ?? 0)
    }
}
