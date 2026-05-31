# Phase 1: Core Scroll State

<!-- Updated: Validation Session 1 - switched to onScrollGeometryChange; removed ScrollOffsetKey; added tabBarHeight default -->
<!-- Completed: 2026-03-21 - Used PreferenceKey instead of onScrollGeometryChange (iOS 17.6 compatibility) -->

## Overview
- **Priority**: High (blocking phases 2 & 3)
- **Status**: ✅ completed
- **Effort**: 20m

## Files to Create

### `StressMonitor/Views/Components/TabBar/TabBarScrollState.swift`

```swift
import Observation
import SwiftUI

@Observable
final class TabBarScrollState {
    var isVisible: Bool = true
    var tabBarHeight: CGFloat = 83  // fallback before onAppear fires

    private var lastOffset: CGFloat = 0
    private let threshold: CGFloat = 10

    func handleScrollOffset(_ contentOffsetY: CGFloat) {
        // Always show when at top
        if contentOffsetY <= 5 {
            isVisible = true
            lastOffset = contentOffsetY
            return
        }

        let delta = contentOffsetY - lastOffset
        guard abs(delta) >= threshold else { return }

        // contentOffsetY increasing = scrolling down = hide
        // contentOffsetY decreasing = scrolling up = show
        isVisible = delta < 0
        lastOffset = contentOffsetY
    }

    func resetToVisible() {
        isVisible = true
        lastOffset = 0
    }
}
```

**Notes:**
- `contentOffsetY` is from `onScrollGeometryChange` — `0` at top, positive going down
- `threshold` prevents jitter on micro-scrolls
- `tabBarHeight = 83` is a safe fallback for typical floating tab bar + 16pt padding; overwritten by `onAppear`

## Todo
- [x] Create `TabBarScrollState.swift`
- [x] Build & verify no compile errors

## Implementation Deviation
- Used `PreferenceKey` instead of `onScrollGeometryChange` for iOS 17.6 compatibility
- `ScrollOffsetPreferenceKey` merged into same file
