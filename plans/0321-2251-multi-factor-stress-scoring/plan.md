---
title: "Multi-Factor Stress Scoring"
description: "Evolve stress calculation from HRV+HR to composite score with sleep, activity, and recovery factors"
status: pending
priority: P1
effort: 24h
branch: main
tags: [algorithm, healthkit, multi-factor, architecture]
created: 2026-03-21
---

# Multi-Factor Stress Scoring

## Summary

Evolve StressMonitor from a 2-factor (HRV+HR) to a 5-factor (HRV+HR+Sleep+Activity+Recovery) composite stress score. Uses a `StressFactor` protocol architecture for extensibility and graceful degradation. Ships incrementally -- each phase is independently shippable.

## Context

- **Brainstorm:** [brainstorm-0321-2251-multi-factor-stress-scoring.md](../reports/brainstorm-0321-2251-multi-factor-stress-scoring.md)
- **Research:** [researcher-0321-2243-stress-formula-validation.md](../reports/researcher-0321-2243-stress-formula-validation.md)
- **Architecture:** [system-architecture.md](../../docs/system-architecture.md)

## Architecture Decision

**Factor-based architecture** (Approach B from brainstorm). Each data source is a `StressFactor` contributing a weighted component. Factors are independently testable, removable, and support graceful degradation when data is unavailable.

```
HealthKitManager → fetchAll() → StressContext
                                     ↓
                        [HRVFactor, HRFactor, SleepFactor, ActivityFactor, RecoveryFactor]
                                     ↓
                          MultiFactorStressCalculator.combine()
                                     ↓
                          StressResult (level, category, confidence, factorBreakdown)
                                     ↓
                          StressMeasurement (SwiftData, optional component fields)
```

## Weight Distribution

| Factor | Weight | Data Source |
|--------|--------|-------------|
| HRV | 0.40 | `.heartRateVariabilitySDNN` |
| Sleep | 0.20 | `.sleepAnalysis` (category) |
| Heart Rate | 0.15 | `.heartRate` |
| Activity | 0.15 | `.stepCount`, `.activeEnergyBurned`, `.appleStandTime` |
| Recovery | 0.10 | `.respiratoryRate`, `.oxygenSaturation`, `.restingHeartRate` |

When factors are missing, weights redistribute proportionally across available factors.

## Phases

| # | Phase | Status | Effort | Shippable? |
|---|-------|--------|--------|------------|
| 1 | [Fix Formula Science](./phase-01-fix-formula-science.md) | pending | 4h | Yes |
| 2 | [Factor Architecture + Sleep](./phase-02-factor-architecture-sleep.md) | pending | 8h | Yes |
| 3 | [Activity Factor](./phase-03-activity-factor.md) | pending | 4h | Yes |
| 4 | [Recovery Factor](./phase-04-recovery-factor.md) | pending | 4h | Yes |
| 5 | [Calibration & Polish](./phase-05-calibration-polish.md) | pending | 4h | Yes |

## Key Constraints

- iOS 17+ / watchOS 10+ (SwiftUI, SwiftData, @Observable)
- No external dependencies (system frameworks only)
- MVVM + protocol-based DI
- All new `StressMeasurement` fields must be optional (lightweight migration)
- PascalCase for Swift files, kebab-case for non-Swift
- Files under 200 LOC
- watchOS mirrors iPhone (shared `StressFactor` protocol + implementations)

## Risk Summary

| Risk | Severity | Mitigation |
|------|----------|------------|
| SDNN vs RMSSD limitation | High | Apple provides SDNN only; document limitation, use SDNN with sigmoid |
| Sleep data unavailable | Medium | Graceful degradation; "limited data" badge |
| Weight tuning guesswork | Medium | Research-backed defaults, Phase 5 per-user calibration |
| SwiftData migration | Low | All new fields optional -- lightweight migration |
| watchOS battery | Low | Factor calcs are lightweight math; profile in Phase 3 |

## Dependencies

- Phase 1 has no external dependencies (formula improvement only)
- Phase 2 depends on Phase 1 (introduces factor architecture)
- Phases 3-4 depend on Phase 2 (add factors to existing architecture)
- Phase 5 depends on Phases 3-4 (calibration needs all factors)
