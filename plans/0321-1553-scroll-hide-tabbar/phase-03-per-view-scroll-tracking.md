# Phase 3: Per-View Scroll Tracking

<!-- Updated: Validation Session 1 - replaced PreferenceKey/GeometryReader with onScrollGeometryChange; removed Color.clear anchors and coordinateSpace modifiers -->
<!-- Completed: 2026-03-21 - Used PreferenceKey for iOS 17.6 compatibility instead of onScrollGeometryChange (iOS 18+) -->

## Overview
- **Priority**: High (depends on Phase 1 & 2)
- **Status**: ✅ completed
- **Effort**: 20m

## Pattern Applied to All 3 Views

Each view needs:
1. `@Environment(TabBarScrollState.self)` to access state
2. `.onScrollGeometryChange` on the `ScrollView` — replaces PreferenceKey entirely
3. Static bottom padding = `tabBarScrollState.tabBarHeight + 16` (replace any hardcoded values)

No `Color.clear` anchors. No `.coordinateSpace`. No GeometryReader.

---

## HomeDashboardView.swift

```swift
@Environment(TabBarScrollState.self) private var tabBarScrollState

var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 0) {
            // ... existing content unchanged ...

            // Bottom padding accounts for floating tab bar
            Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
        }
    }
    .onScrollGeometryChange(for: CGFloat.self) { geometry in
        geometry.contentOffset.y
    } action: { _, newOffset in
        tabBarScrollState.handleScrollOffset(newOffset)
    }
}
```

---

## TrendsView.swift

```swift
@Environment(TabBarScrollState.self) private var tabBarScrollState

var body: some View {
    ScrollView {
        VStack(spacing: 16) {
            // ... existing content unchanged ...

            Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
        }
    }
    .onScrollGeometryChange(for: CGFloat.self) { geometry in
        geometry.contentOffset.y
    } action: { _, newOffset in
        tabBarScrollState.handleScrollOffset(newOffset)
    }
}
```

---

## ActionView.swift

```swift
@Environment(TabBarScrollState.self) private var tabBarScrollState

var body: some View {
    NavigationStack {
        ScrollView {
            VStack(spacing: 24) {
                // ... existing content unchanged ...

                // Replace hardcoded Spacer().frame(height: 100) with:
                Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
            }
            .padding(.horizontal, 16)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newOffset in
            tabBarScrollState.handleScrollOffset(newOffset)
        }
        .background(Color.Wellness.adaptiveBackground)
        .navigationTitle("Action")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Key**: Replace `Spacer().frame(height: 100)` → `Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)`.

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Scroll to top | `contentOffsetY <= 5` → force `isVisible = true` |
| Tab switch | `resetToVisible()` in `MainTabView` binding |
| Content shorter than screen | `onScrollGeometryChange` never fires → tab bar stays visible |
| Very fast fling | Threshold still applies; top-check handles bounce direction flip |

## Todo
- [x] Update `HomeDashboardView.swift`: add `@Environment`, scroll tracking, bottom padding
- [x] Update `TrendsView.swift`: same pattern
- [x] Update `ActionView.swift`: same pattern, replace hardcoded `height: 100` spacer
- [x] Build & verify all 3 views compile
- [x] Run in simulator: scroll each tab, verify hide/show + tab switch reset

## Implementation Deviation
- Used `PreferenceKey` + `.coordinateSpace(name:)` + `.onPreferenceChange()` pattern instead of `onScrollGeometryChange`
- Reason: Project targets iOS 17.6; `onScrollGeometryChange` requires iOS 18+
- All 3 views use unique coordinate space names: "homeScrollView", "trendsScrollView", "actionScrollView"
