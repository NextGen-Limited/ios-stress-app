import Foundation

// MARK: - StressContext

/// Carries all raw inputs needed for multi-factor stress calculation.
/// All data fields are optional to support graceful degradation when
/// sensors or permissions are unavailable.
struct StressContext: Sendable {
    let baseline: PersonalBaseline
    let timestamp: Date

    // Raw inputs — nil means factor will be skipped and its weight redistributed
    let hrv: Double?
    let heartRate: Double?
    let sleepData: SleepData?
    let activityData: ActivityData?
    let recoveryData: RecoveryData?
    let lastReadingDate: Date?

    init(
        baseline: PersonalBaseline,
        timestamp: Date = Date(),
        hrv: Double? = nil,
        heartRate: Double? = nil,
        sleepData: SleepData? = nil,
        activityData: ActivityData? = nil,
        recoveryData: RecoveryData? = nil,
        lastReadingDate: Date? = nil
    ) {
        self.baseline = baseline
        self.timestamp = timestamp
        self.hrv = hrv
        self.heartRate = heartRate
        self.sleepData = sleepData
        self.activityData = activityData
        self.recoveryData = recoveryData
        self.lastReadingDate = lastReadingDate
    }
}
