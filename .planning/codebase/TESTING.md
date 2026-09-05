# Testing Patterns

**Analysis Date:** 2026-09-01

## Test Framework

**Runner:**
- Swift Testing, supplied by the Xcode 26.3 toolchain, is the primary framework. Thirty-three active test source files import `Testing` under `StressMonitor/StressMonitorTests/`.
- XCTest remains for two legacy suites, including `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift`. New tests should use Swift Testing unless extending an existing XCTest suite or a framework API requires XCTest.
- Tests execute through Xcode's test runner and the shared `StressMonitor` scheme in `StressMonitor/StressMonitor.xcodeproj`.
- Config: `.github/workflows/_test.yml`; there is no committed `.xctestplan`.

**Assertion Library:**
- Use Swift Testing `#expect`, `#require`, and `Issue.record` in new tests. Examples are `StressMonitor/StressMonitorTests/SSEParserTests.swift` and `StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift`.
- Existing XCTest files use `XCTAssertEqual`, `XCTAssertNil`, and related XCTest assertions in `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift`.

**Run Commands:**
```bash
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
python3 scripts/run-tests.py
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO -only-testing:StressMonitorTests/SSEParserTests CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO -only-testing:StressMonitorTests/SSEParserTests/testMethod CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
CI=1 python3 scripts/run-tests.py   # Enables code coverage and writes StressMonitor/build/TestResults.xcresult
```

## Test File Organization

**Location:**
- Put all active iOS unit/integration tests in the separate target directory `StressMonitor/StressMonitorTests/`, adjacent to the Xcode project.
- Do not add tests to root `StressMonitorTests/`; AGENTS.md identifies it as orphaned code that is not in the Xcode project and never builds or runs.
- Watch test directories listed in `.swiftlint.yml` are excluded placeholders; no active watch test sources are present. Test shared algorithm behavior in the active iOS test target and separately verify mirrored watch source builds.

**Naming:**
- Name files and suite types `[Subject]Tests`, for example `StressAPIClientTests.swift`, `SSEParserTests.swift`, and `StoreKitServiceTests.swift` in `StressMonitor/StressMonitorTests/`.
- Swift Testing methods use descriptive lowerCamelCase names and human-readable `@Test("...")` labels. XCTest methods use `test[Method]_[Condition]` or the established `test[Behavior]` form; preserve the style of the suite being extended.
- Group multiple related contracts with `@Suite("...")` or `// MARK: - Topic` sections, as in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` and `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`.

**Structure:**
```text
StressMonitor/
├── StressMonitor.xcodeproj/
├── StressMonitor/                  # Production target
└── StressMonitorTests/             # Active StressMonitorTests target
    ├── SubjectTests.swift
    ├── SharedTestDoubleProvider.swift
    └── StressMonitorProducts.storekit
```

## Test Structure

**Suite Organization:**
```swift
import Testing
@testable import StressMonitor

@MainActor
struct AccountViewModelTests {
    @Test("successful Google sign-in stores the linked email")
    func successfulGoogleSignInStoresLinkedEmail() async throws {
        let mock = MockAuthService(googleSignInError: nil, email: "linked@ripple.app")
        let viewModel = AccountViewModel(authService: mock)

        try await viewModel.signInWithGoogle(presenting: UIViewController())

        #expect(viewModel.linkedEmail == "linked@ripple.app")
        #expect(viewModel.errorMessage == nil)
    }
}
```
This arrange-act-assert pattern is taken from `StressMonitor/StressMonitorTests/AccountViewModelTests.swift`.

**Patterns:**
- Keep setup local to each Swift Testing test or extract a private `make...` helper into the suite, as `makeClient(token:)` does in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`.
- Use `@MainActor` on suites that exercise `@MainActor` production types, including ViewModels, StoreKit services, SwiftData contexts, and API clients.
- Use XCTest `setUp()`/`tearDown()` only in existing XCTestCase suites such as `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift`.
- Make one contract or edge case the focus of each test. Assert all fields needed to pin that contract, but do not couple to unrelated implementation details.
- Use `guard case` plus `Issue.record` for enum payload inspection, as in `StressMonitor/StressMonitorTests/SSEParserTests.swift`.
- Use `#expect(throws:)` or `await #expect(throws:)` when only the error type/case matters; use `do/catch` plus `Issue.record` when associated values or post-failure state must be inspected.
- Use `accuracy:` for floating-point assertions in XCTest and explicit tolerances/comparisons for Swift Testing; never compare derived floating-point results without a tolerance when rounding is possible.

## Mocking

**Framework:** Hand-written protocol fakes and stubs; no third-party mocking library is present.

