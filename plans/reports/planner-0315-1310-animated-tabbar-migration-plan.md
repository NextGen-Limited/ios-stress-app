# Animated TabBar Migration Plan

**Date:** 2026-03-15
**Status:** Complete
**Total Effort:** ~4h

## Summary

Created comprehensive implementation plan for migrating `StressTabBarView` to Exyte-style animated tab bar with:
- Ball animation along bezier path
- Indented rectangle with delayed animation
- Icon scale + wiggle effects
- Preserved accessibility and haptic feedback

## Plan Location

`/Users/ddphuong/Projects/next-labs/ios-stress-app/plans/0315-1308-animated-tabbar-migration/`

## Files Created

| File | Purpose |
|------|---------|
| `plan.md` | Overview, architecture, file structure |
| `phase-01-core-infrastructure.md` | Layout protocol, PreferenceKey, timing constants |
| `phase-02-bezier-path-utilities.md` | Path length calculation, point interpolation |
| `phase-03-ball-animation.md` | GeometryEffect, BallView, path construction |
| `phase-04-indented-rectangle.md` | Custom Shape with animatable indent |
| `phase-05-animated-button.md` | Scale + wiggle effects, accessibility |
| `phase-06-integration.md` | Final integration, testing checklist |

## Key Architecture Decisions

1. **Modular Structure:** 8 new files, each < 80 lines
2. **Pure SwiftUI:** No external dependencies (uses Layout protocol, GeometryEffect, Shape)
3. **iOS 17+:** Uses @Observable patterns, modern animation APIs
4. **Preserved Features:** TabItem enum, accessibility, haptics unchanged

## Implementation Order

```
Phase 1 (1h)     Phase 2 (45m)    Phase 3 (1h)
Infrastructure → Bezier Utils → Ball Animation
                                        ↓
Phase 6 (45m)     Phase 5 (45m)    Phase 4 (45m)
Integration ← Animated Button ← Indented Rect
```

## Files to Create (8 total)

```
TabBar/
├── Animations/
│   └── TabBarAnimation.swift        (30 lines)
├── Components/
│   ├── TabBarLayout.swift           (60 lines)
│   ├── BallView.swift               (50 lines)
│   ├── IndentedRectShape.swift      (70 lines)
│   └── AnimatedTabButton.swift      (80 lines)
└── Effects/
    ├── BezierPathLength.swift       (80 lines)
    └── PathPositionEffect.swift     (40 lines)
```

## Files to Modify (1)

- `StressTabBarView.swift` - Major refactor (~120 lines)

## Animation Specs

| Animation | Duration | Curve | Notes |
|-----------|----------|-------|-------|
| Ball travel | 0.4s | easeInOut | Bezier arc path |
| Indent appear | 0.3s | easeIn | Starts at 0.7s |
| Indent disappear | 0.3s | easeOut | Ends at 0.3s |
| Icon scale | 0.2s | linear | 1.0 -> 1.15 |
| Icon wiggle | 0.4s | spring | 5 deg rotation |

## Unresolved Questions

None. All requirements addressed in plan.

## References

- Exyte Tutorial: https://exyte.com/blog/swiftui-animated-tabbar
- Current Implementation: `StressMonitor/.../TabBar/StressTabBarView.swift`
- TabItem Definition: `StressMonitor/.../TabBar/TabItem.swift`
