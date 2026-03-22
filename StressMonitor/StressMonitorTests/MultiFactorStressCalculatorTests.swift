import XCTest
@testable import StressMonitor

final class MultiFactorStressCalculatorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private var calculator: MultiFactorStressCalculator!

    override func setUp() {
        super.setUp()
        calculator = MultiFactorStressCalculator(baseline: baseline)
    }

    private func makeContext(hrv: Double? = 45, heartRate: Double? = 65,
                              sleep: SleepData? = nil) -> StressContext {
        StressContext(baseline: baseline, hrv: hrv, heartRate: heartRate,
                      sleepData: sleep, activityData: nil, recoveryData: nil)
    }

    // MARK: - Basic combination

    func testHRVAndHROnly_producesValidResult() async throws {
        let result = try await calculator.calculateMultiFactorStress(context: makeContext())
        XCTAssertGreaterThanOrEqual(result.level, 0)
        XCTAssertLessThanOrEqual(result.level, 100)
        XCTAssertNotNil(result.factorBreakdown)
        XCTAssertNotNil(result.factorBreakdown?.hrvComponent)
        XCTAssertNotNil(result.factorBreakdown?.hrComponent)
        XCTAssertNil(result.factorBreakdown?.sleepComponent, "No sleep data → nil sleep component")
    }

    func testAllFactorsNil_throwsNoData() async {
        let emptyContext = StressContext(baseline: baseline)
        do {
            _ = try await calculator.calculateMultiFactorStress(context: emptyContext)
            XCTFail("Should throw StressError.noData")
        } catch StressError.noData {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Weight redistribution

    func testMissingFactors_dataCompletenessReflectsAvailability() async throws {
        // Only HRV + HR: weight = 0.40 + 0.15 = 0.55 / 1.0
        let result = try await calculator.calculateMultiFactorStress(context: makeContext())
        XCTAssertEqual(result.factorBreakdown!.dataCompleteness, 0.55, accuracy: 0.05)
    }

    func testAllFactors_fullDataCompleteness() async throws {
        let sleep = SleepData(totalSleepHours: 7, deepSleepHours: 1, remSleepHours: 1.5,
                              coreSleepHours: 3, awakenings: 2, timeInBedHours: 7.8,
                              sleepEfficiency: 0.9, analysisDate: Date())
        let activity = ActivityData(stepCount: 8000, activeEnergyKcal: 250, standHours: 8,
                                    lastWorkoutEndTime: nil, lastWorkoutDurationMinutes: nil,
                                    analysisDate: Date())
        let recovery = RecoveryData(respiratoryRate: 15, bloodOxygen: 98, restingHeartRate: 58,
                                    restingHRTrend: 1.0, analysisDate: Date())
        let context = StressContext(baseline: baseline, hrv: 45, heartRate: 65,
                                    sleepData: sleep, activityData: activity, recoveryData: recovery)

        let result = try await calculator.calculateMultiFactorStress(context: context)
        XCTAssertEqual(result.factorBreakdown!.dataCompleteness, 1.0, accuracy: 0.01)
        XCTAssertNotNil(result.factorBreakdown?.sleepComponent)
        XCTAssertNotNil(result.factorBreakdown?.activityComponent)
        XCTAssertNotNil(result.factorBreakdown?.recoveryComponent)
    }

    // MARK: - Stress level ordering

    func testHighStressInputs_higherLevelThanLow() async throws {
        let lowStressContext = StressContext(baseline: baseline, hrv: 60, heartRate: 55)
        let highStressContext = StressContext(baseline: baseline, hrv: 15, heartRate: 110)

        let low = try await calculator.calculateMultiFactorStress(context: lowStressContext)
        let high = try await calculator.calculateMultiFactorStress(context: highStressContext)

        XCTAssertLessThan(low.level, high.level, "Better physiology → lower stress level")
    }

    // MARK: - Backward compatibility

    func testLegacyCalculateStress_stillWorks() async throws {
        let result = try await calculator.calculateStress(hrv: 50, heartRate: 70)
        XCTAssertGreaterThanOrEqual(result.level, 0)
        XCTAssertLessThanOrEqual(result.level, 100)
    }
}
