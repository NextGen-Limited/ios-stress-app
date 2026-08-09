import Foundation
import Testing
@testable import StressMonitor

/// WidgetPublisher.Keys and WidgetDataProvider.Keys are both `private` and live in
/// separate compile targets (StressMonitor app vs. StressMonitorWidget extension), so
/// they cannot be compared by type. This regression-proofs the contract via the literal
/// key strings both sides are known to use instead.
struct WidgetPublisherKeyMatchingTests {
    private static let suiteName = "group.stress.ai.com"

    private static let allKeys = [
        "latest_stress_level",
        "latest_stress_category",
        "latest_hrv",
        "latest_heart_rate",
        "latest_timestamp",
        "latest_confidence"
    ]

    private func cleanUp(_ defaults: UserDefaults) {
        for key in Self.allKeys {
            defaults.removeObject(forKey: key)
        }
    }

    @Test("publish writes all six App-Group UserDefaults keys")
    func publishWritesAllSixKeys() {
        let defaults = UserDefaults(suiteName: Self.suiteName)!
        cleanUp(defaults)

        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 42,
            hrv: 55,
            restingHeartRate: 68,
            confidences: nil
        )

        WidgetPublisher.publish(measurement)

        #expect(defaults.object(forKey: "latest_stress_level") != nil)
        #expect(defaults.object(forKey: "latest_stress_category") != nil)
        #expect(defaults.object(forKey: "latest_hrv") != nil)
        #expect(defaults.object(forKey: "latest_heart_rate") != nil)
        #expect(defaults.object(forKey: "latest_timestamp") != nil)
        #expect(defaults.object(forKey: "latest_confidence") != nil)

        cleanUp(defaults)
    }

    @Test("published values match the source measurement")
    func publishedValuesMatchSource() {
        let defaults = UserDefaults(suiteName: Self.suiteName)!
        cleanUp(defaults)

        let timestamp = Date()
        let measurement = StressMeasurement(
            timestamp: timestamp,
            stressLevel: 61,
            hrv: 38,
            restingHeartRate: 74,
            confidences: nil
        )

        WidgetPublisher.publish(measurement)

        #expect(defaults.double(forKey: "latest_stress_level") == measurement.stressLevel)
        #expect(defaults.string(forKey: "latest_stress_category") == measurement.categoryRawValue)
        #expect(defaults.double(forKey: "latest_hrv") == measurement.hrv)
        #expect(defaults.double(forKey: "latest_heart_rate") == measurement.restingHeartRate)
        #expect(defaults.double(forKey: "latest_confidence") == 1.0)
        #expect(defaults.double(forKey: "latest_timestamp") == measurement.timestamp.timeIntervalSince1970)

        cleanUp(defaults)
    }
}
