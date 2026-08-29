# Testing Patterns

**Analysis Date:** 2026-08-29

## Test Framework

**Runner:**
- **Swift Testing** (`import Testing`) — primary framework, 33 of 35 test files
- **XCTest** — legacy, 2 files: `BioAgeCalculatorTests.swift`, `StressContextPayloadTests.swift` (both `StressMonitor/StressMonitorTests/`)
- Config: Xcode project `StressMonitor/StressMonitor.xcodeproj`, scheme `StressMonitor` (shared, at `StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme`; sibling scheme `StressMonitorWatch Watch App.xcscheme` has no test action). No `.xctestplan` files.
- Scale: 16 `@Suite` declarations, 217 `@Test` functions (214 carry human-readable titles)

**Assertion Library:**
- Swift Testing: `#expect(...)`, `Issue.record("...")`, `try #require(...)` for unwraps
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
- Keep `-parallel-testing-enabled NO` when reproducing CI failures — CI disables parallelism deliberately (`.github/workflows/_test.yml` also sets `-maximum-concurrent-test-simulator-destinations 1`). Suites share process-wide static state (`RequestCaptureURLProtocol` statics, one shared `SKTestSession`); parallel test hosts break both assumptions.
- CI environment: Xcode 26.3, macos-15 runner, iPhone 16 / OS=latest

**CI behavior (`.github/workflows/_test.yml`, called by `ci.yml`):**
- Also builds iOS, watchOS, and widget-extension targets in separate jobs (all `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`)
- SwiftLint runs in the lint-and-build job (`swiftlint lint --reporter github-actions-logging || true` — advisory)
- `TEST_RUNNER_GSD_CI: "1"` env — forwarded (prefix stripped) into the test host to gate flaky suites (see Common Patterns)
- On failure uploads `raw-test-output.log` and `TestResults.xcresult` as artifacts (5-day retention)
- DerivedData and SPM checkouts cached, keyed on `project.pbxproj` / `Package.resolved`

## Test File Organization

**Location:**
- Single test target: `StressMonitor/StressMonitorTests/` (36 Swift files — 35 test files + 1 support file — ~5,600 LOC). Tests are co-located in one flat directory (no mirrors of app structure).
- **`StressMonitorTests/` at the repo root is orphaned (0 references in `project.pbxproj`) — never add tests there; they will not run.**

