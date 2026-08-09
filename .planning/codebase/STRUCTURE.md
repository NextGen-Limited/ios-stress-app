# Codebase Structure

**Analysis Date:** 2026-08-08

## Directory Layout

```
ios-stress-app/
├── StressMonitor/                     # Xcode project root
│   ├── StressMonitor.xcodeproj        # Project + shared schemes
│   ├── StressMonitor/                 # iPhone app target
│   ├── StressMonitorWatch Watch App/  # watchOS app target
│   ├── StressMonitorWidget/           # WidgetKit extension target
│   ├── StressMonitorTests/            # XCTest target
│   ├── Models/, Services/, Views/     # Legacy loose files (not in modern targets)
│   ├── build/                         # Build output (generated, not committed)
│   └── spm-cache/                     # SPM proxy/umbrella cache (generated)
├── docs/                              # Project documentation (source of truth)
├── docs-site/                         # Published docs site
├── design/                            # HTML design system + screen mockups
├── plans/                             # GSD plans and reports
├── .planning/                         # GSD planning state incl. codebase/ maps
├── scripts/                           # generate_app_icons.py, run-tests.py
├── ci_scripts/                        # Xcode Cloud hooks (ci_post_clone.sh, …)
├── fastlane/                          # Appfile, Fastfile, Matchfile
├── assets/, data/                     # Static and scratch data
├── .swiftlint.yml                     # Lint config
├── CLAUDE.md / AGENTS.md              # Agent instructions
└── README.md, CHANGELOG.md
```

### iPhone target layout

```
StressMonitor/StressMonitor/
├── StressMonitorApp.swift        # @main entry
├── Navigation/                   # AppRouter, Route, View+NavigationDestinations
├── Models/                       # @Model entities + value types (Base/, Character/)
├── ViewModels/                   # App-wide VMs (Stress, Chat, Premium, Habit, …)
├── Views/                        # Feature folders, each with Components/
│   ├── Dashboard/ History/ Trends/ Chat/ Characters/ Breathing/ MiniWalk/
│   ├── Onboarding/ Premium/ Settings/ Action/ Journal/ Shared/
│   ├── Components/               # Cross-feature components (Gauges/, TabBar/)
│   └── DesignSystem/             # Spacing, Typography, Shadows, Components/
├── Components/Character/         # Character illustrations + mood glyphs
├── Services/                     # Algorithm/ HealthKit/ Repository/ CloudKit/
│                                 # Sync/ LLM/ StoreKit/ Background/ Premium/
│                                 # DataManagement/ Connectivity/ Protocols/
├── Theme/                        # DesignTokens, Color+/Font+ extensions, Gradients
├── Utilities/                    # Accessibility, animation, fonts, misc modifiers
├── Fonts/ , Assets.xcassets      # Resources
```

## Directory Purposes

**`StressMonitor/StressMonitor/Services/Protocols/`:**
- Purpose: the dependency-injection seam for the iPhone target.
- Key files: `HealthKitServiceProtocol.swift`, `StressAlgorithmServiceProtocol.swift`, `StressRepositoryProtocol.swift`, `CloudKitServiceProtocol.swift`. (`LLMServiceProtocol.swift` and `StoreKitServiceProtocol.swift` live beside their implementations in `Services/LLM/` and `Services/StoreKit/`.)

**`StressMonitor/StressMonitor/Services/Algorithm/`:**
- Purpose: stress scoring pipeline.
- Key files: `StressFactor.swift` (protocol + `FactorResult`), the five factor implementations, `MultiFactorStressCalculator.swift`, `StressCalculator.swift`, `BaselineCalculator.swift`, `FactorCalibrator.swift`, `BioAgeCalculator.swift`.

**`StressMonitor/StressMonitor/Views/<Feature>/`:**
- Purpose: one folder per screen area; screen file at the folder root, private subviews in `Components/`, feature-local view model beside the screen (e.g. `Trends/TrendsViewModel.swift`).

**`StressMonitor/StressMonitorWatch Watch App/`:**
- Purpose: independent watchOS target mirroring the phone structure (`Models/`, `Services/`, `ViewModels/`, `Views/`, `Theme/`) plus `Complications/` (Intents/, Providers/, Services/, Views/).
- Note: algorithm and model files are duplicated here, not shared.

**`StressMonitor/StressMonitorWidget/`:**
- Purpose: WidgetKit extension — `StressMonitorWidgetBundle.swift`, `Providers/StressWidgetProvider.swift`, `Models/WidgetDataProvider.swift`, `Intents/`, `Views/` (Small/Medium/Large/LockScreen).

**`StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/` (project-root level):**
- Purpose: older loose Swift files (`HRVAnalyzer.swift`, `StressPredictor.swift`, `MorningReadinessService.swift`, `ActivityManager.swift`, `MergeBenchmark.swift`, `UserSettings.swift`, `StressReading.swift`) sitting outside the four target folders. Do not add new code here.

**`StressMonitor/build/`, `StressMonitor/spm-cache/`:**
- Purpose: generated build artifacts and the SPM proxy/umbrella cache. Generated: yes. Committed: no (git-ignored).

## Key File Locations

