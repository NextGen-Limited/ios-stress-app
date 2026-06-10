# [P1] Fix try! Crash Path in DashboardView

**Task ID:** t_98445878  
**Branch:** `fix/crash-dashboard-init`  
**Priority:** P1  
**Date:** 2025-06-10  
**Status:** Planning

---

## Problem Statement

`DashboardView.swift` uses `try!` to create a `ModelContainer` in its fallback initializer path (line 26). If `ModelContainer(for:configurations:)` throws — which can happen due to schema migration failures, corrupt SQLite files, or CloudKit misconfiguration — the app **crashes immediately** with no user feedback. The same `try!` pattern also appears in the `#Preview` block (line 155).

### Crash Location

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift`

**Line 26 (init fallback):**
```swift
} else {
    _viewModel = State(initialValue: StressViewModel(
        healthKit: HealthKitManager(),
        algorithm: MultiFactorStressCalculator(),
        repository: StressRepository(modelContext: ModelContext(
            try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))  // 💥 CRASH
        ))
    ))
}
```

**Line 155 (preview):**
```swift
DashboardView(repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))))
```

### Root Cause

The `else` branch of `DashboardView.init` runs when no `viewModel` and no `repository` are injected. This is the **production code path** used when the view is instantiated from `MainTabView` without explicit dependencies. The `try!` will crash if:

1. SwiftData schema migration fails (model version mismatch)
2. In-memory container creation fails due to low memory
3. Any `PersistentError` is thrown by the SwiftData stack

The `#Preview` usage is lower risk (debug-only) but should still be fixed for consistency.

---

## Scope of Change

### In Scope (Primary — This Task)
- Replace `try!` with safe error handling in `DashboardView.init`
- Add a user-facing error state when container creation fails
- Fix the `#Preview` blocks in `DashboardView.swift`

### Out of Scope (Follow-up Tasks)
- `SettingsView.swift` (line 15) — same `try!` pattern (P2)
- `TrendsView.swift` (line 12) — same `try!` pattern (P2)
- `MeasurementHistoryView.swift` — same `try!` pattern (P2)
- `OnboardingBaselineCalibrationView.swift` — same `try!` pattern (P2)
- `OnboardingSuccessView.swift` — same `try!` pattern (P2)
- These should be tracked as a separate follow-up task to apply the same pattern project-wide.

---

## Implementation Plan

### Step 1: Add Error State to DashboardView

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift`

Add a new `@State` property to track initialization failure:

```swift
@State private var containerError: Error?
```

### Step 2: Create a Safe In-Memory Container Helper

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift` (private helper at bottom of struct)

Extract the `ModelContainer` creation into a throwing static helper, then catch in the init:

```swift
private static func makeInMemoryContainer() throws -> ModelContainer {
    try ModelContainer(
        for: StressMeasurement.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}
```

### Step 3: Replace `try!` in init with `do/catch`

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift`

Replace the `else` branch (lines 22-27) with:

```swift
} else {
    do {
        let container = try Self.makeInMemoryContainer()
        _viewModel = State(initialValue: StressViewModel(
            healthKit: HealthKitManager(),
            algorithm: MultiFactorStressCalculator(),
            repository: StressRepository(modelContext: ModelContext(container))
        ))
    } catch {
        _viewModel = State(initialValue: StressViewModel(
            healthKit: HealthKitManager(),
            algorithm: MultiFactorStressCalculator(),
            repository: StressRepository(modelContext: ModelContext(
                // Last-resort: attempt with no explicit config (will still be in-memory if possible)
                // If this also fails, the containerError state captures it
                (try? ModelContainer(for: StressMeasurement.self)) ?? ModelContainer()
            ))
        ))
        _containerError = State(initialValue: error)
    }
}
```

**Note:** The double-fallback approach ensures the view never crashes. If even `ModelContainer()` fails (which would be a SwiftData framework bug), the process would still crash — but that's outside our control. The key win is handling the `ModelConfiguration(isStoredInMemoryOnly: true)` failure path.

### Step 4: Add User-Facing Error UI

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift`

