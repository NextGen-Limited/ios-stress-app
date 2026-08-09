# Testing Patterns

**Analysis Date:** 2026-08-08

> **BLOCKING FACT — no test target exists.** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`
> declares 2 × `com.apple.product-type.application` (iPhone, Watch) and 1 ×
> `com.apple.product-type.app-extension` (Widget). It declares **zero**
> `com.apple.product-type.bundle.unit-test` targets. Both test directories —
> `StressMonitor/StressMonitorTests/` and the repo-root `StressMonitorTests/` — are orphaned.
> **No test in this repo can currently run.** Every run command, coverage claim, and
> "wired-up target" reference below describes the intended state, not the actual one.
> Creating a unit-test bundle target is the prerequisite for all of it.

## Test Framework

**Runners — both are in use, deliberately mixed:**
- **Swift Testing** (`import Testing`, `@Test`, `#expect`) — the newer convention. Used by `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift`, `StoreKitProductCatalogTests.swift`, `CharacterAssetResolverTests.swift`, `CharacterCollectionViewModelTests.swift`.
- **XCTest** (`import XCTest`, `XCTestCase`) — used by `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift` and by the entire orphaned root `StressMonitorTests/` directory.

**Use Swift Testing for new tests.** XCTest remains only where `setUp`/`tearDown` lifecycle is already established.

**Assertions:** `#expect(...)` (Swift Testing) or `XCTAssert*` (XCTest). Floating point comparisons use `XCTAssertLessThan`/`XCTAssertGreaterThan` against a documented threshold rather than `accuracy:` in current code — `CLAUDE.md` prescribes `XCTAssertEqual(..., accuracy:)`; either is acceptable, but always state the tolerance.

**Run Commands:**
```bash
# Canonical entry point — resolves/boots a simulator, then runs the suite
python3 scripts/run-tests.py

# CI mode (name-based destination, code coverage on)
CI=1 python3 scripts/run-tests.py

# Raw equivalent
xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:StressMonitorTests \
  -resultBundlePath StressMonitor/build/TestResults.xcresult
```

`scripts/run-tests.py` prefers an already-booted iPhone locally, otherwise picks from an ordered preference list (iPhone 16 → 17 → 15 → …), boots it via `simctl bootstatus`, and passes a UDID destination. In CI it switches to a name-based destination because UUID resolution between `simctl` and `xcodebuild` is unreliable. Result bundle lands at `StressMonitor/build/TestResults.xcresult`.

Xcode-MCP equivalents (`mcp__plugin_xclaude-plugin_xc-all__xcode_test` with `only_testing:`) are documented in `CLAUDE.md` for single-class/method runs.

## Test File Organization

**Location:** separate test target directory, not co-located with sources.

```
StressMonitor/
├── StressMonitor/            # app sources
└── StressMonitorTests/       # NOT wired into any target — see blocking note at top
    ├── BioAgeCalculatorTests.swift          (350 lines, XCTest)
    ├── PremiumViewModelTests.swift          (276 lines, Swift Testing)
    ├── StoreKitProductCatalogTests.swift    (173 lines, Swift Testing)
    ├── CharacterAssetResolverTests.swift    (59 lines,  Swift Testing)
    └── CharacterCollectionViewModelTests.swift (54 lines, Swift Testing)
```

**Naming:** `<TypeUnderTest>Tests.swift`; suite type is `struct <Type>Tests` (Swift Testing) or `final class <Type>Tests: XCTestCase`. Test methods are `lowerCamelCase` behaviour names (`loadInitialDataLoadsPlans`, `testCalculateWithGoodHRVReturnsYoungerAge`).

**Orphaned directory — important:** the repo-root `StressMonitorTests/` (`HRVAnalyzerTests.swift`, `StressPredictorTests.swift`, `MorningReadinessServiceTests.swift`, `StressReadingTests.swift`, `StressHistoryTests.swift`, ~28KB, last touched 2025-05-31) is **not referenced by `StressMonitor.xcodeproj`** and is excluded from SwiftLint. It targets the legacy source set at `StressMonitor/Services/HRVAnalyzer.swift` etc. These tests never run. Do not add to them; either wire them into the target or delete them.

## Test Structure

**Swift Testing suite (preferred):**
```swift
import Foundation
import Testing
@testable import StressMonitor

@MainActor
struct PremiumViewModelTests {

    /// Helper to create an isolated PremiumState that doesn't pollute real UserDefaults.
    private func makeIsolatedState(isPremium: Bool = false) -> PremiumState {
        let defaults = UserDefaults(suiteName: "PremiumViewModelTests_\(UUID().uuidString)")!
        let state = PremiumState(defaults: defaults, key: "isPremiumUser")
        state.isPremiumUser = isPremium
        return state
    }

    @Test("loadInitialData loads plans")
    func loadInitialDataLoadsPlans() async {
        let service = FakeStoreKitService()
        let vm = PremiumViewModel(storeKit: service, premiumState: makeIsolatedState())
        await vm.loadInitialData()
        #expect(vm.plans.count == service.stubbedPlans.count)
    }
}
```

