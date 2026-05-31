---
phase: 2
title: "Factor Architecture + Sleep Integration"
status: pending
priority: P1
effort: 8h
depends_on: [phase-01]
---

# Phase 2: Factor Architecture + Sleep Integration

## Context Links

- [Phase 1: Fix Formula Science](./phase-01-fix-formula-science.md)
- [Current StressCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift)
- [Current StressAlgorithmServiceProtocol](../../StressMonitor/StressMonitor/Services/Protocols/StressAlgorithmServiceProtocol.swift)
- [Current HealthKitServiceProtocol](../../StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift)
- [Current HealthKitManager](../../StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift)
- [Current StressMeasurement](../../StressMonitor/StressMonitor/Models/StressMeasurement.swift)
- [Current StressResult](../../StressMonitor/StressMonitor/Models/StressResult.swift)
- [StressViewModel](../../StressMonitor/StressMonitor/ViewModels/StressViewModel.swift)
- [MockServices](../../StressMonitor/StressMonitor/Services/MockServices.swift)
- [Brainstorm](../reports/brainstorm-0321-2251-multi-factor-stress-scoring.md)

## Overview

Biggest structural change: introduce `StressFactor` protocol, refactor existing HRV+HR into factors, add `SleepStressFactor`, and update the full data pipeline. Sleep is the #1 missing factor -- strongest recovery predictor after HRV.

**Priority:** P1 -- Architectural foundation for all future factors
**Status:** pending

## Key Insights

1. **Apple Watch sleep staging** -- HealthKit provides `HKCategoryValueSleepAnalysis` with values: `.inBed`, `.asleepUnspecified`, `.asleepCore`, `.asleepDeep`, `.asleepREM`, `.awake`. Sleep stages available since watchOS 9.
2. **Sleep data is category-type** -- query via `HKCategoryType(.sleepAnalysis)`, not quantity type
3. **Graceful degradation** -- if sleep permission denied or no watch worn overnight, weight redistributes to HRV+HR
4. **Factor architecture earns complexity at 3+ factors** -- we'll have 3 factors minimum after this phase
5. **Shared code between iPhone/watchOS** -- factor protocol + implementations can live in shared target or be duplicated (currently duplicated pattern)

## Requirements

### Functional
- Define `StressFactor` protocol with `id`, `weight`, `calculate(context:)` method
- Create `StressContext` struct carrying all raw inputs + baseline
- Refactor existing HRV logic into `HRVStressFactor` (weight: 0.40)
- Refactor existing HR logic into `HeartRateStressFactor` (weight: 0.15)
- Create `SleepStressFactor` (weight: 0.20) querying last night's sleep
- Create `MultiFactorStressCalculator` replacing old `StressCalculator`
- Extend `HealthKitManager` to fetch sleep data
- Extend `StressMeasurement` with optional component fields
- Extend `StressResult` with factor breakdown
- Update `StressViewModel` to pass sleep data through
- Handle graceful degradation (missing factors = weight redistribution)

### Non-Functional
- New HealthKit permission: `.sleepAnalysis` (read-only)
- Lightweight SwiftData migration (optional fields only)
- All files under 200 LOC
- Both iPhone and watchOS updated
- >80% test coverage on new code

## Architecture

### New Types

```swift
// MARK: - StressFactor Protocol
// File: StressMonitor/Services/Algorithm/StressFactor.swift

protocol StressFactor: Sendable {
    var id: String { get }
    var weight: Double { get }
    func calculate(context: StressContext) async throws -> FactorResult?
}

struct FactorResult: Sendable {
    let value: Double          // 0-1 normalized stress contribution
    let confidence: Double     // 0-1 how reliable this factor's reading is
    let metadata: [String: Double]  // debug/display data
}
```

```swift
// MARK: - StressContext
// File: StressMonitor/Models/StressContext.swift

struct StressContext: Sendable {
    let baseline: PersonalBaseline
    let timestamp: Date

    // Raw inputs (all optional for graceful degradation)
    let hrv: Double?
    let heartRate: Double?
    let sleepData: SleepData?
    let activityData: ActivityData?    // Phase 3
    let recoveryData: RecoveryData?    // Phase 4
    let lastReadingDate: Date?
}
```

