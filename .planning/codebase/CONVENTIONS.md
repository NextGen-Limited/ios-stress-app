# Coding Conventions

**Analysis Date:** 2026-08-08

Source of truth for this document is the actual Swift in `StressMonitor/StressMonitor/` (iOS app target), `StressMonitor/StressMonitorWatch Watch App/` (watchOS), and `StressMonitor/StressMonitorWidget/` (WidgetKit). Where the code diverges from `CLAUDE.md`, the drift is flagged inline.

## Naming Patterns

**Files:**
- One primary type per file, filename == type name: `Services/Algorithm/MultiFactorStressCalculator.swift`, `ViewModels/StressViewModel.swift`.
- Extensions use `Type+Feature.swift`: `Services/HealthKit/HealthKitManager+SleepFetch.swift`, `Theme/Color+Extensions.swift`, `Utilities/Animation+Wellness.swift`.
- Protocols live in `Services/Protocols/` and end in `...ServiceProtocol.swift` (`HealthKitServiceProtocol.swift`, `StressRepositoryProtocol.swift`, `StressAlgorithmServiceProtocol.swift`, `CloudKitServiceProtocol.swift`). Exceptions live beside their implementation: `Services/LLM/LLMServiceProtocol.swift`, `Services/StoreKit/StoreKitServiceProtocol.swift`.
- Views end in `View`: `Views/Settings/SettingsView.swift`, `Views/Components/DemoModeBannerView.swift`. Sub-components go in a sibling `Components/` folder (`Views/Dashboard/Components/`, `Views/Premium/Components/`).
- ViewModels end in `ViewModel`. Note: they are split across two places — `ViewModels/` (`StressViewModel`, `ChatViewModel`, `PremiumViewModel`, `CharacterCollectionViewModel`, `DataManagementViewModel`, `HabitViewModel`) and feature-local files (`Views/Dashboard/DashboardViewModel.swift`, `Views/Settings/SettingsViewModel.swift`). Prefer `ViewModels/` for new cross-screen VMs; a screen-only VM next to its screen is accepted.
- Test files end in `Tests.swift` (`StressMonitorTests/PremiumViewModelTests.swift`).

**Types:** `UpperCamelCase`. Namespacing is done with caseless `enum` containers, not structs — `enum DesignTokens`, `enum SupabaseConfig`, `enum DemoMode`, `enum SupabaseSecrets`.

**Functions / properties:** `lowerCamelCase`, verb-first for actions (`calculateMultiFactorStress(context:)`, `fetchLatestHRV()`, `refreshEntitlements()`), noun for state (`currentStress`, `isPermissionRequired`).

**Errors:** one `enum <Domain>Error` per subsystem, conforming to `Error` and usually `LocalizedError` or `Sendable`: `StoreKitError`, `RepositoryError`, `CloudKitSyncError`, `SyncError`, `LLMServiceError`, `ExportError`, `BaselineCalculatorError`.

## Code Style

**Formatting:**
- No SwiftFormat config exists. Formatting is enforced only by SwiftLint (`.swiftlint.yml` at repo root) plus convention.
- Indentation: 4 spaces in 288 of 292 iOS-target files. A handful of older `@Model` files use 2 spaces (`StressMonitor/StressMonitor/Models/StressMeasurement.swift`). **Use 4 spaces.**
- `// MARK: - Section` dividers are used heavily to segment types and files. This is the one comment form the codebase does use consistently; keep it.
- Doc comments (`///`) are used on public/shared types and on non-obvious stored properties (see `StressViewModel` property block). Prose explains *why* a value exists, not what the line does.

**Linting (`.swiftlint.yml`):**
- Disabled: `trailing_whitespace`.
- Opt-in enabled: `empty_count`, `closure_spacing`, `force_unwrapping`, `implicitly_unwrapped_optional`, `overridden_super_call`, `private_outlet`, `vertical_whitespace_closing_braces`.
- `line_length`: warn 150 / error 250. `type_body_length`: warn 400 / error 600. `large_tuple`: warn 5 / error 6.
- `identifier_name` allows short domain identifiers: `hr`, `hrv`, `dt`, `dx`, `dy`, `id`, `db`, `ui`, plus single letters.
- `included: StressMonitor` only; watch tests/UI-test dirs are excluded. **Lint does not cover the root-level `StressMonitorTests/` directory.**

## Import Organization

Observed pattern — a single alphabetically sorted block, no blank-line grouping, no third-party section (the app has no non-Apple imports outside the SPM UI packages):

```swift
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI
```

