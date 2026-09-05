# Coding Conventions

**Analysis Date:** 2026-09-01

## Naming Patterns

**Files:**
- Name Swift files after the primary type in UpperCamelCase: `StressAPIClient.swift`, `AccountViewModel.swift`, and `StressMeasurement.swift` under `StressMonitor/StressMonitor/`.
- Split a large type by responsibility with `Type+Concern.swift`; API endpoint groups use `StressAPIClient+Credits.swift`, `StressAPIClient+Preferences.swift`, `StressAPIClient+QuickActions.swift`, and `StressAPIClient+Sessions.swift` in `StressMonitor/StressMonitor/Services/API/`.
- End protocols in `Protocol` when the protocol represents an injectable service, as in `StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift` and `StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift`.
- End observable presentation types in `ViewModel`, concrete services in `Service` or `Manager`, and tests in `Tests`, as demonstrated by `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift`, `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`, and `StressMonitor/StressMonitorTests/AccountViewModelTests.swift`.
- Add production files only beneath the real targets in `StressMonitor/StressMonitor/`, `StressMonitor/StressMonitorWatch Watch App/`, or `StressMonitor/StressMonitorWidget/`. Do not add code to orphaned `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, or root `StressMonitorTests/`.

**Functions:**
- Use lowerCamelCase and verb-led names: `authorizedRequest(path:method:body:accept:)`, `fetchLatestHRV()`, `refreshAccountState()`, and `calculateMultiFactorStress(context:)`.
- Include argument labels that describe roles at the call site. Use domain-specific overloads where behavior remains cohesive, such as the URL- and path-based `authorizedRequest` overloads in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.
- Use `make...` for local factories and `is`/`has`/`can` for Boolean queries, as in `makeClient(token:)` in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift` and `hasEnoughData(measurements:)` in `StressMonitor/StressMonitor/Services/Algorithm/BioAgeCalculator.swift`.

**Variables:**
- Use lowerCamelCase with explicit domain terms: `creditsRemaining`, `restingHeartRate`, `stressContext`, and `linkedEmail`.
- Prefix Boolean state with `is`, `has`, `can`, or an action state: `isSigningIn` in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift` and `isSynced` in `StressMonitor/StressMonitor/Models/StressMeasurement.swift`.
- Keep dependencies `private let` by default and expose only extension seams at module scope. `StressAPIClient` keeps `authService` private but leaves `baseURL` and `session` internal for endpoint extensions in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.
- Avoid single-letter identifiers except the explicit scientific/coordinate exceptions configured in `.swiftlint.yml` (`i`, `x`, `hrv`, and similar).

**Types:**
- Use UpperCamelCase for structs, classes, actors, enums, protocols, and nested error cases: `SSEParser`, `StressAPIClient`, `SSEEvent`, and `AuthServiceProtocol`.
- Prefer value types for stateless parsers, DTOs, and test suites; use `final class` for identity-bearing services, observable models, URL protocol fakes, and XCTest suites. Examples are `SSEParser` in `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift` and `StressAPIClient` in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.
- Mark UI-facing observable types `@MainActor @Observable final class`, as in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift` and `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift`.
- Use `Sendable` for values crossing concurrency boundaries. When framework inheritance prevents checked conformance, limit `@unchecked Sendable` to carefully controlled adapters such as `MockAuthService` and `RequestCaptureURLProtocol` in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`.

## Code Style

**Formatting:**
- No SwiftFormat or Prettier-style formatter is configured. Follow the dominant Xcode Swift style: four-space indentation, opening braces on the declaration line, trailing commas in multiline collections/calls, and one declaration per line.
- Keep lines below the SwiftLint warning threshold of 150 characters and never exceed the 250-character error threshold in `.swiftlint.yml`.
- Keep type bodies below 400 lines where practical; `.swiftlint.yml` warns at 400 and errors at 600. Split cohesive endpoint groups or framework concerns into extensions before exceeding those limits.
- Use `// MARK: - Section` to divide substantial files. This is the dominant organization in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`, `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`, and `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`.
- Match surrounding indentation exactly when editing older files. Some model files, including `StressMonitor/StressMonitor/Models/StressMeasurement.swift`, contain inconsistent two- and four-space indentation; new code should use four spaces without mechanically reformatting unrelated lines.

**Linting:**
- Run `swiftlint lint` from the repository root; `.swiftlint.yml` scopes linting to `StressMonitor/` and excludes build output and watch test placeholders.
- Avoid force unwraps and implicitly unwrapped optionals in new code. Both rules are opt-in in `.swiftlint.yml`, even though legacy XCTest code such as `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift` still contains them.
- Prefer `.isEmpty` over `count == 0`, keep closure braces spaced, call overridden superclass methods, and keep closing-brace whitespace clean; these are opt-in rules in `.swiftlint.yml`.
- SwiftLint is advisory in `.github/workflows/_test.yml` because CI invokes it with `|| true`, but code should still satisfy its rules.

## Import Organization

