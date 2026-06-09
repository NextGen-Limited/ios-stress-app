# Fix Slow App Launch — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Eliminate 3-5+ second cold launch delay caused by duplicate SwiftData containers, synchronous font loading, and sequential async chains.

**Architecture:** Consolidate to single ModelContainer, move blocking I/O off main thread, parallelize async data loading.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, HealthKit, CloudKit

---

## Root Cause Analysis

### 🔴 CRITICAL: Duplicate ModelContainer Creation (2-5+ sec)

**Two separate `ModelContainer` instances created on launch:**

1. `StressMonitorApp.swift` defines `sharedModelContainer` — local-only, no CloudKit
2. `StressMonitorSchema.swift` defines `StressMonitorSchema.modelContainer` — with CloudKit sync attempt + fallback

Both are `static let` (lazy init). The CloudKit-enabled container attempts synchronous network verification, causing:
- CoreData "Application Support" directory missing errors
- Sandbox access denied errors
- Race conditions on SQLite store creation
- 2-5+ seconds of blocking on poor network

### 🟠 HIGH: FontBlaster.blast() Synchronous in App.init() (~200-500ms)

`FontBlaster.blast()` called synchronously in `StressMonitorApp.init()`:
- 2 full recursive directory traversals of app bundle
- Synchronous file I/O for each .ttf/.otf file
- All on main thread before first frame

### 🟠 HIGH: DashboardView Fallback Creates 3rd ModelContainer

If no viewModel/repository passed, DashboardView creates a throwaway in-memory `ModelContainer` via `try! ModelContainer(for:...)` — potential crash + extra init overhead.

### 🟡 MEDIUM-HIGH: Sequential await Chain in loadInitialData() (1-3 sec)

`DashboardView.task` triggers sequential chain:
1. `await loadBaseline()` → fetches 30 days of measurements + calibration
2. `await loadDashboardData()` → 5+ sequential HealthKit queries
3. All chained with `await`, not `async let`

### 🟡 MEDIUM: Baseline Fetched Twice

`getBaseline()` called in both `loadBaseline()` AND inside `loadCurrentStress()` — duplicate I/O and computation.

---

## Tasks

### Task 1: Consolidate to Single ModelContainer

**Objective:** Remove duplicate ModelContainer, use `StressMonitorSchema.modelContainer` as the single source of truth.

**Files:**
- Modify: `StressMonitor/StressMonitor/StressMonitorApp.swift` (remove duplicate container, use schema's)
- Modify: `StressMonitor/StressMonitor/StressMonitorApp.swift` (line 18: change `.modelContainer(sharedModelContainer)` to `.modelContainer(StressMonitorSchema.modelContainer)`)
- Verify: `StressMonitor/StressMonitorSchema.swift` (ensure it handles CloudKit fallback correctly)

**Step 1: Remove duplicate container from StressMonitorApp.swift**

In `StressMonitorApp.swift`, remove the private `schema`, `modelConfiguration`, and `sharedModelContainer` static properties (lines ~15-27). Change line 18 from:
```swift
.modelContainer(sharedModelContainer)
```
to:
```swift
.modelContainer(StressMonitorSchema.modelContainer)
```

**Step 2: Ensure StressMonitorSchema handles Application Support directory**

Verify `StressMonitorSchema.swift` creates the Application Support directory before ModelContainer init. Add guard:
```swift
static let modelContainer: ModelContainer = {
    // Ensure Application Support directory exists
    let fm = FileManager.default
    if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        if !fm.fileExists(atPath: appSupport.path) {
            try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
    }
    // ... existing container creation
}()
```

**Step 3: Verify build succeeds**
```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Commit:**
```bash
git add StressMonitor/StressMonitor/StressMonitorApp.swift StressMonitor/StressMonitorSchema.swift
git commit -m "fix: consolidate to single ModelContainer, eliminate duplicate SwiftData init"
```

---

### Task 2: Move FontBlaster Off Main Thread

**Objective:** Defer font loading so it doesn't block first frame.

**Files:**
- Modify: `StressMonitor/StressMonitor/StressMonitorApp.swift`

**Step 1: Remove FontBlaster.blast() from init()**

Remove the `FontBlaster.blast()` call from `StressMonitorApp.init()`. Instead, add it as a non-blocking task in the first view or use `dispatchPrecondition`:

```swift
@main
struct StressMonitorApp: App {
    // ... existing @StateObject properties

    init() {
        // FontBlaster moved off main thread — see .task in body
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Load fonts in background, non-blocking
                    await Task.detached(priority: .utility) {
                        FontBlaster.blast()
                    }.value
                }
                .environmentObject(healthManager)
                .environmentObject(cloudKitManager)
                .environmentObject(readinessService)
        }
        .modelContainer(StressMonitorSchema.modelContainer)
    }
}
```

**Note:** SwiftUI's default system fonts will render first, then custom fonts kick in after ~100ms. This is acceptable for launch performance.

**Step 2: Verify build and fonts still load**
```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Commit:**
```bash
git add StressMonitor/StressMonitor/StressMonitorApp.swift
git commit -m "perf: move FontBlaster off main thread to async background task"
```

---

