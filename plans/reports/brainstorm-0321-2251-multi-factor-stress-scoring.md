# Brainstorm: Multi-Factor Stress Scoring

## Problem Statement

Current stress calculation is single-factor (HRV + HR only). Competitors like Garmin Body Battery, WHOOP, Fitbit use multi-factor models incorporating sleep, activity, and recovery. Need to evolve to a composite score while shipping incrementally.

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data sources | Full: HRV+HR+Sleep+Activity+Recovery | Maximum accuracy, competitive parity |
| Score model | Single composite 0-100 | Simpler UX, Garmin-style |
| Permission denial | Graceful degradation | Score works with available data, reduced confidence |
| watchOS | Mirrors iPhone (full multi-factor) | Independent experience on watch |
| Timeline | Ship incrementally | Phase per factor, each shippable independently |

## Current Architecture

```
HealthKitManager → fetchLatestHRV() + fetchHeartRate()
                        ↓
                  StressCalculator.calculateStress(hrv:, heartRate:)
                        ↓
                  StressResult (level, category, confidence)
                        ↓
                  StressMeasurement (@Model, SwiftData)
```

**Key constraints:**
- `StressAlgorithmServiceProtocol` takes only `hrv: Double, heartRate: Double`
- `HealthKitServiceProtocol` only fetches HRV and HR
- `StressMeasurement` stores: timestamp, stressLevel, hrv, restingHeartRate
- `PersonalBaseline` has: restingHeartRate, baselineHRV
- Separate `StressCalculator` exists for watchOS (duplicated)
- HealthKit currently requests only: `.heartRateVariabilitySDNN`, `.heartRate`

---

## Evaluated Approaches

### Approach A: Extend Current Protocol (Flat)

Add all new parameters directly to `calculateStress()`.

```swift
func calculateStress(hrv: Double, heartRate: Double,
                     sleepHours: Double?, sleepQuality: Double?,
                     activeEnergy: Double?, stepCount: Int?,
                     respiratoryRate: Double?, bloodOxygen: Double?) async throws -> StressResult
```

| Pros | Cons |
|------|------|
| Minimal structural change | Parameter explosion |
| Easy to understand | Every new factor changes the protocol |
| Quick to implement | Hard to test individual factors |
| | Violates Open/Closed principle |

### Approach B: Factor-Based Architecture (Recommended)

Each data source is a `StressFactor` that contributes a weighted component to the final score.

```swift
protocol StressFactor: Sendable {
    var id: String { get }
    var weight: Double { get }
    func calculate(context: StressContext) async throws -> FactorResult?
}

struct FactorResult {
    let value: Double        // 0-1 normalized
    let confidence: Double   // 0-1 how reliable
    let metadata: [String: Double]  // debug/display data
}

struct StressContext {
    let baseline: PersonalBaseline
    let timestamp: Date
    // raw inputs
    let hrv: Double?
    let heartRate: Double?
    let sleepData: SleepData?
    let activityData: ActivityData?
    let recoveryData: RecoveryData?
}
```

Factors:
1. `HRVStressFactor` (weight: 0.40) — RMSSD-based, sigmoid transform
2. `HeartRateStressFactor` (weight: 0.15) — HR vs resting baseline
3. `SleepStressFactor` (weight: 0.20) — duration + quality + consistency
4. `ActivityStressFactor` (weight: 0.15) — exercise load vs recovery
5. `RecoveryStressFactor` (weight: 0.10) — respiratory rate, SpO2, RHR trend

| Pros | Cons |
|------|------|
| Each factor is independently testable | More files/abstractions |
| Add/remove factors without changing protocol | Slightly higher learning curve |
| Weights can be tuned per-factor | Need careful weight normalization |
| Graceful degradation is natural (skip nil factors) | |
| Same architecture works on iPhone + watchOS | |

### Approach C: ML Model

Train a model on labeled stress data, ship as CoreML.

