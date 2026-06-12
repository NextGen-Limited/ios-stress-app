# Codebase Summary

**Total Files:** ~600 files (including 303+ Swift files)
**Total LOC:** ~34,000+
**Architecture:** MVVM + Protocol-Oriented Design
**Last Updated:** June 12, 2026

---

## High-Level Structure

```
ios-stress-app/
├── StressMonitor/                      # Xcode project root
│   ├── StressMonitor/                  # iOS App (210 files)
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

## iOS App Structure (225 Swift files)

### Models (21 files, ~1,100 LOC)
Core data structures for health metrics, stress calculations, and character system.

| File | Purpose |
|------|---------|
| `StressMeasurement.swift` | @Model SwiftData entity for measurements |
| `StressResult.swift` | Stress calculation output |
| `StressCategory.swift` | Enum: Relaxed, Mild, Moderate, High |
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

### Services (52 files, ~8,200 LOC)
Business logic and system integrations.

#### Algorithm Services (10 files)
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

#### LLM Services (10 files)
- `LLMServiceProtocol.swift` - AI service abstraction
- `AppleIntelligenceService.swift` - On-device AI integration (iOS 26+)
- `CloudLLMService.swift` - Cloud-based AI fallback with hardcoded endpoint
- `ChatContextBuilder.swift` - Conversation context management
- `ChatQuickActions.swift` - Quick response suggestions
- `SSEParser.swift` - Server-Sent Events streaming parser
- `LLMAPITarget.swift` - API configuration for cloud LLM
- Plus 3 additional service classes for LLM infrastructure

#### Data Management Services (8 files)
- `DataManagementService.swift` - Central data management
- `DataExporter.swift` - Data export functionality
- `DataDeleter.swift` - Data cleanup and management
- `CSVGenerator.swift` - CSV file generation
- `JSONGenerator.swift` - JSON export formatting
- `CloudKitResetService.swift` - CloudKit data reset utilities
- `LocalDataWipeService.swift` - Local data cleanup
- `DataManagementUtilities.swift` - Data management helpers

#### Background Services (2 files)
- `HealthBackgroundScheduler.swift` - Background health data collection
- `NotificationManager.swift` - Local notification system

#### Sync Services (2 files)
- `SyncManager.swift` - Data synchronization coordination
- `ConflictResolver.swift` - Sync conflict resolution

#### StoreKit Services (3 files)
- `PremiumState.swift` - Centralized premium state management singleton
- `StoreKitServiceProtocol.swift` - StoreKit abstraction layer
- `MockStoreKitService.swift` - Mock implementation for development

#### Additional Services
- `InsightGeneratorService.swift` - AI-powered insights
- `MockServices.swift` - Development mock data services

### ViewModels (10 files)
State management layer:

- `StressViewModel.swift` - Core stress tracking state
- `ChatViewModel.swift` - AI chat with streaming responses
- `DashboardViewModel.swift` - Dashboard data aggregation
- `TrendViewModel.swift` - Historical trend analysis
- `HistoryViewModel.swift` - Historical data browsing
- `SettingsViewModel.swift` - App configuration state
- `DataManagementViewModel.swift` - Data management operations
- `BreathingViewModel.swift` - Breathing exercise state
- `MiniWalkViewModel.swift` - Mini Walk exercise state
- `CharacterCollectionViewModel.swift` - Character collection state & unlock logic

### Views (150+ files)
SwiftUI user interface components:

#### Main Navigation Structure (5 tabs)
1. **Home** (`DashboardView.swift`) - Main stress monitoring dashboard
2. **Trends** (`TrendsView.swift`) - Historical stress visualization
3. **Breathing** (`BreathingView.swift`) - Breathing exercises
4. **Characters** (`CharacterCollectionView.swift`) - Character collection & evolution
5. **Settings** (`SettingsView.swift`) - App settings

#### Feature Views
- `Dashboard/` (26 files) - Dashboard components, cards, metrics, insights
- `Trends/` (12 files) - Trend charts, heatmaps, statistics
- `Breathing/` (6 files) - Breathing exercise flow
- `Characters/` (8 files) - Character collection, detail, picker, celebration
- `Settings/` (13 files) - Settings screens, data management
- `History/` (7 files) - Historical data browsing
- `Onboarding/` (10 files) - Onboarding flow
- `Premium/` (6 files) - IAP Premium subscription screen
- `Chat/` - AI chat interface components
- `Journal/` - Journaling features
- `MiniWalk/` - Mini Walk exercise with circular timer

### Theme (5 files)
Design system and styling:

- `Color+Wellness.swift` - App-specific color definitions
- `Color+Extensions.swift` - Color system extensions
- `DesignTokens.swift` - Core design tokens
- `Font+WellnessType.swift` - Typography system
- `Gradients.swift` - Gradient definitions

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

### 3-Tab Navigation Architecture
The app uses a simplified 3-tab navigation structure:

1. **Home** (`DashboardView.swift`) - Main stress monitoring dashboard with current stress levels, recent trends, and quick actions
2. **Action** (`ActionView.swift`) - Quick access to exercises, breathing techniques, and AI chat
3. **Trend** (`TrendsView.swift`) - Historical stress visualization and pattern analysis

### Secondary Navigation
- Settings, History, and Data Management are accessible via navigation within respective tabs
- Settings accessible through Dashboard → Settings icon
- History accessible through Trends → Historical data views

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
- **Primary**: Apple Intelligence (Foundation Models, iOS 26+)
- **Fallback**: CloudLLMService with SSE streaming
- **Architecture**: Server-Sent Events for real-time streaming
- **Features**: Stress insights, breathing guidance, conversation

### Dependencies
- **13 SPM packages** - Moya, Alamofire, Kingfisher, SwiftUICharts, ReactiveSwift, RxSwift, Chat, Giphy iOS SDK, MediaPicker, ActivityIndicatorView, AnchoredPopup, AnimatedTabBar, LibWebP
- **Privacy-first design** - All data processed locally when possible
- **Modular architecture** - Protocol-based dependency injection

---

## Key Features

### Stress Monitoring
- Multi-factor stress calculation (HRV 70%, Heart Rate 30%)
- Real-time stress level assessment with confidence scoring
- Personalized baseline calibration
- Stress categorization: Relaxed, Mild, Moderate, High

### AI-Powered Insights
- Apple Intelligence integration for iOS 26+
- CloudLLM fallback with SSE streaming
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

1. **Stress History Timeline** - Activity correlation with stress data
2. **Guided Breathing with Biofeedback** - Enhanced breathing exercises with real-time feedback
3. **Apple Watch Complications** - Live stress metrics on watch face
4. **Morning Readiness Check** - HRV trend analysis for daily readiness
5. **Real-time Stress Score** - HRV analysis with immediate feedback
6. **Mini Walk Exercise** - Walking exercise screen with circular timer
7. **IAP Premium Screen** - Subscription paywall with StoreKit service protocol
8. **CloudLLMService** - Hardcoded endpoint configuration with SSE streaming
9. **5-Tab Navigation** - Home/Trends/Breathing/Characters/Settings structure
10. **Character Collection UI** - 5 elemental characters with evolution system, unlock types (free/premium/streak-gated), persistent storage, 38 SVG assets

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
- **38 SVG assets**: Named as `{character}_{evolution}_{mood}.svg`
- **Services**: `CharacterAssetResolver` (maps character+evolution+mood → SVG), `CharacterCollectionViewModel` (state management)
- **Models**: `CharacterCreature` (definition), `CharacterUnlock` (persistent state in SwiftData)
- **Views**: CharacterCollectionView (grid), CharacterDetailView, CharacterPickerSheet, EvolutionCelebrationView
- **Element colors**: Water blue, Earth green, Fire orange, Air purple, Moon indigo

### Asset Naming Convention
See `/docs/design/ASSET_NAMING.md` for full SVG asset naming specification.

---

## Key Metrics

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 303+ |
| **Total LOC** | ~34,000+ |
| **iOS App Files** | 225+ |
| **External Dependencies** | 13 SPM packages |
| **Average File Size** | <200 LOC |
| **Font** | Roboto (6 weights) |
| **Character Assets** | 38 SVG files |

---

**Last Updated:** June 12, 2026
**Maintainers:** Phuong Doan