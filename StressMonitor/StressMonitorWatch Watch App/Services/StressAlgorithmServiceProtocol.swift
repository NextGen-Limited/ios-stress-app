import Foundation

protocol StressAlgorithmServiceProtocol: Sendable {
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
}
