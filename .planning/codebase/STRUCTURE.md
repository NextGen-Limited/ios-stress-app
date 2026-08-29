<!-- refreshed: 2026-08-29 -->
# Codebase Structure

**Analysis Date:** 2026-08-29

## Directory Layout

```
ios-stress-app/                          # Repo root — run xcodebuild/fastlane/swiftlint here
├── AGENTS.md / CLAUDE.md / README.md / CHANGELOG.md   # Agent + project guidance
├── docs/                                # Product & engineering docs (start at docs/INDEX.md)
├── .github/workflows/                   # ci.yml → _test.yml, deploy.yml, distribute.yml,
│                                        #   release.yml, match.yml, droid-wiki-refresh.yml
├── fastlane/                            # Fastfile, Appfile, Matchfile (upload_beta etc.)
├── scripts/                             # run-tests.py (local test helper), generate_app_icons.py
├── ci_scripts/                          # Xcode CI scripts
├── assets/ · design/ · data/ · docs-site/ · droid-wiki/ · plans/   # Supporting assets/docs
├── .planning/                           # GSD planning docs (codebase maps live here)
└── StressMonitor/                       # Xcode project container
    ├── StressMonitor.xcodeproj/         # THE project — 4 targets (app, tests, widget ext, watch)
    │   └── xcshareddata/xcschemes/      #   Schemes: StressMonitor, "StressMonitorWatch Watch App"
    ├── StressMonitor/                   # iOS APP TARGET (real code) — 301 Swift files
    │   ├── StressMonitorApp.swift       # @main entry, DI root, SwiftData schema/migration
    │   ├── Components/Character/        # Character companion art views (Ripple, Lumi, Ember…)
    │   ├── Models/ (+Base, +Character)  # SwiftData @Model entities + DTOs + WidgetSharedData
    │   ├── Navigation/                  # AppRouter, Route, View+NavigationDestinations
    │   ├── Services/<Domain>/           # 17 domain subdirectories (see below)
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
- `Algorithm/` — stress math: `MultiFactorStressCalculator.swift`, 5 `*StressFactor.swift`, `BaselineCalculator.swift`, `FactorCalibrator.swift`, `BioAgeCalculator.swift`, legacy `StressCalculator.swift`, `StressFactor.swift` (protocol)
- `API/` — `StressAPIClient.swift` + `+Credits/+Preferences/+QuickActions/+Sessions` extensions, `StressAPIConfig.swift` (base URL: Info.plist `STRESS_API_BASE_URL` → env → `https://stress-api.dropitx.site` fallback)
- `Auth/` — `FirebaseAuthService.swift` (defines `AuthServiceProtocol`), `AuthServiceError.swift`
- `Background/` — `HealthBackgroundScheduler.swift`, `NotificationManager.swift`
- `Chat/` — `ChatAvailability.swift`
- `CloudKit/` — `CloudKitManager.swift`, `CloudKitSchema.swift`, `CloudKitSyncEngine.swift`
- `Connectivity/` — `PhoneConnectivityManager.swift` (WCSession phone side)
- `Credits/` — `CreditService.swift`, `CreditServiceProtocol.swift`
- `DataManagement/` — `DataDeleter*.swift`, `CloudKitResetService.swift`, `LocalDataWipeService.swift`, `DataManagementUtilities.swift`
- `Firebase/` — `FirebaseBootstrap.swift`
- `HealthKit/` — `HealthKitManager.swift` + `+ActivityFetch/+RecoveryFetch/+SleepFetch` extensions, `SimulatorHealthKitService.swift`
- `LLM/` — `StressLLMService.swift`, `SSEParser.swift`, `ChatContextBuilder.swift`, `ChatQuickActions.swift`, `StressContextPayload.swift`, `LLMServiceProtocol.swift`
- `Preferences/` — `PreferencesService.swift`
- `Premium/` — `PaywallController.swift`
- `Protocols/` — the 4 core DI protocols: `StressAlgorithmServiceProtocol`, `HealthKitServiceProtocol`, `StressRepositoryProtocol`, `CloudKitServiceProtocol`
- `Repository/` — `StressRepository.swift`
- `StoreKit/` — `StoreKitService.swift`, `MockStoreKitService.swift`, `PremiumState.swift`, `StoreKitProductCatalog.swift`, `CreditPack.swift`, `StoreKitServiceEnvironment.swift`, `StoreKitServiceProtocol.swift`
- `Sync/` — `SyncManager.swift`, `ConflictResolver.swift`
- Root-level: `MockServices.swift`, `KeychainService.swift`, `AppearanceManager.swift`, `InsightGeneratorService.swift`, `CharacterAssetResolver.swift`, `CharacterIllustrationExporter.swift`

