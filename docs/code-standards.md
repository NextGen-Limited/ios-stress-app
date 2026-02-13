# StressMonitor - Code Standards & Conventions

**Created by:** Phuong Doan
**Last Updated:** 2026-02-13
**Version:** 1.0
**Language:** Swift 5.9+

---

## Table of Contents

- [Swift Language Standards](#swift-language-standards)
- [File Organization](#file-organization)
- [Naming Conventions](#naming-conventions)
- [Architecture Patterns](#architecture-patterns)
- [State Management](#state-management)
- [Concurrency](#concurrency)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [SwiftUI Conventions](#swiftui-conventions)
- [Wellness Design System Usage](#wellness-design-system-usage)
- [Import Organization](#import-organization)

---

## Swift Language Standards

### Language Version

- **Minimum**: Swift 5.9
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Macros**: @Observable, @Model (iOS 17+)

### Code Style

- **Indentation**: 2 spaces (not tabs)
- **Line Length**: 120 characters maximum (soft limit)
- **Vertical Spacing**: One blank line between methods/properties
- **Trailing Commas**: Required in multi-line arrays/dictionaries
- **Trailing Whitespace**: Remove all trailing whitespace

### Access Control

Use explicit access modifiers:

```swift
// Good
public final class StressMeasurement { }
internal func calculateStress() { }
private let healthKit: HealthKitServiceProtocol

// Avoid
class StressMeasurement { }  // implicit internal
func calculateStress() { }   // implicit internal
```

**Guidelines:**
- `public`: Protocol definitions, shared models
- `internal`: Default for implementation files
- `private`: Helper methods, computed properties
- `fileprivate`: Rarely used, only for extensions in same file

---

## File Organization

### File Structure

Every Swift file follows this order:

```swift
// 1. Import statements (alphabetical, grouped)
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI

// 2. Type definition
@Observable
@MainActor
final class StressViewModel {

    // 3. MARK: - Properties

    // Public properties
    var currentStress: StressResult?
    var isLoading = false

    // Private properties
    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol

    // 4. MARK: - Initialization

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
    }

    // 5. MARK: - Public Methods

    func loadCurrentStress() async { }

    // 6. MARK: - Private Methods

    private func calculateStress() async { }
}

// 7. MARK: - Extensions

extension StressViewModel {
    // Extension methods
}
```

### File Size Guidelines

- **Target**: <200 lines per file
- **Maximum**: 400 lines (split if exceeded)
- **Extract**: Large files into smaller, focused modules
- **Composition**: Use composition over inheritance

### MARK Comments

Use `// MARK:` to organize code sections:

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Helper Methods
```

---

## Naming Conventions

### Files

- **Format**: PascalCase
- **Pattern**: `[Entity][Type].swift`
- **Examples**:
  - `StressMeasurement.swift` (Model)
  - `HealthKitManager.swift` (Service)
  - `DashboardViewModel.swift` (ViewModel)
  - `StressDashboardView.swift` (View)
  - `HealthKitServiceProtocol.swift` (Protocol)

### Types

- **Classes/Structs/Enums**: PascalCase
- **Protocols**: PascalCase with `Protocol` suffix (services) or descriptive name

```swift
// Good
class StressCalculator { }
struct PersonalBaseline { }
enum StressCategory { }
protocol HealthKitServiceProtocol { }

// Avoid
class stressCalculator { }
struct personal_baseline { }
protocol HealthKitService { }  // missing Protocol suffix for services
```

### Variables & Properties

- **Format**: camelCase
- **Booleans**: Start with `is`, `has`, `should`
- **Collections**: Plural nouns

```swift
// Good
var stressLevel: Double
var isLoading: Bool
var hasSynced: Bool
var measurements: [StressMeasurement]
private let healthKit: HealthKitServiceProtocol

// Avoid
var StressLevel: Double
var loading: Bool  // not boolean prefix
var measurement: [StressMeasurement]  // not plural
```

### Methods

- **Format**: camelCase
- **Verbs**: Start with action verb
- **Async**: Use `async` suffix for clarity (optional)

```swift
// Good
func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
func loadCurrentStress() async
func fetchRecent(limit: Int) async throws -> [StressMeasurement]

// Avoid
func StressCalculation() { }
func getStress() { }  // prefer load/fetch for async operations
```

### Constants

- **Format**: camelCase
- **Enums for grouping**: Use nested enums for related constants

```swift
// Good
enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
    }

    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let minTouchTarget: CGFloat = 44
    }
}

// Usage
padding(DesignTokens.Spacing.md)

// Avoid
let SPACING_XS: CGFloat = 4  // SCREAMING_SNAKE_CASE
let spacing_xs: CGFloat = 4  // snake_case
```

---

## Architecture Patterns

### MVVM Pattern

**Strict separation of concerns:**

```
User Input → View → ViewModel → Services → Models → SwiftData/CloudKit
                ↓
          State Updates
```

#### Model

Pure data structures, no business logic:

```swift
@Model
public final class StressMeasurement {
    public var timestamp: Date
    public var stressLevel: Double
    public var hrv: Double

    public init(timestamp: Date, stressLevel: Double, hrv: Double) {
        self.timestamp = timestamp
        self.stressLevel = stressLevel
        self.hrv = hrv
    }
}
```

#### ViewModel

Presentation logic, orchestrates services:

```swift
@Observable
@MainActor
final class DashboardViewModel {
    // State
    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?

    // Dependencies
    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    // DI Constructor
    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    // Public methods
    func refreshStressLevel() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 10)
            let (hrvData, hrData) = try await (hrv, hr)

            currentStress = try await algorithm.calculateStress(
                hrv: hrvData.value,
                heartRate: hrData.first?.value ?? 0
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

#### View

UI only, no business logic:

```swift
struct StressDashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            if let stress = viewModel?.currentStress {
                StressRingView(stressLevel: stress.level)
            } else if viewModel?.isLoading == true {
                LoadingView()
            }
        }
        .task {
            // Setup dependencies
            let repository = StressRepository(modelContext: modelContext)
            let healthKit = HealthKitManager()
            let algorithm = StressCalculator()

            viewModel = DashboardViewModel(
                healthKit: healthKit,
                algorithm: algorithm,
                repository: repository
            )

            await viewModel?.refreshStressLevel()
        }
    }
}
```

### Protocol-Based Dependency Injection

**Every service has a protocol:**

```swift
// Protocol (abstraction)
protocol HealthKitServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func fetchLatestHRV() async throws -> HRVMeasurement?
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}

// Implementation
@MainActor
@Observable
final class HealthKitManager: HealthKitServiceProtocol {
    func requestAuthorization() async throws { /* ... */ }
    func fetchLatestHRV() async throws -> HRVMeasurement? { /* ... */ }
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] { /* ... */ }
}

// Usage in ViewModel
init(healthKit: HealthKitServiceProtocol) {
    self.healthKit = healthKit
}
```

**Benefits:**
- Testability (mock services)
- Flexibility (swap implementations)
- Clear contracts

### Repository Pattern

Data access abstraction:

```swift
protocol StressRepositoryProtocol: Sendable {
    func save(_ measurement: StressMeasurement) async throws
    func fetchRecent(limit: Int) async throws -> [StressMeasurement]
    func fetchAll() async throws -> [StressMeasurement]
    func delete(_ measurement: StressMeasurement) async throws
}

@MainActor
final class StressRepository: StressRepositoryProtocol {
    private let modelContext: ModelContext
    private let cloudKitManager: CloudKitServiceProtocol?

    func save(_ measurement: StressMeasurement) async throws {
        // Offline-first: Save locally first
        modelContext.insert(measurement)
        try modelContext.save()

        // Then sync to CloudKit (best-effort)
        if let cloudKit = cloudKitManager {
            try? await cloudKit.saveMeasurement(measurement)
        }
    }
}
```

---

## State Management

### @Observable Macro (iOS 17+)

Replace `@ObservableObject` + `@Published`:

```swift
// Modern (iOS 17+)
@Observable
final class ViewModel {
    var isLoading = false
    var errorMessage: String?
}

// View
@State private var viewModel = ViewModel()

// Old (iOS 16)
class ViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
}

// View
@StateObject private var viewModel = ViewModel()
```

### SwiftData @Model

Automatic persistence:

```swift
@Model
public final class StressMeasurement {
    public var timestamp: Date
    public var stressLevel: Double

    // Computed property (not persisted)
    public var category: StressCategory {
        StressResult.category(for: stressLevel)
    }
}
```

### Property Wrappers

| Wrapper | Use Case | Example |
|---------|----------|---------|
| `@State` | View-local mutable state | `@State private var isExpanded = false` |
| `@Binding` | Two-way binding to parent | `@Binding var stressLevel: Double` |
| `@Environment` | Environment values | `@Environment(\.modelContext) var modelContext` |
| `@Observable` | ViewModel state (iOS 17+) | `@Observable final class ViewModel { }` |
| `@Model` | SwiftData models | `@Model final class Entity { }` |

---

## Concurrency

### Async/Await

Prefer `async`/`await` over callbacks:

```swift
// Good
func fetchStress() async throws -> StressResult {
    async let hrv = healthKit.fetchLatestHRV()
    async let hr = healthKit.fetchHeartRate(samples: 10)
    let (hrvData, hrData) = try await (hrv, hr)
    return try await algorithm.calculateStress(hrv: hrvData.value, heartRate: hrData.first?.value ?? 0)
}

// Avoid
func fetchStress(completion: @escaping (Result<StressResult, Error>) -> Void) {
    // callback hell
}
```

### Actor Isolation

- Use `@MainActor` for ViewModels and UI-related types
- Use `nonisolated` for pure functions

```swift
@Observable
@MainActor
final class StressViewModel {
    var currentStress: StressResult?

    // MainActor isolated
    func updateUI() {
        // Safe to update UI properties
    }
}

@MainActor
final class HealthKitManager {
    private nonisolated let baselineCalculator: BaselineCalculator

    // nonisolated functions can be called from any thread
    nonisolated func performCalculation() -> Double {
        // Pure calculation, no shared state
        return 42.0
    }
}
```

### Sendable Conformance

All models and protocols should conform to `Sendable`:

```swift
struct StressResult: Sendable {
    let level: Double
    let category: StressCategory
    let timestamp: Date
}

protocol HealthKitServiceProtocol: Sendable {
    func fetchLatestHRV() async throws -> HRVMeasurement?
}
```

### Continuation Patterns

Wrap callback-based APIs:

```swift
func fetchLatestHRV() async throws -> HRVMeasurement? {
    return try await withCheckedThrowingContinuation { continuation in
        var queryHasReturned = false

        let query = HKSampleQuery(...) { _, samples, error in
            guard !queryHasReturned else { return }
            queryHasReturned = true

            if let error {
                continuation.resume(throwing: error)
                return
            }
            continuation.resume(returning: samples?.first)
        }

        healthStore.execute(query)
    }
}
```

**Critical**: Always use guard to prevent double-resume.

---

## Error Handling

### Custom Error Enums

Use descriptive error types:

```swift
public enum CloudKitError: Error, Sendable {
    case networkUnavailable(NetworkReason)
    case rateLimited
    case quotaExceeded
    case recordNotFound
    case unknown(Error)

    public enum NetworkReason: Sendable {
        case noInternet
        case iCloudNotSignedIn
        case quotaExceeded
    }
}

public enum RepositoryError: Error, Sendable {
    case saveFailed(Error)
    case deleteFailed(Error)
    case cloudKitUnavailable
}
```

### Error Handling Pattern

```swift
func loadCurrentStress() async {
    isLoading = true
    defer { isLoading = false }

    do {
        let stress = try await fetchStress()
        currentStress = stress
        errorMessage = nil
    } catch let error as CloudKitError {
        errorMessage = handleCloudKitError(error)
    } catch {
        errorMessage = error.localizedDescription
    }
}

private func handleCloudKitError(_ error: CloudKitError) -> String {
    switch error {
    case .networkUnavailable(.noInternet):
        return "No internet connection. Data will sync when online."
    case .rateLimited:
        return "Too many requests. Please try again later."
    default:
        return "Sync error: \(error.localizedDescription)"
    }
}
```

### Graceful Degradation

Always provide fallback:

```swift
func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
    do {
        return try modelContext.fetch(descriptor)
    } catch {
        // Return empty array instead of throwing
        return []
    }
}
```

---

## Testing

### Test Conventions

- **File Naming**: `[Target]Tests.swift` (e.g., `StressCalculatorTests.swift`)
- **Method Naming**: `test[Condition]_[Result]` (e.g., `testNormalStress_ReturnsRelaxed()`)
- **Structure**: Given-When-Then pattern
- **Floating Point**: Use `accuracy` parameter (e.g., `XCTAssertEqual(result, 0, accuracy: 10)`)

### Mock Services

Protocol-based mocking:

```swift
final class MockHealthKitService: HealthKitServiceProtocol {
    var mockHRV: HRVMeasurement?
    func fetchLatestHRV() async throws -> HRVMeasurement? { mockHRV }
}
```

---

## SwiftUI Conventions

- **View Modifiers**: Use custom `ViewModifier` for reusable styling
- **ViewBuilder**: Use `@ViewBuilder` for conditional views
- **Lifecycle**: Prefer `.task {}` over `.onAppear` for async work

---

## Wellness Design System Usage

### Phase 1 Implementation ✅

The wellness design system provides a cohesive, accessible visual foundation. **Always use these utilities** instead of raw SwiftUI types.

#### Color Usage Guidelines

**DO:** Use wellness colors with accessibility support

```swift
// Good - Wellness color with accessibility
Text("Stress Level")
    .foregroundStyle(Color.Wellness.calmBlue)

// Better - Stress category with automatic contrast
Text("High Stress")
    .accessibleStressColor(for: .high)

// Best - Full dual coding (color + icon + text)
HStack {
    Image(systemName: category.icon)
    Text(category.displayName)
}
.accessibleStressColor(for: category)
.accessibilityLabel(category.accessibilityDescription)
```

**DON'T:** Use raw system colors

```swift
// Avoid - No wellness theme
Text("Stress")
    .foregroundColor(.blue)

// Avoid - Color only (accessibility violation)
Circle()
    .fill(.green)  // No icon or text
```

---

### Phase 2: Character System ✅

#### Character Usage Guidelines

**DO:** Use StressCharacterCard for stress visualization

```swift
// Good - Character card with all data
StressCharacterCard(
    mood: .calm,
    stressLevel: 15,
    hrv: 70,
    size: .dashboard
)

// Better - From StressResult
StressCharacterCard(
    result: stressResult,
    size: .widget
)

// Minimal - When HRV unavailable
StressCharacterCard(
    stressLevel: 60,
    size: .watchOS
)
```

**DON'T:** Create custom character representations

```swift
// Avoid - Inconsistent with character system
Image(systemName: "face.smiling")
    .foregroundColor(.green)

// Avoid - No animation support
ZStack {
    Image(systemName: mood.symbol)
    // Manual accessory layout
}
```

#### Animation Guidelines

**MANDATORY:** All animations must respect Reduce Motion

```swift
// Good - Respects Reduce Motion
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(.wellness(reduceMotion: reduceMotion)) {
    scale = 1.2
}

// Better - Use built-in wellness animations
withAnimation(.breathing(reduceMotion: reduceMotion)) {
    breathingScale = 1.05
}

// Best - Use view modifier
Image(systemName: mood.symbol)
    .characterAnimation(for: mood)
```

**DON'T:** Use animations without Reduce Motion support

```swift
// Avoid - No accessibility consideration
withAnimation(.easeInOut(duration: 1.0)) {
    scale = 1.2
}

// Avoid - Always animates
.animation(.spring(), value: value)
```

#### Character Animation Patterns

```swift
// Breathing (sleeping): Slow, gentle scale
.characterAnimation(for: .sleeping)
// → 4s scale 0.95-1.05, auto-reverse

// Fidget (concerned): Random subtle movement
.characterAnimation(for: .concerned)
// → Random ±3pt offset every 2.5s

// Shake (worried): Alert trembling
.characterAnimation(for: .worried)
// → ±5° rotation over 0.5s, repeat 3x

// Dizzy (overwhelmed): Continuous spin
.characterAnimation(for: .overwhelmed)
// → 360° rotation over 1.5s

// Accessory floating
Image(systemName: "drop.fill")
    .accessoryAnimation(index: 0)
// → Staggered float -5pt with rotation
```

#### Character Mood Mapping

**ALWAYS** use `StressBuddyMood.from(stressLevel:)` for consistency

```swift
// Good - Automatic mapping
let mood = StressBuddyMood.from(stressLevel: 65)  // → .worried

// Mapping rules:
//   0-10:   .sleeping
//   10-25:  .calm
//   25-50:  .concerned
//   50-75:  .worried
//   75-100: .overwhelmed
```

#### Context Sizing

**Use predefined sizes** for consistency across platforms

```swift
// Dashboard (iOS main screen): 120pt symbol
StressCharacterCard(..., size: .dashboard)

// Widget (iOS home screen): 80pt symbol
StressCharacterCard(..., size: .widget)

// watchOS (watch face): 60pt symbol
StressCharacterCard(..., size: .watchOS)
```

#### Typography Guidelines

**DO:** Use wellness typography with Dynamic Type

```swift
// Good - Custom font with fallback
Text("72")
    .font(.WellnessType.heroNumber)

// Better - With accessibility scaling
Text("Stress Level")
    .font(.WellnessType.cardTitle)
    .accessibleWellnessType()

// Best - Single-line constraint for buttons
Button("Measure") {
    measureStress()
}
.font(.WellnessType.bodyEmphasized)
.accessibleWellnessTypeSingleLine()
```

**DON'T:** Use raw system fonts without scaling

```swift
// Avoid - No Dynamic Type support
Text("Title")
    .font(.system(size: 28, weight: .bold))

// Avoid - Missing accessibility modifier
Text("Content")
    .font(.WellnessType.body)  // Missing .accessibleWellnessType()
```

#### Gradient Usage Guidelines

**DO:** Use wellness gradients for backgrounds

```swift
// Good - Calm wellness background
VStack {
    // Content
}
.wellnessBackground()

// Good - Stress card with tint
Card {
    // Content
}
.stressCard(for: .moderate, baseColor: Color.Wellness.surface)

// Good - Manual stress background
VStack { }
    .background(LinearGradient.stressSpectrum(for: .relaxed))
```

**DON'T:** Use raw gradients without wellness theme

```swift
// Avoid - Not wellness-themed
.background(
    LinearGradient(
        colors: [.blue, .green],
        startPoint: .top,
        endPoint: .bottom
    )
)
```

#### Dual Coding Requirements (WCAG Compliance)

**MANDATORY:** Every stress indicator must combine color + icon + text

```swift
// ✅ CORRECT - Full dual coding
struct StressIndicator: View {
    let category: StressCategory
    let level: Double

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: category.icon)
                .font(.title2)

            // Text
            VStack(alignment: .leading) {
                Text(category.displayName)
                    .font(.WellnessType.bodyEmphasized)
                Text("\(Int(level))")
                    .font(.WellnessType.caption)
            }
        }
        .accessibleStressColor(for: category)
        .accessibilityLabel(category.accessibilityValue(level: level))
    }
}

// ❌ WRONG - Color only (fails WCAG)
Circle()
    .fill(Color.stressColor(for: .relaxed))
    .frame(width: 20, height: 20)
```

### Design System File Locations

```
StressMonitor/
├── Theme/
│   ├── Color+Wellness.swift      // Wellness colors, stress colors
│   ├── Gradients.swift            // Background/stress gradients
│   └── Font+WellnessType.swift   // Custom typography
├── Models/
│   └── StressCategory.swift       // Enhanced with dual coding
└── Fonts/
    └── README.md                  // Font installation guide
```

### Accessibility Checklist

Before merging any UI code, verify:

- [ ] **Color + Icon + Text**: No color-only indicators
- [ ] **Dynamic Type**: All text uses `.accessibleWellnessType()`
- [ ] **VoiceOver**: Meaningful `.accessibilityLabel()` and `.accessibilityHint()`
- [ ] **High Contrast**: Uses `.accessibleStressColor()` for stress indicators
- [ ] **Dark Mode**: All colors have light/dark variants
- [ ] **Touch Targets**: Minimum 44x44pt for interactive elements

### Migration from Old System

When updating existing code:

```swift
// OLD SYSTEM
Text("Content")
    .foregroundColor(.green)
    .font(.system(size: 28, weight: .bold))

// NEW SYSTEM (Wellness Design System v2.0)
Text("Content")
    .accessibleStressColor(for: .relaxed)
    .font(.WellnessType.cardTitle)
    .accessibleWellnessType()
```

### Quick Reference

For complete usage examples, see:
- **Quick Reference**: `./docs/wellness-design-system-quick-reference.md`
- **Implementation Guide**: `./docs/implementation-phase-1-visual-foundation.md`
- **Design Specs**: `./docs/design-guidelines.md`

---

## Import Organization

### Import Order

Group imports alphabetically:

```swift
// 1. System frameworks (alphabetical)
import CloudKit
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI
import WidgetKit

// 2. Third-party (if any) - NONE in this project

// 3. Internal modules (if any)
```

### Minimal Imports

Only import what you use:

```swift
// Good
import Foundation  // for Date, UUID
import SwiftUI     // for View

// Avoid
import Foundation
import UIKit      // not needed in SwiftUI
import SwiftUI
```

---

## Code Quality Guidelines

- **Prefer Immutability**: Use `let` over `var` when possible
- **Avoid Force Unwrapping**: Use optional binding or nil-coalescing (`??`)
- **SwiftLint**: Follow configured rules (no trailing whitespace, no force unwrap)

---

## Documentation

- **Inline Comments**: Use `//` for single-line, `/* */` for multi-line
- **DocC Comments**: Use `///` with parameters and return documentation

---

## Summary

StressMonitor follows **modern Swift conventions** with emphasis on:

- **MVVM architecture** with protocol-based DI
- **SwiftUI + SwiftData** for iOS 17+ patterns
- **Async/await** for all async operations
- **@Observable macro** for state management
- **Sendable conformance** for thread safety
- **Graceful error handling** with custom error types
- **Comprehensive testing** with protocol-based mocking

**Key Principle**: Write clean, readable, maintainable code that prioritizes developer productivity and type safety.

---

**Document Version:** 1.0
**Last Updated:** 2026-02-13
**Lines of Code Count:** 788 (under 800-line target)
