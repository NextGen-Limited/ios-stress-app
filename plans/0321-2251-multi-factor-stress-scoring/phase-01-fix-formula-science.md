---
phase: 1
title: "Fix Formula Science"
status: pending
priority: P1
effort: 4h
---

# Phase 1: Fix Formula Science

## Context Links

- [Current StressCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift)
- [Current BaselineCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/BaselineCalculator.swift)
- [Watch StressCalculator](../../StressMonitor/StressMonitorWatch%20Watch%20App/Services/StressCalculator.swift)
- [Researcher Report](../reports/researcher-0321-2243-stress-formula-validation.md)
- [StressCalculatorTests](../../StressMonitor/StressMonitorTests/StressCalculatorTests.swift)

## Overview

Replace arbitrary math transforms (`^0.8` power function, `atan` HR scaling) with scientifically-grounded sigmoid functions. Improve confidence scoring with recency and data quality checks. No new data sources or permissions needed -- purely algorithmic improvement.

**Priority:** P1 -- Foundation for all subsequent phases
**Status:** pending

## Key Insights

1. **Power function `^0.8` is arbitrary** -- no published research justifies it; dampens extreme stress signals
2. **`atan` for HR is unconventional** -- not found in stress algorithm literature
3. **Sigmoid** is standard in physiology/ML, well-documented, easier to tune
4. **Confidence scoring** is oversimplified -- misses recency, motion detection, data quality
5. **Apple provides SDNN** via `.heartRateVariabilitySDNN`, not RMSSD -- we must acknowledge this but it's still usable for relative stress detection via baseline normalization
6. **Circadian adjustment** absent -- HRV naturally declines through the day

## Requirements

### Functional
- Replace `pow(normalizedHRV, 0.8)` with sigmoid transform
- Replace `atan(normalizedHR * 2) / (pi/2)` with sigmoid transform
- Add recency penalty to confidence scoring (stale data = lower confidence)
- Add circadian baseline adjustment (optional, time-of-day aware)
- Explicitly document SDNN usage in code comments

### Non-Functional
- Stress calculation remains <1 second
- All existing tests must pass (update expected values)
- No new HealthKit permissions
- No SwiftData schema changes
- Both iPhone and watchOS calculators updated identically

## Architecture

### Modified Types

```swift
// StressCalculator.swift -- replace private helper methods
final class StressCalculator: StressAlgorithmServiceProtocol {

    /// Sigmoid transform: maps normalized value to 0-1 curve
    /// k controls steepness (default 4.0), x0 is midpoint (default 0.5)
    private func sigmoid(_ x: Double, k: Double = 4.0, x0: Double = 0.5) -> Double {
        1.0 / (1.0 + exp(-k * (x - x0)))
    }

    /// Replaces pow(normalizedHRV, 0.8)
    private func calculateHRVComponent(_ normalizedHRV: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHRV))
        return sigmoid(clamped, k: 4.0, x0: 0.5)
    }

    /// Replaces atan(normalizedHR * 2) / (pi/2)
    private func calculateHRComponent(_ normalizedHR: Double) -> Double {
        let clamped = max(0, min(2.0, normalizedHR))
        return sigmoid(clamped, k: 3.0, x0: 0.3)
    }
}
```

### Improved Confidence Scoring

```swift
func calculateConfidence(hrv: Double, heartRate: Double, samples: Int,
                          lastReadingDate: Date? = nil) -> Double {
    var confidence = 1.0

    // Low HRV penalty (gradual, not binary)
    if hrv < 20 {
        confidence *= max(0.3, hrv / 20.0)
    }

    // Extreme HR penalty (gradual)
    if heartRate < 50 || heartRate > 160 {
        let deviation = heartRate < 50 ? (50 - heartRate) / 50 : (heartRate - 160) / 160
        confidence *= max(0.4, 1.0 - deviation)
    }

    // Sample count factor
    let sampleFactor = min(1.0, Double(samples) / 10.0)
    confidence *= (0.7 + sampleFactor * 0.3)

    // Recency penalty: confidence decays if data is stale
    if let lastDate = lastReadingDate {
        let minutesAgo = Date().timeIntervalSince(lastDate) / 60.0
        let recencyFactor = max(0.3, 1.0 - (minutesAgo / 120.0))
        confidence *= recencyFactor
    }

    return max(0.0, min(1.0, confidence))
}
```

### Circadian Baseline Adjustment

