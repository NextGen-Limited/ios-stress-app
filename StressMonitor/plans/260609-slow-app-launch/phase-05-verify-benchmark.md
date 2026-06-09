---
phase: 5
title: "Verify & Benchmark"
status: pending
effort: "1h"
dependencies: [2, 3, 4]
---

# Phase 5: Verify & Benchmark

## Overview

Measure the optimized cold start time against the baseline from Phase 1. Run the full test suite to verify no regressions. Produce a before/after comparison report.

## Requirements

- **Functional**: All 11 existing test files pass. No behavioral regressions.
- **Non-functional**: Measurable improvement in cold start time documented with evidence.

## Related Code Files

- Read: All modified files from Phases 2-4
- Execute: Full test suite via `xcodebuild test`
- Execute: Instruments → os_signpost for benchmarking

## Implementation Steps

### Step 1: Run full test suite

```bash
# Build and test
xcodebuild test \
  -scheme StressMonitor \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  -resultBundlePath ./build/TestResults.xcresult
```

Verify all 11 test files pass without modification:
- `StressMonitorTests/` (5): StressReadingTests, StressHistoryTests, HRVAnalyzerTests, StressPredictorTests, MorningReadinessServiceTests
- `StressMonitor/StressMonitorTests/` (1): StressMonitorTests
- UI tests (5): StressMonitorUITests, LaunchTests, Watch UITests ×2, Watch LaunchTests

### Step 2: Benchmark cold start with Instruments

1. Close simulator, wipe derived data
2. Profile the app with Instruments → Time Profiler / os_signpost
3. Measure:
   - T0→T1: App.init to MainTabView.body
   - T1→T2: MainTabView.body to DashboardView.body
   - T2→T3: DashboardView.body to loadInitialData() completion
   - Total: Time to first interactive frame

### Step 3: Produce before/after report

Create a benchmark comparison:

```
| Metric                     | Before | After | Improvement |
|----------------------------|--------|-------|-------------|
| App.init → first frame     | ~?ms   | ~?ms  | -?%         |
| FontBlaster time           | ~?ms   | 0ms*  | 100%*       |
| HealthKit queries total    | ~?ms   | ~?ms  | -?%         |
| loadInitialData total      | ~?ms   | ~?ms  | -?%         |
| Cold start to interactive  | ~?ms   | ~?ms  | -?%         |

* FontBlaster still runs, but async after first render
```

### Step 4: Smoke test critical paths

- [ ] Cold launch → dashboard shows loading → data appears
- [ ] Warm launch → cached data shows immediately
- [ ] HealthKit denied → permission card shows
- [ ] Demo mode (`-demo-mode` arg) → animated data loads
- [ ] Background → foreground → data refreshes
- [ ] Tab switching → Action tab, Trends tab work
- [ ] Settings → navigation works

### Step 5: Clean up instrumentation

Strip or conditionally compile the `os_signpost` markers from Phase 1:
```swift
#if DEBUG
os_signpost(.end, log: launchLog, name: "AppInit")
#endif
```

### Step 6: Update plan status

Mark all phases as completed. Archive the plan.

## Success Criteria

- [ ] All existing tests pass (11 test files)
- [ ] Cold start to interactive < 1.5s on iPhone 15 simulator
- [ ] Before/after benchmark comparison documented
- [ ] No behavioral regressions in smoke tests
- [ ] Instrumentation cleaned up for production
- [ ] Plan marked as completed
