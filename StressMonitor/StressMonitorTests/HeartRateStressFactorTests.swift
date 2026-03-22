import XCTest
@testable import StressMonitor

final class HeartRateStressFactorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private let factor = HeartRateStressFactor()

    private func makeContext(heartRate: Double?) -> StressContext {
        StressContext(baseline: baseline, hrv: 50, heartRate: heartRate)
    }

    func testNilHeartRate_returnsNil() async throws {
        let result = try await factor.calculate(context: makeContext(heartRate: nil))
        XCTAssertNil(result, "Nil heart rate should return nil")
    }

    func testAtRestingHR_lowStress() async throws {
        // HR = resting (60): normalized = 0, sigmoid(0, k=3, x0=0.3) ≈ 0.29
        let result = try await factor.calculate(context: makeContext(heartRate: 60))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.29, accuracy: 0.05)
    }

    func testElevatedHR_highStress() async throws {
        // HR = 120bpm: normalized = 1.0, sigmoid(1.0, k=3, x0=0.3) near 1
        let result = try await factor.calculate(context: makeContext(heartRate: 120))
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.value, 0.7)
    }

    func testOutputAlwaysInRange() async throws {
        for hr in stride(from: 30.0, through: 200.0, by: 10.0) {
            let result = try await factor.calculate(context: makeContext(heartRate: hr))
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.value, 0.0)
                XCTAssertLessThanOrEqual(r.value, 1.0)
            }
        }
    }
}
