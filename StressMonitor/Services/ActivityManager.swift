import Foundation
import HealthKit

/// Service for fetching workout/activity data from HealthKit and computing
/// correlations with stress readings for the history timeline.
@MainActor
class ActivityManager: ObservableObject {
    private let healthStore: HKHealthStore

    // MARK: - Published State

    @Published var workouts: [ActivityWorkout] = []
    @Published var correlations: [StressActivityCorrelation] = []
    @Published var dailySummaries: [DailyStressSummary] = []
    @Published var isLoading = false

    // MARK: - Configuration

    /// How many days back to look for history
    var historyDays: Int = 30

    // MARK: - Init

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    // MARK: - Public API

    /// Fetch workouts and compute daily summaries + correlations.
    /// - Parameter stressReadings: Recent stress readings from HealthKitManager
    /// - Parameter hrvReadings: HRV values paired with timestamps
    func fetchHistory(
        stressReadings: [StressReading],
        hrvByTimestamp: [(timestamp: Date, value: Double)]
    ) async {
        isLoading = true
        defer { isLoading = false }

        // 1. Fetch workouts from HealthKit
        let fetchedWorkouts = await fetchWorkouts(days: historyDays)
        workouts = fetchedWorkouts

        // 2. Compute activity-stress correlations
        correlations = computeCorrelations(
            workouts: fetchedWorkouts,
            stressReadings: stressReadings
        )

        // 3. Build daily summaries
        dailySummaries = buildDailySummaries(
            stressReadings: stressReadings,
            workouts: fetchedWorkouts,
            correlations: correlations,
            days: historyDays
        )
    }

    // MARK: - HealthKit Workout Fetch

    private func fetchWorkouts(days: Int) async -> [ActivityWorkout] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                let activityWorkouts = workouts.map { ActivityWorkout(workout: $0) }
                continuation.resume(returning: activityWorkouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Correlation Computation

    /// Compute stress correlations for each workout:
    /// Compare average stress in the 30 min before vs 30 min after.
    private func computeCorrelations(
        workouts: [ActivityWorkout],
        stressReadings: [StressReading]
    ) -> [StressActivityCorrelation] {
        guard !workouts.isEmpty, !stressReadings.isEmpty else { return [] }

        let sorted = stressReadings.sorted { $0.timestamp < $1.timestamp }
        var results: [StressActivityCorrelation] = []

        for workout in workouts {
            let beforeStart = workout.startDate.addingTimeInterval(-1800) // 30 min before
            let afterEnd = workout.endDate.addingTimeInterval(1800)       // 30 min after

            let beforeReadings = sorted.filter {
                $0.timestamp >= beforeStart && $0.timestamp < workout.startDate
            }
            let duringReadings = sorted.filter {
                $0.timestamp >= workout.startDate && $0.timestamp <= workout.endDate
            }
            let afterReadings = sorted.filter {
                $0.timestamp > workout.endDate && $0.timestamp <= afterEnd
            }

            let stressBefore = beforeReadings.isEmpty ? 0 :
                beforeReadings.map(\.level).reduce(0, +) / Double(beforeReadings.count)
            let stressDuring = duringReadings.isEmpty ? 0 :
                duringReadings.map(\.level).reduce(0, +) / Double(duringReadings.count)
            let stressAfter = afterReadings.isEmpty ? 0 :
                afterReadings.map(\.level).reduce(0, +) / Double(afterReadings.count)

            let hrvBefore = beforeReadings.isEmpty ? 0 :
                beforeReadings.map(\.hrv).reduce(0, +) / Double(beforeReadings.count)
            let hrvDuring = duringReadings.isEmpty ? 0 :
                duringReadings.map(\.hrv).reduce(0, +) / Double(duringReadings.count)
            let hrvAfter = afterReadings.isEmpty ? 0 :
                afterReadings.map(\.hrv).reduce(0, +) / Double(afterReadings.count)

            // Only include if we have at least before OR after data
            if !beforeReadings.isEmpty || !afterReadings.isEmpty {
                let correlation = StressActivityCorrelation(
                    workout: workout,
                    stressBefore: stressBefore,
                    stressDuring: stressDuring,
                    stressAfter: stressAfter,
                    stressChange: stressAfter - stressBefore,
                    hrvBefore: hrvBefore,
                    hrvDuring: hrvDuring,
                    hrvAfter: hrvAfter
                )
                results.append(correlation)
            }
        }

        return results
    }

    // MARK: - Daily Summaries

    private func buildDailySummaries(
        stressReadings: [StressReading],
        workouts: [ActivityWorkout],
        correlations: [StressActivityCorrelation],
        days: Int
    ) -> [DailyStressSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DailyStressSummary] = []

        for dayOffset in 0..<days {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayDate)!

            let dayReadings = stressReadings.filter {
                $0.timestamp >= dayDate && $0.timestamp < dayEnd
            }
            let dayWorkouts = workouts.filter {
                $0.startDate >= dayDate && $0.startDate < dayEnd
            }
            let dayCorrelations = correlations.filter {
                $0.workout.startDate >= dayDate && $0.workout.startDate < dayEnd
            }

            let stressValues = dayReadings.map(\.level)
            let hrvValues = dayReadings.map(\.hrv)

            let summary = DailyStressSummary(
                date: dayDate,
                averageStress: stressValues.isEmpty ? 0 : stressValues.reduce(0, +) / Double(stressValues.count),
                peakStress: stressValues.max() ?? 0,
                lowestStress: stressValues.min() ?? 0,
                averageHRV: hrvValues.isEmpty ? 0 : hrvValues.reduce(0, +) / Double(hrvValues.count),
                readingCount: dayReadings.count,
                workouts: dayWorkouts,
                correlations: dayCorrelations
            )
            summaries.append(summary)
        }

        return summaries
    }
}
