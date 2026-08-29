# Testing Patterns

**Analysis Date:** 2026-08-29

## Test Framework

**Runner:**
- **Swift Testing** (`import Testing`) — primary framework, 33 of 35 test files
- **XCTest** — legacy, 2 files: `BioAgeCalculatorTests.swift`, `StressContextPayloadTests.swift` (both `StressMonitor/StressMonitorTests/`)
- Config: Xcode project `StressMonitor/StressMonitor.xcodeproj`, scheme `StressMonitor` (shared, at `StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme`). No `.xctestplan` files.

**Assertion Library:**
- Swift Testing: `#expect(...)`, `Issue.record("...")`
- XCTest: `XCTAssert*` family
- Floating-point comparisons use `accuracy:` (XCTest) per `AGENTS.md` — prescriptive rule; current suites mostly assert exact values/Sets

**Run Commands:**
```bash
# All tests (CI parity — mirrors .github/workflows/_test.yml)
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -parallel-testing-enabled NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Single class / single method
xcodebuild test ... -only-testing:StressMonitorTests/SSEParserTests
xcodebuild test ... -only-testing:StressMonitorTests/SSEParserTests/testMethod

# Local helper: finds/boots a simulator, passes its UUID, results in StressMonitor/build/
python3 scripts/run-tests.py
```
- Always run from the **repo root** with `-project StressMonitor/StressMonitor.xcodeproj`
- Keep `-parallel-testing-enabled NO` when reproducing CI failures — CI disables parallelism deliberately (`.github/workflows/_test.yml` also sets `-maximum-concurrent-test-simulator-destinations 1`)
- CI environment: Xcode 26.3, macos-15 runner, iPhone 16 / OS=latest

**CI behavior (`.github/workflows/_test.yml`, called by `ci.yml`):**
- `TEST_RUNNER_GSD_CI: "1"` env — forwarded (prefix stripped) into the test host to gate flaky suites (see Common Patterns)
- On failure uploads `raw-test-output.log` and `TestResults.xcresult` as artifacts (5-day retention)
- DerivedData and SPM checkouts cached, keyed on `project.pbxproj` / `Package.resolved`

## Test File Organization

**Location:**
- Single test target: `StressMonitor/StressMonitorTests/` (35 Swift files, ~5,600 LOC). Tests are co-located in one flat directory (no mirrors of app structure).
- **`StressMonitorTests/` at the repo root is orphaned (not in the Xcode project) — never add tests there; they will not run.**

**Naming:**
- Files: `XxxTests.swift` named after the SUT (`SSEParserTests.swift`, `StressAPIClientTests.swift`, `AccountViewModelTests.swift`)
- Feature-per-contract split instead of one mega-file: `StressAPIClientCreditsTests.swift`, `StressAPIClientPreferencesTests.swift`, `StressAPIClientSessionsTests.swift`, `StressAPIClientQuickActionsTests.swift`
- Test doubles live in the file that owns them and are reused across files (module-internal): `MockAuthService` defined in `StressAPIClientTests.swift` is used by 11 test files
- Support files: `StoreKitTestSessionProvider.swift` (shared SKTestSession), `StressMonitorProducts.storekit` (StoreKit config)

**Structure:**
```
StressMonitor/StressMonitorTests/
├── <SUT>Tests.swift           # one suite per SUT/contract
├── StoreKitTestSessionProvider.swift   # shared IAP test session helper
├── StressMonitorProducts.storekit      # StoreKit test catalog
└── ... (35 files, flat)
```

## Test Structure

**Suite Organization (canonical Swift Testing pattern):**
```swift
import Testing
import UIKit
@testable import StressMonitor

@Suite("Delete All Credential Clearance")
@MainActor
struct DataDeleterConsolidationTests {

    @Test("clearCredentialsAndSharedCaches removes the stored chat session id")
    func clearsStressChatSessionId() throws {
        UserDefaults.standard.set("seed-session-id", forKey: "stressChatSessionId")
        DataDeleterService.clearCredentialsAndSharedCaches()
        #expect(UserDefaults.standard.string(forKey: "stressChatSessionId") == nil)
    }
}
```
- Suites: `struct` named `XxxTests`, annotated `@MainActor` when touching UI/UserDefaults/SwiftData
- Every test gets a human-readable `@Test("...")` title; the method name restates it in camelCase
- XCTest legacy naming follows `test[Method]_[Condition]` (e.g. `testCalculateWithGoodHRVReturnsYoungerAge` in `BioAgeCalculatorTests.swift`) — use this style **only** when extending the two XCTest files
- Helper factories inside suites: `makeClient()`, `makeService()`, `makeSession()` (private, `private static let` constants for product IDs)

