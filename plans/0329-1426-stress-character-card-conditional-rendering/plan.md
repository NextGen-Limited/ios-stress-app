---
title: StressCharacterCard Conditional Rendering
status: in-progress
created: 2026-03-29
blockedBy: []
blocks: [0331-2256-dashboard-content-only-rendering]
relatedPlans: [0331-2256-dashboard-content-only-rendering]
---

# StressCharacterCard Conditional Rendering

## Overview

**Priority:** High (compile error in current state)
**Status:** In-progress
**Scope:** 2 files — `StressCharacterCard.swift`, `DashboardView.swift`

Current `StressCharacterCard.body` always renders both `characterView` AND `PermissionCardView()` — the latter without required params, causing a compile error. Fix: conditional `@ViewBuilder` based on `StressResult?` availability.

## Problem

```swift
// Current (broken — PermissionCardView() missing required args)
VStack {
    characterView
    PermissionCardView()  // ← compile error
}
```

## Target

```swift
// Target
if result != nil {
    characterView
} else {
    PermissionCardView(permissionType: .healthKit, isLoading: isRequestingAccess, onGrantAccess: ...)
}
```

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [StressCharacterCard conditional body](phase-01-character-card.md) | todo |
| 2 | [DashboardView — wire permissionContent to card](phase-02-dashboard.md) | todo |

## Key Files

| File | Action |
|------|--------|
| `Views/Dashboard/Components/PermissionCardView.swift` | Add `embedded: Bool = false` — strips card bg/shadow when inside outer card |
| `Components/Character/StressCharacterCard.swift` | `StressResult?` optional, permission props, conditional body |
| `Views/DashboardView.swift` | `permissionContent` → use `StressCharacterCard(result: nil, ...)` |

## Architecture

**Condition for `characterView`:** `result != nil`
**Condition for `PermissionCardView`:** `result == nil`

`StressCharacterCard` becomes the unified card — owns both states. `DashboardView.permissionContent` passes `result: nil` + permission callbacks into the card, then appends skeleton blocks below.

**DateHeaderView:** Always shown. In permission state, displays current date. Settings gear remains accessible.

---

## Validation Log

### Session 1 — 2026-03-29
**Trigger:** `/ck:plan --validate` pre-implementation
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** PermissionCardView has its own background/cornerRadius/shadow. When embedded inside StressCharacterCard (also has rounded bg + shadow), there's a double-card visual. How should this be handled?
   - Options: Strip inner background | Accept double-card | Remove outer card in permission state
   - **Answer:** Strip inner background
   - **Rationale:** Add `embedded: Bool = false` to `PermissionCardView`. When `true`, skip `.background`/`.cornerRadius`/`.elevatedShadow`. Clean single-card visual, minimal extra code.

2. **[Architecture]** When result == nil (permission state), should DateHeaderView be hidden or still shown?
   - Options: Hide it | Show settings gear only | Show full DateHeaderView
   - **Answer:** Show full DateHeaderView
   - **Rationale:** Consistent header in all states. Settings gear accessible even before permission granted.

3. **[Scope]** What to do with `init(stressLevel:size:lastUpdated:onSettingsTapped:)` convenience init after Phase 1?
   - Options: Remove it | Keep, build minimal StressResult
   - **Answer:** Remove it
   - **Rationale:** YAGNI — only used in Previews. Previews will use `init(result:...)` with mock StressResult.

4. **[Scope]** Should Phase 2 (DashboardView.permissionContent update) be included?
   - Options: Include Phase 2 | Phase 1 only
   - **Answer:** Include Phase 2
   - **Rationale:** Full consolidation — single source of truth for permission UI inside the card.

#### Confirmed Decisions
- `PermissionCardView.embedded`: add `Bool = false` param, strip card styling when `true` ✓
- `DateHeaderView`: always shown in all states ✓
- `init(stressLevel:size:...)`: deleted ✓
- Phase 2 (DashboardView update): included ✓

#### Action Items
- [x] Phase 01: Update requirements — DateHeaderView always shown
- [x] Phase 01: Add `embedded` param to PermissionCardView to target state + todo
- [x] Phase 01: Add `PermissionCardView.swift` to files to modify
- [x] Phase 01: Delete `init(stressLevel:size:...)` — remove from impl steps + todo
- [x] plan.md: Add PermissionCardView.swift to Key Files

#### Impact on Phases
- Phase 01: 3 changes — DateHeaderView always shown; `embedded` param added to PermissionCardView; `init(stressLevel:...)` deleted
- Phase 02: No changes — confirmed as in scope
