# [P1] Create Shared Swift Package — StressMonitorKit

**Task ID:** t_bc16cb71  
**Branch:** `feature/stress-monitor-kit`  
**Date:** 2025-06-10  
**Priority:** P1  
**Status:** Planning

---

## 1. Executive Summary

Extract all duplicated models, protocols, algorithm logic, and shared types from the iOS app target, watchOS Watch App target, and Widget extension into a single local Swift Package named **StressMonitorKit**. This eliminates 25+ duplicated files across 3 targets and provides a single source of truth for the stress monitoring domain layer.

---

## 2. Duplication Audit

### 2.1 Complete Symbol Inventory

Every duplicated type was found by comparing source files between these three targets:

| Target | Root Path |
|--------|-----------|
| **iOS App** | `StressMonitor/StressMonitor/` |
| **Watch App** | `StressMonitor/StressMonitorWatch Watch App/` |
| **Widget** | `StressMonitor/StressMonitorWidget/` |

---

### 2.2 Category A: Identical/Near-Identical Models (shared between iOS + Watch)

These files have **identical structure** with minor whitespace/comment differences. They are safe to extract directly.

| # | Symbol | iOS File | Watch File | Duplication |
|---|--------|----------|------------|-------------|
| 1 | `StressResult` | `Models/StressResult.swift` | `Models/StressResult.swift` | 2× — byte-identical structs |
| 2 | `StressCategory` | `Models/StressCategory.swift` | `Models/StressCategory.swift` | 2× — same enum + color/icon/pattern/accessibility (Watch lacks `StressSource` extra struct) |
| 3 | `StressContext` | `Models/StressContext.swift` | `Models/StressContext.swift` | 2× — same struct, iOS has more doc comments |
| 4 | `FactorBreakdown` | `Models/FactorBreakdown.swift` | `Models/FactorBreakdown.swift` | 2× — identical struct |
| 5 | `FactorWeights` | `Models/FactorWeights.swift` | `Models/FactorWeights.swift` | 2× — identical struct |
| 6 | `PersonalBaseline` | `Models/PersonalBaseline.swift` | `Models/PersonalBaseline.swift` | 2× — identical struct |
| 7 | `HRVMeasurement` | `Models/HRVMeasurement.swift` | `Models/HRVMeasurement.swift` | 2× — identical struct |
| 8 | `HeartRateSample` | `Models/HeartRateSample.swift` | `Models/HeartRateSample.swift` | 2× — identical struct |
| 9 | `SleepData` | `Models/SleepData.swift` | `Models/SleepData.swift` | 2× — same struct, iOS has doc comments |
| 10 | `ActivityData` | `Models/ActivityData.swift` | `Models/ActivityData.swift` | 2× — same struct, iOS has doc comments |
| 11 | `RecoveryData` | `Models/RecoveryData.swift` | `Models/RecoveryData.swift` | 2× — same struct, iOS has doc comments |

### 2.3 Category B: Identical/Near-Identical Protocols (shared between iOS + Watch)

| # | Symbol | iOS File | Watch File | Duplication |
|---|--------|----------|------------|-------------|
| 12 | `StressAlgorithmServiceProtocol` | `Services/Protocols/StressAlgorithmServiceProtocol.swift` | `Services/StressAlgorithmServiceProtocol.swift` | 2× — same protocol + extension, iOS has extra default impl for `calculateConfidence` |
| 13 | `StressFactor` + `FactorResult` | `Services/Algorithm/StressFactor.swift` | `Services/StressFactor.swift` | 2× — same protocol + struct |
| 14 | `HealthKitServiceProtocol` | `Services/Protocols/HealthKitServiceProtocol.swift` | `Services/HealthKitServiceProtocol.swift` | 2× — same protocol, iOS has default extensions for optional methods |
| 15 | `CloudKitServiceProtocol` + `SyncStatus` + `NetworkReason` + `CloudKitAccountStatus` + `ResolutionStrategy` + `MergeDecision` | `Services/Protocols/CloudKitServiceProtocol.swift` | `Services/CloudKitServiceProtocol.swift` | 2× — same enums, protocols differ in parameter types (`StressMeasurement` vs `WatchStressMeasurement`) |

