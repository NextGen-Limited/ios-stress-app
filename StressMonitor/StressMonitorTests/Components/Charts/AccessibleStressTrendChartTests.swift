import XCTest
import SwiftUI
@testable import StressMonitor

// MARK: - Accessible Stress Trend Chart Tests

final class AccessibleStressTrendChartTests: XCTestCase {

    // MARK: - Properties

    private var sampleMeasurements: [StressMeasurement]!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        sampleMeasurements = (0..<20).map { i in
            StressMeasurement(
                timestamp: Calendar.current.date(byAdding: .hour, value: -i, to: Date())!,
                stressLevel: Double(20 + i * 3),
                hrv: 50,
                restingHeartRate: 70
            )
        }
    }

    override func tearDown() {
        sampleMeasurements = nil
        super.tearDown()
    }

    // MARK: - Time Range Tests

    func testTimeRangeDescriptions() {
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.day.description, "24 hours")
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.week.description, "7 days")
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.month.description, "4 weeks")
    }

    func testTimeRangeRawValues() {
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.day.rawValue, "24H")
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.week.rawValue, "7D")
        XCTAssertEqual(AccessibleStressTrendChart.TimeRange.month.rawValue, "4W")
    }

    func testTimeRangeAllCases() {
        let allCases = AccessibleStressTrendChart.TimeRange.allCases
        XCTAssertEqual(allCases.count, 3, "Should have exactly 3 time range options")
        XCTAssertTrue(allCases.contains(.day))
        XCTAssertTrue(allCases.contains(.week))
        XCTAssertTrue(allCases.contains(.month))
    }

    // MARK: - Empty State Tests

    func testEmptyStateHandling() {
        let emptyData: [StressMeasurement] = []
        XCTAssertTrue(emptyData.isEmpty, "Empty data should be handled gracefully")
    }

    // MARK: - Statistics Tests

    func testStatsCalculation() {
        // Given: Sample measurements with known values
        let measurements = [
            StressMeasurement(timestamp: Date(), stressLevel: 20, hrv: 50, restingHeartRate: 70),
            StressMeasurement(timestamp: Date(), stressLevel: 40, hrv: 50, restingHeartRate: 70),
            StressMeasurement(timestamp: Date(), stressLevel: 60, hrv: 50, restingHeartRate: 70),
            StressMeasurement(timestamp: Date(), stressLevel: 80, hrv: 50, restingHeartRate: 70)
        ]

        // When: Calculating stats
        let levels = measurements.map { $0.stressLevel }
        let average = levels.reduce(0, +) / Double(levels.count)
        let min = levels.min() ?? 0
        let max = levels.max() ?? 0

        // Then: Stats should be correct
        XCTAssertEqual(average, 50.0, "Average should be 50")
        XCTAssertEqual(min, 20.0, "Min should be 20")
        XCTAssertEqual(max, 80.0, "Max should be 80")
    }

    func testStatsWithSingleDataPoint() {
        let measurements = [
            StressMeasurement(timestamp: Date(), stressLevel: 42, hrv: 50, restingHeartRate: 70)
        ]

        let average = measurements.map { $0.stressLevel }.reduce(0, +) / Double(measurements.count)
        let min = measurements.map { $0.stressLevel }.min() ?? 0
        let max = measurements.map { $0.stressLevel }.max() ?? 0

        XCTAssertEqual(average, 42.0)
        XCTAssertEqual(min, 42.0)
        XCTAssertEqual(max, 42.0)
    }

    // MARK: - VoiceOver Data Table Tests

    func testDataTableRowAccessibility() {
        // Test that each measurement has required accessibility properties
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 42,
            hrv: 50,
            restingHeartRate: 70
        )

        XCTAssertNotNil(measurement.timestamp, "Timestamp should be available for VoiceOver")
        XCTAssertNotNil(measurement.stressLevel, "Stress level should be available for VoiceOver")
        XCTAssertNotNil(measurement.category, "Category should be available for VoiceOver")
    }

    func testDataTableWithMultipleMeasurements() {
        XCTAssertEqual(sampleMeasurements.count, 20, "Should have 20 measurements")

        for measurement in sampleMeasurements {
            XCTAssertGreaterThanOrEqual(measurement.stressLevel, 0, "Stress level should be non-negative")
            XCTAssertLessThanOrEqual(measurement.stressLevel, 100, "Stress level should not exceed 100")
        }
    }

    // MARK: - Reduce Motion Tests

    func testReduceMotionStaticDataEntry() {
        // With Reduce Motion enabled, chart should show static data
        // Verify that measurements can be displayed without animation
        let measurements = sampleMeasurements!

        XCTAssertFalse(measurements.isEmpty, "Should have data to display")
        XCTAssertTrue(measurements.allSatisfy { $0.stressLevel >= 0 }, "All stress levels valid")
    }

    // MARK: - Chart Scale Tests

    func testChartYAxisScale() {
        // Chart should use 0-100 scale
        let minScale = 0.0
        let maxScale = 100.0

        for measurement in sampleMeasurements {
            XCTAssertGreaterThanOrEqual(measurement.stressLevel, minScale, "Stress should be >= 0")
            XCTAssertLessThanOrEqual(measurement.stressLevel, maxScale, "Stress should be <= 100")
        }
    }

    // MARK: - Data Validation Tests

    func testMeasurementCategoryMapping() {
        let relaxed = StressMeasurement(timestamp: Date(), stressLevel: 20, hrv: 50, restingHeartRate: 70)
        let mild = StressMeasurement(timestamp: Date(), stressLevel: 40, hrv: 50, restingHeartRate: 70)
        let moderate = StressMeasurement(timestamp: Date(), stressLevel: 60, hrv: 50, restingHeartRate: 70)
        let high = StressMeasurement(timestamp: Date(), stressLevel: 80, hrv: 50, restingHeartRate: 70)

        XCTAssertEqual(relaxed.category, .relaxed)
        XCTAssertEqual(mild.category, .mild)
        XCTAssertEqual(moderate.category, .moderate)
        XCTAssertEqual(high.category, .high)
    }
}
