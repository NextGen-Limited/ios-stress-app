# iOS Stress App - Agent Guidelines

This is a planning repository for a stress monitoring iOS/watchOS app. No implementation exists yet.

## Build & Test Commands

```bash
# Build iOS app
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build watchOS app
xcodebuild -scheme StressMonitorWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9' build

# Run all tests
xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15'

# Run single test class
xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:StressMonitorTests/StressCalculatorTests

# Run single test method
xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:StressMonitorTests/StressCalculatorTests/testNormalStress
```

## Tech Stack

- **Minimum iOS:** 17.0
- **Language:** Swift 5.9+
- **UI:** SwiftUI (no UIKit)
- **Persistence:** SwiftData
- **Health Data:** HealthKit
- **Sync:** CloudKit
- **Dependencies:** None - system frameworks only

## Project Structure

```
StressMonitor/
├── App/
│   └── StressMonitorApp.swift
├── Models/
│   ├── HRVMeasurement.swift
│   └── StressMeasurement.swift
├── ViewModels/
│   └── StressViewModel.swift
├── Views/
│   ├── DashboardView.swift
│   └── Components/
├── Services/
│   ├── HealthKit/
│   ├── Algorithm/
│   └── Repository/
└── Resources/
```

## Code Style

### Imports
Group system frameworks alphabetically. No blank line between groups.
```swift
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI
```

### Naming
- **Types:** `PascalCase` (e.g., `StressViewModel`, `HRVMeasurement`)
- **Methods/Properties:** `camelCase` (e.g., `calculateStress`, `currentStress`)
- **Protocols:** `PascalCase` + `Protocol` suffix (e.g., `HealthKitServiceProtocol`)

### State Management
Use `@Observable` macro (iOS 17+) for ViewModels:
```swift
@Observable
class StressViewModel {
    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?
}
```

### Error Handling
Define domain-specific errors as enums:
```swift
enum AlgorithmError: Error {
    case noData
    case insufficientData
}
```

Use `do-catch` with descriptive error messages:
```swift
do {
    let result = try await algorithm.calculateStress(hrv: hrv, heartRate: heartRate)
} catch {
    errorMessage = "Failed to calculate stress: \(error.localizedDescription)"
}
```

### Async/Await
Prefer `async`/`await` over callbacks:
```swift
func fetchAndCalculate() async {
    isLoading = true
    defer { isLoading = false }

    do {
        let hrv = try await healthKit.fetchLatestHRV()
        currentStress = try await algorithm.calculateStress(hrv: hrv.value, heartRate: 70)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### SwiftData Models
Use `@Model` macro for persisted entities:
```swift
@Model
final class StressMeasurement {
    var timestamp: Date
    var stressLevel: Double
    var hrv: Double

    init(timestamp: Date, stressLevel: Double, hrv: Double) {
        self.timestamp = timestamp
        self.stressLevel = stressLevel
        self.hrv = hrv
    }
}
```

### Dependency Injection
Protocol-based with constructor injection:
```swift
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchLatestHRV() async throws -> HRVMeasurement?
}

class StressViewModel {
    private let healthKit: HealthKitServiceProtocol

    init(healthKit: HealthKitServiceProtocol = DefaultHealthKitService()) {
        self.healthKit = healthKit
    }
}
```

### SwiftUI Views
- Use `@State` for local view state
- Use `@Environment` for framework-provided values
- Prefer `.task {}` over `.onAppear { Task {} }` for async work

### Organization
Use `MARK` comments to group related code:
```swift
// MARK: - Normalization
// MARK: - Component Calculations
// MARK: - Confidence
```

### Testing
- Use XCTest with async test support
- Name tests: `test[Condition]` or `test[Method]_[Condition]`
- Use `XCTAssertEqual` with `accuracy` parameter for floating point comparisons

```swift
func testNormalStress() async throws {
    let result = try await calculator.calculateStress(hrv: 50, heartRate: 60)
    XCTAssertEqual(result.level, 0, accuracy: 10)
    XCTAssertEqual(result.category, .relaxed)
}
```

## Architecture Principles

1. **MVVM** with Observable ViewModels
2. **Protocol-oriented** design for testability
3. **Async-first** concurrency
4. **Privacy-first** - local storage, no third-party analytics
5. **Native-only** - no external dependencies

## Implementation Phases

Follow the phased approach in `documentation/references/`:
1. Project Foundation
2. Data Layer
3. Core Algorithm
4. iPhone UI
5. watchOS App
6. Background Notifications
7. Data Sync
8. Testing & Polish
