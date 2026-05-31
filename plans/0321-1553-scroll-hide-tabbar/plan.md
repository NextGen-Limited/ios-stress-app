---
title: Scroll-Hide Tab Bar
slug: scroll-hide-tabbar
status: completed
created: 2026-03-21
completed: 2026-03-21
branch: main
---

# Scroll-Hide Tab Bar

Hide `AnimatedTabBar` when scrolling down, reveal on scroll up. Slide animation with spring.

## References
- Brainstorm: `plans/reports/brainstorm-0321-1553-scroll-hide-tabbar.md`
- Tab bar: `StressMonitor/Views/MainTabView.swift`
- Tab buttons: `StressMonitor/Views/Components/TabBar/AnimatedTabButtons.swift`

## Approach
- iOS 17+ `onScrollGeometryChange` for scroll offset tracking (no PreferenceKey/GeometryReader boilerplate)
- `@Observable TabBarScrollState` as environment object in `MainTabView`
- Slide animation: `.offset(y: tabBarHeight)` with spring(response: 0.3, dampingFraction: 0.8)
- `tabBarHeight` defaults to `83` pt as fallback before `onAppear` fires
- Static bottom padding = tabBarHeight on all scroll views (no content jump)
- Reset `isVisible = true` on tab switch

## Phases

| # | Phase | Status | Est |
|---|-------|--------|-----|
| 1 | [Core scroll state](phase-01-core-scroll-state.md) | ✅ completed | 20m |
| 2 | [MainTabView animation](phase-02-main-tab-view-animation.md) | ✅ completed | 20m |
| 3 | [Per-view scroll tracking](phase-03-per-view-scroll-tracking.md) | ✅ completed | 20m |

## Files Changed

### Created
- `Views/Components/TabBar/TabBarScrollState.swift`

### Modified
- `Views/MainTabView.swift`
- `Views/Dashboard/HomeDashboardView.swift`
- `Views/Trends/TrendsView.swift`
- `Views/Action/ActionView.swift`

## Implementation Notes

**iOS Version Compatibility Deviation:**
- Plan specified `onScrollGeometryChange` (iOS 18+)
- Project targets iOS 17.6, so implementation used `PreferenceKey` approach instead
- `ScrollOffsetPreferenceKey` merged into `TabBarScrollState.swift`
- All scroll tracking uses `.coordinateSpace(name:)` + `.onPreferenceChange()` pattern

## Validation Log

### Session 1 — 2026-03-21
**Trigger:** Pre-implementation validation interview
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** All 3 scroll views use the same coordinateSpace name "scrollView". What's your preference?
   - Options: Keep shared name | Use unique names per view
   - **Answer:** Use unique names per view
   - **Rationale:** Moot — superseded by `onScrollGeometryChange` decision (no coordinateSpace needed)

2. **[Assumptions]** `tabBarHeight` defaults to 0 and is set via `.onAppear`. How to handle first-scroll race?
   - Options: Add fallback ~83pt | Leave as 0
   - **Answer:** Add fallback default ~83pt
   - **Rationale:** Prevents content jump on very fast first scroll before onAppear fires

3. **[Architecture]** PreferenceKey + GeometryReader vs `onScrollGeometryChange`?
   - Options: onScrollGeometryChange | Keep PreferenceKey
   - **Answer:** `onScrollGeometryChange`
   - **Rationale:** Eliminates ScrollOffsetKey.swift, ScrollOffsetTracker modifier, and Color.clear anchors in all 3 views

4. **[Scope]** Other scrollable tabs beyond Dashboard, Trends, Action?
   - Options: No — only these 3 | Yes — others exist
   - **Answer:** No — only these 3

#### Confirmed Decisions
- Scroll tracking API: `onScrollGeometryChange` — eliminates boilerplate, cleaner iOS 17+ native
- tabBarHeight default: `83` pt fallback — prevents first-frame race condition
- CoordSpace naming: N/A — no coordinateSpace needed with `onScrollGeometryChange`
- Scope: 3 views only (Dashboard, Trends, Action)

#### Action Items
- [x] Remove `ScrollOffsetKey.swift` from plan (not needed)
- [x] Update Phase 1 to use `onScrollGeometryChange` pattern
- [x] Update Phase 3 to replace PreferenceKey boilerplate
- [x] Add `tabBarHeight = 83` default to `TabBarScrollState`

#### Impact on Phases
- Phase 1: Remove ScrollOffsetKey.swift + ScrollOffsetTracker; simplify TabBarScrollState with default height
- Phase 3: Replace Color.clear anchor + coordinateSpace + onPreferenceChange with onScrollGeometryChange
