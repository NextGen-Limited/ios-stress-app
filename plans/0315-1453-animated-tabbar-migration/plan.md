# Animated TabBar Migration Plan

**Created:** 2026-03-15
**Status:** Complete
**Priority:** Medium
**Completed:** 2026-03-20

## Overview

Migrate custom `StressTabBarView` to use **exyte/AnimatedTabBar** library to reduce code complexity and leverage maintained animation presets.

## Current State

- Custom ball animation with bezier path
- IndentedRectShape background
- 9 supporting files in TabBar folder
- ~225 lines in main view

## Target State

- Use library's `AnimatedTabBar` with preset animations
- Minimal custom code
- Cleaner architecture

## Files to Modify

| File | Action |
|------|--------|
| `MainTabView.swift` | Replace StressTabBarView with AnimatedTabBar |
| `StressTabBarView.swift` | Delete |
| `TabBar/*.swift` | Delete supporting files |

## Implementation Steps

### Step 1: Create TabButton Views
Create custom `TabButtonView` for each tab using library's `TabButton`:
- Home button with selected/unselected icons
- Action button with selected/unselected icons
- Trend button with selected/unselected icons

### Step 2: Update MainTabView
Replace `StressTabBarView(selectedTab: $selectedTab)` with:
```swift
AnimatedTabBar(selectedIndex: $selectedIndex) {
    TabButton1()
    TabButton2()
    TabButton3()
}
```

### Step 3: Handle Tab Conversion
Convert `TabItem` to Int index:
```swift
var selectedIndex: Binding<Int> {
    Binding(
        get: { selectedTab.rawValue },
        set: { selectedTab = TabItem(rawValue: $0) ?? .home }
    )
}
```

### Step 4: Remove Old Code
- Delete StressTabBarView.swift
- Delete TabBar/Animations/, TabBar/Components/, TabBar/Effects/
- Keep TabItem.swift (reusable enum)

## Animation Options

Library provides: `Default`, `Spring`, `Bounce`, `Wave`, `Tilt`, `Pulse`

**Recommended:** Use default or customize with `animation` parameter.

## Risks

- Custom icons may need wrapping in `AnyView`
- Indented background shape may not be supported - fallback to standard rounded rect
- Haptic feedback needs manual re-addition

## Success Criteria

- [x] Library integrated via SPM (already done)
- [x] 3 tabs working with animations (DropletButton used)
- [x] Tab selection syncs with NavigationStack (selectedIndex Binding)
- [x] Old supporting files removed (StressTabBarView.swift deleted)
- [x] Build succeeds (verified Mar 15, 2026)
- [x] Accessibility labels preserved (accessibilityLabel, accessibilityHint, accessibilityIdentifier)
- [x] Haptic feedback integration (completed Mar 20, 2026)

## Files Modified

| File | Status | Notes |
|------|--------|-------|
| `MainTabView.swift` | Updated | Uses AnimatedTabBar with selectedIndex binding |
| `AnimatedTabButtons.swift` | Created | Extension with tabButtons() helper |
| `TabItem.swift` | Updated | Added rawValue (0,1,2), Identifiable conformance |
| `StressTabBarView.swift` | Deleted | Custom implementation removed |

## Known Follow-ups

- [x] Re-add haptic feedback via `HapticManager.shared.buttonPress()` in tab selection (completed Mar 20, 2026)

---

## Validation Log

**Date:** 2026-03-15

| Question | Decision | Notes |
|----------|----------|-------|
| Animation preset | Default | Use library default animation |
| Icon rendering | Custom icons | Use TabItem.selectedIconName/unselectedIconName |
| Haptic feedback | Add back | Re-add HapticManager.shared.buttonPress() |

**Recommendation:** Proceed with implementation.
