# System Architecture: Overview

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Data Flow:** Unidirectional (Models -> Services -> ViewModels -> Views)
**Last Updated:** June 17, 2026

---

## Overview

StressMonitor follows a clean, layered architecture designed for testability, maintainability, and scalability. This document provides navigation to detailed architecture information.

## Quick Links

### Core Architecture
Understanding the foundation:
- **[System Architecture: Core](./system-architecture-core.md)** - MVVM pattern, layer responsibilities, service architecture (HealthKit, Algorithm, Repository), data models, data flow, concurrency, error handling, testing architecture

### Platform Features & Security
Advanced platform capabilities:
- **[System Architecture: Platform](./system-architecture-platform.md)** - CloudKit sync, Apple Watch standalone app, WidgetKit complications, home screen widgets, performance considerations, security model, extensibility points

---

## Architecture Layers

### 1. Presentation Layer (SwiftUI Views)
- Declarative, zero business logic
- Render based on ViewModel state
- Forward actions to ViewModels
- Handle loading/error display
- Implement accessibility

### 2. ViewModel Layer (@Observable)
- Manage reactive state
- Coordinate services
- Handle async operations
- Error presentation
- @MainActor for UI thread safety

### 3. Service Layer
- Business logic implementation
- Protocol-based design
- Testable via dependency injection
- Domain-organized (HealthKit, Algorithm, Repository, CloudKit, etc.)

### 4. Data Layer
- SwiftData for local persistence
- CloudKit for cloud sync
- E2E encrypted storage
- Offline-first queue management

---

## Key Technologies

| Technology | Usage | Rationale |
|-----------|-------|-----------|
| **SwiftUI** | UI framework | Modern, declarative, iOS 17+ |
| **MVVM** | Architecture pattern | Testable, reactive, clean separation |
| **SwiftData** | Local persistence | iOS 17+ native, encrypted at rest |
| **CloudKit** | Cloud sync | Apple ecosystem, E2E encryption |
| **HealthKit** | Health data | Official Apple health API, privacy-first |
| **WidgetKit** | Widgets & complications | Modern widget framework, watchOS 10+, Live Activities |
| **async/await** | Concurrency | Swift 5.9+ native, structured concurrency |
| **SSE Streaming** | Real-time AI chat | Server-sent events for SupabaseLLM responses |
| **Foundation Models** | On-device LLM | Apple Intelligence (iOS 26+), conversational AI |
| **Combine** | Async streams | Background health data observation |
| **AppearanceManager** | Theme management | @Observable singleton for Light/Dark/System mode |

---

## Data Flow

```
User Action
    ↓
SwiftUI View
    ↓
ViewModel (async operation)
    ↓
Service Layer (protocol-based)
    ↓
Data Layer (SwiftData + CloudKit)
    ↓
System APIs (HealthKit)
    ↓
Apple Watch Sensors
```

**AI Chat data flow (Jun 2026):**
```
ActionView.isChatPresented → .sheet(ChatBottomSheetView)
    ↓
ChatViewModel (sends messages + receives streaming tokens)
    ↓
LLMServiceProtocol.send(messages:systemPrompt:) → AsyncThrowingStream<String, Error>
    ↓
SupabaseLLMService (Supabase Edge Functions with SSE streaming) OR AppleIntelligenceService (iOS 26+ Foundation Models)
    ↑
ChatContextBuilder (assembles health/stress context into system prompt)
```

**Auto-refresh path (Mar 2026):**
```
HKObserverQuery (background) → StressViewModel.startAutoRefresh()
    ↓ [#if !targetEnvironment(simulator)]
Debounce (60s min) → fetchAndCalculate() → State update → SwiftUI re-render
```

**Weekly dashboard data flow (Mar 2026):**
```
StressRepository.fetchRecent() → StressViewModel.weeklyMeasurements
    ↓
DashboardViewModel.weeklyMeasurements (7-day slice)
    ↓
DailyTimelineView (7-day × 7-slot dot-matrix grid)
```

**3-Tab Navigation flow (Jun 2026):**
```
MainTabView (3 tabs: Home, Action, Trend)
    ↓
Home → DashboardView (stress monitoring, bio age card, insights)
    ↓
Action → ActionView (breathing exercises, AI chat, quick actions)
    ↓
Trend → TrendsView (analytics, charts, heatmaps, statistics)
    ↓
Settings Button → SettingsView (non-tab, accessed via button/chevron)
    → CharactersCard (entry point to CharacterCollectionView)
```

**Reverse for updates:**
```
Model Change
    ↓
ViewModel Updates State (@Observable)
    ↓
SwiftUI Re-renders
    ↓
UI Updates on screen
```

---

## Core Services

