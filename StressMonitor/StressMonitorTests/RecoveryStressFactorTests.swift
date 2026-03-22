import XCTest
@testable import StressMonitor

final class RecoveryStressFactorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private let factor = RecoveryStressFactor()

    private func makeContext(recovery: RecoveryData?) -> StressContext {
        StressContext(baseline: baseline, hrv: 50, heartRate: 60, recoveryData: recovery)
    }

    private func makeRecovery(rr: Double? = nil, spo2: Double? = nil, trend: Double? = nil) -> RecoveryData {
        RecoveryData(respiratoryRate: rr, bloodOxygen: spo2,
                     restingHeartRate: nil, restingHRTrend: trend, analysisDate: Date())
    }

    func testNilRecovery_returnsNil() async throws {
        let result = try await factor.calculate(context: makeContext(recovery: nil))
        XCTAssertNil(result, "Missing recovery data should return nil")
    }

    func testAllMetricsNil_returnsNil() async throws {
        // RecoveryData present but all optional fields nil → guard !components.isEmpty
        let recovery = makeRecovery()
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNil(result, "RecoveryData with all nil metrics should return nil")
    }

    func testHealthyRecovery_lowStress() async throws {
        // rr=14 (low-normal), spo2=99 (optimal), trend=0 (stable)
        let recovery = makeRecovery(rr: 14, spo2: 99, trend: 0)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.value, 0.2, "Healthy recovery metrics → low stress")
    }

    func testElevatedRespiratoryRate_highStress() async throws {
        // rr=28 → (28-12)/16 = 1.0, only rr available
        let recovery = makeRecovery(rr: 28)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 1.0, accuracy: 0.05, "RR at 28bpm → max stress component")
    }

    func testNormalRespiratoryRate_nearZeroStress() async throws {
        // rr=12 → (12-12)/16 = 0
        let recovery = makeRecovery(rr: 12)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.0, accuracy: 0.05)
    }

    func testLowSpO2_highStress() async throws {
        // spo2=92 → (100-92)/8 = 1.0
        let recovery = makeRecovery(spo2: 92)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 1.0, accuracy: 0.05, "SpO2 at 92% → max stress component")
    }

    func testOptimalSpO2_noStress() async throws {
        // spo2=100 → (100-100)/8 = 0
        let recovery = makeRecovery(spo2: 100)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.0, accuracy: 0.05)
    }

    func testRisingHRTrend_addsStress() async throws {
        // trend=10 (bpm above 7-day avg) → 10/10 = 1.0
        let recovery = makeRecovery(trend: 10)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 1.0, accuracy: 0.05)
    }

    func testSingleMetric_reducedConfidence() async throws {
        // 1 sub-metric: dataAvailability = 1/3, confidence = 0.6 + (1/3)*0.3 ≈ 0.70
        let recovery = makeRecovery(rr: 15)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.confidence, 0.70, accuracy: 0.02)
    }

    func testThreeMetrics_highConfidence() async throws {
        // 3 sub-metrics: dataAvailability = 1.0, confidence = 0.6 + 0.3 = 0.90
        let recovery = makeRecovery(rr: 15, spo2: 98, trend: 2)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.confidence, 0.90, accuracy: 0.01)
    }

    func testPartialData_weightsNormalizedCorrectly() async throws {
        // Only rr + spo2: weights 0.40 + 0.30 = 0.70, normalized to 1.0
        // rr=28 (stress=1.0, raw_weight=0.40), spo2=100 (stress=0.0, raw_weight=0.30)
        // combined = (1.0 * 0.40/0.70) + (0.0 * 0.30/0.70) ≈ 0.571
        let recovery = makeRecovery(rr: 28, spo2: 100)
        let result = try await factor.calculate(context: makeContext(recovery: recovery))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.571, accuracy: 0.05)
    }

    func testOutputAlwaysInRange() async throws {
        let cases: [(Double?, Double?, Double?)] = [
            (12, 100, 0), (16, 97, 2), (20, 95, 5), (28, 92, 10),
            (nil, 98, nil), (15, nil, 3), (nil, nil, 5)
        ]
        for (rr, spo2, trend) in cases {
            let recovery = makeRecovery(rr: rr, spo2: spo2, trend: trend)
            let result = try await factor.calculate(context: makeContext(recovery: recovery))
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.value, 0.0)
                XCTAssertLessThanOrEqual(r.value, 1.0)
                XCTAssertGreaterThanOrEqual(r.confidence, 0.0)
                XCTAssertLessThanOrEqual(r.confidence, 1.0)
            }
        }
    }
}
