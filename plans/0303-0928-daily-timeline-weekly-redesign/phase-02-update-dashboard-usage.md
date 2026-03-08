# Phase 2: Add DailyTimelineView to StressDashboardView

**Status:** ✅ Completed
**Priority:** Medium
**Effort:** ~30 minutes
**File:** `StressMonitor/StressMonitor/Views/Dashboard/StressDashboardView.swift`

---

## Context Links
- Phase 1: `phase-01-rewrite-daily-timeline-view.md`
- Dashboard view: `Views/Dashboard/StressDashboardView.swift`
- Dashboard VM: `Views/Dashboard/DashboardViewModel.swift`
- Repository: `Services/Repository/StressRepository.swift`

---

## Overview

`DailyTimelineView` is currently an orphan — it exists but is never used. After Phase 1 rewrites it as a weekly chart, add it to `StressDashboardView` so users can see their last 7 days of stress patterns.

The chart needs `[StressMeasurement]` for the last 7 days. `DashboardViewModel` already fetches up to 50 recent measurements via `repository.fetchRecent(limit: 50)` — expose this as a property.

---

## Related Code Files

**Modify:**
- `StressMonitor/StressMonitor/Views/Dashboard/StressDashboardView.swift`
- `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift`

---

## Implementation Steps

### Step 1: Expose weekly measurements in DashboardViewModel

Add a stored property that `refreshStressLevel()` populates:

```swift
// In DashboardViewModel
var weeklyMeasurements: [StressMeasurement] = []
```

In `refreshStressLevel()`, after `let (_, _, _, weeklyData) = try await (...)`:
```swift
weeklyMeasurements = weeklyData  // already fetched (limit: 50 covers 7 days)
```

### Step 2: Add DailyTimelineView to contentView

In `StressDashboardView.contentView(viewModel:)`, insert after the `quickStatsRow`:

```swift
// Weekly timeline chart
DailyTimelineView(measurements: viewModel.weeklyMeasurements)
    .padding(.horizontal)
```

Full updated scroll content:
```swift
VStack(spacing: 20) {
    header
        .padding(.horizontal)
        .padding(.top, 16)

    if let stress = viewModel.currentStress {
        StressCharacterCard(result: stress, size: .dashboard)
            .padding(.horizontal)
    }

    quickStatsRow
        .padding(.horizontal)

    // ← INSERT HERE
    DailyTimelineView(measurements: viewModel.weeklyMeasurements)
        .padding(.horizontal)

    BreathingExerciseCTA { showingBreathing = true }
        .padding(.horizontal)

    if let insight = viewModel.aiInsight {
        AIInsightCard(insight: insight) { showingBreathing = true }
            .padding(.horizontal)
    }

    Spacer().frame(height: 80)
}
```

### Step 3: Verify no other changes needed

- `StressRepository.fetchRecent(limit:)` already returns measurements sorted by timestamp desc — confirmed from `refreshStressLevel()` usage
- 50 measurements covers ~7 days for a user measuring 2–3x daily
- No new async calls, no new data fetching needed

---

## Todo

- [x] Add `var weeklyMeasurements: [StressMeasurement] = []` to `DashboardViewModel`
- [x] Populate it in `refreshStressLevel()`
- [x] Add `DailyTimelineView(measurements: viewModel.weeklyMeasurements)` in `StressDashboardView`
- [x] Build and check no compile errors
- [x] Visually verify chart appears below quickStatsRow

---

## Success Criteria

- Dashboard shows the weekly dot-matrix chart below the quick stats row
- Chart populates with real data after a measurement is taken
- Chart shows gray dots for days/slots with no data
- No regressions in existing dashboard layout
- Build passes with 0 errors/warnings

---

## Risk

- **Low**: Minimal changes — just exposing an existing fetched array and inserting one view
- **Note**: If user has < 7 days of data, chart correctly shows gray dots for missing slots (handled by Phase 1 logic)
