import XCTest
@testable import StressMonitor

// MARK: - BioAgeCalculatorTests

final class BioAgeCalculatorTests: XCTestCase {

    private var calculator: BioAgeCalculator!

    override func setUp() {
        super.setUp()
        calculator = BioAgeCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Basic Calculation Tests

    func testCalculateWithGoodHRVReturnsYoungerAge() {
        // 35-year-old with HRV well above age norm (52ms expected, 70ms actual)
        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 70,
            restingHeartRate: 62,
            sleepEfficiency: 0.90
        )

        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.estimatedAge, 35,
                         "High HRV with low RHR should estimate younger bio age")
    }

    func testCalculateWithPoorHRVReturnsOlderAge() {
        // 35-year-old with very low HRV (20ms vs 52ms expected)
        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 20,
            restingHeartRate: 80,
            sleepEfficiency: 0.70
        )

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.estimatedAge, 35,
                            "Low HRV with high RHR should estimate older bio age")
    }

    func testCalculateWithAverageInputsReturnsNearChronological() {
        // HRV and RHR at age-expected norms
        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 52,
            restingHeartRate: 65,
            sleepEfficiency: 0.85
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.estimatedAge, 35,
                       "Age-matched inputs should estimate chronological age")
    }

    // MARK: - Edge Case Tests

    func testCalculateWithNilHRVReturnsResultFromRHR() {
        let result = calculator.calculate(
            chronologicalAge: 40,
            hrv: nil,
            restingHeartRate: 66,
            sleepEfficiency: nil
        )

        XCTAssertNotNil(result, "Should calculate with partial data (RHR only)")
    }

    func testCalculateWithAllNilReturnsNil() {
        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: nil,
            restingHeartRate: nil,
            sleepEfficiency: nil
        )

        XCTAssertNil(result, "Should return nil when no factors available")
    }

    func testCalculateWithZeroAgeReturnsNil() {
        let result = calculator.calculate(
            chronologicalAge: 0,
            hrv: 50,
            restingHeartRate: 65,
            sleepEfficiency: 0.85
        )

        XCTAssertNil(result, "Should return nil for age <= 0")
    }

    func testCalculateMinimumAgeFloor() {
        // Extremely good health should not estimate below 18
        let result = calculator.calculate(
            chronologicalAge: 25,
            hrv: 200,
            restingHeartRate: 40,
            sleepEfficiency: 0.99
        )

        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result!.estimatedAge, 18,
                                    "Bio age should not go below 18")
    }

    // MARK: - Difference Property Tests

    func testDifferenceIsNegativeWhenYounger() {
        let result = calculator.calculate(
            chronologicalAge: 40,
            hrv: 70,
            restingHeartRate: 58,
            sleepEfficiency: 0.92
        )

        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.difference, 0,
                         "Younger bio age should have negative difference")
    }

    func testDifferenceIsPositiveWhenOlder() {
        let result = calculator.calculate(
            chronologicalAge: 25,
            hrv: 20,
            restingHeartRate: 85,
            sleepEfficiency: 0.65
        )

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.difference, 0,
                            "Older bio age should have positive difference")
    }

    func testDifferenceEqualsEstimatedMinusChronological() {
        let result = calculator.calculate(
            chronologicalAge: 30,
            hrv: 55,
            restingHeartRate: 64,
            sleepEfficiency: 0.85
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.difference, result!.estimatedAge - result!.chronologicalAge)
    }

    // MARK: - Trend Tests

    func testTrendStableWithNoPreviousResult() {
        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 52,
            restingHeartRate: 65,
            sleepEfficiency: 0.85,
            previousResult: nil
        )

        XCTAssertEqual(result?.trend, .stable,
                       "Trend should be stable when no previous result")
    }

    func testTrendImprovingWhenAgeDecreases() {
        let previous = BioAgeResult(
            estimatedAge: 40,
            chronologicalAge: 35,
            trend: .stable
        )

        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 75,
            restingHeartRate: 58,
            sleepEfficiency: 0.92,
            previousResult: previous
        )

        XCTAssertEqual(result?.trend, .improving)
    }

    func testTrendDecliningWhenAgeIncreases() {
        let previous = BioAgeResult(
            estimatedAge: 32,
            chronologicalAge: 35,
            trend: .stable
        )

        let result = calculator.calculate(
            chronologicalAge: 35,
            hrv: 25,
            restingHeartRate: 78,
            sleepEfficiency: 0.68,
            previousResult: previous
        )

        XCTAssertEqual(result?.trend, .declining)
    }

    // MARK: - Data Sufficiency Tests

    func testHasEnoughDataReturnsFalseForFewerThan7Days() {
        let measurements = (0..<5).map { i in
            StressMeasurement(
                timestamp: Date().addingTimeInterval(-Double(i) * 86400),
                stressLevel: 30,
                hrv: 50,
                restingHeartRate: 65
            )
        }

        XCTAssertFalse(calculator.hasEnoughData(measurements: measurements))
    }

    func testHasEnoughDataReturnsTrueFor7PlusDays() {
        let measurements = (0..<8).map { i in
            StressMeasurement(
                timestamp: Date().addingTimeInterval(-Double(i) * 86400),
                stressLevel: 30,
                hrv: 50,
                restingHeartRate: 65
            )
        }

        XCTAssertTrue(calculator.hasEnoughData(measurements: measurements))
    }

    // MARK: - Age-Group Norm Tests

    func testDifferentAgeGroupsProduceDifferentEstimates() {
        // Same health metrics, different chronological ages
        let youngResult = calculator.calculate(
            chronologicalAge: 25,
            hrv: 50,
            restingHeartRate: 65,
            sleepEfficiency: 0.85
        )

        let oldResult = calculator.calculate(
            chronologicalAge: 60,
            hrv: 50,
            restingHeartRate: 65,
            sleepEfficiency: 0.85
        )

        XCTAssertNotNil(youngResult)
        XCTAssertNotNil(oldResult)
        // 50ms HRV is above the norm for a 25yo (65ms expected) but
        // at/above norm for a 60yo (34ms expected) — different deltas
        XCTAssertNotEqual(
            youngResult!.estimatedAge - 25,
            oldResult!.estimatedAge - 60,
            "Same metrics should produce different bio-age deltas for different age groups"
        )
    }

    // MARK: - BioAgeResult Model Tests

    func testCharacterExpressionIsCelebratoryWhenYounger() {
        let result = BioAgeResult(
            estimatedAge: 25,
            chronologicalAge: 40,
            trend: .improving
        )

        XCTAssertTrue(result.isCelebratory)
        XCTAssertFalse(result.characterExpression.isEmpty)
    }

    func testCharacterExpressionWhenOlder() {
        let result = BioAgeResult(
            estimatedAge: 45,
            chronologicalAge: 35,
            trend: .stable
        )

        XCTAssertFalse(result.isCelebratory)
        XCTAssertFalse(result.characterExpression.isEmpty)
    }

    func testDifferenceLabelFormatsCorrectly() {
        let younger = BioAgeResult(
            estimatedAge: 28,
            chronologicalAge: 35,
            trend: .improving
        )
        XCTAssertEqual(younger.differenceLabel, "7 years younger")

        let older = BioAgeResult(
            estimatedAge: 40,
            chronologicalAge: 35,
            trend: .stable
        )
        XCTAssertEqual(older.differenceLabel, "5 years older")

        let equal = BioAgeResult(
            estimatedAge: 35,
            chronologicalAge: 35,
            trend: .stable
        )
        XCTAssertEqual(equal.differenceLabel, "On par")
    }

    func testSingleYearLabelUsesSingular() {
        let result = BioAgeResult(
            estimatedAge: 34,
            chronologicalAge: 35,
            trend: .stable
        )
        XCTAssertEqual(result.differenceLabel, "1 year younger")
    }

    // MARK: - StressContext Convenience Tests

    func testCalculateFromStressContext() {
        let baseline = PersonalBaseline(
            restingHeartRate: 62,
            baselineHRV: 55
        )

        let sleepData = SleepData(
            totalSleepHours: 7.5,
            deepSleepHours: 1.5,
            remSleepHours: 1.5,
            coreSleepHours: 4.5,
            awakenings: 1,
            timeInBedHours: 8.0,
            sleepEfficiency: 0.90,
            analysisDate: Date()
        )

        let context = StressContext(
            baseline: baseline,
            hrv: 58,
            heartRate: 62,
            sleepData: sleepData
        )

        let result = calculator.calculate(
            from: context,
            chronologicalAge: 35
        )

        XCTAssertNotNil(result)
    }
}
