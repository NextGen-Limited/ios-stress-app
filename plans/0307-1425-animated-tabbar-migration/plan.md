# Plan: Migrate to Exyte AnimatedTabBar

## Overview
- **Status**: Draft
- **Priority**: Medium
- **Effort**: Low
- **Phase**: 1 phase

## Context
User wants to migrate from custom `StressTabBarView` to Exyte AnimatedTabBar library (v1.0.0). Library already added to project via SPM.

### Current Implementation
- Custom `StressTabBarView` with `TabItem` enum (5 tabs)
- Custom `TabBarItem` with separate selected/unselected icons
- Custom corner radius (64pt), shadow styling
- Haptic feedback on tap
- Accessibility support

### Target
- Use `AnimatedTabBar` from Exyte
- Preserve current visual design (corner radius, shadow)
- Maintain haptics and accessibility

---

## Phase 1: AnimatedTabBar Integration

### Steps

1. **Update TabItem to conform to `AnimatableTab`**
   - Add required properties: `title`, `icon`, `color`
   - Keep existing icon logic for selected/unselected states

2. **Create custom TabButton views**
   - Build custom button matching current `TabBarItem` design
   - Support both SF Symbols and custom images
   - Add haptic feedback in `didSelectIndex`

3. **Migrate MainTabView**
   - Replace `ZStack` + `StressTabBarView` with `AnimatedTabBar`
   - Map `TabItem` to tab buttons
   - Handle content switching via `selectedIndex`

4. **Apply custom styling**
   - Match current corner radius (64pt)
   - Preserve shadow styling
   - Configure ball animation (parabolic recommended)

5. **Build and verify**
   - Compile succeeds
   - All 5 tabs work
   - Animations display correctly

---

## Files to Modify

| File | Change |
|------|--------|
| `StressMonitor/Views/Components/TabBar/TabItem.swift` | Add AnimatableTab conformance |
| `StressMonitor/Views/Components/TabBar/StressTabBarView.swift` | Replace with AnimatedTabBar wrapper |
| `StressMonitor/Views/MainTabView.swift` | Update to use AnimatedTabBar |

---

## Notes

- Exyte AnimatedTabBar requires iOS 16+
- Library provides `DropletButton` and `WiggleButton` as built-in options
- Custom buttons needed to match current design with separate selected/unselected icons
- Current `Tabbable` protocol can be removed or adapted

---

## Next Steps

After plan approval → Cook command to implement migration
