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

#### Triple Redundancy System (Phase 3)

**WCAG 2.1 AAA Compliance with Color + Icon + Pattern:**

```
StressCategory
    │
    ├─ color ──────────────▶ Visual Indicator (Primary)
    ├─ icon ───────────────▶ Shape Indicator (Secondary)
    ├─ pattern (NEW) ──────▶ Texture Indicator (Tertiary)
    └─ accessibilityDescription ──▶ VoiceOver
```

**Pattern Overlay System Architecture:**

```
┌─────────────────────────────────────────────────────┐
│                 Pattern Overlay Layer                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Diagonal │  │   Dots   │  │Crosshatch│          │
│  │  Lines   │  │  Pattern │  │  Pattern │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
        ▼             ▼             ▼
┌─────────────────────────────────────────────────────┐
│              Rendering Engine                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   Path   │  │  Canvas  │  │   Path   │          │
│  │  Stroke  │  │   Fill   │  │  Stroke  │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
        ▼             ▼             ▼
    Diagonal       Dot Grid     H+V Lines
    (8pt spacing)  (8pt grid)   (6pt spacing)
```

**Pattern Specifications:**

```swift
enum StressPattern {
    case solid       // Relaxed: No pattern
    case diagonal    // Mild: 45° lines, 1pt stroke, 8pt spacing
    case dots        // Moderate: 2pt circles, 8pt grid
    case crosshatch  // High: H+V lines, 1pt stroke, 6pt grid

    func overlay(color: Color, opacity: Double = 0.3) -> some View
}
```

**Pattern Rendering Flow:**

```
User Request
    │
    ▼
StressCategory.pattern
    │
    ▼
StressPattern.pattern(for:)
    │
    ├─ Relaxed ──▶ .solid ─────▶ EmptyView (no overlay)
    ├─ Mild ─────▶ .diagonal ──▶ DiagonalLinesView (Path)
    ├─ Moderate ─▶ .dots ──────▶ DotsView (Canvas)
    └─ High ─────▶ .crosshatch ▶ CrosshatchView (Path)
```

#### High Contrast Mode Architecture (Phase 3)

**System Integration:**

```
iOS Accessibility Setting
    "Differentiate Without Color"
    │
    ▼
SwiftUI Environment
    @Environment(\.accessibilityDifferentiateWithoutColor)
    │
    ├─ true ──▶ Apply 2pt borders
    │           Color.primary (adapts to light/dark)
    │
    └─ false ─▶ No additional borders
```

**High Contrast Modifiers:**

```swift
// Interactive Elements
Button("Measure") { }
    .highContrastBorder(interactive: true, cornerRadius: 10)
    // → Adds 2pt strokeBorder when enabled

// Cards
VStack { }
    .highContrastCard(backgroundColor: .white, cornerRadius: 12)
    // → Adds 2pt border + ensures background

// Buttons (styled)
MeasureButton { }
    .highContrastButton(style: .primary)
    // → Primary: 2pt Color.primary border
```

**Border Application Flow:**

```
View Rendering
    │
    ▼
Check Environment
    │
    ├─ differentiateWithoutColor == true
    │   │
    │   ▼
    │   Apply Border:
    │   RoundedRectangle(cornerRadius: radius)
    │       .strokeBorder(Color.primary, lineWidth: 2)
    │
    └─ differentiateWithoutColor == false
        │
        ▼
        No border overlay
```

#### Dynamic Type Scaling Architecture (Phase 3)

**Scaling System:**

```
System Dynamic Type Setting
    │
    ▼
@Environment(\.dynamicTypeSize)
    │
    ├─ xSmall ───────▶ 0.8x multiplier
    ├─ small ────────▶ 0.9x
    ├─ medium ───────▶ 1.0x (base)
    ├─ large ────────▶ 1.1x
    ├─ xLarge ───────▶ 1.2x
    ├─ xxLarge ──────▶ 1.3x
    ├─ xxxLarge ─────▶ 1.4x
    ├─ accessibility1 ▶ 1.6x
    ├─ accessibility2 ▶ 1.8x
    ├─ accessibility3 ▶ 2.0x
    ├─ accessibility4 ▶ 2.3x
    └─ accessibility5 ▶ 2.6x
```

**Scaling Modifiers:**

```swift
// Basic scalable text
Text("Content")
    .scalableText(minimumScale: 0.75)
    // → minimumScaleFactor + lineLimit(nil)

// Adaptive sizing
Text("72")
    .adaptiveTextSize(72, weight: .bold)
    // → Applies multiplier based on dynamicTypeSize

// Limited scaling (critical UI)
VStack { }
    .limitedDynamicType()
    // → .dynamicTypeSize(...DynamicTypeSize.accessibility3)

// Comprehensive
VStack { }
    .accessibleDynamicType(minimumScale: 0.75, maxDynamicTypeSize: .accessibility3)
```

