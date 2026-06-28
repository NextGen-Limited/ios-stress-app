# Patterns and conventions

## MVVM with @Observable

ViewModels use the `@Observable` macro (iOS 17+) instead of `ObservableObject`. State mutations drive SwiftUI updates directly; there is no `@Published` boilerplate.

```swift
@Observable
@MainActor
final class StressViewModel {
    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?
}
```

ViewModels are `@MainActor` because they own UI state and drive SwiftUI views. They are never passed across isolation boundaries; services are.

## Protocol-based dependency injection

Every service has a protocol in `StressMonitor/StressMonitor/Services/Protocols/`. ViewModels accept protocols through constructor injection with a default concrete type, which makes production wiring automatic and test substitution a one-line change.

```swift
init(
    healthKit: HealthKitServiceProtocol = HealthKitManager(),
    algorithm: StressAlgorithmServiceProtocol = MultiFactorStressCalculator(),
    repository: StressRepositoryProtocol = StressRepository()
) { ... }
```

Concrete types are `final class` or `struct` and conform to `Sendable` when they cross actor boundaries.

## Async/await everywhere

The codebase prefers `async`/`await` and `AsyncStream` over completion handlers. HealthKit callback APIs are wrapped with `withCheckedThrowingContinuation` inside `HealthKitManager`. Views use `.task { }` to kick off async work tied to the view lifetime.

```swift
func refresh() async {
    isLoading = true
    defer { isLoading = false }
    async let hrv = healthKit.fetchLatestHRV()
    async let hr = healthKit.fetchHeartRate(samples: 10)
    let (hrvData, hrData) = try await (hrv, hr)
    currentStress = try await algorithm.calculateStress(
        hrv: hrvData?.value ?? 0,
        heartRate: hrData.first?.value ?? 0
    )
}
```

## Sendable and strict concurrency

All service types crossing actor boundaries are `Sendable`. Immutable value types get `Sendable` automatically; reference types either hold only `let`-bound `Sendable` properties or are marked `@unchecked Sendable` with an explicit thread-safety comment. `@MainActor` isolates UI-bound singletons like `HealthKitManager` and `CloudKitManager`.

## Dual coding for stress levels

Stress categories always pair color with an icon and a pattern description so color-blind users can distinguish tiers. The canonical mapping lives in `StressMonitor/StressMonitor/Models/StressCategory.swift`:

```swift
StressCategory.relaxed  // green #34C759, leaf.fill, solid fill
StressCategory.mild     // blue #007AFF, circle.fill, diagonal lines
StressCategory.moderate // yellow #FFD60A, triangle.fill, dots pattern
StressCategory.high     // orange #FF9500, square.fill, crosshatch
StressCategory.severe   // red #FF3B30, exclamationmark.octagon.fill, solid warning
```

Never use a stress color in isolation; always pair it with the icon and VoiceOver description from `accessibilityDescription`.

## Accessibility

- Touch targets are at least 44x44pt.
- Dynamic Type is supported via `.accessibleDynamicType()` (see `StressMonitor/StressMonitor/Utilities/DynamicTypeScaling.swift`).
- High-contrast mode is handled by `HighContrastModifier`.
- Color-blind simulation lives in `StressMonitor/StressMonitor/Utilities/ColorBlindSimulator.swift` for design QA.
- Haptic feedback is centralized in `HapticManager` at `StressMonitor/StressMonitor/Views/Components/HapticManager.swift`.

## SwiftData models

Models use the `@Model` macro. Mutating fields are plain `var`; computed helpers derive the category from the raw value. Migration is explicit: declare a `VersionedSchema` pair and a `SchemaMigrationPlan` with lightweight stages. The app's V1-to-V2 migration adding `Habit` lives in `StressMonitor/StressMonitor/StressMonitorApp.swift`.

## Error handling

Services throw typed errors (`StressError`, `LLMServiceError`, `StoreKitError`). ViewModels catch at the call site and write a user-facing `errorMessage` string. Never surface raw error descriptions in production UI; provide a fallback message.

## Naming

- Types: `PascalCase`.
- Methods and properties: `camelCase`.
- Test methods: `test[Method]_[Condition]` or `test[Condition]`.
- Stress category enum cases: lowercase (`relaxed`, `mild`, `moderate`, `high`, `severe`).
- File names match the primary type.

## Imports

Group system frameworks alphabetically. `Foundation` first, then frameworks, then `SwiftUI` last.

```swift
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI
```

## File size

Most source files stay under 500 lines. The largest offenders are `StressViewModel.swift` (573 lines), `StressRepository.swift` (16KB), and `DashboardView.swift` (10KB). Split a file when it exceeds ~600 lines or clearly owns two responsibilities.