**Order:**
1. Import Apple or standard modules, generally alphabetically when there are several (`CloudKit`, `Foundation`, `Security`, `SwiftData`, `SwiftUI`, `UIKit`).
2. Import third-party modules such as `FirebaseAuth`, `GoogleSignIn`, or `Testing` where required.
3. Put `@testable import StressMonitor` last in test files, as in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`.

**Path Aliases:**
- Not applicable. Swift files use target membership and module imports; there are no source-level path aliases.
- Do not add barrel imports. Import the owning framework explicitly and rely on the `StressMonitor` module for internal app types.

## Error Handling

**Patterns:**
- Propagate recoverable failures with `async throws`/`throws` through service protocols and implementations. Examples include `StressMonitor/StressMonitor/Services/Protocols/CloudKitServiceProtocol.swift` and `StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift`.
- Model domain failures as typed `Error` enums with user-facing descriptions, as in `StressMonitor/StressMonitor/Services/Auth/AuthServiceError.swift` and `LLMServiceError` in `StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift`.
- Use `guard` for invalid response shape and early exits. Cancel owned streaming work before throwing when necessary, as `sendChat` does in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.
- Use `defer` to restore transient state regardless of success or failure. `AccountViewModel.signInWithGoogle` resets `isSigningIn` in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift`.
- Catch at presentation or orchestration boundaries to translate errors into observable state, log them, or map them to a domain error; rethrow when callers still need failure semantics. Do not silently swallow operational failures.
- Restrict `try?` to deliberately optional parsing or best-effort enrichment. `SSEParser.parse` returns `nil` for malformed events in `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`; it does not use this pattern for required network or persistence operations.

## Logging

**Framework:** Apple unified logging (`Logger`/`OSLog`) with occasional diagnostic `print` output in tooling.

**Patterns:**
- Inject or define subsystem/category loggers in service boundaries; `DataDeleterService` accepts a logger in `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`.
- Log lifecycle, recovery, and integration failures where the caller cannot surface them directly. Preserve typed errors for operations that callers can handle.
- Never log Firebase tokens, Keychain values, raw health records, or other sensitive payloads. Tests use fixed fake tokens only in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`.
- Use `print` only in command-line support such as `scripts/run-tests.py`, not as the normal application logging mechanism.

## Comments

**When to Comment:**
- Explain contracts, external field names, security boundaries, concurrency constraints, migration requirements, and non-obvious workarounds. Good examples are the endpoint contract comments in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` and the CI gating rationale in `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`.
- Use comments to explain why, not to restate straightforward code. Keep backend field-name and endpoint comments synchronized with their implementations.
- Preserve repository-specific warnings: algorithm changes under `StressMonitor/StressMonitor/Services/Algorithm/` must be mirrored into `StressMonitor/StressMonitorWatch Watch App/Services/` where duplicated.

**JSDoc/TSDoc:**
- Not applicable; this is Swift. Use Swift documentation comments (`///`) for public/internal contracts, injectable seams, types reused across files, and behavior with surprising constraints.
- Use parameter and return sections for parsing or service APIs when they improve call-site understanding, as in `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`.

## Function Design

**Size:** Keep functions focused on one operation. Extract request construction, parsing, mapping, or endpoint groups when branching grows; `StressAPIClient.swift` owns common request behavior while `StressAPIClient+Sessions.swift` owns session endpoints.

**Parameters:**
- Prefer labeled domain values and injected protocols/defaults over global lookups. `AccountViewModel.init(authService:)` in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift` and `StressAPIClient.init(authService:baseURL:session:)` establish testable seams.
- Use default arguments for production dependencies and common pagination values, but pass explicit fakes in tests.
- Group transport data in Codable/domain types instead of unstructured dictionaries except at unavoidable dynamic JSON boundaries such as SSE parsing in `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`.

**Return Values:**
- Return domain values or optionals for expected absence; throw for operational failure. `SSEParser.parse` returns `SSEEvent?`, while network service calls are `async throws`.
- Use `AsyncThrowingStream` or `URLSession.AsyncBytes` for streaming rather than callback pyramids, as in `StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift` and `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.

## Module Design

**Exports:**
- Default to internal access. Use `private` for implementation details, `private(set)` for observable counters/state that callers may read, and `public` only where target boundaries or persisted model access require it.
- Define protocol-based dependency seams in `StressMonitor/StressMonitor/Services/Protocols/` or beside the owning service when narrowly scoped, as with `StressMonitor/StressMonitor/Services/Credits/CreditServiceProtocol.swift`.
- Keep test doubles in the test target. Shared doubles such as `MockAuthService` and `RequestCaptureURLProtocol` live in `StressMonitor/StressMonitorTests/StressAPIClientTests.swift` and must never be moved into the release target.

**Barrel Files:**
- Not used. Add a focused Swift file in the owning feature directory and ensure it belongs to the appropriate Xcode target in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- Mirror shared stress-algorithm source changes into the watch target rather than attempting cross-target barrel exports; corresponding watch sources live in `StressMonitor/StressMonitorWatch Watch App/Services/`.

---

*Convention analysis: 2026-09-01*
