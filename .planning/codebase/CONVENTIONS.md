# Coding Conventions

**Analysis Date:** 2026-08-29

## Scope Notes

- Live code = files inside the Xcode project at `StressMonitor/StressMonitor.xcodeproj`. Real targets: app `StressMonitor/StressMonitor/`, tests `StressMonitor/StressMonitorTests/`, watch `StressMonitor/StressMonitorWatch Watch App/` (path contains spaces), widget `StressMonitor/StressMonitorWidget/`.
- `StressMonitorTests/` (repo root) and `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/` are **orphaned** (not in any target). Never edit or extend them; changes there never build.
- The watch target **duplicates algorithm sources** (`MultiFactorStressCalculator`, all `*StressFactor.swift`, shared protocols). Algorithm changes must be mirrored into `StressMonitor/StressMonitorWatch Watch App/Services/`.
- Companion docs (partly stale; trust the code): `docs/code-standards-swift.md`, `docs/code-standards-patterns.md`, `docs/code-standards.md`. `docs/TESTING.md` is stale (describes the orphaned repo-root test dir).

## Naming Patterns

**Files:**
- PascalCase matching the primary type: `StressMeasurement.swift`, `HealthKitManager.swift`, `DashboardView.swift`
- ViewModels: `XxxViewModel.swift` in `StressMonitor/StressMonitor/ViewModels/` (7 files: `StressViewModel.swift`, `ChatViewModel.swift`, `AccountViewModel.swift`, `PremiumViewModel.swift`, `CreditsViewModel.swift`, `HabitViewModel.swift`, `CharacterCollectionViewModel.swift`)
- Services: `XxxService.swift` / `XxxManager.swift`, organized by domain subdirectory under `StressMonitor/StressMonitor/Services/` (`API/`, `Auth/`, `Algorithm/`, `Chat/`, `CloudKit/`, `Credits/`, `DataManagement/`, `Firebase/`, `HealthKit/`, `LLM/`, `Preferences/`, `Premium/`, `Repository/`, `StoreKit/`, `Sync/`, `Background/`, `Connectivity/`)
- Protocols: `XxxProtocol.swift` in `StressMonitor/StressMonitor/Services/Protocols/` (`AuthServiceProtocol` lives at `Services/Auth/`, `LLMServiceProtocol` at `Services/LLM/`, `StoreKitServiceProtocol` at `Services/StoreKit/`)
- Extensions: `Type+Feature.swift` — `Theme/Color+Extensions.swift`, `Theme/Color+Wellness.swift`, `Utilities/Animation+Wellness.swift`, `Services/API/StressAPIClient+Credits.swift` (endpoint groups as extensions: `+Preferences`, `+QuickActions`, `+Sessions`)
- Views: `XxxView.swift` grouped by feature folder `Views/<Feature>/` with shared subcomponents in `Views/<Feature>/Components/` and cross-feature pieces in `Views/Components/`

**Types / Functions / Variables:**
- Types PascalCase; functions/variables camelCase
- Booleans read as predicates: `isSigningIn`, `isSynced`, `isPremiumUser`, `isLoading`, `appeared`
- Factory helpers in views/tests: `makeClient()`, `makeService()`, `makeSession()`
- Test doubles: `MockXxx` (verification doubles with call counters) or `FakeXxx` (working stubs) — see TESTING.md

**Errors:**
- One `enum XxxError: Error, LocalizedError` per domain, colocated with the protocol/service it guards: `Services/Auth/AuthServiceError.swift` (`AuthServiceError`), `Services/LLM/LLMServiceProtocol.swift` (`LLMServiceError`), `Services/StoreKit/StoreKitServiceProtocol.swift` (`StoreKitError`), `Services/Repository/StressRepository.swift` (`RepositoryError`), `Services/CloudKit/CloudKitManager.swift` (`CloudKitError`), `Services/Algorithm/BaselineCalculator.swift` (`BaselineCalculatorError`)
- Cases are `camelCase`, often with payloads: `googleSignInFailed(underlying: Error?)`, `unknown(Error)`

## Code Style