| Pros | Cons |
|------|------|
| Potentially most accurate | Need training data (don't have) |
| Handles non-linear interactions | Black box, hard to debug |
| Industry trend | Overkill for current stage |

**Verdict: Approach B** — extensible, testable, supports graceful degradation naturally.

---

## Recommended Architecture

### New HealthKit Data Types

```swift
// Additional HKQuantityTypes to request
.sleepAnalysis                    // HKCategoryType
.appleStandTime
.activeEnergyBurned
.stepCount
.respiratoryRate
.oxygenSaturation
.restingHeartRate
```

### New Models

```swift
struct SleepData: Sendable {
    let totalHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double
    let awakenings: Int
    let sleepEfficiency: Double   // time asleep / time in bed
    let bedtimeConsistency: Double // deviation from avg bedtime
}

struct ActivityData: Sendable {
    let stepCount: Int
    let activeEnergyKcal: Double
    let exerciseMinutes: Double
    let standHours: Int
    let lastWorkoutHoursAgo: Double?
}

struct RecoveryData: Sendable {
    let respiratoryRate: Double?
    let bloodOxygen: Double?
    let restingHRTrend: Double?  // delta from 7-day avg
}
```

### Weight Distribution

Based on research (WHOOP published model + Garmin patents):

| Factor | Weight | Justification |
|--------|--------|---------------|
| HRV (RMSSD) | 0.40 | Primary autonomic stress marker |
| Sleep | 0.20 | Strongest recovery predictor after HRV |
| Heart Rate | 0.15 | Secondary acute stress indicator |
| Activity | 0.15 | Exercise load affects stress/recovery balance |
| Recovery | 0.10 | Physiological recovery markers |

**When factors are missing:** Redistribute weights proportionally across available factors. Track `dataCompleteness` (0-1) in the result.

### Composite Score Calculation

```
For each available factor:
  component_i = factor_i.calculate(context) → FactorResult

Available factors only:
  totalWeight = sum(available factor weights)

Normalize:
  score = sum(component_i.value * (factor_i.weight / totalWeight)) * 100

Confidence:
  dataCompleteness = sum(available weights) / sum(all weights)
  avgFactorConfidence = avg(component_i.confidence)
  finalConfidence = dataCompleteness * 0.4 + avgFactorConfidence * 0.6
```

### StressMeasurement Schema Changes

```swift
@Model
public final class StressMeasurement {
    // existing
    public var timestamp: Date
    public var stressLevel: Double
    public var hrv: Double
    public var restingHeartRate: Double
    public var categoryRawValue: String
    public var confidences: [Double]?

    // new: factor breakdown for UI/debugging
    public var hrvComponent: Double?
    public var hrComponent: Double?
    public var sleepComponent: Double?
    public var activityComponent: Double?
    public var recoveryComponent: Double?
    public var dataCompleteness: Double?   // 0-1, how many factors available
}
```

**Migration:** Lightweight — all new fields are optional. Existing data stays valid.

---

## Incremental Shipping Plan

### Phase 1: Fix Formula Science (no new data sources)
- Switch HRV metric to explicitly use RMSSD (already `.heartRateVariabilitySDNN` = SDNN, need to clarify)
- Replace `^0.8` with sigmoid transform
- Replace `atan` HR with sigmoid
- Add circadian adjustment to baseline
- Improve confidence scoring (motion detection, signal quality)
- **Ship independently.** No new permissions needed.

### Phase 2: Factor Architecture + Sleep
- Introduce `StressFactor` protocol and `StressContext`
- Refactor existing HRV+HR into `HRVStressFactor` + `HeartRateStressFactor`
- Add `SleepStressFactor` — fetch sleep analysis from HealthKit
- New HealthKit permission: `.sleepAnalysis`
- Add sleep component display in UI
- Update `StressMeasurement` schema (additive migration)
- **Ship.** Biggest user-facing impact — sleep is the #1 missing factor.

### Phase 3: Activity
- Add `ActivityStressFactor`
- Fetch: steps, active energy, workouts, stand hours
- New permissions: `.stepCount`, `.activeEnergyBurned`, `.appleStandTime`
- Adjust weights when activity data available
- **Ship.**

### Phase 4: Recovery
- Add `RecoveryStressFactor`
- Fetch: respiratory rate, SpO2, resting HR trends
- New permissions: `.respiratoryRate`, `.oxygenSaturation`, `.restingHeartRate`
- **Ship.**

### Phase 5: Calibration & Polish
- Per-user weight calibration based on historical correlation
- Time-of-day baseline adjustments
- "Data quality" indicator in UI
- Onboarding explaining multi-factor approach

---

## Operational Concerns

| Concern | Mitigation |
|---------|------------|
| HealthKit permission prompt grows | Progressive permission requests per phase |
| Sleep data unavailable (no Apple Watch overnight) | Graceful degradation, show "limited data" badge |
| Factor weight tuning | Store weights in config, not hardcoded. A/B testable |
| watchOS memory/battery | Factor calculations are lightweight math, no concern |
| SwiftData migration | All new fields optional — lightweight migration |
| Backward compatibility | Old measurements render fine (nil components = single-factor) |

## Security

- All new HealthKit types are read-only (no writes)
- Sleep/activity data stays local (SwiftData) + encrypted CloudKit
- No new external API calls or third-party services

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| SDNN vs RMSSD confusion | High | Apple provides SDNN via HealthKit, not raw RMSSD. Need to document this limitation clearly |
| Weight distribution is still arbitrary | Medium | Start with research-backed defaults, add per-user calibration in Phase 5 |
| Users expect accuracy comparable to WHOOP | Medium | Transparency about data quality and limitations |
| Factor architecture overengineering | Low | Each factor is <50 LOC. Abstraction earns its keep at 3+ factors |

## Unresolved Questions

1. **SDNN vs RMSSD:** Apple HealthKit provides `.heartRateVariabilitySDNN` — is SDNN sufficient or do we need to compute RMSSD from raw RR intervals? (HealthKit doesn't expose raw RR intervals easily)
2. **Sleep stage accuracy:** Apple Watch sleep staging is less accurate than polysomnography. How much should we trust deep/REM categorization?
3. **Workout detection:** Should recent high-intensity workout suppress stress score (elevated HR is expected) or should we track it separately?
4. **Circadian adjustment curve:** What time-of-day curve should we use for baseline adjustment? Linear decline or research-backed circadian HRV curve?
5. **watchOS battery impact:** Fetching 5+ HealthKit types on watch — need to profile background refresh energy cost
6. **Existing user experience:** When Phase 2 ships, old single-factor scores in history will look different from new multi-factor ones. How to communicate this transition?
