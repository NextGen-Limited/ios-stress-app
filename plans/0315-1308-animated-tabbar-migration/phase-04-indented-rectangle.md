# Phase 4: Indented Rectangle

**Priority:** P1
**Status:** Pending
**Estimated Time:** 45m

## Overview

Create a custom Shape with an animatable indent at the top. The indent appears with a delay (0.7-1.0s) and disappears quickly (0-0.3s) using normalized parameter interpolation.

## Requirements

### Functional
- Rectangle with indent at top center
- Indent depth animates smoothly
- Delayed appear animation (0.7-1.0s)
- Quick disappear animation (0-0.3s)
- Positioned behind selected tab

### Non-Functional
- Smooth interpolation via animatableData
- Clean SVG-like path construction

## Key Insights from Exyte Tutorial

1. Use `Shape` protocol with `animatableData`
2. Construct path using bezier curves
3. Normalize parameter for delayed animation
4. Same normalization works for both appear/disappear

## Related Code Files

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/Components/IndentedRectShape.swift`

### Reference
- `TabBarAnimation.swift` (for indent depth constant)

## Architecture

### IndentedRectShape.swift

```swift
struct IndentedRectShape: Shape {
    var t: CGFloat  // 0 to 1, animatable

    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Normalize t for delayed animation
        let indentDepth = normalizedIndentDepth(t: t)

        // Construct path with indent
        var path = Path()

        // Start from top-left
        // Add indent in top-center if depth > 0
        // Complete rectangle

        return path
    }

    private func normalizedIndentDepth(t: CGFloat) -> CGFloat {
        if t >= TabBarAnimation.indentAppearStart {
            // Appear: map 0.7-1.0 to 0-1
            return (t - TabBarAnimation.indentAppearStart) / (1.0 - TabBarAnimation.indentAppearStart)
        } else if t <= TabBarAnimation.indentDisappearEnd {
            // Disappear: map 0-0.3 to 1-0
            return 1.0 - (t / TabBarAnimation.indentDisappearEnd)
        } else {
            // No indent
            return 0
        }
    }
}
```

### SVG-like Path Construction

```
Vertices:
- V1: top-left
- V2: indent-start (top-center-left)
- V3: indent-bottom (deepest point)
- V4: indent-end (top-center-right)
- V5: top-right
- V6: bottom-right
- V7: bottom-left

Path:
V1 -> V2 -> [bezier to V3] -> V4 -> V5 -> V6 -> V7 -> close
```

### Normalizer Struct (for any rect size)

```swift
private struct PathNormalizer {
    let rect: CGRect

    func point(xPercent: CGFloat, yPercent: CGFloat) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * xPercent,
            y: rect.minY + rect.height * yPercent
        )
    }
}
```

## Implementation Steps

1. **Create IndentedRectShape.swift**
   - Define Shape struct
   - Add `t` parameter with animatableData

2. **Implement path construction**
   - Define vertex points
   - Connect with lines and bezier curves
   - Use normalizer for any rect size

3. **Implement normalized indent depth**
   - Handle appear case (0.7-1.0 -> 0-1)
   - Handle disappear case (0-0.3 -> 1-0)
   - Return 0 for middle range

4. **Add preview**
   - Test with various t values
   - Verify animation smoothness

5. **Build and verify**
   - No compile errors

## Todo List

- [ ] Create `IndentedRectShape.swift`
- [ ] Implement Shape protocol
- [ ] Add animatableData for t
- [ ] Implement path construction
- [ ] Implement normalized indent depth
- [ ] Test with preview
- [ ] Build and verify no errors

## Success Criteria

- [x] IndentedRectShape compiles
- [x] Path draws correctly
- [x] AnimatableData works
- [x] Delayed animation logic correct
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Path construction errors | Debug draw full rectangle first |
| Animation timing feels off | Adjust constants in TabBarAnimation |

## Next Steps

- Proceed to Phase 5: Animated Button
