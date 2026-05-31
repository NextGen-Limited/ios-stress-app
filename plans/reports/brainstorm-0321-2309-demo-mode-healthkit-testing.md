# Brainstorm: Demo Mode for HealthKit Testing

## Problem Statement

App requires real HealthKit data (HRV, heart rate) from Apple Watch to function. On simulator or devices without Apple Watch, the app has no data to display. Need a way to test the full app pipeline with realistic, dynamic data.

## Current State

Already have strong foundations:
- `HealthKitServiceProtocol` with protocol-based DI
- `MockHealthKitService` in `Services/MockServices.swift` (static values, previews/unit tests only)
- `PreviewDataFactory` with mock data generators
- `#if targetEnvironment(simulator) return` guard in `startAutoRefresh()`
- `StressMonitorApp.swift` directly creates `MainTabView()` with no service injection override

**Gap:** No runtime demo mode with dynamic, time-varying data that exercises the real algorithm + persistence pipeline.

## Evaluated Approaches

| Approach | Effort | Simulator | Device | Real Pipeline | Live Data |
|----------|--------|-----------|--------|---------------|-----------|
| A: Demo Mode Toggle | 2-3h | Yes | Yes | Yes (algo+SwiftData) | Yes |
| B: HealthKit Seeding | 1-2h | No | Yes | Yes (full HK) | No |
| C: Hybrid (A+B) | 3-4h | Yes | Yes | Yes (both paths) | Yes |

## Chosen Solution: A - Demo Mode Toggle

### Rationale
- Covers simulator (primary dev environment) without physical device
- Exercises real `StressCalculator` + `StressRepository` + SwiftData pipeline
- Dynamic data with live HR streaming, historical trends, category transitions
- All code behind `#if DEBUG` — zero production impact
- Simplest to maintain; can add Option B later if needed

### Architecture

```
Launch Argument: -demo-mode
        |
StressMonitorApp
        |
   #if DEBUG check
        |
SimulatorHealthKitService (new)
   implements HealthKitServiceProtocol
        |
   Real StressCalculator ──> Real StressRepository ──> SwiftData
        |
   SwiftUI Views (unchanged)
```

### Key Component: SimulatorHealthKitService

New file: `Services/HealthKit/SimulatorHealthKitService.swift`

Implements `HealthKitServiceProtocol` with:

#### 1. Live Streaming HR Updates
- `observeHeartRateUpdates()` emits new HR every 3-5 seconds
- HR varies with simulated stress patterns using sine wave + noise
- Baseline HR 65bpm, range 55-110bpm

#### 2. Historical Trends (Days/Weeks)
- `fetchHRVHistory(since:)` generates 7-14 days of data
- Circadian rhythm: lower HRV at night, higher during day
- Day-to-day variation with weekly trend
- 3-5 measurements per day

#### 3. Edge Cases (All Stress Levels)
- Cycles through stress scenarios over time:
  - Relaxed: HRV 60-80ms, HR 55-65bpm
  - Mild: HRV 40-60ms, HR 65-80bpm
  - Moderate: HRV 25-40ms, HR 80-95bpm
  - High: HRV 15-25ms, HR 95-110bpm
- Low confidence scenarios: HRV < 20ms, extreme HR
- Missing data: occasional nil returns

#### 4. Stress Category Transitions
- Stress level changes every 30-60 seconds in demo
- Smooth transitions (not abrupt jumps)
- Follows realistic pattern: relaxed -> mild -> moderate -> back down

### Data Generation Strategy

```
Time-based simulation using sin/cos curves:

Base HRV = 50 + 20 * sin(timeOfDay * pi / 12)  // circadian
Noise    = random(-5...5)
Stress   = sin(elapsedTime / 60) * stressAmplitude  // cycling

Final HRV = clamp(Base + Noise - Stress, 15...80)
Final HR  = clamp(mapHRVtoHR(Final HRV) + noise, 55...110)
```

### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `Services/HealthKit/SimulatorHealthKitService.swift` | Create | Dynamic data generator implementing protocol |
| `StressMonitorApp.swift` | Modify | `#if DEBUG` demo mode check via launch argument |
| Xcode Scheme | Modify | Add `-demo-mode` launch argument (disabled by default) |

### Implementation Steps

1. Create `SimulatorHealthKitService` implementing `HealthKitServiceProtocol`
2. Add time-based HRV/HR generation with circadian + stress cycling
3. Implement `AsyncStream` for live HR with 3-5s interval
4. Generate historical data with day/week patterns
5. Add edge case scenarios (extreme values, nil returns)
6. Modify `StressMonitorApp` to check `-demo-mode` launch argument
7. Wire up with real `StressCalculator` + `StressRepository`
8. Add `-demo-mode` to Xcode scheme (unchecked by default)

### Success Criteria

- [ ] App runs on simulator with dynamic stress data
- [ ] All 4 stress categories appear during demo session
- [ ] Live HR updates visible on dashboard every 3-5s
- [ ] History/Trends views show 7+ days of data
- [ ] Edge cases (low confidence, extreme values) trigger correctly
- [ ] `#if DEBUG` wraps all demo code — no production impact
- [ ] Real `StressCalculator` processes the simulated inputs
- [ ] SwiftData persists demo measurements

### Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Demo data bleeds into production | All behind `#if DEBUG` + launch argument check |
| Synthetic patterns don't match real HRV | Use published HRV research ranges; good enough for UI testing |
| SwiftData fills with demo data | Add "Clear Demo Data" button in debug settings, or use in-memory container |
| Timer/AsyncStream leaks | Proper cancellation in `onTermination`, `Task` cancellation |

### Security

- No HealthKit entitlement needed for demo mode
- No real health data involved
- All code compiled out of release builds

## Unresolved Questions

1. Should demo mode use in-memory SwiftData container (clean each launch) or persistent (accumulate history)?
   - Recommendation: persistent by default, with clear button. Lets you test historical views naturally.
2. Should we add a visible "DEMO MODE" banner so it's obvious?
   - Recommendation: yes, small pill overlay in DEBUG builds when demo active.