**Scaling Flow:**

```
Text("Stress Level")
    │
    ▼
.scalableText(minimumScale: 0.75)
    │
    ├─ Apply minimumScaleFactor(0.75)
    ├─ Set lineLimit(nil) // Allow wrapping
    │
    ▼
Rendered Text
    (scales with system setting, wraps if needed)
```

#### VoiceOver Architecture (Enhanced Phase 3)

**Accessibility Label Flow:**

```
UI Element
    │
    ├─ .accessibilityLabel("What is it?")
    ├─ .accessibilityValue("Current state")
    ├─ .accessibilityHint("What happens?")
    ├─ .accessibilityAddTraits(.isButton / .isHeader)
    └─ .accessibilityElement(children: .combine)
        │
        ▼
    VoiceOver Announcement
```

**Combined Elements Pattern:**

```swift
HStack {
    Image(systemName: "heart.fill")
        .accessibilityHidden(true)  // Decorative
    VStack {
        Text("Live Heart Rate")
        Text("\(heartRate) bpm")
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Live heart rate")
.accessibilityValue("\(heartRate) beats per minute")
```

**Label Best Practices:**

```
Component Type → Accessibility Treatment
─────────────────────────────────────────
Stress Indicator → Label + Value + Hint
Button          → Label + Hint
Card            → Combined children + Label
Header          → Label + .isHeader trait
Decorative Icon → .accessibilityHidden(true)
```

#### Color Blindness Testing Architecture (DEBUG Only)

**Simulation System:**

```
#if DEBUG
┌─────────────────────────────────────────────────────┐
│          Color Blindness Simulator                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │Deutera-  │  │Prota-    │  │Trita-    │          │
│  │nopia     │  │nopia     │  │nopia     │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
        ▼             ▼             ▼
    Transformation Matrices
        │
        ▼
    Simulated Color Output
#endif
```

**Transformation Flow:**

```
Original Color (RGB)
    │
    ▼
Extract components (r, g, b, a)
    │
    ▼
Apply transformation matrix:
    • Deuteranopia: r' = 0.625r + 0.375g
    • Protanopia:   r' = 0.567r + 0.433g
    • Tritanopia:   b' = 0.433r + 0.567b
    │
    ▼
Color(.sRGB, red: r', green: g', blue: b', opacity: a)
```

**Preview Integration:**

```swift
#if DEBUG
#Preview("Color Blindness Tests") {
    ColorBlindnessPreviewContainer {
        StressIndicatorView(category: .moderate)
    }
    // → Shows: Normal, Deuteranopia, Protanopia, Tritanopia
}
#endif
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

### Accessibility Layer File Locations (Phase 3)

```
StressMonitor/StressMonitor/
├── Theme/
│   ├── Color+Wellness.swift       // Wellness colors
│   ├── Color+Extensions.swift     // Delegates to StressCategory
│   ├── Gradients.swift            // Gradient utilities
│   └── Font+WellnessType.swift   // Custom typography
│
├── Utilities/ (NEW - Phase 3)
│   ├── PatternOverlay.swift       // Pattern overlay system
│   ├── HighContrastModifier.swift // High contrast borders
│   ├── DynamicTypeScaling.swift   // Dynamic Type scaling
│   └── ColorBlindnessSimulator.swift // DEBUG testing tool
│
├── Models/
│   └── StressCategory.swift       // Enhanced with pattern descriptions
│
└── Fonts/
    └── README.md                  // Font installation guide
```

**watchOS Synchronization:**

```
StressMonitorWatch Watch App/
├── Theme/
│   └── Color+Extensions.swift     // Synchronized with iOS
└── Models/
    └── StressCategory.swift       // Pattern descriptions synced
