# Phase 3: Core Algorithm

**Goal:** Implement the stress detection algorithm with HRV analysis and confidence scoring.

## Prerequisites
- ✅ Phase 2 completed
- Health data accessible via repository
- Algorithm documentation ready

---

## 1. Stress Algorithm Service

### Algorithm Interface
File: `StressMonitor/Services/Algorithm/StressAlgorithmService.swift`

```swift
import Foundation

protocol StressAlgorithmServiceProtocol {
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
}

struct StressResult {
    let level: Double // 0-100
    let category: StressCategory
    let confidence: Double
    let timestamp: Date
    let inputs: AlgorithmInputs
}

struct AlgorithmInputs {
    let hrv: Double
    let heartRate: Double
    let restingHeartRate: Double
    let hrvBaseline: Double
}

enum StressCategory: String, CaseIterable {
    case relaxed = "Relaxed"
    case mild = "Mild Stress"
    case moderate = "Moderate Stress"
    case high = "High Stress"

    init(level: Double) {
        switch level {
        case 0..<25: self = .relaxed
        case 25..<50: self = .mild
        case 50..<75: self = .moderate
        default: self = .high
        }
    }
}
```

---

## 2. Core Algorithm Implementation

### Main Algorithm
File: `StressMonitor/Services/Algorithm/StressCalculator.swift`

```swift
import Foundation

class StressCalculator: StressAlgorithmServiceProtocol {

    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        // Get user's baseline
        let baseline = await getBaseline()

        // Normalize inputs (0-1 range)
        let normalizedHRV = normalizeHRV(hrv, baseline: baseline.hrv)
        let normalizedHR = normalizeHeartRate(heartRate, resting: baseline.restingHR)

        // Calculate stress components
        let hrvComponent = calculateHRVComponent(normalizedHRV)
        let hrComponent = calculateHRComponent(normalizedHR)

        // Combine components (weights sum to 1.0)
        let stressLevel = (hrvComponent * 0.7) + (hrComponent * 0.3)

        // Calculate confidence
        let confidence = calculateConfidence(
            hrv: hrv,
            heartRate: heartRate,
            samples: baseline.sampleCount
        )

        return StressResult(
            level: stressLevel * 100,
            category: StressCategory(level: stressLevel * 100),
            confidence: confidence,
            timestamp: Date(),
            inputs: AlgorithmInputs(
                hrv: hrv,
                heartRate: heartRate,
                restingHeartRate: baseline.restingHR,
                hrvBaseline: baseline.hrv
            )
        )
    }

    // MARK: - Normalization

    private func normalizeHRV(_ hrv: Double, baseline: Double) -> Double {
        // Lower HRV = higher stress
        let deviation = (baseline - hrv) / baseline
        return max(0, min(1, deviation))
    }

    private func normalizeHeartRate(_ hr: Double, resting: Double) -> Double {
        // Higher HR = higher stress
        let deviation = (hr - resting) / resting
        return max(0, min(1, deviation))
    }

    // MARK: - Component Calculations

    private func calculateHRVComponent(_ normalized: Double) -> Double {
        // Non-linear mapping to emphasize high deviations
        return pow(normalized, 0.8)
    }

    private func calculateHRComponent(_ normalized: Double) -> Double {
        // More gradual curve
        return atan(normalized * 2) / (Double.pi / 2)
    }

    // MARK: - Confidence

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        var confidence = 1.0

        // Reduce confidence if low HRV (< 20ms)
        if hrv < 20 {
            confidence *= 0.6
        }

        // Reduce confidence if extreme HR
        if heartRate < 40 || heartRate > 180 {
            confidence *= 0.7
        }

        // Boost confidence if we have lots of samples
        let sampleBonus = min(0.2, Double(samples) / 1000.0)
        confidence = min(1.0, confidence + sampleBonus)

        return confidence
    }

    // MARK: - Baseline

    private func getBaseline() async -> BaselineData {
        // In real app, fetch from UserDefaults or calculated from historical data
        return BaselineData(
            hrv: 50.0, // ms
            restingHR: 60.0, // bpm
            sampleCount: 100
        )
    }
}

struct BaselineData {
    let hrv: Double
    let restingHR: Double
    let sampleCount: Int
}
```

---

## 3. Baseline Calculator

### Personal Baseline
File: `StressMonitor/Services/Algorithm/BaselineCalculator.swift`

