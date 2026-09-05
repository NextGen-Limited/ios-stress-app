import Foundation
import HealthKit

// MARK: - HealthKitManager Daily Aggregation

extension HealthKitManager {

    struct DailyAggregates: Equatable, Sendable {
        var hrvSDNN: Double?
        var heartRateAvg: Double?
        var restingHeartRate: Double?
        var hrvCount: Int
        var heartRateCount: Int
        var restingHeartRateCount: Int
    }

    /// Average + count of each metric over one local calendar day.
    func dailyAggregates(for date: Date) async throws -> DailyAggregates {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let ms = HKUnit(from: "ms")
        let bpm = HKUnit.count().unitDivided(by: .minute())

        async let hrv = averageAndCount(type: hrvType, unit: ms, predicate: predicate)
        async let hr = averageAndCount(type: heartRateType, unit: bpm, predicate: predicate)
        async let rhr = averageAndCount(type: restingHeartRateType, unit: bpm, predicate: predicate)

        let (hrvStats, hrStats, rhrStats) = try await (hrv, hr, rhr)

        return DailyAggregates(
            hrvSDNN: hrvStats.average,
            heartRateAvg: hrStats.average,
            restingHeartRate: rhrStats.average,
            hrvCount: hrvStats.count,
            heartRateCount: hrStats.count,
            restingHeartRateCount: rhrStats.count)
    }

    /// Maps one day's aggregates onto the backend contract; nil when every
    /// metric is missing (nothing to upload).
    static func makePayload(
        aggregates: DailyAggregates, date: Date, timeZone: TimeZone
    ) -> DailySummaryPayload? {
        guard aggregates.hrvSDNN != nil || aggregates.heartRateAvg != nil ||
            aggregates.restingHeartRate != nil else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return DailySummaryPayload(
            localDate: formatter.string(from: date),
            timezone: timeZone.identifier,
            hrvSdnnMs: aggregates.hrvSDNN,
            heartRateAvgBpm: aggregates.heartRateAvg,
            restingHeartRateBpm: aggregates.restingHeartRate,
            sampleCounts: .init(
                hrv: aggregates.hrvCount,
                heartRate: aggregates.heartRateCount,
                restingHeartRate: aggregates.restingHeartRateCount),
            source: "healthkit")
    }

    private func averageAndCount(
        type: HKQuantityType,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> (average: Double?, count: Int) {
        let average: Double? = try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: statistics?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
        let count: Int = try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: samples?.count ?? 0)
            }
            self.healthStore.execute(query)
        }
        return (average, count)
    }
}
