---
phase: 5
title: "Calibration & Polish"
status: pending
priority: P3
effort: 4h
depends_on: [phase-03, phase-04]
---

# Phase 5: Calibration & Polish

## Context Links

- [Phase 2: Factor Architecture](./phase-02-factor-architecture-sleep.md)
- [Phase 3: Activity Factor](./phase-03-activity-factor.md)
- [Phase 4: Recovery Factor](./phase-04-recovery-factor.md)
- [MultiFactorStressCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift)
- [BaselineCalculator](../../StressMonitor/StressMonitor/Services/Algorithm/BaselineCalculator.swift)
- [PersonalBaseline](../../StressMonitor/StressMonitor/Models/PersonalBaseline.swift)
- [DashboardView](../../StressMonitor/StressMonitor/Views/Dashboard/HomeDashboardView.swift)

## Overview

Per-user weight calibration based on historical correlation, refined circadian baseline, and a data quality indicator in the UI. This phase tunes the multi-factor system for individual users after sufficient data accumulates.

**Priority:** P3
**Status:** pending

## Key Insights

1. **Individual variation is large** -- HRV ranges from 20-200ms across population. One user's "relaxed" is another's "stressed". Per-user calibration is essential for accuracy.
2. **30+ days of data** needed before calibration is meaningful
3. **Data quality badge** helps users understand when their score is less reliable (missing watch, skipped sleep tracking)
4. **Weight calibration** should be subtle -- adjust within +/-25% of default weights based on factor-to-perceived-stress correlation
5. **Circadian model** from Phase 1 can be refined with per-user hourly HRV patterns

## Requirements

### Functional
- Per-user factor weight calibration using historical data correlation
- Refined circadian baseline from user's own hourly HRV/HR patterns
- Data quality indicator in dashboard UI (shows which factors are active)
- Extended `PersonalBaseline` to store per-user weights and hourly baselines
- Calibration runs automatically after 30+ days of multi-factor data

### Non-Functional
- No new HealthKit permissions
- Calibration computation <2 seconds
- UI indicator is non-intrusive (badge/tooltip style)
- All files under 200 LOC

## Architecture

### Modified Types

```swift
// PersonalBaseline -- extend with calibration data
struct PersonalBaseline: Codable, Sendable {
    var restingHeartRate: Double
    var baselineHRV: Double
    var lastUpdated: Date

    // Phase 5 additions
    var factorWeights: FactorWeights?      // per-user calibrated weights
    var hourlyHRVBaseline: [Int: Double]?  // hour (0-23) -> avg HRV
    var hourlyHRBaseline: [Int: Double]?   // hour (0-23) -> avg resting HR
    var calibrationDate: Date?
}

struct FactorWeights: Codable, Sendable {
    var hrv: Double      // default 0.40
    var heartRate: Double // default 0.15
    var sleep: Double     // default 0.20
    var activity: Double  // default 0.15
    var recovery: Double  // default 0.10

    static let defaults = FactorWeights(
        hrv: 0.40, heartRate: 0.15, sleep: 0.20, activity: 0.15, recovery: 0.10
    )
}
```

### New Types