**Patterns:**
```swift
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    let token: String
    private(set) var tokenCallCount = 0

    func getIDToken() async throws -> String {
        tokenCallCount += 1
        return token
    }
}

final class RequestCaptureURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    // startLoading() captures the request and returns a configured HTTP response.
}
```
The complete shared network/auth doubles live in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`.

**What to Mock:**
- Mock protocol dependencies at service/ViewModel boundaries: authentication, CloudKit reset, StoreKit purchase/redemption, credit APIs, preferences APIs, and session APIs. Concrete examples are in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`, `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`, and `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift`.
- Stub HTTP transport with an ephemeral `URLSessionConfiguration` and custom `URLProtocol`; assert method, URL, headers, encoded body, decoding, and error mapping without live backend traffic.
- Use in-memory SwiftData via `ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)` for persistence tests, as in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` and `StressMonitor/StressMonitorTests/StressMeasurementMigrationTests.swift`.
- Inject dictionaries, `UserDefaults` suites, bundles, clocks/dates, and closures instead of mutating production globals when an initializer seam exists. `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift` demonstrates environment/defaults injection.

**What NOT to Mock:**
- Do not mock pure calculators, parsers, DTO mappings, or deterministic state resolvers. Exercise `BioAgeCalculator`, `SSEParser`, `StressContextPayload`, and `WidgetDataState` directly in their corresponding files under `StressMonitor/StressMonitorTests/`.
- Do not hit the live backend, Firebase network, or CloudKit in ordinary unit tests. Live/configuration checks must be explicitly named and isolated, such as `StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift`.
- Do not place mocks in `StressMonitor/StressMonitor/Services/MockServices.swift` merely for tests; test-only doubles belong to `StressMonitor/StressMonitorTests/` so they cannot ship in Release.
- Do not mock the SwiftData model layer when an in-memory container can exercise the real persistence behavior cheaply.

## Fixtures and Factories

**Test Data:**
```swift
private func makeContextWithOneMeasurement() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: StressMeasurement.self, configurations: config)
    let context = container.mainContext
    context.insert(StressMeasurement(
        timestamp: Date(), stressLevel: 50, hrv: 40, restingHeartRate: 65
    ))
    try context.save()
    return context
}
```
This factory pattern is used in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`.

**Location:**
- Keep small fixtures and private factories in the consuming test file.
- Reuse intentionally shared doubles already compiled into the test target, such as `MockAuthService` and `RequestCaptureURLProtocol` in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`; reset their static state before tests that inspect it.
- Store StoreKit product fixtures in `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit`; `StressMonitor/StressMonitorTests/StoreKitTestSessionProvider.swift` centralizes StoreKit test-session setup.
- Use isolated `UserDefaults(suiteName:)` namespaces and remove suites in `defer`, as shown in `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`.
- For file fixtures, write only to temporary/cache locations and clean them after the assertion, following `cleanupExportTempFile` coverage in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`.

## Coverage

**Requirements:** No numeric coverage threshold is enforced in `.github/workflows/_test.yml` or the Xcode project.

**View Coverage:**
```bash
CI=1 python3 scripts/run-tests.py
xcrun xccov view --report StressMonitor/build/TestResults.xcresult
xcrun xccov view --report --json StressMonitor/build/TestResults.xcresult
```
- `scripts/run-tests.py` adds `-enableCodeCoverage YES` only when `CI` is truthy and writes the result bundle beneath `StressMonitor/build/`.
- The GitHub Actions test command in `.github/workflows/_test.yml` writes `TestResults.xcresult` but does not explicitly enable coverage or publish a coverage threshold.

## Test Types

**Unit Tests:**
- Primary coverage includes calculators, parsers, error mappings, model helpers, ViewModels, catalogs, entitlement state, credits, preferences, widget freshness, and request construction under `StressMonitor/StressMonitorTests/`.
- Favor injected protocols and deterministic values. Keep unit tests fast and independent of HealthKit, network availability, CloudKit accounts, and device state.

**Integration Tests:**
- Exercise production `URLSession` request/response behavior through `RequestCaptureURLProtocol` in the `StressAPIClient*Tests.swift` files.
- Exercise SwiftData with in-memory `ModelContainer` instances in `StressMonitor/StressMonitorTests/ModelContainerRecoveryTests.swift`, `StressMeasurementMigrationTests.swift`, and `DataDeletionConsolidationTests.swift`.
- Exercise StoreKit through `StressMonitorProducts.storekit` and `StoreKitTestSessionProvider.swift` in the active test target.
- Firebase bootstrap/configuration tests exist in `StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift`; keep them deterministic and confined to bundled configuration rather than remote authentication.

**E2E Tests:**
- No active XCUITest target or committed UI test files are detected.
- For simulator QA, use the configured Argent workflow described by AGENTS.md. HealthKit is unavailable on Simulator; launch with `-demo-mode` to cycle stress levels through the real application pipeline.
- CI separately builds iOS, watchOS, and widget targets in `.github/workflows/_test.yml`, but only the `StressMonitor` scheme's test target executes automated tests.

## Common Patterns

**Async Testing:**
```swift
@Test("sign-in exposes progress while the request is pending")
func signInShowsProgress() async throws {
    let task = Task {
        try await viewModel.signInWithGoogle(presenting: viewController)
    }
    await Task.yield()
    #expect(viewModel.isSigningIn)
    try await task.value
    #expect(!viewModel.isSigningIn)
}
```
- Use structured tasks and await their values; do not leave unstructured work running after a test. The pattern appears in `StressMonitor/StressMonitorTests/AccountViewModelTests.swift`.
- Mark actor-bound suites `@MainActor`. Use continuations or explicit fake behavior for cancellation/ordering tests, following `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`.
- Keep `-parallel-testing-enabled NO` when reproducing CI. Several test doubles use shared static capture state, and CI intentionally serializes execution in `.github/workflows/_test.yml`.
- Preserve the `GSD_CI` conditional suite gating in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`; the workflow forwards it as `TEST_RUNNER_GSD_CI` because those suites stall the CI test host.

**Error Testing:**
```swift
await #expect(throws: SessionsAPIError.notFound) {
    try await client.fetchMessages(sessionId: sessionId)
}

do {
    try await viewModel.signInWithGoogle(presenting: UIViewController())
    Issue.record("Expected sign-in to throw")
} catch {
    #expect(error is AuthServiceError)
}
```
- Prefer the first form for exact error cases, as in `StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift`.
- Prefer the second when also asserting state cleanup or an associated error payload, as in `StressMonitor/StressMonitorTests/AccountViewModelTests.swift` and `DataDeletionConsolidationTests.swift`.
- After failure, assert invariants such as loading-state reset, unchanged local records, cancelled work, or absence of partial writes.

---

*Testing analysis: 2026-09-01*
