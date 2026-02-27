# Phase 02: Auto-Refresh Implementation

**Parent:** [plan.md](./plan.md)
**Status:** pending
**Priority:** P1
**Effort:** 1h

---

## Context

- **Previous Phase:** [phase-01-layout-components.md](./phase-01-layout-components.md)
- **Brainstorm:** [brainstorm-0223-2217-dashboard-ui-enhancement.md](../reports/brainstorm-0223-2217-dashboard-ui-enhancement.md)

---

## Overview

Replace manual Measure button with automatic HealthKit data refresh using HKObserverQuery. Implement 60-second debounce to minimize battery impact.

---

## Key Insights

1. HealthKit provides `HKObserverQuery` for background data monitoring
2. Debounce prevents excessive refreshes from rapid HealthKit updates
3. Need proper query lifecycle management (start/stop)
4. Current `observeHeartRate()` already uses async stream pattern

---

## Requirements

### Functional
- Auto-refresh stress data when HealthKit HRV/HR changes
- 60-second minimum interval between refreshes
- Haptic feedback on stress category change
- Remove MeasureButton from dashboard

### Non-Functional
- Minimal battery impact
- Proper cleanup on view disappearance
- Handle HealthKit observer errors gracefully

---

## Architecture

### Data Flow

```
HealthKit (HRV/HR Update)
    ↓
HKObserverQuery triggers
    ↓
Debounce check (60s since last refresh?)
    ↓ Yes                    ↓ No
Refresh stress data      Skip (too soon)
    ↓
Category changed?
    ↓ Yes
HapticManager.stressLevelChanged()
    ↓
UI updates via @Observable
```

---

## Related Code Files

### Modify
| File | Changes |
|------|---------|
| `ViewModels/StressViewModel.swift` | Add HKObserverQuery subscription, debounce logic |
| `Services/HealthKit/HealthKitManager.swift` | Add observer query methods if not present |

### Remove
| File | Changes |
|------|---------|
| `Views/DashboardView.swift` | Remove MeasureButton and measureStress() calls |

---

## Implementation Steps

### Step 1: Add Debounce Property (5 min)

```swift
// In StressViewModel.swift
private var lastRefreshTime: Date?
private let refreshInterval: TimeInterval = 60 // 60 seconds

private var canRefresh: Bool {
    guard let last = lastRefreshTime else { return true }
    return Date().timeIntervalSince(last) >= refreshInterval
}
```

### Step 2: Add HealthKit Observer Subscription (25 min)

```swift
// In StressViewModel.swift
private var observerQuery: HKObserverQuery?
private let healthStore = HKHealthStore()

func startAutoRefresh() {
    // Observe HRV changes
    let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

    let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, error in
        if let error = error {
            Task { @MainActor in
                self?.errorMessage = "HealthKit observer error: \(error.localizedDescription)"
            }
            completionHandler()
            return
        }

        Task { @MainActor [weak self] in
            self?.handleHealthKitUpdate()
        }

        completionHandler()
    }

    healthStore.execute(query)
    observerQuery = query
}

func stopAutoRefresh() {
    if let query = observerQuery {
        healthStore.stop(query)
        observerQuery = nil
    }
}

private func handleHealthKitUpdate() {
    guard canRefresh else {
        // Debounce: skip if refreshed within last 60s
        return
    }

    let previousCategory = currentStress?.category

    Task {
        await loadCurrentStress()

        // Haptic feedback on category change
        if let newCategory = currentStress?.category,
           newCategory != previousCategory {
            HapticManager.shared.stressLevelChanged(to: newCategory)
        }

        lastRefreshTime = Date()
    }
}
```

### Step 3: Update DashboardView Lifecycle (10 min)

```swift
// In DashboardView.swift
var body: some View {
    NavigationStack {
        // ... content
    }
    .task {
        if !appeared {
            appeared = true
            await loadInitialData()
            viewModel.startAutoRefresh()  // Start observer
        }
    }
    .onDisappear {
        viewModel.stopAutoRefresh()  // Stop observer
    }
}
```

### Step 4: Remove MeasureButton (10 min)

Remove from DashboardView:
- `MeasureButton` component usage
- `measureStress()` method
- Related accessibility labels

Update `emptyState` to not show MeasureButton - auto-refresh will handle data loading.

### Step 5: Add HapticManager Category Method (10 min)

```swift
// In HapticManager.swift (if not already present)
func stressLevelChanged(to category: StressCategory) {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    switch category {
    case .relaxed:
        style = .light
    case .mild:
        style = .medium
    case .moderate:
        style = .heavy
    case .high:
        style = .heavy
    }

    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
```

---

## Todo List

- [ ] Add debounce properties to StressViewModel
- [ ] Implement `startAutoRefresh()` with HKObserverQuery
- [ ] Implement `stopAutoRefresh()` for cleanup
- [ ] Implement `handleHealthKitUpdate()` with debounce check
- [ ] Add haptic feedback on category change
- [ ] Update DashboardView lifecycle hooks
- [ ] Remove MeasureButton from DashboardView
- [ ] Remove measureStress() method from DashboardView
- [ ] Update emptyState to not show button
- [ ] Run compile check
- [ ] Test auto-refresh on simulator

---

## Success Criteria

- [ ] HKObserverQuery successfully subscribes to HRV changes
- [ ] Refresh debounced to max once per 60 seconds
- [ ] Haptic triggers on stress category change
- [ ] MeasureButton completely removed
- [ ] Observer properly stopped on view disappear
- [ ] No memory leaks from observer lifecycle

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Observer not stopped | High | .onDisappear cleanup, deinit fallback |
| Excessive refreshes | Medium | 60s debounce enforced |
| HealthKit permission denied | Medium | Handle gracefully, show permission card |

---

## Security Considerations

- HealthKit data already protected by system permissions
- No additional security concerns

---

## Next Steps

After completion:
1. Test on device with real Apple Watch data
2. Verify battery impact is minimal
3. Proceed to Phase 03 (Animations + Haptics polish)
