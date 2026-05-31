import XCTest
@testable import StressMonitor

final class HRVAnalyzerTests: XCTestCase {
    
    // MARK: - Stress Category Tests
    
    func testStressCategoryRanges() {
        XCTAssertEqual(HRVAnalyzer.StressCategory.resting.range, 0.0...0.2)
        XCTAssertEqual(HRVAnalyzer.StressCategory.low.range, 0.2...0.4)
        XCTAssertEqual(HRVAnalyzer.StressCategory.moderate.range, 0.4...0.6)
        XCTAssertEqual(HRVAnalyzer.StressCategory.high.range, 0.6...0.8)
        XCTAssertEqual(HRVAnalyzer.StressCategory.veryHigh.range, 0.8...1.0)
    }
    
    func testStressCategoryColors() {
        XCTAssertEqual(HRVAnalyzer.StressCategory.resting.color, "green")
        XCTAssertEqual(HRVAnalyzer.StressCategory.low.color, "blue")
        XCTAssertEqual(HRVAnalyzer.StressCategory.moderate.color, "yellow")
        XCTAssertEqual(HRVAnalyzer.StressCategory.high.color, "orange")
        XCTAssertEqual(HRVAnalyzer.StressCategory.veryHigh.color, "red")
    }
    
    // MARK: - Quick Stress Score Tests
    
    func testQuickStressScoreHighHRV() {
        // High HRV (60ms) with normal HR (65bpm) = low stress
        let score = HRVAnalyzer.quickStressScore(hrvSDNN: 60, heartRate: 65, baselineHRV: 60)
        XCTAssertLessThan(score, 0.3, "High HRV should indicate low stress")
    }
    
    func testQuickStressScoreLowHRV() {
        // Low HRV (20ms) with elevated HR (100bpm) = high stress
        let score = HRVAnalyzer.quickStressScore(hrvSDNN: 20, heartRate: 100, baselineHRV: 60)
        XCTAssertGreaterThan(score, 0.5, "Low HRV with high HR should indicate high stress")
    }
    
    func testQuickStressScoreNormalized() {
        // Score should always be between 0 and 1
        let score1 = HRVAnalyzer.quickStressScore(hrvSDNN: 0, heartRate: 200, baselineHRV: 60)
        let score2 = HRVAnalyzer.quickStressScore(hrvSDNN: 200, heartRate: 40, baselineHRV: 60)
        
        XCTAssertGreaterThanOrEqual(score1, 0)
        XCTAssertLessThanOrEqual(score1, 1)
        XCTAssertGreaterThanOrEqual(score2, 0)
        XCTAssertLessThanOrEqual(score2, 1)
    }
    
    func testQuickStressScoreWithDifferentBaselines() {
        // Same HRV but different baselines should produce different scores
        let score1 = HRVAnalyzer.quickStressScore(hrvSDNN: 50, heartRate: 70, baselineHRV: 40)
        let score2 = HRVAnalyzer.quickStressScore(hrvSDNN: 50, heartRate: 70, baselineHRV: 80)
        
        XCTAssertNotEqual(score1, score2, "Different baselines should produce different scores")
    }
    
    // MARK: - Full Analysis Tests
    
