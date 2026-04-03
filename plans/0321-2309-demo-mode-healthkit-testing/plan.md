# Demo Mode for HealthKit Testing

## Status: completed
## Branch: main
## Priority: high
## Completed: 2026-03-22

## Overview

Add `#if DEBUG` demo mode that swaps `HealthKitManager` with `SimulatorHealthKitService` at runtime. Activated via `-demo-mode` launch argument. Generates dynamic, time-varying data for all 5 stress factors (HRV, HR, Sleep, Activity, Recovery) covering all 4 stress categories with live streaming, historical trends, edge cases, and smooth transitions. Wires through real `MultiFactorStressCalculator` + `StressRepository` + SwiftData.

## Cross-Plan Dependency

**Depends on:** `plans/0321-2251-multi-factor-stress-scoring` (Phase 2+ introduces `StressFactor` protocol, `StressContext`, `MultiFactorStressCalculator`, new `HealthKitServiceProtocol` methods for sleep/activity/recovery data).

This plan's `SimulatorHealthKitService` must implement all protocol methods added by the multi-factor plan, including `fetchSleepData(for:)`, `fetchActivityData(for:)`, and `fetchRecoveryData(for:)`.

## Phases

| Phase | File | Status | Effort |
|-------|------|--------|--------|
| 1. SimulatorHealthKitService | [phase-01](phase-01-simulator-healthkit-service.md) | completed | Medium |
| 2. App Wiring + Demo Banner | [phase-02](phase-02-app-wiring-demo-banner.md) | completed | Small |
| 3. Xcode Scheme + Verify | [phase-03](phase-03-xcode-scheme-verify.md) | completed | Small |

## Dependencies

- Phase 2 depends on Phase 1
- Phase 3 depends on Phase 2

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data persistence | Persistent SwiftData (not in-memory) | Lets historical views accumulate naturally |
| Activation | Launch argument `-demo-mode` | No code changes needed to toggle; scheme checkbox |
| Auto-refresh | Timer-based in demo (not HKObserverQuery) | Simulator has no HK entitlement |
| Existing `useMockData` | Replace with demo mode check | Current approach uses static `PreviewDataFactory` data; demo mode is superior |
| Algorithm | Real `MultiFactorStressCalculator` | Tests full 5-factor pipeline with simulated inputs |
| Multi-factor data | Generate all 5 factors | Sleep/Activity/Recovery simulated alongside HRV/HR |

## Files Changed

| File | Action |
|------|--------|
| `Services/HealthKit/SimulatorHealthKitService.swift` | Create |
| `Views/Components/DemoModeBannerView.swift` | Create |
| `StressMonitorApp.swift` | Modify |
| `Views/MainTabView.swift` | Modify |
| `Views/DashboardView.swift` | Modify (minor) |

## Success Criteria

- App runs on simulator with dynamic stress data
- All 4 stress categories appear during ~2 min demo session
- Live HR updates on dashboard every 3-5s
- History/Trends views show 7+ days of data
- Edge cases (low confidence, extreme values) trigger
- `#if DEBUG` wraps all demo code
- Real `MultiFactorStressCalculator` processes all 5 simulated factors
- `StressResult.factorBreakdown` populated with all factor components
- SwiftData persists demo measurements with component fields
- "DEMO MODE" banner visible when active
- Sleep/Activity/Recovery data varies realistically across scenarios
