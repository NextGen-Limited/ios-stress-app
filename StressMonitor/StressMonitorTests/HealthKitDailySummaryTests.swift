import Foundation
import Testing
@testable import StressMonitor

/// Pins the daily aggregation seam (Task 2):
/// - `makePayload` maps `DailyAggregates` onto the snake_case backend
///   contract with the metric's local date and IANA timezone
/// - `makePayload` returns nil when every metric is missing — nothing
///   to upload
/// (The HealthKit query path itself needs a store; covered by the pure
/// builder here.)
@MainActor
struct HealthKitDailySummaryTests {

    @Test("makePayload maps aggregates to snake_case payload with local date")
    func payloadBuilt() throws {
        let tz = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let date = cal.date(from: DateComponents(year: 2026, month: 9, day: 4))!
        let aggregates = HealthKitManager.DailyAggregates(
            hrvSDNN: 48.2, heartRateAvg: 72.4, restingHeartRate: 61,
            hrvCount: 4, heartRateCount: 163, restingHeartRateCount: 1)

        let payload = HealthKitManager.makePayload(
            aggregates: aggregates, date: date, timeZone: tz)

        #expect(payload?.localDate == "2026-09-04")
        #expect(payload?.timezone == "Asia/Ho_Chi_Minh")
        #expect(payload?.hrvSdnnMs == 48.2)
        #expect(payload?.sampleCounts.heartRate == 163)
        #expect(payload?.source == "healthkit")
    }

    @Test("makePayload is nil when every metric is missing")
    func payloadSkippedWhenEmpty() throws {
        let empty = HealthKitManager.DailyAggregates(
            hrvSDNN: nil, heartRateAvg: nil, restingHeartRate: nil,
            hrvCount: 0, heartRateCount: 0, restingHeartRateCount: 0)
        #expect(HealthKitManager.makePayload(
            aggregates: empty, date: Date(), timeZone: .current) == nil)
    }
}
