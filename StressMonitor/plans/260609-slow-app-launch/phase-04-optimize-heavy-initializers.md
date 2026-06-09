---
phase: 4
title: "Optimize Heavy Initializers"
status: pending
effort: "1.5h"
dependencies: [2]
---

# Phase 4: Optimize Heavy Initializers

## Overview

Fix structural inefficiencies in view initialization and service creation that cause unnecessary work during the critical launch path. This phase targets the `MainTabView` body re-creating `StressRepository` on every evaluation and the `ModelContainer` being created eagerly.

## Requirements

- **Functional**: `StressRepository` created once and shared. `ModelContainer` initialization doesn't block app init.
- **Non-functional**: Reduce object churn during view body evaluations. Maintain testability.

## Architecture

### Problem: Repository created in view body

```swift
// Current: MainTabView.body creates a NEW StressRepository every body evaluation
DashboardView(repository: StressRepository(modelContext: modelContext), ...)
```

### Solution: Lazy `@State` initialization (no flash)

```swift
// Best approach: Create in MainTabView body lazily via @State
// @State's wrappedValue is created once on first access
@State private var stressRepository: StressRepository?
```

This avoids the `.task` flash problem — `@State` initializes before the first body render.

## Related Code Files

- Modify: `StressMonitor/StressMonitor/Views/MainTabView.swift` — create repository once
- Modify: `StressMonitor/StressMonitor/Views/DashboardView.swift` — accept repository via init or environment
- Read: `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` — verify no heavy init work

## Implementation Steps

### Step 1: Move StressRepository creation to lazy `@State` in MainTabView

**Validation fix:** The original plan used `.task` which causes a render flash (empty DashboardView until task fires). Using lazy `@State` initialization eliminates the flash.

In `MainTabView.swift`:

```swift
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stressRepository: StressRepository?

    // ... existing @State properties ...

    var body: some View {
        let repo = stressRepository ?? StressRepository(modelContext: modelContext)

        ZStack(alignment: .bottom) {
            NavigationStack {
                Group {
                    switch selectedTab {
                    case .home:
                        #if DEBUG
                        if DemoMode.isEnabled {
                            DashboardView(
                                viewModel: StressViewModel(
                                    healthKit: SimulatorHealthKitService(),
                                    algorithm: MultiFactorStressCalculator(),
                                    repository: repo
                                ),
                                onSettingsTapped: { showSettings = true }
                            )
                        } else {
                            DashboardView(repository: repo, onSettingsTapped: { showSettings = true })
                        }
                        #else
                        DashboardView(repository: repo, onSettingsTapped: { showSettings = true })
                        #endif
                    // ... rest unchanged
                    }
                }
            }
        }
        .onAppear {
            if stressRepository == nil {
                stressRepository = StressRepository(modelContext: modelContext)
            }
        }
    }
}
```

**How it works:**
1. First render: `stressRepository` is nil, creates a temporary `StressRepository` via `??` — no flash, DashboardView renders immediately
2. `.onAppear`: stores the repository in `@State` — survives re-renders
3. Subsequent renders: uses the stored `@State` instance — no re-creation

**Alternative (cleaner):** Use a computed `@State` with lazy initialization:
```swift
// Even simpler — use @State directly since StressRepository creation is lightweight
@State private var stressRepository: StressRepository?

// In body, create on first access:
var body: some View {
    let repo = stressRepository ?? {
        let r = StressRepository(modelContext: modelContext)
        DispatchQueue.main.async { stressRepository = r }
        return r
    }()
    // ... use repo
}
```

<!-- Updated: Validation Session 1 - Replaced .task with lazy @State to avoid render flash -->

### Step 2: Verify StressRepository init is lightweight

Review `StressRepository.init()`:
- ✅ Only stores `modelContext`, creates `BaselineCalculator`, stores optional `CloudKitManager`
- ✅ No HealthKit queries or SwiftData fetches in init
- ✅ Baseline caching is lazy (loads on first `getBaseline()` call)

No changes needed to `StressRepository` itself.

### Step 3: Verify ModelContainer creation is fast

In `StressMonitorApp.swift`, the `sharedModelContainer` is a stored property:
```swift
var sharedModelContainer: ModelContainer = {
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

This is a lazy stored property — created on first access. It's fine as-is, but verify:
- Schema only has `StressMeasurement.self` — lightweight ✅
- No CloudKit container in model configuration ✅
- `isStoredInMemoryOnly: false` — default SQLite ✅

No changes needed here.

### Step 4: Audit third-party dependency impact

Review the SPM dependencies loaded at launch time:
| Package | Used at Launch? | Lazy-loadable? |
|---------|----------------|----------------|
| AnimatedTabBar | Yes (MainTabView) | No |
| SwiftUICharts | No (Trends tab) | Consider lazy tab |
| Kingfisher | No | Already lazy |
| Alamofire/Moya | No | Already lazy |
| GiphySDK | No | Already lazy |
| RxSwift/ReactiveSwift | No (legacy?) | Consider removal |

No changes in this phase, but document for future optimization.

## Success Criteria

- [ ] `StressRepository` created once per app lifecycle, not in view body
- [ ] No object churn in `MainTabView.body` evaluations
- [ ] `ModelContainer` creation confirmed lightweight
- [ ] Third-party dependency audit documented
