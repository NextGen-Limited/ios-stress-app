# Debugger Report: Scroll-Hide Tab Bar Animation Not Working

**Date:** 2026-03-21 17:47
**Status:** FIXED
**Simulator:** iPhone 17 Pro (00AFDCEE-858A-4B7D-B5B4-08D3B1D6CAFB)

## Summary

The scroll-hide tab bar animation was not working because the **DashboardView** (the primary view for the home tab) was missing the scroll tracking implementation.

## Root Cause

**DashboardView.swift** was not configured to participate in scroll tracking:

1. Missing `@Environment(TabBarScrollState.self)` injection
2. Missing `.trackScrollOffsetForTabBar(state:)` modifier on scroll content
3. Missing `.coordinateSpace(.named("scrollView"))` on ScrollView
4. Missing bottom padding to account for tab bar height

While other views (TrendsView, ActionView, HomeDashboardView) had all the necessary setup, the main DashboardView used for the `.home` tab case was missing these components.

## Fix Applied

**File:** `/Users/ddphuong/Projects/next-labs/ios-stress-app/StressMonitor/StressMonitor/Views/DashboardView.swift`

### Changes:

1. Added environment injection:
```swift
@Environment(TabBarScrollState.self) private var tabBarScrollState
```

2. Updated `content()` function:
   - Added `.trackScrollOffsetForTabBar(state: tabBarScrollState)` to LazyVStack
   - Added `.coordinateSpace(.named("scrollView"))` to ScrollView
   - Changed bottom padding from `32` to `tabBarScrollState.tabBarHeight + 16`

## Implementation Details

### How Scroll-Hide Works

```
User scrolls down
    ↓
ScrollView content moves up
    ↓
GeometryReader captures frame.origin.y (goes negative)
    ↓
PreferenceKey propagates value
    ↓
handleScrollOffset() negates value (makes positive)
    ↓
Delta > 0 && offset > 0 → isVisible = false
    ↓
Tab bar animates down with spring animation
```

### Key Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `TabBarScrollState` | TabBarScrollState.swift | Observable state managing visibility |
| `ScrollOffsetPreferenceKey` | TabBarScrollState.swift | Propagates scroll offset |
| `.trackScrollOffsetForTabBar()` | TabBarScrollState.swift | View extension for tracking |
| `.coordinateSpace(.named("scrollView"))` | Each scroll view | Reference frame for GeometryReader |
| `@Environment(TabBarScrollState.self)` | Scroll views | Receives state from MainTabView |
| `.offset(y:)` + `.animation()` | MainTabView.swift | Actual hide/show animation |

## Files Verified

All scrollable views now have proper tracking:

- [x] **DashboardView.swift** - FIXED (was missing)
- [x] **TrendsView.swift** - Already correct
- [x] **ActionView.swift** - Already correct
- [x] **HomeDashboardView.swift** - Already correct

## Build & Test

```
Build: SUCCEEDED (warnings only)
Install: SUCCESS
Launch: SUCCESS (PID: 3308)
```

App is running in simulator. Tab bar visible on launch. User should manually test:
1. Scroll down on Home tab → tab bar should hide
2. Scroll up → tab bar should reveal with spring animation
3. Switch tabs → tab bar should reset to visible

## Unresolved Questions

1. **Manual verification needed**: Cannot programmatically trigger swipe gestures in simulator without idb installed. User should manually test scroll-hide behavior.

2. **Threshold tuning**: Current scroll threshold is 5pt. May need adjustment based on user feedback.
