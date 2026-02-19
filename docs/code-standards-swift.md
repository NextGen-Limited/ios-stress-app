# Code Standards: Swift Formatting & Naming

**Framework:** Swift 5.9+ with SwiftUI & SwiftData
**Architecture:** MVVM + Protocol-Oriented Design
**Section:** File organization, naming, imports, state management
**Last Updated:** February 2026

---

## File Organization

### Naming Conventions

**Swift Files:** PascalCase (language standard)
```
Models/StressMeasurement.swift
Services/HealthKit/HealthKitManager.swift
Views/Dashboard/DashboardView.swift
```

**File Size Management:** Keep under 200 LOC
- Split large files into focused components
- Extract utilities into separate modules
- Use composition over inheritance

### Directory Structure

```
StressMonitor/
├── Models/                  # Data structures
├── Services/                # Business logic (organized by domain)
│   ├── HealthKit/
│   ├── Algorithm/
│   ├── Repository/
│   ├── CloudKit/
│   ├── DataManagement/
│   ├── Sync/
│   ├── Protocols/
│   └── ...
├── ViewModels/              # State management (@Observable)
├── Views/                   # SwiftUI screens (organized by feature)
├── Theme/                   # Design tokens
└── Utilities/               # Helper functions
```

---

## Swift Coding Style

### Imports

Group system frameworks alphabetically:
```swift
import Combine
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI

// Blank line, then project imports
import StressMonitorCore
```

### Indentation & Formatting

- **Indentation:** 2 spaces (not tabs)
- **Line Length:** 120 characters max
- **Braces:** Allman style (opening brace on same line)

```swift
func calculateStress(hrv: Double, heartRate: Double) -> Double {
  let normalized = (hrv - baseline) / baseline
  return normalized * 100
}
```

### Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Constants | camelCase | `let maxHeartRate = 200` |
| Variables | camelCase | `var currentStress = 0.0` |
| Functions | camelCase | `func calculateStress()` |
| Types | PascalCase | `struct StressMeasurement {}` |
| Enums | PascalCase | `enum StressCategory {}` |
| Properties | camelCase | `var stressLevel: Double` |
| Private | prefix `_` if needed | `private var _cache` |

### Comments

Use descriptive comments for complex logic only:
```swift
// Calculate normalized HRV deviation from baseline
let normalizedHRV = (baseline - current) / baseline
```

**No:** Over-commenting obvious code
```swift
// Set the stress level  ← Redundant
stressLevel = 50
```

---

## State Management

### ViewModels with @Observable

Use the `@Observable` macro (iOS 17+) for view state:

```swift
@Observable
final class StressViewModel {
  var currentStress: StressResult?
  var recentMeasurements: [StressMeasurement] = []
  var isLoading = false
  var errorMessage: String?

  private let healthKit: HealthKitServiceProtocol
  private let algorithm: StressAlgorithmServiceProtocol

  init(
    healthKit: HealthKitServiceProtocol = DefaultHealthKitService(),
    algorithm: StressAlgorithmServiceProtocol = StressCalculator()
  ) {
    self.healthKit = healthKit
    self.algorithm = algorithm
  }

  @MainActor
  func measureStress() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let hrv = try await healthKit.fetchLatestHRV()
      let hr = try await healthKit.fetchHeartRate(samples: 1)
      let result = try await algorithm.calculateStress(
        hrv: hrv?.value ?? 0,
        heartRate: hr.first?.value ?? 0
      )
      currentStress = result
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
```

**Key Rules:**
- Final class only (`final class`)
- All properties at top
- Dependencies via constructor injection
- @MainActor for UI updates
- No @State or @StateObject

---

## SwiftUI Views

### View Structure

```swift
struct DashboardView: View {
  @State var viewModel: StressViewModel

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          stressDisplaySection
          actionsSection
          historySection
        }
        .padding()
      }
      .navigationTitle("Stress Monitor")
    }
  }

  private var stressDisplaySection: some View {
    // Extracted view
  }

  private var actionsSection: some View {
    // Extracted view
  }

  private var historySection: some View {
    // Extracted view
  }
}
```

**Rules:**
- Extract subviews for clarity (>50 LOC)
- Use private `var` for extracted views
- One main layout in `body`
- Limit nesting depth to 3 levels

### View Modifiers

Group related modifiers:

```swift
// ✅ Good
Text("Stress Level")
  .font(.headline)
  .foregroundStyle(.primary)
  .padding()
  .background(Color.stressColor(for: .relaxed))
  .cornerRadius(8)

// ❌ Don't scatter modifiers
Text("Stress Level")
  .padding()
  .font(.headline)
  .cornerRadius(8)
  .foregroundStyle(.primary)
```

### Accessibility

Always include accessibility labels:

```swift
Button(action: { viewModel.measureStress() }) {
  Label("Measure", systemImage: "waveform.circle.fill")
}
.accessibilityLabel("Measure stress level")
.accessibilityHint("Fetches your current HRV and heart rate")
```

---

## Performance Guidelines

### Avoid Main Thread Blocking

Use background queues for heavy computation:

```swift
// ✅ Good
func calculateStress() async throws -> StressResult {
  return try await Task.detached(priority: .userInitiated) {
    // Heavy computation on background thread
    let result = computeStress()
    return result
  }.value
}

// ❌ Don't block main thread
func calculateStress() -> StressResult {
  // Blocks UI while computing
  return computeStress()
}
```

### Lazy Evaluation

Load data only when needed:

```swift
// ✅ Good - Fetch on demand
struct HistoryView: View {
  @State var measurements: [StressMeasurement] = []

  var body: some View {
    List(measurements) { measurement in
      MeasurementRow(measurement)
    }
    .task {
      measurements = try await repository.fetchRecent(limit: 50)
    }
  }
}

// ❌ Don't load everything upfront
var allMeasurements: [StressMeasurement] = loadAll()
```

---

## Code Quality Checklist

- [ ] No compiler warnings
- [ ] All tests passing
- [ ] Test coverage >80% for core logic
- [ ] No force unwraps (`!`) unless unavoidable
- [ ] Error handling with `throws` or `Result`
- [ ] Access control (private/public) appropriate
- [ ] Comments for non-obvious logic
- [ ] File size <200 LOC
- [ ] No dead code or unused imports
- [ ] Accessibility labels on interactive elements
- [ ] No global state or singletons
- [ ] Protocol-based dependencies

---

**Next:** See `code-standards-patterns.md` for dependency injection, async/await, SwiftData, testing, and error handling patterns.
**Enforced By:** Code review & automated tests
**Last Updated:** February 2026
