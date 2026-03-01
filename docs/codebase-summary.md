# Codebase Summary

**Total Files:** 206 Swift files
**Total Tokens:** ~205,000
**Architecture:** MVVM + Protocol-Oriented Design
**Last Updated:** February 28, 2026

---

## High-Level Structure

```
ios-stress-app/
├── StressMonitor/                      # Xcode project root
│   ├── StressMonitor/                  # iOS App (136 files)
│   │   ├── Components/                 # Shared UI components (7 files)
│   │   ├── Models/                     # Data models (10 files)
│   │   ├── Services/                   # Business logic (27 files)
│   │   ├── Theme/                      # Design tokens (5 files)
│   │   ├── Utilities/                  # Helpers (7 files)
│   │   ├── ViewModels/                 # State management (2 files)
│   │   └── Views/                      # SwiftUI screens (77 files)
│   ├── StressMonitorWatch Watch App/   # watchOS App (29 files)
│   ├── StressMonitorWidget/            # Home Screen Widgets (7 files)
│   ├── StressMonitorTests/             # Unit Tests (27 files)
│   └── StressMonitorUITests/           # UI Tests
└── docs/                               # Project documentation
```

---

## iOS App Structure (136 files, ~14,500 LOC)

### Components (7 files, ~606 LOC)
Character components using SVG assets with SwiftUI animations.

| File | LOC | Purpose |
|------|-----|---------|
| `Components/Character/StressBuddyIllustration.swift` | 66 | SVG-based character loader with 5 mood expressions |
| `Components/Character/StressCharacterCard.swift` | 270 | Character card with ZStack layout |
| `Components/Character/CharacterAnimationModifier.swift` | 161 | Mood-specific animations (breathing, fidget, shake, dizzy) |
| `Components/Character/DecorativeTriangleView.swift` | 109 | Decorative triangle element for card corners |

**SVG Assets (refactored Feb 2026):**
- `CharacterCalm.svg` - Relaxed expression
- `CharacterConcerned.svg` - Moderate concern
- `CharacterOverwhelmed.svg` - High stress
- `CharacterSleeping.svg` - Rest state
- `CharacterWorried.svg` - Mild stress

**Key Features:**
- 5 mood expressions via SVG assets (replaced 549 LOC of custom drawing)
- Reduce Motion support throughout
- Accessibility labels and VoiceOver support

### Models (9 files, ~485 LOC)
Data structures for health metrics and stress calculations.

| File | LOC | Purpose |
|------|-----|---------|
| `Models/Base/ObservableModel.swift` | 12 | Base protocol for observable models |
| `Models/StressMeasurement.swift` | 45 | @Model SwiftData entity for measurements |
| `Models/StressResult.swift` | 28 | Stress calculation output |
| `Models/StressCategory.swift` | 35 | Enum: Relaxed, Mild, Moderate, High |
| `Models/HRVMeasurement.swift` | 32 | Heart Rate Variability data |
| `Models/HeartRateSample.swift` | 28 | Individual HR reading |
| `Models/PersonalBaseline.swift` | 48 | User's physiological baseline |
| `Models/StressBuddyMood.swift` | 38 | Character mood states |
| `Models/ExportModels.swift` | 279 | CSV/JSON export structures |

### Services (27 files, ~4,861 LOC)
Business logic, HealthKit integration, data persistence, cloud sync.

#### HealthKit Service (1 file, 156 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/HealthKit/HealthKitManager.swift` | 156 | HealthKit authorization + data fetching |

**Key Methods:**
- `requestAuthorization()` - HealthKit permission flow
- `fetchLatestHRV()` - Get latest HRV measurement
- `fetchHeartRate(samples:)` - Get HR samples

#### Insight Service (1 file, 83 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/InsightGeneratorService.swift` | 83 | AI-powered insight generation |

**Key Methods:**
- `generateInsight(stress:baseline:history:)` - Generate personalized insights from patterns

#### Algorithm Service (2 files, 312 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/Algorithm/StressCalculator.swift` | 187 | Core stress algorithm (HRV + HR) |
| `Services/Algorithm/BaselineCalculator.swift` | 125 | Personal baseline computation |