**Naming:**
- Files: `XxxTests.swift` named after the SUT (`SSEParserTests.swift`, `StressAPIClientTests.swift`, `AccountViewModelTests.swift`)
- Feature-per-contract split instead of one mega-file: `StressAPIClientCreditsTests.swift`, `StressAPIClientPreferencesTests.swift`, `StressAPIClientSessionsTests.swift`, `StressAPIClientQuickActionsTests.swift`
- Test doubles live in the file that owns them and are reused across files (module-internal): `MockAuthService` defined in `StressAPIClientTests.swift` is used by 10 test files. **Doubles must be members of the test target, never the app target** (stated convention in `CreditPurchaseFlowTests.swift`'s `MockCreditService` doc comment)
- Support files: `StoreKitTestSessionProvider.swift` (shared SKTestSession), `StressMonitorProducts.storekit` (StoreKit config)

**Structure:**
```
StressMonitor/StressMonitorTests/
├── <SUT>Tests.swift           # one suite per SUT/contract (35 files)
├── StoreKitTestSessionProvider.swift   # shared IAP test session helper
├── StressMonitorProducts.storekit      # StoreKit test catalog
└── ... (flat, no subdirectories)
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
- Helper factories inside suites: `makeClient()`, `makeService()`, `makeSession()` (private, `private static let` constants for product IDs). The factory is also where URLProtocol statics get reset (see Mocking)
- Suite-level `///` doc comments state what external contract the suite pins (see Contract-pinning headers below)

**Patterns:**
- Setup: constructor injection of test doubles; isolated persistence (`UserDefaults(suiteName: "StoreKitServiceTests-\(UUID().uuidString)")`, in-memory or isolated-on-disk `ModelContainer`); local `@Model` fixtures declared inside the test file when the migration scenario needs a shape the app no longer ships (`LegacyShape` in `ModelContainerRecoveryTests.swift`)
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
- Ordering under `async let` is asserted by polling with a deadline, not by assuming dispatch order (`PreferencesServiceTests.swift`):
```swift
let deadline = Date().addingTimeInterval(5)
while RequestCaptureURLProtocol.capturedRequests.filter({ $0.httpMethod == "PUT" }).count < count,
      Date() < deadline {
    await Task.yield()
    try? await Task.sleep(nanoseconds: 1_000_000)
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
- Error **copy** is itself pinned: `AuthServiceErrorTests` / `LLMServiceErrorTests` assert `errorDescription` wording so an auth failure can never render as an "AI outage" again (regression from v1.0 documented in the suite header)

## Mocking

**Framework:** None — all doubles are **hand-written** conformances to app protocols (`Services/Protocols/`, `Services/Auth/`, `Services/LLM/`, `Services/StoreKit/`, `Services/Credits/`)

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

**Network stubbing — URLProtocol doubles:**
- `RequestCaptureURLProtocol` (`StressMonitor/StressMonitorTests/StressAPIClientTests.swift:66`) — the workhorse: `nonisolated(unsafe) static var` for `lastRequest`, `statusCode`, `responseBody`, `statusCodeSequence`, `responseByPath`, `capturedRequests`; installed on an `URLSessionConfiguration.ephemeral.protocolClasses`. Reused by 8 files (`StressAPIClient*Tests`, `CreditServiceTests`, `PreferencesServiceTests`, `ChatHistoryRestoreTests`)
- `DelayedResponseURLProtocol` (`StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift:470`) — same shape plus `delayMS`, for race/ordering tests that need the stubbed response to land *after* the code under test moves on
- **Reset discipline (mandatory):** the statics are process-global and suites run in one host. Reset **all** of them inside your `makeClient()`/`makeService()` factory, and `defer { RequestCaptureURLProtocol.responseByPath = nil }` when a test uses `responseByPath` — its precedence over single-response statics causes cross-suite order-dependent pollution otherwise (open defect `.planning/WINDOWS.md` #12: a stale `/preferences` stub from `ChatHistoryRestoreTests` failed 10 assertions in later suites)

**What to Mock:**
- Network (`URLSession` via the URLProtocol doubles above), auth (`MockAuthService` — fixed token, no live Firebase), LLM (`FakeLLMService`), StoreKit (`FakeStoreKitService`, or `FakePurchaseTransaction: PurchaseTransactionHandle` — the protocol seam at `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:13` that stands in for a StoreKit `Purchase` without StoreKitTest), CloudKit reset (`FakeCloudKitResetService`), server wipes (`FakeServerSessionWiper` — scripted page sequences), credits (`MockCreditService`)
- Firebase cannot be mocked through the SDK (`Auth.app()` singleton) — `FirebaseAuthServiceTests` instead pins the **injectability contract**: `FirebaseAuthService.init` stays lazy (no `Auth.app()` touch), and `MockAuthService` substitutes cleanly through `AuthServiceProtocol`
- Reuse existing doubles before writing new ones — check `grep -rn "class Mock\|class Fake" StressMonitor/StressMonitorTests/`; duplicate sessions/doubles are explicitly called out as bugs in doc comments ("Reused by FirebaseAuthServiceTests — do not duplicate")

**What NOT to Mock:**
- SwiftData persistence — use real containers against in-memory stores or isolated on-disk URLs (`StressMeasurementMigrationTests`, `ModelContainerRecoveryTests`)
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
- IAP catalog fixture: `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` (product IDs `com.stressmonitor.app.premium.{weekly,monthly,annual}`), referenced by the shared scheme's LaunchAction

## Coverage

**Requirements:** None enforced — no coverage flags in CI or the scheme.

**View Coverage:**
```bash
# via xcodebuild result bundle produced by the test action
xcrun xcresulttool get --path StressMonitor/build/TestResults.xcresult ...
```

## Test Types

**Unit Tests:**
- All 35 test files are unit tests running in the app host (`StressMonitorTests` bundle `stress.ai.com.StressMonitorTests`, `TEST_HOST` = the app executable). Focus: API client contracts, parsers, ViewModels with injected doubles, StoreKit/IAP flows (purchase → server JWS verify → credits grant), SwiftData migration + container recovery, widget data state, data deletion, config resolution precedence.

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
- For purchase-verification logic that does not need StoreKitTest at all, prefer the `PurchaseTransactionHandle` seam + `FakePurchaseTransaction` (`CreditPurchaseFlowTests.swift`) — it sidesteps the session-isolation problems entirely

**Suite quarantines — current inventory (do not "fix" without root-causing):**
- `StoreKitServiceTests` — `@Suite(.serialized, .disabled("StoreKitTest session-isolation bug on CI — see file header"))`: productNotFound after the first test on the macos-15 CI runner regardless of session-reset strategy (header documents everything tried). Production path stays covered by `PremiumViewModelTests` (FakeStoreKitService) + manual `.storekit` verification in the scheme
- `EntitlementForegroundCorrectionTests` — `@Suite(.serialized, .disabled("StoreKitTest cannot resolve subscription products — see file header and IAP-01"))`: same lineage; pins the refund → `refreshEntitlements` → stale-premium correction path for re-enabling
- `DataDeleterFailureAndCancellationTests` and `DataExportFieldSelectionTests` (both inside `DataDeletionConsolidationTests.swift`) — `.enabled(if: ProcessInfo.processInfo.environment["GSD_CI"] == nil)`: they stall the CI test host (exit 65, zero assertion failures; `.planning/WINDOWS.md` #8 lineage). CI sets `GSD_CI` via `TEST_RUNNER_GSD_CI` in `_test.yml`; locally they run normally
- When adding a suite that manipulates real credentials/persistent state or StoreKitTest sessions, apply the same `.enabled(if:)` / `.disabled(...)` gate **with a header comment naming the symptom and the re-enable condition** — that comment style is the convention
- `StoreKitProductCatalogLiveTests` runs ungated (re-enabled after IAP-01): it pins the live `StoreKitProductCatalog.live` resolution — subscription IDs, group `SMPREMIUM01`, credit-pack IDs `com.stressmonitor.app.credits.{small,large}` — with failure messages that name the exact build setting to add

**Decision-pinning suites:**
- Suites exist solely to pin a planning decision so it cannot silently regress: `ChatAvailabilityTests` (D-02: chat reachable in every build configuration), `StressAPIConfigTests` (D-03: 3-tier `STRESS_API_BASE_URL` precedence, asserted against the `resolveBaseURL` seam because static `baseURL` captures at type-load time), `WidgetPublisherKeyMatchingTests` (App Group keys). Suite headers cite the decision ID. Follow this style when a plan decision has no other observable home.

**Contract-pinning headers:**
- Suite doc comments state which external contract is pinned and why a rename breaks silently (e.g. `SSEParserTests` pins the backend `quick_actions` field; `WidgetPublisherKeyMatchingTests` pins App Group keys). Follow this style for new wire-format tests.

**Known flakiness ledger:**
- `.planning/WINDOWS.md` is the cross-phase defect register test comments reference ("WINDOWS.md #8"). Check it before re-enabling or debugging a quarantined suite; add an entry when a new order-dependence or host-stall is accepted rather than fixed.

**Stale docs warning:** `docs/TESTING.md` describes the orphaned repo-root `StressMonitorTests/` and an outdated XCTest-only setup — do not follow it; this file reflects the live target.

---

*Testing analysis: 2026-08-29*
