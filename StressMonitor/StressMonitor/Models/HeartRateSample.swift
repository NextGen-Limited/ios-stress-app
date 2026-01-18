import Foundation

struct HeartRateSample: Identifiable, Codable, Sendable {
    let id: UUID
    let value: Double
    let timestamp: Date

    init(value: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
    }
}
