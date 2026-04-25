# Phase 2: Clean Up StressViewModel

**Priority:** P2 | **Effort:** 10m | **Status:** completed

## Overview

Remove `renderState` computed property and `DashboardRenderState` enum. Keep `isRequestingAccess` — still used by StressCharacterCard via viewModel binding.

## Files to Modify

- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`

## Implementation Steps

### 1. Remove `renderState` computed property (lines 44-49)

```swift
// DELETE this entire computed property
var renderState: DashboardRenderState {
    if isPermissionRequired { return .permissionRequired }
    if isLoading && currentStress == nil { return .loading }
    if let stress = currentStress { return .content(stress) }
    return .noData
}
```

### 2. Remove `DashboardRenderState` enum (lines 418-423)

```swift
// DELETE this entire enum
enum DashboardRenderState {
    case loading
    case permissionRequired
    case noData
    case content(StressResult)
}
```

### 3. Keep `isRequestingAccess` (line 38)

**DO NOT remove** — StressCharacterCard uses it:
```swift
StressCharacterCard(
    result: nil,
    size: .dashboard,
    isRequestingAccess: viewModel.isRequestingAccess,  // ← used here
    onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } },
    onSettingsTapped: onSettingsTapped
)
```

### 4. Grep verification

Before deleting, confirm no external references to `DashboardRenderState`:
```bash
grep -rn "renderState\|DashboardRenderState" StressMonitor/ --include="*.swift"
```

Only `StressViewModel.swift` should reference these (the definitions being deleted).

## Success Criteria

- [x] `renderState` computed property removed
- [x] `DashboardRenderState` enum removed
- [x] `isRequestingAccess` kept intact
- [x] No compile errors from removed types
- [x] `grep -rn "DashboardRenderState"` returns zero results
