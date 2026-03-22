import Foundation

// MARK: - RecoveryData

/// Physiological recovery markers from HealthKit.
/// All fields optional — requires Apple Watch Series 6+ for SpO2/respiratory rate.
struct RecoveryData: Sendable {
    let respiratoryRate: Double?       // breaths/min (latest)
    let bloodOxygen: Double?           // SpO2 percentage 0-100 (latest)
    let restingHeartRate: Double?      // latest resting HR
    let restingHRTrend: Double?        // delta from 7-day avg (positive = rising = worse recovery)
    let analysisDate: Date
}