### 2.4 Category C: Duplicated Algorithm/Service Classes (iOS + Watch)

| # | Symbol | iOS File | Watch File | Differences |
|---|--------|----------|------------|-------------|
| 16 | `StressCalculator` | `Services/Algorithm/StressCalculator.swift` | `Services/StressCalculator.swift` | Same logic, iOS has more comments, `Sendable` vs `@unchecked Sendable` |
| 17 | `MultiFactorStressCalculator` | `Services/Algorithm/MultiFactorStressCalculator.swift` | `Services/MultiFactorStressCalculator.swift` | Same logic, iOS has `StressError.noData` in-file vs standalone, `Sendable` vs `@unchecked Sendable` |
| 18 | `BaselineCalculator` + `BaselineCalculatorError` | `Services/Algorithm/BaselineCalculator.swift` | `Services/BaselineCalculator.swift` | Identical |
| 19 | `HRVStressFactor` | `Services/Algorithm/HRVStressFactor.swift` | `Services/HRVStressFactor.swift` | Same algorithm, iOS version has extra local-copy safety pattern, more metadata |
| 20 | `HeartRateStressFactor` | `Services/Algorithm/HeartRateStressFactor.swift` | `Services/HeartRateStressFactor.swift` | Same algorithm, iOS version has separate `sigmoid` helper and `calculateConfidence` |
| 21 | `SleepStressFactor` | `Services/Algorithm/SleepStressFactor.swift` | `Services/SleepStressFactor.swift` | Same algorithm, iOS has more metadata fields |
| 22 | `ActivityStressFactor` | `Services/Algorithm/ActivityStressFactor.swift` | `Services/ActivityStressFactor.swift` | Same algorithm, iOS has extracted helper methods |
| 23 | `RecoveryStressFactor` | `Services/Algorithm/RecoveryStressFactor.swift` | `Services/RecoveryStressFactor.swift` | Same algorithm, iOS has more metadata |
| 24 | `StressError` | `ViewModels/StressViewModel.swift` (line 405) | `Services/MultiFactorStressCalculator.swift` (line 3) | 2× — identical `enum StressError: Error { case noData }` |

### 2.5 Category D: TrendDirection — 4 Separate Definitions

| # | Location | Definition | Cases |
|---|----------|------------|-------|
| 25 | `StressMonitor/ViewModels/StressViewModel.swift` (line 53) | `enum TrendDirection { case up, down, stable }` | nested in StressViewModel |
| 26 | `StressMonitor/Views/Dashboard/DashboardViewModel.swift` (line 126) | `enum TrendDirection { case up, down, stable }` | top-level |
| 27 | `StressMonitor/Views/Dashboard/Components/WeeklyInsightCard.swift` (line 101) | `private enum TrendDirection { case improved, increased, stable }` | private nested — different cases! |
| 28 | `StressMonitorWidget/Providers/StressWidgetProvider.swift` (line 154) | `public enum TrendDirection: String, Codable { case increasing, stable, decreasing }` | public, Codable, has icon/color |

**Design decision required:** These have divergent semantics:
- StressViewModel / DashboardViewModel / DetailViewModel use `up/down/stable` (generic numeric trend)
- WeeklyInsightCard uses `improved/increased/stable` (stress-specific: "improved" = lower stress = good)
- Widget uses `increasing/stable/decreasing` (Codable for serialization, has UI properties)

**Recommendation:** Unify into a single `TrendDirection` enum in StressMonitorKit with:
- Cases: `improving`, `declining`, `stable` (semantically clear for stress: improving = stress going down)
- `Codable` conformance for Widget serialization
- `icon` and `color` properties (String-based for Widget compatibility)
- Free functions `trendIcon()`, `trendColor()`, `trendText()` moved into the package

