# Testing

The test suite lives in `StressMonitor/StressMonitorTests/`. Tests use `XCTest` and follow `test[Method]_[Condition]` or `test[Condition]` naming.

## Current coverage

Five test files, ~756 lines total. This is sparse relative to the ~54K lines of app code, and expanding the suite is the current B3 ship blocker (per `docs/KANBAN-SHIP-READINESS.md`).

| File | Covers |
| --- | --- |
| `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift` | `BioAgeCalculator` edge cases |
| `StressMonitor/StressMonitorTests/CharacterAssetResolverTests.swift` | Character asset name resolution |
| `StressMonitor/StressMonitorTests/CharacterCollectionViewModelTests.swift` | Character collection view model |
| `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift` | Premium view model and plan selection |
| `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift` | Product ID resolution from config |

A separate test bundle under `StressMonitor/StressMonitorTests/` (the inner directory) contains older tests covering HRV analysis, morning readiness, stress history, and stress prediction.

## Running tests

```bash
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

Scope to a single class:

```bash
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:StressMonitorTests/BioAgeCalculatorTests
```

A Python wrapper with retries is at `scripts/run-tests.py`.

The `xc-all` MCP plugin (documented in `CLAUDE.md`) exposes `xcode_test`, `xcode_build`, `xcode_clean`, and `simulator_*` tools that wrap the same invocations.

## Patterns

- Inject mock services through protocol-based initializers. `MockServices.swift` and `MockStoreKitService.swift` provide canned implementations.
- Use `XCTAssertEqual` with `accuracy:` for floating-point comparisons. The stress calculator outputs are continuous and should never be compared for exact equality.
- Mark async tests with `async throws` and use `await` for service calls.
- For HealthKit-dependent code, substitute `SimulatorHealthKitService` or a custom `HealthKitServiceProtocol` mock; never depend on the simulator having HealthKit data.

## What to test when adding code

- **New stress factor**: test that `calculate(context:)` returns `nil` when its input is missing and returns a value in [0, 1] with confidence in [0, 1] when present.
- **New view model state**: test the state transitions and the outputs the VM exposes to SwiftUI.
- **New StoreKit product ID resolution**: test that `StoreKitProductCatalog` resolves IDs from each source (Info.plist, env, UserDefaults) and treats `$(...)` placeholders as nil.
- **New algorithm threshold**: test the boundary values explicitly.
