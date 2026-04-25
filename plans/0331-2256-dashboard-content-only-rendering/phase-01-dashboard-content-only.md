# Phase 1: Simplify DashboardView to Content-Only

**Priority:** P2 | **Effort:** 15m | **Status:** completed

## Overview

Replace 4-branch `renderState` switch with single `dashboardContent(viewModel.currentStress)` call. Pass `StressResult?` — never coalesce nil. Each component handles nil natively.

## Files to Modify

- `StressMonitor/StressMonitor/Views/DashboardView.swift`

## Implementation Steps

### 1. Change `dashboardContent` signature to accept optional

```swift
// Before:
private func dashboardContent(_ stress: StressResult) -> some View

// After:
private func dashboardContent(_ stress: StressResult?) -> some View
```

### 2. Replace body's `switch renderState` with single call

**Before:**
```swift
switch viewModel.renderState {
case .loading:
    loadingContent
case .permissionRequired:
    permissionContent
case .noData:
    noDataContent
case .content(let stress):
    dashboardContent(stress)
}
```

**After:**
```swift
dashboardContent(viewModel.currentStress)
```

### 3. Update `TripleMetricRow` to show placeholders when nil

```swift
// Before:
TripleMetricRow(
    rhrValue: "\(Int(stress.heartRate))",
    hrvValue: "\(Int(stress.hrv))",
    rrValue: "14"
)

// After:
TripleMetricRow(
    rhrValue: stress.map { "\($0.heartRate)" } ?? "--",
    hrvValue: stress.map { "\($0.hrv)" } ?? "--",
    rrValue: stress != nil ? "14" : "--"
)
.opacity(appearAnimation ? 1 : 0)
```

### 4. Remove dead code

Delete these members:
- `@State private var docsURL: URL?` (line 11)
- `loadingContent` computed property (lines 87-94)
- `permissionContent` computed property (lines 99-111)
- `noDataContent` computed property (lines 116-150)
- `measureFirstStress()` method (lines 222-231)
- `showHelpDocumentation()` method (lines 233-235)
- `.sheet(item: $docsURL)` modifier (lines 63-66)

### 5. Keep permission-related state

**DO NOT remove:**
- `onChange(of: scenePhase)` — still needed to re-check permission when app returns to foreground
- `isPermissionRequired` check in `onChange` — guards permission re-request on foreground

### 6. Update previews

```swift
#Preview("Dashboard - No Data") {
    DashboardView(repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
}
```

## Data Flow After Changes

```
currentStress is nil →
  StressCharacterCard(result: nil) → PermissionCardView (embedded)
  TripleMetricRow → visible with "--" placeholders
  DataQualityBadge → hidden (already if let)
  DashboardInsightCard → hidden (already if let)
  SelfNoteCard, HealthDataSection, QuickActionCard, StressOverTimeChart → visible (independent)

currentStress is non-nil →
  StressCharacterCard(result: stress) → character illustration
  TripleMetricRow → visible with real data
  DataQualityBadge → visible if available
  DashboardInsightCard → visible if available
  All other components → visible

No loading state — dashboard renders immediately, swaps to real data when loaded.
```

## Success Criteria

- [x] DashboardView.body contains only `dashboardContent(viewModel.currentStress)` — no switch/if branches
- [x] No `loadingContent`, `permissionContent`, `noDataContent` computed properties
- [x] No `docsURL` state or `.sheet` modifier
- [x] No `measureFirstStress`, `showHelpDocumentation` methods
- [x] `StressCharacterCard` receives nil when no data → shows PermissionCardView
- [x] `TripleMetricRow` shows "--" placeholders when stress is nil
- [x] No loading state — dashboard renders immediately
- [x] Compiles without errors