### 2.6 Category E: Widget-Specific Duplicated Types

| # | Symbol | Location | Notes |
|---|--------|----------|-------|
| 29 | `StressCategory` (3rd copy) | `StressMonitorWidget/Models/WidgetDataProvider.swift` (line 178) | Simplified version — String-based `color`, no SwiftUI Color, has `displayName` |
| 30 | `Color(hex:)` init | `StressMonitorWatch Watch App/Theme/Color+Extensions.swift` | Also exists in iOS app (not found as separate file, likely in extensions) |
| 31 | `CloudKitRecordType` + `CloudKitStressMeasurement` + `CloudKitError` | `StressMonitorWatch Watch App/Services/CloudKitSchema.swift` | Duplicated with iOS `Services/CloudKit/CloudKitSchema.swift` (iOS also has `CloudKitPersonalBaseline`) |

### 2.7 Duplication Summary Counts

| Symbol | # of Copies | Affected Targets |
|--------|-------------|------------------|
| `TrendDirection` | 4 (or 5 with TrendsViewModel) | iOS App, Widget |
| `StressCategory` | 3 | iOS App, Watch App, Widget |
| `StressError` | 2 | iOS App, Watch App |
| `StressResult` | 2 | iOS App, Watch App |
| `StressContext` | 2 | iOS App, Watch App |
| `FactorBreakdown` | 2 | iOS App, Watch App |
| `FactorWeights` | 2 | iOS App, Watch App |
| `PersonalBaseline` | 2 | iOS App, Watch App |
| `HRVMeasurement` | 2 | iOS App, Watch App |
| `HeartRateSample` | 2 | iOS App, Watch App |
| `SleepData` | 2 | iOS App, Watch App |
| `ActivityData` | 2 | iOS App, Watch App |
| `RecoveryData` | 2 | iOS App, Watch App |
| `StressAlgorithmServiceProtocol` | 2 | iOS App, Watch App |
| `StressFactor` + `FactorResult` | 2 | iOS App, Watch App |
| `HealthKitServiceProtocol` | 2 | iOS App, Watch App |
| `CloudKitServiceProtocol` + enums | 2 | iOS App, Watch App |
| `StressCalculator` | 2 | iOS App, Watch App |
| `MultiFactorStressCalculator` | 2 | iOS App, Watch App |
| `BaselineCalculator` | 2 | iOS App, Watch App |
| `HRVStressFactor` | 2 | iOS App, Watch App |
| `HeartRateStressFactor` | 2 | iOS App, Watch App |
| `SleepStressFactor` | 2 | iOS App, Watch App |
| `ActivityStressFactor` | 2 | iOS App, Watch App |
| `RecoveryStressFactor` | 2 | iOS App, Watch App |
| `CloudKitSchema` types | 2 | iOS App, Watch App |

**Total: 25+ symbols duplicated across 2-4 targets, representing ~50 duplicated files.**

---

## 3. Proposed Package Structure

