import Foundation

struct HRVMeasurement: Identifiable, Codable, Sendable {
    let id: UUID
    let value: Double
    let timestamp: Date
    let unit: String

    init(value: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
        self.unit = "ms"
    }
}
