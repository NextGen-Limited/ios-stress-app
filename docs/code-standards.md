# Code Standards & Conventions: Overview

**Framework:** Swift 5.9+ with SwiftUI & SwiftData
**Architecture:** MVVM + Protocol-Oriented Design
**Last Updated:** February 2026

---

## Overview

Code standards ensure consistency, maintainability, and quality across the StressMonitor codebase. All code must follow these conventions before review and merge.

## Quick Links

### Swift Formatting & Naming
Foundation of our code style:
- **[Code Standards: Swift](./code-standards-swift.md)** - File organization, naming conventions, imports, indentation, state management (@Observable), SwiftUI views

### Design Patterns & Testing
Advanced patterns and quality practices:
- **[Code Standards: Patterns](./code-standards-patterns.md)** - Dependency injection, async/await, SwiftData models, testing conventions, error handling, common patterns, performance targets

---

## Code Quality Standards

### Mandatory Checks

Before committing code, verify:

- [ ] No compiler warnings
- [ ] All tests passing (100+ tests)
- [ ] Test coverage >80% for core logic
- [ ] No force unwraps (`!`) unless unavoidable
- [ ] Error handling with `throws` or `Result`
- [ ] Access control (private/public) appropriate
- [ ] Comments for non-obvious logic only
- [ ] File size <200 LOC
- [ ] No dead code or unused imports
- [ ] Accessibility labels on interactive elements
- [ ] No global state or singletons
- [ ] Protocol-based dependencies

### Performance Targets

| Metric | Target |
|--------|--------|
| Stress Calculation | <1 second |
| View Render Time | <16ms (60 FPS) |
| Memory (Idle) | <50 MB |
| Memory (After 100 measurements) | <100 MB |
| CloudKit Sync | <30 seconds |
| App Launch | <2 seconds |

---

## File Organization

```
StressMonitor/
├── Components/              # Shared UI components
│   └── Character/           # StressBuddy illustration + animations
├── Models/                  # Data structures
├── Services/                # Business logic
│   ├── HealthKit/
│   ├── Algorithm/
│   ├── Repository/
│   ├── CloudKit/
│   ├── DataManagement/
│   ├── Sync/
│   ├── Protocols/
│   └── ...
├── ViewModels/              # State management (@Observable)
├── Views/                   # SwiftUI screens
├── Theme/                   # Design tokens
└── Utilities/               # Helper functions
```

**Key Rules:**
- PascalCase for Swift files
- Keep files under 200 lines of code
- Group related functionality by domain
- One public type per file (usually)

---

## State Management

All ViewModels must use `@Observable` macro (iOS 17+):

```swift
@Observable
final class StressViewModel {
  var currentStress: StressResult?
  var isLoading = false
  var errorMessage: String?

  private let healthKit: HealthKitServiceProtocol
  private let algorithm: StressAlgorithmServiceProtocol

  @MainActor
  func measureStress() async {
    // Implementation
  }
}
```

---

## Dependency Injection

Always use protocols for dependencies:

```swift
// ✅ Good
class StressViewModel {
  private let healthKit: HealthKitServiceProtocol

  init(healthKit: HealthKitServiceProtocol = HealthKitManager()) {
    self.healthKit = healthKit
  }
}

// ❌ Bad - Global singleton
class HealthKitManager {
  static let shared = HealthKitManager()
}
```

---

## Async/Await

Prefer `async/await` over callbacks:

```swift
// ✅ Good
func fetchStress() async throws -> StressResult {
  let hrv = try await healthKit.fetchLatestHRV()
  return try await algorithm.calculateStress(hrv: hrv.value)
}

// ❌ Bad - Callback hell
func fetchStress(completion: @escaping (Result<StressResult, Error>) -> Void) {
  // ...
}
```

---

## Testing Requirements

All services and ViewModels must have tests:

```swift
final class StressCalculatorTests: XCTestCase {
  private var calculator: StressCalculator!

  override func setUp() async throws {
    try await super.setUp()
    calculator = StressCalculator()
  }

  func testNormalStress() async throws {
    let result = try await calculator.calculateStress(hrv: 50, heartRate: 70)
    XCTAssertEqual(result.level, 15, accuracy: 5)
  }
}
```

---

## Code Review Process

All pull requests must pass:

1. **Automated Checks**
   - Compile without warnings
   - All tests pass
   - No linting errors

2. **Code Review**
   - Follows these standards
   - Clean, readable code
   - Appropriate error handling
   - Test coverage >80%

3. **Manual Testing**
   - Tested on iOS device
   - Tested on watch (if applicable)
   - Accessibility verified

---

**Enforced By:** Code review & automated tests
**Last Updated:** February 2026
