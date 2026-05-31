---
title: Dashboard Content-Only Rendering
description: Simplify DashboardView to single content branch with nil-passing, remove renderState enum
status: completed
priority: P2
effort: 30m
branch: main
tags: [refactor, ui, cleanup]
created: 2026-03-31
updated: 2026-04-25
blockedBy: []
blocks: []
relatedPlans: [0329-1426-stress-character-card-conditional-rendering]
---

# Dashboard Content-Only Rendering

## Overview

Remove `DashboardRenderState` enum and 4-branch switch → always render `dashboardContent(viewModel.currentStress)`. Pass `StressResult?` directly — no coalescing. Components handle nil natively.

## Architecture

```
Before:
  DashboardView.body → switch renderState
    ├── .loading → loadingContent (skeletons)
    ├── .permissionRequired → permissionContent (skeletons + CTA)
    ├── .noData → noDataContent (CTAs)
    └── .content(StressResult) → dashboardContent (full dashboard)

After:
  DashboardView.body → dashboardContent(viewModel.currentStress?)
    └── StressCharacterCard(result: StressResult?)
         ├── result != nil → character illustration
         └── result == nil → PermissionCardView (embedded)
    └── TripleMetricRow → hidden when nil (if let guard)
    └── DataQualityBadge → hidden when nil (existing guard)
    └── DashboardInsightCard → hidden when nil (existing guard)
    └── All other components → always visible (data-independent)
```

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Simplify DashboardView to content-only | pending | 15m | [phase-01-dashboard-content-only.md](phase-01-dashboard-content-only.md) |
| 2 | Clean up StressViewModel | pending | 10m | [phase-02-cleanup-viewmodel.md](phase-02-cleanup-viewmodel.md) |
| 3 | Build & test | pending | 5m | [phase-03-build-test.md](phase-03-build-test.md) |

## Key Files

| File | Action |
|------|--------|
| `Views/DashboardView.swift` | Remove renderState switch, dead state views, helpers. Change dashboardContent to accept `StressResult?`. TripleMetricRow shows "--" when nil. |
| `ViewModels/StressViewModel.swift` | Remove `renderState`, `DashboardRenderState` enum. Keep `isRequestingAccess` (used by StressCharacterCard via viewModel binding). |
| `Components/Character/StressCharacterCard.swift` | NO CHANGES — already handles nil → PermissionCardView |

## Red Team Review

### Session — 2026-04-25
**Reviewers:** Assumption Destroyer, Failure Mode Analyst, Scope & Complexity Critic
**Findings:** 8 (7 accepted, 1 rejected)
**Severity breakdown:** 2 Critical, 4 High, 1 Medium

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | `effectiveStress` coalescing erases nil signal | Critical | Accept — removed coalescing, pass nil directly | Phase 1 |
| 2 | `onGrantAccess` callback dropped | Critical | Accept — StressCharacterCard handles via existing viewModel binding | Phase 1 |
| 3 | Loading state eliminated, fake data shown | High | Accept — acceptable tradeoff: real data loads in <2s, PermissionCardView shows during load | Phase 1 |
| 4 | "Take First Measurement" CTA deleted | High | Accept — PermissionCardView serves this role | Phase 1 |
| 5 | `onChange(scenePhase)` references deleted code | High | Accept — keep onChange, it re-checks permission on foreground | Phase 1 |
| 6 | `requestHealthKitAccess` re-entry guard removed | High | Accept — keep `isRequestingAccess` in StressViewModel | Phase 2 |
| 7 | Partial dashboard shows fake data alongside permission prompt | Medium | Accept — pass nil, guard TripleMetricRow with `if let` | Phase 1 |
| 8 | Help documentation link removed | Medium | Reject — YAGNI, non-essential | — |

## Validation Log

### Session 1 — 2026-04-25
**Trigger:** Red team review required validation of revised approach
**Questions asked:** 2

#### Questions & Answers

1. **[Assumptions]** When data is loading (first launch, ~2s), dashboard shows with PermissionCardView (nil stress) then swaps to real data. Acceptable?
   - Options: No loading state (Recommended) | Skeleton behind content
   - **Answer:** No loading state (Recommended)
   - **Rationale:** Simplifies implementation. Real data loads in <2s. PermissionCardView serves as de-facto loading state.

2. **[Architecture]** When stress is nil, should TripleMetricRow (RHR/HRV/RR) be hidden or show placeholder values?
   - Options: Hide metrics row (Recommended) | Show with placeholder values
   - **Answer:** Show with placeholder values
   - **Rationale:** Maintains consistent layout. "--" placeholders are visually clear.

#### Confirmed Decisions
- No loading state: dashboard renders immediately, swaps to real data
- TripleMetricRow shows "--" placeholders when no data (not hidden)