```swift
// MARK: - SleepData Model
// File: StressMonitor/Models/SleepData.swift

struct SleepData: Sendable {
    let totalSleepHours: Double        // total asleep time
    let deepSleepHours: Double         // .asleepDeep
    let remSleepHours: Double          // .asleepREM
    let coreSleepHours: Double         // .asleepCore
    let awakenings: Int                // number of .awake segments
    let timeInBedHours: Double         // .inBed duration
    let sleepEfficiency: Double        // totalSleep / timeInBed (0-1)
    let analysisDate: Date             // date of sleep session
}
```

```swift
// MARK: - FactorBreakdown (for StressResult)
// File: extend StressResult.swift

struct FactorBreakdown: Codable, Sendable {
    let hrvComponent: Double?
    let hrComponent: Double?
    let sleepComponent: Double?
    let activityComponent: Double?
    let recoveryComponent: Double?
    let dataCompleteness: Double  // 0-1, available factor weight / total weight
}
```

### Modified Types

```swift
// StressResult -- add optional factorBreakdown
struct StressResult {
    // existing fields...
    let factorBreakdown: FactorBreakdown?  // nil for legacy single-factor measurements
}

// StressMeasurement -- add optional component fields (lightweight migration)
@Model public final class StressMeasurement {
    // existing fields...
    public var hrvComponent: Double?
    public var hrComponent: Double?
    public var sleepComponent: Double?
    public var activityComponent: Double?
    public var recoveryComponent: Double?
    public var dataCompleteness: Double?
}

// StressAlgorithmServiceProtocol -- new method
protocol StressAlgorithmServiceProtocol: Sendable {
    // existing method (kept for backward compat)
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
    // new method
    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult
}

// HealthKitServiceProtocol -- add sleep fetch
protocol HealthKitServiceProtocol: Sendable {
    // existing methods...
    func fetchSleepData(for date: Date) async throws -> SleepData?
}
```

### MultiFactorStressCalculator

```swift
// File: StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift

final class MultiFactorStressCalculator: StressAlgorithmServiceProtocol {
    private let factors: [StressFactor]

    init(factors: [StressFactor]? = nil) {
        self.factors = factors ?? [
            HRVStressFactor(),
            HeartRateStressFactor(),
            SleepStressFactor()
        ]
    }

    func calculateMultiFactorStress(context: StressContext) async throws -> StressResult {
        var results: [(factor: StressFactor, result: FactorResult)] = []

        for factor in factors {
            if let result = try await factor.calculate(context: context) {
                results.append((factor, result))
            }
        }

        guard !results.isEmpty else {
            throw StressError.noData
        }

        // Normalize weights across available factors
        let totalWeight = results.reduce(0) { $0 + $1.factor.weight }

        // Weighted combination
        let compositeScore = results.reduce(0.0) { sum, item in
            sum + item.result.value * (item.factor.weight / totalWeight)
        }

        let level = max(0, min(100, compositeScore * 100))
        let category = StressResult.category(for: level)

        // Composite confidence
        let dataCompleteness = totalWeight / factors.reduce(0) { $0 + $1.weight }
        let avgConfidence = results.reduce(0.0) { $0 + $1.result.confidence } / Double(results.count)
        let confidence = dataCompleteness * 0.4 + avgConfidence * 0.6

        let breakdown = FactorBreakdown(
            hrvComponent: results.first { $0.factor.id == "hrv" }?.result.value,
            hrComponent: results.first { $0.factor.id == "heartRate" }?.result.value,
            sleepComponent: results.first { $0.factor.id == "sleep" }?.result.value,
            activityComponent: nil,
            recoveryComponent: nil,
            dataCompleteness: dataCompleteness
        )

        return StressResult(
            level: level,
            category: category,
            confidence: confidence,
            hrv: context.hrv ?? 0,
            heartRate: context.heartRate ?? 0,
            timestamp: context.timestamp,
            factorBreakdown: breakdown
        )
    }
}
```

### Sleep HealthKit Query

```swift
// HealthKitManager -- add fetchSleepData
func fetchSleepData(for date: Date) async throws -> SleepData? {
    let sleepType = HKCategoryType(.sleepAnalysis)

    // Query last night: from yesterday 6 PM to today noon
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!  // yesterday 6 PM
    let queryEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!    // today noon

    let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

    // ... query and aggregate sleep stages into SleepData
}
```

## Related Code Files