### Task 3: Remove DashboardView Fallback ModelContainer

**Objective:** Prevent accidental creation of a 3rd in-memory ModelContainer.

**Files:**
- Modify: `StressMonitor/StressMonitor/Views/Dashboard/DashboardView.swift`

**Step 1: Remove the else branch that creates in-memory container**

In `DashboardView.swift`, the init has a fallback path that creates `ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))`. Replace this with a fatal error or use the shared container:

```swift
// Before:
} else {
    _viewModel = State(initialValue: StressViewModel(
        healthKit: HealthKitManager(),
        algorithm: MultiFactorStressCalculator(),
        repository: StressRepository(modelContext: ModelContext(
            try! ModelContainer(for: StressMeasurement.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        )
    ))
}

// After:
} else {
    // Use the shared model container from the environment
    let context = ModelContext(StressMonitorSchema.modelContainer)
    _viewModel = State(initialValue: StressViewModel(
        healthKit: HealthKitManager(),
        algorithm: MultiFactorStressCalculator(),
        repository: StressRepository(modelContext: context)
    ))
}
```

**Step 2: Verify build**
```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Commit:**
```bash
git add StressMonitor/StressMonitor/Views/Dashboard/DashboardView.swift
git commit -m "fix: remove fallback in-memory ModelContainer, use shared container"
```

---

### Task 4: Parallelize loadInitialData() with async let

**Objective:** Run independent async operations concurrently instead of sequentially.

**Files:**
- Modify: `StressMonitor/StressMonitor/Views/Dashboard/DashboardView.swift` (the `loadInitialData()` method)

**Step 1: Refactor loadInitialData() to use async let**

```swift
func loadInitialData() async {
    // Load baseline first (needed by subsequent calls)
    await viewModel.loadBaseline()

    // Then run dashboard data and heart rate observation in parallel
    async let dashboard: Void = viewModel.loadDashboardData()
    async let heartRate: Void = viewModel.observeHeartRate()

    let _ = await (dashboard, heartRate)
}
```

**Step 2: Refactor loadDashboardData() to parallelize independent queries**

Inside `StressViewModel.loadDashboardData()`, identify independent operations and parallelize:
```swift
func loadDashboardData() async {
    async let stress: Void = loadCurrentStress()
    async let historical: Void = loadHistoricalData(days: 14)
    async let today: Void = loadTodayMeasurements()
    async let weekly: Void = loadWeeklyComparison()

    let _ = await (stress, historical, today, weekly)

    // Generate insight after all data is loaded
    await generateInsight()
}
```

**Step 3: Verify build**
```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Commit:**
```bash
git add StressMonitor/StressMonitor/Views/Dashboard/DashboardView.swift StressMonitor/StressMonitor/ViewModels/StressViewModel.swift
git commit -m "perf: parallelize async data loading with async let"
```

---

### Task 5: Cache Baseline to Avoid Double Fetch

**Objective:** Baseline is fetched twice during launch — cache it in StressRepository.

**Files:**
- Modify: `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
- Modify: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`

**Step 1: Add cached baseline property to StressRepository**

```swift
private var cachedBaseline: PersonalBaseline?
private var baselineFetchDate: Date?

func getBaseline() async throws -> PersonalBaseline? {
    // Return cached if less than 5 minutes old
    if let cached = cachedBaseline,
       let fetchDate = baselineFetchDate,
       Date().timeIntervalSince(fetchDate) < 300 {
        return cached
    }

    // ... existing fetch logic ...

    cachedBaseline = baseline
    baselineFetchDate = Date()
    return baseline
}
```

**Step 2: Remove duplicate baseline fetch in StressViewModel**

In `loadCurrentStress()`, remove or guard the `try? await repository.getBaseline()` call if baseline was already loaded in `loadBaseline()`.

**Step 3: Verify build**
```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Commit:**
```bash
git add StressMonitor/StressMonitor/Services/Repository/StressRepository.swift StressMonitor/StressMonitor/ViewModels/StressViewModel.swift
git commit -m "perf: cache baseline in repository to avoid double fetch on launch"
```

---

## Expected Impact

| Task | Before | After | Savings |
|------|--------|-------|---------|
| 1. Single ModelContainer | 2-5 sec (duplicate init + CloudKit hang) | <500ms | **2-4.5 sec** |
| 2. FontBlaster async | 200-500ms blocking main thread | 0ms blocking | **200-500ms** |
| 3. Remove fallback container | Potential crash/extra init | 0ms | **Variable** |
| 4. Parallelize async | 1-3 sec sequential | 0.3-1 sec parallel | **0.7-2 sec** |
| 5. Cache baseline | Duplicate fetch | Cache hit | **100-300ms** |

**Total estimated improvement: 3-7 seconds faster launch.**

---

## Verification

After all tasks, test on physical device:
1. Delete app from device
2. Clean build folder (Cmd+Shift+K)
3. Build & Run on device
4. Measure time from tap to first interactive frame
5. Verify no CoreData errors in console
6. Verify fonts render correctly after ~100ms

Run launch test from Xcode:
- Product → Profile → Time Profiler
- Filter by app launch time
- Verify main thread is unblocked within 400ms