**XCTest suite:**
```swift
final class BioAgeCalculatorTests: XCTestCase {
    private var calculator: BioAgeCalculator!
    override func setUp() { super.setUp(); calculator = BioAgeCalculator() }
    override func tearDown() { calculator = nil; super.tearDown() }
}
```

Patterns to follow:
- `@MainActor` on the suite whenever it touches an `@Observable @MainActor` ViewModel or `ModelContext`.
- No shared setup in Swift Testing suites — build fresh state per `@Test` via a `private func make...()` helper. Suites are structs, so each test gets a new instance.
- `@Test("human readable description")` on every test; the string is the spec.
- Assertions carry an explanatory message where the threshold is a judgement call: `XCTAssertLessThan(result!.estimatedAge, 35, "High HRV with low RHR should estimate younger bio age")`.

## Mocking

**Approach: hand-written protocol doubles. No mocking framework, no code generation.**

Two distinct families:

**1. Test-local fakes** — declared `private final class Fake<X>: <X>Protocol` inside the test file, with stub properties and closure hooks:
```swift
private final class FakeStoreKitService: StoreKitServiceProtocol {
    var stubbedPlans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans
    var stubbedIsPremiumUser: Bool = false
    var purchaseStub: (() async throws -> Void)?
    var didCallRefresh = false

    var availablePlans: [SubscriptionPlan] { get async { stubbedPlans } }
    func purchase(_ plan: SubscriptionPlan) async throws { try await purchaseStub?() }
    func refreshEntitlements() async { didCallRefresh = true }
}
```
Convention: `stubbed*` for canned returns, `*Stub` closures for behaviour/error injection, `didCall*` booleans for interaction assertions.

**2. Shipping mocks in the app target** — `StressMonitor/StressMonitor/Services/MockServices.swift` (`MockHealthKitService`, `MockStressAlgorithmService`, `MockStressRepository`) and `Services/StoreKit/MockStoreKitService.swift`. These exist primarily to feed the 119 `#Preview` blocks and are also available to tests. They expose `mockHRV`, `mockHeartRate`, `mockSleepData`, … plus `shouldThrowError: Bool` to drive the failure path. They are `@unchecked Sendable`.

**What to mock:** anything behind a `...ServiceProtocol` — HealthKit, StoreKit, CloudKit, the LLM service, the repository. Inject via the initializer default-parameter seam.

**What NOT to mock:** the stress algorithm itself (`MultiFactorStressCalculator` and the five `StressFactor` implementations are pure and fast — test them directly), `DesignTokens`/pure value types, and SwiftData — use a real in-memory container instead.

**SwiftData in tests** — use an in-memory `ModelContainer`, never the app store:
```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
let ctx = container.mainContext
let vm = CharacterCollectionViewModel()
vm.configure(modelContext: ctx)
```

**UserDefaults in tests** — always a per-test suite name seeded with a UUID (`makeIsolatedState()` above). Never touch `UserDefaults.standard`.

## Simulator / Demo-Mode Harness

Not a test target, but the primary manual-verification path for anything HealthKit-driven (the simulator has no health data):

- Launch argument `-demo-mode`, checked by `enum DemoMode` in `StressMonitor/StressMonitorApp.swift`; consumed by `ViewModels/StressViewModel.swift:477` and `Views/MainTabView.swift`.
- `Services/HealthKit/SimulatorHealthKitService.swift` (whole file wrapped in `#if DEBUG`) generates time-varying 5-factor data, cycling `relaxed → mild → moderate → high → edgeLowHRV` every 30s and emitting live HR through `AsyncStream`. The `edgeLowHRV` scenario deliberately omits sleep/activity/recovery to exercise weight redistribution.
- `Views/Components/DemoModeBannerView.swift` renders the on-screen "DEMO MODE" pill.
- It runs the real `MultiFactorStressCalculator` + SwiftData pipeline, so it validates integration, not just rendering.

Use demo mode to verify UI states that unit tests cannot reach; do not use it as a substitute for a unit test of the calculator.

## Coverage

**No coverage threshold is enforced anywhere.** `-enableCodeCoverage YES` is passed only in CI mode of `scripts/run-tests.py`, and nothing gates on the number.

```bash
CI=1 python3 scripts/run-tests.py
xcrun xccov view --report StressMonitor/build/TestResults.xcresult
```

## CI

`.github/workflows/ci.yml` delegates to the reusable `.github/workflows/_test.yml`, which despite the name runs **three build jobs and zero test jobs**:

