import XCTest
@testable import StressMonitor

/// Guards the D3 privacy decision: HealthKit-derived raw readings (HRV ms,
/// heart rate bpm, baseline values) must never reach the /chat backend. Only
/// the app's own derived stress score/category may — that's the product's
/// own analytics output, not HealthKit data itself.
final class StressContextPayloadTests: XCTestCase {

    func testBuildDoesNotIncludeRawHealthReadings() {
        let result = StressResult(level: 65, category: .moderate, confidence: 0.9, hrv: 42.5, heartRate: 78)
        let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)

        let payload = StressContextPayload.build(stressResult: result, baseline: baseline)

        XCTAssertNil(payload.hrv, "Raw HRV must never leave the device.")
        XCTAssertNil(payload.heartRate, "Raw heart rate must never leave the device.")
        XCTAssertNil(payload.baselineHRV, "Raw baseline HRV must never leave the device.")
        XCTAssertNil(payload.baselineHR, "Raw baseline resting heart rate must never leave the device.")
    }

    func testBuildStillIncludesDerivedStressScore() {
        let result = StressResult(level: 65, category: .moderate, confidence: 0.9, hrv: 42.5, heartRate: 78)

        let payload = StressContextPayload.build(stressResult: result, baseline: nil)

        XCTAssertEqual(payload.stressLevel, 65, "The derived stress score is the coach's core input and is not HealthKit data.")
        XCTAssertEqual(payload.stressCategory, StressCategory.moderate.rawValue)
        XCTAssertEqual(payload.confidence, 0.9)
    }

    func testEncodedPayloadOmitsRawHealthKeysEntirely() throws {
        let result = StressResult(level: 65, category: .moderate, confidence: 0.9, hrv: 42.5, heartRate: 78)
        let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
        let payload = StressContextPayload.build(stressResult: result, baseline: baseline)

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Swift's Codable synthesis omits nil Optional keys entirely (does not
        // emit "key": null) — asserting absence here proves the wire format,
        // not just the in-memory struct.
        XCTAssertNil(json?["hrv"], "hrv key must be absent from the wire payload.")
        XCTAssertNil(json?["heart_rate"], "heart_rate key must be absent from the wire payload.")
        XCTAssertNil(json?["baseline_hrv"], "baseline_hrv key must be absent from the wire payload.")
        XCTAssertNil(json?["baseline_hr"], "baseline_hr key must be absent from the wire payload.")
        XCTAssertNotNil(json?["stress_level"], "Derived stress level must still be present.")
    }

    // MARK: - CR-02 trend direction (repository delivers newest-first)

    /// `StressRepository.fetchRecent` hands `build` a newest-first history
    /// (SortDescriptor reverse), so the trend must be computed after
    /// restoring chronological order. These cases pin that contract (CR-02).
    private func measurement(level: Double, minutesAgo: Int) -> StressMeasurement {
        StressMeasurement(
            timestamp: Date(timeIntervalSinceNow: -TimeInterval(minutesAgo * 60)),
            stressLevel: level,
            hrv: 40,
            restingHeartRate: 60
        )
    }

    func testTrendIncreasingWhenStressRoseOverTime() {
        // Newest-first [70, 40]: chronologically the user went 40 → 70.
        let history = [
            measurement(level: 70, minutesAgo: 0),
            measurement(level: 40, minutesAgo: 60)
        ]

        let payload = StressContextPayload.build(stressResult: nil, baseline: nil, recentHistory: history)

        XCTAssertEqual(payload.stressTrend, "increasing", "A newest-first [70, 40] history rose over time.")
        XCTAssertEqual(payload.stressTrendDelta, "+30%")
    }

    func testTrendDecreasingWhenStressFellOverTime() {
        // Newest-first [40, 70]: chronologically the user went 70 → 40.
        let history = [
            measurement(level: 40, minutesAgo: 0),
            measurement(level: 70, minutesAgo: 60)
        ]

        let payload = StressContextPayload.build(stressResult: nil, baseline: nil, recentHistory: history)

        XCTAssertEqual(payload.stressTrend, "decreasing", "A newest-first [40, 70] history fell over time.")
        XCTAssertEqual(payload.stressTrendDelta, "-30%")
    }

    func testTrendStableWhenFluctuationWithinThreshold() {
        // ±5 either order is stable — direction is irrelevant at this delta.
        let history = [
            measurement(level: 52, minutesAgo: 0),
            measurement(level: 50, minutesAgo: 60)
        ]

        let payload = StressContextPayload.build(stressResult: nil, baseline: nil, recentHistory: history)

        XCTAssertEqual(payload.stressTrend, "stable")
    }

    func testTrendNilForSingleMeasurement() {
        let history = [measurement(level: 55, minutesAgo: 0)]

        let payload = StressContextPayload.build(stressResult: nil, baseline: nil, recentHistory: history)

        XCTAssertNil(payload.stressTrend, "One measurement has no direction.")
        XCTAssertNil(payload.stressTrendDelta)
    }
}
