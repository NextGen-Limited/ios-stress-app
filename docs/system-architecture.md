# StressMonitor - System Architecture

**Created by:** Phuong Doan
**Last Updated:** 2026-02-13
**Version:** 1.0
**Architecture:** MVVM + Protocol-Oriented Design

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [MVVM Pattern Implementation](#mvvm-pattern-implementation)
- [Theme Layer Architecture](#theme-layer-architecture)
- [Data Flow Architecture](#data-flow-architecture)
- [Service Layer Architecture](#service-layer-architecture)
- [CloudKit Sync Architecture](#cloudkit-sync-architecture)
- [Widget Integration Architecture](#widget-integration-architecture)
- [Protocol-Based Design](#protocol-based-design)
- [Concurrency Model](#concurrency-model)
- [Cross-Platform Architecture](#cross-platform-architecture)

---

## Architecture Overview

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  SwiftUI   │  │  Widgets   │  │ Watch Face │            │
│  │   Views    │  │ (WidgetKit)│  │Complications│            │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘            │
└────────┼────────────────┼────────────────┼──────────────────┘
         │                │                │
         │ Uses Theme     │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                      Theme Layer (NEW)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │    Colors    │ │  Typography  │ │  Gradients   │        │
│  │  (Wellness)  │ │(Lora+Raleway)│ │  (Wellness)  │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                   Presentation Layer                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │ ViewModels │  │   Widget   │  │Complication│            │
│  │(@Observable)│  │ Providers  │  │ Providers  │            │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘            │
└────────┼────────────────┼────────────────┼──────────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐    │
│  │HealthKit │ │Algorithm │ │Repository│ │  CloudKit  │    │
│  │  Manager │ │Calculator│ │  (Data)  │ │   Manager  │    │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬──────┘    │
└───────┼────────────┼────────────┼─────────────┼────────────┘
        │            │            │             │
        ▼            ▼            ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐    │
│  │HealthKit │ │  Models  │ │SwiftData │ │  CloudKit  │    │
│  │  Store   │ │ (Struct/ │ │  (@Model)│ │  (iCloud)  │    │
│  │ (Apple)  │ │  Enum)   │ │          │ │            │    │
│  └──────────┘ └──────────┘ └──────────┘ └────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Architectural Principles

1. **Separation of Concerns**: Clear boundaries between UI, logic, and data
2. **Offline-First**: Local data storage with optional cloud sync
3. **Protocol-Oriented**: All services defined by protocols
4. **Dependency Injection**: Constructor-based DI throughout
5. **Unidirectional Data Flow**: Data flows down, events flow up
6. **Actor Isolation**: Thread-safe with @MainActor and Sendable
7. **Privacy-First**: No external servers, E2E encrypted sync

---

## MVVM Pattern Implementation

### Component Responsibilities

#### Model

Pure data structures, no business logic:

```swift
// SwiftData Model (Persistent)
@Model
public final class StressMeasurement {
    public var timestamp: Date
    public var stressLevel: Double
    public var hrv: Double
    public var restingHeartRate: Double
    public var categoryRawValue: String

    // CloudKit sync metadata
    public var isSynced: Bool
    public var cloudKitRecordName: String?
    public var deviceID: String
}

// Transient Result (Non-persistent)
struct StressResult: Sendable {
    let level: Double
    let category: StressCategory
    let confidence: Double
    let hrv: Double
    let heartRate: Double
    let timestamp: Date
}
```

#### ViewModel

Orchestrates services, manages presentation state:

```swift
@Observable
@MainActor
final class DashboardViewModel {
    // MARK: - State

    var currentStress: StressResult?
    var todayHRV: Double?
    var weeklyTrend: TrendDirection = .stable
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies (Protocol-based)

    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    // MARK: - Initialization (DI)

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    // MARK: - Public Methods

    func refreshStressLevel() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Parallel fetching
            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 10)
            async let baseline = repository.getBaseline()

            let (hrvData, hrData, baselineData) = try await (hrv, hr, baseline)

            // Calculate stress
            currentStress = try await algorithm.calculateStress(
                hrv: hrvData?.value ?? 0,
                heartRate: hrData.first?.value ?? 0,
                baseline: baselineData
            )

            // Save to repository (offline-first)
            if let stress = currentStress {
                let measurement = StressMeasurement(
                    timestamp: stress.timestamp,
                    stressLevel: stress.level,
                    hrv: stress.hrv,
                    restingHeartRate: baselineData.restingHeartRate
                )
                try await repository.save(measurement)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

#### View

UI only, binds to ViewModel:

```swift
struct StressDashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            if let stress = viewModel?.currentStress {
                stressContent(stress)
            } else if viewModel?.isLoading == true {
                LoadingView()
            } else {
                EmptyStateView()
            }
        }
        .task {
            // Setup dependencies (DI)
            setupViewModel()
            await viewModel?.refreshStressLevel()
        }
        .refreshable {
            await viewModel?.refreshStressLevel()
        }
    }

    private func setupViewModel() {
        let repository = StressRepository(modelContext: modelContext)
        let healthKit = HealthKitManager()
        let algorithm = StressCalculator()

        viewModel = DashboardViewModel(
            healthKit: healthKit,
            algorithm: algorithm,
            repository: repository
        )
    }

    @ViewBuilder
    private func stressContent(_ stress: StressResult) -> some View {
        StressRingView(stressLevel: stress.level, category: stress.category)
        QuickStatCard(title: "HRV", value: "\(Int(stress.hrv))ms")
    }
}
```

---

## Theme Layer Architecture

### Design System Components

The Theme layer provides a unified, accessible visual foundation for all UI components. Implemented in Phase 1: Visual Foundation.

#### Layer Structure

```
Theme Layer
├── Colors (Color+Wellness.swift)
│   ├── Wellness Palette (calmBlue, healthGreen, gentlePurple)
│   ├── Stress Category Colors (adaptive light/dark)
│   ├── High Contrast Support (WCAG AAA)
│   └── Dual Coding Utilities (icon, pattern)
│
├── Typography (Font+WellnessType.swift)
│   ├── Custom Fonts (Lora + Raleway)
│   ├── SF Pro Fallback
│   ├── Dynamic Type Support
│   └── Accessibility Modifiers
│
└── Gradients (Gradients.swift)
    ├── Wellness Backgrounds
    ├── Stress Spectrums
    ├── Card Tints
    └── View Modifiers
```

#### Color System Architecture

**Delegation Pattern:**

```
StressCategory (Source of Truth)
         │
         │ Defines
         ▼
    Icon + Pattern
         │
         │ Used by
         ▼
Color+Wellness Extension
         │
         │ Provides
         ▼
   View Modifiers
         │
         │ Applied to
         ▼
    SwiftUI Views
```

**Implementation:**

```swift
// StressCategory.swift (Model Layer)
public enum StressCategory: String, Codable, Sendable, CaseIterable {
    case relaxed, mild, moderate, high

    // Source of truth for visual coding
    public var icon: String {
        case .relaxed: return "leaf.fill"
        case .mild: return "circle.fill"
        case .moderate: return "triangle.fill"
        case .high: return "square.fill"
    }

    public var pattern: String {
        case .relaxed: return "solid fill"
        case .mild: return "diagonal lines"
        case .moderate: return "dots pattern"
        case .high: return "horizontal lines"
    }

    public var color: Color {
        // Adaptive light/dark colors
        switch self {
        case .relaxed:
            return Color(light: Color(hex: "#34C759"), dark: Color(hex: "#30D158"))
        // ...
        }
    }
}
```

**Usage in Views:**

```swift
struct StressIndicator: View {
    let category: StressCategory

    var body: some View {
        HStack {
            // Icon (dual coding)
            Image(systemName: category.icon)

            // Text (dual coding)
            Text(category.displayName)
        }
        // Color with automatic high contrast
        .accessibleStressColor(for: category)
        // VoiceOver description
        .accessibilityLabel(category.accessibilityDescription)
    }
}
```

#### Typography System Architecture

**Font Loading Strategy:**

```
Font Request
    │
    ▼
Check if Custom Fonts Available
    │
    ├─ YES ──▶ Use Lora/Raleway
    │
    └─ NO ───▶ Fallback to SF Pro
         │
         ▼
Apply Dynamic Type Scaling
         │
         ▼
Return Font Instance
```

**Font Hierarchy:**

```swift
// Headings (Lora - Organic wellness vibe)
Font.WellnessType.heroNumber     // 72pt Bold  → SF .system(72, .bold)
Font.WellnessType.largeMetric    // 48pt Bold  → SF .system(48, .bold)
Font.WellnessType.cardTitle      // 28pt Bold  → SF .title
Font.WellnessType.sectionHeader  // 22pt SemiBold → SF .title2

// Body (Raleway - Elegant simplicity)
Font.WellnessType.body           // 17pt Regular → SF .body
Font.WellnessType.bodyEmphasized // 17pt SemiBold → SF .body.weight(.semibold)
Font.WellnessType.caption        // 13pt Regular → SF .caption
Font.WellnessType.caption2       // 11pt Regular → SF .caption2
```

**Dynamic Type Support:**

```swift
extension View {
    func accessibleWellnessType(lines: Int? = nil) -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .minimumScaleFactor(0.7)
            .lineLimit(lines)
    }
}
```

#### Gradient System Architecture

**Gradient Types:**

| Gradient | Purpose | Colors | Opacity |
|----------|---------|--------|---------|
| `calmWellness` | App background | Blue→Green→Clear | 100%→60%→0% |
| `stressSpectrum(for:)` | Chart fills | Category color | 60%→30%→10% |
| `stressBackgroundTint(for:)` | Card backgrounds | Category color | 8%→4%→0% |
| `mindfulness` | Meditation UI | Purple→Blue | 80%→60% |
| `relaxation` | Calm states | Green gradients | 70%→50% |

**View Modifiers:**

```swift
// Background gradient
.wellnessBackground()

// Stress card with tint
.stressCard(for: category, baseColor: .surface)

// Manual stress background
.stressBackground(for: category)
```

### Theme Layer Integration with MVVM

```
View (SwiftUI)
    │
    │ Uses Theme
    ▼
Theme Layer
    ├─ Color.Wellness.*
    ├─ Font.WellnessType.*
    └─ LinearGradient.*
    │
    │ Applied to
    ▼
UI Components
    ├─ StressRingView
    ├─ Cards
    └─ Buttons
    │
    │ Binds to
    ▼
ViewModel (Presentation)
    │
    │ Coordinates
    ▼
Services (Business Logic)
```

### Accessibility Architecture

**Dual Coding Flow:**

```
StressCategory
    │
    ├─ color ──────▶ Visual Indicator
    ├─ icon ───────▶ Shape Indicator
    ├─ pattern ────▶ Texture Indicator
    └─ accessibilityDescription ──▶ VoiceOver
```

**High Contrast Mode:**

```
System High Contrast Setting
    │
    ▼
Environment Check
    │
    ├─ Enabled ──▶ Use darker colors (7:1 ratio)
    │
    └─ Disabled ─▶ Use standard colors (4.5:1 ratio)
```

**Implementation:**

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

if reduceTransparency {
    // Use solid colors
} else {
    // Use gradients
}
```

### Theme File Locations

```
StressMonitor/StressMonitor/
├── Theme/
│   ├── Color+Wellness.swift       // NEW - Wellness colors
│   ├── Color+Extensions.swift     // MODIFIED - Delegates to StressCategory
│   ├── Gradients.swift            // NEW - Gradient utilities
│   └── Font+WellnessType.swift   // NEW - Custom typography
│
├── Models/
│   └── StressCategory.swift       // MODIFIED - Enhanced dual coding
│
└── Fonts/
    └── README.md                  // NEW - Font installation guide
```

**watchOS Synchronization:**

```
StressMonitorWatch Watch App/
├── Theme/
│   └── Color+Extensions.swift     // NEW - Synchronized with iOS
└── Models/
    └── StressCategory.swift       // SYNCHRONIZED - Same implementation
```

### Testing Strategy

**Theme Layer Tests:**

- ✅ Color contrast ratios (WCAG AA/AAA)
- ✅ Dark mode color variants
- ✅ High contrast mode activation
- ✅ Font fallback behavior
- ✅ Dynamic Type scaling
- ✅ Gradient opacity calculations
- ✅ VoiceOver label generation

**86 Unit Tests Created:**
- Color system tests (18 tests)
- Typography tests (22 tests)
- Gradient tests (14 tests)
- StressCategory tests (32 tests)

---

### MVVM Data Flow

```
User Action (Tap "Measure")
         │
         ▼
View calls viewModel.refreshStressLevel()
         │
         ▼
ViewModel coordinates services:
  1. HealthKit.fetchLatestHRV()
  2. HealthKit.fetchHeartRate()
  3. Repository.getBaseline()
         │
         ▼
ViewModel calculates stress:
  Algorithm.calculateStress(hrv, hr, baseline)
         │
         ▼
ViewModel saves measurement:
  Repository.save(measurement)
         │
         ▼
Repository saves locally:
  SwiftData.insert(measurement)
         │
         ▼
Repository syncs to cloud (best-effort):
  CloudKitManager.saveMeasurement(measurement)
         │
         ▼
ViewModel updates state:
  currentStress = result
         │
         ▼
View re-renders:
  StressRingView displays new stress level
```

---

## Data Flow Architecture

### Offline-First Pattern

```
User Action
    ↓
Write to Local Storage (SwiftData)
    ↓
Commit Transaction
    ↓
Trigger Background Sync (CloudKit)
    ↓
Update Sync Metadata on Success
```

### Read Path

```
Query Local Storage (SwiftData)
    ↓
Return Immediately (Offline-first)
    ↓
Background: Check CloudKit for Updates
    ↓
Merge Remote Changes (Conflict Resolution)
    ↓
Update SwiftData with Remote Data
```

### Stress Measurement Flow

```
┌──────────────────────────────────────────────────────────┐
│                    HealthKit (System)                     │
│  ┌───────────────┐           ┌────────────────┐         │
│  │  HRV Samples  │           │ Heart Rate     │         │
│  │  (SDNN, ms)   │           │ Samples (bpm)  │         │
│  └───────┬───────┘           └────────┬───────┘         │
└──────────┼─────────────────────────────┼────────────────┘
           │                             │
           ▼                             ▼
    ┌──────────────────────────────────────────┐
    │      HealthKitManager (Service)          │
    │  - fetchLatestHRV() → HRVMeasurement    │
    │  - fetchHeartRate() → [HeartRateSample] │
    └───────────────┬──────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────────────┐
    │     StressCalculator (Algorithm)         │
    │  Input: HRV (ms), HR (bpm), Baseline    │
    │  Output: StressResult (level, category)  │
    │  Formula:                                 │
    │    - Normalize HRV & HR                   │
    │    - Apply power scaling (HRV^0.8)       │
    │    - Weight (HRV 70%, HR 30%)            │
    │    - Output: 0-100 scale                  │
    └───────────────┬──────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────────────┐
    │      StressRepository (Data)             │
    │  - Save to SwiftData (local)             │
    │  - Trigger CloudKit sync (background)    │
    └───────────────┬──────────────────────────┘
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
┌────────────────┐    ┌────────────────┐
│   SwiftData    │    │   CloudKit     │
│  (Local Store) │    │  (iCloud Sync) │
│  - Persistent  │    │  - E2E Encrypt │
│  - Fast access │    │  - Multi-device│
└────────────────┘    └────────────────┘
```

---

## Service Layer Architecture

### Service Protocols

```swift
// HealthKit Integration
protocol HealthKitServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func fetchLatestHRV() async throws -> HRVMeasurement?
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
    func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement]
    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?>
}

// Stress Calculation
protocol StressAlgorithmServiceProtocol: Sendable {
    func calculateStress(hrv: Double, heartRate: Double, baseline: PersonalBaseline) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
}

// Data Persistence
protocol StressRepositoryProtocol: Sendable {
    func save(_ measurement: StressMeasurement) async throws
    func fetchRecent(limit: Int) async throws -> [StressMeasurement]
    func fetchAll() async throws -> [StressMeasurement]
    func delete(_ measurement: StressMeasurement) async throws
    func getBaseline() async throws -> PersonalBaseline
}

// Cloud Synchronization
protocol CloudKitServiceProtocol: Sendable {
    var syncStatus: SyncStatus { get }
    var lastSyncDate: Date? { get }
    func saveMeasurement(_ measurement: StressMeasurement) async throws
    func fetchMeasurements(since: Date?) async throws -> [StressMeasurement]
    func deleteMeasurement(_ measurement: StressMeasurement) async throws
    func performFullSync() async throws
    func checkAccountStatus() async throws -> CloudKitAccountStatus
}
```

### Service Interaction Diagram

```
┌────────────────┐
│   ViewModel    │
└───────┬────────┘
        │
        │ Coordinates
        │
┌───────▼────────────────────────────────────┐
│         Service Layer (Protocols)          │
├────────┬─────────┬──────────┬──────────────┤
│        │         │          │              │
▼        ▼         ▼          ▼              ▼
┌──────┐ ┌──────┐ ┌────────┐ ┌─────────┐ ┌────────┐
│Health│ │Stress│ │Repository│ │CloudKit│ │Baseline│
│ Kit  │ │Algo  │ │         │ │ Manager│ │Calculator│
└───┬──┘ └───┬──┘ └────┬───┘ └────┬────┘ └────┬───┘
    │        │         │          │          │
    │        │         │          │          │
    ▼        ▼         ▼          ▼          ▼
┌──────────────────────────────────────────────┐
│              Data Sources                     │
│  ┌────────┐ ┌─────────┐ ┌────────────────┐ │
│  │HealthKit│ │SwiftData│ │CloudKit (iCloud)│ │
│  └────────┘ └─────────┘ └────────────────┘ │
└──────────────────────────────────────────────┘
```

### HealthKit Integration

```swift
@MainActor
@Observable
final class HealthKitManager: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        let hrvType = HKQuantityType.heartRateVariabilitySDNN
        let sortDescriptor = SortDescriptor(\.endDate, order: .reverse)

        return try await withCheckedThrowingContinuation { continuation in
            var queryReturned = false

            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !queryReturned else { return }
                queryReturned = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let sample = samples?.first as? HKQuantitySample {
                    let hrv = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                    continuation.resume(returning: HRVMeasurement(value: hrv, timestamp: sample.endDate))
                } else {
                    continuation.resume(returning: nil)
                }
            }

            healthStore.execute(query)
        }
    }
}
```

---

## CloudKit Sync Architecture

### Sync Strategy

```
┌─────────────────────────────────────────────────────────┐
│              Offline-First Sync Pattern                  │
└─────────────────────────────────────────────────────────┘

Write Path:
1. User action (measure stress)
2. Write to SwiftData (local)        ← Always succeeds
3. Commit transaction
4. Trigger CloudKit sync (async)     ← Best-effort
5. Update isSynced flag on success

Read Path:
1. Query SwiftData (local)            ← Always fast
2. Return results immediately
3. Background: Check CloudKit
4. Merge remote changes
5. Update SwiftData with new data

Conflict Resolution:
- Use cloudKitModTime for comparison
- Most recent modification wins
- Device ID tracks origin
```

### CloudKit Schema

```
Record Type: CD_StressMeasurement

Fields:
├─ timestamp         : Date          (indexed)
├─ stressLevel       : Double
├─ hrv               : Double
├─ restingHeartRate  : Double
├─ category          : String
├─ confidences       : [Double]
├─ deviceID          : String        (indexed)
├─ isDeleted         : Bool
└─ cloudKitModTime   : Date          (indexed)

Indexes:
- timestamp (for date range queries)
- deviceID (for multi-device sync)
- cloudKitModTime (for incremental sync)

Container: CKContainer.default()
Database: privateCloudDatabase (user's private data)
```

### Sync Flow Diagram

```
┌──────────────┐
│  iOS Device  │
└──────┬───────┘
       │
       │ 1. Save locally (SwiftData)
       │
       ▼
┌──────────────────┐
│ StressRepository │
└──────┬───────────┘
       │
       │ 2. Mark as unsynced
       │
       ▼
┌─────────────────────┐
│  CloudKitManager    │
└──────┬──────────────┘
       │
       │ 3. Push to CloudKit
       │
       ▼
┌──────────────────────┐
│   iCloud (CloudKit)  │
│  (E2E Encrypted)     │
└──────┬───────────────┘
       │
       │ 4. Distribute to other devices
       │
       ▼
┌──────────────────┐
│  watchOS Device  │
└──────┬───────────┘
       │
       │ 5. Pull changes
       │
       ▼
┌────────────────────┐
│ WatchCloudKitMgr   │
└──────┬─────────────┘
       │
       │ 6. Merge with local data
       │
       ▼
┌───────────────────┐
│ App Groups Storage│
└───────────────────┘
```

### Conflict Resolution Algorithm

```swift
private func mergeRemoteMeasurement(_ remote: StressMeasurement) async {
    let allMeasurements = try? modelContext.fetch(FetchDescriptor<StressMeasurement>())
    let existing = allMeasurements?.filter {
        $0.timestamp == remote.timestamp && $0.deviceID == remote.deviceID
    }

    if let local = existing?.first {
        // Conflict: Both local and remote versions exist
        if let remoteModTime = remote.cloudKitModTime,
           let localModTime = local.cloudKitModTime,
           remoteModTime > localModTime {
            // Remote is newer - update local
            local.stressLevel = remote.stressLevel
            local.hrv = remote.hrv
            local.restingHeartRate = remote.restingHeartRate
            local.categoryRawValue = remote.categoryRawValue
            local.isSynced = true
            local.cloudKitModTime = remote.cloudKitModTime
        }
        // Else: Keep local version (local is newer)
    } else {
        // No conflict: Insert remote
        modelContext.insert(remote)
        remote.isSynced = true
    }

    try? modelContext.save()
}
```

---

## Widget Integration Architecture

### Widget Data Flow

```
┌─────────────────────────────────────────────────────┐
│                  Main iOS App                        │
│  ┌────────────────────────────────────────────┐    │
│  │         StressRepository.save()            │    │
│  └─────────────────┬──────────────────────────┘    │
└────────────────────┼───────────────────────────────┘
                     │
                     │ Write measurement
                     ▼
┌─────────────────────────────────────────────────────┐
│        App Groups UserDefaults Container             │
│      group.com.stressmonitor.app                     │
│  ┌────────────────────────────────────────────┐    │
│  │  WidgetSharedData (Codable)                │    │
│  │  - stressLevel: Double                      │    │
│  │  - category: StressCategory                 │    │
│  │  - hrv: Double                               │    │
│  │  - heartRate: Double                         │    │
│  │  - timestamp: Date                           │    │
│  └────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Read shared data
                     ▼
┌─────────────────────────────────────────────────────┐
│              Widget Extension                        │
│  ┌────────────────────────────────────────────┐    │
│  │    WidgetProvider.getTimeline()            │    │
│  │  - Fetch latest from App Groups            │    │
│  │  - Generate timeline entries                │    │
│  │  - Schedule next refresh (30 min)          │    │
│  └─────────────────┬──────────────────────────┘    │
└────────────────────┼───────────────────────────────┘
                     │
                     │ Display
                     ▼
┌─────────────────────────────────────────────────────┐
│               Home Screen Widget                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Small   │  │  Medium  │  │  Large   │         │
│  │  Widget  │  │  Widget  │  │  Widget  │         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
```

### Widget Timeline

```swift
struct WidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Fetch latest stress data from App Groups
        let sharedData = WidgetSharedData.fetch()

        let entry = WidgetEntry(
            date: Date(),
            stressLevel: sharedData.stressLevel,
            category: sharedData.category,
            hrv: sharedData.hrv
        )

        // Refresh every 30 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))

        completion(timeline)
    }
}
```

---

## Protocol-Based Design

### Dependency Inversion

```
High-Level Modules (ViewModels)
         │
         │ Depend on abstractions
         ▼
    Protocols (Service Contracts)
         ▲
         │ Implemented by
         │
Low-Level Modules (Concrete Services)
```

### Example

ViewModels depend on protocol abstractions, not concrete implementations. This enables dependency injection and testing with mocks.

---

## Concurrency Model

### Actor Isolation Strategy

```
@MainActor Zone (UI Thread)
├─ ViewModels
├─ HealthKitManager
├─ CloudKitManager
└─ StressRepository

Nonisolated (Any Thread)
├─ StressCalculator (pure functions)
├─ BaselineCalculator (pure functions)
└─ Model structs (Sendable)

Background Tasks
├─ CloudKit sync operations
├─ HealthKit queries
└─ Baseline calculations
```

### Async/Await Flow

ViewModels run on `@MainActor`. Async operations execute on background threads. Use `async let` for parallel fetching. UI updates return to main thread automatically.

---

## Cross-Platform Architecture

### iOS vs watchOS Differences

| Component | iOS | watchOS |
|-----------|-----|---------|
| **Persistence** | SwiftData (@Model) | App Groups UserDefaults |
| **UI Complexity** | Multi-tab, navigation | Single screen |
| **CloudKit Batch** | 10 records | 5 records (battery-aware) |
| **Sync Throttle** | Frequent | 5 minutes minimum |
| **Complications** | Home screen widgets | Watch face complications |
| **Background** | BGAppRefreshTask | None (complications only) |
| **Standalone** | Full independence | Can run without iPhone |

### Shared Code

- **Models**: StressResult, StressCategory, PersonalBaseline
- **Algorithm**: StressCalculator (identical implementation)
- **Protocols**: HealthKitServiceProtocol, StressAlgorithmServiceProtocol

### Platform-Specific Code

- **iOS**: SwiftData repository, BGAppRefreshTask, full navigation
- **watchOS**: App Groups storage, battery optimization, compact UI

---

## Summary

StressMonitor implements a **modern, protocol-oriented MVVM architecture** with:

- **Clear Separation**: Models, ViewModels, Views, Services
- **Offline-First**: Local SwiftData with best-effort CloudKit sync
- **Protocol-Based DI**: Testable, flexible, maintainable
- **Actor Isolation**: Thread-safe with @MainActor and Sendable
- **Cross-Platform**: Shared logic, platform-optimized implementations
- **Privacy-First**: E2E encryption, no external servers

**Key Pattern**: View → ViewModel → Services → Data Layer → External Systems (HealthKit/CloudKit)

---

---

## Recent Updates

### Phase 1: Visual Foundation (2026-02-13) ✅

**Theme Layer Added:**

New architectural layer for unified design system:

1. **Color System** (`Color+Wellness.swift`)
   - Wellness palette (calm blue, health green, gentle purple)
   - Stress category colors with adaptive light/dark modes
   - High contrast support (WCAG AAA 7:1 ratio)
   - Dual coding utilities (color + icon + pattern)

2. **Typography System** (`Font+WellnessType.swift`)
   - Google Fonts integration (Lora + Raleway)
   - Automatic SF Pro fallback
   - Dynamic Type support with accessibility scaling
   - Font status debugging utilities

3. **Gradient System** (`Gradients.swift`)
   - Wellness background gradients
   - Stress spectrum gradients (category-based)
   - Card background tints
   - View modifiers for easy application

4. **Enhanced StressCategory Model**
   - Updated icon system (leaf, circle, triangle, square)
   - Pattern descriptions for color-blind users
   - Accessibility descriptions and VoiceOver support
   - iOS/watchOS synchronization

**Architectural Benefits:**

- ✅ Separation of concerns (Theme as dedicated layer)
- ✅ StressCategory as source of truth for dual coding
- ✅ Automatic fallback mechanisms (fonts, colors)
- ✅ Built-in accessibility compliance (WCAG AAA)
- ✅ Cross-platform consistency (iOS/watchOS)
- ✅ Testable design system (86 unit tests)

**Implementation Details:**

See complete documentation:
- `./docs/implementation-phase-1-visual-foundation.md`
- `./docs/wellness-design-system-quick-reference.md`
- `./docs/design-guidelines.md`

---

**Document Version:** 1.0
**Last Updated:** 2026-02-13
**Lines of Code Count:** Under 800-line target
