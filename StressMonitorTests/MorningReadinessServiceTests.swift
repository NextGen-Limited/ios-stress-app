import XCTest
@testable import StressMonitor

final class MorningReadinessServiceTests: XCTestCase {
    
    // MARK: - Score Computation Tests
    
    func testComputeScoreAtBaseline() {
        // When morning HRV equals baseline, score should be ~50
        let score = MorningReadinessService.computeScore(morningHRV: 60, baseline: 60)
        XCTAssertEqual(score, 50, accuracy: 1, "Score at baseline should be ~50")
    }
    
    func testComputeScoreAboveBaseline() {
        // When morning HRV is 30% above baseline, score should be ~80
        let score = MorningReadinessService.computeScore(morningHRV: 78, baseline: 60)
        XCTAssertGreaterThan(score, 70, "Score above baseline should be > 70")
    }
    
    func testComputeScoreBelowBaseline() {
        // When morning HRV is 30% below baseline, score should be ~20
        let score = MorningReadinessService.computeScore(morningHRV: 42, baseline: 60)
        XCTAssertLessThan(score, 30, "Score below baseline should be < 30")
    }
    
    func testComputeScoreNormalized() {
        // Score should always be between 0 and 100
        let score1 = MorningReadinessService.computeScore(morningHRV: 0, baseline: 60)
        let score2 = MorningReadinessService.computeScore(morningHRV: 200, baseline: 60)
        
        XCTAssertGreaterThanOrEqual(score1, 0)
        XCTAssertLessThanOrEqual(score1, 100)
        XCTAssertGreaterThanOrEqual(score2, 0)
        XCTAssertLessThanOrEqual(score2, 100)
    }
    
    func testComputeScoreWithZeroBaseline() {
        // Should handle zero baseline gracefully
        let score = MorningReadinessService.computeScore(morningHRV: 60, baseline: 0)
        XCTAssertEqual(score, 50, "Should return 50 for zero baseline")
    }
    
    // MARK: - Categorization Tests
    
    func testCategorizeLow() {
        let level = MorningReadinessService.categorize(score: 15)
        XCTAssertEqual(level, .low)
    }
    
    func testCategorizeModerate() {
        let level = MorningReadinessService.categorize(score: 35)
        XCTAssertEqual(level, .moderate)
    }
    
    func testCategorizeGood() {
        let level = MorningReadinessService.categorize(score: 60)
        XCTAssertEqual(level, .good)
    }
    
    func testCategorizeExcellent() {
        let level = MorningReadinessService.categorize(score: 85)
        XCTAssertEqual(level, .excellent)
    }
    
    // MARK: - ReadinessLevel Tests
    
    func testReadinessLevelEmoji() {
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.noData.emoji, "—")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.low.emoji, "🔴")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.moderate.emoji, "🟠")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.good.emoji, "🟢")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.excellent.emoji, "💚")
    }
    
    func testReadinessLevelColor() {
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.noData.color, "gray")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.low.color, "red")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.moderate.color, "orange")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.good.color, "green")
        XCTAssertEqual(MorningReadinessService.ReadinessLevel.excellent.color, "mint")
    }
    
    func testReadinessLevelAdvice() {
        // All levels should have non-empty advice
        for level in MorningReadinessService.ReadinessLevel.allCases {
            XCTAssertFalse(level.advice.isEmpty, "Advice for \(level.rawValue) should not be empty")
        }
    }
    
    // MARK: - Configuration Tests
    
    func testMorningWindow() {
        XCTAssertEqual(MorningReadinessService.morningStartHour, 4)
        XCTAssertEqual(MorningReadinessService.morningEndHour, 10)
    }
    
    func testBaselineDays() {
        XCTAssertEqual(MorningReadinessService.baselineDays, 7)
    }
    
    // MARK: - Data Model Tests
    
    func testDailyHRVPoint() {
        let date = Date()
        let point = MorningReadinessService.DailyHRVPoint(date: date, hrv: 65, isToday: true)
        
        XCTAssertEqual(point.date, date)
        XCTAssertEqual(point.hrv, 65)
        XCTAssertTrue(point.isToday)
    }
    
    func testDailyHRVPointIdentifiable() {
        let point1 = MorningReadinessService.DailyHRVPoint(date: Date(), hrv: 60, isToday: false)
        let point2 = MorningReadinessService.DailyHRVPoint(date: Date(), hrv: 65, isToday: true)
        
        XCTAssertNotEqual(point1.id, point2.id)
    }
    
    func testReadinessInsight() {
        let insight = MorningReadinessService.ReadinessInsight(
            icon: "arrow.up.circle.fill",
            title: "Above Baseline",
            detail: "Your HRV is above average"
        )
        
        XCTAssertEqual(insight.icon, "arrow.up.circle.fill")
        XCTAssertEqual(insight.title, "Above Baseline")
        XCTAssertEqual(insight.detail, "Your HRV is above average")
    }
    
    // MARK: - Edge Cases
    
    func testScoreSymmetry() {
        // Score for +30% and -30% deviation should be roughly symmetric around 50
        let highScore = MorningReadinessService.computeScore(morningHRV: 78, baseline: 60) // +30%
        let lowScore = MorningReadinessService.computeScore(morningHRV: 42, baseline: 60)  // -30%
        
        let highDeviation = highScore - 50
        let lowDeviation = 50 - lowScore
        
        // Should be roughly symmetric (within 5 points)
        XCTAssertEqual(highDeviation, lowDeviation, accuracy: 5, "Score should be symmetric around baseline")
    }
    
    func testMonotonicity() {
        // Higher HRV should always produce higher score
        let scores = [40, 50, 60, 70, 80].map { hrv in
            MorningReadinessService.computeScore(morningHRV: Double(hrv), baseline: 60)
        }
        
        for i in 1..<scores.count {
            XCTAssertGreaterThan(scores[i], scores[i-1], "Score should increase with HRV")
        }
    }
}
