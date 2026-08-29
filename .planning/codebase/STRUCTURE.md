# Codebase Structure

**Analysis Date:** 2026-08-29

## Directory Layout

```
ios-stress-app/                          # Repo root — run xcodebuild/fastlane/swiftlint here
├── AGENTS.md / CLAUDE.md                # Agent guidance (build cmds, quirks, conventions)
├── docs/                                # Product & engineering docs (start at docs/INDEX.md)
├── .github/workflows/                   # ci.yml → _test.yml, deploy.yml, distribute.yml, release.yml
├── fastlane/                            # Fastfile, Appfile, Matchfile (upload_beta etc.)
├── scripts/                             # run-tests.py (local test helper), generate_app_icons.py
├── ci_scripts/                          # Xcode CI scripts
├── assets/ · design/ · data/ · docs-site/ · droid-wiki/ · plans/   # Supporting assets/docs
├── .planning/                           # GSD planning docs (codebase maps live here)
└── StressMonitor/                       # Xcode project container
    ├── StressMonitor.xcodeproj/         # THE project (schemes: StressMonitor, watch; widget via CI only)
    ├── StressMonitor/                   # iOS APP TARGET (real code) — 301 Swift files
    │   ├── StressMonitorApp.swift       # @main entry, DI root, SwiftData schema/migration
    │   ├── Components/Character/        # Character companion art views (Ripple, Lumi, Ember…)
    │   ├── Models/ (+Base, +Character)  # SwiftData @Model entities + DTOs + WidgetSharedData
    │   ├── Navigation/                  # AppRouter, Route, View+NavigationDestinations
    │   ├── Services/<Domain>/           # 18 domain subdirectories (see below)
    │   ├── Theme/                       # DesignTokens, Color+Extensions, Gradients, Fonts
    │   ├── Utilities/                   # Accessibility, animation presets, FontBlaster
    │   ├── ViewModels/                  # Cross-tab @Observable VMs
    │   ├── Views/<Feature>/Components/  # Feature screens + local components + local VMs
    │   ├── Assets.xcassets · Fonts/     # Resources
    │   ├── Info.plist · StressMonitor.entitlements · PrivacyInfo.xcprivacy
    │   └── GoogleService-Info.plist     # Firebase config (committed)
    ├── StressMonitorTests/              # UNIT TEST TARGET (real) — 36 test files + .storekit
    ├── StressMonitorWatch Watch App/    # WATCH TARGET (path has spaces) — 74 Swift files
    ├── StressMonitorWidget/             # WIDGET TARGET — 13 Swift files
    ├── Models/ · Services/ · Views/     # ⚠️ ORPHANED — committed but in NO target
    ├── StressMonitorTests (none here — orphan is at repo root, see below)
    ├── build/ · spm-cache/              # Generated, gitignored
    └── plans/                           # Old planning notes
StressMonitorTests/                      # ⚠️ ORPHANED test dir at REPO ROOT — never builds
```

## Directory Purposes

**`StressMonitor/StressMonitor/` (iOS app target):**
- Purpose: All shipping iOS code
- Key files: `StressMonitorApp.swift` (entry), `Views/MainTabView.swift` (tab shell), `Views/Onboarding/OnboardingContainerView.swift` (root gate)
- ~301 Swift files across Models / Navigation / Services / Theme / Utilities / ViewModels / Views

**`StressMonitor/StressMonitor/Services/` (domain subdirectories):**
- `Algorithm/` — stress math: `MultiFactorStressCalculator.swift`, 5 `*StressFactor.swift`, `BaselineCalculator.swift`, `FactorCalibrator.swift`, `BioAgeCalculator.swift`, legacy `StressCalculator.swift`
- `API/` — `StressAPIClient.swift` + `+Credits/+Preferences/+QuickActions/+Sessions` extensions, `StressAPIConfig.swift`
- `Auth/` — `FirebaseAuthService.swift`, `AuthServiceError.swift`
- `Background/` — `HealthBackgroundScheduler.swift`, `NotificationManager.swift`
- `Chat/` — `ChatAvailability.swift`
- `CloudKit/` — `CloudKitManager.swift`, `CloudKitSchema.swift`, `CloudKitSyncEngine.swift`
- `Connectivity/` — `PhoneConnectivityManager.swift` (WCSession phone side)
- `Credits/` — `CreditService.swift`, `CreditServiceProtocol.swift`
- `DataManagement/` — `DataDeleter*.swift`, `CloudKitResetService.swift`, `LocalDataWipeService.swift`
- `Firebase/` — `FirebaseBootstrap.swift`
- `HealthKit/` — `HealthKitManager.swift` + `+ActivityFetch/+RecoveryFetch/+SleepFetch` extensions, `SimulatorHealthKitService.swift`
- `LLM/` — `StressLLMService.swift`, `SSEParser.swift`, `ChatContextBuilder.swift`, `ChatQuickActions.swift`, `LLMServiceProtocol.swift`
- `Preferences/` — `PreferencesService.swift`
- `Premium/` — `PaywallController.swift`
- `Protocols/` — the 4 core DI protocols: `StressAlgorithmServiceProtocol`, `HealthKitServiceProtocol`, `StressRepositoryProtocol`, `CloudKitServiceProtocol`
- `Repository/` — `StressRepository.swift`
- `StoreKit/` — `StoreKitService.swift`, `MockStoreKitService.swift`, `PremiumState.swift`, `StoreKitProductCatalog.swift`, `CreditPack.swift`, `StoreKitServiceEnvironment.swift`
- `Sync/` — `SyncManager.swift`, `ConflictResolver.swift`
- Root-level: `MockServices.swift`, `KeychainService.swift`, `AppearanceManager.swift`, `InsightGeneratorService.swift`, `CharacterAssetResolver.swift`

