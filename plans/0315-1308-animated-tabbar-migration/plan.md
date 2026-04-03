---
title: "Exyte-Style Animated TabBar Migration"
description: "Migrate StressTabBarView to Exyte-style animated tab bar with ball animation, indented rect, and icon effects"
status: pending
priority: P2
effort: 4h
branch: main
tags: [ui, animation, swiftui, tabbar]
created: 2026-03-15
---

## Overview

Migrate `StressTabBarView` from static tab bar to animated tab bar using Exyte's design pattern. Features: ball animation along bezier path, indented rect with delayed animation, and icon scale/wiggle effects.

**Source Reference:** https://exyte.com/blog/swiftui-animated-tabbar

## Current State

- **File:** `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarView.swift`
- **Lines:** ~130 lines, simple HStack-based layout
- **Features:** 3 tabs (home, action, trend), separate selected/unselected images, haptic feedback, accessibility

## Target Architecture

```
TabBar/
├── StressTabBarView.swift          # Main container (updated)
├── TabItem.swift                   # Unchanged
├── Components/
│   ├── AnimatedTabButton.swift     # Individual button with scale/wiggle
│   ├── BallView.swift              # Ball that travels along bezier path
│   ├── IndentedRectShape.swift     # Rectangle with animated indent
│   └── TabBarLayout.swift          # Layout protocol + PreferenceKey
├── Effects/
│   ├── PathPositionEffect.swift    # GeometryEffect for ball position
│   └── BezierPathLength.swift      # Bezier curve utilities
└── Animations/
    └── TabBarAnimation.swift       # Animation timing constants
```

## Key Components

### 1. Layout Protocol (TabBarLayout.swift)
- Custom `Layout` protocol for equal button distribution
- `PreferenceKey` to store frame coordinates
- `sizeThatFits` and `placeSubviews` methods

### 2. Ball Animation (BallView.swift + PathPositionEffect.swift)
- `GeometryEffect` with `AnimatableData` for position interpolation
- Bezier path from previous tab to selected tab
- Control point above tabs for arc trajectory
- Uses `BezierPathLength` utility for path traversal

### 3. Indented Rectangle (IndentedRectShape.swift)
- Custom `Shape` with `animatableData`
- SVG-like path with parameterized indent depth
- Indent appears from 0.7-1.0s, disappears from 0-0.3s
- Normalized parameter for smooth interpolation

### 4. Icon Effects (AnimatedTabButton.swift)
- Scale effect on selection (linear curve)
- Wiggle animation (spring curve)
- Separate animation parameters for growth vs wiggle
- Initial selection handling

## Animation Timing

| Phase | Duration | Behavior |
|-------|----------|----------|
| Ball travel | 0.3-0.5s | Bezier path traversal |
| Indent appear | 0.7-1.0s | Delayed depth animation |
| Indent disappear | 0-0.3s | Quick collapse |
| Icon scale | 0.2s | Linear curve |
| Icon wiggle | 0.4s | Spring curve |

## Implementation Phases

### Phase 1: Core Infrastructure (1h)
- Create `TabBarLayout.swift` with Layout protocol
- Create `PreferenceKey` for frame storage
- Create `TabBarAnimation.swift` with timing constants

### Phase 2: Bezier Path Utilities (45m)
- Create `Effects/BezierPathLength.swift`
- Implement path length calculation
- Implement point-at-percent functionality

### Phase 3: Ball Animation (1h)
- Create `Effects/PathPositionEffect.swift`
- Create `Components/BallView.swift`
- Implement path construction between tabs
- Handle previous selection tracking

### Phase 4: Indented Rectangle (45m)
- Create `Components/IndentedRectShape.swift`
- Implement animatable indent depth
- Add delayed animation logic

### Phase 5: Animated Button (45m)
- Create `Components/AnimatedTabButton.swift`
- Implement scale + wiggle effects
- Preserve existing icon rendering logic
- Preserve accessibility features

### Phase 6: Integration (45m)
- Update `StressTabBarView.swift` to use new components
- Add ball view with z-index layering
- Wire up selection state and animations
- Preserve haptic feedback

## Files to Create

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `TabBarLayout.swift` | Layout protocol + PreferenceKey | 60 |
| `BezierPathLength.swift` | Path utilities | 80 |
| `PathPositionEffect.swift` | GeometryEffect for ball | 40 |
| `BallView.swift` | Ball component | 50 |
| `IndentedRectShape.swift` | Animated shape | 70 |
| `AnimatedTabButton.swift` | Button with effects | 80 |
| `TabBarAnimation.swift` | Timing constants | 30 |
| **Updated `StressTabBarView.swift`** | Main container | 120 |

**Total:** ~530 new lines, modular structure

## Files to Modify

- `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarView.swift` (major refactor)

## Files to Preserve (No Changes)

- `StressMonitor/StressMonitor/Views/Components/TabBar/TabItem.swift`
- `StressMonitor/StressMonitor/Views/Components/HapticManager.swift`

## Success Criteria

1. **Visual:** Ball animates smoothly between tabs along arc path
2. **Visual:** Indent appears with delay, disappears quickly
3. **Visual:** Icons scale up and wiggle on selection
4. **Functional:** All existing accessibility features work
5. **Functional:** Haptic feedback triggers on selection
6. **Performance:** 60fps animation, no dropped frames
7. **Code:** No external dependencies, pure SwiftUI
8. **Code:** Files under 200 lines each (modularized)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Complex animation timing | Use explicit timing constants, test thoroughly |
| Bezier path edge cases | Handle 2-3 tab cases, edge positions |
| Accessibility regression | Preserve all existing a11y modifiers |
| Performance on older devices | Profile with Instruments, simplify if needed |

## Security Considerations

- No security implications (UI-only change)

## Dependencies

- None (pure SwiftUI, iOS 17+)

## Next Steps

1. Start with Phase 1 (Core Infrastructure)
2. Build incrementally, test each phase
3. Run build after each component creation
4. Final integration and visual testing
