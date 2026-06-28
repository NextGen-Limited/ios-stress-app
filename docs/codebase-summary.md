# Codebase Summary

**Total Files:** ~720+ files (including 389 Swift files)
**Total LOC:** ~41,000+
**Architecture:** MVVM + Protocol-Oriented Design
**Last Updated:** June 27, 2026

---

## High-Level Structure

```
ios-stress-app/
├── StressMonitor/                      # Xcode project root
│   ├── StressMonitor/                  # iOS App (298 files)
│   │   ├── Models/                     # Data models (18 files)
│   │   ├── Services/                   # Business logic (46 files)
│   │   ├── ViewModels/                 # State management (4+ files)
│   │   ├── Views/                      # SwiftUI screens (~100 files)
│   │   ├── Theme/                      # Design tokens (5 files)
│   │   ├── Utilities/                  # Helpers (9 files)
│   │   └── Components/                 # Shared UI components (4 files)
│   ├── StressMonitorWatch Watch App/   # watchOS App
│   ├── StressMonitorWidget/            # Home Screen Widgets
│   ├── StressMonitorTests/             # Unit Tests
│   └── StressMonitorUITests/           # UI Tests
├── .github/workflows/ci.yml            # GitHub Actions CI pipeline
├── scripts/run-tests.py                # Python test runner
└── docs/                               # Project documentation
```

---

## iOS App Structure (298 Swift files)

### Models (23 files, ~1,300 LOC)
Core data structures for health metrics, stress calculations, and character system.

| File | Purpose |
|------|---------|
| `StressMeasurement.swift` | @Model SwiftData entity for measurements |
| `StressResult.swift` | Stress calculation output |
| `StressCategory.swift` | Enum: Relaxed, Mild, Moderate, High, Severe (5 levels, WCAG dual-coding) |
| `HRVMeasurement.swift` | Heart Rate Variability data |
| `HeartRateSample.swift` | Individual HR reading |
| `PersonalBaseline.swift` | User's physiological baseline |
| `StressBuddyMood.swift` | Character mood states |
| `ChatMessage.swift` | Chat message model |
| `ActivityData.swift` | Activity metrics for multi-factor algorithm |
| `SleepData.swift` | Sleep quality data |
| `RecoveryData.swift` | Recovery status data |
| `DataQualityInfo.swift` | Data quality assessment |
| `FactorBreakdown.swift` | Per-factor stress breakdown |
| `FactorWeights.swift` | Dynamic weight configuration |
| `StressContext.swift` | Aggregated health data input |
| `WidgetSharedData.swift` | `ComplicationEntry` + `WidgetEntry` widget timeline data |
| `ExportModels.swift` | CSV/JSON export structures |
| `ObservableModel.swift` | Base protocol for observable models |
| `Base/ObservableModel.swift` | Base observable model class |
| `CharacterCreature.swift` | Character definition (species, element) |
| `CharacterUnlock.swift` | Character unlock state + evolution progress |
| `BioAgeResult.swift` | Biological age calculation output with trend (NEW: Jun 17) |

### Services (60+ files, ~9,000 LOC)
Business logic and system integrations.

#### Algorithm Services (11 files)
- `StressCalculator.swift` - Main stress calculation orchestration
- `MultiFactorStressCalculator.swift` - Advanced multi-factor stress analysis
- `StressFactor.swift` - Base stress factor protocol
- `HeartRateStressFactor.swift` - Heart rate-based stress analysis
- `HRVStressFactor.swift` - HRV-based stress calculation
- `SleepStressFactor.swift` - Sleep quality impact on stress
- `ActivityStressFactor.swift` - Physical activity stress correlation
- `RecoveryStressFactor.swift` - Recovery capacity assessment
- `FactorCalibrator.swift` - Stress factor weight calibration
- `BaselineCalculator.swift` - Individual baseline computation
- `BioAgeCalculator.swift` - Biological age estimation from HRV and health metrics (NEW: Jun 17)

