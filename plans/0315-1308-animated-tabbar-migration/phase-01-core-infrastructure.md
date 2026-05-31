# Phase 1: Core Infrastructure

**Priority:** P1
**Status:** Pending
**Estimated Time:** 1h

## Overview

Create the foundational components for the animated tab bar: Layout protocol for equal button distribution, PreferenceKey for storing frame coordinates, and animation timing constants.

## Requirements

### Functional
- Custom Layout protocol that distributes buttons equally
- Store each button's frame coordinates for later use
- Centralized animation timing constants

### Non-Functional
- Pure SwiftUI (iOS 17+)
- No external dependencies
- Clean, documented code

## Key Insights from Exyte Tutorial

1. Use `Layout` protocol instead of HStack for precise control
2. Override `sizeThatFits` and `placeSubviews` methods
3. Store frames via PreferenceKey for ball animation calculations

## Related Code Files

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/Components/TabBarLayout.swift`
- `StressMonitor/StressMonitor/Views/Components/TabBar/Animations/TabBarAnimation.swift`

### Read (Reference)
- `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarView.swift`

## Architecture

### TabBarLayout.swift

```swift
// Layout protocol for equal distribution
struct TabBarLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Return size based on proposal and subview heights
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Distribute subviews equally along horizontal axis
    }
}

// PreferenceKey for storing frames
struct TabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// Frame data transfer
struct TabFrameData: Equatable {
    let index: Int
    let frame: CGRect
}
```

### TabBarAnimation.swift

```swift
enum TabBarAnimation {
    // Ball animation
    static let ballDuration: Double = 0.4

    // Indent timing
    static let indentAppearStart: Double = 0.7
    static let indentDisappearEnd: Double = 0.3
    static let indentMaxDepth: CGFloat = 15

    // Icon effects
    static let iconScaleDuration: Double = 0.2
    static let iconWiggleDuration: Double = 0.4
    static let iconScaleFactor: CGFloat = 1.15

    // Animation curves
    static let scaleCurve: Animation = .linear
    static let wiggleCurve: Animation = .spring(response: 0.3, dampingFraction: 0.6)
}
```

## Implementation Steps

1. **Create directory structure**
   - Create `Components/` subdirectory
   - Create `Animations/` subdirectory

2. **Create TabBarAnimation.swift**
   - Define timing constants
   - Define animation curves
   - Group related values

3. **Create TabBarLayout.swift**
   - Implement `Layout` protocol
   - Implement `sizeThatFits` method
   - Implement `placeSubviews` method
   - Create `TabFramePreferenceKey`
   - Create `TabFrameData` struct

4. **Test layout works**
   - Build project
   - Verify no compile errors

## Todo List

- [ ] Create `Components/` directory
- [ ] Create `Animations/` directory
- [ ] Create `TabBarAnimation.swift` with constants
- [ ] Create `TabBarLayout.swift` with Layout protocol
- [ ] Implement `sizeThatFits` method
- [ ] Implement `placeSubviews` method
- [ ] Create `TabFramePreferenceKey`
- [ ] Build and verify no errors

## Success Criteria

- [x] Directory structure created
- [x] Animation constants centralized
- [x] Layout protocol compiles
- [x] PreferenceKey compiles
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Layout protocol complexity | Start simple, add complexity incrementally |
| PreferenceKey not capturing data | Test with debug prints first |

## Next Steps

- Proceed to Phase 2: Bezier Path Utilities
