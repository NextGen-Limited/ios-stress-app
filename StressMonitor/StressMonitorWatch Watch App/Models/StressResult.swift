import Foundation

struct StressResult: Identifiable, Codable, Sendable {
    let id: UUID
    let level: Double
    let category: StressCategory
    let confidence: Double
    let hrv: Double
    let heartRate: Double
    let timestamp: Date
    let factorBreakdown: FactorBreakdown?

    init(
        level: Double,
        category: StressCategory,
        confidence: Double,
        hrv: Double,
        heartRate: Double,
        timestamp: Date = Date(),
        factorBreakdown: FactorBreakdown? = nil
    ) {
        self.id = UUID()
        self.level = level
        self.category = category
        self.confidence = confidence
        self.hrv = hrv
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.factorBreakdown = factorBreakdown
    }

    /// Resolve the tier from a raw 0–100+ stress level.
    /// Delegates to `StressCategory.category(for:)` so the model is the
    /// single source of truth (and includes the Severe band 100+).
    static func category(for level: Double) -> StressCategory {
        StressCategory.category(for: level)
    }
}
