import XCTest
@testable import StressMonitor

final class StressPredictorTests: XCTestCase {
    
    var predictor: StressPredictor!
    
    override func setUp() {
        super.setUp()
        predictor = StressPredictor()
    }
    
    override func tearDown() {
        predictor = nil
        super.tearDown()
    }
    
    // MARK: - Quick Score Tests
    
    func testQuickScoreWithNormalValues() {
        let score = predictor.quickScore(hrvSDNN: 60, heartRate: 70)
        XCTAssertGreaterThanOrEqual(score, 0, "Score should be >= 0")
        XCTAssertLessThanOrEqual(score, 1, "Score should be <= 1")
    }
    
    func testQuickScoreUpdatesCurrentScore() {
        let score = predictor.quickScore(hrvSDNN: 45, heartRate: 85)
        XCTAssertEqual(predictor.currentScore, score, "currentScore should match returned score")
    }
    
    func testQuickScoreUpdatesCategory() {
        // High stress scenario
        _ = predictor.quickScore(hrvSDNN: 20, heartRate: 120)
        XCTAssertEqual(predictor.currentCategory, .veryHigh, "Should categorize as very high stress")
        
        // Low stress scenario
        _ = predictor.quickScore(hrvSDNN: 80, heartRate: 60)
        XCTAssertEqual(predictor.currentCategory, .resting, "Should categorize as resting")
    }
    
    func testQuickScoreTracksRecentScores() {
        _ = predictor.quickScore(hrvSDNN: 50, heartRate: 70)
        _ = predictor.quickScore(hrvSDNN: 55, heartRate: 72)
        _ = predictor.quickScore(hrvSDNN: 60, heartRate: 68)
        
        XCTAssertEqual(predictor.recentScores.count, 3, "Should track 3 recent scores")
    }
    
    func testQuickScoreLimitsRecentScores() {
        // Add more than maxRecentScores (100)
        for i in 0..<110 {
            _ = predictor.quickScore(hrvSDNN: Double(50 + i % 30), heartRate: 70)
        }
        
        XCTAssertLessThanOrEqual(predictor.recentScores.count, 100, "Should limit to 100 recent scores")
    }
    
    // MARK: - Baseline Tests
    
    func testUpdateBaselines() {
        predictor.updateBaselines(averageHRV: 75, averageHeartRate: 62)
        XCTAssertEqual(predictor.baselineHRV, 75, "Baseline HRV should be updated")
        XCTAssertEqual(predictor.baselineHeartRate, 62, "Baseline HR should be updated")
    }
    
    // MARK: - Trend Tests
    
    func testTrendSlopeWithInsufficientData() {
        // Need at least 3 scores for trend
        _ = predictor.quickScore(hrvSDNN: 50, heartRate: 70)
        _ = predictor.quickScore(hrvSDNN: 55, heartRate: 72)
        
        XCTAssertEqual(predictor.trendSlope, 0, "Trend should be 0 with insufficient data")
    }
    
    func testTrendSlopeIncreasing() {
        // Add increasing stress scores
        for i in 0..<10 {
            _ = predictor.quickScore(hrvSDNN: Double(80 - i * 5), heartRate: Double(60 + i * 5))
        }
        
        XCTAssertGreaterThan(predictor.trendSlope, 0, "Trend should be positive for increasing stress")
    }
    
    func testTrendSlopeDecreasing() {
        // Add decreasing stress scores
        for i in 0..<10 {
            _ = predictor.quickScore(hrvSDNN: Double(40 + i * 5), heartRate: Double(100 - i * 5))
        }
        
        XCTAssertLessThan(predictor.trendSlope, 0, "Trend should be negative for decreasing stress")
    }
    
    // MARK: - Average Score Tests
    
    func testAverageScoreWithNoData() {
        let avg = predictor.averageScore(last: 10)
        XCTAssertEqual(avg, 0, "Average should be 0 with no data")
    }
    
    func testAverageScoreCalculation() {
        _ = predictor.quickScore(hrvSDNN: 50, heartRate: 70)  // ~0.3
        _ = predictor.quickScore(hrvSDNN: 60, heartRate: 65)  // ~0.2
        _ = predictor.quickScore(hrvSDNN: 40, heartRate: 80)  // ~0.4
        
        let avg = predictor.averageScore(last: 3)
        XCTAssertGreaterThan(avg, 0, "Average should be positive")
        XCTAssertLessThan(avg, 1, "Average should be less than 1")
    }
    
    func testAverageScoreWithSubset() {
        // Add 10 scores
        for _ in 0..<10 {
            _ = predictor.quickScore(hrvSDNN: 50, heartRate: 70)
        }
        
        let avg5 = predictor.averageScore(last: 5)
        let avg10 = predictor.averageScore(last: 10)
        
        // Both should be valid
        XCTAssertGreaterThanOrEqual(avg5, 0)
        XCTAssertLessThanOrEqual(avg5, 1)
        XCTAssertGreaterThanOrEqual(avg10, 0)
        XCTAssertLessThanOrEqual(avg10, 1)
    }
    
    // MARK: - Real-time Analysis Tests
    
    func testAnalyzeRealTimeWithValidData() {
        let rrIntervals = generateRRIntervals(count: 50, mean: 800, sd: 50)
        let result = predictor.analyzeRealTime(rrIntervals: rrIntervals)
        
        XCTAssertNotNil(result, "Should return result for valid input")
        XCTAssertEqual(predictor.lastAnalysis?.stressScore, predictor.currentScore,
                       "currentScore should match last analysis")
    }
    
    func testAnalyzeRealTimeWithInsufficientData() {
        let rrIntervals: [Double] = [800, 850, 900]
        let result = predictor.analyzeRealTime(rrIntervals: rrIntervals)
        
        XCTAssertNil(result, "Should return nil for insufficient data")
    }
    
    // MARK: - Helper Methods
    
    private func generateRRIntervals(count: Int, mean: Double, sd: Double) -> [Double] {
        var intervals: [Double] = []
        for _ in 0..<count {
            let u1 = Double.random(in: 0...1)
            let u2 = Double.random(in: 0...1)
            let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
            let rr = mean + z * sd
            intervals.append(max(300, min(2000, rr)))
        }
        return intervals
    }
}
