---
phase: 2
title: "Defer Non-Critical Startup Work"
status: pending
effort: "2h"
dependencies: [1]
---

# Phase 2: Defer Non-Critical Startup Work

## Overview

Move operations that block the initial render off the critical launch path. The user should see the dashboard UI (with loading indicators) immediately, while heavy work happens in the background.

## Requirements

- **Functional**: Dashboard renders skeleton/loading state within 400ms. FontBlaster, baseline calibration, and historical data loading happen after initial render.
- **Non-functional**: No visual regressions. Fonts may flash from system → custom on first render (acceptable trade-off).

## Architecture

### Before (Current)
```
App.init() { FontBlaster.blast() }  ← BLOCKS
     ↓
MainTabView.body
     ↓
DashboardView.body
     ↓
.task { loadBaseline() → loadDashboardData() }  ← SEQUENTIAL, BLOCKS CONTENT
```

### After (Optimized)
```
App.init() { /* no FontBlaster */ }
     ↓
MainTabView.body
     ↓
DashboardView.body → immediate skeleton render
     ↓
.task {
    async let _ = loadFonts()           // background
    async let _ = loadDashboardData()   // parallel
    await loadBaseline()                // non-blocking for UI
}
```

## Related Code Files

- Modify: `StressMonitor/StressMonitorApp.swift` — remove `FontBlaster.blast()` from `init()`
- Modify: `StressMonitor/StressMonitor/Views/DashboardView.swift` — show skeleton state, defer font loading
- Modify: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` — defer baseline calibration to background
- Modify: `StressMonitor/StressMonitor/Utilities/FontBlaster.swift` — add async wrapper (optional)

## Implementation Steps

### Step 1: Remove FontBlaster from App.init()

In `StressMonitorApp.swift`:
```swift
// REMOVE from init():
init() {
    FontBlaster.blast()  // ← DELETE THIS
}

// init() should be empty or removed entirely
```

### Step 2: Load fonts asynchronously in DashboardView

Add font loading as a fire-and-forget task:
```swift
// In DashboardView, add to .task block:
.task {
    if !appeared {
        appeared = true
        // Load fonts in background — accepted: <200ms font flash on cold start only
        Task.detached(priority: .utility) {
            FontBlaster.blast()
        }
        // Show skeleton immediately, load data async
        await loadInitialData()
        viewModel.startAutoRefresh()
    }
}
```

FontBlaster uses CoreText (not MainActor-bound), so `Task.detached` is safe here. ✅
Custom fonts will flash from system → custom — accepted trade-off for faster launch.

### Step 3: Add loading skeleton to DashboardView

Ensure `dashboardContent()` handles `nil` stress gracefully with skeleton views:
```swift
// Already partially handled — stress is nil initially
// Verify all child views handle nil with loading placeholders
```

### Step 4: Defer baseline calibration

**Important:** `StressRepository` is `@MainActor` — must use `Task {}` (not `Task.detached`) to stay on MainActor pool.

In `StressViewModel.loadBaseline()`:
```swift
func loadBaseline() async {
    isLoading = true
    defer { isLoading = false }

    do {
        // Fast path: return cached baseline immediately
        var loadedBaseline = try await repository.getBaseline()
        baseline = loadedBaseline
        
        // Defer calibration — Task (NOT Task.detached) because repository is @MainActor
        Task { [weak self] in
            guard let self else { return }
            let measurements = try? await self.repository.fetchRecent(limit: 200)
            if let measurements, measurements.count >= 30 {
                let weights = self.calibrator.calibrate(from: measurements)
                let hourly = self.calibrator.calculateHourlyBaseline(from: measurements)
                loadedBaseline.factorWeights = weights
                loadedBaseline.hourlyHRVBaseline = hourly
                loadedBaseline.calibrationDate = Date()
                try? await self.repository.updateBaseline(loadedBaseline)
                self.baseline = loadedBaseline
            }
        }
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

<!-- Updated: Validation Session 1 - Task.detached → Task {} for @MainActor safety -->

### Step 5: Show immediate visual feedback

Ensure `DashboardView` shows a shimmer/skeleton for the stress character card while data loads, not just an empty screen.

## Success Criteria

- [ ] `FontBlaster.blast()` removed from `StressMonitorApp.init()`
- [ ] Dashboard renders within 400ms (skeleton state) on cold start
- [ ] Baseline calibration runs in background, doesn't block initial data load
- [ ] Custom fonts load asynchronously without blocking main thread
- [ ] No blank screen — skeleton/loading state visible immediately
