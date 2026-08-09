# System Architecture: Core Layers

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Data Flow:** Unidirectional (Models -> Services -> ViewModels -> Views)
**Section:** MVVM, data flow, core services, protocols
**Last Updated:** July 19, 2026

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│              SwiftUI Views + AppRouter                   │
│  (Dashboard, Action, Trends, Breathing, Settings, Chat) │
│   AppRouter: tab + per-tab NavigationPath (deep links)  │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                  ViewModels (@Observable)                │
│  (StressViewModel, ChatViewModel, DashboardViewModel)   │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│              Services (Protocol-Based)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  HealthKit   │  │  Algorithm   │  │  Repository  │  │
│  │  Services    │  │  Services    │  │  Services    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                  Data Layer                              │
│  ┌──────────────────┐         ┌──────────────────────┐ │
│  │  SwiftData       │         │  CloudKit Container  │ │
│  │  (Local DB)      │         │  (iCloud Sync)       │ │
│  └──────────────────┘         └──────────────────────┘ │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
         ┌─────────────────────────┐
         │  HealthKit / System     │
         │  (Apple Watch Sensors)  │
         └─────────────────────────┘
```

---

## Layer Responsibilities

### Presentation Layer (Views)

**Files:** `Views/` (~100 files)

Declarative SwiftUI screens, zero business logic.

**Responsibilities:**
- Render UI based on ViewModel state
- Forward user actions to ViewModel
- Display loading/error states
- A11y (VoiceOver, Dynamic Type, haptics)

**Example:**
```swift
struct DashboardView: View {
  @State var viewModel: StressViewModel

  var body: some View {
    VStack {
      if let stress = viewModel.currentStress {
        StressRingView(stress: stress)
      } else if viewModel.isLoading {
        ProgressView()
      } else {
        Button("Measure") {
          Task { await viewModel.measureStress() }
        }
      }
    }
    .task { await viewModel.loadRecentMeasurements() }
  }
}
```

**No direct access to:**
- SwiftData/CloudKit
- HealthKit APIs
- File system
- Sensors

**Navigation:** Views push `Route` values via `NavigationLink(value:)` or `AppRouter.deepLink(to:in:)`. A single `.navigationDestination(for: Route.self)` block resolves routes to screens across all tabs. Paywall presentation goes through `@Environment(PaywallController.self)` — never a local `@State` boolean.

### ViewModel Layer (@Observable)

**Files:** `ViewModels/` (4+ files)

Orchestrates business logic, manages UI state.

**Standalone ViewModels:**
| File | Purpose |
|------|---------|
| `StressViewModel.swift` | Main app state, auto-refresh, 5-factor algorithm |
| `ChatViewModel.swift` | Chat state, LLM interaction, streaming responses |
| `DashboardViewModel.swift` | Dashboard data aggregation |
| `TrendViewModel.swift` | Historical trend analysis |
| `HistoryViewModel.swift` | Historical data browsing |
| `SettingsViewModel.swift` | App configuration state (profile, notifications, theme, iCloud sync) |
| `DataManagementViewModel.swift` | Export, delete, reset operations |
| `BreathingViewModel.swift` | Breathing exercise state |
| `PremiumViewModel.swift` | Subscription management & StoreKit state |
| `CharacterCollectionViewModel.swift` | Character collection state & unlock logic |

**Responsibilities:**
- Manage @Observable state
- Coordinate between services
- Handle async operations
- Error handling & presentation

**Example:**
```swift
@Observable
final class StressViewModel {
  var currentStress: StressResult?
  var isLoading = false
  var errorMessage: String?

  private let healthKit: HealthKitServiceProtocol
  private let algorithm: StressAlgorithmServiceProtocol
  private let repository: StressRepositoryProtocol

