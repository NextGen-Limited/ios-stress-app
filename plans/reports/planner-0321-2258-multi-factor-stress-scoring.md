# Planner Report: Multi-Factor Stress Scoring

**Date:** 2026-03-21
**Plan:** `plans/0321-2251-multi-factor-stress-scoring/`
**Status:** Complete

---

## Summary

Created 5-phase implementation plan to evolve StressMonitor from 2-factor (HRV+HR) to 5-factor (HRV+HR+Sleep+Activity+Recovery) composite stress scoring. Architecture uses `StressFactor` protocol for extensibility and graceful degradation. Each phase is independently shippable.

## Plan Structure

| Phase | Title | Effort | Dependencies |
|-------|-------|--------|-------------|
| 1 | Fix Formula Science | 4h | None |
| 2 | Factor Architecture + Sleep | 8h | Phase 1 |
| 3 | Activity Factor | 4h | Phase 2 |
| 4 | Recovery Factor | 4h | Phase 2 |
| 5 | Calibration & Polish | 4h | Phases 3+4 |
| **Total** | | **24h** | |

## Key Decisions

- **Factor-based architecture** over flat parameter extension -- extensible, testable, graceful degradation
- **Sigmoid transforms** replace arbitrary `^0.8` and `atan` functions -- scientifically grounded
- **SDNN acknowledged** -- Apple HealthKit provides SDNN not RMSSD; baseline normalization still valid
- **Progressive permissions** -- each phase adds only the HealthKit types it needs
- **Lightweight SwiftData migration** -- all new StressMeasurement fields are optional
- **Weight redistribution** -- missing factors don't break the score; weights normalize across available data
- **watchOS mirrors iPhone** -- same factor protocol + implementations

## Files Created

- `plans/0321-2251-multi-factor-stress-scoring/plan.md`
- `plans/0321-2251-multi-factor-stress-scoring/phase-01-fix-formula-science.md`
- `plans/0321-2251-multi-factor-stress-scoring/phase-02-factor-architecture-sleep.md`
- `plans/0321-2251-multi-factor-stress-scoring/phase-03-activity-factor.md`
- `plans/0321-2251-multi-factor-stress-scoring/phase-04-recovery-factor.md`
- `plans/0321-2251-multi-factor-stress-scoring/phase-05-calibration-polish.md`

## New Swift Files (Across All Phases)

| File | Phase | Purpose |
|------|-------|---------|
| `StressFactor.swift` | 2 | Protocol + FactorResult |
| `StressContext.swift` | 2 | Input container |
| `SleepData.swift` | 2 | Sleep model |
| `FactorBreakdown.swift` | 2 | Per-factor output |
| `HRVStressFactor.swift` | 2 | Extracted HRV logic |
| `HeartRateStressFactor.swift` | 2 | Extracted HR logic |
| `SleepStressFactor.swift` | 2 | Sleep scoring |
| `MultiFactorStressCalculator.swift` | 2 | Orchestrator |
| `ActivityData.swift` | 3 | Activity model |
| `ActivityStressFactor.swift` | 3 | Activity scoring |
| `RecoveryData.swift` | 4 | Recovery model |
| `RecoveryStressFactor.swift` | 4 | Recovery scoring |
| `FactorCalibrator.swift` | 5 | Per-user weight tuning |
| `FactorWeights.swift` | 5 | Weight config |
| `DataQualityInfo.swift` | 5 | Quality metadata |
| `DataQualityBadge.swift` | 5 | UI badge |

## Codebase Impact

- **Modified files:** ~15 existing files across iPhone + watchOS
- **New files:** ~16 Swift files + mirrors for watchOS
- **Deleted files:** 0 (backward compatible)
- **New HealthKit permissions:** `.sleepAnalysis` (P2), `.stepCount`/`.activeEnergyBurned`/`.appleStandTime` (P3), `.respiratoryRate`/`.oxygenSaturation`/`.restingHeartRate` (P4)

## Unresolved Questions

1. **Sigmoid parameter tuning** -- k=4.0/x0=0.5 for HRV and k=3.0/x0=0.3 for HR are initial guesses. Need to compare old vs new output distributions on real data before shipping Phase 1.
2. **Sleep stage trust level** -- Apple Watch sleep staging accuracy is "moderate" vs polysomnography. Should deep/REM weights be discounted?
3. **Post-workout suppression duration** -- 2h grace period is a guess. May need user feedback to tune.
4. **Calibration sample threshold** -- 30 measurements minimum; might need 60+ for stable weight adjustment.
5. **Historical score transition** -- old single-factor scores in history will look different from new multi-factor ones. Phase 5 should address UI communication.
6. **watchOS battery profiling** -- need to measure actual battery impact of fetching 5+ HealthKit types in background refresh (Phase 3+4).