**Patterns:**
- Setup: constructor injection of test doubles; isolated persistence (`UserDefaults(suiteName: "StoreKitServiceTests-\(UUID().uuidString)")`, in-memory `ModelContainer`)
- Teardown: `defer { Self.cleanupDirectory(for: storeURL) }` for filesystem stores (see `StressMeasurementMigrationTests.swift`); XCTest files use `setUp`/`tearDown`
- Assertion: `#expect(value == expected, "explanation")` — trailing message explains the intent, not the failure

**Async testing:**
```swift
@Test("signInWithGoogle presents progress and calls the auth service once")
func signInWithGooglePresentsProgressAndCallsAuthService() async throws {
    let mock = MockAuthService(googleSignInError: nil, email: "linked@ripple.app")
    let viewModel = AccountViewModel(authService: mock)

    let signInTask = Task { try await viewModel.signInWithGoogle(presenting: UIViewController()) }
    await Task.yield()
    #expect(viewModel.isSigningIn)          // mid-flight state
    try await signInTask.value

    #expect(!viewModel.isSigningIn)
    #expect(mock.googleSignInCallCount == 1)
}
```

**Error testing:**
```swift
do {
    try await viewModel.signInWithGoogle(presenting: UIViewController())
    Issue.record("Expected sign-in to throw")
} catch {
    #expect(error is AuthServiceError)
}
```
- Pattern-decoding: `guard case .metadata(let metadata) = event else { Issue.record(...); return }` (Swift Testing has no `XCTThrowsError`)

## Mocking

**Framework:** None — all doubles are **hand-written** conformances to app protocols (`Services/Protocols/`, `Services/Auth/`, `Services/LLM/`, `Services/StoreKit/`)

**Patterns:**
```swift
// Mock = verification double with call counters (StressAPIClientTests.swift)
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    let token: String
    var email: String?
    private(set) var googleSignInCallCount = 0
    private(set) var lastPresentingViewController: UIViewController?
    init(token: String = "fake-token", ...) { ... }
    func getIDToken() async throws -> String { tokenCallCount += 1; return token }
}

// Fake = working stub (ChatLifecycleTests.swift, PremiumViewModelTests.swift)
final class FakeLLMService: LLMServiceProtocol { ... }
private final class FakeStoreKitService: StoreKitServiceProtocol { ... }
```
- Network stubbing via `URLProtocol` subclass: `RequestCaptureURLProtocol` (in `StressAPIClientTests.swift`) — `nonisolated(unsafe) static var` for `statusCode`, `responseBody`, `statusCodeSequence`, `responseByPath`, `capturedRequests`; installed on an `URLSessionConfiguration.protocolClasses`. **Reset all statics before each test that inspects them** (documented in the class doc comment)

**What to Mock:**
- Network (`URLSession` via `RequestCaptureURLProtocol`), auth (`MockAuthService` — fixed token, no live Firebase), LLM (`FakeLLMService`), StoreKit (`FakeStoreKitService` or `StoreKitTestSessionProvider`), CloudKit reset (`FakeCloudKitResetService`), server wipes (`FakeServerSessionWiper`)
- Reuse existing doubles before writing new ones — check `grep -rn "class Mock\|class Fake" StressMonitor/StressMonitorTests/`; duplicate sessions/doubles are explicitly called out as bugs in doc comments ("Reused by FirebaseAuthServiceTests — do not duplicate")

**What NOT to Mock:**
- SwiftData persistence — use real containers against in-memory stores or isolated on-disk URLs (`StressMeasurementMigrationTests`)
- The stress pipeline — use `-demo-mode` launch argument (cycles stress levels through the real pipeline; no HealthKit data exists on simulator)
- Keychain/UserDefaults in data-deletion suites — real `KeychainService` + real suites, asserted via `SecItemCopyMatching` status

## Fixtures and Factories