### AppearanceManager Service (NEW - Jun 2026)
- **@Observable singleton** for app-wide theme management
- Manages Light/Dark/System color scheme preference
- Persists preference to UserDefaults
- Provides `colorScheme: ColorScheme?` property for SwiftUI environment
- Integrates with Settings screen's ProfileCard appearance picker
- Synchronized across all tabs and modals

### HealthKit Service
- Request HealthKit authorization
- Fetch HRV data from Apple Watch  
- Fetch heart rate samples
- Handle permission denial gracefully
- Support for 5-factor data (HRV, HR, Sleep, Activity, Recovery)
- Extensions for activity, sleep, and recovery data fetching
- Simulator service for testing

### Multi-Factor Algorithm Service
- **5-factor stress algorithm with dynamic weight redistribution**
- Core algorithm: MultiFactorStressCalculator (HRV, HR, Sleep, Activity, Recovery)
- Individual factor services: HRVStressFactor, HeartRateStressFactor, SleepStressFactor, ActivityStressFactor, RecoveryStressFactor
- FactorCalibrator for adjusting weights based on data quality
- StressFactor protocol for extensibility
- Updated algorithm: HRV (70% dynamic), HR (30% dynamic), Sleep, Activity, Recovery weights redistribute based on data availability

### Biological Age Calculator Service (NEW - Jun 17)
- `BioAgeCalculator` — Estimates biological age from HRV (SDNN), resting HR, sleep efficiency using age-group norm tables
- Requires ≥7 days of baseline data for accuracy
- Returns `BioAgeResult` with estimatedAge, chronologicalAge, difference, BioAgeTrend enum
- Follows `MultiFactorStressCalculator` pattern (Sendable, struct-based)
- Graceful degradation when insufficient data

### Insight Service
- Generate AI-powered personalized insights from measurement history
- `InsightGeneratorService.generateInsight(stress:baseline:history:)`
- Surfaces patterns and recommendations to `AIInsightCard` on dashboard

### LLM Service (Apr 2026, updated Jun 2026)
- Protocol-based LLM abstraction (`LLMServiceProtocol`)
- **`SupabaseLLMService` (Production Primary)** -- Cloud service using Supabase Edge Functions for SSE streaming
  - Configurable endpoint via `SupabaseConfig` (URL + anonKey) for easy deployment switching
  - Fully tested in production; reliable streaming with SSE (Server-Sent Events)
  - SSE streaming: `data: {"token": "..."}` with `[DONE]` sentinel
  - Health context injection via `StressContextPayload` (anonymized)
  - Graceful fallback when server unreachable
  - Real deployment ready as of Jun 12, 2026
- **`AppleIntelligenceService` (iOS 26+ Fallback)** -- On-device Apple Foundation Models, streaming token response
  - Automatic fallback for iOS 26+ capable devices
  - On-device processing, no external API calls
  - Streaming token response for real-time UX
- `SSEParser` -- Server-Sent Events parser for streaming responses
- `ChatContextBuilder` -- assembles health/stress data into system prompt
- `ChatQuickActions` -- pre-built prompt suggestions for wellness topics
- Graceful degradation on pre-iOS 26 devices (uses SupabaseLLM)
- `LLMServiceError` enum covers all failure modes (unavailable, context exceeded, guardrail, rate limit, etc.)
- Session-only chat persistence (no SwiftData)

### Character System Service (Jun 2026)
- `CharacterAssetResolver` -- Maps character + evolution stage + mood → SVG asset path
- 5 elemental characters with dual unlock types (free/premium/streak-gated)
- Evolution system: 3 stages triggered by streaks, sessions, resilience scores
- 38 SVG assets following `{character}_{evolution}_{mood}.svg` naming
- `CharacterUnlock` SwiftData model for persistent unlock progress tracking

