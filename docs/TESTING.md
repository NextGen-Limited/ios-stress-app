<!-- generated-by: gsd-doc-writer -->
# Testing

How to run, write, and organize tests for StressMonitor.

---

## Overview

The project uses **XCTest** for unit testing. Test files live in `StressMonitorTests/` (bundle ID: `stress.ai.com.StressMonitorTests`).

Current test coverage focuses on:
- Stress algorithm components (HRV analysis, category ranges)
- Morning readiness scoring
- Stress history time ranges
- Stress prediction
- Stress reading model initialization

> **Note**: A comprehensive test suite rewrite is in progress (tracked as blocker B3). The current 5 test files cover core logic but many services lack dedicated tests yet.

---

## Running Tests

### From Xcode

1. Select the **StressMonitor** scheme.
2. Press `⌘U` to run all tests.
3. Or use the Test Navigator (`⌘6`) to run individual tests.

### From the Command Line

```bash
xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```

### Via the Python Runner

The project includes a test runner script that auto-detects a booted iPhone simulator:

```bash
python3 scripts/run-tests.py
```

This script finds a booted iPhone simulator (or boots one), runs the `StressMonitorTests` target, and reports results.

---

## Running Specific Tests

### Single Test Class

```bash
xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StressMonitorTests/HRVAnalyzerTests \
  -skipPackagePluginValidation
```

### Single Test Method

```bash
xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StressMonitorTests/MorningReadinessServiceTests/testComputeScoreAtBaseline \
  -skipPackagePluginValidation
```

---

## Test Files

| File | Tests |
|------|-------|
| `HRVAnalyzerTests.swift` | Stress category ranges, HRV analysis logic |
| `MorningReadinessServiceTests.swift` | Score computation at/above/below baseline |
| `StressHistoryTests.swift` | History time ranges (day/week/month), raw values |
| `StressPredictorTests.swift` | Stress prediction logic |
| `StressReadingTests.swift` | `StressReading` model initialization |

---

## Writing Tests

### Naming Convention

- Test methods: `test[Condition]` or `test[Method]_[Condition]`
- Examples: `testNormalStress`, `testComputeScoreAtBaseline`

### Floating Point Comparisons

Use `XCTAssertEqual` with `accuracy` for floating point values:

```swift
func testScoreAtBaseline() {
    let score = MorningReadinessService.computeScore(morningHRV: 60, baseline: 60)
    XCTAssertEqual(score, 50, accuracy: 1, "Score at baseline should be ~50")
}
```

### Test Structure

```swift
import XCTest
@testable import StressMonitor

final class MyServiceTests: XCTestCase {
    var service: MyService!

    override func setUp() {
        super.setUp()
        service = MyService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testNormalCase() async throws {
        let result = try await service.calculate(input: 50)
        XCTAssertEqual(result.level, 0, accuracy: 10)
    }
}
```

### Mocking Services

Use the protocol-based injection pattern. All services have protocols (e.g., `HealthKitServiceProtocol`, `StressAlgorithmServiceProtocol`, `StoreKitServiceProtocol`). Inject mock implementations in tests:

```swift
let vm = StressViewModel(
    healthKit: MockHealthKitService(),
    algorithm: MockStressAlgorithm()
)
```

The project includes `MockServices.swift` and `MockStoreKitService.swift` for this purpose.

---

## CI Testing

GitHub Actions runs build validation (not full test execution yet) on every PR via `.github/workflows/ci.yml` → `_test.yml`:

- **Lint & Build** (iOS Simulator) — SwiftLint + xcodebuild build
- **Build watchOS** — watchOS Simulator build
- **Build Widget** — Widget extension build

To run the full test suite in CI, trigger the `_test.yml` workflow with a test step or use the `scripts/run-tests.py` runner.

---

## Test Coverage Gaps

The following areas need dedicated tests (part of blocker B3):

- `MultiFactorStressCalculator` — weight normalization, graceful degradation
- Individual stress factors (`HRVStressFactor`, `HeartRateStressFactor`, etc.)
- `StressRepository` — CRUD, batch operations, sync queries
- `CloudKitSyncEngine` — sync orchestration, conflict resolution
- `SupabaseLLMService` — SSE parsing, context building
- `StoreKitService` — product fetching, transaction monitoring
- ViewModels — state transitions, error handling

---

## Related Docs

- [DEVELOPMENT.md](./DEVELOPMENT.md) — Coding conventions and mock patterns
- [CONFIGURATION.md](./CONFIGURATION.md) — CI workflow details
