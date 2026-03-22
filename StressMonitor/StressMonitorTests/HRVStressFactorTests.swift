import XCTest
@testable import StressMonitor

final class HRVStressFactorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private let factor = HRVStressFactor()

    private func makeContext(hrv: Double?) -> StressContext {
        StressContext(baseline: baseline, hrv: hrv, heartRate: 70)
    }

    func testNilHRV_returnsNil() async throws {
        let result = try await factor.calculate(context: makeContext(hrv: nil))
        XCTAssertNil(result, "Nil HRV should return nil — factor gracefully unavailable")
    }

    func testAtBaselineHRV_midpointStress() async throws {
        // hrv = 50ms (= baseline): normalized = 0, sigmoid(0, k=4, x0=0.5) ≈ 0.12
        let result = try await factor.calculate(context: makeContext(hrv: 50))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.12, accuracy: 0.05)
        XCTAssertGreaterThan(result!.confidence, 0.8)
    }

    func testLowHRV_highStress() async throws {
        // hrv = 10ms (well below baseline): normalized = 0.8, sigmoid near 1
        let result = try await factor.calculate(context: makeContext(hrv: 10))
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.value, 0.7, "Very low HRV → high stress factor")
    }

    func testHighHRV_lowStress() async throws {
        // hrv = 80ms (above baseline): normalized = -0.6, clamped to 0, sigmoid low
        let result = try await factor.calculate(context: makeContext(hrv: 80))
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.value, 0.2, "HRV above baseline → low stress factor")
    }

    func testVeryLowHRV_reducedConfidence() async throws {
        // hrv < 20ms → proportional confidence reduction
        let result = try await factor.calculate(context: makeContext(hrv: 5))
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.confidence, 0.5, "Very low HRV degrades confidence")
    }

    func testOutputAlwaysInRange() async throws {
        for hrv in stride(from: 0.0, through: 150.0, by: 10.0) {
            let result = try await factor.calculate(context: makeContext(hrv: hrv))
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.value, 0.0)
                XCTAssertLessThanOrEqual(r.value, 1.0)
                XCTAssertGreaterThanOrEqual(r.confidence, 0.0)
                XCTAssertLessThanOrEqual(r.confidence, 1.0)
            }
        }
    }
}
