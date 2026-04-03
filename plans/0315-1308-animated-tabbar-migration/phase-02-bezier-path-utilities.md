# Phase 2: Bezier Path Utilities

**Priority:** P1
**Status:** Pending
**Estimated Time:** 45m

## Overview

Create utility functions for calculating bezier path lengths and getting point coordinates at specific percent values along the path. Required for smooth ball animation.

## Requirements

### Functional
- Calculate total length of cubic bezier path
- Get point coordinates at any percent (0-1) along path
- Handle edge cases (start, end points)

### Non-Functional
- Efficient calculations (avoid recalculating path length)
- Clean Swift code with proper documentation

## Key Insights from Exyte Tutorial

1. Need to approximate bezier curve length numerically
2. Use interpolation to find point at specific percent
3. Reference implementation exists (BezierPathLength in Exyte sources)

## Related Code Files

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/Effects/BezierPathLength.swift`

### Reference
- Phase 1 files (for integration understanding)

## Architecture

### BezierPathLength.swift

```swift
// Bezier path utility for calculating length and points
struct BezierPathLength {
    let path: Path

    // Pre-calculated segments for interpolation
    private let segments: [Segment]

    // Total path length
    let totalLength: CGFloat

    init(path: Path, precision: Int = 100)

    // Get point at percent (0-1) along path
    func point(at percent: CGFloat) -> CGPoint

    // Get tangent at percent (for rotation if needed)
    func tangent(at percent: CGFloat) -> CGPoint
}

private struct Segment {
    let length: CGFloat
    let point: CGPoint
    let cumulativeLength: CGFloat
}
```

### Algorithm

1. **Path Length Calculation**
   - Sample points along path at regular intervals
   - Calculate distance between consecutive points
   - Sum for total length
   - Store cumulative lengths for interpolation

2. **Point at Percent**
   - Convert percent to target distance
   - Binary search segments for closest match
   - Interpolate between segment points

## Implementation Steps

1. **Create Effects directory**
   - Create `Effects/` subdirectory if not exists

2. **Create Segment struct**
   - Private helper for storing path data
   - Store point, length, cumulative length

3. **Implement BezierPathLength**
   - Initialize with path and precision
   - Calculate segments during init
   - Implement `point(at:)` method
   - Add optional `tangent(at:)` method

4. **Add unit tests (optional)**
   - Test with simple paths
   - Verify start/end points
   - Verify midpoint accuracy

5. **Build and verify**
   - No compile errors

## Todo List

- [ ] Create `Effects/` directory
- [ ] Create `BezierPathLength.swift`
- [ ] Implement `Segment` struct
- [ ] Implement path length calculation
- [ ] Implement `point(at:)` method
- [ ] Implement `tangent(at:)` method (optional)
- [ ] Build and verify no errors

## Success Criteria

- [x] BezierPathLength struct compiles
- [x] Can calculate path length
- [x] Can get point at any percent
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Numerical precision issues | Use CGFloat, test with debug output |
| Performance on complex paths | Pre-calculate in init, use reasonable precision |

## Next Steps

- Proceed to Phase 3: Ball Animation
