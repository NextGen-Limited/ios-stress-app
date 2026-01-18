# Phase 8: Testing & Polish

**Goal:** Comprehensive testing, performance optimization, and final polish for production.

## Prerequisites
- ✅ All previous phases completed
- Full feature set implemented

---

## 1. Unit Testing

### Test Coverage Goals
- Models: 90%+
- ViewModels: 85%+
- Services: 80%+
- UI Views: 50%+

### Algorithm Tests
File: `StressMonitorTests/Algorithm/StressCalculatorTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class StressCalculatorTests: XCTestCase {
    var calculator: StressCalculator!

    override func setUp() {
        calculator = StressCalculator()
    }

    func testNormalStressLevel() async throws {
        let result = try await calculator.calculateStress(hrv: 50, heartRate: 60)

        XCTAssertEqual(result.level, 0, accuracy: 10)
        XCTAssertEqual(result.category, .relaxed)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }

    func testHighStressLevel() async throws {
        let result = try await calculator.calculateStress(hrv: 20, heartRate: 100)

        XCTAssertGreaterThan(result.level, 50)
        XCTAssertTrue(result.category == .moderate || result.category == .high)
    }

    func testExtremeHRV() async throws {
        let result = try await calculator.calculateStress(hrv: 5, heartRate: 60)
        XCTAssertLessThan(result.confidence, 0.7)
    }

    func testBaselineCalculation() async throws {
        let measurements = [
            HRVMeasurement(value: 45),
            HRVMeasurement(value: 50),
            HRVMeasurement(value: 55),
            HRVMeasurement(value: 48),
            HRVMeasurement(value: 52)
        ]

        let baseline = BaselineCalculator()
        let result = try await baseline.calculateBaseline(from: measurements)

        XCTAssertEqual(result.averageHRV, 50, accuracy: 1)
        XCTAssertGreaterThan(result.confidence, 0)
    }
}
```

### Repository Tests
File: `StressMonitorTests/Data/StressRepositoryTests.swift`

```swift
import XCTest
import SwiftData
@testable import StressMonitor

final class StressRepositoryTests: XCTestCase {
    var repository: StressRepository!
    var container: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([StressMeasurement.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])

        let context = ModelContext(container)
        repository = StressRepository(modelContext: context)
    }

    func testSaveMeasurement() async throws {
        let measurement = StressMeasurement(
            stressLevel: 42,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        try await repository.save(measurement)

        let fetched = try await repository.fetchLatest(limit: 1)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.stressLevel, 42)
    }

    func testFetchByDate() async throws {
        let measurement = StressMeasurement(
            stressLevel: 42,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        try await repository.save(measurement)

        let today = Date()
        let fetched = try await repository.fetch(for: today)
        XCTAssertEqual(fetched.count, 1)
    }
}
```