Rules in practice:
- `Foundation` first (alphabetical anyway), then remaining frameworks alphabetically.
- Import only what the file uses — service/model files typically import just `Foundation`, sometimes `+ SwiftData`.
- Conditional imports are wrapped: `#if DEBUG import os #endif` (`ViewModels/StressViewModel.swift`), and whole DEBUG-only files open with `#if DEBUG` at line 1 (`Services/HealthKit/SimulatorHealthKitService.swift`).
- No path aliases / module aliases; everything is one app module accessed via `@testable import StressMonitor` from tests.

## State Management

**`@Observable` is the only ViewModel pattern.** 32 files use `@Observable`; **zero** files use `ObservableObject`/`@Published`. Do not introduce Combine-era observation.

Canonical shape (`ViewModels/StressViewModel.swift`):

```swift
@Observable
@MainActor
final class StressViewModel {
    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?
    private(set) var isRequestingAccess: Bool = false
}
```

- `@Observable` + `@MainActor` on the class, `final` preferred (`DashboardViewModel` omits `final` — prefer `final` on new code).
- Mutable UI state is `var` and internal; state the view must not set is `private(set)`.
- 37 files carry `@MainActor`. There are **no `actor` declarations anywhere** — concurrency isolation is main-actor-plus-`Sendable`, not custom actors.

## Concurrency & Sendable

- `Sendable` appears ~100 times across the iOS target. Protocols that cross task boundaries declare it: `StressAlgorithmServiceProtocol: Sendable`, `LLMServiceProtocol: Sendable`. Error enums that escape are `Error, Sendable` (`RepositoryError`, `CloudKitSyncError`, `SyncError`, `CloudKitError`).
- Mocks and framework-backed services use `@unchecked Sendable` with mutable stored state: `final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable`, `final class SimulatorHealthKitService: HealthKitServiceProtocol, @unchecked Sendable`. **Drift:** `@unchecked` opts out of the checking that `CLAUDE.md`'s "strict concurrency, `Sendable` throughout" implies. Acceptable for test/demo doubles; avoid it in production services — prefer making stored state immutable or main-actor-isolated.
- `async`/`await` everywhere; callbacks only at HealthKit/CloudKit framework boundaries. Streaming uses `AsyncStream` / `AsyncThrowingStream` (`observeHeartRateUpdates()`, `LLMServiceProtocol.send`).
- Concurrent fetches use `async let` then a tuple `try await`.

## Dependency Injection

Protocol-based constructor injection with defaulted parameters, so call sites stay terse and tests can substitute doubles:

```swift
final class MultiFactorStressCalculator: StressAlgorithmServiceProtocol {
    init(factors: [any StressFactor]? = nil,
         baseline: PersonalBaseline = PersonalBaseline(),
         calibratedWeights: FactorWeights? = nil) { ... }
}
```

- Heterogeneous protocol collections use `[any Protocol]` (`[any StressFactor]`), not generics.
- Non-optional collaborators are `private let` and assigned once in `init`.
- Test-time substitution passes a fake into the initializer (`PremiumViewModel(storeKit:premiumState:)` in `StressMonitorTests/PremiumViewModelTests.swift`).
- `UserDefaults`-backed state accepts an injected suite so tests avoid polluting the real domain (`PremiumState(defaults:key:)`).

## SwiftData Models

`@Model public final class` with plain stored properties and an explicit memberwise `init` — see `StressMonitor/StressMonitor/Models/StressMeasurement.swift`.

- New fields added post-release are **optional** (`var hrvComponent: Double?`) so SwiftData performs a lightweight migration; the file marks these with a `// MARK: - Multi-Factor Component Fields (optional — lightweight migration)` banner. Follow this: never add a non-optional field without a default to an existing `@Model`.
- Enums are persisted as `...RawValue: String` companions (`categoryRawValue`) rather than as enum-typed properties.
- CloudKit sync bookkeeping travels on the model itself: `isSynced`, `cloudKitRecordName`, `deviceID`, `cloudKitModTime`.
- Schema registration lives in `StressMonitor/StressMonitorSchema.swift`; container setup in `StressMonitor/StressMonitorApp.swift`.

## Error Handling

**`throws` is the default mechanism.** `Result` is not used as a return type anywhere — the only `Result<...>` occurrences are StoreKit's own `VerificationResult` (`Services/StoreKit/StoreKitService.swift`).