**`StressMonitor/StressMonitor/ViewModels/` (cross-tab VMs):**
- `StressViewModel.swift` (571 lines, main orchestration), `ChatViewModel.swift`, `CreditsViewModel.swift`, `PremiumViewModel.swift`, `AccountViewModel.swift` (Google sign-in linking), `HabitViewModel.swift`, `CharacterCollectionViewModel.swift`
- Feature-local VMs live beside their screens instead (see Views below)

**`StressMonitor/StressMonitor/Views/` (feature folders):**
- Each feature = folder with screens + `Components/` subfolder; many also hold their ViewModel
- Folders: `Action/`, `Breathing/` (+`BreathingViewModel`), `Characters/`, `Chat/` (`ChatBottomSheetView.swift`), `Components/` (shared: `Gauges/`, `TabBar/`, `HapticManager.swift`), `Dashboard/` (only `DashboardViewModel.swift` + `Components/` with 42 files), `DesignSystem/` (`Spacing/`/`Typography/`/`Shadows` + `Components/`), `History/` (+`HistoryViewModel`, `DetailViewModel`), `Journal/`, `MiniWalk/` (+`MiniWalkViewModel`), `Onboarding/` (5 view+VM pairs), `Premium/` (+`Components/`), `Settings/` (+`Components/`, `DataManagement/`, `SettingsViewModel`), `Shared/`, `Trends/` (+`TrendsViewModel`)
- Root files: `DashboardView.swift`, `MainTabView.swift`, `HistoryView.swift`

**`StressMonitor/StressMonitor/Models/`:**
- SwiftData `@Model`: `StressMeasurement.swift`, `Character/CharacterUnlock.swift`, `Habit.swift`
- Chat/session DTOs: `ChatMessage.swift`, `ChatSession.swift`, `ChatSessionMessage.swift`
- Backend DTOs: `CreditBalance.swift`, `ServerQuickAction.swift`, `UserPreferences.swift`, `SubscriptionPlan.swift`
- Algorithm value types: `StressContext.swift`, `StressResult.swift`, `FactorBreakdown.swift`, `FactorWeights.swift`, `PersonalBaseline.swift`, `BioAgeResult.swift`, `DataQualityInfo.swift`, `StressCategory.swift`
- HealthKit sample types: `HRVMeasurement.swift`, `HeartRateSample.swift`, `SleepData.swift`, `ActivityData.swift`, `RecoveryData.swift`
- Other: `MoodEntry.swift`, `WidgetSharedData.swift` (App Group snapshot + `WidgetPublisher`), `Base/ObservableModel.swift`

**`StressMonitor/StressMonitorWatch Watch App/` (watch target — path contains spaces):**
- Purpose: Standalone watch app with duplicated algorithm sources; NO backend/API/Auth/LLM/StoreKit code
- Layout mirrors the app: `Models/` (20 files incl. watch-only `CyclePhase.swift`, `Mood.swift`, `SeasonalTheme.swift`, `TierNamePreferences.swift`, `WatchFacePreferences.swift`, `WorkoutZone.swift`), `Services/` (duplicated `MultiFactorStressCalculator.swift`, `*StressFactor.swift`, protocol files, plus `WatchHealthKitManager.swift` (+`MultiFactorFetch`), `WatchConnectivityManager.swift`, `WatchSharedDataStore.swift`, `CloudKit/`), `ViewModels/` (`WatchStressViewModel`, `WatchCycleViewModel`, `WatchMoodViewModel`, `WatchHabitViewModel`, `WatchWorkoutViewModel`), `Views/`, `Theme/`, `Complications/` (`Providers/`, `Intents/`, `Views/`, `Services/`, `ComplicationBundle.swift`)
- Entry: `StressMonitorWatchApp.swift` → `ContentView.swift`

**`StressMonitor/StressMonitorWidget/` (widget target):**
- Purpose: WidgetKit widgets + Live Activity reading App Group data
- Key files: `StressMonitorWidgetBundle.swift`, `StressMonitorWidget.swift`, `StressMonitorWidgetControl.swift`, `StressMonitorWidgetLiveActivity.swift`, `WidgetStressCharacter.swift`, `Providers/StressWidgetProvider.swift`, `Models/WidgetDataProvider.swift`, `Views/{Small,Medium,Large,LockScreen}WidgetView.swift`, `Intents/UpdateWidgetIntent.swift`, `AppIntent.swift`
- `README.md` documents the target

