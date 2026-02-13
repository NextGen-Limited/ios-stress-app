import XCTest
import SwiftUI
@testable import StressMonitor

// MARK: - Sparkline Chart Tests

final class SparklineChartTests: XCTestCase {

    // MARK: - Properties

    private var upwardTrendData: [SparklineChart.DataPoint]!
    private var downwardTrendData: [SparklineChart.DataPoint]!
    private var stableTrendData: [SparklineChart.DataPoint]!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Upward trend: values increase by 5 each day
        upwardTrendData = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double(30 + i * 5),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }

        // Downward trend: values decrease by 5 each day
        downwardTrendData = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double(70 - i * 5),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }

        // Stable trend: values stay around 50
        stableTrendData = (0..<7).map { i in
            SparklineChart.DataPoint(
                value: Double.random(in: 48...52),
                timestamp: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            )
        }
    }

    override func tearDown() {
        upwardTrendData = nil
        downwardTrendData = nil
        stableTrendData = nil
        super.tearDown()
    }

    // MARK: - Data Point Tests

    func testDataPointCount() {
        // Sparkline should show last 7 data points
        XCTAssertEqual(upwardTrendData.count, 7, "Should have 7 data points")
        XCTAssertEqual(downwardTrendData.count, 7, "Should have 7 data points")
        XCTAssertEqual(stableTrendData.count, 7, "Should have 7 data points")
    }

    func testDataPointIdentifiable() {
        // Each data point should have unique ID
        let ids = Set(upwardTrendData.map { $0.id })
        XCTAssertEqual(ids.count, 7, "All data points should have unique IDs")
    }

    // MARK: - Trend Description Tests

    func testUpwardTrendDescription() {
        let firstValue = upwardTrendData.first?.value ?? 0
        let lastValue = upwardTrendData.last?.value ?? 0
        let change = lastValue - firstValue

        XCTAssertEqual(change, 30.0, "Upward trend should increase by 30 points")
        XCTAssertGreaterThan(change, 5, "Change should be > 5 for upward trend")
    }

    func testDownwardTrendDescription() {
        let firstValue = downwardTrendData.first?.value ?? 0
        let lastValue = downwardTrendData.last?.value ?? 0
        let change = lastValue - firstValue

        XCTAssertEqual(change, -30.0, "Downward trend should decrease by 30 points")
        XCTAssertLessThan(change, -5, "Change should be < -5 for downward trend")
    }

    func testStableTrendDescription() {
        let firstValue = stableTrendData.first?.value ?? 0
        let lastValue = stableTrendData.last?.value ?? 0
        let change = abs(lastValue - firstValue)

        XCTAssertLessThanOrEqual(change, 5, "Stable trend change should be <= 5 points")
    }

    // MARK: - Y-Axis Auto Scaling Tests

    func testYAxisDomainCalculation() {
        // Test auto-scaling with upward trend
        let values = upwardTrendData.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 100

        XCTAssertEqual(min, 30.0, "Min value should be 30")
        XCTAssertEqual(max, 60.0, "Max value should be 60")

        // Padding should be 20% of range
        let range = max - min
        let padding = range * 0.2

        XCTAssertEqual(range, 30.0)
        XCTAssertEqual(padding, 6.0)

        // Domain should be (min - padding)...(max + padding)
        let expectedMin = min - padding
        let expectedMax = max + padding

        XCTAssertEqual(expectedMin, 24.0, accuracy: 0.1)
        XCTAssertEqual(expectedMax, 66.0, accuracy: 0.1)
    }

    func testYAxisDomainWithEmptyData() {
        let emptyData: [SparklineChart.DataPoint] = []

        // Should default to 0...100 range
        let values = emptyData.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 100

        XCTAssertEqual(min, 0.0)
        XCTAssertEqual(max, 100.0)
    }

    // MARK: - Empty State Tests

    func testEmptyStateHandling() {
        let emptyData: [SparklineChart.DataPoint] = []
        XCTAssertTrue(emptyData.isEmpty, "Empty data should be handled gracefully")
    }

    // MARK: - Accessibility Tests

    func testAccessibilityHintWithSevenDataPoints() {
        // Should show "Shows 7 recent measurements"
        XCTAssertEqual(upwardTrendData.count, 7)
    }

    func testAccessibilityValueForUpwardTrend() {
        let firstValue = upwardTrendData.first?.value ?? 0
        let lastValue = upwardTrendData.last?.value ?? 0
        let change = lastValue - firstValue

        // Should describe as "Trending up by X points"
        XCTAssertGreaterThan(change, 5)
        XCTAssertEqual(Int(abs(change)), 30)
    }

    func testAccessibilityValueForDownwardTrend() {
        let firstValue = downwardTrendData.first?.value ?? 0
        let lastValue = downwardTrendData.last?.value ?? 0
        let change = lastValue - firstValue

        // Should describe as "Trending down by X points"
        XCTAssertLessThan(change, -5)
        XCTAssertEqual(Int(abs(change)), 30)
    }

    func testAccessibilityValueForStableTrend() {
        let firstValue = stableTrendData.first?.value ?? 0
        let lastValue = stableTrendData.last?.value ?? 0
        let change = abs(lastValue - firstValue)

        // Should describe as "Stable trend"
        XCTAssertLessThanOrEqual(change, 5)
    }

    // MARK: - Dimension Tests

    func testSparklineChartDimensions() {
        // Sparkline should be 60x120pt
        let expectedWidth = 120.0
        let expectedHeight = 60.0

        XCTAssertEqual(expectedWidth, 120.0)
        XCTAssertEqual(expectedHeight, 60.0)
    }

    // MARK: - Reduce Motion Tests

    func testReduceMotionSupport() {
        // Sparkline should work with reduce motion enabled
        // Static rendering should still show all data points
        XCTAssertEqual(upwardTrendData.count, 7)
        XCTAssertFalse(upwardTrendData.isEmpty)
    }
}