```swift
// BaselineCalculator.swift -- add circadian adjustment
func circadianAdjustment(for hour: Int) -> Double {
    // HRV is ~10-15% higher in morning, declines through day
    // Simplified cosine model peaking at 6 AM
    let radians = Double(hour - 6) * .pi / 12.0
    return 1.0 + 0.1 * cos(radians) // +-10% adjustment
}
```

## Related Code Files

### Files to Modify
- `StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift` -- sigmoid transforms, confidence
- `StressMonitor/StressMonitorWatch Watch App/Services/StressCalculator.swift` -- mirror changes
- `StressMonitor/StressMonitor/Services/Algorithm/BaselineCalculator.swift` -- circadian adjustment
- `StressMonitor/StressMonitorTests/StressCalculatorTests.swift` -- update expected values

### Files to Create
- None

### Files to Delete
- None

## Implementation Steps

1. **Add sigmoid helper** to `StressCalculator.swift` (both iPhone and watchOS)
   - Private function `sigmoid(_ x: Double, k: Double, x0: Double) -> Double`
   - Parameters: k=4.0 steepness, x0=0.5 midpoint (tunable)

2. **Replace `calculateHRVComponent`**
   - Remove `pow(value, 0.8)`
   - Use `sigmoid(clamped, k: 4.0, x0: 0.5)`
   - Clamp input to [0, 2.0] range

3. **Replace `calculateHRComponent`**
   - Remove `atan(scaled) / (.pi / 2)`
   - Use `sigmoid(clamped, k: 3.0, x0: 0.3)` -- lower midpoint since HR elevation matters more at smaller deviations
   - Clamp input to [0, 2.0] range

4. **Improve `calculateConfidence`**
   - Replace binary `hrv < 20 → *0.5` with gradual penalty
   - Replace binary HR check with gradual penalty
   - Add `lastReadingDate` parameter for recency
   - Add default parameter value so existing callers don't break

5. **Add circadian adjustment** to `BaselineCalculator`
   - `circadianAdjustment(for hour: Int) -> Double`
   - Cosine model peaking at 6 AM
   - Applied in `StressCalculator.normalizeHRV()` when baseline is accessed

6. **Add SDNN documentation** -- code comments explaining Apple Watch provides SDNN, not RMSSD, and why baseline normalization still works

7. **Update `StressAlgorithmServiceProtocol`** -- add optional `lastReadingDate` param to `calculateConfidence`

8. **Update watchOS `StressCalculator`** -- mirror all changes from iPhone version

9. **Update tests** -- adjust expected stress levels for sigmoid outputs; add tests for:
   - Sigmoid boundary conditions (0, 0.5, 1.0, 2.0 inputs)
   - Gradual confidence decay
   - Circadian adjustment values at different hours
   - Recency penalty decay

10. **Build and verify** -- compile both targets, run all tests

## TODO Checklist

- [ ] Add `sigmoid()` helper to iPhone `StressCalculator`
- [ ] Replace `calculateHRVComponent` with sigmoid
- [ ] Replace `calculateHRComponent` with sigmoid
- [ ] Improve `calculateConfidence` with gradual penalties + recency
- [ ] Add `circadianAdjustment()` to `BaselineCalculator`
- [ ] Wire circadian adjustment into HRV normalization
- [ ] Update `StressAlgorithmServiceProtocol` signature
- [ ] Mirror all changes to watchOS `StressCalculator`
- [ ] Add SDNN documentation comments
- [ ] Update `StressCalculatorTests` expected values
- [ ] Add sigmoid boundary tests
- [ ] Add confidence gradual decay tests
- [ ] Add circadian adjustment tests
- [ ] Build iPhone target -- zero warnings
- [ ] Build watchOS target -- zero warnings
- [ ] Run all tests -- 100% pass

## Success Criteria

- All stress calculations use sigmoid transforms (no `pow`, no `atan`)
- Confidence scoring degrades gradually (not binary thresholds)
- Recency penalty reduces confidence for stale readings
- Circadian adjustment applied to baseline
- All existing tests pass with updated expected values
- New tests cover sigmoid, confidence, and circadian logic
- Both iPhone and watchOS calculators are identical
- Stress calculation <1 second

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Sigmoid parameters produce different stress distribution | Medium | Compare old vs new outputs on test data before committing |
| Existing test expectations break | Low | Update expected values to match sigmoid outputs |
| Circadian model oversimplified | Low | Start with cosine model; refine in Phase 5 |

## Security Considerations

- No new data access -- uses same HRV + HR inputs
- No new permissions required
- No network calls
