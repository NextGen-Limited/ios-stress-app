---
phase: 4
title: "Recovery Factor"
status: pending
priority: P2
effort: 4h
depends_on: [phase-02]
---

# Phase 4: Recovery Factor

## Context Links

- [Phase 2: Factor Architecture + Sleep](./phase-02-factor-architecture-sleep.md)
- [StressFactor Protocol](../../StressMonitor/StressMonitor/Services/Algorithm/StressFactor.swift) (created in Phase 2)
- [MultiFactorStressCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift)
- [HealthKitManager](../../StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift)
- [BaselineCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/BaselineCalculator.swift)
- [Brainstorm](../reports/brainstorm-0321-2251-multi-factor-stress-scoring.md)

## Overview

Add `RecoveryStressFactor` (weight: 0.10) measuring physiological recovery markers: respiratory rate, blood oxygen (SpO2), and resting heart rate trend. These are secondary indicators that validate HRV/HR readings and detect longer-term stress accumulation.

**Priority:** P2
**Status:** pending

## Key Insights

1. **Respiratory rate** -- elevated respiratory rate (>20 breaths/min) correlates with stress/illness. HealthKit: `.respiratoryRate` (HKQuantityType)
2. **Blood oxygen (SpO2)** -- drops below 95% can indicate physiological stress. HealthKit: `.oxygenSaturation` (HKQuantityType). Only available on Apple Watch Series 6+.
3. **Resting HR trend** -- upward trend in resting HR over 7 days indicates accumulated stress/poor recovery. HealthKit: `.restingHeartRate` (HKQuantityType)
4. **Data availability** -- respiratory rate and SpO2 require Apple Watch worn during sleep. Many users won't have this data. Factor must handle nil gracefully.
5. **Low weight (0.10)** -- these are supporting markers, not primary. Even if all three are missing, total factor pool only loses 10%.

## Requirements

### Functional
- Create `RecoveryStressFactor` conforming to `StressFactor` (weight: 0.10)
- Fetch respiratory rate, SpO2, and resting HR trend from HealthKit
- Score: elevated resp rate / low SpO2 / rising resting HR = higher stress
- Create `RecoveryData` model
- Sub-factor weighting: respiratory rate 40%, SpO2 30%, resting HR trend 30%

### Non-Functional
- New HealthKit permissions: `.respiratoryRate`, `.oxygenSaturation`, `.restingHeartRate`
- No SwiftData schema changes (uses existing `recoveryComponent` field from Phase 2)
- Files under 200 LOC
- Handle nil for each sub-metric independently (partial recovery data still useful)

## Architecture

### New Types

```swift
// File: StressMonitor/Models/RecoveryData.swift

struct RecoveryData: Sendable {
    let respiratoryRate: Double?         // breaths per minute (latest)
    let bloodOxygen: Double?             // SpO2 percentage 0-100 (latest)
    let restingHeartRate: Double?        // latest resting HR
    let restingHRTrend: Double?          // delta from 7-day avg (positive = rising = worse)
    let analysisDate: Date
}
```

```swift
// File: StressMonitor/Services/Algorithm/RecoveryStressFactor.swift

struct RecoveryStressFactor: StressFactor {
    let id = "recovery"
    let weight = 0.10

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let recovery = context.recoveryData else { return nil }

        var components: [(value: Double, weight: Double)] = []

        // Respiratory rate: normal 12-20; >20 = stress indicator
        if let rr = recovery.respiratoryRate {
            let rrStress = max(0, min(1.0, (rr - 12.0) / 16.0))  // 12=0, 28=1
            components.append((rrStress, 0.40))
        }

        // Blood oxygen: normal >96%; <92% = significant stress
        if let spo2 = recovery.bloodOxygen {
            let spo2Stress = max(0, min(1.0, (100.0 - spo2) / 8.0))  // 100%=0, 92%=1
            components.append((spo2Stress, 0.30))
        }

        // Resting HR trend: rising = poor recovery
        if let trend = recovery.restingHRTrend {
            let trendStress = max(0, min(1.0, trend / 10.0))  // +10bpm over avg = max stress
            components.append((trendStress, 0.30))
        }

        guard !components.isEmpty else { return nil }

        // Normalize sub-weights
        let totalSubWeight = components.reduce(0) { $0 + $1.weight }
        let combined = components.reduce(0.0) { $0 + $1.value * ($1.weight / totalSubWeight) }

        // Confidence based on data availability
        let dataAvailability = Double(components.count) / 3.0
        let confidence = 0.6 + dataAvailability * 0.3  // 0.7-0.9 range

        return FactorResult(
            value: combined,
            confidence: confidence,
            metadata: [
                "respiratoryRate": recovery.respiratoryRate ?? -1,
                "bloodOxygen": recovery.bloodOxygen ?? -1,
                "restingHRTrend": recovery.restingHRTrend ?? 0
            ]
        )
    }
}
```