Patterns:
- Each subsystem defines its own `enum ...Error: LocalizedError` and throws it; `guard ... else { throw StressError.noData }` (`MultiFactorStressCalculator.calculateMultiFactorStress`).
- Optionals signal "absent, not exceptional": `fetchLatestHRV() async throws -> HRVMeasurement?`, and a factor returning `nil` from `calculate(context:)` means "this factor has no data" and triggers weight redistribution rather than an error.
- ViewModels catch at the boundary and surface `errorMessage: String?` for the UI; permission failures get their own flag (`isPermissionRequired` is set *only* on `HKError.errorAuthorizationDenied`, deliberately not inferred from nil data).
- `try!` count is **0**. `try?` appears in ~33 files — acceptable only where failure is genuinely ignorable; prefer `do/catch` with a logged reason.
- `force_unwrapping` and `implicitly_unwrapped_optional` are SwiftLint opt-ins, so both are flagged in app code (test code is outside `included:` and does use `!`).

## Logging

There is **no unified logging layer** — this is real drift worth fixing.

- `os.Logger` is used in only 2 files, and `DataManagementViewModel`/`DataManagementUtilities` define their own `DataManagementLogger` abstraction with a `static let \`default\``.
- 17 raw `print(` calls remain in the iOS target.
- `import os` is `#if DEBUG`-gated in `StressViewModel`.

Guidance for new code: use `os.Logger` with a subsystem/category, gate verbose output behind `#if DEBUG`, never `print` in a shipping path, and never log health values or auth tokens.

## Comments

- Do not write "what" comments. The prevailing style is `// MARK: - ` structural dividers plus `///` doc comments on shared types and on properties whose semantics are non-obvious.
- Where a comment exists it explains a constraint or a rationale ("Set exclusively when `HKError.errorAuthorizationDenied` is caught — NOT a proxy for `currentStress == nil`").
- Match the CLAUDE.md comment policy: prefer better naming; only comment non-obvious rules, framework workarounds, and numeric/algorithmic derivations.

## Function & Type Design

- Types are `final class` for services/ViewModels, `struct` for value types and views, caseless `enum` for namespaces. `type_body_length` warns at 400 lines — several ViewModels approach this; split with extensions in `Type+Feature.swift` files rather than growing the primary declaration (see the `HealthKitManager+*Fetch.swift` split).
- Prefer expression-bodied one-line forwarding (`try await fallback.calculateStress(...)` with no `return`).
- Parameters use full external labels; multi-argument initializers wrap one-per-line.
- Access control: mostly implicit `internal`; `public` is used on model/repository/sync types that the widget & watch targets share (`StressMeasurement`, `RepositoryError`, `SyncError`). Collaborators and helpers are `private`.

## Theming & Design Tokens

- `Theme/DesignTokens.swift` provides nested caseless enums — `DesignTokens.Spacing.{xs…xxxl}`, `.Layout.{cornerRadius, minTouchTarget: 44, cardPadding, sectionSpacing}`, `.Typography`, `.Animation`. Used in 257 places.
- Stress colors come from `Color.stressColor(for:)` (`Theme/Color+Extensions.swift`), used 23 times.
- **Drift:** 424 call sites still construct colors inline via `Color(hex:)` / `Color(red:)`, and additional token sets exist in parallel (`Theme/HomeCharacterDesignTokens.swift`, `Theme/Color+Wellness.swift`, `Theme/Gradients.swift`). New UI should reach for `DesignTokens` / `Color.stressColor` / `Font+WellnessType` first and add a token rather than an inline literal.
- Accessibility helpers live in `Utilities/` (`AccessibilityModifiers.swift`, `DynamicTypeScaling.swift`, `HighContrastModifier.swift`, `PatternOverlay.swift`, `ColorBlindnessSimulator.swift`). **Drift:** `CLAUDE.md` requires `.accessibleDynamicType()` on views but only 1 file applies it — treat Dynamic Type as an open gap when touching a screen.
- Haptics are centralized in `HapticManager` (39 call sites); do not call `UIImpactFeedbackGenerator` directly.
- 119 files ship `#Preview` blocks, generally fed by `Services/MockServices.swift` doubles. Add a preview for every new view.

## Module & Target Layout Notes

- Single app module `StressMonitor` — no barrel files, no re-export shims.
- Shared code is duplicated per target rather than extracted into a framework: `StressMonitorWatch Watch App/` mirrors `Models/`, `Services/`, `Theme/`, `ViewModels/`, `Views/`. Changing a shared model means editing both sides.
- A legacy source set sits one level up at `StressMonitor/{Models,Services,Views}/` (`Services/HRVAnalyzer.swift`, `Services/StressPredictor.swift`, `Services/MorningReadinessService.swift`, `Models/StressReading.swift`). New work belongs in `StressMonitor/StressMonitor/`.

---

*Convention analysis: 2026-08-08*
