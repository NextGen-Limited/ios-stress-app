# Phase 3: Ball Animation

**Priority:** P1
**Status:** Pending
**Estimated Time:** 1h

## Overview

Create the ball that animates along a bezier path between tabs using GeometryEffect with AnimatableData. The ball follows an arc trajectory with a control point above the tabs.

## Requirements

### Functional
- Ball animates from previous tab to newly selected tab
- Path is a quadratic bezier curve with arc trajectory
- Smooth interpolation using AnimatableData
- Track previous selection for path construction

### Non-Functional
- 60fps animation
- Smooth easing
- Pure SwiftUI

## Key Insights from Exyte Tutorial

1. Use `GeometryEffect` with `AnimatableData` for position interpolation
2. Control point should be above tabs for arc trajectory
3. Subscribe to selection changes to track previous index
4. `t` parameter (0-1) controls position along path

## Related Code Files

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/Effects/PathPositionEffect.swift`
- `StressMonitor/StressMonitor/Views/Components/TabBar/Components/BallView.swift`

### Reference
- Phase 1: `TabBarLayout.swift` (for frame coordinates)
- Phase 2: `BezierPathLength.swift` (for path utilities)
- `TabBarAnimation.swift` (for timing)

## Architecture

### PathPositionEffect.swift

```swift
// GeometryEffect for ball position along path
struct PathPositionEffect: GeometryEffect {
    var t: CGFloat  // 0 to 1, declared as animatableData
    let path: Path

    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        // Get point at t percent along path
        // Return translation transform
    }
}

// Convenience modifier
extension View {
    func followPath(_ path: Path, progress: CGFloat) -> some View {
        self.modifier(PathPositionEffect(t: progress, path: path))
    }
}
```

### BallView.swift

```swift
struct BallView: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.primaryBlue)
            .frame(width: size, height: size)
            .shadow(color: .primaryBlue.opacity(0.3), radius: 4)
    }
}
```

### Path Construction Logic

```swift
// In StressTabBarView or helper
func createPath(from start: CGRect, to end: CGRect) -> Path {
    var path = Path()

    let startPoint = CGPoint(x: start.midX, y: start.midY)
    let endPoint = CGPoint(x: end.midX, y: end.midY)

    // Control point above mid-point
    let controlY = min(start.midY, end.midY) - 30
    let controlPoint = CGPoint(
        x: (startPoint.x + endPoint.x) / 2,
        y: controlY
    )

    path.move(to: startPoint)
    path.addQuadCurve(to: endPoint, control: controlPoint)

    return path
}
```

## Implementation Steps

1. **Create PathPositionEffect.swift**
   - Implement GeometryEffect protocol
   - Add `t` as animatableData
   - Use BezierPathLength for point calculation
   - Return ProjectionTransform with offset

2. **Create BallView.swift**
   - Simple circle with color
   - Add shadow for depth
   - Make size configurable

3. **Implement path construction**
   - Create helper function for path between tabs
   - Use frame coordinates from PreferenceKey
   - Calculate control point for arc

4. **Add selection tracking**
   - Store previous selected index
   - Update on selection change via onChange

5. **Build and verify**
   - No compile errors

## Todo List

- [ ] Create `PathPositionEffect.swift`
- [ ] Implement GeometryEffect with AnimatableData
- [ ] Create `BallView.swift`
- [ ] Implement path construction helper
- [ ] Add previous selection tracking
- [ ] Build and verify no errors

## Success Criteria

- [x] PathPositionEffect compiles
- [x] BallView compiles
- [x] Path construction works
- [x] Selection tracking works
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Animation jank | Test with various timing curves |
| Path calculation errors | Debug print frame coordinates |

## Next Steps

- Proceed to Phase 4: Indented Rectangle
