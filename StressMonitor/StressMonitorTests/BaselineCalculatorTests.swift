import XCTest
@testable import StressMonitor

final class BaselineCalculatorTests: XCTestCase {

    var calculator: BaselineCalculator!

    override func setUp() {
        super.setUp()
        calculator = BaselineCalculator(minimumSampleCount: 30, timeWindowDays: 30)
    }

    // MARK: - calculateBaseline Tests

    func testCalculateBaselineWithValidSamples() async throws {
        let measurements = (0..<40).map { _ in
            HRVMeasurement(value: Double.random(in: 40...60))
        }

        let baseline = try await calculator.calculateBaseline(from: measurements)

        XCTAssertGreaterThan(baseline.baselineHRV, 0)
        XCTAssertEqual(baseline.restingHeartRate, 60)
    }

    func testCalculateBaselineWithInsufficientSamples() async {
        let measurements = (0..<10).map { _ in
            HRVMeasurement(value: 50)
        }

        do {
            _ = try await calculator.calculateBaseline(from: measurements)
            XCTFail("Should throw insufficientSamples error")
        } catch BaselineCalculatorError.insufficientSamples {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCalculateBaselineFiltersOutliers() async throws {
        var measurements = (0..<35).map { _ in
            HRVMeasurement(value: Double.random(in: 40...60))
        }

        measurements.append(HRVMeasurement(value: 200))
        measurements.append(HRVMeasurement(value: 5))

        let baseline = try await calculator.calculateBaseline(from: measurements)

        XCTAssertGreaterThan(baseline.baselineHRV, 40)
        XCTAssertLessThan(baseline.baselineHRV, 60)
    }

    // MARK: - calculateRestingHeartRate Tests

    func testCalculateRestingHeartRate() {
        let samples = [
            HeartRateSample(value: 80),
            HeartRateSample(value: 75),
            HeartRateSample(value: 70),
            HeartRateSample(value: 65),
            HeartRateSample(value: 60),
            HeartRateSample(value: 58),
            HeartRateSample(value: 55),
            HeartRateSample(value: 52),
            HeartRateSample(value: 50),
            HeartRateSample(value: 48),
            HeartRateSample(value: 45)
        ]

        let restingHR = calculator.calculateRestingHeartRate(from: samples)
        XCTAssertEqual(restingHR, 48, accuracy: 1)
    }

    func testCalculateRestingHeartRateWithFewSamples() {
        let samples = [
            HeartRateSample(value: 60),
            HeartRateSample(value: 65)
        ]

        let restingHR = calculator.calculateRestingHeartRate(from: samples)
        XCTAssertEqual(restingHR, 60)
    }

    // MARK: - shouldUpdateBaseline Tests

    func testShouldUpdateBaselineAfterWeek() {
        let lastUpdate = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        XCTAssertTrue(calculator.shouldUpdateBaseline(lastUpdate: lastUpdate, samples: 5))
    }

    func testShouldNotUpdateBaselineRecentlyUpdated() {
        let lastUpdate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        XCTAssertFalse(calculator.shouldUpdateBaseline(lastUpdate: lastUpdate, samples: 5))
    }

    func testShouldUpdateBaselineWithManyNewSamples() {
        let lastUpdate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        XCTAssertTrue(calculator.shouldUpdateBaseline(lastUpdate: lastUpdate, samples: 15))
    }

    // MARK: - filterOutliers Tests

    func testFilterOutliers() {
        let measurements = [
            HRVMeasurement(value: 45),
            HRVMeasurement(value: 48),
            HRVMeasurement(value: 50),
            HRVMeasurement(value: 52),
            HRVMeasurement(value: 55),
            HRVMeasurement(value: 200),
            HRVMeasurement(value: 5)
        ]

        let filtered = calculator.filterOutliers(measurements)

        XCTAssertFalse(filtered.contains(where: { $0.value == 200 }))
        XCTAssertFalse(filtered.contains(where: { $0.value == 5 }))
        XCTAssertEqual(filtered.count, 5)
    }

    func testFilterOutliersWithSmallDataset() {
        let measurements = [
            HRVMeasurement(value: 45),
            HRVMeasurement(value: 50),
            HRVMeasurement(value: 55)
        ]

        let filtered = calculator.filterOutliers(measurements)
        XCTAssertEqual(filtered.count, 3)
    }

    // MARK: - Circadian Adjustment Tests

    func testCircadianAdjustment_PeakAt6AM() {
        // cos(0) = 1 → maximum adjustment: 1.0 + 0.1 = 1.1
        let adjustment = calculator.circadianAdjustment(for: 6)
        XCTAssertEqual(adjustment, 1.1, accuracy: 0.001, "HRV peaks at 6 AM (10% above baseline)")
    }

    func testCircadianAdjustment_TroughAt18() {
        // hour 18: cos((18-6)*π/12) = cos(π) = -1 → 1.0 + 0.1*(-1) = 0.9
        let adjustment = calculator.circadianAdjustment(for: 18)
        XCTAssertEqual(adjustment, 0.9, accuracy: 0.001, "HRV trough at 6 PM (10% below baseline)")
    }

    func testCircadianAdjustment_Midday() {
        // hour 12: cos((12-6)*π/12) = cos(π/2) = 0 → 1.0
        let adjustment = calculator.circadianAdjustment(for: 12)
        XCTAssertEqual(adjustment, 1.0, accuracy: 0.001, "Midday = neutral adjustment")
    }

    func testCircadianAdjustment_RangeIsValid() {
        for hour in 0..<24 {
            let adjustment = calculator.circadianAdjustment(for: hour)
            XCTAssertGreaterThanOrEqual(adjustment, 0.9, "Adjustment must be >= 0.9")
            XCTAssertLessThanOrEqual(adjustment, 1.1, "Adjustment must be <= 1.1")
        }
    }
}
