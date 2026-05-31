import Foundation
import HealthKit

// MARK: - HealthKitManager Sleep Fetching

extension HealthKitManager {

    /// Fetches last night's sleep (yesterday 6 PM → today noon) and aggregates into SleepData.
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let queryEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false

            let query = HKSampleQuery(
                sampleType: self.sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !hasReturned else { return }
                hasReturned = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: Self.aggregateSleepSamples(samples, date: date))
            }

            self.healthStore.execute(query)
        }
    }

    private static func aggregateSleepSamples(_ samples: [HKCategorySample], date: Date) -> SleepData {
        var totalSleep: TimeInterval = 0
        var deepSleep: TimeInterval = 0
        var remSleep: TimeInterval = 0
        var coreSleep: TimeInterval = 0
        var awakenings = 0
        var timeInBed: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                timeInBed += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleep += duration; totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleep += duration; totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                coreSleep += duration; totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awakenings += 1
            default:
                break
            }
        }

        let toHours = { (t: TimeInterval) in t / 3600.0 }
        let efficiency = timeInBed > 0 ? min(1.0, totalSleep / timeInBed) : 0

        return SleepData(
            totalSleepHours: toHours(totalSleep),
            deepSleepHours: toHours(deepSleep),
            remSleepHours: toHours(remSleep),
            coreSleepHours: toHours(coreSleep),
            awakenings: awakenings,
            timeInBedHours: toHours(timeInBed),
            sleepEfficiency: efficiency,
            analysisDate: date
        )
    }
}
