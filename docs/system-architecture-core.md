# System Architecture: Core Layers

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Data Flow:** Unidirectional (Models -> Services -> ViewModels -> Views)
**Section:** MVVM, data flow, core services, protocols
**Last Updated:** April 25, 2026

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                         │
│  (Dashboard, Action, Trends, Breathing, Settings, Chat) │
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
| `SettingsViewModel.swift` | App configuration state |
| `DataManagementViewModel.swift` | Export, delete, reset operations |
| `BreathingViewModel.swift` | Breathing exercise state |

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
**Files:** `Services/Algorithm/` (10 files, 656 LOC)
- `MultiFactorStressCalculator.swift` (104 LOC) - Orchestrates 5 factors
- `StressCalculator.swift` (118 LOC) - Legacy 2-factor calculator
- `BaselineCalculator.swift` (97 LOC) - 30-day baseline adaptation
- `StressFactor.swift` (22 LOC) - Protocol for individual factors
- `FactorCalibrator.swift` (56 LOC) - Weight adjustment
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

#### LLM Service
**Files:** `Services/LLM/` (7 files, ~500+ LOC)

Protocol-based LLM integration with on-device and cloud backends.

```swift
protocol LLMServiceProtocol: Sendable {
    func isAvailable() -> Bool
    func send(messages: [ChatMessage], systemPrompt: String)
        async throws -> AsyncThrowingStream<String, Error>
}
```

| Implementation | Platform | Transport | Model |
|---------------|----------|-----------|-------|
| `AppleIntelligenceService` | iOS 26+ (on-device) | Foundation Models framework | System default |
| `CloudLLMService` | All iOS (network) | HTTP/SSE to self-hosted FastAPI gateway | glm-4.7-flash |

**NEW - Apr 2026:**
- `SSEParser.swift` - Server-Sent Events streaming parser
- `LLMAPITarget.swift` - API configuration for cloud LLM endpoints
- **Hardcoded endpoint configuration** (removed server config UI)

**Supporting Types:**
- `ChatContextBuilder` -- builds system prompts with live health data, "AI Kitten" persona (~600 tokens)
- `ChatQuickActions` -- predefined prompt suggestions contextualized by stress level
- `LLMServiceError` -- typed errors: unavailable, exceededContext, guardrailViolation, rateLimited, refused, concurrentRequests, decodingFailure, cancelled, unknown

**Data Flow:**
```
ChatViewModel → ChatContextBuilder.buildSystemPrompt(stress:baseline:history:)
             → LLMServiceProtocol.send(messages:systemPrompt:)
             → AsyncThrowingStream<String, Error> (token-by-token streaming)
```

**Persistence:** Chat data is session-only (in-memory `[ChatMessage]` array). No SwiftData persistence. Messages are lost on app restart.

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
- `StressCategory` - Enum (Relaxed, Mild, Moderate, High)
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
| **Zero external dependencies** | Privacy, control, reduced bloat | More code to maintain |
| **CloudLLMService gateway** | Provides LLM fallback for pre-iOS 26 devices | Connects to self-hosted FastAPI endpoint; chat context (not raw health data) sent externally |
| **Local-first architecture** | Works offline, fast responsiveness | Eventual consistency |
| **MVVM + Protocols** | Testability, loose coupling | More boilerplate |
| **@Observable macro** | Modern, iOS 17+ reactive | Excludes iOS 16 |
| **Hardcoded LLM endpoint** | Simplified configuration, removed UI complexity | Requires deployment updates for endpoint changes |

---

**Next:** See `system-architecture-platform.md` for CloudKit, Watch, widgets, and security details.
**Maintained By:** Phuong Doan
**Version:** 1.0 Production
**Last Updated:** April 25, 2026