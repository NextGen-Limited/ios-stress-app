# Phase 1: Simplify DashboardView to Content-Only

**Priority:** P2 | **Effort:** 20m | **Status:** pending

## Overview

Replace 3-branch conditional Group with single `content(effectiveStress)` call. Remove all dead loading/empty state code.

## Files to Modify

- `StressMonitor/StressMonitor/Views/DashboardView.swift`

## Implementation Steps

### 1. Add `effectiveStress` computed property

```swift
private var effectiveStress: StressResult {
    viewModel.currentStress ?? StressResult(
        level: 0, category: .relaxed, confidence: 1.0,
        hrv: 50, heartRate: 70
    )
}
```

### 2. Replace `body` Group with single content call

**Before:**
```swift
Group {
    if viewModel.isLoading && viewModel.currentStress == nil && !viewModel.isPermissionRequired {
        loadingView
    } else if let stress = viewModel.currentStress {
        content(stress)
    } else {
        emptyState
    }
}
.alert(...)
.sheet(item: $docsURL) { ... }
.task { ... }
.onDisappear { ... }
.onChange(of: scenePhase) { ... }
```

**After:**
```swift
content(effectiveStress)
    .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
        Button("OK") { viewModel.clearError() }
    } message: {
        if let error = viewModel.errorMessage { Text(error) }
    }
    .task {
        if !appeared {
            appeared = true
            await loadInitialData()
            viewModel.startAutoRefresh()
        }
    }
    .onDisappear { viewModel.stopAutoRefresh() }
    .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active && viewModel.isPermissionRequired {
            Task { await viewModel.loadCurrentStress() }
        }
    }
```

### 3. Remove dead code

Delete these members:
- `private static var lastEmptyDashboardAppearanceLog = Date.distantPast`
- `@State private var docsURL: URL?`
- `private var loadingView: some View` (lines 85-96)
- `private var emptyState: some View` (lines 175-183)
- `private func measureFirstStress()` (lines 185-194)
- `private func showHelpDocumentation()` (lines 196-198)
- `private func handleEmptyDashboardAppear()` (lines 200-208)
- `.sheet(item: $docsURL)` modifier

### 4. Update previews

- Keep "Dashboard - With Mock Data" and "Dashboard - Dark Mode" previews (they work as-is)
- Update "Dashboard - Permission Required" preview to not set `isPermissionRequired` since empty state no longer exists. Instead show it with nil result:
  ```swift
  #Preview("Dashboard - Permission State") {
      DashboardView(viewModel: StressViewModel(
          healthKit: HealthKitManager(),
          algorithm: MultiFactorStressCalculator(),
          repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
      ))
  }
  ```
  This will render content with default data, and StressCharacterCard will show PermissionCardView since `currentStress` is nil.

## Success Criteria

- [ ] DashboardView.body contains only `content(effectiveStress)` + modifiers
- [ ] No references to `loadingView`, `emptyState`, `measureFirstStress`, `showHelpDocumentation`, `handleEmptyDashboardAppear`
- [ ] No `docsURL` state or `.sheet` modifier
- [ ] Compiles without errors
- [ ] StressCharacterCard shows PermissionCardView when `currentStress` is nil (default data flows in)
