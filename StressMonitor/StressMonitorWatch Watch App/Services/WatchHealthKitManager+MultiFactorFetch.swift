import Foundation
import HealthKit

// MARK: - WatchHealthKitManager Multi-Factor Data Fetching

extension WatchHealthKitManager {

    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let queryEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            var done = false
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                guard !done else { return }; done = true
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: Self.aggregateSleep(samples, date: date))
            }
            healthStore.execute(query)
        }
    }

    func fetchActivityData(for date: Date) async throws -> ActivityData? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        async let steps = fetchCumulativeSum(type: stepCountType, unit: .count(), predicate: predicate)
        async let energy = fetchCumulativeSum(type: activeEnergyType, unit: .kilocalorie(), predicate: predicate)
        async let standTime = fetchCumulativeSum(type: appleStandTimeType, unit: .second(), predicate: predicate)

        let (s, e, st) = try await (steps, energy, standTime)
        return ActivityData(stepCount: Int(s ?? 0), activeEnergyKcal: e ?? 0,
                            standHours: Int((st ?? 0) / 3600.0),
                            lastWorkoutEndTime: nil, lastWorkoutDurationMinutes: nil, analysisDate: date)
    }

    func fetchRecoveryData(for date: Date) async throws -> RecoveryData? {
        async let rr = fetchLatestSample(type: respiratoryRateType, unit: .count().unitDivided(by: .minute()))
        async let spo2 = fetchLatestSample(type: oxygenSaturationType, unit: .percent())
        let (rrVal, spo2Val) = try await (rr, spo2)
        guard rrVal != nil || spo2Val != nil else { return nil }
        return RecoveryData(respiratoryRate: rrVal, bloodOxygen: spo2Val.map { $0 * 100.0 },
                            restingHeartRate: nil, restingHRTrend: nil, analysisDate: date)
    }

    // MARK: - Private helpers

    private func fetchCumulativeSum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            var done = false
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, error in
                guard !done else { return }; done = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestSample(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            var done = false
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                guard !done else { return }; done = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private static func aggregateSleep(_ samples: [HKCategorySample], date: Date) -> SleepData {
        var total: TimeInterval = 0, deep: TimeInterval = 0
        var rem: TimeInterval = 0, core: TimeInterval = 0
        var awakenings = 0, inBed: TimeInterval = 0

        for s in samples {
            let d = s.endDate.timeIntervalSince(s.startDate)
            switch s.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue: inBed += d
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += d; total += d
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += d; total += d
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue: core += d; total += d
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: total += d
            case HKCategoryValueSleepAnalysis.awake.rawValue: awakenings += 1
            default: break
            }
        }

        let h = { (t: TimeInterval) in t / 3600.0 }
        return SleepData(totalSleepHours: h(total), deepSleepHours: h(deep), remSleepHours: h(rem),
                         coreSleepHours: h(core), awakenings: awakenings, timeInBedHours: h(inBed),
                         sleepEfficiency: inBed > 0 ? min(1.0, total / inBed) : 0, analysisDate: date)
    }
}