### Files to Create
- `StressMonitor/StressMonitor/Services/Algorithm/StressFactor.swift` -- protocol + FactorResult
- `StressMonitor/StressMonitor/Services/Algorithm/HRVStressFactor.swift` -- extracted HRV logic
- `StressMonitor/StressMonitor/Services/Algorithm/HeartRateStressFactor.swift` -- extracted HR logic
- `StressMonitor/StressMonitor/Services/Algorithm/SleepStressFactor.swift` -- sleep factor
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` -- orchestrator
- `StressMonitor/StressMonitor/Models/StressContext.swift` -- context struct
- `StressMonitor/StressMonitor/Models/SleepData.swift` -- sleep model
- `StressMonitor/StressMonitor/Models/FactorBreakdown.swift` -- breakdown struct
- Mirror above files for watchOS target
- `StressMonitorTests/MultiFactorStressCalculatorTests.swift`
- `StressMonitorTests/HRVStressFactorTests.swift`
- `StressMonitorTests/HeartRateStressFactorTests.swift`
- `StressMonitorTests/SleepStressFactorTests.swift`

### Files to Modify
- `StressMonitor/StressMonitor/Services/Protocols/StressAlgorithmServiceProtocol.swift` -- add `calculateMultiFactorStress`
- `StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift` -- add `fetchSleepData`
- `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` -- implement sleep fetch, add sleepType to auth
- `StressMonitor/StressMonitor/Models/StressResult.swift` -- add `factorBreakdown` field
- `StressMonitor/StressMonitor/Models/StressMeasurement.swift` -- add optional component fields
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` -- build StressContext, call multi-factor
- `StressMonitor/StressMonitor/Services/MockServices.swift` -- update mocks
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift` -- add sleep fetch
- `StressMonitor/StressMonitorWatch Watch App/Services/HealthKitServiceProtocol.swift` -- add sleep fetch
- `StressMonitor/StressMonitorWatch Watch App/Services/StressAlgorithmServiceProtocol.swift` -- add multi-factor
- `StressMonitor/StressMonitorWatch Watch App/Models/StressMeasurement.swift` -- add component fields

### Files to Delete
- None (keep old `StressCalculator.swift` -- `MultiFactorStressCalculator` conforms to same protocol and delegates to old method for backward compat)

## Implementation Steps

1. **Create `StressFactor` protocol and `FactorResult`**
   - File: `Services/Algorithm/StressFactor.swift`
   - Protocol: `id: String`, `weight: Double`, `calculate(context:) async throws -> FactorResult?`
   - FactorResult: `value: Double`, `confidence: Double`, `metadata: [String: Double]`

2. **Create `StressContext` and data models**
   - File: `Models/StressContext.swift` -- all inputs, all optional except baseline+timestamp
   - File: `Models/SleepData.swift` -- sleep stage aggregation
   - File: `Models/FactorBreakdown.swift` -- per-factor output values

3. **Extract `HRVStressFactor`** from existing `StressCalculator`
   - File: `Services/Algorithm/HRVStressFactor.swift`
   - Move sigmoid HRV logic (from Phase 1) into `calculate(context:)`
   - Weight: 0.40
   - Returns nil if `context.hrv` is nil

4. **Extract `HeartRateStressFactor`**
   - File: `Services/Algorithm/HeartRateStressFactor.swift`
   - Move sigmoid HR logic into `calculate(context:)`
   - Weight: 0.15
   - Returns nil if `context.heartRate` is nil

5. **Implement `SleepStressFactor`**
   - File: `Services/Algorithm/SleepStressFactor.swift`
   - Weight: 0.20
   - Score components:
     - Duration score: `min(1.0, (8.0 - totalSleepHours) / 4.0)` -- less sleep = more stress
     - Quality score: weighted by deep+REM proportion
     - Efficiency score: `1.0 - sleepEfficiency`
     - Combined: `duration * 0.4 + quality * 0.35 + efficiency * 0.25`
   - Returns nil if `context.sleepData` is nil

6. **Create `MultiFactorStressCalculator`**
   - File: `Services/Algorithm/MultiFactorStressCalculator.swift`
   - Conforms to `StressAlgorithmServiceProtocol`
   - Old `calculateStress(hrv:heartRate:)` builds minimal context and delegates to multi-factor
   - New `calculateMultiFactorStress(context:)` runs all factors, normalizes weights, combines

7. **Update `StressResult`** -- add optional `factorBreakdown: FactorBreakdown?`

8. **Update `StressMeasurement`** -- add optional fields: `hrvComponent`, `hrComponent`, `sleepComponent`, `activityComponent`, `recoveryComponent`, `dataCompleteness`

9. **Update `HealthKitServiceProtocol`** -- add `fetchSleepData(for: Date) async throws -> SleepData?`

10. **Implement sleep fetch in `HealthKitManager`**
    - Add `HKCategoryType(.sleepAnalysis)` to authorization types
    - Query last night's sleep samples
    - Aggregate by category value (`.asleepDeep`, `.asleepREM`, `.asleepCore`, `.awake`, `.inBed`)
    - Calculate duration per stage, efficiency, awakening count

11. **Update `StressViewModel`**
    - In `loadCurrentStress()`: fetch sleep data, build `StressContext`, call `calculateMultiFactorStress`
    - In `calculateAndSaveStress()`: persist component fields to `StressMeasurement`
    - Handle sleep permission denial gracefully

12. **Update mocks** -- `MockHealthKitService`, `MockStressAlgorithmService`, `MockStressRepository`

13. **Mirror all changes to watchOS**
    - Duplicate new files into watch target
    - Update `WatchHealthKitManager` with sleep fetch
    - Update watch `StressMeasurement` (WatchStressMeasurement)

14. **Write tests**
    - `MultiFactorStressCalculatorTests`: full factor combination, weight redistribution, missing factors
    - `HRVStressFactorTests`: sigmoid output ranges, nil input handling
    - `HeartRateStressFactorTests`: sigmoid output ranges, nil input
    - `SleepStressFactorTests`: good/bad/missing sleep scenarios
    - Update existing `StressCalculatorTests` if kept

15. **Build both targets, run all tests**

## TODO Checklist

- [ ] Create `StressFactor.swift` (protocol + FactorResult)
- [ ] Create `StressContext.swift`
- [ ] Create `SleepData.swift`
- [ ] Create `FactorBreakdown.swift`
- [ ] Create `HRVStressFactor.swift` (weight: 0.40)
- [ ] Create `HeartRateStressFactor.swift` (weight: 0.15)
- [ ] Create `SleepStressFactor.swift` (weight: 0.20)
- [ ] Create `MultiFactorStressCalculator.swift`
- [ ] Update `StressAlgorithmServiceProtocol` -- add `calculateMultiFactorStress`
- [ ] Update `StressResult` -- add `factorBreakdown`
- [ ] Update `StressMeasurement` -- add optional component fields
- [ ] Update `HealthKitServiceProtocol` -- add `fetchSleepData`
- [ ] Implement `fetchSleepData` in `HealthKitManager`
- [ ] Add `.sleepAnalysis` to HealthKit authorization request
- [ ] Update `StressViewModel` to use multi-factor path
- [ ] Update `MockServices.swift`
- [ ] Mirror new files to watchOS target
- [ ] Update `WatchHealthKitManager` with sleep fetch
- [ ] Write `MultiFactorStressCalculatorTests`
- [ ] Write `HRVStressFactorTests`
- [ ] Write `HeartRateStressFactorTests`
- [ ] Write `SleepStressFactorTests`
- [ ] Build iPhone target -- zero warnings
- [ ] Build watchOS target -- zero warnings
- [ ] Run all tests -- 100% pass

## Success Criteria

- `StressFactor` protocol defined and used by 3 factors
- `MultiFactorStressCalculator` produces scores comparable to old calculator when only HRV+HR available
- Sleep data fetched from HealthKit and integrated into stress score
- Missing sleep data handled gracefully (weight redistribution, no crash)
- `StressMeasurement` stores per-factor breakdown
- Old `calculateStress(hrv:heartRate:)` still works (backward compat)
- New tests cover all factor combinations (HRV only, HRV+HR, HRV+HR+Sleep)
- Both iPhone and watchOS compile and pass tests

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Sleep data unavailable (no watch overnight) | Medium | Return nil from factor; redistribute weight |
| HealthKit sleep permission denied | Medium | Graceful degradation; explain in UI |
| Sleep stage categorization inaccurate | Low | Apple Watch sleep staging is "moderate" accuracy; document limitation |
| Large number of new files | Low | Each file <100 LOC; well-organized by domain |
| Breaking changes to StressResult | Medium | Add optional field with default nil; no breakage |

## Security Considerations

- New HealthKit read permission: `.sleepAnalysis` -- read-only, no writes
- Sleep data stored locally via SwiftData (encrypted at rest)
- Sleep data synced via CloudKit E2E encryption (inherits existing sync)
- No new external API calls
- Progressive permission request (only ask for sleep when user reaches sleep-aware feature)