**Test Data:**
```swift
// Isolated defaults suite per test (StoreKitServiceTests.swift)
let suite = "StoreKitServiceTests-\(UUID().uuidString)"
let state = PremiumState(defaults: UserDefaults(suiteName: suite)!, key: "isPremiumUser")

// Inline SSE wire fixtures as raw string literals (SSEParserTests.swift)
let line = #"data: {"type":"metadata","session_id":"00000000-...","credits_remaining":42,"quick_actions":["breathe","reflect"]}"#

// Divergent legacy store seeded then migrated (StressMeasurementMigrationTests.swift)
let storeURL = Self.makeIsolatedStoreURL()
defer { Self.cleanupDirectory(for: storeURL) }
try Self.seedDivergentStore(at: storeURL)
let container = StressMonitorApp.makeContainer(at: storeURL)
```

**Location:**
- Fixtures are inline in the test file; shared helpers are `private` static funcs on the suite (`Self.makeIsolatedStoreURL()`, `Self.seedDivergentStore(at:)`)
- IAP catalog fixture: `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` (product IDs `com.stressmonitor.app.premium.{weekly,monthly,annual}`)

## Coverage

**Requirements:** None enforced — no coverage flags in CI or the scheme.

**View Coverage:**
```bash
# via xcodebuild result bundle produced by the test action
xcrun xcresulttool get --path StressMonitor/build/TestResults.xcresult ...
```

## Test Types

**Unit Tests:**
- All 35 files are unit tests running in the app host (`StressMonitorTests` bundle `stress.ai.com.StressMonitorTests`). Focus: API client contracts, parsers, ViewModels with injected doubles, StoreKit/IAP flows, SwiftData migration, widget data state, data deletion.

**Integration Tests:**
- Network-stack integration via `URLSession` + `RequestCaptureURLProtocol` (real encode/decode over stubbed HTTP responses)
- StoreKit integration via `StoreKitTest` shared session (see Common Patterns)

**E2E Tests:**
- Not used. No XCUITest target; no watch-target tests (`StressMonitor/StressMonitorWatch Watch App` has no test target; its directories are excluded from SwiftLint).
- Manual/QA on simulator: run the app with `-demo-mode` (Edit Scheme → Run → Arguments) — cycles all stress levels through the real pipeline. The `argent` MCP iOS-simulator skills are wired via `opencode.json` for simulator interaction.

## Common Patterns

**StoreKit test discipline (mandatory for any StoreKit-backed test):**
- `SKTestSession` connects exactly one session per process to its daemon — never call `SKTestSession(configurationFileNamed:)` directly in a test file. Always use `StoreKitTestSessionProvider.session()` (`StressMonitor/StressMonitorTests/StoreKitTestSessionProvider.swift`), which returns the shared session fully reset (`resetToDefaultState()`, `disableDialogs = true`)
- The `StressMonitorProducts.storekit` file is also referenced by the shared scheme's LaunchAction
- `StoreKitServiceTests` is disabled with a documented CI-only session-isolation bug (`@Suite(.serialized, .disabled("StoreKitTest session-isolation bug on CI — see file header"))`); `PremiumViewModelTests` against `FakeStoreKitService` carries the production-path coverage

**CI-only suite gating (do not "fix"):**
- `DataDeletionConsolidationTests` suites that touch real Keychain/CloudKit use `.enabled(if: ProcessInfo.processInfo.environment["GSD_CI"] == nil)` — they stall the CI test host (exit 65, zero assertion failures). CI sets `GSD_CI` via `TEST_RUNNER_GSD_CI` in `_test.yml`; locally they run normally. This is deliberate gating, not a bug.
- When adding a suite that manipulates real credentials/persistent state, apply the same `.enabled(if:)` gate.

**Contract-pinning headers:**
- Suite doc comments state which external contract is pinned and why a rename breaks silently (e.g. `SSEParserTests` pins the backend `quick_actions` field; `WidgetPublisherKeyMatchingTests` pins App Group keys). Follow this style for new wire-format tests.

**Stale docs warning:** `docs/TESTING.md` describes the orphaned repo-root `StressMonitorTests/` and an outdated XCTest-only setup — do not follow it; this file reflects the live target.

---

*Testing analysis: 2026-08-29*
