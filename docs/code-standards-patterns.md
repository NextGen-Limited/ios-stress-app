# Code Standards: Design Patterns & Testing

**Framework:** Swift 5.9+ with SwiftUI & SwiftData
**Architecture:** MVVM + Protocol-Oriented Design
**Section:** DI, async/await, SwiftData, testing, error handling
**Last Updated:** February 2026

---

## Dependency Injection

### Protocol-Based DI

Always use protocols for dependencies:

```swift
protocol HealthKitServiceProtocol {
  func requestAuthorization() async throws
  func fetchLatestHRV() async throws -> HRVMeasurement?
  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}

class HealthKitManager: HealthKitServiceProtocol {
  func requestAuthorization() async throws { ... }
  func fetchLatestHRV() async throws -> HRVMeasurement? { ... }
  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] { ... }
}
```

### Constructor Injection

```swift
class StressViewModel {
  private let healthKit: HealthKitServiceProtocol
  private let repository: StressRepositoryProtocol

  init(
    healthKit: HealthKitServiceProtocol = HealthKitManager(),
    repository: StressRepositoryProtocol = StressRepository()
  ) {
    self.healthKit = healthKit
    self.repository = repository
  }
}
```

**Avoid global singletons:**
```swift
// ❌ Don't do this
class HealthKitManager {
  static let shared = HealthKitManager()
}

// ✅ Do this instead
let healthKit = HealthKitManager()
let viewModel = StressViewModel(healthKit: healthKit)
```

---

## Async/Await Patterns

### Async Methods

Use `async/await` throughout. Avoid callbacks:

```swift
// ✅ Good
func fetchStress() async throws -> StressResult {
  let hrv = try await healthKit.fetchLatestHRV()
  let hr = try await healthKit.fetchHeartRate(samples: 10)
  return try await algorithm.calculateStress(hrv: hrv.value, heartRate: hr.first?.value ?? 0)
}

// ❌ Don't use completions
func fetchStress(completion: @escaping (Result<StressResult, Error>) -> Void) {
  // ...
}
```

### Task Modifiers in Views

Use `.task {}` for async operations in SwiftUI:

```swift
struct DashboardView: View {
  @State var viewModel: StressViewModel

  var body: some View {
    VStack {
      if let stress = viewModel.currentStress {
        Text("Stress: \(stress.level)")
      } else if viewModel.isLoading {
        ProgressView()
      }
    }
    .task {
      await viewModel.measureStress()
    }
  }
}
```

### Error Handling in Async

Always use `do-catch` with `throws`:

```swift
func calculateStress() async {
  do {
    let result = try await algorithm.calculateStress(hrv: 50, heartRate: 70)
    currentStress = result
  } catch HealthKitError.notAuthorized {
    errorMessage = "Please grant HealthKit permission"
  } catch {
    errorMessage = error.localizedDescription
  }
}
```

---

## SwiftData Models

### @Model Macro

Use SwiftData for persistence:

```swift
@Model
final class StressMeasurement {
  var timestamp: Date
  var stressLevel: Double
  var hrv: Double
  var heartRate: Double
  var confidence: Double
  var category: StressCategory

  init(
    timestamp: Date = .now,
    stressLevel: Double,
    hrv: Double,
    heartRate: Double,
    confidence: Double,
    category: StressCategory
  ) {
    self.timestamp = timestamp
    self.stressLevel = stressLevel
    self.hrv = hrv
    self.heartRate = heartRate
    self.confidence = confidence
    self.category = category
  }
}
```

**Rules:**
- Use `@Model` for SwiftData entities
- All properties must be serializable (Codable types)
- Include explicit `init`
- Use `@Transient` for computed properties not to persist

---

## Testing Conventions

### Test Naming

Use `test[Condition]` or `test[Method]_[Condition]` pattern:

```swift
func testNormalStress() async throws {
  // Test relaxed stress calculation
}

func testStressCalculator_HighHRV() async throws {
  // Test edge case
}

func testBaselineCalculation_WithFewerThan30Days() {
  // Test insufficient data
}
```

### Test Structure

```swift
final class StressCalculatorTests: XCTestCase {
  private var calculator: StressCalculator!

  override func setUp() async throws {
    try await super.setUp()
    calculator = StressCalculator()
  }

  func testNormalStress() async throws {
    // Arrange
    let hrv = 50.0
    let hr = 70.0

    // Act
    let result = try await calculator.calculateStress(hrv: hrv, heartRate: hr)

    // Assert
    XCTAssertEqual(result.level, 15, accuracy: 5)
    XCTAssertEqual(result.category, .relaxed)
  }
}
```

### Floating Point Comparison

Always use `accuracy` parameter:

```swift
// ✅ Good
XCTAssertEqual(result.level, 50.0, accuracy: 0.1)

// ❌ Don't
XCTAssertEqual(result.level, 50.0)
```

### Mocking

Create mock implementations for testing:

```swift
final class MockHealthKitManager: HealthKitServiceProtocol {
  var mockHRV: HRVMeasurement?
  var mockHeartRates: [HeartRateSample] = []

  func fetchLatestHRV() async throws -> HRVMeasurement? {
    return mockHRV
  }

  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
    return mockHeartRates
  }
}
```

---

## Error Handling

### Define Custom Errors

```swift
enum StressError: LocalizedError {
  case healthKitNotAvailable
  case invalidMeasurement
  case baselineNotEstablished

  var errorDescription: String? {
    switch self {
    case .healthKitNotAvailable:
      return "HealthKit is not available on this device"
    case .invalidMeasurement:
      return "Invalid HRV or heart rate measurement"
    case .baselineNotEstablished:
      return "Personal baseline not yet established"
    }
  }
}
```

### Handle Specific Errors

```swift
do {
  try await calculateStress()
} catch StressError.baselineNotEstablished {
  showOnboarding()
} catch {
  showGenericError(error)
}
```

---

## Common Patterns

### Protocol Extension for Default Behavior

```swift
protocol HealthKitServiceProtocol {
  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}

extension HealthKitServiceProtocol {
  func fetchLatestHeartRate() async throws -> Double? {
    let samples = try await fetchHeartRate(samples: 1)
    return samples.first?.value
  }
}
```

### Builder Pattern for Complex Objects

```swift
struct StressResultBuilder {
  var level: Double = 0
  var category: StressCategory = .relaxed
  var confidence: Double = 1.0

  func build() -> StressResult {
    StressResult(level: level, category: category, confidence: confidence)
  }
}
```

### Result Type for Error Handling

```swift
// Use Swift.Result explicitly to avoid collision with StressResult model
typealias StressComputationResult = Swift.Result<Double, StressError>

func calculateStress() -> StressComputationResult {
  do {
    let value = try computation()
    return .success(value)
  } catch {
    return .failure(error as? StressError ?? .unknown)
  }
}
```

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Stress Calculation | <1 second |
| View Render Time | <16ms (60 FPS) |
| Memory (Idle) | <50 MB |
| Memory (After 100 measurements) | <100 MB |
| CloudKit Sync | <30 seconds |
| App Launch | <2 seconds |

---

**Previous:** See `code-standards-swift.md` for formatting and naming conventions.
**Enforced By:** Code review & automated tests
**Last Updated:** February 2026