#### HealthKit Services (5 files)
- `HealthKitManager.swift` - Core HealthKit integration
- `ActivityDataFetcher.swift` - Activity data retrieval
- `SleepDataFetcher.swift` - Sleep data collection  
- `RecoveryDataFetcher.swift` - Recovery metrics integration
- `SimulatorHealthKitService.swift` - Mock data for development

#### CloudKit Services (3 files)
- `CloudKitManager.swift` - CloudKit synchronization core
- `CloudKitSyncEngine.swift` - Sync conflict resolution
- `CloudKitSchema.swift` - CloudKit data model definitions

#### LLM Services (7 files)
- `LLMServiceProtocol.swift` - AI service abstraction
- `SupabaseLLMService.swift` - Cloud LLM via Supabase Edge Functions with SSE streaming
- `ChatContextBuilder.swift` - Conversation context management
- `ChatQuickActions.swift` - Quick response suggestions
- `SSEParser.swift` - Server-Sent Events streaming parser
- `StressContextPayload.swift` - Health context for LLM system prompt
- `LLMServiceError.swift` - Typed error handling

#### Data Management Services (9 files)
- `DataManagementService.swift` - Central data management
- `DataExporter.swift` - Data export functionality
- `DataDeleter.swift` - Data cleanup and management
- `CSVGenerator.swift` - CSV file generation
- `JSONGenerator.swift` - JSON export formatting
- `CloudKitResetService.swift` - CloudKit data reset utilities
- `LocalDataWipeService.swift` - Local data cleanup
- `DataManagementUtilities.swift` - Data management helpers
- `CharacterIllustrationExporter.swift` - Renders character × evolution × mood combinations to PNG + ZIP (NEW: In-progress Jun 17)

#### Background Services (2 files)
- `HealthBackgroundScheduler.swift` - Background health data collection
- `NotificationManager.swift` - Local notification system

#### Sync Services (2 files)
- `SyncManager.swift` - Data synchronization coordination
- `ConflictResolver.swift` - Sync conflict resolution

#### StoreKit Services (5 files)
- `StoreKitService.swift` - Real StoreKit 2 implementation with App Store product fetching (Jun 12, 2026)
- `StoreKitServiceProtocol.swift` - StoreKit abstraction layer
- `PremiumState.swift` - Centralized premium state management singleton
- `StoreKitProductCatalog.swift` - Product ID resolution from Info.plist
- `MockStoreKitService.swift` - Mock implementation for testing only

#### Theme Services (1 file)
- `AppearanceManager.swift` - Dark mode preference management (@Observable singleton, Light/Dark/System modes, UserDefaults persistence) (lives in `Services/`; design tokens live in `Theme/`)

#### Character Services (2 files)
- `CharacterAssetResolver.swift` - Routes character IDs to design-exported SVG assets; mood drives ambient animation via the `StressBuddyIllustration` layer
- `CharacterIllustrationExporter.swift` - @MainActor service rendering character × evolution × mood combinations to PNG + ZIP (illustration export pipeline)

#### Additional Services
- `InsightGeneratorService.swift` - AI-powered insights
- `MockServices.swift` - Development mock data services

### ViewModels (11 files)
State management layer:

- `StressViewModel.swift` - Core stress tracking state
- `ChatViewModel.swift` - AI chat with streaming responses
- `DashboardViewModel.swift` - Dashboard data aggregation
- `TrendViewModel.swift` - Historical trend analysis
- `HistoryViewModel.swift` - Historical data browsing
- `SettingsViewModel.swift` - App configuration state (NEW: Jun 2026, manages profile, notifications, theme, iCloud sync)
- `DataManagementViewModel.swift` - Data management operations
- `BreathingViewModel.swift` - Breathing exercise state
- `MiniWalkViewModel.swift` - Mini Walk exercise state
- `CharacterCollectionViewModel.swift` - Character collection state & unlock logic
- `PremiumViewModel.swift` - Subscription management & StoreKit state

### Views (150+ files)
SwiftUI user interface components:

#### Main Navigation Structure (3 tabs + Settings screen)
The app uses a **3-tab navigation** architecture (updated Jun 17, 2026):
1. **Home** (`DashboardView.swift`) - Main stress monitoring dashboard
2. **Action** (`ActionView.swift`) - Quick stress relief exercises + Ripple AI Coach
3. **Trends** (`TrendsView.swift`) - Historical stress visualization

Secondary (non-tab):
- **Settings** (`SettingsView.swift`) - App settings, accessed via chevron from Dashboard
- **Characters** - Collection accessible via CharactersCard inside Settings (not a tab)
- **Breathing** / **Mini Walk** / **Chat** - Launched from Action tab quick-actions

#### Feature Views
- `Dashboard/` (27 files) - Dashboard components, cards, metrics, insights, BioAgeCardView (NEW: Jun 17)
- `Trends/` (12 files) - Trend charts, heatmaps, statistics with Ripple character commentary
- `Breathing/` (6 files) - Breathing exercise flow
- `Characters/` (9 files) - Character collection, detail, picker, celebration, CharacterIllustrationExportView (NEW: In-progress Jun 17)
- `Settings/` (14 files) - Settings screens, data management, ProfileCard, appearance picker, dark mode toggle, delete data CTA
- `History/` (7 files) - Historical data browsing
- `Onboarding/` (10 files) - Onboarding flow with HealthKit permission integration
- `Premium/` (6 files) - IAP Premium subscription screen
- `Chat/` - AI chat interface components
- `Journal/` - Journaling features
- `MiniWalk/` - Mini Walk exercise with circular timer
- `Action/` - Quick stress relief interface with Ripple AI Coach, Bento grid, dark-canvas theme

### Theme (8 files)
Design system and styling — the visual source of truth for the entire app:

- `AppIconSystem.swift` - **Centralized icon system** enum mapping the design spec to SF Symbols; single source of truth for every icon (37+ files migrated to this in PR #44). Categories: Tab (4), Nav (3), Action (6), Metric (8), Setting (17), System (11). Also defines `MoodFaceIcon` (5-level stress scale) + `SettingsIconView` + `MoodFaceView`
- `CharacterAssetCatalog.swift` - Bridges design-exported character SVGs to SwiftUI `Image` for **static** contexts (list avatars, grid tiles, picker sheets, tab icons, locked placeholders). Bundled characters: ripple, blossom, ember, zephyr, lumi (+ ripple-hero)
- `MoodFaceAssetCatalog.swift` - Bridges mood-face SVGs (mood-relaxed…mood-severe) to SwiftUI `Image`
- `Color+Wellness.swift` - App-specific color definitions
- `Color+Extensions.swift` - Color system extensions (incl. `Color(hex:)`, light/dark dual-mode)
- `DesignTokens.swift` - Core design tokens
- `Font+WellnessType.swift` - Typography system (SF Pro family)
- `Gradients.swift` - Gradient definitions
- `HomeCharacterDesignTokens.swift` - Dashboard character sizing/positioning tokens

### Components (15+ files)
Reusable UI components:

#### Character Components
- `StressBuddyIllustration.swift` - AI companion visual components
- `StressCharacterCard.swift` - Character representation
- `CharacterAnimationModifier.swift` - Animation utilities
- `CharacterGridCard.swift` - Character grid card for collection
- `EvolutionDots.swift` - Evolution stage indicator
- `EvolutionTimelineRow.swift` - Evolution timeline visualization
- `MoodPreviewButton.swift` - Mood preview in character detail
- `StressBuddyIllustration.swift` (Character variant) - SVG-based character render

#### General Components
- `DecorativeTriangleView.swift` - Decorative UI elements
- `TabBar/TabItem.swift` - Tab bar item definition
- `TabBar/AnimatedTabButtons.swift` - Animated tab button components
- `TabBar/TabBarScrollState.swift` - Tab bar scroll state management

### Utilities (9 files)
Helper functions and extensions:

- `Animation+Wellness.swift` - Animation utilities
- `AnimationPresets.swift` - Pre-defined animations
- `AccessibilityModifiers.swift` - Accessibility enhancements
- `DynamicTypeScaling.swift` - Dynamic type scaling
- `FontBlaster.swift` - Font loading utilities
- `HighContrastModifier.swift` - High contrast support
- `PatternOverlay.swift` - Visual pattern utilities
- `ColorBlindnessSimulator.swift` - Accessibility testing
- `DocsURL.swift` - Documentation references

### Protocols (5 files)
Interface definitions:

- `LLMServiceProtocol.swift` - AI service contract
- `CloudKitServiceProtocol.swift` - CloudKit abstraction
- `HealthKitServiceProtocol.swift` - HealthKit access contract
- `StressRepositoryProtocol.swift` - Data persistence contract
- `StressAlgorithmServiceProtocol.swift` - Stress calculation contract

---

## Navigation Structure

### 3-Tab Navigation Architecture (Updated June 17, 2026)
The app uses a 3-tab navigation structure:

1. **Home** (`DashboardView.swift`) - Main stress monitoring dashboard with current stress levels, recent trends, biological age card, and insights
2. **Action** (`ActionView.swift`) - Quick stress relief with breathing exercises, Ripple AI Coach, and bento grid of quick actions
3. **Trend** (`TrendsView.swift`) - Historical stress visualization, charts, heatmaps, and pattern analysis

### Secondary Navigation
- **Settings** (accessed via button/chevron from Dashboard, not a tab) - App settings, data management, preferences, character collection access via CharactersCard
- Characters now accessible via **CharactersCard** component in Settings screen (previously Tab 4)
- Journal and History accessible via navigation within Dashboard and Trends tabs
- Data export/delete accessible through Settings

---

## Tech Stack

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (no UIKit dependencies)
- **Architecture**: MVVM with @Observable macro (iOS 17+)
- **Persistence**: SwiftData (iOS 17+ native)
- **Health Data**: HealthKit (read-only access)
- **Cloud Sync**: CloudKit (end-to-end encrypted)
- **Background Tasks**: BGAppRefreshTask
- **Widgets**: WidgetKit for watchOS complications

### AI Integration
- **Primary**: SupabaseLLMService with SSE streaming via Supabase Edge Functions (production cloud service, fully configured)
- **Architecture**: Server-Sent Events for real-time streaming
- **Features**: Stress insights, breathing guidance, conversation
- **Configuration**: SupabaseConfig (URL + anonKey) for cloud endpoints

### Dependencies
- **8 resolved SPM packages** (2 direct, 6 transitive):
  - Direct: `Chat` (ExyteChat — AI chat UI), `SwiftUICharts` (trend charts)
  - Transitive (via Chat): `Kingfisher`, `Giphy-ios-sdk`, `MediaPicker`, `ActivityIndicatorView`, `AnchoredPopup`, `LibWebP-Xcode`
  - *Note: Moya, Alamofire, ReactiveSwift, RxSwift, and AnimatedTabBar were removed in earlier refactors and are no longer dependencies. The tab bar is now a custom SwiftUI implementation (`Components/TabBar/`).*
- **Privacy-first design** - All data processed locally when possible
- **Modular architecture** - Protocol-based dependency injection

---

## Key Features

### Stress Monitoring
- Multi-factor stress calculation (5 factors: HRV, Heart Rate, Sleep, Activity, Recovery with dynamic weight normalization)
- Real-time stress level assessment with confidence scoring
- Personalized baseline calibration
- Stress categorization: **5 levels** — Relaxed, Mild, Moderate, High, Severe (`StressCategory` enum, WCAG dual-coding colors)

### AI-Powered Insights
- SupabaseLLMService with SSE streaming via Edge Functions
- Contextual stress analysis and recommendations
- Breathing exercise guidance
- Conversational stress management

### Data Management
- Local data persistence with SwiftData
- CloudKit synchronization for seamless cross-device experience
- Data export functionality (CSV, JSON)
- Privacy-focused data handling

### User Experience
- Clean, accessible SwiftUI interface
- Dynamic Type support for accessibility
- Haptic feedback for stress level changes
- Demo mode for development/testing

---

## Recent Updates (June 2026)

22. **AppIconSystem — Centralized Icon System** (PR #44, NEW: Jun 25) - Single source of truth for every SF Symbol in the app (`Theme/AppIconSystem.swift`, 321 LOC). 7 categories (Tab, Nav, Action, Metric, Setting, System, MoodFace). **37 files / 59 references migrated** from scattered SF Symbol strings to `AppIconSystem.Icon.x.sfSymbol`. Pairs with bundled character/mood SVG assets in the Asset Catalog.
21. **Character Views → SVG Assets** (PR #45, NEW: Jun 25) - Character views migrated from procedural SwiftUI drawing to design-exported SVG assets via `CharacterAssetResolver` + `CharacterAssetCatalog`. 16 view files updated to render `Image(assetName)` instead of procedural shapes. Mood-reactivity preserved via the `StressBuddyIllustration` animation layer.
20. **AppearanceManager** - Dark mode preference manager (NEW: Jun 13) - @Observable singleton, Light/Dark/System modes, UserDefaults persistence
19. **Settings Redesign** - Ripple UI card-based architecture (NEW: Jun 13) - 13 card components, ProfileCard with appearance picker
18. **ProfileCard** - Appearance toggle (Light/Dark/System), Delete All Data button (NEW: Jun 13)
17. **Trends Redesign** - Ripple character system (NEW: Jun 13) - MascotSpeechBubbleView, HorizontalWeekCalendarView, WeeklyHeatmapView, PatternInsightsSection
16. **ActionView Redesign** - Ripple dark-canvas theme (NEW: Jun 13) - Mood Calendar, Daily Focus Hero, Ripple AI Coach, Bento Health Grid, Quick Actions
15. **OnboardingFlow** - HealthKit permission integration (NEW: Jun 13) - 3-screen TabView (Welcome → HealthKit Sync → Success)
14. **WatchOS Character-Reactive** - Stress tier emoji display (NEW: Jun 13) - 5 stress tiers mapped to emoji + color, NO numeric scores
13. **WidgetKit Extensions** - Live Activity + ControlCenter launcher (NEW: Jun 13) - SmallWidget, MediumWidget, LargeWidget, no numeric scores, character emoji only
12. **Stress History Timeline** - Activity correlation with stress data
11. **Guided Breathing with Biofeedback** - Enhanced breathing exercises with real-time feedback
10. **Apple Watch Complications** - Live stress metrics on watch face
9. **Mini Walk Exercise** - Walking exercise screen with circular timer
8. **Real StoreKit 2 Premium** - Real App Store product fetching + transaction monitoring (PR #19, Jun 12)
7. **SupabaseLLMService** - Production cloud service with SSE streaming (replaces CloudLLMService)
6. **3-Tab Navigation** - Home/Action/Trend structure with Settings moved to non-tab screen (Jun 17)
5. **Character Collection UI** - 5 elemental characters with evolution system, unlock types (free/premium/streak-gated), persistent storage, 6 character SVGs + 5 mood-face SVGs (single exported SVG per character; mood-reactivity via StressBuddyIllustration animation layer)
4. **Biological Age Calculator** - `BioAgeCalculator` with estimatedAge, chronologicalAge, difference, BioAgeTrend; 7-day min data req (NEW: Jun 17)
3. **BioAgeCardView** - Dark glass card on Dashboard showing bio age diff + character expression, color-coded (NEW: Jun 17)
2. **Watch Face Personalization** - Background style selection, synced via WatchConnectivityManager (NEW: Jun 17)
1. **Weekly Billing Option** - `SubscriptionPeriod.weekly` added to premium tier alongside monthly/annual (NEW: Jun 17)

## New Files Added (IAP Premium)
- **PremiumState** - Centralized premium state management singleton
- **StoreKitServiceProtocol** - StoreKit abstraction layer with mock implementation
- **IAPPremiumView** - Main subscription screen with plan selection
- **Premium/Components** - Subscription card, CTA button, utility row components

---

## Implementation Standards

### Architecture Patterns
- **MVVM** with clear separation of concerns
- **Protocol-oriented design** for testability and flexibility
- **Dependency injection** for loose coupling
- **Async/await** throughout for modern concurrency

### Code Quality
- Swift 5.9+ features and best practices
- Comprehensive error handling and graceful degradation
- Accessibility-first design principles
- Consistent naming conventions and code structure

### Testing Strategy
- Unit tests for core algorithms
- Integration tests for service layers
- UI testing for critical user flows
- Demo mode for comprehensive testing scenarios

---

## Character System (NEW - June 2026)

### Overview
- **5 elemental characters**: Ripple (Water/free), Blossom (Earth/free), Ember (Fire/premium), Zephyr (Air/premium), Lumi (Moon/streak-gated)
- **Evolution system**: 3 stages (Droplet → Ripple → Tidal) triggered by streaks, sessions, resilience scores
- **Unlock types**: Free, Premium (StoreKit-gated), Streak-gated (30-day)
- **6 character SVGs**: 5 characters (ripple, blossom, ember, zephyr, lumi) + ripple-hero (larger detail view)
- **5 mood-face SVGs**: mood-relaxed, mood-mild, mood-moderate, mood-high, mood-severe (WCAG dual-coding colors)
- **Services**: `CharacterAssetResolver` (routes character IDs to exported SVGs; mood drives ambient animation via StressBuddyIllustration), `CharacterCollectionViewModel` (state management)
- **Asset bridges**: `CharacterAssetCatalog` (static image contexts), `MoodFaceAssetCatalog` (mood-face SVGs)
- **Models**: `CharacterCreature` (definition), `CharacterUnlock` (persistent state in SwiftData)
- **Views**: CharacterCollectionView (grid), CharacterDetailView, CharacterPickerSheet, EvolutionCelebrationView
- **Element colors**: Water blue, Earth green, Fire orange, Air purple, Moon indigo
- **Icon system**: `AppIconSystem` enum (single source of truth for all SF Symbol mappings; 37 files adopt this)
- **Mood taxonomy**: `MoodFaceIcon` enum (5-level stress scale with SF Symbols + WCAG colors: relaxed #34C759, mild #007AFF, moderate #FFD60A, high #FF9500, severe #FF3B30)

### Asset Structure
Design source exports live in `design/exports/characters/` and `design/exports/mood-faces/` (generated from `design/characters-export.html` and `design/icon-system.html`). The legacy `{character}_{evolution}_{mood}.svg` naming is deprecated and retained only for the illustration export pipeline. See `/docs/design/ASSET_NAMING.md` for details.

### Icon System (`AppIconSystem`)
- **Single source of truth** for every SF Symbol in the app (`Theme/AppIconSystem.swift`)
- **7 categories**: Tab (4 tabs, active/inactive variants), Nav (3), Action (6 exercises), Metric (8 factor icons), Setting (17 rows), System (11 semantic icons), MoodFace (5-level stress scale)
- **Migration** (PR #44): 37 files / 59 references migrated from scattered SF Symbol string literals to `AppIconSystem.Icon.x.sfSymbol`
- **WCAG dual-coding**: `MoodFaceIcon` enum always pairs face shape with its stress color (relaxed #34C759, mild #007AFF, moderate #FFD60A, high #FF9500, severe #FF3B30)
- **Helper views**: `SettingsIconView` (28×28 tinted rounded square), `MoodFaceView` (colored circle + white face)

---

## Key Metrics

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 389 |
| **Total LOC** | ~41,000+ |
| **iOS App Files** | 298 |
| **watchOS App Files** | 52 |
| **Widget Files** | 13 |
| **Test Files** | 5 |
| **External Dependencies** | 8 SPM packages (2 direct) |
| **Average File Size** | <200 LOC |
| **Font** | SF Pro (Foundation design system) |
| **Character Assets** | 11 SVG files (6 characters + 5 mood-faces) |
| **Icon System** | `AppIconSystem` — 7 categories, 37+ files migrated |

---

**Last Updated:** June 27, 2026
**Maintainers:** Phuong Doan