**`StressMonitor/StressMonitor/Views/` (feature folders):**
- Each feature = folder with screens + `Components/` subfolder; some also hold their ViewModel
- Folders: `Action/`, `Breathing/`, `Characters/`, `Chat/`, `Components/` (shared: `Gauges/`, `TabBar/`, `HapticManager.swift`), `Dashboard/` (+42 components + `DashboardViewModel.swift`), `DesignSystem/`, `History/`, `Journal/`, `MiniWalk/`, `Onboarding/`, `Premium/`, `Settings/` (+`DataManagement/`), `Shared/`, `Trends/`
- Root files: `DashboardView.swift`, `MainTabView.swift`, `HistoryView.swift`

**`StressMonitor/StressMonitorWatch Watch App/` (watch target — path contains spaces):**
- Purpose: Standalone watch app with duplicated algorithm sources
- Layout mirrors the app: `Models/`, `Services/` (incl. duplicated `MultiFactorStressCalculator.swift`, `*StressFactor.swift`, `*Protocol.swift`, plus `WatchHealthKitManager.swift`, `WatchConnectivityManager.swift`, `WatchSharedDataStore.swift`, `CloudKit/`), `ViewModels/`, `Views/`, `Theme/`, `Complications/` (`Providers/`, `Intents/`, `Views/`, `Services/`)
- Entry: `StressMonitorWatchApp.swift` → `ContentView.swift`

**`StressMonitor/StressMonitorWidget/` (widget target):**
- Purpose: WidgetKit widgets + Live Activity reading App Group data
- Key files: `StressMonitorWidgetBundle.swift`, `StressMonitorWidget.swift`, `StressMonitorWidgetControl.swift`, `StressMonitorWidgetLiveActivity.swift`, `Providers/StressWidgetProvider.swift`, `Models/WidgetDataProvider.swift`, `Views/{Small,Medium,Large,LockScreen}WidgetView.swift`, `Intents/UpdateWidgetIntent.swift`, `AppIntent.swift`
- `README.md` documents the target

**`StressMonitor/StressMonitorTests/` (test target):**
- Purpose: 36 unit-test files for API, StoreKit/IAP, credits, chat/SSE, persistence, ViewModels
- Key files: `StressMonitorProducts.storekit` (StoreKit config for IAP tests), `StoreKitTestSessionProvider.swift`, `SSEParserTests.swift`, `StressAPIClientTests.swift`, `DataDeletionConsolidationTests.swift` (skips under `GSD_CI`)

**`docs/`:**
- Purpose: Product/engineering documentation
- Key files: `INDEX.md` (navigation hub), `system-architecture*.md`, `code-standards*.md`, `design-guidelines*.md`, `TESTING.md`, `DEPLOYMENT.md`
- Committed; treat README package table as stale (trust the pbxproj)

## Key File Locations

**Entry Points:**
- `StressMonitor/StressMonitor/StressMonitorApp.swift`: iOS `@main`, DI root, versioned SwiftData schema V1→V2
- `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`: watchOS `@main`
- `StressMonitor/StressMonitorWidget/StressMonitorWidgetBundle.swift`: widget entry
- `StressMonitor/StressMonitor/Views/Onboarding/OnboardingContainerView.swift`: first-screen gate (onboarding vs MainTabView)
- `StressMonitor/StressMonitor/Views/MainTabView.swift`: tab shell, paywall cover, nav restoration