```

### Testing Strategy

**Theme Layer Tests (Phase 1):**

- ✅ Color contrast ratios (WCAG AA/AAA)
- ✅ Dark mode color variants
- ✅ High contrast mode activation
- ✅ Font fallback behavior
- ✅ Dynamic Type scaling
- ✅ Gradient opacity calculations
- ✅ VoiceOver label generation

**Accessibility Layer Tests (Phase 3):**

- ✅ Pattern overlay rendering (diagonal, dots, crosshatch)
- ✅ High contrast border detection
- ✅ Dynamic Type size multipliers
- ✅ VoiceOver label completeness
- ✅ Color blindness simulation (DEBUG)
- ✅ Pattern + color + icon triple redundancy
- ✅ Touch target minimum sizes (44x44pt)

**Test Coverage:**
- Phase 1: 86 unit tests (color, typography, gradients)
- Phase 2: 253 unit tests (character system, animations)
- Phase 3: 315 unit tests (accessibility enhancements)
- **Total: 315/315 tests passing (100%)**

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

### Phase 2: Character System (2026-02-13) ✅

**Character System Architecture:**

New component layer for playful, character-based stress visualization:

```
Character System Layer
├── Models
│   └── StressBuddyMood (5 mood states)
│       ├── Stress level mapping (0-100 → mood)
│       ├── SF Symbol selection
│       ├── Accessory symbols
│       └── Context-aware sizing
│
├── Utilities
│   └── Animation+Wellness
│       ├── Reduce Motion support
│       ├── Wellness animations (breathing, fidget, shake, dizzy)
│       └── Accessible transitions
│
└── Components
    ├── CharacterAnimationModifier
    │   ├── Mood-specific animations
    │   ├── Breathing (sleeping)
    │   ├── Fidget (concerned)
    │   ├── Shake (worried)
    │   └── Dizzy (overwhelmed)
    │
    └── StressCharacterCard
        ├── Character display
        ├── Stress level number
        ├── Optional HRV value
        └── Accessory positioning
```

**Component Architecture:**

```
StressCharacterCard (View)
    │
    ├─ Uses StressBuddyMood (Model)
    │   ├─ Stress level → Mood mapping
    │   ├─ Symbol + Accessories
    │   └─ Color from StressCategory
    │
    ├─ Applies CharacterAnimationModifier
    │   ├─ Mood-specific animations
    │   └─ Reduce Motion awareness
    │
    └─ Uses Animation+Wellness
        ├─ Returns nil if Reduce Motion enabled
        └─ Wellness timing patterns
```

**Animation Architecture:**

```
@Environment(\.accessibilityReduceMotion) var reduceMotion
    │
    ▼
Animation.wellness(reduceMotion: reduceMotion)
    │
    ├─ Reduce Motion ON  → Returns nil (static)
    └─ Reduce Motion OFF → Returns animation
        │
        ▼
CharacterAnimationModifier
    │
    ├─ Sleeping  → Breathing (4s scale)
    ├─ Calm      → No animation
    ├─ Concerned → Fidget (random offset)
    ├─ Worried   → Shake (rotation ±5°)
    └─ Overwhelmed → Dizzy (360° rotation)
