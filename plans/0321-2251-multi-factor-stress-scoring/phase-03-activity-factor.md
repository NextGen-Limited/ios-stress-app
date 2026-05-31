---
phase: 3
title: "Activity Factor"
status: pending
priority: P2
effort: 4h
depends_on: [phase-02]
---

# Phase 3: Activity Factor

## Context Links

- [Phase 2: Factor Architecture + Sleep](./phase-02-factor-architecture-sleep.md)
- [StressFactor Protocol](../../StressMonitor/StressMonitor/Services/Algorithm/StressFactor.swift) (created in Phase 2)
- [MultiFactorStressCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift) (created in Phase 2)
- [HealthKitManager](../../StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift)
- [HealthKitServiceProtocol](../../StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift)
- [Brainstorm](../reports/brainstorm-0321-2251-multi-factor-stress-scoring.md)

## Overview

Add `ActivityStressFactor` (weight: 0.15) measuring exercise load and movement patterns. High recent activity with insufficient recovery increases stress; moderate regular activity reduces it.

**Priority:** P2
**Status:** pending

## Key Insights

1. **Exercise paradox** -- intense workout temporarily raises stress markers (HR up, HRV down) but long-term reduces stress. Need to differentiate acute post-workout state from chronic inactivity.
2. **HealthKit quantity types** -- `.stepCount`, `.activeEnergyBurned`, `.appleStandTime` are all `HKQuantityType`
3. **Workout detection** -- `HKWorkoutType.workoutType()` provides workout sessions with duration and energy
4. **Stand hours** -- `.appleStandTime` returns seconds of standing time; Apple Watch counts hours with >1 min standing
5. **Post-workout suppression** -- if last workout was <2 hours ago, activity factor should partially suppress stress (elevated HR is expected)

## Requirements

### Functional
- Create `ActivityStressFactor` conforming to `StressFactor` (weight: 0.15)
- Fetch today's steps, active energy, stand hours from HealthKit
- Detect recent workouts (last 24h) for post-workout context
- Score: sedentary = higher stress contribution, moderate activity = lower
- Post-workout grace period: suppress activity stress contribution for 2h after workout
- Create `ActivityData` model

### Non-Functional
- New HealthKit permissions: `.stepCount`, `.activeEnergyBurned`, `.appleStandTime`
- No SwiftData schema changes (uses existing `activityComponent` field from Phase 2)
- Files under 200 LOC

## Architecture

### New Types

```swift
// File: StressMonitor/Models/ActivityData.swift

struct ActivityData: Sendable {
    let stepCount: Int                  // today's total steps
    let activeEnergyKcal: Double        // today's active energy burned
    let standHours: Int                 // hours with standing activity
    let lastWorkoutEndTime: Date?       // most recent workout end
    let lastWorkoutDurationMinutes: Double?
    let analysisDate: Date
}
```

```swift
// File: StressMonitor/Services/Algorithm/ActivityStressFactor.swift

struct ActivityStressFactor: StressFactor {
    let id = "activity"
    let weight = 0.15

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let activity = context.activityData else { return nil }

        // Sedentary detection: low steps + low energy = stress contributor
        let stepScore = activityStressFromSteps(activity.stepCount)
        let energyScore = activityStressFromEnergy(activity.activeEnergyKcal)
        let standScore = activityStressFromStanding(activity.standHours)

        var combined = stepScore * 0.4 + energyScore * 0.35 + standScore * 0.25

        // Post-workout suppression
        if let workoutEnd = activity.lastWorkoutEndTime {
            let hoursSince = Date().timeIntervalSince(workoutEnd) / 3600.0
            if hoursSince < 2.0 {
                combined *= max(0.3, hoursSince / 2.0)  // suppress stress contribution
            }
        }

        return FactorResult(
            value: max(0, min(1.0, combined)),
            confidence: 0.85,  // activity data is generally reliable
            metadata: [
                "steps": Double(activity.stepCount),
                "activeEnergy": activity.activeEnergyKcal,
                "standHours": Double(activity.standHours)
            ]
        )
    }

    // Less movement = more stress contribution
    private func activityStressFromSteps(_ steps: Int) -> Double {
        // 10,000 steps = low stress; <2,000 = high stress
        let normalized = Double(steps) / 10000.0
        return max(0, 1.0 - min(1.0, normalized))
    }

    private func activityStressFromEnergy(_ kcal: Double) -> Double {
        // 300+ kcal active = low stress; <50 = high stress
        let normalized = kcal / 300.0
        return max(0, 1.0 - min(1.0, normalized))
    }

    private func activityStressFromStanding(_ hours: Int) -> Double {
        // 10+ stand hours = low stress; <4 = high stress
        let normalized = Double(hours) / 10.0
        return max(0, 1.0 - min(1.0, normalized))
    }
}
```