**Configuration:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`: target membership (source of truth — 4 targets)
- `StressMonitor/StressMonitor/Info.plist` + `StressMonitor.entitlements`: app config (base URL via `STRESS_API_BASE_URL`, CloudKit/HealthKit/App Group entitlements)
- `StressMonitor/StressMonitor/GoogleService-Info.plist`: Firebase (committed)
- `.swiftlint.yml` (repo root, `included: StressMonitor/`), `.github/workflows/*.yml`, `fastlane/Fastfile`

**Core Logic:**
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift`: composite stress score
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`: main orchestration VM (571 lines)
- `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`: persistence + sync + widget publish
- `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`: backend client

**Testing:**
- `StressMonitor/StressMonitorTests/`: all real tests
- `StressMonitor/StressMonitor/Services/MockServices.swift`: mock/stub factories for previews and tests

## Naming Conventions

**Files:**
- Views: `*View.swift` (e.g. `DashboardView.swift`, `BreathingSessionView.swift`)
- ViewModels: `*ViewModel.swift` — cross-tab in `ViewModels/`, feature-local co-located in `Views/<Feature>/` (e.g. `Views/Trends/TrendsViewModel.swift`); watch files prefixed `Watch*` (e.g. `WatchStressViewModel.swift`)
- Protocols: `*Protocol.swift` (e.g. `HealthKitServiceProtocol.swift`) or `*ServiceProtocol.swift`
- Service extensions: `Type+Feature.swift` (e.g. `StressAPIClient+Credits.swift`, `HealthKitManager+SleepFetch.swift`)
- Models: noun `*.swift` matching the type (e.g. `StressMeasurement.swift`, `FactorWeights.swift`)
- Tests: `*Tests.swift` matching subject (e.g. `SSEParserTests.swift`)

**Directories:**
- Feature folders in `Views/`: capitalized feature name with `Components/` subfolder for reusable pieces (`Views/Dashboard/Components/`)
- Service domains: singular noun (`Algorithm/`, `Auth/`, `Credits/`)
- The watch target directory literally contains spaces: `StressMonitorWatch Watch App/` — always quote it

**Bundles/IDs:**
- App `stress.ai.com`, watch `stress.ai.com.watchkitapp`, widget `stress.ai.com.widget`; App Group `group.stress.ai.com`; team `K2TYLYAWMK`

## Where to Add New Code

**New feature screen (iOS):**
- Screen: `StressMonitor/StressMonitor/Views/<Feature>/<Feature>View.swift`
- Components: `StressMonitor/StressMonitor/Views/<Feature>/Components/`
- ViewModel: `StressMonitor/StressMonitor/ViewModels/<Feature>ViewModel.swift` (cross-tab) or co-locate in the feature folder (feature-local)
- Route: add a case to `Navigation/Route.swift` and a destination in `Navigation/View+NavigationDestinations.swift`
- MUST also add the file to the `StressMonitor` target in Xcode (pbxproj)

**New service:**
- Implementation: `StressMonitor/StressMonitor/Services/<Domain>/<Name>Service.swift`
- Protocol (if consumed by ViewModels): `StressMonitor/StressMonitor/Services/Protocols/` (or domain-local like `Credits/CreditServiceProtocol.swift`)
- Mock: extend `Services/MockServices.swift`
- If it is stress-algorithm code: MIRROR the file into `StressMonitor/StressMonitorWatch Watch App/Services/` and add to the watch target

**New SwiftData model:**
- Model file: `StressMonitor/StressMonitor/Models/<Name>.swift` (`@Model final class`)
- Bump the versioned schema: new `AppSchemaV(n)` enum + lightweight `MigrationStage` in `StressMonitorApp.swift:40-74`
- Mirror into watch `Models/` only if the watch target needs it (watch has its own copies of the model types)

**New API endpoint:**
- Either extend the matching `StressAPIClient+<Domain>.swift` or create `Services/API/StressAPIClient+<Domain>.swift`; build query-carrying URLs with `URLComponents`, never `appendingPathComponent`
- Test: matching `StressMonitorTests/StressAPIClient<Domain>Tests.swift`

**New widget surface:**
- View in `StressMonitor/StressMonitorWidget/Views/`, wire in `StressMonitorWidget.swift`/`StressMonitorWidgetBundle.swift`; shared data shape changes must update `Models/WidgetSharedData.swift` (app side) AND the duplicated widget copies

**New test:**
- `StressMonitor/StressMonitorTests/<Subject>Tests.swift`; IAP tests use `StressMonitorProducts.storekit`

**Utilities:**
- Shared helpers: `StressMonitor/StressMonitor/Utilities/`
- Shared UI components: `StressMonitor/StressMonitor/Views/Components/` (design primitives in `Views/DesignSystem/`)

**Do NOT add code to (orphaned, never compiles):**
- `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, repo-root `StressMonitorTests/`

## Special Directories

**`StressMonitor/build/`, `StressMonitor/spm-cache/`:**
- Purpose: Build output and SPM package cache (`scripts/run-tests.py` writes results here)
- Generated: Yes
- Committed: No (gitignored)

**`.planning/`:**
- Purpose: GSD planning artifacts (codebase maps, milestones, phases)
- Generated: By GSD commands
- Committed: Yes

**`.gsd/`, `.gitnexus/`, `.claude/`, `.agents/`, `.opencode/`, `.kiro/`, `.gemini/`, `.codex/`, `.cursor/`:**
- Purpose: Agent tooling configs, skills, rules, indexes
- Generated: Partly (indexes/caches)
- Committed: Varies — do not delete, do not treat as product code

**`docs/`:**
- Purpose: Human documentation; `INDEX.md` is the entry point
- Generated: No
- Committed: Yes

**Orphaned source dirs (`StressMonitor/{Models,Services,Views}`, root `StressMonitorTests/`):**
- Purpose: Legacy pre-restructure locations; committed but absent from the pbxproj
- Generated: No
- Committed: Yes (do not edit — never builds; candidates for deletion in a cleanup phase)

---

*Structure analysis: 2026-08-29*
