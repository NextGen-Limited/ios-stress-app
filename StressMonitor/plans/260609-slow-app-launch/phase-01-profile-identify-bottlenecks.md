---
phase: 1
title: "Profile & Identify Bottlenecks"
status: pending
effort: "1h"
dependencies: []
---

# Phase 1: Profile & Identify Bottlenecks

## Overview

Add launch measurement instrumentation and run Instruments to establish baseline metrics before optimizing. This phase produces concrete numbers to validate improvements against.

## Requirements

- **Functional**: Add `CFAbsoluteTimeGetCurrent()` or `os_signpost` markers at key launch points. Capture time from `main` to first frame render.
- **Non-functional**: Instrumentation must be stripped or gated behind `#if DEBUG` for production builds.

## Architecture

```
App.init() ──→ MainTabView.body ──→ DashboardView.body ──→ .task { loadInitialData() }
   │                │                      │                       │
   │<── T0 ────────│<── T1 ───────────────│<── T2 ───────────────│<── T3
   │                │                      │                       │
   │  FontBlaster   │  Tab bar init        │  View render          │  HealthKit queries
```

## Related Code Files

- Modify: `StressMonitor/StressMonitorApp.swift` — add `os_signpost(.begin)` in `init()`
- Modify: `StressMonitor/StressMonitor/Views/DashboardView.swift` — add timing markers in `loadInitialData()`
- Modify: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` — add timing markers in `loadBaseline()`, `loadCurrentStress()`, `loadDashboardData()`

## Implementation Steps

1. Add `import os` to `StressMonitorApp.swift`
2. Create a static `Logger` category for launch tracking:
   ```swift
   private static let launchLog = OSLog(subsystem: "com.stressmonitor.app", category: "Launch")
   ```
3. Add `os_signpost(.begin, log:, name: "AppInit")` in `StressMonitorApp.init()` and `.end` after `FontBlaster.blast()`
4. Add signpost in `DashboardView.loadInitialData()` for each sub-call
5. Add signpost in `StressViewModel.loadCurrentStress()` around HealthKit queries
6. Run Instruments → os_signpost to capture baseline cold start
7. Document baseline numbers in this file

## Success Criteria

- [ ] `os_signpost` instrumentation added to all 5 bottleneck points
- [ ] Baseline cold start time documented
- [ ] All markers gated behind `#if DEBUG`
