import XCTest
@testable import StressMonitor

final class StressHistoryTests: XCTestCase {
    
    // MARK: - Time Range Tests
    
    func testTimeRangeDays() {
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.day.days, 1)
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.week.days, 7)
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.month.days, 30)
    }
    
    func testTimeRangeRawValues() {
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.day.rawValue, "Day")
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.week.rawValue, "Week")
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.month.rawValue, "Month")
    }
    
    func testTimeRangeAllCases() {
        XCTAssertEqual(StressHistoryView.HistoryTimeRange.allCases.count, 3)
    }
    
    // MARK: - Activity Manager Tests
    
    func testActivityManagerInitialization() {
        let manager = ActivityManager()
        XCTAssertTrue(manager.workouts.isEmpty)
        XCTAssertTrue(manager.correlations.isEmpty)
    }
    
    // MARK: - Daily Stress Summary Tests
    
    func testDailyStressSummary() {
        let summary = DailyStressSummary(
            date: Date(),
            averageStress: 0.45,
            peakStress: 0.78,
            minStress: 0.12,
            readingCount: 50,
            workouts: []
        )
        
        XCTAssertEqual(summary.averageStress, 0.45)
        XCTAssertEqual(summary.peakStress, 0.78)
        XCTAssertEqual(summary.minStress, 0.12)
        XCTAssertEqual(summary.readingCount, 50)
        XCTAssertTrue(summary.workouts.isEmpty)
    }
    
    func testDailyStressSummaryIdentifiable() {
        let summary1 = DailyStressSummary(date: Date(), averageStress: 0.3, peakStress: 0.5, minStress: 0.1, readingCount: 20, workouts: [])
        let summary2 = DailyStressSummary(date: Date().addingTimeInterval(86400), averageStress: 0.4, peakStress: 0.6, minStress: 0.2, readingCount: 25, workouts: [])
        
        XCTAssertNotEqual(summary1.id, summary2.id)
    }
    
    // MARK: - Stress Correlation Tests
    
    func testStressCorrelation() {
        let correlation = StressCorrelation(
            activityType: "Running",
            averageStressBefore: 0.6,
            averageStressAfter: 0.3,
            sampleCount: 10
        )
        
        XCTAssertEqual(correlation.activityType, "Running")
        XCTAssertEqual(correlation.averageStressBefore, 0.6)
        XCTAssertEqual(correlation.averageStressAfter, 0.3)
        XCTAssertEqual(correlation.sampleCount, 10)
    }
    
    func testStressCorrelationStressReduction() {
        let correlation = StressCorrelation(
            activityType: "Yoga",
            averageStressBefore: 0.7,
            averageStressAfter: 0.3,
            sampleCount: 5
        )
        
        let reduction = correlation.averageStressBefore - correlation.averageStressAfter
        XCTAssertGreaterThan(reduction, 0, "Stress should reduce after activity")
    }
}
