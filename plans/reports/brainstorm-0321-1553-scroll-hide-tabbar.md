# Brainstorm: Scroll-Hide Tab Bar

## Problem
Implement hide-on-scroll-down / show-on-scroll-up behavior for the custom `AnimatedTabBar` in `MainTabView`, with smooth spring animation.

## Requirements
- iOS 17+ (PreferenceKey approach)
- All 3 main tabs trigger hide (Dashboard, Trends, Action)
- Slide-only animation (no opacity change)
- Smooth spring feel matching other polished apps

## Evaluated Approaches

| Approach | iOS | Complexity | Chosen |
|----------|-----|------------|--------|
| PreferenceKey + GeometryReader | 17+ | Medium | YES |
| `onScrollGeometryChange` | 18+ | Low | No |
| Hybrid 17+18 | 17+ | High | No |

## Final Solution Architecture

### State
- `@Observable TabBarScrollState` owned by `MainTabView`
- Injected via `.environment()` to all tab views
- Tracks `isVisible: Bool` and `tabBarHeight: CGFloat`

### Scroll Detection
- `ScrollOffsetPreferenceKey` propagates scroll position
- `GeometryReader` with `.frame(in: .named("scroll"))` placed at top of each ScrollView content
- `minY >= 0` → always show; `delta < 0` → hide; `delta > 0` → show
- 10pt threshold to filter jitter

### Animation
```swift
AnimatedTabBar(...)
    .offset(y: isVisible ? 0 : tabBarScrollState.tabBarHeight)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
```

### Content Layout
- Static bottom padding = `tabBarHeight` (never changes = no content jump on hide/show)

## Files to Create/Modify

| File | Action |
|------|--------|
| `Views/Components/TabBar/TabBarScrollState.swift` | New |
| `Views/Components/TabBar/ScrollOffsetKey.swift` | New |
| `Views/MainTabView.swift` | Add env inject, height capture, offset animation |
| `Views/Dashboard/HomeDashboardView.swift` | Add scroll tracking |
| `Views/Trends/TrendsView.swift` | Add scroll tracking |
| `Views/Action/ActionView.swift` | Add scroll tracking |

## Risks
- `AnimatedTabBar` ball animation is independent — no interference expected
- `List`-based views need different GeometryReader placement (check ActionView)
- Tab switch should reset `isVisible = true` to prevent "stuck hidden" state
