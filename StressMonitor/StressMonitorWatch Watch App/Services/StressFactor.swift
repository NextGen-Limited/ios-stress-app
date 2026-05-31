import Foundation

protocol StressFactor: Sendable {
    var id: String { get }
    var weight: Double { get }
    func calculate(context: StressContext) async throws -> FactorResult?
}

struct FactorResult: Sendable {
    let value: Double
    let confidence: Double
    let metadata: [String: Double]
}