## Related Code Files

### Files to Create
- `StressMonitor/StressMonitor/Models/ActivityData.swift`
- `StressMonitor/StressMonitor/Services/Algorithm/ActivityStressFactor.swift`
- Mirror both for watchOS target
- `StressMonitorTests/ActivityStressFactorTests.swift`

### Files to Modify
- `StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift` -- add `fetchActivityData`
- `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` -- implement activity fetch, add types to auth
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` -- add `ActivityStressFactor` to default factors
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` -- fetch activity data, include in context
- `StressMonitor/StressMonitor/Services/MockServices.swift` -- add mock activity data
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift` -- add activity fetch
- `StressMonitor/StressMonitorWatch Watch App/Services/HealthKitServiceProtocol.swift` -- add method

### Files to Delete
- None

## Implementation Steps

1. **Create `ActivityData` model**
   - File: `Models/ActivityData.swift`
   - Properties: stepCount, activeEnergyKcal, standHours, lastWorkoutEndTime, lastWorkoutDurationMinutes, analysisDate

2. **Create `ActivityStressFactor`**
   - File: `Services/Algorithm/ActivityStressFactor.swift`
   - Implement scoring: steps (40%), energy (35%), standing (25%)
   - Post-workout suppression logic (2h grace period)
   - Return nil if no activity data

3. **Add `fetchActivityData` to HealthKit protocol**
   - Signature: `func fetchActivityData(for date: Date) async throws -> ActivityData?`

4. **Implement `fetchActivityData` in `HealthKitManager`**
   - Add `stepCountType`, `activeEnergyType`, `standTimeType` properties
   - Add these to authorization request
   - Query today's cumulative statistics using `HKStatisticsQuery` with `.cumulativeSum`
   - Query most recent workout using `HKWorkoutType.workoutType()`
   - Aggregate into `ActivityData`

5. **Register `ActivityStressFactor` in `MultiFactorStressCalculator`**
   - Add to default factors array
   - Total weights now: HRV(0.40) + HR(0.15) + Sleep(0.20) + Activity(0.15) = 0.90

6. **Update `StressViewModel`**
   - In context building: `let activityData = try? await healthKit.fetchActivityData(for: Date())`
   - Pass into `StressContext`

7. **Update mocks** -- `MockHealthKitService` returns mock `ActivityData`

8. **Mirror to watchOS** -- duplicate new files, update `WatchHealthKitManager`

9. **Write tests**
   - Sedentary scenario (low steps, low energy, few stand hours) = high activity stress
   - Active scenario (10k+ steps, 300+ kcal) = low activity stress
   - Post-workout suppression: stress reduced within 2h of workout
   - Nil data returns nil (graceful degradation)

10. **Build and verify both targets**

## TODO Checklist

- [ ] Create `ActivityData.swift` model
- [ ] Create `ActivityStressFactor.swift`
- [ ] Add `fetchActivityData` to `HealthKitServiceProtocol`
- [ ] Implement `fetchActivityData` in `HealthKitManager`
- [ ] Add `.stepCount`, `.activeEnergyBurned`, `.appleStandTime` to auth request
- [ ] Register `ActivityStressFactor` in `MultiFactorStressCalculator`
- [ ] Update `StressViewModel` to fetch activity data
- [ ] Update `MockServices`
- [ ] Mirror files to watchOS target
- [ ] Update `WatchHealthKitManager`
- [ ] Write `ActivityStressFactorTests`
- [ ] Build iPhone -- zero warnings
- [ ] Build watchOS -- zero warnings
- [ ] Run all tests -- 100% pass

## Success Criteria

- Activity factor produces scores correlated with movement patterns
- Post-workout suppression prevents false high-stress readings
- Missing activity data handled via weight redistribution
- 4 factors active: HRV + HR + Sleep + Activity
- Both platforms compile and pass tests

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Step count varies wildly by user | Low | Relative scoring (not absolute thresholds); Phase 5 calibration |
| Stand hours unavailable on non-Watch users | Low | Graceful nil handling |
| Workout detection may lag | Low | Query recent 24h; 2h grace period is generous |
| watchOS battery from additional queries | Low | Use `HKStatisticsQuery` (efficient cumulative sum) |

## Security Considerations

- New HealthKit read permissions: `.stepCount`, `.activeEnergyBurned`, `.appleStandTime`
- Read-only access, no writes
- Activity data stored locally + CloudKit E2E encrypted
- Progressive permission request
