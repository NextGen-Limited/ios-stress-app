import XCTest
@testable import StressMonitor

// MARK: - Stress Calculator Tests
final class StressCalculatorTests: XCTestCase {

    // MARK: - Properties
    private var sut: StressCalculator!
    private var defaultBaseline: PersonalBaseline!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        defaultBaseline = PersonalBaseline(restingHeartRate: 60.0, baselineHRV: 50.0)
        sut = StressCalculator(baseline: defaultBaseline)
    }

    override func tearDown() async throws {
        sut = nil
        defaultBaseline = nil
        try await super.tearDown()
    }

    // MARK: - Normal Stress Calculation Tests
    func testNormalStress() async throws {
        // Given: Normal HRV (50ms) and normal heart rate (60bpm)
        let hrv = 50.0
        let heartRate = 60.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should be relaxed — sigmoid(0) is non-zero (~0.12 for HRV, ~0.29 for HR) → ~17%
        XCTAssertEqual(result.level, 17, accuracy: 5, "At-baseline readings result in ~17% stress with sigmoid")
        XCTAssertEqual(result.category, .relaxed, "Normal readings should be categorized as relaxed")
        XCTAssertEqual(result.hrv, hrv, accuracy: 0.001)
        XCTAssertEqual(result.heartRate, heartRate, accuracy: 0.001)
        XCTAssertTrue(result.confidence > 0, "Confidence should be positive")
    }

    func testHighStressElevatedHeartRate() async throws {
        // Given: Normal HRV but elevated heart rate (100bpm)
        let hrv = 50.0
        let heartRate = 100.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should show mild stress
        // normalizedHR = (100-60)/60 = 0.667
        // hrComponent = sigmoid(0.667, k=3, x0=0.3) ≈ 0.75
        // stress = (0.119*0.7 + 0.75*0.3) * 100 ≈ 30.8
        XCTAssertEqual(result.level, 31, accuracy: 5, "Elevated heart rate with sigmoid HR scaling")
        XCTAssertEqual(result.category, .mild, "Normal HRV + elevated HR → mild stress with sigmoid")
    }

    func testHighStressLowHRV() async throws {
        // Given: Low HRV (25ms) indicating stress
        let hrv = 25.0
        let heartRate = 60.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should show elevated stress
        XCTAssertGreaterThan(result.level, 30, "Low HRV should significantly increase stress")
        XCTAssertTrue([.mild, .moderate].contains(result.category), "Should be mild or moderate stress")
    }

    func testSevereStress() async throws {
        // Given: Very low HRV (20ms) and elevated heart rate (90bpm)
        let hrv = 20.0
        let heartRate = 90.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should show high stress
        // normalizedHRV = (50-20)/50 = 0.6, hrvComponent = pow(0.6, 0.8) ≈ 0.66
        // normalizedHR = (90-60)/60 = 0.5, hrComponent = atan(1) / (π/2) ≈ 0.64
        // stress = (0.66 * 0.7 + 0.64 * 0.3) * 100 ≈ 65
        XCTAssertEqual(result.level, 65, accuracy: 5, "Severe stress indicators should result in high stress level")
        XCTAssertEqual(result.category, .moderate, "Should be categorized as moderate stress (65)")
    }

    // MARK: - Category Boundary Tests
    func testCategoryBoundary_RelaxedToMild() async throws {
        // Test the boundary between relaxed (0-25) and mild (25-50)

        // Just below 25 - should be relaxed
        let result1 = try await sut.calculateStress(hrv: 40.0, heartRate: 70.0)
        if result1.level < 25 {
            XCTAssertEqual(result1.category, .relaxed, "Level below 25 should be relaxed")
        }

        // Just above 25 - should be mild
        let result2 = try await sut.calculateStress(hrv: 35.0, heartRate: 85.0)
        if result2.level >= 25 && result2.level < 50 {
            XCTAssertEqual(result2.category, .mild, "Level 25-50 should be mild")
        }
    }

    func testCategoryBoundary_MildToModerate() async throws {
        // Test the boundary between mild (25-50) and moderate (50-75)

        // HRV low enough to push into moderate
        let result = try await sut.calculateStress(hrv: 22.0, heartRate: 80.0)
        if result.level >= 50 && result.level < 75 {
            XCTAssertEqual(result.category, .moderate, "Level 50-75 should be moderate")
        }
    }

    func testCategoryBoundary_ModerateToHigh() async throws {
        // Test the boundary between moderate (50-75) and high (75-100)

        // Very low HRV and high heart rate
        let result = try await sut.calculateStress(hrv: 15.0, heartRate: 110.0)
        if result.level >= 75 {
            XCTAssertEqual(result.category, .high, "Level 75+ should be high stress")
        }
    }

    // MARK: - Edge Cases
    func testZeroHRV() async throws {
        // Given: Edge case with zero HRV
        let hrv = 0.0
        let heartRate = 60.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should handle gracefully with high stress
        // normalizedHRV = 1.0, hrvComponent = sigmoid(1.0, k=4, x0=0.5) ≈ 0.88
        // stress = (0.88*0.7 + 0.289*0.3) * 100 ≈ 70
        XCTAssertEqual(result.level, 70, accuracy: 5, "Zero HRV with normal HR → ~70% stress with sigmoid")
        XCTAssertEqual(result.category, .moderate, "Level ~70 falls in moderate range (50-75)")
    }

    func testZeroHeartRate() async throws {
        // Given: Edge case with zero heart rate (physiologically impossible)
        let hrv = 50.0
        let heartRate = 0.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should handle gracefully
        XCTAssertGreaterThanOrEqual(result.level, 0, "Stress level should be non-negative")
        XCTAssertLessThanOrEqual(result.level, 100, "Stress level should not exceed 100")
    }

    func testExtremeValues() async throws {
        // Given: Extremely high heart rate
        let hrv = 50.0
        let heartRate = 200.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: sigmoid clamps at 2.0 input → hrComponent ≈ 0.994
        // normalizedHR = (200-60)/60 = 2.33, clamped to 2.0
        // hrComponent = sigmoid(2.0, k=3, x0=0.3) ≈ 0.994
        // stress = (0.119*0.7 + 0.994*0.3) * 100 ≈ 38
        XCTAssertEqual(result.level, 38, accuracy: 5, "Extreme heart rate clamped at 2.0 input → ~38% stress")
        XCTAssertEqual(result.category, .mild, "Should be categorized as mild stress")
    }

    func testNegativeValues() async throws {
        // Given: Negative HRV (physiologically impossible)
        let hrv = -10.0
        let heartRate = 60.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: Should handle gracefully
        XCTAssertGreaterThanOrEqual(result.level, 0, "Stress level should be non-negative")
        XCTAssertLessThanOrEqual(result.level, 100, "Stress level should not exceed 100")
    }

    // MARK: - Confidence Scoring Tests
    func testConfidence_NormalReading() async throws {
        // Given: Normal physiological values
        let hrv = 50.0
        let heartRate = 60.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: Should have high confidence
        XCTAssertEqual(confidence, 1.0, accuracy: 0.1, "Normal readings should have high confidence")
    }

    func testConfidence_LowHRV() async throws {
        // Given: Low HRV (< 20ms)
        let hrv = 15.0
        let heartRate = 60.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: Gradual penalty — max(0.3, 15/20) = 0.75, not binary 0.5
        XCTAssertEqual(confidence, 0.75, accuracy: 0.05, "Low HRV should reduce confidence proportionally")
    }

    func testConfidence_LowHeartRate() async throws {
        // Given: Very low heart rate (< 40 bpm)
        let hrv = 50.0
        let heartRate = 35.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: hr=35 < 50 threshold, deviation=(50-35)/50=0.3, *max(0.4, 0.7)=*0.7
        XCTAssertEqual(confidence, 0.70, accuracy: 0.05, "Low HR reduces confidence proportionally (new threshold: 50bpm)")
    }

    func testConfidence_HighHeartRate() async throws {
        // Given: Very high heart rate (> 160 bpm — new threshold)
        let hrv = 50.0
        let heartRate = 190.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: hr=190 > 160 threshold, deviation=(190-160)/160≈0.19, *max(0.4, 0.81)=*0.81
        XCTAssertEqual(confidence, 0.81, accuracy: 0.05, "High HR reduces confidence proportionally (new threshold: 160bpm)")
    }

    func testConfidence_SampleCount() async throws {
        // Given: Different sample counts

        // When: Calculating confidence with few samples
        let confidenceLow = sut.calculateConfidence(hrv: 50.0, heartRate: 60.0, samples: 1)

        // When: Calculating confidence with many samples
        let confidenceHigh = sut.calculateConfidence(hrv: 50.0, heartRate: 60.0, samples: 20)

        // Then: More samples should increase confidence
        XCTAssertLessThan(confidenceLow, confidenceHigh, "More samples should increase confidence")
        XCTAssertGreaterThanOrEqual(confidenceLow, 0.7, "Minimum confidence should be 70% with normal readings")
        XCTAssertEqual(confidenceHigh, 1.0, accuracy: 0.01, "10+ samples should give maximum confidence")
    }

    func testConfidence_MultipleReductions() async throws {
        // Given: Low HRV AND extreme heart rate
        let hrv = 15.0
        let heartRate = 35.0
        let samples = 1

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: 0.75 (hrv) * 0.7 (hr<50) * 0.73 (samples=1) ≈ 0.38
        XCTAssertEqual(confidence, 0.38, accuracy: 0.05, "Multiple gradual penalties compound confidence reduction")
    }

    // MARK: - Algorithm Component Tests
    func testHRVComponentWeight() async throws {
        // Given: Low HRV with normal heart rate
        let hrv = 25.0
        let heartRate = 60.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: HRV should dominate (70% weight)
        // HRV alone would give significant stress
        XCTAssertGreaterThan(result.level, 30, "HRV component should drive stress level")
    }

    func testHRComponentWeight() async throws {
        // Given: Normal HRV with elevated heart rate
        let hrv = 50.0
        let heartRate = 100.0

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: hrv, heartRate: heartRate)

        // Then: HR contributes meaningfully with sigmoid scaling
        // Same inputs as testHighStressElevatedHeartRate → ~30.8
        XCTAssertEqual(result.level, 31, accuracy: 5, "HR component contributes to stress")
        XCTAssertEqual(result.category, .mild, "Normal HRV + elevated HR → mild stress with sigmoid")
    }

    // MARK: - Baseline Customization Tests
    func testCustomBaseline() async throws {
        // Given: Custom baseline (athlete with low resting HR and high baseline HRV)
        let athleteBaseline = PersonalBaseline(restingHeartRate: 45.0, baselineHRV: 70.0)
        let customCalculator = StressCalculator(baseline: athleteBaseline)

        // When: Calculating stress with athlete's baseline
        let result = try await customCalculator.calculateStress(hrv: 70.0, heartRate: 45.0)

        // Then: At-baseline sigmoid gives ~17% — still in relaxed range
        XCTAssertEqual(result.level, 17, accuracy: 5, "Athlete at-baseline → ~17% with sigmoid")
        XCTAssertEqual(result.category, .relaxed, "Athlete should be categorized as relaxed")
    }

    // MARK: - Timestamp Tests
    func testTimestamp() async throws {
        // Given: Current time before calculation
        let beforeDate = Date()

        // When: Calculating stress
        let result = try await sut.calculateStress(hrv: 50.0, heartRate: 60.0)

        // Then: Timestamp should be current
        let afterDate = Date()
        XCTAssertGreaterThanOrEqual(result.timestamp, beforeDate, "Timestamp should be after start")
        XCTAssertLessThanOrEqual(result.timestamp, afterDate, "Timestamp should be before end")
    }

    // MARK: - Sigmoid Boundary Tests
    func testSigmoid_AtMidpoint() async throws {
        // hrv = 25ms with 50ms baseline → normalizedHRV = 0.5 → sigmoid midpoint = 0.5
        let result = try await sut.calculateStress(hrv: 25.0, heartRate: 60.0)
        // hrvComp = 0.5, hrComp = ~0.289 → stress = (0.5*0.7 + 0.289*0.3)*100 ≈ 43.7
        XCTAssertEqual(result.level, 44, accuracy: 5, "At sigmoid midpoint → ~44% stress")
    }

    func testSigmoid_HighNormalization() async throws {
        // hrv = 0ms → normalizedHRV = 1.0, sigmoid approaches ~0.88
        let result = try await sut.calculateStress(hrv: 0.0, heartRate: 60.0)
        XCTAssertGreaterThan(result.level, 60, "High normalization → stress above 60%")
        XCTAssertLessThanOrEqual(result.level, 100, "Stress must not exceed 100")
    }

    // MARK: - Recency Penalty Tests
    func testConfidence_RecentReading() async throws {
        let recentDate = Date().addingTimeInterval(-5 * 60)  // 5 min ago
        let confidence = sut.calculateConfidence(hrv: 50.0, heartRate: 60.0, samples: 10, lastReadingDate: recentDate)
        // recency = max(0.3, 1.0 - 5/120) ≈ 0.958
        XCTAssertGreaterThan(confidence, 0.9, "Recent reading should have high confidence")
    }

    func testConfidence_StaleReading() async throws {
        let staleDate = Date().addingTimeInterval(-180 * 60)  // 3h ago
        let confidence = sut.calculateConfidence(hrv: 50.0, heartRate: 60.0, samples: 10, lastReadingDate: staleDate)
        // recency = max(0.3, 1.0 - 180/120) = max(0.3, -0.5) = 0.3
        XCTAssertLessThan(confidence, 0.4, "Stale (3h) reading should have low confidence")
    }

    func testConfidence_NoLastReadingDate() async throws {
        let confidence = sut.calculateConfidence(hrv: 50.0, heartRate: 60.0, samples: 10, lastReadingDate: nil)
        XCTAssertEqual(confidence, 1.0, accuracy: 0.01, "No date means no recency penalty")
    }

    // MARK: - Thread Safety Tests
    func testConcurrentCalculations() async throws {
        // Given: Multiple concurrent calculations
        let expectations = (1...10).map { _ in
            Task {
                try await sut.calculateStress(hrv: Double.random(in: 20...80), heartRate: Double.random(in: 50...120))
            }
        }

        // When: Waiting for all to complete
        var results: [StressResult] = []
        for expectation in expectations {
            let result = try await expectation.value
            results.append(result)
        }

        // Then: All should succeed
        XCTAssertEqual(results.count, 10, "All concurrent calculations should complete")
        for result in results {
            XCTAssertGreaterThanOrEqual(result.level, 0, "Stress should be non-negative")
            XCTAssertLessThanOrEqual(result.level, 100, "Stress should not exceed 100")
        }
    }
}
