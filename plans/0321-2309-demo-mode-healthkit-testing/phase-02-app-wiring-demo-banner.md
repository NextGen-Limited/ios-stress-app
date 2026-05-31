# Phase 2: App Wiring + Demo Banner

## Priority: high
## Status: completed
## Effort: small
## Depends on: Phase 1

## Overview

Wire `SimulatorHealthKitService` into the app via launch argument detection. Replace existing `useMockData` static approach with proper demo mode. Add "DEMO MODE" pill banner overlay. Use `MultiFactorStressCalculator` (from multi-factor plan) so all 5 factors flow through the real pipeline.

## Context Links

- App entry: `StressMonitor/StressMonitorApp.swift`
- MainTabView: `StressMonitor/Views/MainTabView.swift`
- DashboardView: `StressMonitor/Views/DashboardView.swift`
- StressViewModel init: `StressMonitor/ViewModels/StressViewModel.swift:56-64`
- StressRepository init: `StressMonitor/Services/Repository/StressRepository.swift:23-34`

## Key Insights

- `MainTabView.useMockData` currently checks `XCODE_RUNNING_FOR_PREVIEWS` — confusing logic (returns `true` when NOT in previews)
- When `useMockData == true`, uses `PreviewDataFactory.mockDashboardViewModel()` — static data, no real pipeline
- Demo mode should use real `MultiFactorStressCalculator` + `StressRepository` but with `SimulatorHealthKitService`
- `StressViewModel.startAutoRefresh()` has `#if targetEnvironment(simulator) return` — demo mode needs its own refresh mechanism
- `DashboardView` already accepts optional `viewModel` parameter — can inject demo-configured one

## Related Code Files

- Modify: `StressMonitor/StressMonitor/StressMonitorApp.swift`
- Modify: `StressMonitor/StressMonitor/Views/MainTabView.swift`
- Create: `StressMonitor/StressMonitor/Views/Components/DemoModeBannerView.swift`

## Implementation Steps

### 1. Add DemoMode check utility

In `StressMonitorApp.swift`, add a simple static check:

```swift
#if DEBUG
enum DemoMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo-mode")
}
#endif
```

### 2. Modify MainTabView

Replace current `useMockData` approach:

```swift
// Before:
static var useMockData: Bool = { ... }()

// After:
static var useMockData: Bool = {
    #if DEBUG
    return DemoMode.isEnabled
    #else
    return false
    #endif
}()
```

Change the `case .home` branch to create `StressViewModel` with `SimulatorHealthKitService` + `MultiFactorStressCalculator` instead of `PreviewDataFactory.mockDashboardViewModel()`:

```swift
case .home:
    if Self.useMockData {
        DashboardView(
            viewModel: StressViewModel(
                healthKit: SimulatorHealthKitService(),
                algorithm: MultiFactorStressCalculator(),  // full 5-factor pipeline
                repository: StressRepository(modelContext: modelContext)
            ),
            onSettingsTapped: { showSettings = true }
        )
    } else {
        // existing real path unchanged
    }
```

This wires all 5 simulated factors through the real multi-factor algorithm + real persistence. The `StressViewModel` builds `StressContext` from `SimulatorHealthKitService` data (HRV, HR, sleep, activity, recovery) and passes it to `MultiFactorStressCalculator.calculateMultiFactorStress(context:)`.

### 3. Handle startAutoRefresh() for demo mode

The `StressViewModel.startAutoRefresh()` returns early on simulator. For demo mode, the live data comes through `observeHeartRateUpdates()` on `SimulatorHealthKitService` which uses `Task.sleep` instead of `HKObserverQuery`. The `DashboardView` already calls `viewModel.observeHeartRate()` — verify this path works.

If `startAutoRefresh()` is still needed for periodic stress recalculation, add a demo-mode timer path:

```swift
func startAutoRefresh() {
    #if targetEnvironment(simulator)
    // In demo mode, use timer-based refresh instead of HKObserverQuery
    #if DEBUG
    if DemoMode.isEnabled {
        startDemoAutoRefresh()
        return
    }
    #endif
    return
    #else
    // existing HKObserverQuery code
    #endif
}
```

### 4. Create DemoModeBannerView

Small pill overlay shown when demo mode is active:

```swift
#if DEBUG
struct DemoModeBannerView: View {
    var body: some View {
        Text("DEMO MODE")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange.opacity(0.8), in: Capsule())
    }
}
#endif
```

### 5. Add banner to MainTabView

Overlay the banner in top-trailing corner when demo mode is active:

```swift
.overlay(alignment: .topTrailing) {
    #if DEBUG
    if DemoMode.isEnabled {
        DemoModeBannerView()
            .padding(.trailing, 16)
            .padding(.top, 8)
    }
    #endif
}
```

## Todo List

- [ ] Add `DemoMode` enum with `isEnabled` static check
- [ ] Replace `useMockData` logic to use `DemoMode.isEnabled`
- [ ] Update `case .home` to create `StressViewModel` with `SimulatorHealthKitService`
- [ ] Handle `startAutoRefresh()` for demo mode (timer-based or via `observeHeartRate()`)
- [ ] Create `DemoModeBannerView.swift`
- [ ] Add banner overlay to `MainTabView`
- [ ] Verify TrendsView / HistoryView also display demo data from SwiftData

## Success Criteria

- App launches in demo mode with `-demo-mode` argument
- Dashboard shows live, changing stress data
- Real `MultiFactorStressCalculator` processes all 5 factors from `SimulatorHealthKitService`
- `StressResult.factorBreakdown` shows non-nil values for all available factors
- `StressRepository` persists measurements with component fields to SwiftData
- "DEMO MODE" banner visible in top corner
- Without `-demo-mode`, app behaves exactly as before
- No `#if DEBUG` code leaks into release builds

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `DemoMode` referenced outside `#if DEBUG` | Keep all usages inside `#if DEBUG` blocks |
| ViewModel created multiple times on tab switch | `@State` in `MainTabView` persists across re-renders |
| TrendsView ignores demo data | TrendsView queries SwiftData directly — demo measurements persist there |