**Formatting:**
- Tool: SwiftLint, config `.swiftlint.yml` (repo root). Lint scope `included: StressMonitor/`
- `disabled_rules`: `trailing_whitespace`
- Opt-in rules enabled: `empty_count`, `closure_spacing`, `force_unwrapping`, `implicitly_unwrapped_optional`, `overridden_super_call`, `private_outlet`, `vertical_whitespace_closing_braces`
- **Avoid `!` (force unwrap/try) and `var x: T!` in all new code** — `force_unwrapping` and `implicitly_unwrapped_optional` are enforced
- Escape hatch when unavoidable: `// swiftlint:disable:next force_try` with a reason (see `StressMonitor/StressMonitorTests/StoreKitTestSessionProvider.swift`)
- Thresholds: `line_length` 150 warn / 250 error; `type_body_length` 400 warn / 600 error; `large_tuple` 5 warn / 6 error; short identifiers (`i`, `x`, `hr`, `hrv`, `id`, `dx`, ...) allowed via `identifier_name.excluded`
- CI lint is advisory (`swiftlint lint ... || true` in `.github/workflows/_test.yml`) — do not regress anyway
- Run locally from repo root: `swiftlint lint`

**Section organization:**
- `// MARK: - Section Name` used pervasively (~800 occurrences) to segment files: `// MARK: - Stress API Client`, `// MARK: - Request Builder`, `// MARK: - Auth Service Errors`

**Concurrency:**
- `@MainActor` on ViewModels and UI-facing services (`StressAPIClient`, test suites)
- ViewModels: `@MainActor @Observable final class` (34 `@Observable` types in app target)
- `async throws` throwing APIs; `defer` for state reset (`AccountViewModel.signInWithGoogle` resets `isSigningIn` in `defer`)
- Cross-thread test doubles use `@unchecked Sendable` with a comment justifying it

**Access control:**
- Default internal; `public` only where a framework boundary demands it (e.g. `RepositoryError`, `CloudKitSyncError` in `Services/Repository/StressRepository.swift`, `Utilities/DynamicTypeScaling.swift` helpers)
- Mutable verification state in doubles is `private(set) var`

## Architecture Conventions

**MVVM + protocol DI (prescriptive — follow for all new features):**
1. Define the seam as a protocol (`Services/<Domain>/XxxProtocol.swift` or `Services/Protocols/`)
2. Implement a production service (`final class XxxService: XxxProtocol`)
3. ViewModel takes the protocol with a production default so views need no wiring:
   ```swift
   // StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift
   @MainActor
   @Observable
   final class AccountViewModel {
       private let authService: AuthServiceProtocol
       init(authService: AuthServiceProtocol = FirebaseAuthService()) {
           self.authService = authService
       }
   }
   ```
4. Tests inject a hand-written `MockXxx`/`FakeXxx` through the same initializer
5. Views own ViewModels via `@State private var viewModel:` and `State(initialValue:)` in `init` (see `Views/DashboardView.swift`)