## Related Code Files

### Files to Create
- `StressMonitor/StressMonitor/Models/RecoveryData.swift`
- `StressMonitor/StressMonitor/Services/Algorithm/RecoveryStressFactor.swift`
- Mirror both for watchOS target
- `StressMonitorTests/RecoveryStressFactorTests.swift`

### Files to Modify
- `StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift` -- add `fetchRecoveryData`
- `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` -- implement recovery fetch, add types to auth
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` -- add `RecoveryStressFactor` to defaults
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` -- fetch recovery data, include in context
- `StressMonitor/StressMonitor/Services/MockServices.swift` -- add mock recovery data
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift` -- add recovery fetch
- `StressMonitor/StressMonitorWatch Watch App/Services/HealthKitServiceProtocol.swift` -- add method

### Files to Delete
- None

## Implementation Steps

1. **Create `RecoveryData` model**
   - File: `Models/RecoveryData.swift`
   - All fields optional except `analysisDate`

2. **Create `RecoveryStressFactor`**
   - File: `Services/Algorithm/RecoveryStressFactor.swift`
   - Sub-scoring for respiratory rate, SpO2, resting HR trend
   - Handle partial data (any combination of 1-3 sub-metrics)
   - Return nil only if all sub-metrics are nil

3. **Add `fetchRecoveryData` to HealthKit protocol**
   - Signature: `func fetchRecoveryData(for date: Date) async throws -> RecoveryData?`

4. **Implement `fetchRecoveryData` in `HealthKitManager`**
   - Add `respiratoryRateType`, `oxygenSaturationType`, `restingHeartRateType` properties
   - Add to authorization request
   - Fetch latest respiratory rate sample
   - Fetch latest SpO2 sample
   - Fetch 7-day resting HR history, compute trend (current - 7d avg)
   - Return `RecoveryData` with available fields

5. **Register `RecoveryStressFactor` in `MultiFactorStressCalculator`**
   - Add to default factors array
   - Total weights now: HRV(0.40) + HR(0.15) + Sleep(0.20) + Activity(0.15) + Recovery(0.10) = 1.00

6. **Update `StressViewModel`**
   - Fetch recovery data alongside other HealthKit queries
   - Pass into `StressContext`

7. **Update mocks and watchOS**

8. **Write tests**
   - Normal recovery (low resp rate, high SpO2, stable resting HR) = low stress
   - Poor recovery (high resp rate, low SpO2, rising resting HR) = high stress
   - Partial data (only SpO2 available) = scores with available data
   - All nil = returns nil

9. **Build and verify both targets**

## TODO Checklist

- [ ] Create `RecoveryData.swift` model
- [ ] Create `RecoveryStressFactor.swift`
- [ ] Add `fetchRecoveryData` to `HealthKitServiceProtocol`
- [ ] Implement `fetchRecoveryData` in `HealthKitManager`
- [ ] Add `.respiratoryRate`, `.oxygenSaturation`, `.restingHeartRate` to auth
- [ ] Register `RecoveryStressFactor` in `MultiFactorStressCalculator`
- [ ] Update `StressViewModel` to fetch recovery data
- [ ] Update `MockServices`
- [ ] Mirror files to watchOS target
- [ ] Update `WatchHealthKitManager`
- [ ] Write `RecoveryStressFactorTests`
- [ ] Build iPhone -- zero warnings
- [ ] Build watchOS -- zero warnings
- [ ] Run all tests -- 100% pass

## Success Criteria

- All 5 factors active: HRV + HR + Sleep + Activity + Recovery (total weight = 1.0)
- Recovery factor produces scores correlated with physiological recovery markers
- Partial recovery data handled gracefully (1, 2, or 3 sub-metrics)
- Missing recovery data = weight redistribution to other factors
- Both platforms compile and pass tests

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| SpO2 unavailable on older watches | Medium | Optional field; Series 6+ only; factor handles nil |
| Respiratory rate requires sleep | Medium | Only measured during sleep; nil handling |
| Resting HR trend calculation accuracy | Low | Simple 7-day average; sufficient for trend detection |
| 3 new HealthKit permissions at once | Low | Progressive permission request; explain value to user |

## Security Considerations

- New HealthKit read permissions: `.respiratoryRate`, `.oxygenSaturation`, `.restingHeartRate`
- Read-only access, no writes
- Recovery data stored locally + CloudKit E2E encrypted
- SpO2 data is particularly sensitive -- no external transmission
