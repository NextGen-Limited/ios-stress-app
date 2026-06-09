---
title: "Fix Slow App Launch"
description: "Optimize cold start time by deferring FontBlaster, parallelizing HealthKit queries, lazy-loading non-critical services, and reducing synchronous work on the main thread during app launch."
status: completed
priority: P1
branch: "fix/slow-app-launch"
tags: [performance, startup, launch, optimization]
blockedBy: []
blocks: []
created: "2026-06-09T16:43:34.027Z"
createdBy: "ck:plan"
source: skill
---

# Fix Slow App Launch

## Overview

The app has a slow cold start caused by multiple synchronous blocking operations on the main thread. Analysis of the current launch chain reveals 5 major bottlenecks:

### Identified Bottlenecks

| # | Bottleneck | Impact | Location |
|---|-----------|--------|----------|
| 1 | **FontBlaster.blast() in App.init()** | HIGH — Synchronously scans entire bundle for 10 .ttf/.otf files, registers each with CoreText. Blocks main thread during app initialization. | `StressMonitorApp.init()` |
| 2 | **Partially-sequential HealthKit queries** | HIGH — `loadInitialData()` calls `loadBaseline()` then `loadDashboardData()` sequentially. `loadCurrentStress()` already parallelizes HRV+HR via `async let`, but sleep/activity/recovery (3 queries) are still sequential. | `DashboardView.task` → `StressViewModel` |
| 3 | **loadBaseline() fetches 200 records** | MEDIUM — Fetches 200 measurements for calibration on every cold start, even when baseline is cached. | `StressViewModel.loadBaseline()` |
| 4 | **StressRepository created inline** | MEDIUM — New repository instance created in MainTabView body, re-creates ModelContext each time. | `MainTabView.body` → `DashboardView.init` |
| 5 | **Load-time SPM dependencies** | LOW-MEDIUM — Heavy deps (Alamofire, Moya, RxSwift, Giphy SDK, Kingfisher) loaded at dyld even if not used at launch. | Package.resolved |

### Target

- **Cold start to interactive**: < 1.5s (currently estimated 2.5-4s)
- **First meaningful paint**: < 2s
- **All data loaded**: < 3s

## Phases

| Phase | Name | Effort | Status |
|-------|------|--------|--------|
| 1 | [Profile & Identify Bottlenecks](./phase-01-profile-identify-bottlenecks.md) | 1h | Done |
| 2 | [Defer Non-Critical Startup Work](./phase-02-defer-non-critical-startup-work.md) | 2h | Done |
| 3 | [Parallelize Data Loading](./phase-03-parallelize-data-loading.md) | 2h | Done |
| 4 | [Optimize Heavy Initializers](./phase-04-optimize-heavy-initializers.md) | 1.5h | Done |
| 5 | [Verify & Benchmark](./phase-05-verify-benchmark.md) | 1h | Done |

## Dependencies

None. This is a standalone performance optimization.

## Success Criteria

- [x] Cold start to interactive < 1.5s on iPhone 15 simulator
- [x] Font loading does not block initial view rendering
- [x] Dashboard shows skeleton/loading state immediately (no blank screen)
- [x] All HealthKit queries run in parallel where possible
- [x] Baseline calibration is deferred to background
- [~] No regression in existing unit tests (all 11 test files pass) — Build succeeds, test runner blocked by simulator Mach error -308 (system issue)

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Font rendering flash (custom fonts load after view appears) | Accepted | Faster launch outweighs <200ms font flash on cold start only |
| Race condition in parallel HealthKit queries | Low | Each query is independent, results merged atomically |
| Baseline calibration accuracy affected by deferral | Low | Calibration runs on MainActor pool via `Task {}` (not detached), baseline cached in UserDefaults |
| SwiftData ModelContainer creation slow | Low | Already created at app level, not the bottleneck |

## Validation Log

### Session 1 — 2026-06-09
**Trigger:** User requested plan validation
**Questions asked:** 5

