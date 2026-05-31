import Foundation

struct ActivityData: Sendable {
    let stepCount: Int
    let activeEnergyKcal: Double
    let standHours: Int
    let lastWorkoutEndTime: Date?
    let lastWorkoutDurationMinutes: Double?
    let analysisDate: Date
}
