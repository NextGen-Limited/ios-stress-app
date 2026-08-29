<!-- refreshed: 2026-08-29 -->
# Architecture

**Analysis Date:** 2026-08-29

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                            iOS App (stress.ai.com)                           │
│  Entry: StressMonitor/StressMonitor/StressMonitorApp.swift (@main)           │
├─────────────────────────────────┬────────────────────────────────────────────┤
│  OnboardingContainerView       │  MainTabView (4 tabs: home/action/trend/    │
│  → MainTabView                 │  settings, NavigationStack per tab)         │
│  Views/* + Views/Components/*  │  Navigation: AppRouter + Route enum         │
├─────────────────────────────────┴────────────────────────────────────────────┤
│  ViewModels (@Observable, @MainActor)                                        │
│  ViewModels/: Stress · Chat · Credits · Premium · Account · Habit ·          │
│    CharacterCollection  |  feature-local: Dashboard · History(+Detail) ·     │
│    Trends · Settings · Breathing · MiniWalk · Onboarding*                    │
├──────────────────────────────────────────────────────────────────────────────┤
│  Services (protocol-based DI, Services/Protocols/*Protocol.swift)            │
│  ┌────────────┬──────────────┬───────────────┬──────────────┬─────────────┐  │
│  │ HealthKit  │ Algorithm    │ Repository    │ API/LLM      │ StoreKit/   │  │
│  │ Manager    │ MultiFactor  │ StressRepo    │ StressAPI    │ Credits/    │  │
│  │ (read-only)│ StressCalc   │ (SwiftData)   │ Client (SSE) │ Paywall     │  │
│  └────────────┴──────────────┴───────────────┴──────────────┴─────────────┘  │
├──────────────────────────────────────────────────────────────────────────────┤
│  Persistence & Sync                                                          │
│  SwiftData ModelContainer (schema V2, CloudKit .automatic) · CloudKitManager │
│  + CloudKitSyncEngine (offline-first manual sync w/ ConflictResolver)        │
└───────────────┬──────────────────────────────┬───────────────────────────────┘
                │                              │
                ▼                              ▼
┌──────────────────────────────┐  ┌───────────────────────────────────────────┐
│ watchOS App (stress.ai.com.  │  │ Widget Extension (stress.ai.com.widget)   │
│ watchkitapp) — duplicates    │  │ App Group "group.stress.ai.com":          │
│ algorithm sources; talks via │  │ WidgetPublisher (app writes) →            │
│ WCSession ↔ PhoneConnector   │  │ WidgetDataProvider (widget reads)         │
└──────────────────────────────┘  └───────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  Backend (https://stress-api.dropitx.site) via StressAPIClient — Firebase    │
│  Auth Bearer token; chat SSE streaming, credits (redeem/premium-verify),     │
│  preferences, quick-actions, sessions                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry / DI root | Owns app-scope singletons (AppRouter, PaywallController, StoreKitService, CreditService, PreferencesService), SwiftData container with versioned schema + recovery, Firebase bootstrap + anonymous auth, scenePhase entitlement/credit refresh | `StressMonitor/StressMonitor/StressMonitorApp.swift` |
| Router | Central navigation state: selected tab + per-tab `NavigationPath`, deep links, state restoration | `StressMonitor/StressMonitor/Navigation/AppRouter.swift` |
| Route table | Codable, Hashable value-type destinations resolved by one `.navigationDestination` block | `StressMonitor/StressMonitor/Navigation/Route.swift` |
| Stress VM | Orchestrates HealthKit fetch → algorithm → persistence → dashboard state | `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` |
| Multi-factor calculator | Weighted composite of 5 `StressFactor`s, weight redistribution for missing factors, confidence = 0.4·dataCompleteness + 0.6·avgConfidence | `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` |
| Legacy calculator | HRV+HR 2-factor fallback (`calculateStress(hrv:heartRate:)`) | `StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift` |
| HealthKit service | Read-only HRV/HR/sleep/activity/recovery/respiratory queries | `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` |
| Repository | Offline-first SwiftData CRUD, baseline storage, CloudKit sync triggers, widget publish | `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` |
| API client | Authenticated HTTP for backend (Bearer token injection, endpoint-group extensions) | `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` |
| Auth service | Firebase anonymous sign-in + Google linking upgrade; ID-token retrieval with expiry margin; `AuthServiceProtocol` seam defined alongside | `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift` |
| LLM service | SSE consumption loop for `/chat`, rolling session id, credits metadata convergence, 402→insufficientCredits mapping | `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift` |
| Credit service | App-scope credit balance cache; converged only from server responses (GET /credits, redemption, chat metadata) — never client arithmetic | `StressMonitor/StressMonitor/Services/Credits/CreditService.swift` |
| StoreKit service | Purchases + entitlements; posts signed purchase JWS to backend for server-authoritative grants (`completePurchase` choke point) | `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` |
| Paywall controller | App-wide paywall presentation singleton (`present(reason:)` from anywhere) | `StressMonitor/StressMonitor/Services/Premium/PaywallController.swift` |
| CloudKit sync | Batched, retrying CloudKit sync with conflict resolution | `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift`, `Services/Sync/SyncManager.swift` |
| Watch connectivity | WCSession bridge: watch measurements → phone inserts | `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` |
| Widget publishing | Writes latest measurement to App Group + reloads widget timeline | `StressMonitor/StressMonitor/Models/WidgetSharedData.swift` (`WidgetPublisher`) |
| Watch app | Standalone stress measurement, complications, cycle/mood/habit/workout logging | `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift` |
| Widget | Home-screen/lock-screen stress widgets reading App Group data | `StressMonitor/StressMonitorWidget/StressMonitorWidget.swift` |

## Pattern Overview

**Overall:** MVVM with SwiftUI, `@Observable` ViewModels, protocol-oriented DI

**Key Characteristics:**
- ViewModels are `@Observable @MainActor final class`; views hold them via `@State` and construct them in `init` with concrete services (constructor injection at the view boundary — see `Views/DashboardView.swift:12-28`)
- Every cross-cutting dependency has a protocol seam: `Services/Protocols/` (iOS), `Services/LLM/LLMServiceProtocol.swift`, `Services/StoreKit/StoreKitServiceProtocol.swift`, `Services/Credits/CreditServiceProtocol.swift`, `Services/Auth/FirebaseAuthService.swift` (`AuthServiceProtocol`), and duplicated protocol files in the watch target (`StressMonitorWatch Watch App/Services/*Protocol.swift`)
- App-scope state uses SwiftUI `@Environment` injection from `StressMonitorApp` (AppRouter, PaywallController, CreditService, PreferencesService) plus a custom `\.storeKitService` environment value
- Singletons exist deliberately for process-lifetime concerns: `PhoneConnectivityManager.shared`, `PremiumState.shared`, `AppearanceManager.shared`, watch `WatchConnectivityManager.shared`
- Offline-first writes: SwiftData local save always happens before CloudKit sync (`Services/Repository/StressRepository.swift:47-62`)
- Server-authoritative money: credits and premium are only granted from backend responses to posted Apple-signed JWS transactions (`Services/StoreKit/StoreKitService.swift:345-400`)

## Layers

**Views (UI):**
- Purpose: SwiftUI screens and reusable components; no business logic
- Location: `StressMonitor/StressMonitor/Views/` (feature folders with `Components/` subfolders), shared character art in `StressMonitor/StressMonitor/Components/Character/`
- Contains: `*View.swift`, feature-local `*ViewModel.swift` (e.g. `Views/Onboarding/OnboardingWelcomeViewModel.swift`), design tokens in `Views/DesignSystem/`
- Depends on: ViewModels, Theme (`Theme/DesignTokens.swift`), environment objects
- Used by: `MainTabView` / `OnboardingContainerView` compose them

**ViewModels:**
- Purpose: Presentation state + orchestration of services
- Location: `StressMonitor/StressMonitor/ViewModels/` (cross-tab: Stress, Chat, Credits, Premium, Account, Habit, CharacterCollection) or co-located with feature (`Views/Dashboard/DashboardViewModel.swift`, `Views/History/HistoryViewModel.swift` + `DetailViewModel.swift`, `Views/Trends/TrendsViewModel.swift`, `Views/Settings/SettingsViewModel.swift`, `Views/Breathing/BreathingViewModel.swift`, `Views/MiniWalk/MiniWalkViewModel.swift`, `Views/Onboarding/*ViewModel.swift`)
- Depends on: `HealthKitServiceProtocol`, `StressAlgorithmServiceProtocol`, `StressRepositoryProtocol`, `StressAPIClient`, `AuthServiceProtocol`
- Used by: views via `@State private var viewModel`

**Services:**
- Purpose: All I/O and domain logic, grouped by domain subdirectory (`Algorithm/`, `API/`, `Auth/`, `Background/`, `Chat/`, `CloudKit/`, `Connectivity/`, `Credits/`, `DataManagement/`, `Firebase/`, `HealthKit/`, `LLM/`, `Preferences/`, `Premium/`, `Repository/`, `StoreKit/`, `Sync/`)
- Location: `StressMonitor/StressMonitor/Services/`
- Depends on: system frameworks (HealthKit, CloudKit, WatchConnectivity, StoreKit, WidgetKit), Firebase/GoogleSignIn SPM packages
- Used by: ViewModels, other services (e.g. `StoreKitService` → `StressAPIClient` for JWS redemption)

**Models:**
- Purpose: SwiftData `@Model` entities, value-type DTOs, shared schemas
- Location: `StressMonitor/StressMonitor/Models/` (`Base/` for `ObservableModel.swift`, `Character/` for character domain)
- Note: `Models/WidgetSharedData.swift` also contains behavior (`WidgetPublisher`, `WidgetDataState`) because it is shared shape with the widget target

**Navigation:**
- Purpose: Type-safe routing and state restoration
- Location: `StressMonitor/StressMonitor/Navigation/` (`AppRouter.swift`, `Route.swift`, `View+NavigationDestinations.swift`)

**Persistence:**
- SwiftData `ModelContainer` created in `StressMonitorApp.makeContainer()`; schema V2 = `[StressMeasurement, CharacterUnlock, Habit]`; lightweight migration V1→V2; on failure the store is deleted and rebuilt local-only, then in-memory as last resort
- CloudKit via `ModelConfiguration(cloudKitDatabase: .automatic)` plus a manual sync path (`CloudKitSyncEngine`, `SyncManager`, `ConflictResolver`)

## Data Flow

### Primary Request Path: Stress Score

1. App launch — `StressMonitorApp.init` bootstraps Firebase and signs in anonymously (`StressMonitorApp.swift:164-172`); `OnboardingContainerView` → `MainTabView` builds `StressRepository(modelContext:)` (`StressMonitor/StressMonitor/Views/Onboarding/OnboardingContainerView.swift`)
2. `DashboardView` constructs `StressViewModel(healthKit:algorithm:repository:)` (`Views/DashboardView.swift:12-28`); `.task` → `loadCurrentStress()` (`ViewModels/StressViewModel.swift:110`)
3. Five parallel HealthKit queries via `async let`: HRV, HR (critical, throwing) + sleep/activity/recovery (graceful `try?`) (`ViewModels/StressViewModel.swift:131-147`)
4. `StressContext` assembled → `algorithm.calculateMultiFactorStress(context:)` (`ViewModels/StressViewModel.swift:150-160`)
5. `MultiFactorStressCalculator.calculateMultiFactorStress` runs each `StressFactor`, redistributes weights over available factors, produces `StressResult` (0–100 → Relaxed/Mild/Moderate/High) + `FactorBreakdown` (`Services/Algorithm/MultiFactorStressCalculator.swift`)
6. VM persists via `repository.save(measurement)` — SwiftData insert/save → `WidgetPublisher.publish` (App Group + timeline reload) → optional CloudKit sync (`Services/Repository/StressRepository.swift:47-62`)
7. Dashboard renders; `DataQualityInfo(from:breakdown:baseline:)` derives data-quality badge state

### Chat Flow (AI Coach)

1. `ChatBottomSheetView` presents `ChatViewModel`; view injects `apiClient` + `preferencesService` on appear (`ViewModels/ChatViewModel.swift:46-60`)
2. Send → `StressLLMService` (via `LLMServiceProtocol`) creates a titled session first when none exists (fail-soft), then builds the stress-context payload (`Services/LLM/ChatContextBuilder.swift`, `StressContextPayload.swift`)
3. `StressAPIClient.authorizedRequest` attaches the Firebase Bearer token (`Services/API/StressAPIClient.swift:38-70`); `/chat` streams SSE parsed by `Services/LLM/SSEParser.swift`
4. Terminal SSE event metadata (`credits_remaining`, session id, model, quick actions) converges into `CreditService` via the `onCreditsRemainingChange` callback (`Services/LLM/StressLLMService.swift`)
5. HTTP 402 → `LLMServiceError.insufficientCredits` (`StressLLMService.mapHTTPError`) → `presentPaywall` closure → `PaywallController.present(reason:)` full-screen cover above all tabs (`Views/MainTabView.swift:105-107`)

### Purchase → Server Verification Flow (StoreKit + backend)

1. `PaywallView`/`IAPPremiumView` → `StoreKitService.purchase(_:)` (subscription) or `purchase(pack:)` (credit pack) (`Services/StoreKit/StoreKitService.swift:127-190`)
2. Purchase sheet returns a `VerificationResult<Transaction>`; local `checkVerified` runs, then the signed JWS travels as an explicit parameter: `completePurchase(transaction, jwsRepresentation: verification.jwsRepresentation)` (`StoreKitService.swift:344-400`)
3. **Credit packs use a deferred grant:** the backend redeems the JWS (`POST /credits/redeem`, idempotent on Apple transaction id) BEFORE `transaction.finish()` — a finished consumable is gone forever, an unfinished one is redelivered and retried (`Services/API/StressAPIClient+Credits.swift`, `StoreKitService.swift:351-358`)
4. **Subscriptions post to `POST /credits/premium/verify`** (DEC-1 server-side premium sync) then finish immediately — restorable via `currentEntitlements`; a revoked subscription JWS is still posted as a demotion signal; a refunded pack is finished without redemption (`StoreKitService.swift:344-400`)
5. `Transaction.updates` listener (`StoreKitServiceEnvironment.swift` owns it for the process lifetime in Release; `StressMonitorApp` owns the service) routes redelivered transactions through the same `completePurchase` choke point — a redemption failure leaves the transaction unfinished so StoreKit retries
6. Server response carries the authoritative `CreditBalance`, applied to the app-scope `CreditService`; `refreshEntitlements()` remains the sole local corrector for premium state and re-syncs active subscriptions to the server on every foreground (`StressMonitorApp.swift:219-243`)

### Auth Flow (anonymous + Google linking)

1. `FirebaseBootstrap.bootstrap()` guards `FirebaseApp.configure()`; only on `.configured` does `StressMonitorApp.init` fire `Auth.auth().signInAnonymously()` (fail-soft) (`Services/Firebase/FirebaseBootstrap.swift`, `StressMonitorApp.swift:164-172`)
2. `FirebaseAuthService.getIDToken()` returns a cached-or-refreshed ID token, forcing refresh within a 60s expiry margin; `StressAPIClient.authorizedRequest` injects it as Bearer on every non-`/health` request (`Services/Auth/FirebaseAuthService.swift`, `Services/API/StressAPIClient.swift:38-70`)
3. Google upgrade path: Settings → `AccountViewModel.signInWithGoogle(presenting:)` runs Google OAuth then LINKS the credential to the current anonymous user (preserving credits/chat history); if the Google credential is already bound to another account it falls back to plain `signIn(with:)` (`ViewModels/AccountViewModel.swift`, `Services/Auth/FirebaseAuthService.swift`)
4. Stale sessions surface as HTTP 401 from the backend — typed as `CreditsAPIError.unauthorized` / mapped in `StressLLMService.mapHTTPError`; the foreground `creditService.refreshBalance()` doubles as the stale-session probe (`StressMonitorApp.swift:224-233`)

### Watch → Phone Flow

1. Watch `WatchStressViewModel` computes stress with duplicated algorithm (`StressMonitorWatch Watch App/Services/MultiFactorStressCalculator.swift`)
2. `WatchConnectivityManager.syncData` → `WCSession.transferUserInfo` (`StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift:23`)
3. Phone `PhoneConnectivityManager.handleWatchMeasurement` decodes userInfo → constructs `StressMeasurement` → inserts into SwiftData (`Services/Connectivity/PhoneConnectivityManager.swift:27-55`)

### Widget Flow

1. `StressRepository.save` → `WidgetPublisher.publish(measurement)` writes snapshot to App Group `group.stress.ai.com` and calls `WidgetCenter.shared.reloadAllTimelines` (`Models/WidgetSharedData.swift:132-145`)
2. `StressWidgetProvider.timeline` reads via `WidgetDataProvider` (App Group UserDefaults) (`StressMonitorWidget/Providers/StressWidgetProvider.swift`, `StressMonitorWidget/Models/WidgetDataProvider.swift`)
3. Freshness resolved by `WidgetDataState` (duplicated byte-identical in both targets — no shared module exists)

**State Management:**
- UI state: `@Observable` ViewModels owned by views (`@State`)
- App-scope state: `@Environment` injection from the App struct (single source for paywall, credits, preferences, navigation, StoreKit service)
- IAP entitlements: `PremiumState.shared` singleton, self-corrected on every foreground (`StressMonitorApp.swift:219-243`)
- Persistence: SwiftData `@Environment(\.modelContext)` flows down from `.modelContainer(sharedModelContainer)`

## Key Abstractions

**StressFactor (strategy pattern):**
- Purpose: One stress contributor scoring 0–1 with its own weight
- Examples: `Services/Algorithm/HRVStressFactor.swift`, `HeartRateStressFactor.swift`, `SleepStressFactor.swift`, `ActivityStressFactor.swift`, `RecoveryStressFactor.swift`
- Pattern: `protocol StressFactor: Sendable { var id: String; var weight: Double; func calculate(context:) async throws -> FactorResult? }` (`Services/Algorithm/StressFactor.swift`) — returning nil excludes the factor and triggers weight redistribution

**Service protocols (DI seams):**
- Purpose: Decouple ViewModels from concrete services; enable `MockServices.swift` and `SimulatorHealthKitService`
- Examples: `Services/Protocols/StressAlgorithmServiceProtocol.swift`, `HealthKitServiceProtocol.swift`, `StressRepositoryProtocol.swift`, `CloudKitServiceProtocol.swift`; plus `Services/Credits/CreditServiceProtocol.swift`, `Services/StoreKit/StoreKitServiceProtocol.swift`, `Services/LLM/LLMServiceProtocol.swift`, `AuthServiceProtocol` (`Services/Auth/FirebaseAuthService.swift`)
- Pattern: protocol with default-implemented backward-compatible overloads; ViewModels accept protocols in `init`

**Endpoint-group extensions:**
- Purpose: Keep `StressAPIClient` small while grouping endpoints by domain
- Examples: `Services/API/StressAPIClient+Credits.swift`, `+Preferences.swift`, `+QuickActions.swift`, `+Sessions.swift`
- Pattern: `extension StressAPIClient` per API domain around shared `authorizedRequest` builder; per-domain typed errors (e.g. `CreditsAPIError` with `.unauthorized` distinct from server faults)

**Purchase grant seam (`PurchaseTransactionHandle` / `PurchaseRedeemer`):**
- Purpose: Make the redeem-before-finish ordering unit-pinnable without a StoreKitTest session
- Examples: `Services/StoreKit/StoreKitService.swift:11-27`
- Pattern: minimal transaction-surface protocol (`Transaction` conforms via extension) + a `@MainActor (String) async throws -> CreditBalance` redeemer closure injected in `init`; the JWS travels as an explicit parameter because StoreKit 2 exposes it on `VerificationResult`, not `Transaction`

**Versioned SwiftData schema:**
- Purpose: Safe migration instead of silent store wipe
- Examples: `AppSchemaV1`/`AppSchemaV2`/`AppMigrationPlan` nested in `StressMonitorApp.swift:40-74`
- Pattern: nested `VersionedSchema` enums + `SchemaMigrationPlan` with lightweight stages; adding a model = new V(n) enum + stage

**Character unlock domain:**
- Purpose: Gamified companion characters tied to stress data and premium entitlement
- Examples: `Models/Character/CharacterCreature.swift`, `CharacterUnlock.swift` (SwiftData), `Components/Character/*` views, seeding in `StressMonitorApp.seedDefaultCharacterUnlocks`

## Entry Points

**iOS app:**
- Location: `StressMonitor/StressMonitor/StressMonitorApp.swift`
- Triggers: `@main`; normal launch and `-demo-mode` launch argument (DEBUG) which swaps `SimulatorHealthKitService` into the real pipeline
- Responsibilities: DI root, ModelContainer + recovery, Firebase bootstrap, anonymous auth, scenePhase refresh, schema migration; DEBUG builds substitute `MockStoreKitService` at the factory (`makeStoreKitService`)

**watchOS app:**
- Location: `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`
- Triggers: `@main`; activates `WatchConnectivityManager.shared` in `init`, root `ContentView`
- Note: the watch target has NO backend/API/Auth/LLM/StoreKit code — server integration is iOS-only

**Widget extension:**
- Location: `StressMonitor/StressMonitorWidget/StressMonitorWidgetBundle.swift`
- Triggers: WidgetKit timeline from `StressWidgetProvider`; `AppIntent.swift` / `Intents/UpdateWidgetIntent.swift` for interactive updates; `StressMonitorWidgetLiveActivity.swift` for Live Activity

**Unit tests:**
- Location: `StressMonitor/StressMonitorTests/` (36 test files + `StressMonitorProducts.storekit`)
- Host: `StressMonitor` scheme with `-parallel-testing-enabled NO`
- Network-touching suites mock transport with `URLProtocol` subclasses (`StressAPIClient*Tests.swift`, `CreditServiceTests.swift`, `ChatHistoryRestoreTests.swift`, `PreferencesServiceTests.swift`)

**Background work:**
- `Services/Background/HealthBackgroundScheduler.swift` — HealthKit background delivery
- `Services/Background/NotificationManager.swift` — local notifications
- `StoreKitServiceEnvironment.swift` — process-lifetime `Transaction.updates` listener (`Services/StoreKit/StoreKitServiceEnvironment.swift`)

## Architectural Constraints

- **Target duplication (CRITICAL):** The watch target duplicates algorithm and protocol sources — `MultiFactorStressCalculator`, all `*StressFactor.swift`, `StressFactor.swift`, `StressCalculator`, `BaselineCalculator`, `BioAgeCalculator`, model types, and `CloudKitServiceProtocol`/`HealthKitServiceProtocol`/`StressAlgorithmServiceProtocol` exist in BOTH `StressMonitor/StressMonitor/Services/Algorithm/` and `StressMonitor/StressMonitorWatch Watch App/Services/`. There is no shared framework/module. Any algorithm change must be mirrored into the watch target or the two platforms silently diverge.
- **Widget shared-shape duplication:** `WidgetDataState` and the App Group keys are duplicated by convention between `Models/WidgetSharedData.swift` (app) and `StressMonitorWidget/Providers/StressWidgetProvider.swift` / `Models/WidgetDataProvider.swift` (widget) — they must stay byte-identical (pinned by `WidgetPublisherKeyMatchingTests.swift`).
- **Orphaned code (never edit):** `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, and repo-root `StressMonitorTests/` are committed to git but NOT members of any target in `StressMonitor.xcodeproj` — edits there never build or run. Real targets live at `StressMonitor/StressMonitor/`, `StressMonitor/StressMonitorTests/`, `StressMonitor/StressMonitorWatch Watch App/`, `StressMonitor/StressMonitorWidget/`.
- **Threading:** ViewModels and most services are `@MainActor`; `StressRepository` holds a `nonisolated` `BaselineCalculator` to avoid isolation violations; HealthKit/background work hops off main via `async let` and `Task(priority:)`. `StressLLMService` and `FirebaseAuthService` are `@MainActor` + `@unchecked Sendable`.
- **Global state:** `PremiumState.shared`, `PhoneConnectivityManager.shared`, `AppearanceManager.shared`, `CharacterSelectionSync.shared` (app); `WatchConnectivityManager.shared`, `WatchSharedDataStore` (watch).
- **Xcode paths:** Watch target path contains spaces — quote `"StressMonitorWatch Watch App"` in every xcodebuild/fastlane invocation.
- **Test-host constraints:** CloudKit is disabled when `XCTestConfigurationFilePath` is set (`StressMonitorApp.isRunningUnitTests`) to keep CI test hosts alive; `DataDeletionConsolidationTests` skip when `GSD_CI` is set (CI sets it as `TEST_RUNNER_GSD_CI` so xcodebuild forwards it into the test host).
- **Deployment targets:** iOS 18.6 (some configurations 26.1), watchOS 11.6, Swift 5 language mode. Bundle IDs `stress.ai.com` / `.watchkitapp` / `.widget`, App Group `group.stress.ai.com`, team `K2TYLYAWMK`.

## Anti-Patterns

### Editing orphaned directories

**What happens:** `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, root `StressMonitorTests/` look like the app's source tree but are not in the pbxproj file lists.
**Why it's wrong:** Changes there compile nowhere; tests and app behavior never reflect them, producing phantom "fixed" work.
**Do this instead:** All edits go under `StressMonitor/StressMonitor/` (app), `StressMonitor/StressMonitorWatch Watch App/`, `StressMonitor/StressMonitorWidget/`, `StressMonitor/StressMonitorTests/`. Verify with a build: `xcodebuild build -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor ...`.

### Duplicating a shared type instead of updating both copies

**What happens:** New fields/types added to one target's copy of algorithm sources or widget shared-shape types (e.g. adding a factor metadata key only on iOS).
**Why it's wrong:** Watch and widget targets drift; `Codable` App Group payloads and WCSession dictionaries stop decoding.
**Do this instead:** Mirror the change into the watch copy (`StressMonitorWatch Watch App/Services/`) or both widget copies, keeping them byte-identical where the comment says so (`Models/WidgetSharedData.swift`).

### Business logic in views

**What happens:** Views constructing throwaway persistence in `init` (e.g. `DashboardView` fallback creating an in-memory container, `Views/DashboardView.swift:22-27`).
**Why it's wrong:** Silent data loss path; hard to test.
**Do this instead:** Follow the primary path — build `StressRepository` once in `OnboardingContainerView`/`MainTabView` and pass it down; use the fallback only for previews.

### Finishing a consumable before the server ack

**What happens:** Calling `transaction.finish()` on a credit pack before the backend redeems its JWS.
**Why it's wrong:** A finished consumable is never redelivered — a crash mid-flow silently loses the purchase; conversely, retrying a refunded pack's JWS wedges the queue forever (the server rejects it permanently).
**Do this instead:** Route every grant through `completePurchase` (`Services/StoreKit/StoreKitService.swift:344-400`): redeem-then-finish for packs, verify+finish for subscriptions, finish-only for revoked packs.

## Error Handling

**Strategy:** Typed errors at service boundaries; user-facing message strings on ViewModels; graceful degradation for non-critical data.

**Patterns:**
- `LLMServiceError` with `LocalizedError` descriptions incl. `insufficientCredits` mapped from HTTP 402 and `rateLimited` from 429 (`Services/LLM/LLMServiceProtocol.swift`, `StressLLMService.mapHTTPError`)
- `CreditsAPIError` (`Services/API/StressAPIClient+Credits.swift`) keeps `.unauthorized` (401 = stale session) distinct from `.invalidTransaction` (400) and `.server(statusCode:)`
- `AuthServiceError` (`Services/Auth/AuthServiceError.swift`), `RepositoryError.saveFailed` (`Services/Repository/StressRepository.swift:53`)
- Non-critical HealthKit factors degrade via `try?` while HRV absence aborts (`ViewModels/StressViewModel.swift:136-147`)
- CloudKit errors surfaced through `onSyncError` callbacks rather than thrown to callers
- ViewModels expose `errorMessage: String?` rendered by view `.alert`

## Cross-Cutting Concerns

**Logging:** `os.Logger` with subsystem `com.stressmonitor.app` and per-category loggers; DEBUG-only `os_signpost` for launch/stress-calc timing (`StressMonitorApp.swift`, `ViewModels/StressViewModel.swift:111-118`).
**Validation:** Manual Codable decoding with defensive fallbacks (navigation path decode drops corrupt data, `Navigation/AppRouter.swift:66-78`); URL building via `URLComponents` for query strings (documented pitfall in `Services/API/StressAPIClient.swift:33-37` — `appendingPathComponent` percent-encodes `?`).
**Authentication:** Firebase Auth (anonymous on launch, GoogleSignIn linking upgrade) → ID token injected as Bearer header by `StressAPIClient`; token refresh margin 60s in `FirebaseAuthService`; bootstrap guard in `Services/Firebase/FirebaseBootstrap.swift` (committed `GoogleService-Info.plist`).
**Accessibility:** `.accessibleDynamicType()` modifier, 44pt targets, dual-coded stress levels — see `Utilities/AccessibilityModifiers.swift`, `Utilities/DynamicTypeScaling.swift`.
**Haptics:** Centralized `Views/Components/HapticManager.swift`.
**Theming:** `Theme/DesignTokens.swift`, `Color.stressColor(for:)` in `Theme/Color+Extensions.swift`, shared spacing/typography in `Views/DesignSystem/`.

---

*Architecture analysis: 2026-08-29*