```

**Mood Mapping Logic:**

```swift
// StressBuddyMood.from(stressLevel:)
0-10    → sleeping      (moon.zzz.fill + Z's)
10-25   → calm          (figure.mind.and.body)
25-50   → concerned     (figure.walk.circle + star)
50-75   → worried       (exclamationmark.triangle.fill + drops)
75-100  → overwhelmed   (flame.fill + drops + stars)
```

**Cross-Platform Sizing:**

```swift
enum CharacterContext {
    case dashboard  // 120pt symbol, 36pt accessories
    case widget     // 80pt symbol, 24pt accessories
    case watchOS    // 60pt symbol, 18pt accessories
}
```

**Integration with MVVM:**

```
View (StressCharacterCard)
    ↓
Receives StressResult from ViewModel
    ↓
Maps stressLevel → StressBuddyMood
    ↓
Selects SF Symbol + Color + Accessories
    ↓
Applies CharacterAnimationModifier
    ↓
Respects Reduce Motion Environment
    ↓
Renders Animated Character
```

**Accessibility Features:**

1. **Reduce Motion Support**
   - All animations return `nil` when Reduce Motion enabled
   - Static fallback automatically applied
   - No manual environment checks needed in views

2. **VoiceOver Integration**
   - Character mood accessible descriptions
   - Stress level value announcements
   - HRV value reading (when present)

3. **Dual Coding Compliance**
   - Character symbol (visual)
   - Mood color (visual)
   - Accessories (visual)
   - VoiceOver labels (non-visual)

**File Locations:**

```
StressMonitor/StressMonitor/
├── Models/
│   └── StressBuddyMood.swift        // NEW - Mood states
│
├── Utilities/
│   └── Animation+Wellness.swift     // NEW - Animation utilities
│
└── Components/
    └── Character/
        ├── CharacterAnimationModifier.swift   // NEW - Animations
        └── StressCharacterCard.swift          // NEW - Card component
```

**Testing Coverage:**

- ✅ Mood mapping tests (0-100 → 5 moods)
- ✅ Animation Reduce Motion tests
- ✅ Accessory layout tests (circular positioning)
- ✅ VoiceOver label validation
- ✅ Context sizing tests
- ✅ Dark mode rendering
- ✅ 253/254 tests passing (99.6%)

**Architectural Benefits:**

- ✅ SF Symbols composition (no custom assets)
- ✅ Full Reduce Motion compliance (WCAG 2.1)
- ✅ Mood-driven animation system
- ✅ Context-aware sizing (iOS/watch/widget)
- ✅ Testable component architecture
- ✅ Reusable across platforms

---

---

## Phase 3: Accessibility Enhancements Architecture

### Pattern Overlay Layer

**Component Hierarchy:**

```
PatternOverlay.swift
├── StressPattern enum
│   ├── .solid (no pattern)
│   ├── .diagonal (DiagonalLinesView)
│   ├── .dots (DotsView)
│   └── .crosshatch (CrosshatchView)
├── Pattern rendering
│   ├── Path-based (diagonal, crosshatch)
│   └── Canvas-based (dots)
└── View modifiers
    ├── .stressPattern(_:color:)
    └── .stressPattern(for:)
```

**Rendering Performance:**

| Pattern | Technique | Complexity | Performance |
|---------|----------|-----------|-------------|
| Solid | EmptyView | O(1) | Instant |
| Diagonal | Path stroke | O(n) lines | Fast |
| Dots | Canvas fill | O(n×m) grid | Optimized |
| Crosshatch | Path stroke | O(2n) lines | Fast |

### High Contrast Layer

**Modifier Hierarchy:**

```
HighContrastModifier.swift
├── HighContrastBorderModifier
│   └── Generic border overlay
├── HighContrastCardModifier
│   └── Card with border + background
└── HighContrastButtonModifier
    ├── .primary (Color.primary border)
    ├── .secondary (Color.secondary border)
    └── .tertiary (Color.primary.opacity(0.5))
```

**Environment Detection:**

```swift
@Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

// Automatic border application
if differentiateWithoutColor {
    RoundedRectangle(cornerRadius: radius)
        .strokeBorder(Color.primary, lineWidth: 2)
}
```

### Dynamic Type Layer

**Modifier Hierarchy:**

```
DynamicTypeScaling.swift
├── DynamicTypeScalingModifier
│   └── minimumScaleFactor + lineLimit(nil)
├── AdaptiveTextSizeModifier
│   └── Dynamic size calculation (0.8x-2.6x)
├── LimitedDynamicTypeModifier
│   └── Max: accessibility3
└── AccessibleDynamicTypeModifier
    └── Combined: limit + scale + wrap
```

**Size Calculation Flow:**

```
Base Size (e.g., 72pt)
    │
    ▼
Check @Environment(\.dynamicTypeSize)
    │
    ├─ xSmall ───▶ 72 × 0.8 = 57.6pt
    ├─ medium ───▶ 72 × 1.0 = 72pt
    ├─ xLarge ───▶ 72 × 1.2 = 86.4pt
    └─ accessibility3 ▶ 72 × 2.0 = 144pt
```

### Color Blindness Simulator (DEBUG)

**Simulation Architecture:**

```
#if DEBUG
ColorBlindnessSimulator.swift
├── ColorBlindnessType enum
│   ├── .deuteranopia (transformation matrix)
│   ├── .protanopia (transformation matrix)
│   ├── .tritanopia (transformation matrix)
│   └── .normal (no transformation)
├── Color transformation
│   └── RGB matrix multiplication
└── Preview utilities
    ├── ColorBlindnessSimulatorModifier
    ├── ColorBlindnessPreviewContainer
    └── StressColorValidator
#endif
```

**Transformation Matrices:**

| Type | Red Transform | Green Transform | Blue Transform |
|------|--------------|----------------|----------------|
| Deuteranopia | 0.625r + 0.375g | 0.7r + 0.3g | b |
| Protanopia | 0.567r + 0.433g | 0.558r + 0.442g | b |
| Tritanopia | 0.95r + 0.05g | g | 0.433r + 0.567b |

### Accessibility Integration Points

**View Hierarchy:**

```
SwiftUI Views
    │
    ├─ Pattern Overlays ──▶ .stressPattern(for:)
    ├─ High Contrast ─────▶ .highContrastBorder()
    ├─ Dynamic Type ──────▶ .scalableText()
    ├─ VoiceOver ─────────▶ .accessibilityLabel()
    └─ Color Blindness ───▶ .simulateColorBlindness() (DEBUG)
```

**Architecture Benefits:**

- ✅ Modular accessibility layers
- ✅ Environment-driven behavior
- ✅ Performance optimized (Path/Canvas)
- ✅ WCAG 2.1 AAA compliance
- ✅ DEBUG-only testing tools
- ✅ iOS/watchOS synchronized

---

**Document Version:** 3.0 (Phase 3 Complete)
**Last Updated:** 2026-02-13
**Accessibility Compliance:** WCAG 2.1 Level AAA
