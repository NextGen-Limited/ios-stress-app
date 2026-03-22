import XCTest
@testable import StressMonitor

final class SleepStressFactorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private let factor = SleepStressFactor()

    private func makeContext(sleep: SleepData?) -> StressContext {
        StressContext(baseline: baseline, hrv: 50, heartRate: 60, sleepData: sleep)
    }

    private func makeSleep(total: Double, deep: Double = 1.0, rem: Double = 1.5,
                            efficiency: Double = 0.9) -> SleepData {
        SleepData(totalSleepHours: total, deepSleepHours: deep, remSleepHours: rem,
                  coreSleepHours: total - deep - rem - 0.5, awakenings: 1,
                  timeInBedHours: total / efficiency, sleepEfficiency: efficiency,
                  analysisDate: Date())
    }

    func testNilSleep_returnsNil() async throws {
        let result = try await factor.calculate(context: makeContext(sleep: nil))
        XCTAssertNil(result, "Missing sleep data should return nil — factor gracefully skipped")
    }

    func testGoodSleep_lowStress() async throws {
        // 8h total, good deep+REM, high efficiency
        let sleep = makeSleep(total: 8.0, deep: 1.5, rem: 2.0, efficiency: 0.92)
        let result = try await factor.calculate(context: makeContext(sleep: sleep))
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.value, 0.3, "Good sleep → low stress contribution")
    }

    func testPoorSleep_highStress() async throws {
        // 4h total, little deep/REM, low efficiency
        let sleep = makeSleep(total: 4.0, deep: 0.2, rem: 0.3, efficiency: 0.55)
        let result = try await factor.calculate(context: makeContext(sleep: sleep))
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.value, 0.5, "Poor sleep → high stress contribution")
    }

    func testVeryShortSleep_maxStress() async throws {
        // < 4h → duration component maxes out
        let sleep = makeSleep(total: 2.0, deep: 0.1, rem: 0.1, efficiency: 0.6)
        let result = try await factor.calculate(context: makeContext(sleep: sleep))
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.value, 0.6)
    }

    func testOutputAlwaysInRange() async throws {
        for hours in [2.0, 4.0, 6.0, 7.5, 8.0, 10.0] {
            let sleep = makeSleep(total: hours)
            let result = try await factor.calculate(context: makeContext(sleep: sleep))
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.value, 0.0)
                XCTAssertLessThanOrEqual(r.value, 1.0)
            }
        }
    }
}