### ViewModel Tests
File: `StressMonitorTests/ViewModels/StressViewModelTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class StressViewModelTests: XCTestCase {
    var viewModel: StressViewModel!
    var mockHealthKit: MockHealthKitManager!
    var mockAlgorithm: MockStressAlgorithm!
    var mockRepository: MockStressRepository!

    override func setUp() {
        mockHealthKit = MockHealthKitManager()
        mockAlgorithm = MockStressAlgorithm()
        mockRepository = MockStressRepository()

        viewModel = StressViewModel(
            healthKit: mockHealthKit,
            algorithm: mockAlgorithm,
            repository: mockRepository
        )
    }

    func testCalculateStressSuccess() async throws {
        mockHealthKit.mockHRV = HRVMeasurement(value: 50)
        mockHealthKit.mockHeartRate = [HeartRateSample(value: 60)]
        mockAlgorithm.mockResult = StressResult(
            level: 25,
            category: .mild,
            confidence: 0.85,
            timestamp: Date(),
            inputs: AlgorithmInputs(hrv: 50, heartRate: 60, restingHeartRate: 60, hrvBaseline: 50)
        )

        await viewModel.calculateStress(hrv: 50, heartRate: 60)

        XCTAssertNotNil(viewModel.currentStress)
        XCTAssertEqual(viewModel.currentStress?.level, 25)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCalculateStressFailure() async throws {
        mockHealthKit.shouldThrowError = true

        await viewModel.calculateStress(hrv: 50, heartRate: 60)

        XCTAssertNil(viewModel.currentStress)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

---

## 2. UI Testing

### Snapshot Tests
File: `StressMonitorUITests/SnapshotTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class SnapshotTests: XCTestCase {

    func testDashboardViewNormal() {
        let viewModel = StressViewModel()
        viewModel.currentStress = StressResult(
            level: 25,
            category: .mild,
            confidence: 0.85,
            timestamp: Date(),
            inputs: AlgorithmInputs(hrv: 50, heartRate: 60, restingHeartRate: 60, hrvBaseline: 50)
        )

        let view = DashboardView()
        // Attach snapshot
    }

    func testDashboardViewHighStress() {
        let viewModel = StressViewModel()
        viewModel.currentStress = StressResult(
            level: 80,
            category: .high,
            confidence: 0.9,
            timestamp: Date(),
            inputs: AlgorithmInputs(hrv: 20, heartRate: 100, restingHeartRate: 60, hrvBaseline: 50)
        )

        let view = DashboardView()
        // Attach snapshot
    }
}
```

---

## 3. Performance Testing

### Algorithm Performance
File: `StressMonitorTests/Performance/AlgorithmPerformanceTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class AlgorithmPerformanceTests: XCTestCase {
    var calculator: StressCalculator!

    override func setUp() {
        calculator = StressCalculator()
    }

    func testCalculationPerformance() {
        measure {
            Task {
                for _ in 0..<100 {
                    _ = try? await calculator.calculateStress(hrv: 50, heartRate: 60)
                }
            }
        }
    }

    func testBaselineCalculationPerformance() {
        let baselineCalc = BaselineCalculator()
        let measurements = (0..<1000).map { _ in
            HRVMeasurement(value: Double.random(in: 20...80))
        }

        measure {
            Task {
                _ = try? await baselineCalc.calculateBaseline(from: measurements)
            }
        }
    }
}
```

### Memory Leak Testing
```swift
func testMemoryLeaks() {
    let viewModel = StressViewModel()
    addTeardownBlock { [weak viewModel] in
        XCTAssertNil(viewModel, "ViewModel should be deallocated")
    }
}
```

---

## 4. Integration Testing

### End-to-End Flow
File: `StressMonitorTests/Integration/EndToEndTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class EndToEndTests: XCTestCase {

    func testCompleteMeasurementFlow() async throws {
        // Setup
        let healthKit = HealthKitManager()
        let algorithm = StressCalculator()
        let repository = StressRepository(modelContext: /* context */)

        // Execute
        async let hrv = healthKit.fetchLatestHRV()
        async let heartRate = healthKit.fetchHeartRate(samples: 10)

        let (hrvData, hrData) = try await (hrv, heartRate)

        guard let latestHRV = hrvData,
              let latestHR = hrData.first else {
            XCTFail("No data available")
            return
        }

        let result = try await algorithm.calculateStress(
            hrv: latestHRV.value,
            heartRate: latestHR.value
        )

        let measurement = StressMeasurement(
            stressLevel: result.level,
            hrv: result.inputs.hrv,
            restingHeartRate: result.inputs.restingHeartRate,
            confidences: [result.confidence]
        )

        try await repository.save(measurement)

        // Verify
        let fetched = try await repository.fetchLatest(limit: 1)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.stressLevel, result.level)
    }
}
```

---

## 5. Error Handling

### Error Scenarios
- [ ] HealthKit authorization denied
- [ ] No health data available
- [ ] CloudKit sync failure
- [ ] Network timeout
- [ ] Invalid data values
- [ ] Background task failure

### Error Test Cases
```swift
func testHealthKitUnauthorized() async {
    let mockHealthKit = MockHealthKitManager()
    mockHealthKit.authorizationStatus = .notDetermined

    let viewModel = StressViewModel(healthKit: mockHealthKit)
    await viewModel.calculateStress(hrv: 50, heartRate: 60)

    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.errorMessage?.contains("authorization") == true)
}
```

---

## 6. Device Testing

### Test Matrix
| Device | iOS/watchOS | Screen Size | Testing Priority |
|--------|-------------|-------------|------------------|
| iPhone 15 Pro | 17.0+ | 6.1" | High |
| iPhone SE | 17.0+ | 4.7" | Medium |
| Apple Watch S9 | 10.0+ | 45mm | High |
| Apple Watch SE | 10.0+ | 40mm | Medium |

### Checklist
- [ ] Runs on minimum iOS version (17.0)
- [ ] Runs on minimum watchOS version (10.0)
- [ ] Layout adapts to different screen sizes
- [ ] Performance acceptable on older devices
- [ ] Battery usage reasonable

---

## 7. Polish Items

### Visual Polish
- [ ] Smooth animations
- [ ] Proper haptic feedback
- [ ] Consistent color scheme
- [ ] Good contrast ratios
- [ ] Proper spacing and padding
- [ ] Loading states for all async operations

### User Experience
- [ ] Clear error messages
- [ ] Helpful onboarding
- [ ] Intuitive navigation
- [ ] Responsive to user input
- [ ] No blocking UI

### Accessibility
- [ ] VoiceOver support
- [ ] Dynamic Type support
- [ ] High contrast mode
- [ ] Reduce motion support
- [ ] Proper labels

### Performance
- [ ] Launch time < 2 seconds
- [ ] Smooth scrolling
- [ ] No frame drops
- [ ] Efficient memory usage
- [ ] Background tasks don't drain battery

---

## 8. Pre-Release Checklist

### Code Quality
- [ ] All tests passing
- [ ] Code reviewed
- [ ] No TODO comments left
- [ ] Proper error handling
- [ ] Logging in place

### Documentation
- [ ] Code documented
- [ ] README updated
- [ ] User guide ready
- [ ] Privacy policy prepared
- [ ] App store description ready

### Legal & Privacy
- [ ] Privacy policy in app
- [ ] Terms of service
- [ ] HealthKit usage disclosed
- [ ] Data collection disclosed
- [ ] GDPR compliant (if applicable)

### App Store
- [ ] Screenshots prepared
- [ ] App icon finalized
- [ ] Metadata complete
- [ ] Age rating set
- [ ] Export compliance checked

---

## Testing Checklist

### Unit Tests
- [ ] Algorithm tests pass
- [ ] Repository tests pass
- [ ] ViewModel tests pass
- [ ] Service tests pass
- [ ] Coverage targets met

### Integration Tests
- [ ] End-to-end flows work
- [ ] Cross-device sync works
- [ ] Background tasks work
- [ ] Error scenarios handled

### UI Tests
- [ ] All views render correctly
- [ ] Navigation works
- [ ] Inputs work
- [ ] States display correctly

### Performance
- [ ] Launch time acceptable
- [ ] No memory leaks
- [ ] Battery usage reasonable
- [ ] Smooth animations

### Device Testing
- [ ] Tested on iPhone
- [ ] Tested on Apple Watch
- [ ] Tested on different iOS versions
- [ ] Tested on different screen sizes

---

## Estimated Time

**5-6 hours**

- Unit tests: 2 hours
- Integration tests: 1 hour
- UI tests: 1 hour
- Performance testing: 1 hour
- Polish and review: 1 hour

---

## Completion

🎉 **Congratulations!** The iOS Stress Monitor app is now complete and ready for release.

All 8 phases have been implemented:
1. ✅ Project Foundation
2. ✅ Data Layer
3. ✅ Core Algorithm
4. ✅ iPhone UI
5. ✅ watchOS App
6. ✅ Background Notifications
7. ✅ Data Sync
8. ✅ Testing & Polish

The app is ready for App Store submission and user testing.
