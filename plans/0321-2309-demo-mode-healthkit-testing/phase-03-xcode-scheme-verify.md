# Phase 3: Xcode Scheme + Verification

## Priority: medium
## Status: completed
## Effort: small
## Depends on: Phase 2

## Overview

Configure Xcode scheme with `-demo-mode` launch argument and verify the full pipeline end-to-end on simulator.

## Key Insights

- Project uses auto-managed schemes (no `.xcscheme` files checked in)
- Launch arguments can be added via Xcode UI: Edit Scheme > Run > Arguments
- Alternative: create a shared scheme file so it persists across machines
- Verification must cover all 4 stress categories, live streaming, historical data, and edge cases

## Implementation Steps

### 1. Add launch argument to Xcode scheme

**Option A — Manual (recommended for single developer):**
1. Xcode > Product > Scheme > Edit Scheme
2. Run > Arguments > Arguments Passed on Launch
3. Add `-demo-mode` (unchecked by default)
4. Toggle checkbox to enable/disable

**Option B — Shared scheme (for team):**
Create shared scheme at: `StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor-Demo.xcscheme`

Recommend Option A since this is a single-developer project. Document the setup in README or CLAUDE.md.

### 2. Verification checklist

Build and run on simulator with `-demo-mode` enabled. Verify:

#### Dashboard
- [ ] Stress ring shows current level and updates
- [ ] Live heart rate updates every 3-5 seconds
- [ ] HRV mini chart populated
- [ ] AI insight generates from data
- [ ] Weekly comparison shows non-zero values
- [ ] "DEMO MODE" banner visible
- [ ] Factor breakdown shows contributions from all 5 factors (if UI exists)

#### Stress Categories
- [ ] Relaxed state appears (green, 0-25)
- [ ] Mild state appears (blue, 25-50)
- [ ] Moderate state appears (yellow, 50-75)
- [ ] High state appears (orange/red, 75-100)
- [ ] Transitions are smooth (not abrupt jumps)
- [ ] Full cycle completes within ~2.5 minutes

#### Multi-Factor Data
- [ ] Sleep data populated (total hours, deep/REM, efficiency)
- [ ] Activity data populated (steps, calories, stand hours)
- [ ] Recovery data populated (resp rate, SpO2, resting HR trend)
- [ ] Factor breakdown values change with stress scenario
- [ ] `dataCompleteness` near 1.0 for non-edge scenarios
- [ ] Edge scenario shows graceful degradation (missing factors)

#### Historical Data
- [ ] Trends view shows data for past 7+ days
- [ ] History view lists measurements
- [ ] Day detail view works
- [ ] Weekly comparison calculates correctly
- [ ] Persisted measurements include component fields (hrvComponent, sleepComponent, etc.)

#### Edge Cases
- [ ] Low HRV (<20ms) scenarios produce low confidence
- [ ] Missing data (nil HRV) handled gracefully — no crash
- [ ] Missing sleep/activity/recovery data triggers weight redistribution (not crash)
- [ ] Extreme HR values don't break UI
- [ ] Partial recovery data (some sub-metrics nil) handled

#### Production Safety
- [ ] App launches normally WITHOUT `-demo-mode` argument
- [ ] No "DEMO MODE" banner when disabled
- [ ] Release build compiles without demo code (no `#if DEBUG` leaks)

### 3. Document in CLAUDE.md

Add to Build & Test section:

```markdown
### Demo Mode (Simulator Testing)

To test with simulated HealthKit data:
1. Edit Scheme > Run > Arguments
2. Enable `-demo-mode` checkbox
3. Build and run on simulator

Demo mode provides:
- Dynamic 5-factor data (HRV, HR, Sleep, Activity, Recovery) cycling through all stress levels
- Live heart rate streaming every 3-5s
- 7-14 days of historical data
- Edge cases (low HRV, extreme HR, missing factors, partial recovery)
- Real MultiFactorStressCalculator + SwiftData pipeline (not static mocks)
- Graceful degradation testing (edge scenario omits sleep/activity/recovery)
```

## Todo List

- [ ] Add `-demo-mode` launch argument in Xcode scheme
- [ ] Build and run on simulator — verify dashboard
- [ ] Watch stress categories cycle through all 4 levels
- [ ] Check Trends/History views have historical data
- [ ] Verify edge cases don't crash
- [ ] Verify normal launch (no demo mode) still works
- [ ] Verify release build compiles cleanly
- [ ] Document demo mode setup in CLAUDE.md

## Success Criteria

- Demo mode fully functional on simulator
- All verification checklist items pass
- Normal (non-demo) app behavior unchanged
- Documentation updated