```
StressMonitor/
├── Packages/
│   └── StressMonitorKit/
│       ├── Package.swift
│       ├── Sources/
│       │   └── StressMonitorKit/
│       │       ├── Models/
│       │       │   ├── StressResult.swift
│       │       │   ├── StressCategory.swift
│       │       │   ├── StressContext.swift
│       │       │   ├── FactorBreakdown.swift
│       │       │   ├── FactorWeights.swift
│       │       │   ├── PersonalBaseline.swift
│       │       │   ├── HRVMeasurement.swift
│       │       │   ├── HeartRateSample.swift
│       │       │   ├── SleepData.swift
│       │       │   ├── ActivityData.swift
│       │       │   ├── RecoveryData.swift
│       │       │   └── TrendDirection.swift          ← NEW unified enum
│       │       ├── Protocols/
│       │       │   ├── StressAlgorithmServiceProtocol.swift
│       │       │   ├── StressFactor.swift             ← includes FactorResult
│       │       │   ├── HealthKitServiceProtocol.swift
│       │       │   └── CloudKitServiceProtocol.swift   ← includes SyncStatus, NetworkReason, etc.
│       │       ├── Errors/
│       │       │   └── StressError.swift
│       │       ├── Algorithm/
│       │       │   ├── StressCalculator.swift
│       │       │   ├── MultiFactorStressCalculator.swift
│       │       │   ├── BaselineCalculator.swift        ← includes BaselineCalculatorError
│       │       │   ├── HRVStressFactor.swift
│       │       │   ├── HeartRateStressFactor.swift
│       │       │   ├── SleepStressFactor.swift
│       │       │   ├── ActivityStressFactor.swift
│       │       │   └── RecoveryStressFactor.swift
│       │       ├── CloudKit/
│       │       │   ├── CloudKitSchema.swift            ← CloudKitRecordType, CloudKitStressMeasurement, CloudKitPersonalBaseline, CloudKitError
│       │       │   └── ConflictResolution.swift        ← ResolutionStrategy, MergeDecision
│       │       └── Extensions/
│       │           └── Color+Hex.swift                 ← Color(hex:) init (if SwiftUI available)
│       └── Tests/
│           └── StressMonitorKitTests/
│               ├── StressResultTests.swift
│               ├── StressCalculatorTests.swift
│               ├── MultiFactorStressCalculatorTests.swift
│               ├── BaselineCalculatorTests.swift
│               ├── FactorTests.swift
│               └── TrendDirectionTests.swift
```

---

## 4. Step-by-Step Implementation Plan

### Phase 1: Package Scaffold (Step 1-2)

**Step 1: Create the Swift Package directory structure**
- Create `StressMonitor/Packages/StressMonitorKit/` directory
- Create `Package.swift` with the following configuration:
  - Name: `StressMonitorKit`
  - Platforms: `.iOS(.v17)`, `.watchOS(.v10)`
  - Products: one library `StressMonitorKit`
  - Targets: `StressMonitorKit` (source), `StressMonitorKitTests` (test)
  - Dependencies: none (system frameworks only)
  - The library must conditionally import `SwiftUI` (for `Color` in `StressCategory`) and `CloudKit` (for schema types)

**Step 2: Add package to Xcode project**
- Add `Packages/StressMonitorKit` as a local package dependency in `StressMonitor.xcodeproj`
- Add `StressMonitorKit` as a dependency to all three framework targets:
  - `StressMonitor` (iOS app target)
  - `StressMonitorWatch Watch App` (watchOS target)
  - `StressMonitorWidget` (widget extension)

### Phase 2: Extract Models (Step 3-5)

**Step 3: Copy and unify all Category A models**
For each of these 11 model files, take the **iOS version** (which has more documentation/comments) as the canonical source, add `public` access modifiers, and place in `StressMonitorKit/Models/`:

