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
}
