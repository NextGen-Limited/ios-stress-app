<!-- refreshed: 2026-08-08 -->
# Architecture

**Analysis Date:** 2026-08-08

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Presentation (SwiftUI)                    │
├──────────────────┬──────────────────┬───────────────────────┤
│   iPhone app     │   watchOS app    │   Widget extension    │
│ `StressMonitor/  │ `StressMonitor-  │ `StressMonitorWidget/`│
│  Views/`         │  Watch Watch App/│                       │
│                  │  Views/`         │                       │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│              ViewModels (@Observable, @MainActor)            │
│  `StressMonitor/ViewModels/`, per-feature VMs under Views/   │
│  `StressMonitorWatch Watch App/ViewModels/`                  │
└────────┬────────────────────────────────────────────────────┘
         │  protocol-typed dependencies (constructor injection)
         ▼
┌─────────────────────────────────────────────────────────────┐
│                        Service layer                         │
│ Algorithm │ HealthKit │ Repository │ CloudKit │ Sync │ LLM   │
│ StoreKit  │ Background│ DataManagement │ Connectivity        │
│ `StressMonitor/Services/`                                    │
└────────┬───────────────────────┬──────────────┬─────────────┘
         │                       │              │
         ▼                       ▼              ▼
┌──────────────────┐  ┌────────────────┐  ┌──────────────────┐
│ SwiftData store  │  │ CloudKit       │  │ Supabase Edge    │
│ (StressMeasure-  │  │ private DB     │  │ Functions /chat  │
│  ment, Habit,    │  │ `Services/     │  │ (SSE streaming)  │
│  CharacterUnlock)│  │  CloudKit/`    │  │ `Services/LLM/`  │
└──────────────────┘  └────────────────┘  └──────────────────┘
         │
         ▼  App Group `group.com.stressmonitor.app`
┌─────────────────────────────────────────────────────────────┐
│ Widget / complication snapshot store                         │
│ `StressMonitorWidget/Models/WidgetDataProvider.swift`        │
│ `StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift` │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `StressMonitorApp` | App entry, versioned SwiftData schema + migration plan, ModelContainer, seeds `CharacterUnlock`, injects `AppRouter`/`PaywallController` | `StressMonitor/StressMonitorApp.swift` |
| `AppRouter` | Central navigation state: selected tab + one `NavigationPath` per tab, deep links, path encode/decode for restoration | `StressMonitor/Navigation/AppRouter.swift` |
| `Route` | Codable/Hashable enum of every pushable screen | `StressMonitor/Navigation/Route.swift` |
| `MainTabView` | Four `NavigationStack`s inside a `TabView`, `@SceneStorage` navigation restoration, root paywall cover | `StressMonitor/Views/MainTabView.swift` |
| `StressViewModel` | Primary dashboard state: fetch → build `StressContext` → calculate → persist | `StressMonitor/ViewModels/StressViewModel.swift` |
| `HealthKitManager` (+ extensions) | All HealthKit reads (HRV, HR, sleep, activity, recovery, respiratory) | `StressMonitor/Services/HealthKit/HealthKitManager.swift`, `…+SleepFetch.swift`, `…+ActivityFetch.swift`, `…+RecoveryFetch.swift` |
| `SimulatorHealthKitService` | Demo-mode data generator behind the same protocol | `StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift` |
| `MultiFactorStressCalculator` | Runs the five `StressFactor`s, redistributes weights, emits composite `StressResult` | `StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` |
| `StressCalculator` | Legacy HRV+HR fallback, also supplies confidence scoring | `StressMonitor/Services/Algorithm/StressCalculator.swift` |
| `StressRepository` | SwiftData CRUD, baseline persistence/caching, optional CloudKit passthrough | `StressMonitor/Services/Repository/StressRepository.swift` |
| `SyncManager` / `CloudKitSyncEngine` / `ConflictResolver` | Orchestrated CloudKit sync with conflict merge and background-task guard | `StressMonitor/Services/Sync/SyncManager.swift`, `StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift`, `StressMonitor/Services/Sync/ConflictResolver.swift` |
| `SupabaseLLMService` / `SSEParser` / `ChatContextBuilder` | Chat streaming over Supabase Edge Functions, token + terminal-metadata parsing, stress-context payload | `StressMonitor/Services/LLM/` |
| `PhoneConnectivityManager` / `WatchConnectivityManager` | `WCSession` bridge; watch transfers measurement dictionaries, phone inserts them into SwiftData | `StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift`, `StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` |
| `WidgetDataProvider` | App-Group `UserDefaults` snapshot read/written for widgets | `StressMonitorWidget/Models/WidgetDataProvider.swift` |
| `StoreKitService` / `PremiumState` / `PaywallController` | Subscriptions, premium gating, paywall presentation | `StressMonitor/Services/StoreKit/`, `StressMonitor/Services/Premium/PaywallController.swift` |

## Pattern Overview

**Overall:** MVVM with protocol-based dependency injection, one Swift module per platform target (no shared framework — cross-target types are duplicated by file).

**Key Characteristics:**
- ViewModels are `@Observable @MainActor final class`, constructed with protocol-typed dependencies (`HealthKitServiceProtocol`, `StressAlgorithmServiceProtocol`, `StressRepositoryProtocol`).
- Algorithm is a strategy/composite: `StressFactor` implementations plugged into `MultiFactorStressCalculator`, with a legacy calculator as fallback.
- Value-based navigation: a single `Route` enum plus `View.stressNavigationDestinations()` shared by all tabs.
- Cross-process data hand-off is snapshot-based (App Group `UserDefaults`), never shared SwiftData stores.

## Layers

**Presentation (Views):**
- Purpose: SwiftUI screens and reusable components.
- Location: `StressMonitor/Views/`, `StressMonitor/Components/`, `StressMonitorWatch Watch App/Views/`, `StressMonitorWidget/Views/`.
- Depends on: ViewModels, `Theme/`, `Views/DesignSystem/`.
- Used by: `MainTabView`, `OnboardingContainerView`.

**ViewModels:**
- Purpose: screen state + orchestration.
- Location: `StressMonitor/ViewModels/` (app-wide) and feature-local VMs such as `StressMonitor/Views/Trends/TrendsViewModel.swift`, `StressMonitor/Views/Dashboard/DashboardViewModel.swift`, `StressMonitor/Views/Onboarding/*ViewModel.swift`.
- Depends on: service protocols only.
- Used by: Views.

**Services:**
- Purpose: all IO, algorithms, and platform integration.
- Location: `StressMonitor/Services/` with subfolders `Algorithm/`, `HealthKit/`, `Repository/`, `CloudKit/`, `Sync/`, `LLM/`, `StoreKit/`, `Background/`, `DataManagement/`, `Connectivity/`, `Premium/`, `Protocols/`.
- Depends on: Models, Apple frameworks.
- Used by: ViewModels, app entry.

**Models:**
- Purpose: SwiftData `@Model` entities, value types, DTOs.
- Location: `StressMonitor/Models/` (plus `Models/Character/`, `Models/Base/`).
- Used by: every layer.

## Data Flow

### Primary stress measurement path

1. View calls `StressViewModel.loadCurrentStress()` / `calculateAndSaveStress()` (`StressMonitor/ViewModels/StressViewModel.swift:110`, `:276`).
2. Five HealthKit reads issued in parallel with `async let` — HRV and HR are required, sleep/activity/recovery are `try?` best-effort (`StressViewModel.swift:280-295`).
3. Inputs are packed into `StressContext` (all optional fields) (`StressMonitor/Models/StressContext.swift`).
4. `MultiFactorStressCalculator.calculateMultiFactorStress(context:)` runs each `StressFactor`; factors returning `nil` are dropped and their weight redistributed (`StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift:37`).
5. Composite `StressResult` (+ `FactorBreakdown`) is mapped onto a `StressMeasurement` and saved through `StressRepository.save(_:)` (`StressMonitor/Services/Repository/StressRepository.swift`).
6. `currentStress` publishes to SwiftUI via `@Observable`.

### CloudKit sync flow

1. `SyncManager.sync(localMeasurements:)` guards against a concurrent `syncTask` and checks account status (`StressMonitor/Services/Sync/SyncManager.swift:45`).
2. `CloudKitSyncEngine` pushes/pulls records against the private database (`StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift`, schema in `CloudKitSchema.swift`).
3. `ConflictResolver` merges divergent records (`StressMonitor/Services/Sync/ConflictResolver.swift`).
4. Status surfaces through `SyncStatus` (`StressMonitor/Services/Protocols/CloudKitServiceProtocol.swift`) and the repository's `onSyncStatusChange` callback.

### Watch → phone flow

1. Watch computes stress with its own copy of the factor pipeline (`StressMonitorWatch Watch App/Services/MultiFactorStressCalculator.swift`).
2. `WatchConnectivityManager.syncData(_:)` calls `WCSession.transferUserInfo` (`StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift:18`).
3. `PhoneConnectivityManager.handleWatchMeasurement(_:)` decodes the dictionary and inserts a `StressMeasurement` into the injected `ModelContext` (`StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift:27`).

### Chat streaming flow

1. `ChatViewModel` builds messages and stress context (`StressMonitor/ViewModels/ChatViewModel.swift`, `StressMonitor/Services/LLM/ChatContextBuilder.swift`, `StressContextPayload.swift`).
2. `SupabaseLLMService.send(messages:systemPrompt:)` returns an `AsyncThrowingStream<String, Error>` fed by the Edge Function response (`StressMonitor/Services/LLM/SupabaseLLMService.swift:137`).
3. Each line is decoded by `SSEParser.parse(line:)` into `.content`, `.metadata`, `.done`, `.error` (`StressMonitor/Services/LLM/SSEParser.swift:31`).
4. Terminal `metadata` updates `sessionId`, `creditsRemaining`, `modelUsed`; JWT is read from `KeychainService`.

**State Management:**
- `@Observable` ViewModels; `AppRouter` and `PaywallController` injected via `.environment(...)` at the root scene.
- SwiftData `ModelContainer` attached with `.modelContainer(sharedModelContainer)`.
- Navigation restoration through `@SceneStorage` `Data` blobs per tab.

## Key Abstractions

**Service protocol (DI seam):**
- Purpose: swap live/mock/simulator implementations.
- Examples: `StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift`, `StressAlgorithmServiceProtocol.swift`, `StressRepositoryProtocol.swift`, `CloudKitServiceProtocol.swift`, `StressMonitor/Services/LLM/LLMServiceProtocol.swift`, `StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`.
- Pattern: `Sendable` protocol + default implementations in a protocol extension so mocks only override what they need.

**StressFactor:**
- Purpose: one scoring contributor returning `FactorResult?` (nil = unavailable).
- Examples: `HRVStressFactor.swift`, `HeartRateStressFactor.swift`, `SleepStressFactor.swift`, `ActivityStressFactor.swift`, `RecoveryStressFactor.swift` in `StressMonitor/Services/Algorithm/`.
- Pattern: strategy objects composed by `MultiFactorStressCalculator`.

**Route:**
- Purpose: value-typed destination for all `NavigationStack`s.
- Examples: `StressMonitor/Navigation/Route.swift`, resolved in `StressMonitor/Navigation/View+NavigationDestinations.swift`.

**Snapshot store:**
- Purpose: cross-process data for widgets/complications.
- Examples: `StressMonitorWidget/Models/WidgetDataProvider.swift`, `StressMonitor/Models/WidgetSharedData.swift`, `StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift`.

## Entry Points

**iPhone app:**
- Location: `StressMonitor/StressMonitorApp.swift`
- Triggers: app launch.
- Responsibilities: build versioned `ModelContainer` (`AppSchemaV1` → `AppSchemaV2` lightweight stage), seed default `CharacterUnlock` rows, inject `AppRouter` + `PaywallController`, present `OnboardingContainerView`.

**watchOS app:**
- Location: `StressMonitorWatch Watch App/StressMonitorWatchApp.swift`
- Triggers: watch app launch; activates `WatchConnectivityManager.shared` in `init`.
- Root view: `StressMonitorWatch Watch App/ContentView.swift` → `WatchHomeView`/`WatchMenuView`.

**Widget extension:**
- Location: `StressMonitorWidget/StressMonitorWidgetBundle.swift`
- Contains: `StressMonitorWidget`, `LockScreenStressWidget`, `StressMonitorWidgetControl`, `StressMonitorWidgetLiveActivity`; timeline in `StressMonitorWidget/Providers/StressWidgetProvider.swift`.

**Watch complications:**
- Location: `StressMonitorWatch Watch App/Complications/ComplicationBundle.swift` with WidgetKit providers under `Complications/Providers/`.

**Tests:**
- Location: `StressMonitorTests/` (XCTest, run via the `StressMonitor` scheme).

## Architectural Constraints

- **Concurrency:** Swift strict-concurrency oriented. ViewModels, `StressRepository`, `SyncManager`, and `SupabaseLLMService` are `@MainActor`; service protocols are `Sendable`; HealthKit and SwiftData are imported `@preconcurrency` in `Services/Protocols/HealthKitServiceProtocol.swift` and `StressRepositoryProtocol.swift`.
- **Global state:** several shared singletons — `PhoneConnectivityManager.shared`, `WatchConnectivityManager.shared`, `WidgetDataProvider.shared`, `AppearanceManager.shared`, `HapticManager.shared`, `CharacterSelectionSync.shared`, `PaywallController` (owned once at the root scene).
- **No shared module:** the watch target re-declares models and the algorithm (`StressMonitorWatch Watch App/Models/`, `…/Services/`). Any change to `StressContext`, `StressResult`, `FactorWeights`, or a factor must be mirrored in both targets.
- **Cross-process boundary:** widgets and complications never touch SwiftData; they only read the App Group suite `group.com.stressmonitor.app`.
- **Schema migration:** adding a `@Model` type requires a new `VersionedSchema` + `MigrationStage` in `StressMonitorApp.swift`; skipping it can wipe the on-disk store.
- **Health data locality:** HealthKit-derived values stay on device; only chat context, auth, and preferences leave the device (`Services/LLM/`).

## Anti-Patterns

### Duplicated algorithm/model source across targets

**What happens:** `MultiFactorStressCalculator`, `StressFactor`, `StressContext`, `PersonalBaseline`, and friends exist twice — under `StressMonitor/Services/Algorithm/` and `StressMonitorWatch Watch App/Services/`.
**Why it's wrong:** edits applied to one copy silently diverge, so phone and watch can report different stress levels from the same inputs.
**Do this instead:** when touching algorithm or shared model files, apply the identical change to the watch copy in the same commit, and prefer moving genuinely shared logic into a shared package before adding new duplicated types.

### Force-unwrapped process boundaries

**What happens:** `WidgetDataProvider.init` calls `fatalError` when the App Group suite is missing (`StressMonitorWidget/Models/WidgetDataProvider.swift:45`), and `StressMonitorApp` calls `fatalError` when the `ModelContainer` fails (`StressMonitor/StressMonitorApp.swift:76`).
**Why it's wrong:** a provisioning or migration problem becomes a launch crash rather than a degraded but usable app.
**Do this instead:** for new cross-process stores, return an optional/failable initializer and render an explicit empty state, as `WidgetEntry` already supports.

### Print-based error handling in the connectivity bridge

**What happens:** `PhoneConnectivityManager.handleWatchMeasurement` swallows save failures with `print` (`StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift:55`).
**Why it's wrong:** dropped watch measurements are invisible in release builds.
**Do this instead:** surface failures through an observable status property the way `SyncManager` exposes `syncError`/`SyncStatus`.

## Error Handling

**Strategy:** typed throwing errors at service boundaries, optional/graceful degradation for secondary data, user-facing message string on the ViewModel.

**Patterns:**
- Domain error enums conforming to `LocalizedError`: `LLMServiceError` (`Services/LLM/LLMServiceProtocol.swift`), `SyncError` (`Services/Sync/SyncManager.swift`), `StressError` (used by `StressViewModel`).
- Required inputs `throw`; optional factors use `try?` so a missing sensor degrades weights instead of failing the calculation.
- ViewModels set `errorMessage` and clear it via `clearError()`; permission denial is tracked separately with `isPermissionRequired`.
- Sync/CloudKit surfaces state through `SyncStatus` / `NetworkReason` / `CloudKitAccountStatus` rather than throwing to the UI.

## Cross-Cutting Concerns

**Logging:** `os_signpost` / `OSLog` under `#if DEBUG` for launch and load instrumentation (`StressMonitorApp.swift`, `StressViewModel.swift`); no release-time logging framework.
**Validation:** input validity is encoded in the factor layer (each factor returns `nil` for unusable data) and in `DataQualityInfo` / `FactorResult.confidence`.
**Authentication:** Supabase JWT stored via `KeychainService` (`StressMonitor/Services/KeychainService.swift`), read by `SupabaseLLMService`; a guest JWT fallback lives in `Services/LLM/SupabaseConfig.swift`.
**Theming/accessibility:** `StressMonitor/Theme/` (design tokens, wellness colors, typography) plus `StressMonitor/Utilities/AccessibilityModifiers.swift`, `DynamicTypeScaling.swift`, `HighContrastModifier.swift`.
**Premium gating:** `PremiumState` + `PaywallController` consulted by feature views before showing gated content.

---

*Architecture analysis: 2026-08-08*