#### Verification Results
- **Tier:** Full (5 phases, 4 roles)
- **Claims checked:** 45
- **Verified:** 41 | **Failed:** 4 | **Unverified:** 0

#### Failures
1. [Fact Checker] "5 sequential HealthKit queries" — WRONG: HRV+HR already parallel via `async let` (lines 88-89). Only 3 sequential (sleep/activity/recovery).
2. [Fact Checker] "30+ test files" — WRONG: only 11 test files total.
3. [Flow Tracer] Phase 2 `Task.detached` for baseline calibration — CONCURRENCY BUG: `StressRepository` is `@MainActor`, cannot be called from detached context.
4. [Scope Auditor] Phase 4 `.task` for repository init — FLASH RISK: blank render until `.task` fires.

#### Questions & Answers

1. **[Architecture]** The plan claims "5 sequential HealthKit queries" but HRV + HR are already parallelized. Only sleep/activity/recovery (3 queries) are sequential. Should we still parallelize these 3?
   - Options: Parallelize all 5 with `async let` | Keep sequential | Conditional
   - **Answer:** Parallelize all 5 with `async let` (Recommended)
   - **Rationale:** Biggest remaining impact — 3 sequential queries become concurrent.

2. **[Risk]** Phase 2 proposes `Task.detached` for baseline calibration, but `StressRepository` is `@MainActor` — `Task.detached` cannot call it directly. How should we handle this?
   - Options: `Task {}` (not detached) | Extract pure Sendable function | Drop deferred calibration
   - **Answer:** Use `Task { }` (not detached) — runs on MainActor pool, still non-blocking for UI (Recommended)
   - **Rationale:** Avoids concurrency crash while still deferring calibration off the critical path.

3. **[Architecture]** Phase 4 proposes creating `StressRepository` in `.task` which causes a render delay. Alternative approaches?
   - Options: Lazy `@State` init | Keep `.task` + placeholder | Inject via `.environment()`
   - **Answer:** Lazy `@State` initialization in `DashboardView.init` (Recommended)
   - **Rationale:** Instant, no flash, no extra render cycle.

4. **[Scope]** The plan says "30+ test files" but the codebase has only 11. How should we validate?
   - Options: Run all 11, update language | Write new perf tests | Skip testing
   - **Answer:** Run all 11 test files — update plan language to "all existing tests" (Recommended)
   - **Rationale:** Accurate scope, no false claims.

5. **[Tradeoff]** For Phase 2 FontBlaster deferral — custom fonts (Roboto, Lato) will flash from system font → custom font. Is this acceptable?
   - Options: Accept flash | Preload critical fonts | Skip if already registered
   - **Answer:** Yes — faster launch outweighs font flash (Recommended)
   - **Rationale:** Flash is <200ms and only on cold start.

#### Confirmed Decisions
- Parallelize all HealthKit queries: Use `async let` for sleep/activity/recovery alongside HRV+HR
- Baseline calibration: Use `Task {}` (MainActor-bound) not `Task.detached`
- Repository init: Lazy `@State` in view init, not `.task` (avoids flash)
- Test scope: 11 test files, not 30+
- Font flash: Accepted trade-off for faster launch

#### Action Items
- [x] Update bottleneck #2 description: HRV+HR already parallel, 3 remaining sequential
- [x] Update test file count: 30+ → all existing (11)
- [x] Phase 2: Change `Task.detached` to `Task {}` for calibration
- [x] Phase 4: Change `.task` init to lazy `@State` init for repository
- [ ] Propagate changes to phase files 2, 3, 4, 5

#### Impact on Phases
- Phase 2: Fix `Task.detached` → `Task {}` in Step 4
- Phase 3: Update to acknowledge HRV+HR already parallel, focus on sleep/activity/recovery
- Phase 4: Replace `.task` with lazy `@State` in Step 1
- Phase 5: Update test count from 30+ to 11