**HTTP client pattern** (`Services/API/StressAPIClient*.swift`):
- One `@MainActor final class StressAPIClient` with injected `authService`, `baseURL`, `session`
- Endpoint groups in sibling extension files (`StressAPIClient+Credits.swift` etc.) sharing `authorizedRequest(path:method:body:accept:)`
- Query-string endpoints must build URLs with `URLComponents` and call `authorizedRequest(url:)` — `appendingPathComponent` percent-encodes `?` (documented in the method's doc comment; follow it)

**Base URL resolution:** `STRESS_API_BASE_URL` from Info.plist → env → UserDefaults → fallback `https://stress-api.dropitx.site` (`Services/API/StressAPIConfig.swift`)

**UI conventions (from `AGENTS.md` + `docs/design-guidelines*.md`):**
- Dual-code stress levels: color **plus** icon/text — never color alone
- Colors via `Color.stressColor(for:)` (`Theme/Color+Extensions.swift`); gradients via `Theme/Gradients.swift`
- 44pt touch targets: `.minimumTouchTarget()` (`Utilities/AccessibilityModifiers.swift`, default 44)
- Dynamic Type: `.accessibleDynamicType(minimumScale:maxDynamicTypeSize:)` (`Utilities/DynamicTypeScaling.swift`) applied at screen root
- Haptics via `HapticManager` (`Views/Components/HapticManager.swift`) — never raw `UIImpactFeedbackGenerator` calls in views
- Design tokens in `Theme/DesignTokens.swift`, `Theme/HomeCharacterDesignTokens.swift`; characters via `Theme/CharacterAssetCatalog.swift`

**Launch arguments:**
- `-demo-mode` — simulator demo pipeline (no HealthKit data on simulator); checked in `StressMonitorApp.swift` (`DemoMode.isEnabled`) and backed by `Services/HealthKit/SimulatorHealthKitService.swift`

## Import Organization

**Order** (per `docs/code-standards-swift.md`, observed in source):
1. System/framework imports, alphabetized (`import Foundation`, `import SwiftUI`, `import SwiftData`, `import UIKit`)
2. Third-party (`import StoreKit`, `import StoreKitTest`, `import FirebaseCore`, ...)
3. No project-module imports (single app module); tests add `@testable import StressMonitor` last

## Error Handling

**Patterns (prescriptive):**
- Throw typed domain errors from services; never `NSError` or bare `String`
- Provide `var errorDescription: String?` with **user-facing copy** in the error enum itself:
  ```swift
  // StressMonitor/StressMonitor/Services/Auth/AuthServiceError.swift
  enum AuthServiceError: Error, LocalizedError {
      case googleSignInFailed(underlying: Error?)
      var errorDescription: String? {
          switch self {
          case .googleSignInFailed(let underlying):
              return underlying?.localizedDescription
                  ?? "Google Sign-In could not be completed. Please try again."
          }
      }
  }
  ```
- Keep error enums **distinct per domain** so failures surface as the right UI message (`AuthServiceError` doc comment: kept separate from `LLMServiceError` deliberately)
- ViewModels catch, set `errorMessage: String?`, rethrow when the caller must know, and expose `clearError()`
- Known-noise filtering via small helper enums with static predicates: `GoogleSignInCancellation.isUserCancellation(error)` (checks `NSError.domain == "com.google.GIDSignIn"`, `code == -5`) in `ViewModels/AccountViewModel.swift`
- Comments in tests record why a bug is pinned (`// DISABLED: ...` header in `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift`)

## Logging

**Framework:** `os.Logger` (unified logging), subsystem `"com.stressmonitor.app"`

**Patterns:**
- Private static loggers with a category: `Logger(subsystem: "com.stressmonitor.app", category: "FirebaseBootstrap")` (`Services/Firebase/FirebaseBootstrap.swift`, `StressMonitorApp.swift`)
- Logging is intentionally sparse (~6 files import `os`); a handful of `print(` calls remain (~13) — do not add more; use `Logger`
- No third-party logging/crash SDK in the app target

## Comments

**When to Comment:**
- `///` doc comments on types and public-facing methods explain **why** and pin external contracts, e.g. `StressAPIClient.authorizedRequest(path:)` explains the `URLComponents` rule; `SSEParserTests` header pins the backend-defined `quick_actions` field name ("a rename breaks silently")
- `// MARK: -` for section navigation
- Block comments on test doubles document reset discipline and sharing rules (`RequestCaptureURLProtocol`, `StoreKitTestSessionProvider` doc comments in `StressMonitor/StressMonitorTests/`)
- `// swiftlint:disable:next <rule>` with an adjacent justification

**JSDoc/TSDoc equivalent:** Swift Markup (`///`, `- Parameter`, `- Returns`) — used on services and protocols; keep it current when changing behavior

## Function Design

**Size:** Keep files/types focused; SwiftLint flags type bodies over 400 lines (warn) / 600 (error). `docs/code-standards-swift.md` targets ~200 LOC per file via extraction into `Components/` subdirectories.

**Parameters:** Prefer parameterized initializers with sensible defaults (`StressAPIClient.init(authService:baseURL:session:)`); avoid boolean flag parameters in favor of distinct methods.

**Return Values:** `async throws` for fallible I/O; typed results (`[CreditTransaction]`, `ChatSession`); errors typed per domain (see Error Handling).

## Module Design

**Exports:** One primary type per file (plus tightly-coupled private helpers and its error enum). Extensions on the same type go in `Type+Feature.swift` siblings.

**Barrel Files:** Not used. No umbrella re-exports; consumers import `StressMonitor` (single app module) or `@testable import StressMonitor` in tests.

**Target duplication:** Shared algorithm/protocol sources are compiled into both app and watch targets by membership — there is no shared framework. Mirror changes manually.

---

*Convention analysis: 2026-08-29*
