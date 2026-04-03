# Phase 4: Fix Tab Bar Scroll Tracking

## Overview
- **Priority:** P1
- **Status:** Pending
- **Effort:** 45m

`TabBarScrollState.trackScrollOffsetForTabBar` is a `ScrollView` extension using `.onScrollGeometryChange`. ScalingHeaderScrollView is NOT a SwiftUI ScrollView — the extension won't compile. Need GeometryReader-based content offset tracking.

## Key Insights

- `collapseProgress` only tracks header collapse range (0.0-1.0). Once header fully collapsed, it stays at 1.0 — useless for tracking continued content scrolling.
- GeometryReader inside the content block can track vertical offset relative to a named coordinate space.
- `TabBarScrollState.handleScrollOffset(_:)` already handles delta-based show/hide logic — reuse it.
- ScalingHeaderScrollView wraps a UIScrollView internally, but we can't access its coordinate space directly.

## Architecture

Place an invisible GeometryReader anchor at the top of the content block. Track its Y offset relative to DashboardView's coordinate space.

```swift
// Inside ScalingHeaderScrollView content closure:
LazyVStack(spacing: 24) {
    // Invisible scroll offset tracker
    GeometryReader { geo in
        Color.clear
            .preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geo.frame(in: .named("dashboard")).minY
            )
    }
    .frame(height: 0)

    // ... existing content
}
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
    tabBarScrollState.handleScrollOffset(-offset)
}

// On DashboardView or ScalingHeaderScrollView:
.coordinateSpace(name: "dashboard")
```

## Related Code Files

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/StressMonitor/Views/DashboardView.swift` | **Modify** | Add GeometryReader tracker + coordinate space |
| `StressMonitor/StressMonitor/Views/Components/TabBar/TabBarScrollState.swift` | Read | Reuse existing `handleScrollOffset(_:)` API |

## Implementation Steps

1. Create `ScrollOffsetPreferenceKey` (simple `PreferenceKey` for CGFloat) — can be a private struct in DashboardView or a small shared file
2. Add `.coordinateSpace(name: "dashboard")` to the ScalingHeaderScrollView or its parent
3. Inside the content closure's `LazyVStack`, insert a zero-height `GeometryReader` at the top
4. Read frame in named coordinate space, set as preference value
5. Add `.onPreferenceChange(ScrollOffsetPreferenceKey.self)` to feed offset to `tabBarScrollState.handleScrollOffset(_:)`
6. Test: scroll down past collapsed header — tab bar hides
7. Test: scroll up within content — tab bar shows
8. Test: scroll back to top — header expands, tab bar visible
9. Test: quick flick behavior — no jitter

## Todo List

- [ ] Create ScrollOffsetPreferenceKey
- [ ] Add coordinateSpace to dashboard
- [ ] Add GeometryReader tracker in content block
- [ ] Wire onPreferenceChange to tabBarScrollState
- [ ] Test scroll down hides tab bar (full scroll range)
- [ ] Test scroll up shows tab bar
- [ ] Test quick flick behavior

## Success Criteria

- Tab bar hides when scrolling down — both during header collapse AND during content scrolling
- Tab bar shows when scrolling up at any point
- No jitter or rapid show/hide flickering
- Spring animation on tab bar preserved
- Works across full scroll range, not just header collapse range

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Coordinate space not accessible inside ScalingHeaderScrollView | Place `.coordinateSpace` on parent view wrapping the ScalingHeaderScrollView |
| GeometryReader causes layout issues in LazyVStack | Use `.frame(height: 0)` to make it invisible; place before first content item |
| Offset sign/direction mismatch | Negate offset if needed; test with `handleScrollOffset` existing threshold logic |
