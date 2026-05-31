# Phase 3: Integrate Scaling Header into DashboardView

## Overview
- **Priority:** P1
- **Status:** Pending
- **Effort:** 1.5h

Replace `ScrollView` in `DashboardView.content(_:)` with `ScalingHeaderScrollView`. Wire up collapse/expand crossfade between `StressCharacterCard` and `CompactStressHeaderBar`.

## Key Insights

- `StressCharacterCard` has flexible height in dashboard context (no fixed height)
- Need to measure/constrain max height for ScalingHeaderScrollView (~350pt)
- `collapseProgress` binding drives crossfade opacity
- Snap mode: `.afterFinishAccelerating`
- Current `.ignoresSafeArea(edges: .vertical)` may conflict — test and adjust
- Pull-to-refresh can replace the manual refresh button (bonus UX)

## Requirements

**Functional:**
- Expanded: full StressCharacterCard visible
- Collapsed: CompactStressHeaderBar visible
- Smooth crossfade transition between states
- Snap to expanded/collapsed after scroll deceleration
- All existing content below header unchanged

**Non-functional:**
- No visual glitches during fast scrolling
- Maintain existing appear animations on content cards

## Architecture

```swift
// DashboardView.content(_:)
ScalingHeaderScrollView {
    ZStack {
        StressCharacterCard(...)
            .opacity(1 - collapseProgress)
        CompactStressHeaderBar(...)
            .opacity(collapseProgress)
    }
} content: {
    LazyVStack(spacing: 24) {
        // ... existing content (insight, metrics, health data, etc.)
    }
}
.height(min: 60, max: 350)
.collapseProgress($collapseProgress)
.setHeaderSnapMode(.afterFinishAccelerating)
.allowsHeaderCollapse()
.allowsHeaderGrowth()
.hideScrollIndicators()
```

## Related Code Files

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/StressMonitor/Views/DashboardView.swift` | **Modify** | Replace ScrollView with ScalingHeaderScrollView |
| `StressMonitor/StressMonitor/Views/Dashboard/Components/CompactStressHeaderBar.swift` | Read | Created in Phase 2 |
| `StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift` | **Modify** | Add `.scalingHeader` context or fix dashboard height |

## Implementation Steps

1. **Fix StressCharacterCard height**: Add `.scalingHeader` case to `CharacterContext` returning fixed ~340pt, OR modify `.dashboard` to return 340pt. This prevents spacer compression during header collapse.
2. Add `import ScalingHeaderScrollView` to DashboardView.swift
3. Add `@State private var collapseProgress: CGFloat = 0` to DashboardView
4. Replace `ScrollView { ... }` in `content(_:)` with `ScalingHeaderScrollView`
4. Header block: ZStack with StressCharacterCard + CompactStressHeaderBar, crossfaded by collapseProgress
5. Content block: move existing `LazyVStack` content into the content closure
6. Apply modifiers: `.height(min: 60, max: 350)`, `.collapseProgress($collapseProgress)`, `.setHeaderSnapMode(.afterFinishAccelerating)`, `.allowsHeaderCollapse()`, `.allowsHeaderGrowth()`
7. Remove `.trackScrollOffsetForTabBar(state:)` from the old ScrollView (handled in Phase 4)
8. Test: scroll up/down, verify crossfade, verify snap behavior
9. Test: pull down past top to verify `.allowsHeaderGrowth()` scales character card

## Todo List

- [ ] Add import and collapseProgress state
- [ ] Replace ScrollView with ScalingHeaderScrollView
- [ ] Implement header ZStack with crossfade
- [ ] Move content to content closure
- [ ] Apply height/snap/collapse modifiers
- [ ] Fix StressCharacterCard height for scaling context
- [ ] Remove old scroll tracking (temporary — Phase 4 adds replacement)
- [ ] Test collapse/expand behavior
- [ ] Test dark mode

## Success Criteria

- Header collapses smoothly on scroll down
- Header expands on scroll to top
- Crossfade between character card and compact bar is smooth
- Snaps to expanded/collapsed after deceleration
- All content below header renders correctly
- No safe area layout issues

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| StressCharacterCard exceeds max height | Constrain with `.frame(maxHeight: 340)` inside header |
| Safe area conflict | Remove `.ignoresSafeArea`, test with/without |
| Appear animations break | Verify `appearAnimation` opacity still works in content block |
