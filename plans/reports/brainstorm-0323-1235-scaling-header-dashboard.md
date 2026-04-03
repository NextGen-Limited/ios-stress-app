# Brainstorm: ScalingHeaderScrollView for Dashboard

## Problem Statement

Dashboard's `StressCharacterCard` header (mascot + date + status) occupies significant vertical space. As users scroll through metrics, health data, and charts, the header should collapse into a compact bar to maximize content visibility while keeping stress status always accessible.

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Target view | `DashboardView` (used in `MainTabView`) | Only live dashboard; `HomeDashboardView` is unused Figma prototype (candidate for removal) |
| Dependency | SPM — `exyte/ScalingHeaderScrollView` | Accepted trade-off: breaks zero-dependency rule for polished UX |
| Expanded state | Full `StressCharacterCard` | Mascot illustration + date header + stress level |
| Collapsed state | Date + stress badge compact bar | `Monday, Mar 23  [Relaxed 32]` |
| Snap mode | `.afterFinishAccelerating` | Natural feel — snaps after scroll momentum settles |

## Evaluated Approaches

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **ScalingHeaderScrollView (SPM)** | Battle-tested, pull-to-refresh built-in, snap modes, collapse progress binding | First external dep, iOS 14+ (we target 17+ so fine), known TabView incompatibility | **Selected** |
| **Custom GeometryReader + offset** | Zero deps, full control | Significant effort to get snap/bounce/progress right, edge cases with safe area | Rejected — not worth the engineering time |
| **Native ScrollView + .scrollTargetBehavior** | iOS 17+ native, no deps | No built-in header collapse, would need PreferenceKey chain, limited snap control | Rejected — too much custom work for same result |

## Implementation Plan

### 1. Add SPM Dependency

```
https://github.com/exyte/ScalingHeaderScrollView.git
```

Add to `StressMonitor.xcodeproj` (not Package.swift — this is an Xcode project, not SPM package).

### 2. Modify `DashboardView.content(_:)`

Replace the current `ScrollView` wrapper with `ScalingHeaderScrollView`:

```swift
ScalingHeaderScrollView {
    // HEADER: StressCharacterCard (expanded)
    StressCharacterCard(result: stress, size: .dashboard, ...)
} content: {
    // CONTENT: all current LazyVStack content below the card
    LazyVStack(spacing: 24) { ... }
}
.height(min: 60, max: 350)  // collapsed: 60pt compact bar, expanded: ~350pt character card
.collapseProgress($collapseProgress)
.setHeaderSnapMode(.afterFinishAccelerating)
.allowsHeaderCollapse()
.allowsHeaderGrowth()
.hideScrollIndicators()
```

### 3. Create Compact Header Bar

New component: `CompactStressHeaderBar.swift`

Shows when `collapseProgress` approaches 1.0:
- Left: Date text (e.g., "Monday, Mar 23")
- Right: Stress badge pill (e.g., colored capsule with "Relaxed 32")
- Height: ~60pt
- Background: `Color.Wellness.adaptiveCardBackground` with subtle shadow

Use `collapseProgress` binding to crossfade between full card and compact bar.

### 4. Header View Composition

The header ViewBuilder needs to composite both states:

```swift
ZStack {
    // Full character card — fades out as you scroll
    StressCharacterCard(...)
        .opacity(1 - collapseProgress)

    // Compact bar — fades in
    CompactStressHeaderBar(date: ..., stressLevel: ..., category: ...)
        .opacity(collapseProgress)
}
```

### 5. Integration with TabBar Scroll State

Current `.trackScrollOffsetForTabBar(state:)` modifier works on ScrollView. Need to verify compatibility with ScalingHeaderScrollView's internal ScrollView. May need to attach the tracker inside the `content:` block instead.

### 6. Cleanup

- Remove `HomeDashboardView.swift` if confirmed unused (user said "else it should be removed")
- Verify no other references to `HomeDashboardView`

## Operational Concerns

- **TabView incompatibility**: ScalingHeaderScrollView docs warn TabView won't work inside it. Our dashboard doesn't use TabView in content, so no issue. The outer `MainTabView` uses `AnimatedTabBar` (custom, not SwiftUI TabView) — also fine.
- **TabBar hide-on-scroll**: The existing `trackScrollOffsetForTabBar` uses ScrollView offset detection. ScalingHeaderScrollView wraps a UIScrollView internally — need to test if the PreferenceKey-based tracker still fires. Fallback: use the library's `.scrollViewDidReachBottom` + `.collapseProgress` to drive tab bar visibility.
- **Pull-to-refresh**: Library has built-in `.pullToRefresh(isActive:perform:)` — could replace the current refresh button on `StressCharacterCard`. Nice UX win for free.
- **Safe area**: Current dashboard uses `.ignoresSafeArea(edges: .vertical)` with manual `.padding(.top, 60)`. ScalingHeaderScrollView handles safe area differently — need to test and adjust.

## Security

No security implications — this is a UI-only change with no data flow modifications.

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| TabBar scroll-hide breaks | Medium | Test early; fallback to collapseProgress-driven visibility |
| Safe area conflicts | Medium | Remove `.ignoresSafeArea`, let library manage it |
| Library abandoned | Low | MIT license, simple enough to fork/inline if needed |
| Performance on older devices | Low | Library is lightweight SwiftUI wrapper |

## Success Criteria

- [ ] Character card visible when at top, collapses smoothly on scroll
- [ ] Compact bar shows date + stress badge when collapsed
- [ ] Snaps to expanded/collapsed after scroll deceleration
- [ ] TabBar hide-on-scroll still works
- [ ] Pull-to-refresh triggers stress data reload
- [ ] No visual glitches during fast scrolling
- [ ] Dark mode works correctly for both header states

## Files to Modify

| File | Action |
|------|--------|
| `StressMonitor.xcodeproj` | Add ScalingHeaderScrollView SPM dependency |
| `Views/DashboardView.swift` | Replace ScrollView with ScalingHeaderScrollView |
| `Views/Dashboard/Components/CompactStressHeaderBar.swift` | **Create** — new compact bar component |
| `Views/Dashboard/HomeDashboardView.swift` | **Delete** — unused Figma prototype |

## Unresolved Questions

1. Does `.trackScrollOffsetForTabBar` work with ScalingHeaderScrollView's internal scroll view, or do we need an alternative approach?
2. Should pull-to-refresh replace or coexist with the refresh button on StressCharacterCard?
3. What's the exact `max` height for the expanded header? Need to measure StressCharacterCard's rendered height (currently flexible, might need to constrain it).
