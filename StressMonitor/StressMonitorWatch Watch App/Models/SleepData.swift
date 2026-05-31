import Foundation

struct SleepData: Sendable {
    let totalSleepHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double
    let coreSleepHours: Double
    let awakenings: Int
    let timeInBedHours: Double
    let sleepEfficiency: Double
    let analysisDate: Date
}