**Key Methods:**
- `StressCalculator.calculateStress(hrv:, heartRate:)` - Main algorithm
- `BaselineCalculator.computeBaseline(measurements:)` - 30-day baseline

#### Repository Service (1 file, 445 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/Repository/StressRepository.swift` | 445 | SwiftData persistence layer |

**Key Methods:**
- `save(_:)` - Persist measurement
- `fetchRecent(limit:)` - Query recent data
- `getBaseline()` - Retrieve user baseline

#### CloudKit Services (3 files, 869 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/CloudKit/CloudKitManager.swift` | 294 | CloudKit operations (CRUD) |
| `Services/CloudKit/CloudKitSchema.swift` | 198 | Record type definitions |
| `Services/CloudKit/CloudKitSyncEngine.swift` | 377 | Sync orchestration + conflict resolution |

#### DataManagement Services (9 files, 2,789 LOC)
Large module for export, delete, and CloudKit reset operations.

| File | LOC | Purpose |
|------|-----|---------|
| `Services/DataManagement/DataManagementService.swift` | 464 | Orchestrator for all data operations |
| `Services/DataManagement/CloudKitResetService.swift` | 539 | Wipe CloudKit container |
| `Services/DataManagement/DataDeleterService.swift` | 358 | Delete local data by range/category |
| `Services/DataManagement/LocalDataWipeService.swift` | 326 | Full local wipe |
| `Services/DataManagement/CSVGenerator.swift` | 187 | CSV export format |
| `Services/DataManagement/JSONGenerator.swift` | 249 | JSON export format |
| `Services/DataManagement/DataExporter.swift` | 156 | Orchestrate export |
| `Services/DataManagement/DataDeleter.swift` | 134 | Orchestrate delete |
| `Services/DataManagement/DataManagementUtilities.swift` | 76 | Shared utilities |

#### Supporting Services (9 files, 879 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `Services/Sync/SyncManager.swift` | 278 | Coordinate local + cloud sync |
| `Services/Sync/ConflictResolver.swift` | 271 | Resolve sync conflicts |
| `Services/Connectivity/PhoneConnectivityManager.swift` | 198 | WatchConnectivity bridge |
| `Services/Background/HealthBackgroundScheduler.swift` | 156 | BGAppRefreshTask setup |
| `Services/Background/NotificationManager.swift` | 134 | Push notification handling |
| `Services/Protocols/HealthKitServiceProtocol.swift` | 28 | HealthKit interface |
| `Services/Protocols/StressAlgorithmServiceProtocol.swift` | 24 | Algorithm interface |
| `Services/Protocols/StressRepositoryProtocol.swift` | 32 | Repository interface |
| `Services/Protocols/CloudKitServiceProtocol.swift` | 40 | CloudKit interface |

### ViewModels (2 files, ~737 LOC)
State management with @Observable macro.

| File | LOC | Purpose |
|------|-----|---------|
| `ViewModels/StressViewModel.swift` | 278 | Main app state with auto-refresh (HKObserverQuery) |
| `ViewModels/DataManagementViewModel.swift` | 459 | Export, delete, reset operations state |

**Key Properties in StressViewModel:**
- `currentStress: StressResult?`
- `recentMeasurements: [StressMeasurement]`
- `baseline: PersonalBaseline`
- `isLoading: Bool`
- `errorMessage: String?`
- `todayMeasurements: [StressMeasurement]` (NEW)
- `weeklyAverage: (current: Double, previous: Double)?` (NEW)
- `hrvHistory: [Double]` (NEW)
- `heartRateTrend: TrendDirection` (NEW)
- `aiInsight: AIInsight?` (NEW)

**Auto-Refresh Features (NEW):**
- HKObserverQuery subscription for automatic updates
- Debounced refresh (60-second minimum interval)
- Background health data monitoring

### Views (77 files, ~9,308 LOC)
SwiftUI declarative interface organized by feature.