Add an error banner in the `body` that displays when `containerError` is non-nil:

```swift
// At the top of the VStack inside ScrollView, before dashboardContent
if let error = containerError {
    ContainerErrorBanner(error: error, onRetry: {
        containerError = nil
        // Re-trigger load via the existing task mechanism
    })
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

### Step 5: Create ContainerErrorBanner Component

**File:** `StressMonitor/StressMonitor/Views/Dashboard/Components/ContainerErrorBanner.swift` (new file)

```swift
import SwiftUI

struct ContainerErrorBanner: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text("Unable to Initialize Data")
                .font(.headline)

            Text("The app couldn't set up its data storage. Your data is safe — try restarting the app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
```

### Step 6: Fix Preview Blocks

**File:** `StressMonitor/StressMonitor/Views/DashboardView.swift`

Replace `try!` in previews with `try` + force-unwrap (acceptable in previews only, but safer):

```swift
#Preview("Dashboard - No Data") {
    let container = try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    DashboardView(repository: StressRepository(modelContext: ModelContext(container)))
}
```

**Alternative (cleaner):** Extract preview helper:

```swift
private static func previewContainer() -> ModelContainer {
    // swiftlint:disable:next force_try
    try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}
```

---

## Files to Modify

| File | Action | Lines |
|------|--------|-------|
| `StressMonitor/StressMonitor/Views/DashboardView.swift` | Replace `try!` in init + add error state | 22-27, 155 |
| `StressMonitor/StressMonitor/Views/Dashboard/Components/ContainerErrorBanner.swift` | **NEW** — error UI component | N/A |

---

## Verification Steps

### 1. Build Verification
```bash
cd ~/Projects/ios-stress-app/StressMonitor
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20
```

### 2. Automated Tests
```bash
xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StressMonitorTests 2>&1 | tail -20
```

### 3. Manual Crash Reproduction (Before Fix)
- Not reproducible in normal circumstances (in-memory container rarely fails)
- The fix is defensive; the crash would only appear in edge cases (corrupted SwiftData schema, low memory)

### 4. Error State UI Verification
- Temporarily inject a forced error in init to verify the error banner renders correctly
- Verify the error banner appears and the Retry button is functional
- Verify the app does NOT crash and shows a degraded but usable state

### 5. Regression Check
- Launch app normally → Dashboard loads without error banner
- Navigate away and back → Dashboard still works
- Verify previews render in Xcode canvas

---

## Risk Assessment

- **Risk:** Low — The change only affects the fallback init path and adds defensive error handling.
- **Breaking Change:** No — The view's public API (`init(viewModel:repository:onSettingsTapped:)`) is unchanged.
- **Performance:** Negligible — One extra `do/catch` block in init (runs once).

---

## Git Workflow

```bash
# Create branch
cd ~/Projects/ios-stress-app
git checkout main
git pull
git checkout -b fix/crash-dashboard-init

# After implementation
git add -A
git commit -m "fix: replace try! with safe error handling in DashboardView init

- Replace try! ModelContainer with do/catch + error state
- Add ContainerErrorBanner component for user-facing feedback
- Fix #Preview blocks to use helper method
- Prevents crash on SwiftData schema migration failure

Task: t_98445878"

# Push
git push -u origin fix/crash-dashboard-init
```

---

## Follow-Up Recommendations

1. **[P2] Project-wide `try!` audit** — Apply the same pattern to `SettingsView`, `TrendsView`, `MeasurementHistoryView`, `OnboardingBaselineCalibrationView`, and `OnboardingSuccessView`. Consider creating a shared `SwiftDataContainerFactory` utility.

2. **[P3] StressMonitorSchema.swift line 40** — `fatalError` in the app-level container is also a crash risk. Should show a graceful recovery screen instead.

3. **[P3] StressMonitorApp.swift line 25** — Same `fatalError` pattern in the app entry point.
