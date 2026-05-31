---
title: "ScalingHeaderScrollView for Dashboard"
description: "Add collapsible header to DashboardView using exyte/ScalingHeaderScrollView SPM package"
status: completed
priority: P2
effort: 4h
branch: main
tags: [feature, ui, spm]
created: 2026-03-23
---

# ScalingHeaderScrollView for Dashboard

## Overview

Add `exyte/ScalingHeaderScrollView` as SPM dependency to make `DashboardView`'s `StressCharacterCard` header collapse into a compact date+stress badge bar on scroll. Delete unused `HomeDashboardView`.

## Context

- Brainstorm: [brainstorm-0323-1235-scaling-header-dashboard.md](../reports/brainstorm-0323-1235-scaling-header-dashboard.md)
- Validation: [validate-0323-1328-scaling-header-dashboard.md](../reports/validate-0323-1328-scaling-header-dashboard.md)

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Add SPM dependency | Complete | 30m | [phase-01](./phase-01-add-spm-dependency.md) |
| 2 | Create compact header bar | Complete | 1h | [phase-02](./phase-02-create-compact-header-bar.md) |
| 3 | Integrate scaling header into DashboardView | Complete | 1.5h | [phase-03](./phase-03-integrate-scaling-header.md) |
| 4 | Fix tab bar scroll tracking | Complete | 45m | [phase-04](./phase-04-fix-tabbar-scroll-tracking.md) |
| 5 | Cleanup and verify | Complete | 15m | [phase-05](./phase-05-cleanup-and-verify.md) |

## Dependencies

- `exyte/ScalingHeaderScrollView` (SPM, MIT license)
- Existing: `StressCharacterCard`, `DateHeaderView`, `StressStatusBadge`, `TabBarScrollState`

## Key Risk

`TabBarScrollState.trackScrollOffsetForTabBar` is a `ScrollView` extension using `.onScrollGeometryChange`. ScalingHeaderScrollView is NOT a SwiftUI `ScrollView` — need alternative approach (`.collapseProgress` binding or `.scrollViewDidReachBottom`).