#### Dashboard Module (23 files, ~2,100 LOC)
Main stress display screen with enhanced UI.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Dashboard/StressDashboardView.swift` | 271 | Main dashboard with unified scroll layout |
| `Views/Dashboard/Components/StressRingView.swift` | 86 | 260pt animated ring with spring animations |
| `Views/Dashboard/Components/MetricCardView.swift` | 171 | HRV + HR cards with number transitions |
| `Views/Dashboard/Components/DailyTimelineView.swift` | 263 | 24-hour stress timeline chart |
| `Views/Dashboard/Components/WeeklyInsightCard.swift` | 138 | Week-over-week comparison |
| `Views/Dashboard/Components/AIInsightCard.swift` | 124 | AI-generated personalized insights |
| `Views/Dashboard/Components/LearningPhaseCard.swift` | 192 | Baseline learning progress |
| `Views/Dashboard/Components/MiniLineChartView.swift` | 106 | Sparkline for metrics |
| `Views/Dashboard/Components/StatusBadgeView.swift` | 92 | Stress category badge |
| `Views/Dashboard/Components/EmptyDashboardView.swift` | 98 | Empty state placeholder |
| `Views/Dashboard/Components/NoDataCard.swift` | 101 | No data state |
| `Views/Dashboard/Components/PermissionErrorCard.swift` | 131 | HealthKit error state |
| `Views/Dashboard/Components/QuickStatCard.swift` | 70 | Quick stat display |

**Dashboard Enhancement Features:**
- OLED dark theme (pure black #121212 background)
- Unified single-column scroll layout
- Auto-refresh via HKObserverQuery (no manual Measure button)
- Spring animations with Reduce Motion support
- All 6 components visible in single scroll

#### History Module (8 files, ~550 LOC)
Timeline view with filtering.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/History/HistoryView.swift` | 156 | List of all measurements |
| `Views/History/HistoryFilterView.swift` | 128 | Date/category filter UI |
| `Views/History/MeasurementDetailView.swift` | 128 | Individual measurement details |

#### Trends Module (6 files, ~420 LOC)
Charts and analytics.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Trends/TrendsView.swift` | 145 | Tab interface for charts |
| `Views/Trends/StressTrendChartView.swift` | 134 | Line chart (24h/week/month) |
| `Views/Trends/StressDistributionView.swift` | 108 | Category distribution chart |

#### Breathing Module (6 files, ~450 LOC)
Guided breathing exercises.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Breathing/BreathingExerciseView.swift` | 245 | Guided session UI + timer |
| `Views/Breathing/BreathingHistoryView.swift` | 178 | Past sessions list |

#### Settings Module (6 files, ~400 LOC)
App settings and data management.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Settings/SettingsView.swift` | 167 | Settings tabs |
| `Views/Settings/DataManagementView.swift` | 245 | Export, delete, reset controls |
| `Views/Settings/AccountSettingsView.swift` | 156 | iCloud/CloudKit options |
| `Views/Settings/PrivacyView.swift` | 94 | Privacy policy + data usage |

#### Onboarding Module (10 files, ~467 LOC)
First-launch flow with baseline setup.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Onboarding/OnboardingContainerView.swift` | 134 | Pager controller |
| `Views/Onboarding/WelcomeScreenView.swift` | 78 | Introduction |
| `Views/Onboarding/HealthKitPermissionView.swift` | 92 | HealthKit request |
| `Views/Onboarding/BaselineSetupView.swift` | 156 | Collect baseline data |
| `Views/Onboarding/OnboardingCompletionView.swift` | 7 | Success screen |

#### DesignSystem & Components (11 files, ~650 LOC)
Reusable components and design patterns.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Components/StressRingProgressView.swift` | 98 | Circular progress ring |
| `Views/Components/LoadingStateView.swift` | 67 | Loading skeleton |
| `Views/Components/ErrorStateView.swift` | 85 | Error message + retry |

#### Journal Module (1 file)
Stress journaling (v1.1 feature foundation).

| File | LOC | Purpose |
|------|-----|---------|
| `Views/Journal/` | - | Stress trigger tracking |

### Theme (5 files, ~330 LOC)
Design tokens and styling.

| File | LOC | Purpose |
|------|-----|---------|
| `Theme/Color+Extensions.swift` | 107 | Stress color mapping + OLED/accent colors |
| `Theme/Color+Wellness.swift` | 56 | Wellness color palette + `figmaIconGray` (#717171) |
| `Theme/DesignTokens.swift` | 89 | Spacing, corner radius, shadows |
| `Theme/Font+WellnessType.swift` | 45 | Typography scale |
| `Theme/Gradients.swift` | 30 | Gradient definitions |

**Key Colors:**
```swift
.stressColor(for: .relaxed)   // Green (#34C759)
.stressColor(for: .mild)      // Blue (#007AFF)
.stressColor(for: .moderate)  // Yellow (#FFD60A)
.stressColor(for: .high)      // Orange (#FF9500)