    func testAnalyzeWithInsufficientSamples() {
        // Need at least 10 samples for analysis
        let rrIntervals: [Double] = [800, 850, 900]
        let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals)
        XCTAssertNil(result, "Should return nil with insufficient samples")
    }
    
    func testAnalyzeWithValidSamples() {
        // Generate realistic RR intervals (around 800ms = 75bpm)
        let rrIntervals = generateRRIntervals(count: 50, mean: 800, sd: 50)
        let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals)
        
        XCTAssertNotNil(result, "Should return result with valid samples")
        if let result = result {
            XCTAssertGreaterThan(result.timeDomain.sdnn, 0, "SDNN should be positive")
            XCTAssertGreaterThan(result.timeDomain.rmssd, 0, "RMSSD should be positive")
            XCTAssertGreaterThanOrEqual(result.stressScore, 0, "Stress score should be >= 0")
            XCTAssertLessThanOrEqual(result.stressScore, 1, "Stress score should be <= 1")
            XCTAssertGreaterThanOrEqual(result.coherenceScore, 0, "Coherence should be >= 0")
            XCTAssertLessThanOrEqual(result.coherenceScore, 1, "Coherence should be <= 1")
            XCTAssertGreaterThanOrEqual(result.sampleQuality, 0, "Quality should be >= 0")
            XCTAssertLessThanOrEqual(result.sampleQuality, 1, "Quality should be <= 1")
        }
    }
    
    func testAnalyzeWithArtifacts() {
        // Generate RR intervals with some artifacts (extreme values)
        var rrIntervals = generateRRIntervals(count: 50, mean: 800, sd: 50)
        // Add artifacts
        rrIntervals[10] = 2000  // Way too high
        rrIntervals[20] = 300   // Way too low
        
        let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals)
        XCTAssertNotNil(result, "Should handle artifacts gracefully")
        if let result = result {
            XCTAssertGreaterThan(result.sampleQuality, 0, "Quality should be > 0 after artifact removal")
        }
    }
    
    func testAnalyzeStressedVsRelaxed() {
        // Stressed: low HRV, high HR
        let stressedRR = generateRRIntervals(count: 50, mean: 600, sd: 20)
        let stressedResult = HRVAnalyzer.analyze(rrIntervals: stressedRR)
        
        // Relaxed: high HRV, normal HR
        let relaxedRR = generateRRIntervals(count: 50, mean: 900, sd: 80)
        let relaxedResult = HRVAnalyzer.analyze(rrIntervals: relaxedRR)
        
        XCTAssertNotNil(stressedResult)
        XCTAssertNotNil(relaxedResult)
        
        if let stressed = stressedResult, let relaxed = relaxedResult {
            XCTAssertGreaterThan(stressed.stressScore, relaxed.stressScore,
                               "Stressed state should have higher stress score than relaxed state")
        }
    }
    
    // MARK: - Time Domain Metrics Tests
    
    func testTimeDomainMetrics() {
        let rrIntervals = generateRRIntervals(count: 100, mean: 800, sd: 60)
        let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals)
        
        XCTAssertNotNil(result)
        if let result = result {
            let td = result.timeDomain
            XCTAssertGreaterThan(td.sdnn, 0, "SDNN should be positive")
            XCTAssertGreaterThan(td.rmssd, 0, "RMSSD should be positive")
            XCTAssertGreaterThanOrEqual(td.pnn50, 0, "pNN50 should be >= 0")
            XCTAssertLessThanOrEqual(td.pnn50, 100, "pNN50 should be <= 100")
            XCTAssertGreaterThan(td.meanRR, 0, "Mean RR should be positive")
        }
    }
    
    // MARK: - Frequency Domain Tests
    
    func testFrequencyDomainMetrics() {
        // Need enough samples for frequency analysis
        let rrIntervals = generateRRIntervals(count: 200, mean: 800, sd: 60)
        let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals)
        
        XCTAssertNotNil(result)
        if let result = result {
            let fd = result.frequencyDomain
            XCTAssertGreaterThanOrEqual(fd.lfPower, 0, "LF power should be >= 0")
            XCTAssertGreaterThanOrEqual(fd.hfPower, 0, "HF power should be >= 0")
            XCTAssertGreaterThanOrEqual(fd.lfHfRatio, 0, "LF/HF ratio should be >= 0")
            XCTAssertGreaterThanOrEqual(fd.totalPower, 0, "Total power should be >= 0")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateRRIntervals(count: Int, mean: Double, sd: Double) -> [Double] {
        var intervals: [Double] = []
        for _ in 0..<count {
            // Box-Muller transform for normal distribution
            let u1 = Double.random(in: 0...1)
            let u2 = Double.random(in: 0...1)
            let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
            let rr = mean + z * sd
            intervals.append(max(300, min(2000, rr))) // Clamp to realistic range
        }
        return intervals
    }
}
