import Foundation
import HealthKit

// MARK: - HealthKitManager Activity Fetching

extension HealthKitManager {

    func fetchActivityData(for date: Date) async throws -> ActivityData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let dayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!

        async let steps = fetchCumulativeSum(type: stepCountType, unit: .count(), predicate: dayPredicate)
        async let energy = fetchCumulativeSum(type: activeEnergyType, unit: .kilocalorie(), predicate: dayPredicate)
        async let standTime = fetchCumulativeSum(type: appleStandTimeType, unit: .second(), predicate: dayPredicate)
        async let workout = fetchLastWorkout(since: yesterday)

        let (stepsVal, energyVal, standVal, lastWorkout) = try await (steps, energy, standTime, workout)

        return ActivityData(
            stepCount: Int(stepsVal ?? 0),
            activeEnergyKcal: energyVal ?? 0,
            standHours: Int((standVal ?? 0) / 3600.0),
            lastWorkoutEndTime: lastWorkout?.endDate,
            lastWorkoutDurationMinutes: lastWorkout.map { $0.endDate.timeIntervalSince($0.startDate) / 60.0 },
            analysisDate: date
        )
    }

    func fetchCumulativeSum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }

    private func fetchLastWorkout(since date: Date) async throws -> HKWorkout? {
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: samples?.first as? HKWorkout)
            }
            self.healthStore.execute(query)
        }
    }
}