```swift
import Foundation

class BaselineCalculator {

    struct BaselineResult {
        let averageHRV: Double
        let restingHeartRate: Double
        let sampleCount: Int
        let confidence: Double
    }

    func calculateBaseline(from measurements: [HRVMeasurement]) async throws -> BaselineResult {
        guard !measurements.isEmpty else {
            throw AlgorithmError.noData
        }

        // Calculate average HRV (excluding outliers)
        let filteredHRV = filterOutliers(measurements.map { $0.value })
        let avgHRV = filteredHRV.reduce(0, +) / Double(filteredHRV.count)

        // Calculate resting heart rate
        let restingHR = await calculateRestingHR()

        let confidence = calculateBaselineConfidence(sampleCount: measurements.count)

        return BaselineResult(
            averageHRV: avgHRV,
            restingHeartRate: restingHR,
            sampleCount: measurements.count,
            confidence: confidence
        )
    }

    private func filterOutliers(_ values: [Double]) -> [Double] {
        guard values.count > 4 else { return values }

        let sorted = values.sorted()
        let q1 = sorted[sorted.count / 4]
        let q3 = sorted[sorted.count * 3 / 4]
        let iqr = q3 - q1
        let lowerBound = q1 - (1.5 * iqr)
        let upperBound = q3 + (1.5 * iqr)

        return values.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    private func calculateBaselineConfidence(sampleCount: Int) -> Double {
        // Need at least 50 samples for good baseline
        return min(1.0, Double(sampleCount) / 50.0)
    }
}

enum AlgorithmError: Error {
    case noData
    case insufficientData
}
```

---

## 4. Integration with ViewModels

### Stress ViewModel
File: `StressMonitor/ViewModels/StressViewModel.swift`

```swift
import Foundation
import Observation

@Observable
class StressViewModel {
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?

    init(algorithm: StressAlgorithmServiceProtocol = StressCalculator(),
         repository: StressRepositoryProtocol) {
        self.algorithm = algorithm
        self.repository = repository
    }

    func calculateStress(hrv: Double, heartRate: Double) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await algorithm.calculateStress(hrv: hrv, heartRate: heartRate)
            currentStress = result

            // Save to repository
            let measurement = StressMeasurement(
                stressLevel: result.level,
                hrv: result.inputs.hrv,
                restingHeartRate: result.inputs.restingHeartRate,
                confidences: [result.confidence]
            )

            try await repository.save(measurement)

        } catch {
            errorMessage = "Failed to calculate stress: \(error.localizedDescription)"
        }
    }
}
```

---

## 5. Testing

### Unit Tests
File: `StressMonitorTests/Algorithm/StressCalculatorTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class StressCalculatorTests: XCTestCase {
    var calculator: StressCalculator!

    override func setUp() {
        calculator = StressCalculator()
    }

    func testNormalStress() async throws {
        let result = try await calculator.calculateStress(hrv: 50, heartRate: 60)

        XCTAssertEqual(result.level, 0, accuracy: 10)
        XCTAssertEqual(result.category, .relaxed)
        XCTAssertTrue(result.confidence > 0.8)
    }

    func testHighStress() async throws {
        let result = try await calculator.calculateStress(hrv: 20, heartRate: 100)

        XCTAssertGreaterThan(result.level, 50)
        XCTAssertTrue(result.category == .moderate || result.category == .high)
    }

    func testConfidenceCalculation() {
        let highConfidence = calculator.calculateConfidence(hrv: 50, heartRate: 70, samples: 500)
        let lowConfidence = calculator.calculateConfidence(hrv: 15, heartRate: 200, samples: 10)

        XCTAssertGreaterThan(highConfidence, lowConfidence)
    }
}
```

---

## Testing Checklist

### Algorithm
- [ ] Returns valid stress levels (0-100)
- [ ] Correctly categorizes stress levels
- [ ] Confidence scores are reasonable
- [ ] Handles edge cases (extreme HRV/HR)
- [ ] Normalization works correctly

### Integration
- [ ] ViewModel integrates correctly
- [ ] Saves results to repository
- [ ] Error handling works
- [ ] UI can display results

### Tests
- [ ] Unit tests pass
- [ ] Edge cases covered
- [ ] Confidence scoring tested
- [ ] Baseline calculation tested

---

## Estimated Time

**3-4 hours**

- Algorithm implementation: 2 hours
- Baseline calculator: 1 hour
- ViewModel integration: 30 min
- Testing: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 4: iPhone UI** to build the main iPhone interface.
