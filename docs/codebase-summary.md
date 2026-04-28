# Codebase Summary

**Total Files:** ~570 files (including 210 Swift files)
**Total Tokens:** ~582,571
**Architecture:** MVVM + Protocol-Oriented Design
**Last Updated:** April 26, 2026

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

## iOS App Structure (210 Swift files)

### Models (18 files, ~969 LOC)
Core data structures for health metrics and stress calculations.

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

### Services (46 files, ~6,900 LOC)
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

#### LLM Services (7 files)
- `LLMServiceProtocol.swift` - AI service abstraction
- `AppleIntelligenceService.swift` - On-device AI integration (iOS 26+)
- `CloudLLMService.swift` - Cloud-based AI fallback with hardcoded endpoint
- `ChatContextBuilder.swift` - Conversation context management
- `ChatQuickActions.swift` - Quick response suggestions
- `SSEParser.swift` - Server-Sent Events streaming parser
- `LLMAPITarget.swift` - API configuration for cloud LLM

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

#### Additional Services
- `InsightGeneratorService.swift` - AI-powered insights
- `MockServices.swift` - Development mock data services

### ViewModels (4+ files)
State management layer:

- `StressViewModel.swift` - Core stress tracking state
- `ChatViewModel.swift` - AI chat with streaming responses
- `DashboardViewModel.swift` - Dashboard data aggregation
- `TrendViewModel.swift` - Historical trend analysis
- `HistoryViewModel.swift` - Historical data browsing
- `SettingsViewModel.swift` - App configuration state
- `DataManagementViewModel.swift` - Data management operations
- `BreathingViewModel.swift` - Breathing exercise state

### Views (~100 files)
SwiftUI user interface components:

#### Main Navigation Structure (3 tabs)
1. **Home** (`DashboardView.swift`) - Main stress monitoring dashboard
2. **Action** (`ActionView.swift`) - Quick actions, exercises, breathing, AI chat
3. **Trend** (`TrendsView.swift`) - Historical stress visualization

#### Feature Views
- `HistoryView.swift` - Historical stress data
- `SettingsView.swift` - App settings and configuration
- `BreathingView.swift` - Breathing exercise interface
- `Journal/` - Journaling features
- `Chat/` - AI chat interface components

### Theme (5 files)
Design system and styling:

- `Color+Wellness.swift` - App-specific color definitions
- `Color+Extensions.swift` - Color system extensions
- `DesignTokens.swift` - Core design tokens
- `Font+WellnessType.swift` - Typography system
- `Gradients.swift` - Gradient definitions

### Components (4 files)
Reusable UI components:

- `StressBuddyIllustration.swift` - AI companion visual components
- `StressCharacterCard.swift` - Character representation
- `CharacterAnimationModifier.swift` - Animation utilities
- `DecorativeTriangleView.swift` - Decorative UI elements

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
- **Zero third-party dependencies** - Uses only Apple system frameworks
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

## Recent Updates (April 2026)

1. **CloudLLMService** - Hardcoded endpoint configuration, removed server config UI
2. **SSEParser** + **LLMAPITarget** - New SSE streaming infrastructure
3. **ActionView** - New unified action tab replacing multi-tab layout
4. **Box Breathing** - Aligned with Figma design specifications
5. **ChatViewModel** - Streaming LLM responses with real-time updates
6. **Mini Walk Exercise** - New walking exercise screen with circular timer and Figma-aligned design (Apr 26, 2026)
7. **IAP Premium Screen** - Complete subscription paywall with StoreKit service protocol, premium state management, and Figma-aligned design (Apr 26, 2026)

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

## Key Metrics

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 210 |
| **Total LOC** | ~25,600 |
| **External Dependencies** | 0 (system frameworks only) |
| **Average File Size** | <200 LOC |
| **Font** | Roboto (6 weights) |

---

**Last Updated:** April 26, 2026
**Maintainers:** Phuong Doan