**`StressMonitor/StressMonitorTests/` (test target):**
- Purpose: 36 unit-test files covering API client (5 suites), auth, StoreKit/IAP, credits, chat/SSE, persistence, ViewModels, widget data
- Key files: `StressMonitorProducts.storekit` (StoreKit config for IAP tests), `StoreKitTestSessionProvider.swift`, `SSEParserTests.swift`, `StressAPIClientTests.swift` + `StressAPIClient{Credits,Preferences,QuickActions,Sessions}Tests.swift`, `CreditPurchaseFlowTests.swift`, `FirebaseAuthServiceTests.swift`, `DataDeletionConsolidationTests.swift` (skips when `GSD_CI` env is set)
- Network-touching suites stub transport with `URLProtocol` subclasses; many suites use Swift Testing (`import Testing`)

**`docs/`:**
- Purpose: Product/engineering documentation
- Key files: `INDEX.md` (navigation hub), `ARCHITECTURE.md`, `CONFIGURATION.md`, `DEPLOYMENT.md`, `TESTING.md`, `code-standards*.md`, `design-guidelines*.md`, `GETTING-STARTED.md`
- Committed; treat README package table as stale (trust the pbxproj)

## Key File Locations

**Entry Points:**
- `StressMonitor/StressMonitor/StressMonitorApp.swift`: iOS `@main`, DI root, versioned SwiftData schema V1→V2
- `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`: watchOS `@main`
- `StressMonitor/StressMonitorWidget/StressMonitorWidgetBundle.swift`: widget entry
- `StressMonitor/StressMonitor/Views/Onboarding/OnboardingContainerView.swift`: first-screen gate (onboarding vs MainTabView)
- `StressMonitor/StressMonitor/Views/MainTabView.swift`: tab shell, paywall cover, nav restoration

**Configuration:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`: target membership (source of truth — 4 native targets: StressMonitor, StressMonitorTests, StressMonitorWidgetExtension, "StressMonitorWatch Watch App"; plus Firebase/GoogleSignIn package products)
- `StressMonitor/StressMonitor/Info.plist` + `StressMonitor.entitlements`: app config (base URL via `STRESS_API_BASE_URL`, CloudKit/HealthKit/App Group entitlements)
- `StressMonitor/StressMonitor/GoogleService-Info.plist`: Firebase (committed)
- `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`: backend base-URL resolution
- `.swiftlint.yml` (repo root, `included: StressMonitor/`), `.github/workflows/*.yml`, `fastlane/Fastfile`

**Core Logic:**
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift`: composite stress score
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`: main orchestration VM (571 lines)
- `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`: persistence + sync + widget publish (493 lines)
- `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`: backend client (129 lines + endpoint extensions)
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`: purchases + JWS server verification (529 lines)

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
- Either extend the matching `StressAPIClient+<Domain>.swift` or create `Services/API/StressAPIClient+<Domain>.swift`; build query-carrying URLs with `URLComponents`, never `appendingPathComponent` (it percent-encodes `?`)
- Test: matching `StressMonitorTests/StressAPIClient<Domain>Tests.swift` with a `URLProtocol` stub

**New widget surface:**
- View in `StressMonitor/StressMonitorWidget/Views/`, wire in `StressMonitorWidget.swift`/`StressMonitorWidgetBundle.swift`; shared data shape changes must update `Models/WidgetSharedData.swift` (app side) AND the duplicated widget copies

**New test:**
- `StressMonitor/StressMonitorTests/<Subject>Tests.swift`; IAP tests use `StressMonitorProducts.storekit`; environment-dependent tests should skip via `ProcessInfo.processInfo.environment["GSD_CI"]`

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

**`.github/`, `.claude/`, `.agents/`, `.codex/`, `.cursor/`, `.gemini/`, `.kiro/`, `.opencode/`, `.gitnexus/`:**
- Purpose: CI workflows, agent tooling configs, skills, rules, indexes
- Generated: Partly (indexes/caches)
- Committed: Varies — do not delete, do not treat as product code

**`docs/`:**
- Purpose: Human documentation; `INDEX.md` is the entry point
- Generated: No
- Committed: Yes

**Root-level generated artifacts (`repomix-output.xml`, `DOCUMENTATION_UPDATE_SUMMARY.txt`, `design-system-audit-prompt.md`):**
- Purpose: One-off tooling output / audit notes
- Generated: Yes
- Committed: Yes (safe to ignore; not product code)

**Orphaned source dirs (`StressMonitor/{Models,Services,Views}`, root `StressMonitorTests/`):**
- Purpose: Legacy pre-restructure locations; committed but absent from the pbxproj
- Generated: No
- Committed: Yes (do not edit — never builds; candidates for deletion in a cleanup phase)

---

*Structure analysis: 2026-08-29*