```swift
// File: StressMonitor/Services/Algorithm/FactorCalibrator.swift

final class FactorCalibrator: Sendable {

    /// Calibrate weights based on historical measurements
    /// Looks at which factors best predict the user's overall stress pattern
    func calibrate(from measurements: [StressMeasurement]) -> FactorWeights {
        guard measurements.count >= 30 else { return .defaults }

        // Calculate variance contribution of each factor
        let hrvVariance = varianceContribution(measurements.compactMap(\.hrvComponent))
        let hrVariance = varianceContribution(measurements.compactMap(\.hrComponent))
        let sleepVariance = varianceContribution(measurements.compactMap(\.sleepComponent))
        let activityVariance = varianceContribution(measurements.compactMap(\.activityComponent))
        let recoveryVariance = varianceContribution(measurements.compactMap(\.recoveryComponent))

        let totalVariance = hrvVariance + hrVariance + sleepVariance + activityVariance + recoveryVariance
        guard totalVariance > 0 else { return .defaults }

        // Adjust weights proportional to variance contribution
        // Clamp adjustment to +/-25% of defaults
        return FactorWeights(
            hrv: clampWeight(hrvVariance / totalVariance, default: 0.40),
            heartRate: clampWeight(hrVariance / totalVariance, default: 0.15),
            sleep: clampWeight(sleepVariance / totalVariance, default: 0.20),
            activity: clampWeight(activityVariance / totalVariance, default: 0.15),
            recovery: clampWeight(recoveryVariance / totalVariance, default: 0.10)
        )
    }

    /// Calculate hourly baselines from historical data
    func calculateHourlyBaseline(
        from measurements: [StressMeasurement]
    ) -> [Int: Double] {
        // Group measurements by hour, compute average HRV per hour
        var hourlyGroups: [Int: [Double]] = [:]
        for m in measurements {
            let hour = Calendar.current.component(.hour, from: m.timestamp)
            hourlyGroups[hour, default: []].append(m.hrv)
        }
        return hourlyGroups.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
    }

    private func varianceContribution(_ values: [Double]) -> Double {
        guard values.count >= 10 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    }

    private func clampWeight(_ calculated: Double, default defaultWeight: Double) -> Double {
        let minWeight = defaultWeight * 0.75  // -25%
        let maxWeight = defaultWeight * 1.25  // +25%
        return max(minWeight, min(maxWeight, calculated))
    }
}
```

```swift
// File: StressMonitor/Models/DataQualityInfo.swift

struct DataQualityInfo: Sendable {
    let activeFactors: [String]        // factor IDs that contributed
    let missingFactors: [String]       // factor IDs that were nil
    let dataCompleteness: Double       // 0-1
    let isCalibrated: Bool             // has per-user calibration been applied
    let lastCalibrationDate: Date?

    var qualityLevel: QualityLevel {
        switch dataCompleteness {
        case 0.8...1.0: return .excellent
        case 0.5..<0.8: return .good
        case 0.3..<0.5: return .limited
        default: return .minimal
        }
    }

    enum QualityLevel: String {
        case excellent  // 4-5 factors
        case good       // 3 factors
        case limited    // 2 factors
        case minimal    // 1 factor
    }
}
```

### UI Component

```swift
// File: StressMonitor/Views/Dashboard/Components/DataQualityBadge.swift

struct DataQualityBadge: View {
    let qualityInfo: DataQualityInfo

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(qualityInfo.qualityLevel.rawValue.capitalized)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.2))
        .cornerRadius(8)
    }

    private var iconName: String {
        switch qualityInfo.qualityLevel {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .limited: return "exclamationmark.circle"
        case .minimal: return "exclamationmark.triangle"
        }
    }

    private var backgroundColor: Color {
        switch qualityInfo.qualityLevel {
        case .excellent: return .green
        case .good: return .blue
        case .limited: return .yellow
        case .minimal: return .orange
        }
    }
}
```

## Related Code Files

### Files to Create
- `StressMonitor/StressMonitor/Services/Algorithm/FactorCalibrator.swift`
- `StressMonitor/StressMonitor/Models/DataQualityInfo.swift`
- `StressMonitor/StressMonitor/Models/FactorWeights.swift`
- `StressMonitor/StressMonitor/Views/Dashboard/Components/DataQualityBadge.swift`
- `StressMonitorTests/FactorCalibratorTests.swift`