### StoreKit Service (Jun 2026 - PR #19) ✅ RESOLVED
- Real App Store product fetching and transaction monitoring (no mocks)
- `StoreKitService` - fully production-ready StoreKit 2 implementation
- `StoreKitProductCatalog` - resolves product IDs from Info.plist
- `PremiumState` - singleton for centralized premium/subscription state
- Transaction listeners, entitlement refresh, receipt validation
- Graceful fallback when App Store unavailable (uses SubscriptionPlan.defaultPlans)
- Tested and merged (PR #19, Jun 12, 2026)

### Repository Service
- SwiftData CRUD operations
- Query recent/filtered measurements
- Persist baseline data
- Data cleanup operations
- **UPDATE**: 491 LOC

### Theme & Appearance Service (Jun 2026)
- `AppearanceManager` - Singleton @Observable for dark mode toggle
- Light/Dark/System preference management
- UserDefaults persistence
- Integration with Settings ProfileCard

### CloudKit Service
- Sync measurements to iCloud
- Fetch cloud updates
- E2E encrypted storage
- Offline queue management
- Rate limiting (5-record batches, 5-minute throttle)
- **UPDATE**: CloudKitManager (294 LOC), CloudKitSchema (80 LOC), CloudKitSyncEngine (222 LOC)

### DataManagement Service
- Export to CSV/JSON
- Delete by date range
- Delete by category
- Full local/cloud wipe
- **UPDATE**: 8 files (~2,173 LOC) including DataManagementService, CSVGenerator, JSONGenerator, DataDeleter, CloudKitResetService, LocalDataWipeService, DataManagementUtilities

### StoreKit Service (Apr 2026)
- Protocol-based StoreKit abstraction (`StoreKitServiceProtocol`)
- `PremiumState` - Centralized premium state management singleton
- `MockStoreKitService` - Mock implementation for development/testing
- IAP Premium subscription screen with plan selection
- Subscription card, CTA button, and utility row components

---

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **13+ SPM packages** | Kingfisher, SwiftUICharts, ExyteChat, AnimatedTabBar, etc. | Network, UI, and media capabilities |
| **Local-first architecture** | Works offline, fast responsiveness | Eventual consistency |
| **MVVM + Protocols** | Testability, loose coupling | More boilerplate |
| **@Observable macro** | Modern, iOS 17+ reactive | Excludes iOS 16 |
| **CloudKit E2E encryption** | User privacy, Apple ecosystem | Requires iCloud account |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement | No ClockKit support |
| **Multi-factor algorithm** | More comprehensive stress assessment | Increased complexity, more data required |
| **Offline-first sync** | UX resilience, privacy | Conflict resolution complexity |
| **Protocol-based services** | Testability, extensibility | More abstraction overhead |

---

## Testing Strategy

### Isolation via Protocols

All services conform to protocols, enabling mock implementations:

```swift
protocol HealthKitServiceProtocol {
  func fetchLatestHRV() async throws -> HRVMeasurement?
}

// Mock for testing
final class MockHealthKitManager: HealthKitServiceProtocol {
  var mockHRV: HRVMeasurement?
  func fetchLatestHRV() async throws -> HRVMeasurement? { mockHRV }
}

// Inject into ViewModel
let viewModel = StressViewModel(healthKit: MockHealthKitManager())
```

### Test Coverage
- **Core Algorithm:** >90% coverage
- **Repository:** >85% coverage
- **Services:** >80% coverage
- **ViewModels:** >80% coverage
- **Overall:** >80% target

---

## Performance Targets

| Operation | Target |
|-----------|--------|
| Stress calculation | <1 second |
| View render time | <16ms (60 FPS) |
| CloudKit sync | <30 seconds |
| App launch | <2 seconds |
| Memory (idle) | <50 MB |
| Memory (100 measurements) | <100 MB |

---

## Security & Privacy

### HealthKit
- Read-only access (HRV + Heart Rate)
- User grants explicit permission
- No writes to Apple Health
- Handle denial gracefully

### CloudKit
- Private database (per-user)
- E2E encryption by default
- No PII transmitted
- User controls sync toggle

### Local Storage
- SwiftData encrypted at rest by iOS
- No hardcoded secrets
- User can export/delete anytime

### Privacy
- SupabaseLLMService sends anonymized chat context to Supabase Edge Functions; health data stays on-device
- No telemetry or analytics
- No third-party analytics services
- Health data never leaves device+iCloud
- SSE streaming ensures real-time AI responses without persistent data storage

---

## Extensibility

### Adding a New Service

1. Create protocol: `NewServiceProtocol`
2. Implement service: `NewService: NewServiceProtocol`
3. Create mock for testing: `MockNewService: NewServiceProtocol`
4. Inject into ViewModel
5. Write tests

### Adding a New Widget

1. Create provider: `NewComplicationProvider.swift`
2. Define timeline entries
3. Implement `getTimeline` method
4. Register in `ComplicationBundle`
5. Test on watch simulator

### Adding a New Export Format

1. Create: `NewFormatGenerator.swift`
2. Conform to export protocol
3. Implement serialization logic
4. Register in `DataExporter`
5. Test with sample data

### Adding Custom Shapes (for illustrations)

Custom SwiftUI shapes follow a reusable pattern:

```swift
// Public reusable shape
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Custom path logic
        return path
    }
}

// Usage in views
TriangleShape()
    .fill(Color.Wellness.figmaIconGray)
    .frame(width: 37, height: 34.5)
```

**Pattern Guidelines:**
- Use `Shape` protocol for reusable geometric shapes
- Keep shapes pure (no side effects)
- Accept configuration via init parameters
- Support accessibility with descriptive labels

---

**Maintained By:** Phuong Doan
**Version:** 1.0 Pre-Ship RC1
**Last Updated:** June 19, 2026
**Ship Status:** B1 ✅ Resolved (Jun 7), B2 ✅ Resolved (Jun 12), B3 🚫 Pending (test suite)