// OLED Dark Theme
.oledBackground               // #121212 (pure black)
.cardBackground              // #1E1E1E
.cardSecondary               // #2A2A2A
.accentFor(stress:)          // Dynamic accent per stress level

// NEW (Feb 2026)
.figmaIconGray               // #717171 (Character card icons)
```

### Utilities (7 files, ~435 LOC)
Helper functions and extensions.

| File | LOC | Purpose |
|------|-----|---------|
| `Utilities/HapticManager.swift` | 45 | Haptic feedback |
| `Utilities/AnimationPresets.swift` | 135 | Spring animation configurations (NEW) |
| `Utilities/AccessibilityModifiers.swift` | 144 | Custom accessibility modifiers (NEW) |
| `Utilities/ColorBlindnessSimulator.swift` | 38 | Accessibility testing |
| `Utilities/DynamicTypeScaling.swift` | 34 | Text scaling helper |
| `Utilities/DateFormattingUtility.swift` | 28 | Date formatting |
| `Utilities/AccessibilityUtilities.swift` | 11 | A11y helpers | |

---

## watchOS App Structure (29 files, ~2,541 LOC)

### Models (6 files)
Shared with iOS (via target membership).

### Services (8 files, ~834 LOC)
Watch-specific HealthKit and CloudKit.

| File | LOC | Purpose |
|------|-----|---------|
| `Services/WatchHealthKitManager.swift` | 145 | Optimized HRV/HR fetch |
| `Services/WatchCloudKitManager.swift` | 234 | CloudKit sync for watch |
| `Services/WatchConnectivityManager.swift` | 167 | iPhone bridge |
| `Services/WatchStressCalculator.swift` | 156 | Calculate on watch |
| `Services/ComplicationDataProvider.swift` | 132 | Widget data source |

### ViewModels (1 file, 156 LOC)
| File | LOC | Purpose |
|------|-----|---------|
| `ViewModels/WatchStressViewModel.swift` | 156 | Watch app state |

### Views (5 files, ~412 LOC)
Compact watch UI.

| File | LOC | Purpose |
|------|-----|---------|
| `Views/ContentView.swift` | 178 | Watch app root |
| `Views/Components/CompactStressView.swift` | 145 | Condensed stress display |
| `Views/DetailView.swift` | 89 | Stress detail on watch |

### Complications (9 files, ~745 LOC)
WidgetKit complications (not ClockKit).

| File | LOC | Purpose |
|------|-----|---------|
| `Complications/ComplicationBundle.swift` | 34 | WidgetKit bundle entry |
| `Complications/Providers/CircularComplicationProvider.swift` | 156 | Circular family |
| `Complications/Providers/RectangularComplicationProvider.swift` | 167 | Rectangular family |
| `Complications/Providers/InlineComplicationProvider.swift` | 123 | Inline family |
| `Complications/Views/CircularStressView.swift` | 134 | Circular complication UI |
| `Complications/Views/RectangularStressView.swift` | 145 | Rectangular complication UI |
| `Complications/Views/InlineStressView.swift` | 86 | Inline complication UI |

### Theme (2 files, ~98 LOC)
Watch-specific design tokens.

| File | LOC | Purpose |
|------|-----|---------|
| `Theme/Color+Extensions.swift` | 45 | Watch stress colors |
| `Theme/WatchDesignTokens.swift` | 53 | Watch spacing/fonts |

---

## Home Screen Widgets (7 files, ~1,287 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `StressMonitorWidget/WidgetBundle.swift` | 28 | Widget bundle entry |
| `StressMonitorWidget/Views/SmallWidgetView.swift` | 187 | 2x2 widget |
| `StressMonitorWidget/Views/MediumWidgetView.swift` | 284 | 2x4 widget |
| `StressMonitorWidget/Views/LargeWidgetView.swift` | 424 | 4x4 widget with trends |
| `StressMonitorWidget/DataProviders.swift` | 156 | WidgetKit timeline provider |
| `StressMonitorWidget/Intents/UpdateWidgetIntent.swift` | 73 | Intent for interactive widget |
| `StressMonitorWidget/Utilities/WidgetDataHelper.swift` | 135 | Shared data access |

---

## Unit Tests (27 files, ~7,500 LOC)

### Core Algorithm Tests (2 files, 312 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `StressCalculatorTests.swift` | 167 | 20+ test cases for algorithm |
| `BaselineCalculatorTests.swift` | 145 | 10+ baseline computation tests |

### Service Tests (8 files, ~1,890 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `HealthKitManagerTests.swift` | 198 | HRV/HR fetch mocking |
| `StressRepositoryTests.swift` | 245 | SwiftData CRUD operations |
| `CloudKitManagerTests.swift` | 289 | CloudKit sync tests |
| `SyncManagerTests.swift` | 267 | Sync orchestration tests |
| `DataManagementServiceTests.swift` | 234 | Export/delete functionality |
| `NotificationManagerTests.swift` | 167 | Push notification handling |
| `BaselineCalculatorTests.swift` | 156 | Edge cases for baseline |
| `MockCloudKitManager.swift` | 337 | Mock implementation |

### ViewModel Tests (3 files, ~534 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `StressViewModelTests.swift` | 267 | Main app state tests |
| `DataManagementViewModelTests.swift` | 189 | Export/delete state |
| `WatchStressViewModelTests.swift` | 78 | Watch app state |

### UI & Component Tests (5 files, ~876 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `AccessibleStressTrendChartTests.swift` | 178 | Chart rendering |
| `StressRingViewTests.swift` | 145 | Ring animation tests |
| `ColorSystemTests.swift` | 134 | Stress color accuracy |
| `AccessibilityTests.swift` | 289 | WCAG compliance |
| `DynamicTypeTests.swift` | 130 | Text scaling |

### Onboarding Tests (4 files, ~478 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `OnboardingViewTests.swift` | 156 | Flow completion |
| `BaselineSetupTests.swift` | 134 | Baseline collection |
| `HealthKitPermissionTests.swift` | 123 | Permission request flow |
| `OnboardingStateTests.swift` | 65 | Onboarding transitions |

### Test Utilities (2 files, ~383 LOC)

| File | LOC | Purpose |
|------|-----|---------|
| `TestHelpers/TestDataFactory.swift` | 245 | Test data generation |
| `TestHelpers/MockHealthKitManager.swift` | 138 | Health data mocks |

---

## Key Metrics

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 206 |
| **Total LOC** | ~26,000 |
| **iOS App LOC** | ~14,500 |
| **watchOS App LOC** | ~2,541 |
| **Widget LOC** | ~1,287 |
| **Test LOC** | ~7,500 |
| **Average File Size** | 126 LOC |
| **Test Coverage** | 100+ tests (>80% core logic) |
| **No External Dependencies** | System frameworks only |

---

## Component Responsibilities

### Data Layer
- **Models:** Data structures (@Model, Codable)
- **Repository:** SwiftData CRUD, queries
- **Protocols:** Interface definitions

### Business Logic
- **StressCalculator:** HRV + HR → Stress (0-100)
- **BaselineCalculator:** Physiological baseline adaptation
- **HealthKitManager:** Apple Health API wrapper
- **CloudKitManager:** iCloud sync orchestration
- **InsightGeneratorService:** AI-powered personalized insights (NEW)

### Presentation
- **ViewModels:** @Observable state management with auto-refresh
- **Views:** SwiftUI declarative UI
- **Theme:** Design tokens, colors, fonts

### Supporting
- **Services:** Background tasks, notifications, sync
- **Utilities:** Haptics, accessibility, formatting

---

**Last Updated:** February 28, 2026
**Maintainers:** Phuong Doan