  @MainActor
  func measureStress() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let hrv = try await healthKit.fetchLatestHRV()
      let hr = try await healthKit.fetchHeartRate(samples: 1)
      let result = try await algorithm.calculateStress(
        hrv: hrv?.value ?? 0,
        heartRate: hr.first?.value ?? 0
      )
      currentStress = result
      try await repository.save(StressMeasurement(...))
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
```

### Service Layer

**Files:** `Services/` (46 files)

Business logic, domain-specific operations, protocol-based.

#### HealthKit Service
**Files:** `Services/HealthKit/` (5 files, 624 LOC)

```swift
protocol HealthKitServiceProtocol {
  func requestAuthorization() async throws
  func fetchLatestHRV() async throws -> HRVMeasurement?
  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}
```

**Responsibilities:**
- Request HealthKit permissions
- Fetch HRV data from Apple Watch
- Fetch heart rate samples
- Handle authorization errors

#### Algorithm Service
**Files:** `Services/Algorithm/` (11 files, ~750+ LOC)
- `MultiFactorStressCalculator.swift` (104 LOC) - Orchestrates 5 factors
- `StressCalculator.swift` (118 LOC) - Legacy 2-factor calculator
- `BaselineCalculator.swift` (97 LOC) - 30-day baseline adaptation
- `StressFactor.swift` (22 LOC) - Protocol for individual factors
- `FactorCalibrator.swift` (56 LOC) - Weight adjustment
- `BioAgeCalculator.swift` (NEW - Jun 17) - Biological age estimation from HRV + health metrics
- `HRVStressFactor.swift`, `HeartRateStressFactor.swift`, `SleepStressFactor.swift`, `ActivityStressFactor.swift`, `RecoveryStressFactor.swift`

```swift
protocol StressAlgorithmServiceProtocol {
  func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
  func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
}
```

**Responsibilities:**
- Multi-factor stress algorithm (5 factors: HRV, HR, Sleep, Activity, Recovery)
- Dynamic weight redistribution when factors are unavailable
- Confidence scoring
- Baseline computation (30-day adaptation)
- Per-factor breakdown for UI display
- Edge case handling

**Algorithm:**
```
5 StressFactor contributors:
  - HRVStressFactor, HeartRateStressFactor, SleepStressFactor
  - ActivityStressFactor, RecoveryStressFactor
Each factor → FactorContribution (independent calculation)
MultiFactorStressCalculator → dynamic weight redistribution
StressContext → aggregates HRV, HR, Sleep, Activity, Recovery, Baseline
```

#### Repository Service
**File:** `Services/Repository/StressRepository.swift` (491 LOC)

```swift
protocol StressRepositoryProtocol {
  func save(_ measurement: StressMeasurement) async throws
  func fetchRecent(limit: Int) async throws -> [StressMeasurement]
  func fetchByDateRange(_ start: Date, _ end: Date) async throws -> [StressMeasurement]
  func getBaseline() async throws -> PersonalBaseline
  func deleteAll() async throws
}
```

**Responsibilities:**
- SwiftData CRUD operations
- Query recent/filtered measurements
- Baseline persistence
- Data cleanup

#### AppearanceManager Service
**File:** `Services/AppearanceManager.swift` (NEW - Jun 13)

@Observable singleton for dark mode preference management:

**Features:**
- Light/Dark/System theme modes
- UserDefaults persistence
- @Observable for reactive UI updates
- Single source of truth for appearance state

**Usage:**
```swift
@Environment(\.colorScheme) var systemColorScheme
let appearanceManager = AppearanceManager.shared
// appearanceManager.selectedAppearance: AppearanceMode
```

#### KeychainService
**File:** `Services/KeychainService.swift` (NEW - Jun 2026)

Security Framework wrapper for sensitive credential storage:

**Features:**
- Save/retrieve/delete operations via Security framework
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (no cloud migration)
- Typed error handling for access failures
- Used for API tokens and authentication credentials

**Responsibilities:**
- Secure storage of API tokens (SupabaseLLM, etc)
- Encryption at rest (handled by iOS Security framework)
- No backup/migration to other devices
- Graceful error handling on access denied

#### LLM Service
**Files:** `Services/LLM/` (8 files, ~500+ LOC)

Protocol-based LLM integration with on-device and cloud backends.

```swift
protocol LLMServiceProtocol: Sendable {
    func isAvailable() -> Bool
    func send(messages: [ChatMessage], systemPrompt: String)
        async throws -> AsyncThrowingStream<String, Error>
}
```

| Implementation | Platform | Transport | Status |
|---------------|----------|-----------|--------|
| `SupabaseLLMService` | All iOS (network) | HTTP/SSE to Supabase Edge Functions | Production (Jun 2026) |

**Updated - Jun 2026:**
- Removed `CloudLLMService.swift` (dead code with hardcoded ngrok endpoint)
- Removed `LLMAPITarget.swift` (no longer needed)
- Implemented `SupabaseLLMService` - Production-ready Supabase integration
- Configurable via `SupabaseConfig` (URL + anonKey from environment)

**Supporting Types:**
- `SSEParser.swift` - Server-Sent Events streaming parser
- `ChatContextBuilder` -- builds system prompts with live health data, "AI Assistant" persona
- `StressContextPayload` -- health context for LLM system prompt
- `ChatQuickActions` -- predefined prompt suggestions contextualized by stress level
- `LLMServiceError` -- typed errors: unavailable, exceededContext, guardrailViolation, rateLimited, refused, concurrentRequests, decodingFailure, cancelled, unknown

**Data Flow:**
```
ChatViewModel → ChatContextBuilder.buildSystemPrompt(stress:baseline:history:)
             → LLMServiceProtocol.send(messages:systemPrompt:)
             → AsyncThrowingStream<String, Error> (token-by-token streaming)
                   ↓
             (SupabaseLLMService via Supabase Edge Functions)
```

**Persistence:** Chat data is session-only (in-memory `[ChatMessage]` array). No SwiftData persistence. Messages are lost on app restart.

#### StoreKit Service
**Files:** `Services/StoreKit/` (5 files, ~600+ LOC)

Real StoreKit 2 implementation with App Store product fetching (June 12, 2026 - PR #19).

```swift
protocol StoreKitServiceProtocol {
  var availablePlans: [SubscriptionPlan] { get async }
  var isPremiumUser: Bool { get async }
  func purchase(_ plan: SubscriptionPlan) async throws
  func restorePurchases() async throws
}
```

**Implementation:**
- `StoreKitService.swift` - Real App Store integration with StoreKit 2
- `StoreKitProductCatalog.swift` - Resolves product IDs from Info.plist (StoreKit config)
- `PremiumState.swift` - Singleton for centralized premium/subscription state
- `StoreKitServiceProtocol.swift` - Service protocol abstraction
- `MockStoreKitService.swift` - Mock implementation for testing only

**Features:**
- Real product fetching from App Store
- Transaction listeners and monitoring
- Entitlement refresh for subscription status
- Receipt validation
- Graceful fallback to `SubscriptionPlan.defaultPlans` when App Store unavailable

**Data Flow:**
```
PremiumViewModel → StoreKitService
                → Real App Store transactions OR fallback plans
                → PremiumState (centralized state)
                → PremiumView (paywall UI)
```

#### Character System Service
**Files:** `Services/CharacterAssetResolver.swift`, `Services/CharacterIllustrationExporter.swift`, `Theme/CharacterAssetCatalog.swift`, `Theme/MoodFaceAssetCatalog.swift`, `Theme/AppIconSystem.swift` (MoodFaceIcon) (~400 LOC)

5 elemental characters with evolution tracking (June 2026).

**Components:**
- `CharacterAssetResolver.swift` - Routes character IDs to design-exported SVG assets; mood drives ambient animation via `StressBuddyIllustration` layer. **Character views were migrated from procedural SwiftUI to SVG-backed assets in PR #45** (16 view files render `Image(assetName)` instead of procedural shapes).
- `CharacterIllustrationExporter.swift` - @MainActor service rendering character × evolution × mood combinations to PNG + ZIP (illustration export pipeline)
- `CharacterAssetCatalog.swift` - Bridges design-exported character SVGs to SwiftUI `Image` for **static** contexts (list avatars, grid tiles, picker sheets)
- `MoodFaceAssetCatalog.swift` - Bridges mood-face SVGs to SwiftUI `Image`
- `MoodFaceIcon` enum (in `Theme/AppIconSystem.swift`) - 5-level stress scale with SF Symbols + WCAG colors
- `CharacterUnlock.swift` (@Model) - SwiftData persistence for unlock progress

**Features:**
- 5 elemental characters: Ripple (water), Blossom (earth), Ember (fire), Zephyr (air), Lumi (moon)
- Dual unlock types: free, premium, streak-gated
- Evolution system: 3 stages triggered by user activity
- 6 character SVGs (ripple, blossom, ember, zephyr, lumi + ripple-hero) exported from design/characters-export.html
- 5 mood-face SVGs (relaxed, mild, moderate, high, severe) exported from design/icon-system.html
- Free/premium asset separation for paywall integration
- Mood-reactivity achieved via procedural SwiftUI animation (StressBuddyIllustration) over static SVG base

#### Icon System Service
**File:** `Theme/AppIconSystem.swift` (321 LOC) — centralized icon system, NEW PR #44 (Jun 25).

Single source of truth for every SF Symbol in the app, mapping the design spec (`design/icon-system.html`) to SF Symbols. **37 files / 59 references migrated** from scattered string literals.

**7 categories:**
- `Tab` (4 tabs, `.sfSymbol` + `.sfSymbolActive` active/inactive variants)
- `Nav` (back/forward/close)
- `Action` (6 quick-start exercises: breathing, bodyScan, miniWalk, coldSplash, gratitude, chat)
- `Metric` (8 health factor icons)
- `Setting` (17 settings rows)
- `System` (11 semantic icons: success, warning, locked, premium, etc.)
- `MoodFaceIcon` (5-level stress scale → SF Symbol + WCAG color)

**Helper views:** `SettingsIconView` (28×28 accent-tinted rounded square), `MoodFaceView` (colored circle + white face). Usage: `AppIconSystem.Tab.home.sfSymbol` or `SettingsIconView(.appleHealth, color: .pink)`.

---

## Data Layer

### SwiftData Models

**Entity:** `StressMeasurement` (@Model)

```swift
@Model
final class StressMeasurement {
  var timestamp: Date
  var stressLevel: Double           // 0-100
  var hrv: Double                   // ms
  var heartRate: Double             // bpm
  var confidence: Double            // 0-1
  var category: StressCategory
  var cloudKitRecordID: String?     // Sync tracking
  var isSynced: Bool
}
```

**Other Models:**
- `HRVMeasurement` - Raw HRV reading
- `HeartRateSample` - Raw HR reading
- `PersonalBaseline` - 30-day baseline
- `StressResult` - Calculation output
- `StressCategory` - Enum (Relaxed, Mild, Moderate, High, Severe — 5 levels, WCAG dual-coding)
- `ChatMessage` - Chat message with role enum
- `ActivityData` - Activity metrics for multi-factor algorithm
- `SleepData` - Sleep quality data
- `RecoveryData` - Recovery status data
- `DataQualityInfo` - Data quality assessment
- `FactorBreakdown` - Per-factor stress breakdown
- `FactorWeights` - Dynamic weight configuration
- `StressContext` - Aggregated health data input
- `ComplicationEntry` / `WidgetEntry` - Widget timeline entries

### Storage

**Local:**
- SwiftData database (encrypted at rest)
- Location: `~/Library/Application Support/StressMonitor/`

**Cloud:**
- CloudKit private database (E2E encrypted)
- Container: `iCloud.com.stressmonitor.app`
- Record types: `StressMeasurement`, `PersonalBaseline`

### Data Persistence Flow

```
1. User taps "Measure"
   ↓
2. HealthKitManager fetches HRV + HR
   ↓
3. StressCalculator computes stress level
   ↓
4. StressRepository saves to SwiftData (local)
   ↓
5. CloudKitManager queues sync
   ↓
6. Sync batches 5 records → CloudKit (E2E encrypted)
   ↓
7. Other devices fetch updates (within 30 seconds)
```

---

## Concurrency Model

### async/await Throughout

```swift
// HealthKit
func fetchLatestHRV() async throws -> HRVMeasurement?

// Algorithm
func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult

// Repository
func save(_ measurement: StressMeasurement) async throws

// CloudKit
func sync(measurement: StressMeasurement) async throws
```

### Main Thread Enforcement

All UI updates happen on @MainActor:

```swift
@Observable
final class StressViewModel {
  @MainActor
  func measureStress() async {
    isLoading = true
    // ... async operations ...
    currentStress = result  // Main thread guaranteed
  }
}
```

### Structured Concurrency

```swift
// Concurrent operations
async let hrv = healthKit.fetchLatestHRV()
async let hr = healthKit.fetchHeartRate(samples: 10)
let (hrvData, hrData) = try await (hrv, hr)
```

---

## Error Handling Strategy

### Typed Errors

```swift
enum StressError: LocalizedError {
  case healthKitNotAvailable
  case invalidMeasurement
  case baselineNotEstablished
  case cloudKitSyncFailed(String)
  case storageError(String)

