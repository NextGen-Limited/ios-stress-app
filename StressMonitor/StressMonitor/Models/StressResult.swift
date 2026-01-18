import Foundation

struct StressResult: Identifiable, Codable, Sendable {
    let id: UUID
    let level: Double
    let category: StressCategory
    let confidence: Double
    let hrv: Double
    let heartRate: Double
    let timestamp: Date

    init(level: Double, category: StressCategory, confidence: Double, hrv: Double, heartRate: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.level = level
        self.category = category
        self.confidence = confidence
        self.hrv = hrv
        self.heartRate = heartRate
        self.timestamp = timestamp
    }

    static func category(for level: Double) -> StressCategory {
        switch level {
        case 0..<25: return .relaxed
        case 25..<50: return .mild
        case 50..<75: return .moderate
        default: return .high
        }
    }
}