| Job | What it does |
|-----|--------------|
| `lint-and-build` | SwiftLint (`\|\| true` — non-blocking), then `xcodebuild build` for scheme `StressMonitor`, `generic/platform=iOS Simulator` |
| `build-watchos` | `xcodebuild build` for `"StressMonitorWatch Watch App"` |
| `build-widget` | `xcodebuild build` for `StressMonitorWidgetExtension` |

Xcode 26.3 on `macos-15`, with DerivedData and SPM caches. `xcodebuild test` is never invoked, and SwiftLint failures do not fail the build. Distribution runs through `fastlane` (`fastlane/Fastfile`: `build_widget`, `upload_beta`, `distribute_beta`, `release`) and `ci_scripts/ci_post_clone.sh` / `ci_post_xcodebuild.sh` for Xcode Cloud.

## Test Types

**Unit tests:** the only kind present. Pure calculators (`BioAgeCalculatorTests`), catalog/resolver logic (`StoreKitProductCatalogTests`, `CharacterAssetResolverTests`), and ViewModels with injected fakes (`PremiumViewModelTests`, `CharacterCollectionViewModelTests`).

**Integration tests:** none. `CharacterCollectionViewModelTests` is the closest — ViewModel over a real in-memory SwiftData container.

**UI / E2E tests:** none. No XCUITest target exists (`.swiftlint.yml` excludes a `StressMonitorWatch Watch AppUITests` path that has no sources). UI verification is manual via simulator + demo mode, or via the `idb_*` MCP tools documented in `CLAUDE.md`.

**Watch / Widget tests:** none. Neither target has a test bundle.

## Common Patterns

**Async testing:**
```swift
@Test("loadInitialData loads plans")
func loadInitialDataLoadsPlans() async {
    await vm.loadInitialData()
    #expect(vm.plans.isEmpty == false)
}
```
Swift Testing tests are plain `async`; no expectations/waiters. For throwing paths mark the test `async throws` and `try`.

**Error testing:** inject via the fake's closure hook rather than a separate mock type —
```swift
service.purchaseStub = { throw StoreKitError.purchaseFailed }
await vm.purchase(plan)
#expect(vm.errorMessage != nil)
```
For the shipping mocks, flip `mockService.shouldThrowError = true`.

**Interaction assertions:** `#expect(service.didCallRefresh)`.

## Coverage Gaps

Ranked by risk.

**Core stress algorithm — untested. HIGH.**
`Services/Algorithm/MultiFactorStressCalculator.swift`, `StressCalculator.swift`, `BaselineCalculator.swift`, and all five `StressFactor` implementations (HRV, HeartRate, Sleep, Activity, Recovery) have no tests in the wired-up target. Weight redistribution when factors are missing, the `guard !results.isEmpty else { throw StressError.noData }` path, and the 0–100 clamping are all unverified. This is the product's central logic.

**`StressViewModel` — untested. HIGH.**
The largest ViewModel: HealthKit observer wiring, the 60s refresh debounce, `isPermissionRequired` set only on `HKError.errorAuthorizationDenied`, and the `isRequestingAccess` re-entry guard. `MockHealthKitService` already exists, so this is cheap to cover.

**Persistence & sync — untested. HIGH.**
`Services/Repository/StressRepository.swift`, `Services/Sync/SyncManager.swift`, `Services/Sync/ConflictResolver.swift`, `Services/CloudKit/CloudKitSyncEngine.swift`. Conflict resolution and the `cloudKitModTime`/`isSynced` bookkeeping on `StressMeasurement` are silent-data-loss territory.

**Chat / LLM contract — untested. MEDIUM.**
`Services/LLM/SSEParser.swift` and `SupabaseLLMService.swift` parse a non-standard terminal `metadata` SSE event before `[DONE]`. `SSEParser` is pure and trivially testable; a backend contract change would currently break silently. `ChatViewModel` and `ChatContextBuilder` are also uncovered.

**Data export / deletion — untested. MEDIUM.**
`Services/DataManagement/{DataExporter, DataDeleter, LocalDataWipeService, CloudKitResetService}.swift` — destructive and user-facing (GDPR-style delete).

**watchOS and Widget targets — zero tests. MEDIUM.**
Both duplicate model/service code from the iOS target with no verification that they stay in sync.

**CI does not run tests at all. HIGH (process gap).**
`scripts/run-tests.py` exists and works but is not invoked by any workflow, so all five suites can regress unnoticed. Adding a `test` job that calls `CI=1 python3 scripts/run-tests.py` is the single highest-leverage fix.

**Root `StressMonitorTests/` is dead. LOW (cleanup).**
Five files / ~28KB of XCTest that are not in the project and cannot compile against the current target.

---

*Testing analysis: 2026-08-08*