1. `StressResult.swift` — add `public` to struct and its `init` and `category(for:)` method
2. `StressCategory.swift` — add `public` to enum and all computed properties. Move `StressSource` struct to iOS target only (it's UI-specific, not shared). The `color` property returns `SwiftUI.Color`, which requires conditional compilation or making it `public` with `import SwiftUI`
3. `StressContext.swift` — add `public` to struct and init
4. `FactorBreakdown.swift` — add `public` to struct
5. `FactorWeights.swift` — add `public` to struct, init, and `defaults` static property
6. `PersonalBaseline.swift` — add `public` to struct and init
7. `HRVMeasurement.swift` — add `public` to struct and init
8. `HeartRateSample.swift` — add `public` to struct and init
9. `SleepData.swift` — add `public` to struct and init
10. `ActivityData.swift` — add `public` to struct and init
11. `RecoveryData.swift` — add `public` to struct and init

**Important — `StressCategory.color`**: The `color` property uses `SwiftUI.Color` with `Color(light:dark:)` and `Color(hex:)`. Options:
- **Option A (Recommended):** Move `Color+Hex.swift` extension into StressMonitorKit under `Extensions/` and mark the package as depending on SwiftUI (acceptable since iOS 17+ / watchOS 10+ both have SwiftUI)
- **Option B:** Keep `color` in platform-specific extensions outside the package

**Step 4: Create unified TrendDirection enum**
Create `TrendDirection.swift` in `StressMonitorKit/Models/`:

```swift
import Foundation

/// Unified trend direction across all targets.
/// Semantics: "improving" = stress decreasing (good), "declining" = stress increasing (bad).
public enum TrendDirection: String, Codable, Sendable, CaseIterable {
    case improving   // stress going down (good)
    case declining   // stress going up (bad)
    case stable

    public var icon: String {
        switch self {
        case .improving: return "arrow.down"
        case .declining: return "arrow.up"
        case .stable: return "minus"
        }
    }

    public var colorHex: String {
        switch self {
        case .improving: return "#34C759"  // green
        case .declining: return "#FF9500"  // orange
        case .stable: return "#8E8E93"     // gray
        }
    }

    public var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }
}
```

**Step 5: Extract StressError**
Create `StressError.swift` in `StressMonitorKit/Errors/`:
- Take the canonical version from `docs/code-standards-patterns.md` which uses `LocalizedError`
- Add `noData`, `healthKitNotAvailable`, `baselineNotEstablished`, `unknown` cases as documented

### Phase 3: Extract Protocols (Step 6-7)

**Step 6: Copy all Category B protocols**
For each protocol file, take the **iOS version** (which has more complete default implementations) as canonical:

1. `StressAlgorithmServiceProtocol.swift` — `public protocol`, include all default implementations from iOS version
2. `StressFactor.swift` — includes `FactorResult` struct, `public protocol` + `public struct`
3. `HealthKitServiceProtocol.swift` — `public protocol`, include default extensions for optional methods
4. `CloudKitServiceProtocol.swift` — **Challenge:** parameter types differ between iOS (`StressMeasurement`) and Watch (`WatchStressMeasurement`). Solution: make the protocol generic or use the shared model type. Since both `StressMeasurement` (iOS, SwiftData `@Model`) and `WatchStressMeasurement` (Watch, `@Observable`) are platform-specific persistence models (not shared), the protocol should be refactored to accept a shared DTO. **For now**, extract the associated enums (`SyncStatus`, `NetworkReason`, `CloudKitAccountStatus`, `ResolutionStrategy`, `MergeDecision`) into the package, and keep the protocol itself platform-specific or make it generic with an associated type.

**Step 7: Handle CloudKitSchema duplication**
Create `CloudKitSchema.swift` in `StressMonitorKit/CloudKit/`:
- Merge both versions: include `CloudKitRecordType`, `CloudKitStressMeasurement`, `CloudKitPersonalBaseline` (from iOS), `CloudKitError` (from Watch — more complete)
- Add `public` access modifiers

### Phase 4: Extract Algorithm Classes (Step 8-9)

**Step 8: Copy all Category C algorithm files**
For each algorithm file, take the **iOS version** as canonical (more robust, more comments, better Sendable conformance):

1. `StressCalculator.swift` — `public final class`, all methods `public`
2. `MultiFactorStressCalculator.swift` — `public final class`, remove inline `StressError` (now imported from package)
3. `BaselineCalculator.swift` — `public final class`, includes `BaselineCalculatorError`
4. `HRVStressFactor.swift` — `public struct`
5. `HeartRateStressFactor.swift` — `public struct`
6. `SleepStressFactor.swift` — `public struct`
7. `ActivityStressFactor.swift` — `public struct`
8. `RecoveryStressFactor.swift` — `public struct`
9. `FactorCalibrator.swift` (iOS only, no Watch duplicate) — `public final class`

All algorithm classes currently use `internal` access. They need `public` on the class, init, and all protocol-method signatures.

**Step 9: Handle platform-specific code**
- `FactorCalibrator` uses `StressMeasurement` (SwiftData model) — move to iOS target or make generic
- Verify all `Sendable` conformance is consistent (prefer `Sendable` over `@unchecked Sendable`)

### Phase 5: Delete Duplicated Files (Step 10-12)

**Step 10: Delete Watch App duplicates**
Remove these files from the Watch App target (and file system):
- `StressMonitorWatch Watch App/Models/StressResult.swift`
- `StressMonitorWatch Watch App/Models/StressCategory.swift`
- `StressMonitorWatch Watch App/Models/StressContext.swift`
- `StressMonitorWatch Watch App/Models/FactorBreakdown.swift`
- `StressMonitorWatch Watch App/Models/FactorWeights.swift`
- `StressMonitorWatch Watch App/Models/PersonalBaseline.swift`
- `StressMonitorWatch Watch App/Models/HRVMeasurement.swift`
- `StressMonitorWatch Watch App/Models/HeartRateSample.swift`
- `StressMonitorWatch Watch App/Models/SleepData.swift`
- `StressMonitorWatch Watch App/Models/ActivityData.swift`
- `StressMonitorWatch Watch App/Models/RecoveryData.swift`
- `StressMonitorWatch Watch App/Services/StressAlgorithmServiceProtocol.swift`
- `StressMonitorWatch Watch App/Services/StressFactor.swift`
- `StressMonitorWatch Watch App/Services/HealthKitServiceProtocol.swift`
- `StressMonitorWatch Watch App/Services/CloudKitServiceProtocol.swift`
- `StressMonitorWatch Watch App/Services/StressCalculator.swift`
- `StressMonitorWatch Watch App/Services/MultiFactorStressCalculator.swift`
- `StressMonitorWatch Watch App/Services/BaselineCalculator.swift`
- `StressMonitorWatch Watch App/Services/HRVStressFactor.swift`
- `StressMonitorWatch Watch App/Services/HeartRateStressFactor.swift`
- `StressMonitorWatch Watch App/Services/SleepStressFactor.swift`
- `StressMonitorWatch Watch App/Services/ActivityStressFactor.swift`
- `StressMonitorWatch Watch App/Services/RecoveryStressFactor.swift`
- `StressMonitorWatch Watch App/Services/CloudKitSchema.swift`

**Step 11: Delete iOS App duplicates**
Remove these files from the iOS App target:
- `StressMonitor/Models/StressResult.swift`
- `StressMonitor/Models/StressCategory.swift` (keep `StressSource` struct — move to a separate file or keep in iOS target)
- `StressMonitor/Models/StressContext.swift`
- `StressMonitor/Models/FactorBreakdown.swift`
- `StressMonitor/Models/FactorWeights.swift`
- `StressMonitor/Models/PersonalBaseline.swift`
- `StressMonitor/Models/HRVMeasurement.swift`
- `StressMonitor/Models/HeartRateSample.swift`
- `StressMonitor/Models/SleepData.swift`
- `StressMonitor/Models/ActivityData.swift`
- `StressMonitor/Models/RecoveryData.swift`
- `StressMonitor/Services/Protocols/StressAlgorithmServiceProtocol.swift`
- `StressMonitor/Services/Algorithm/StressFactor.swift`
- `StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift`
- `StressMonitor/Services/Protocols/CloudKitServiceProtocol.swift` (keep enums, move protocol if needed)
- `StressMonitor/Services/Algorithm/StressCalculator.swift`
- `StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift`
- `StressMonitor/Services/Algorithm/BaselineCalculator.swift`
- `StressMonitor/Services/Algorithm/HRVStressFactor.swift`
- `StressMonitor/Services/Algorithm/HeartRateStressFactor.swift`
- `StressMonitor/Services/Algorithm/SleepStressFactor.swift`
- `StressMonitor/Services/Algorithm/ActivityStressFactor.swift`
- `StressMonitor/Services/Algorithm/RecoveryStressFactor.swift`
- `StressMonitor/Services/CloudKit/CloudKitSchema.swift`
- Remove `StressError` definition from `StressMonitor/ViewModels/StressViewModel.swift` (line 405-407)
- Remove `TrendDirection` from `DashboardViewModel.swift` (line 126-130)
- Remove `TrendDirection` from `StressViewModel.swift` (line 53-55)

**Step 12: Delete Widget duplicates**
Remove from Widget target:
- `StressMonitorWidget/Providers/StressWidgetProvider.swift` — remove `TrendDirection` enum (lines 152-174) and `StressCategory` enum (lines 176-210) from `WidgetDataProvider.swift`
- Replace with `import StressMonitorKit`

### Phase 6: Migrate TrendDirection Consumers (Step 13-15)

**Step 13: Update all TrendDirection references**

Files that reference `TrendDirection` and need updating:

| File | Current Usage | Migration |
|------|--------------|-----------|
| `StressViewModel.swift` | Nested `enum TrendDirection { up, down, stable }` | Delete nested enum; use `TrendDirection.improving/.declining/.stable` |
| `DashboardViewModel.swift` | Top-level `enum TrendDirection { up, down, stable }` | Delete enum; map `up→declining`, `down→improving` |
| `WeeklyInsightCard.swift` | Private `enum TrendDirection { improved, increased, stable }` | Delete private enum; map `improved→improving`, `increased→declining` |
| `TrendsViewModel.swift` | Uses `TrendDirection` from `DashboardViewModel` | Update to use package type |
| `DetailViewModel.swift` | Uses `TrendDirection` from `DashboardViewModel`; has `trendIcon()`, `trendColor()` | Update to use package type; migrate helper functions |
| `MeasurementDetailView.swift` | Has `trendText()` function | Migrate to use package type |
| `StressWidgetProvider.swift` | `public enum TrendDirection: String, Codable` | Delete enum; use package type |

**Step 14: Update StressCategory in Widget**
The Widget's `StressCategory` (in `WidgetDataProvider.swift`) is a simplified String-based version. The Widget views use String-based colors (not SwiftUI Color). Options:
- **Option A:** Widget imports StressMonitorKit and uses the full `StressCategory` with SwiftUI Color (requires SwiftUI in Widget, which is already the case)
- **Option B:** Keep a thin String-based wrapper in the Widget that converts from the package type

Recommend **Option A** — the Widget already uses SwiftUI views.

**Step 15: Update all `import` statements**
Add `import StressMonitorKit` to every file that previously defined or used the duplicated types. Estimated ~40-50 files need updated imports.

Key files needing `import StressMonitorKit`:
- All ViewModels in both iOS and Watch targets
- All View files that reference `StressResult`, `StressCategory`, `TrendDirection`
- All Service files that use protocols or algorithm types
- Widget provider and views

### Phase 7: Build & Test (Step 16-18)

**Step 16: Build all targets**
Build in this order:
1. Build `StressMonitorKit` package target first (should compile independently)
2. Build `StressMonitor` (iOS app)
3. Build `StressMonitorWatch Watch App`
4. Build `StressMonitorWidget`

Expected issues:
- Missing `public` on some internal helpers — fix iteratively
- `CloudKitServiceProtocol` parameter type mismatch — may need associated type or generic
- `StressCategory.color` might need conditional `#if canImport(SwiftUI)` guards
- `FactorCalibrator` uses `StressMeasurement` (SwiftData model) — either keep in iOS target or make generic

**Step 17: Run all existing tests**
- Run `StressMonitorTests` — ensure all pass
- Run `StressMonitorWatch_Watch_AppTests` — ensure all pass
- Run UI tests if available

**Step 18: Add StressMonitorKit unit tests**
Create tests in `Tests/StressMonitorKitTests/`:
- `StressResultTests.swift` — test `category(for:)` boundary values
- `StressCalculatorTests.swift` — test sigmoid-based calculation
- `MultiFactorStressCalculatorTests.swift` — test weight normalization, missing factors
- `BaselineCalculatorTests.swift` — test outlier filtering, circadian adjustment
- `FactorTests.swift` — test each factor independently with mock contexts
- `TrendDirectionTests.swift` — test Codable round-trip, case mappings

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| `StressCategory.color` depends on SwiftUI `Color` + hex init | Package ties to SwiftUI | Acceptable: iOS 17+ and watchOS 10+ both ship SwiftUI. Use `import SwiftUI` in package. |
| `CloudKitServiceProtocol` uses different model types on each platform | Protocol cannot be directly shared | Extract associated enums only; keep protocol generic with associated type, or use shared DTO. |
| `FactorCalibrator` depends on `StressMeasurement` (SwiftData `@Model`) | Can't move to package | Keep `FactorCalibrator` in iOS target; Watch doesn't have it anyway. |
| `StressMeasurement` and `WatchStressMeasurement` are different types | Persistence layer stays duplicated | Expected — these are platform-specific persistence models. Only the domain models are extracted. |
| Xcode project file (`.pbxproj`) manual editing | File references could break | Use Xcode's "Add Package" UI or `xcodebuild` to add the local package. Never hand-edit `.pbxproj`. |
| `Sendable` conformance differences | Compile warnings/errors | Use strict `Sendable` (iOS versions); audit all `@unchecked Sendable` in Watch code. |
| TrendDirection semantic unification may invert meaning in some views | UI shows wrong trend direction | Carefully map: old `up` → `declining` (stress going up = bad), old `down` → `improving` (stress going down = good). Add tests. |

---

## 6. Files NOT Moved to StressMonitorKit (stays in targets)

These files/types remain target-specific and are NOT extracted:

| Type | Reason |
|------|--------|
| `StressMeasurement` (iOS `@Model`) | SwiftData model, iOS-specific persistence |
| `WatchStressMeasurement` (Watch `@Observable`) | Watch-specific persistence model |
| `WatchStressCategory` | Watch-specific Int-based category |
| `WatchCloudKitManager` | Watch-specific CloudKit implementation |
| `CloudKitManager` (iOS) | iOS-specific CloudKit implementation |
| `CloudKitSyncEngine` | iOS-specific sync logic |
| `WidgetDataProvider` | Widget-specific UserDefaults bridge |
| `StressData` (Widget) | Widget-specific simplified DTO — could be migrated later |
| `FactorCalibrator` | Depends on `StressMeasurement` (SwiftData model) |
| `HealthKitManager` / `WatchHealthKitManager` | Platform-specific HealthKit implementations |
| All ViewModels | Use `@Observable`/`@Model`, platform-specific |
| All Views | SwiftUI views, platform-specific |
| `MockServices` | Test-only, iOS-specific |

---

## 7. Estimated Effort

| Phase | Steps | Estimated Time |
|-------|-------|---------------|
| Phase 1: Package scaffold | Step 1-2 | 30 min |
| Phase 2: Extract models | Step 3-5 | 1 hour |
| Phase 3: Extract protocols | Step 6-7 | 45 min |
| Phase 4: Extract algorithms | Step 8-9 | 1 hour |
| Phase 5: Delete duplicates | Step 10-12 | 30 min |
| Phase 6: Migrate TrendDirection | Step 13-15 | 1 hour |
| Phase 7: Build & test | Step 16-18 | 1-2 hours |
| **Total** | | **~6 hours** |

---

## 8. Verification Checklist

- [ ] `StressMonitorKit` compiles independently with no warnings
- [ ] iOS app target builds and runs
- [ ] Watch App target builds and runs
- [ ] Widget extension builds and shows correct data
- [ ] All existing unit tests pass
- [ ] No `TrendDirection` definition exists outside StressMonitorKit
- [ ] No `StressError` definition exists outside StressMonitorKit
- [ ] No `StressCategory` definition exists outside StressMonitorKit (except `WatchStressCategory`)
- [ ] All stress calculations produce identical results before/after migration
- [ ] `Codable` serialization round-trips correctly for `TrendDirection`, `StressResult`, `FactorBreakdown`
- [ ] No duplicate symbol linker errors across any target