  var errorDescription: String? {
    switch self {
    case .healthKitNotAvailable:
      return "HealthKit is not available"
    case .baselineNotEstablished:
      return "Complete onboarding to establish baseline"
    // ...
    }
  }
}
```

### Error Propagation

```swift
do {
  let result = try await calculateStress()
  currentStress = result
} catch StressError.baselineNotEstablished {
  showOnboarding()
} catch StressError.healthKitNotAvailable {
  showHealthKitPermissionRequest()
} catch {
  errorMessage = error.localizedDescription
}
```

---

## Testing Architecture

### Isolation via Protocols

```swift
final class StressViewModelTests: XCTestCase {
  private var viewModel: StressViewModel!
  private var mockHealthKit: MockHealthKitManager!

  override func setUp() async throws {
    mockHealthKit = MockHealthKitManager()
    viewModel = StressViewModel(healthKit: mockHealthKit)
  }

  func testMeasureStress() async throws {
    mockHealthKit.mockHRV = HRVMeasurement(value: 50)
    await viewModel.measureStress()
    XCTAssertNotNil(viewModel.currentStress)
  }
}
```

### Test Doubles

```swift
// Mock: Return preset values
final class MockHealthKitManager: HealthKitServiceProtocol {
  var mockHRV: HRVMeasurement?
  func fetchLatestHRV() async throws -> HRVMeasurement? { mockHRV }
}

// Stub: Minimal implementation
final class StubRepository: StressRepositoryProtocol {
  var measurements: [StressMeasurement] = []
  func save(_ m: StressMeasurement) async throws { measurements.append(m) }
}
```

---

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **8 SPM packages** (2 direct: Chat, SwiftUICharts) | Chat UI + charting capabilities without reinventing | Dependency management overhead |
| **SupabaseLLMService** (Edge Functions + SSE) | **Sole production LLM** — Apple Intelligence on-device fallback removed; configurable via `SupabaseConfig` (B1 resolved Jun 7) | Chat context (not raw health data) sent to Supabase Edge Functions |
| **Local-first architecture** | Works offline, fast responsiveness | Eventual consistency |
| **MVVM + Protocols** | Testability, loose coupling | More boilerplate |
| **@Observable macro** | Modern, iOS 17+ reactive | Excludes iOS 16 |
| **Centralized AppIconSystem** (PR #44) | Single source of truth for every icon; design-spec alignment | Central enum must stay in sync with `design/icon-system.html` |
| **SVG-backed character assets** (PR #45) | Crisp at any size; design fidelity; `preserves-vector-representation: true` | Mood-reactivity delegated to a separate animation layer (StressBuddyIllustration) |
| **5-level stress scale** (incl. Severe) | Finer-grained feedback; WCAG dual-coding (color + icon + pattern) | More categories to localize/illustrate |
| **AppRouter + Route enum** (Jun 2026) | Centralized navigation state, deep links, cross-tab routing; Codable paths for state restoration | One more indirection for simple pushes |
| **PaywallController** (Jun 2026) | Single source of truth for full-screen paywall from anywhere; no-op for premium users | Must be injected at app root |
| **Watch list-based navigation** (Jul 2026) | HIG-compliant (2–4 page limit); every screen one tap away | Replaces discoverable swipe paging |

---

**Next:** See `system-architecture-platform.md` for CloudKit, Watch, widgets, and security details.
**Maintained By:** Phuong Doan
**Version:** 1.0 Production
**Last Updated:** July 19, 2026