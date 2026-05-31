# Phase 1: SimulatorHealthKitService

## Priority: high
## Status: completed
## Effort: medium

## Overview

Create `SimulatorHealthKitService` implementing `HealthKitServiceProtocol` with dynamic, time-varying data generation for all 5 stress factors (HRV, HR, Sleep, Activity, Recovery). All code wrapped in `#if DEBUG`.

## Context Links

- Protocol: `StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift`
- Existing mock: `StressMonitor/Services/MockServices.swift`
- Models: `StressMonitor/Models/HRVMeasurement.swift`, `HeartRateSample.swift`
- Multi-factor models: `StressMonitor/Models/SleepData.swift`, `StressContext.swift` (from multi-factor plan)
- Multi-factor plan: `plans/0321-2251-multi-factor-stress-scoring/plan.md`
- Brainstorm: `plans/reports/brainstorm-0321-2309-demo-mode-healthkit-testing.md`

## Key Insights

- Protocol requires original 5 methods + new methods from multi-factor plan: `fetchSleepData(for:)`, `fetchActivityData(for:)`, `fetchRecoveryData(for:)`
- Must conform to `Sendable` (protocol requirement)
- Existing `MockHealthKitService` returns static values — this service must be dynamic
- Data generation uses time-based math (sin/cos curves) for deterministic-but-varying patterns
- `@unchecked Sendable` acceptable since internal state is read-only after init (generation is pure math from current time)
- Sleep/Activity/Recovery data should correlate with stress scenario (high stress = poor sleep, sedentary, poor recovery)

## Architecture

```
SimulatorHealthKitService
├── StressScenario enum (relaxed/mild/moderate/high/edge)
├── currentScenario: computed from elapsed time (cycles every ~2 min)
├── generateHRV(for scenario): Double
├── generateHeartRate(for scenario): Double
├── generateSleepData(for scenario): SleepData
├── generateActivityData(for scenario): ActivityData
├── generateRecoveryData(for scenario): RecoveryData
├── generateHistoricalData(since date): [HRVMeasurement]
└── observeHeartRateUpdates(): AsyncStream (emits every 3-5s)
```

## Related Code Files

- Create: `StressMonitor/StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift`

## Implementation Steps

### 1. Define stress scenario enum and cycling logic

```swift
private enum StressScenario: CaseIterable {
    case relaxed, mild, moderate, high, edgeLowHRV

    var hrvRange: ClosedRange<Double> { ... }
    var hrRange: ClosedRange<Double> { ... }
}
```

Cycle: elapsed seconds / 30 determines scenario index. Smooth interpolation between adjacent scenarios.

### 2. Implement time-based data generation

```
currentHRV():
  scenario = currentScenario (from elapsed time)
  base = scenario.hrvRange.midpoint
  noise = sin(time * 0.7) * 3  // slow drift
  jitter = Double.random(in: -2...2)  // per-call variation
  return clamp(base + noise + jitter, 10...90)

currentHeartRate():
  inversely correlated with HRV
  HR = 120 - (HRV * 0.8) + noise
```

### 3. Implement original protocol methods

- `requestAuthorization()`: no-op, returns immediately
- `fetchLatestHRV()`: returns `HRVMeasurement(value: currentHRV())`
- `fetchHeartRate(samples:)`: returns array of recent HR values with slight variation
- `fetchHRVHistory(since:)`: generates backdated measurements, 3-5 per day, with circadian pattern
- `observeHeartRateUpdates()`: `AsyncStream` yielding every 3-5 seconds, using `Task.sleep`

### 3b. Implement multi-factor protocol methods

These methods are added by the multi-factor stress scoring plan (Phase 2+):

- `fetchSleepData(for:)`: returns `SleepData` correlated with scenario
  - Relaxed: 7.5-8.5h total, 1.5h deep, 2h REM, high efficiency (0.90+)
  - Mild: 6-7h total, 1h deep, 1.5h REM, moderate efficiency (0.80-0.90)
  - Moderate: 5-6h total, 0.5h deep, 1h REM, low efficiency (0.70-0.80), 3+ awakenings
  - High: 3-5h total, 0.2h deep, 0.5h REM, poor efficiency (<0.70), 5+ awakenings
  - Edge: returns `nil` (simulates no sleep data)

- `fetchActivityData(for:)`: returns `ActivityData` correlated with scenario
  - Relaxed: 8000-12000 steps, 300-500 kcal, 10+ stand hours, recent workout
  - Mild: 5000-8000 steps, 200-300 kcal, 8 stand hours
  - Moderate: 2000-5000 steps, 100-200 kcal, 5 stand hours, sedentary
  - High: <2000 steps, <100 kcal, 2-3 stand hours, no workout
  - Edge: returns `nil`

- `fetchRecoveryData(for:)`: returns `RecoveryData` correlated with scenario
  - Relaxed: resp rate 14-16, SpO2 97-99%, resting HR trending down
  - Mild: resp rate 16-18, SpO2 96-98%, resting HR stable
  - Moderate: resp rate 18-20, SpO2 95-97%, resting HR trending up
  - High: resp rate 20-24, SpO2 93-96%, resting HR elevated
  - Edge: partial data (some sub-metrics nil)

### 4. Historical data generation

For each day from `since` to now:
- Generate 3-5 measurements spaced across waking hours (7am-11pm)
- Apply circadian curve: higher HRV morning/evening, lower midday
- Add day-level trend: slight random walk across days
- Include 1-2 edge case days (very low HRV, high stress)

### 5. Edge cases

- 5% chance `fetchLatestHRV()` returns `nil` (simulates missing data)
- `edgeLowHRV` scenario: HRV 10-18ms, HR 100-115bpm
- Low confidence values when HRV < 20ms (handled by real `StressCalculator`)

## Todo List

- [ ] Create `SimulatorHealthKitService.swift` with `#if DEBUG` wrapper
- [ ] Implement `StressScenario` enum with ranges for all 5 factors per category + edge
- [ ] Implement time-based scenario cycling (~30s per scenario)
- [ ] Implement `currentHRV()` and `currentHeartRate()` with noise
- [ ] Implement original 5 protocol methods (HRV, HR, history, auth, observe)
- [ ] Implement `fetchSleepData(for:)` with scenario-correlated sleep patterns
- [ ] Implement `fetchActivityData(for:)` with scenario-correlated activity levels
- [ ] Implement `fetchRecoveryData(for:)` with scenario-correlated recovery markers
- [ ] Implement historical data generation with circadian pattern
- [ ] Implement `AsyncStream` for live HR (3-5s interval)
- [ ] Add edge case handling (nil returns, extreme values, partial recovery data)
- [ ] Verify `Sendable` conformance compiles

## Success Criteria

- Service compiles with no warnings under strict concurrency
- Each protocol method returns realistic, varying data
- Stress categories cycle through all 4 + edge within ~2.5 min
- All 5 factor data (HRV, HR, Sleep, Activity, Recovery) generated per scenario
- Sleep/Activity/Recovery data correlates with stress scenario logically
- Historical data covers requested date range with circadian variation
- AsyncStream emits values at regular intervals and cancels cleanly
- Edge scenario returns nil for sleep/activity/recovery (tests graceful degradation)

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| AsyncStream leak | `onTermination` cleanup, use `Task.sleep` with cancellation check |
| Sendable violation | `@unchecked Sendable` — state is time-derived, no mutation |
| Unrealistic data ranges | Validate against published HRV norms (SDNN 20-80ms typical) |
