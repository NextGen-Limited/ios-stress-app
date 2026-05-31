import Foundation

// MARK: - ActivityData

/// Today's activity metrics from HealthKit.
/// Used by ActivityStressFactor — sedentary patterns increase stress contribution.
struct ActivityData: Sendable {
    let stepCount: Int
    let activeEnergyKcal: Double
    let standHours: Int
    let lastWorkoutEndTime: Date?
    let lastWorkoutDurationMinutes: Double?
    let analysisDate: Date
}
