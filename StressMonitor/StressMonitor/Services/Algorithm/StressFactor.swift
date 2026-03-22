import Foundation

// MARK: - StressFactor Protocol

/// A single stress contributor. Each factor independently scores 0-1
/// and provides a weight. Missing factors cause weight redistribution.
protocol StressFactor: Sendable {
    var id: String { get }
    var weight: Double { get }
    func calculate(context: StressContext) async throws -> FactorResult?
}

// MARK: - FactorResult

struct FactorResult: Sendable {
    /// Normalized stress contribution: 0 = no stress, 1 = maximum stress
    let value: Double
    /// Reliability of this reading: 0 = unreliable, 1 = fully reliable
    let confidence: Double
    /// Debug/display data (e.g., raw sensor values)
    let metadata: [String: Double]
}
