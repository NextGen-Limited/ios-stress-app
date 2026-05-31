import Foundation

struct StressReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: Double        // 0.0 - 1.0
    let hrv: Double          // Heart Rate Variability in ms
    let heartRate: Double    // BPM
    let source: DataSource
    
    enum DataSource: String, Codable {
        case appleWatch
        case manual
        case estimated
    }
}

struct StressSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let averageLevel: Double
    let peakLevel: Double
    let readings: [StressReading]
}
