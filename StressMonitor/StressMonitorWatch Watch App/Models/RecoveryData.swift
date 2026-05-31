import Foundation

struct RecoveryData: Sendable {
    let respiratoryRate: Double?
    let bloodOxygen: Double?
    let restingHeartRate: Double?
    let restingHRTrend: Double?
    let analysisDate: Date
}