### Files to Modify
- `StressMonitor/StressMonitor/Models/PersonalBaseline.swift` -- add calibration fields
- `StressMonitor/StressMonitor/Services/Algorithm/MultiFactorStressCalculator.swift` -- use calibrated weights
- `StressMonitor/StressMonitor/Services/Algorithm/BaselineCalculator.swift` -- hourly baseline calculation
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` -- trigger calibration, expose quality info
- `StressMonitor/StressMonitor/Views/Dashboard/HomeDashboardView.swift` -- show DataQualityBadge
- `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` -- store/fetch calibration data
- Mirror changes to watchOS where applicable

### Files to Delete
- None

## Implementation Steps

1. **Create `FactorWeights` model**
   - File: `Models/FactorWeights.swift`
   - Default weights matching brainstorm decisions
   - Codable + Sendable for persistence

2. **Extend `PersonalBaseline`**
   - Add `factorWeights: FactorWeights?`, `hourlyHRVBaseline: [Int: Double]?`, `calibrationDate: Date?`
   - Existing callers unaffected (optional fields)

3. **Create `FactorCalibrator`**
   - File: `Services/Algorithm/FactorCalibrator.swift`
   - `calibrate(from:)` -- variance-based weight adjustment, clamped to +/-25%
   - `calculateHourlyBaseline(from:)` -- group-by-hour averaging
   - Minimum 30 measurements required

4. **Create `DataQualityInfo` model**
   - File: `Models/DataQualityInfo.swift`
   - Active/missing factors, completeness, calibration status
   - Quality level enum (excellent/good/limited/minimal)

5. **Update `MultiFactorStressCalculator`**
   - Accept optional `FactorWeights` in init
   - If calibrated weights available, override default factor weights
   - Generate `DataQualityInfo` alongside `StressResult`

6. **Create `DataQualityBadge` view**
   - File: `Views/Dashboard/Components/DataQualityBadge.swift`
   - Compact badge with icon + label
   - Color-coded by quality level
   - Accessibility labels included

7. **Update `StressViewModel`**
   - Add `dataQualityInfo: DataQualityInfo?` property
   - Trigger calibration when loading baseline (if 30+ measurements exist)
   - Expose quality info to dashboard

8. **Integrate badge into dashboard**
   - Add `DataQualityBadge` to `HomeDashboardView` near stress score

9. **Write tests**
   - `FactorCalibratorTests`: weight adjustment clamping, insufficient data handling, hourly baseline
   - DataQualityInfo quality level thresholds

10. **Build and verify**

## TODO Checklist

- [ ] Create `FactorWeights.swift`
- [ ] Extend `PersonalBaseline` with calibration fields
- [ ] Create `FactorCalibrator.swift`
- [ ] Create `DataQualityInfo.swift`
- [ ] Update `MultiFactorStressCalculator` to use calibrated weights
- [ ] Create `DataQualityBadge.swift` view
- [ ] Update `StressViewModel` with calibration + quality info
- [ ] Integrate `DataQualityBadge` into dashboard
- [ ] Update `BaselineCalculator` with hourly baselines
- [ ] Write `FactorCalibratorTests`
- [ ] Build iPhone -- zero warnings
- [ ] Build watchOS -- zero warnings
- [ ] Run all tests -- 100% pass

## Success Criteria

- Per-user weights adjust within +/-25% of defaults after 30+ measurements
- Hourly HRV baselines computed and applied for circadian adjustment
- Data quality badge visible on dashboard
- Calibration completes in <2 seconds
- Users with limited data (1-2 factors) see "Limited" badge
- Users with full data (4-5 factors) see "Excellent" badge
- All tests pass

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Calibration overfits to noisy data | Medium | Clamp weights to +/-25%; require 30+ samples |
| Hourly baseline sparse for some hours | Low | Fall back to daily baseline for hours with <5 samples |
| Data quality badge confuses users | Low | Use tooltip/help text; positive framing ("Excellent" not "5/5") |
| PersonalBaseline struct grows too large | Low | Optional fields; Codable handles nil naturally |

## Security Considerations

- No new HealthKit permissions needed
- Calibration data stored in `PersonalBaseline` (local + CloudKit encrypted)
- No external API calls
- Weight adjustments are purely mathematical -- no user-identifying data exposed
