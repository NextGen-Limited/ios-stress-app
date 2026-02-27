# Phase 3: Decorative Elements

## Overview
Add decorative elements from Figma design (triangle shape with shadow).

**Priority:** Low
**Status:** Pending
**Estimated Effort:** 30 minutes

---

## Requirements

### Decorative Triangle (from Figma)
- **Position:** x: 324, y: 225 (top-right area)
- **Size:** 37.11 × 34.5 px
- **Color:** `#363636`
- **Opacity:** 80%
- **Border Radius:** 2.2px
- **Shadow:** Multi-layered box shadow (same as card shadow)

---

## Implementation Steps

### Step 1: Create DecorativeTriangleView

```swift
// Location: StressMonitor/Components/Character/DecorativeTriangleView.swift

import SwiftUI

struct DecorativeTriangleView: View {
    var body: some View {
        // Use Polygon or custom Shape
        Polygon(count: 3)
            .fill(Color(hex: "#363636"))
            .opacity(0.8)
            .frame(width: 37, height: 34.5)
            .shadow(color: .black.opacity(0.1), radius: 2.2, x: 0, y: 2.2)
            .shadow(color: .black.opacity(0.09), radius: 9.9, x: 0, y: 9.9)
            // Additional shadow layers...
    }
}
```

### Step 2: Add to StressCharacterCard

Position in ZStack or overlay:
```swift
ZStack {
    // Existing content...

    DecorativeTriangleView()
        .position(x: geometry.size.width - 66, y: 242)
}
```

### Step 3: Consider Mood-Based Variations

Optional: Change decoration based on mood:
- Relaxed: Triangle (as in Figma)
- Concerned: Circle or diamond
- Worried: Different position
- Overwhelmed: Multiple elements

---

## Todo List

- [ ] Create `DecorativeTriangleView.swift`
- [ ] Add polygon shape with correct dimensions
- [ ] Apply shadow effects
- [ ] Add to `StressCharacterCard` with correct positioning
- [ ] Test in Light/Dark mode

---

## Success Criteria

1. Decorative triangle matches Figma position and size
2. Shadow effects render correctly
3. Doesn't interfere with character or text
4. Dark mode looks correct

---

## Related Files

- `StressMonitor/Components/Character/DecorativeTriangleView.swift` (new)
- `StressMonitor/Components/Character/StressCharacterCard.swift` (modify)

---

## Notes

This is a **nice-to-have** enhancement. If time is limited, this phase can be skipped or deferred.
