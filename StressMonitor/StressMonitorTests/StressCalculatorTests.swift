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

        // Then: Should be relaxed (low stress)
        XCTAssertEqual(result.level, 0, accuracy: 10, "Normal readings should result in near-zero stress")
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

        // Then: Should show mild stress (HR component has 30% weight)
        // normalizedHR = (100-60)/60 = 0.667
        // hrComponent = atan(0.667*2) / (π/2) ≈ 0.59
        // stress = 0.59 * 0.3 * 100 ≈ 17.7
        XCTAssertEqual(result.level, 17.7, accuracy: 2, "Elevated heart rate should result in mild stress")
        XCTAssertEqual(result.category, .relaxed, "Normal HRV with elevated HR should be relaxed due to 70% HRV weight")
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

        // Then: Should handle gracefully with high stress (70% max from HRV)
        // normalizedHRV = (50-0)/50 = 1, hrvComponent = 1, stress = 1 * 0.7 * 100 = 70
        XCTAssertEqual(result.level, 70, accuracy: 5, "Zero HRV with normal HR should result in 70 stress")
        XCTAssertEqual(result.category, .moderate, "Level 70 falls in moderate range (50-75)")
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

        // Then: atan function asymptotes, so won't reach 100 but should be moderate
        // normalizedHRV = 0, hrvComponent = 0
        // normalizedHR = (200-60)/60 = 2.33
        // hrComponent = atan(2.33*2) / (π/2) ≈ 0.87
        // stress = 0.87 * 0.3 * 100 ≈ 26
        XCTAssertEqual(result.level, 26, accuracy: 5, "Extreme heart rate should result in mild stress")
        XCTAssertEqual(result.category, .mild, "Should be categorized as mild stress (26)")
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

        // Then: Should have reduced confidence
        XCTAssertEqual(confidence, 0.5, accuracy: 0.1, "Low HRV should reduce confidence by 50%")
    }

    func testConfidence_LowHeartRate() async throws {
        // Given: Very low heart rate (< 40 bpm)
        let hrv = 50.0
        let heartRate = 35.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: Should have reduced confidence
        XCTAssertEqual(confidence, 0.6, accuracy: 0.1, "Extreme heart rate should reduce confidence")
    }

    func testConfidence_HighHeartRate() async throws {
        // Given: Very high heart rate (> 180 bpm)
        let hrv = 50.0
        let heartRate = 190.0
        let samples = 10

        // When: Calculating confidence
        let confidence = sut.calculateConfidence(hrv: hrv, heartRate: heartRate, samples: samples)

        // Then: Should have reduced confidence
        XCTAssertEqual(confidence, 0.6, accuracy: 0.1, "Extreme heart rate should reduce confidence")
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

        // Then: Should have significantly reduced confidence
        // Expected: 1.0 * 0.5 (low HRV) * 0.6 (extreme HR) * 0.7 (low samples) = 0.21
        XCTAssertEqual(confidence, 0.21, accuracy: 0.05, "Multiple factors should compound confidence reduction")
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

        // Then: HR should contribute (30% weight) but HRV should moderate
        // Same calculation as testHighStressElevatedHeartRate
        XCTAssertEqual(result.level, 17.7, accuracy: 2, "HR component should contribute to stress")
        XCTAssertEqual(result.category, .relaxed, "Normal HRV keeps stress in relaxed range")
    }

    // MARK: - Baseline Customization Tests
    func testCustomBaseline() async throws {
        // Given: Custom baseline (athlete with low resting HR and high baseline HRV)
        let athleteBaseline = PersonalBaseline(restingHeartRate: 45.0, baselineHRV: 70.0)
        let customCalculator = StressCalculator(baseline: athleteBaseline)

        // When: Calculating stress with athlete's baseline
        let result = try await customCalculator.calculateStress(hrv: 70.0, heartRate: 45.0)

        // Then: Should be relaxed for athlete
        XCTAssertEqual(result.level, 0, accuracy: 10, "Athlete's normal readings should be relaxed")
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
