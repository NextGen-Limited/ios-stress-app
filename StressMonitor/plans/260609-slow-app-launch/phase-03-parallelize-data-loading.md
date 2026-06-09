---
phase: 3
title: "Parallelize Data Loading"
status: pending
effort: "2h"
dependencies: [2]
---

# Phase 3: Parallelize Data Loading

## Overview

Refactor the remaining sequential HealthKit data fetching into parallel `async let` operations. **Validation correction:** HRV + HR are already parallelized in the current code (lines 88-89). Only sleep/activity/recovery (3 queries) are still sequential. This phase focuses on parallelizing those 3 plus the higher-level `loadDashboardData()` flow.

## Requirements

- **Functional**: All HealthKit queries for the initial stress calculation run in parallel. Historical data loads in parallel with current stress calculation.
- **Non-functional**: No increase in HealthKit API calls. Proper error handling per-query (one query failing shouldn't block others).

## Architecture

### Before (Current — Partially Parallel)
```
loadInitialData()
  ├── loadBaseline()          ← await (includes fetchRecent(200) for calibration)
  ├── loadDashboardData()
  │     ├── loadCurrentStress()     ← await
  │     │     ├── fetchLatestHRV()   ← async let  ✅ ALREADY PARALLEL
  │     │     ├── fetchHeartRate(1)  ← async let  ✅ ALREADY PARALLEL
  │     │     ├── fetchSleepData()   ← try? await ❌ SEQUENTIAL
  │     │     ├── fetchActivityData()← try? await ❌ SEQUENTIAL
  │     │     └── fetchRecoveryData()← try? await ❌ SEQUENTIAL
  │     ├── loadHistoricalData(14)   ← await (sequential after loadCurrentStress)
  │     ├── loadTodayMeasurements()  ← sync
  │     ├── loadWeeklyComparison()   ← sync
  │     └── generateInsight()        ← sync
  └── observeHeartRate()
```

### After (Optimized — Parallel)
```
loadInitialData()
  ├── async let baselineTask = loadBaselineFast()     // cached or skip calibration
  ├── async let stressTask = loadCurrentStress()      // parallel HealthKit queries
  ├── async let historyTask = loadHistoricalData(14)  // parallel
  └── await all three, then compute derived data

loadCurrentStress() — parallelized:
  ├── async let hrv = fetchLatestHRV()
  ├── async let hr = fetchHeartRate(1)
  ├── async let sleep = fetchSleepData()
  ├── async let activity = fetchActivityData()
  ├── async let recovery = fetchRecoveryData()
  └── await all, build StressContext
```

## Related Code Files

- Modify: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` — refactor `loadCurrentStress()`, `loadDashboardData()`, `loadInitialData()`
- Modify: `StressMonitor/StressMonitor/Views/DashboardView.swift` — update `loadInitialData()` call
- Read: `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` — verify thread-safety of queries

## Implementation Steps

### Step 1: Parallelize the 3 remaining sequential HealthKit queries

The current code already parallelizes HRV + HR via `async let` (lines 88-89). Only sleep/activity/recovery are sequential. Fix:

```swift
func loadCurrentStress() async {
    isLoading = true
    defer { isLoading = false }

    do {
        let fetchedBaseline = try? await repository.getBaseline()
        let currentBaseline = baseline ?? fetchedBaseline ?? PersonalBaseline()

        // ALL 5 queries in parallel (HRV+HR were already async let, now add 3 more)
        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 1)
        async let sleepData: SleepData? = {
            try? await healthKit.fetchSleepData(for: Date())
        }()
        async let activityData: ActivityData? = {
            try? await healthKit.fetchActivityData(for: Date())
        }()
        async let recoveryData: RecoveryData? = {
            try? await healthKit.fetchRecoveryData(for: Date())
        }()

        let (hrvData, hrData, sleep, activity, recovery) = try await (
            hrv, hr, sleepData, activityData, recoveryData
        )

        guard let hrvValue = hrvData?.value else {
            errorMessage = "No HRV data available"
            return
        }

        let context = StressContext(
            baseline: currentBaseline,
            hrv: hrvValue,
            heartRate: hrData.first?.value ?? 70,
            sleepData: sleep,
            activityData: activity,
            recoveryData: recovery,
            lastReadingDate: hrvData?.timestamp
        )

        let result = try await algorithm.calculateMultiFactorStress(context: context)
        currentStress = result
        isPermissionRequired = false
        baseline = currentBaseline
        lastRefresh = Date()
        errorMessage = nil

        if let breakdown = result.factorBreakdown {
            dataQualityInfo = DataQualityInfo(from: breakdown, baseline: currentBaseline)
        }
    } catch let hkError as HKError where hkError.code == .errorAuthorizationDenied {
        isPermissionRequired = true
        currentStress = nil
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

**Note:** `HealthKitManager` is `@MainActor`, but `async let` still provides concurrency within the MainActor — queries are submitted to HealthKit concurrently and awaited in parallel. This is correct and safe. ✅

<!-- Updated: Validation Session 1 - Corrected: HRV+HR already parallel, focus on 3 remaining -->

### Step 2: Parallelize `loadDashboardData()`

```swift
func loadDashboardData() async {
    // Run stress calculation and history fetch in parallel
    async let stressTask: () = loadCurrentStress()
    async let historyTask: () = loadHistoricalData(days: 14)

    // Await both — they run concurrently
    let (_, _) = await (stressTask, historyTask)

    // These depend on the above completing
    loadTodayMeasurements()
    loadWeeklyComparison()
    generateInsight()
}
```

### Step 3: Fast-path baseline loading

```swift
/// Fast baseline load — skips calibration (deferred to Phase 2 background task)
func loadBaselineFast() async {
    do {
        let loadedBaseline = try await repository.getBaseline()
        baseline = loadedBaseline
        if let breakdown = currentStress?.factorBreakdown {
            dataQualityInfo = DataQualityInfo(from: breakdown, baseline: loadedBaseline)
        }
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### Step 4: Refactor DashboardView.loadInitialData()

```swift
private func loadInitialData() async {
    // Parallel: baseline + full dashboard data
    async let _: () = viewModel.loadBaselineFast()
    await viewModel.loadDashboardData()
    viewModel.observeHeartRate()

    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
        appearAnimation = true
    }
}
```

**Note**: `loadDashboardData()` already calls `loadCurrentStress()` internally, which uses `getBaseline()` as a fallback. So running `loadBaselineFast()` in parallel with `loadDashboardData()` means baseline is likely cached by the time stress calculation needs it.

### Step 5: Verify HealthKitManager thread safety

Confirm `HKHealthStore.execute()` is safe to call concurrently from multiple queries. Per Apple docs, `HKHealthStore` is thread-safe for query execution.

## Success Criteria

- [ ] All 5 HealthKit queries in `loadCurrentStress()` run via `async let`
- [ ] `loadDashboardData()` runs stress + history in parallel
- [ ] No sequential `await` chains that could be parallelized
- [ ] Error handling per-query (one failure doesn't cancel others)
- [ ] `loadBaselineFast()` returns cached baseline without calibration overhead
