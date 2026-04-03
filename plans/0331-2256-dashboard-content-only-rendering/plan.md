---
title: Dashboard Content-Only Rendering
description: Simplify DashboardView to single content branch, remove dead loading/empty state code
status: pending
priority: P2
effort: 30m
branch: main
tags: [refactor, ui, cleanup]
created: 2026-03-31
blockedBy: []
blocks: []
relatedPlans: [0329-1426-stress-character-card-conditional-rendering]
---

# Dashboard Content-Only Rendering

## Overview

Remove DashboardView's 3-branch conditional (loading/content/empty) → single `content(effectiveStress)` call. StressCharacterCard already handles nil result → PermissionCardView, making DashboardView-level empty/loading states redundant.

## Rationale

- **StressCharacterCard** (via plan `0329`) already acts as the nil/permission gatekeeper inside content
- Dashboard always renders; character card swaps between mascot and permission prompt as needed
- Loading state: content renders with default data, swaps seamlessly when real data arrives
- Empty state CTAs: permission prompt is embedded in the character card itself

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Simplify DashboardView to content-only | pending | 20m | [phase-01-dashboard-content-only.md](phase-01-dashboard-content-only.md) |
| 2 | Delete EmptyDashboardView | pending | 5m | [phase-02-delete-empty-view.md](phase-02-delete-empty-view.md) |
| 3 | Build & test | pending | 5m | [phase-03-build-test.md](phase-03-build-test.md) |

## Key Files

| File | Action |
|------|--------|
| `Views/DashboardView.swift` | Replace 3-branch Group with `content(effectiveStress)`, remove dead code |
| `Views/Dashboard/Components/EmptyDashboardView.swift` | DELETE — no longer referenced |
| `Components/Character/StressCharacterCard.swift` | NO CHANGES — already handles nil → PermissionCardView |

## Architecture

```
Before:
  DashboardView.body
    ├── isLoading && currentStress == nil → loadingView (spinner)
    ├── currentStress != nil → content(stress) (rich dashboard)
    └── else → emptyState (EmptyDashboardView with CTAs)

After:
  DashboardView.body
    └── content(effectiveStress) — always renders
         └── StressCharacterCard(result: effectiveStress)
              ├── result != nil → character illustration
              └── result == nil → PermissionCardView (embedded)
```

## Validation Log

### Brainstorm Session — 2026-03-31

**Confirmed decisions:**
1. When `currentStress` is nil → show content with default `StressResult(level: 0, category: .relaxed, confidence: 1.0, hrv: 50, heartRate: 70)`
2. Loading spinner and empty-state CTAs removed entirely (not moved elsewhere)
3. StressCharacterCard keeps existing nil → PermissionCardView logic unchanged
4. `EmptyDashboardView.swift` deleted entirely
