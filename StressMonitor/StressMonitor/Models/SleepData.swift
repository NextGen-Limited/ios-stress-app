import Foundation

// MARK: - SleepData

/// Aggregated sleep session data from HealthKit (.sleepAnalysis).
/// Populated from HKCategoryValueSleepAnalysis samples for the prior night
/// (yesterday 6 PM → today noon).
struct SleepData: Sendable {
    let totalSleepHours: Double       // total asleep time
    let deepSleepHours: Double        // .asleepDeep stage
    let remSleepHours: Double         // .asleepREM stage
    let coreSleepHours: Double        // .asleepCore stage
    let awakenings: Int               // number of .awake segments
    let timeInBedHours: Double        // .inBed duration
    let sleepEfficiency: Double       // totalSleep / timeInBed (0-1)
    let analysisDate: Date
}