**Entry Points:**
- `StressMonitor/StressMonitor/StressMonitorApp.swift`: iPhone `@main`, schema/migration, DI roots.
- `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`: watchOS `@main`.
- `StressMonitor/StressMonitorWidget/StressMonitorWidgetBundle.swift`: widget bundle `@main`.
- `StressMonitor/StressMonitorWatch Watch App/Complications/ComplicationBundle.swift`: complication bundle.

**Navigation:**
- `StressMonitor/StressMonitor/Navigation/AppRouter.swift`, `Route.swift`, `View+NavigationDestinations.swift`
- `StressMonitor/StressMonitor/Views/MainTabView.swift`

**Configuration:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`: targets, capabilities, build settings.
- `StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/`: `StressMonitor.xcscheme`, `StressMonitorWatch Watch App.xcscheme`.
- `.swiftlint.yml`, `fastlane/Fastfile`, `ci_scripts/ci_post_clone.sh`.

**Core Logic:**
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift`
- `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
- `StressMonitor/StressMonitor/Services/Sync/SyncManager.swift`
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift`
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`

**Testing:**
- `StressMonitor/StressMonitorTests/` — `BioAgeCalculatorTests.swift`, `CharacterAssetResolverTests.swift`, `CharacterCollectionViewModelTests.swift`, `PremiumViewModelTests.swift`, `StoreKitProductCatalogTests.swift`.
- `scripts/run-tests.py` for CLI runs.

**Docs:**
- `docs/system-architecture.md`, `docs/codebase-summary.md`, `docs/code-standards.md`, `docs/project-roadmap.md`, `docs/INDEX.md`.

## Naming Conventions

**Files:**
- One primary type per file, filename equals the type: `StressViewModel.swift`, `MultiFactorStressCalculator.swift`.
- PascalCase for all Swift sources.
- Protocols end in `Protocol`: `HealthKitServiceProtocol.swift`.
- Extensions use `Type+Feature.swift`: `HealthKitManager+SleepFetch.swift`, `Color+Wellness.swift`, `View+NavigationDestinations.swift`.
- Views end in `View`, view models in `ViewModel`, services in `Service`/`Manager`, mocks prefixed `Mock`/`Simulator`.
- Watch-target types are prefixed `Watch`: `WatchStressViewModel.swift`, `WatchHealthKitManager.swift`.
- Tests: `<TypeUnderTest>Tests.swift`.

**Directories:**
- PascalCase feature folders under `Views/`, each optionally containing `Components/`.
- Service folders named after the integration (`HealthKit/`, `CloudKit/`, `StoreKit/`, `LLM/`).
- Markdown docs and design assets use kebab-case: `docs/system-architecture-core.md`, `design/design-system.html`.

## Where to Add New Code

**New screen:**
- Screen: `StressMonitor/StressMonitor/Views/<Feature>/<Name>View.swift`
- Subviews: `StressMonitor/StressMonitor/Views/<Feature>/Components/`
- View model: `StressMonitor/StressMonitor/Views/<Feature>/<Name>ViewModel.swift` (or `ViewModels/` if reused across features)
- Register a case in `Navigation/Route.swift` and resolve it in `Navigation/View+NavigationDestinations.swift`.

**New service:**
- Implementation: `StressMonitor/StressMonitor/Services/<Domain>/<Name>Service.swift`
- Protocol: `StressMonitor/StressMonitor/Services/Protocols/<Name>ServiceProtocol.swift` (or beside the implementation, matching `LLM/`/`StoreKit/`)
- Test double: extend `StressMonitor/StressMonitor/Services/MockServices.swift`.

**New stress factor:**
- `StressMonitor/StressMonitor/Services/Algorithm/<Name>StressFactor.swift`, add to the default array in `MultiFactorStressCalculator.init`, extend `FactorWeights.swift` and `FactorBreakdown.swift`, and mirror all of it in `StressMonitorWatch Watch App/Services/`.

**New persisted model:**
- `StressMonitor/StressMonitor/Models/<Name>.swift` with `@Model`, then add a new `AppSchemaVN` + `MigrationStage` in `StressMonitor/StressMonitor/StressMonitorApp.swift`.

**Shared design tokens / colors / typography:**
- `StressMonitor/StressMonitor/Theme/` (phone) and `StressMonitorWatch Watch App/Theme/` (watch).

**Reusable UI primitives:**
- `StressMonitor/StressMonitor/Views/DesignSystem/Components/`.

**Tests:**
- `StressMonitor/StressMonitorTests/<TypeUnderTest>Tests.swift`.

## Special Directories

**`StressMonitor/build/`:**
- Purpose: xcodebuild output, `.xcresult` bundles, dSYMs. Generated: Yes. Committed: No.

**`StressMonitor/spm-cache/`:**
- Purpose: SPM proxy and umbrella packages used to cache third-party dependencies. Generated: Yes. Committed: No (artifacts git-ignored).

**`.planning/`:**
- Purpose: GSD workflow state, including these codebase maps under `.planning/codebase/`. Generated: Yes (by GSD commands). Committed: Yes.

**`docs-site/`:**
- Purpose: rendered documentation site generated from `docs/`. Committed: Yes.

**`design/`:**
- Purpose: HTML design-system references and screen mockups used as UI source of truth. Generated: No. Committed: Yes.

---

*Structure analysis: 2026-08-08*
