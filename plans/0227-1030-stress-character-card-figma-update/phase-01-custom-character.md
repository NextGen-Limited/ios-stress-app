# Phase 1: Custom Character View

## Overview
Replace SF Symbol-based character with custom SwiftUI illustration matching Figma design.

**Priority:** High
**Status:** Completed
**Estimated Effort:** 2-3 hours

---

## Requirements

### Functional
- Display mood-specific character illustration
- Support 5 mood states: sleeping, calm, concerned, worried, overwhelmed
- Animate character based on mood (breathing, fidgeting, etc.)
- Respect Reduce Motion accessibility setting

### Non-Functional
- 126×126px for dashboard context
- Smooth animations at 60fps
- Support Dark Mode

---

## Design Specifications

### Character Structure (from Figma)
The character consists of:
1. **Body** - Rounded ellipse with fill `#D9D9D9` (light gray)
2. **Face** - Eyes, nose, mouth with different expressions per mood
3. **Limbs** - Small rounded arms and legs
4. **Mood-specific elements**:
   - Sleeping: Closed eyes, zzz bubbles
   - Calm: Relaxed face, slight smile
   - Concerned: Raised eyebrow, worried expression
   - Worried: Sweat drop, concerned face
   - Overwhelmed: Distressed expression, flames/sweat

### Color Values (from Figma)
| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Body | `#D9D9D9` | `#4A4A4A` |
| Skin tones | `#EAD2CC` | `#B8A39E` |
| Features | `#363636` | `#C4C4C4` |
| Cheeks | `#FF9191` | `#CC7474` |

---

## Implementation Steps

### Step 1: Create StressBuddyIllustration.swift

```swift
// Location: StressMonitor/Components/Character/StressBuddyIllustration.swift

import SwiftUI

struct StressBuddyIllustration: View {
    let mood: StressBuddyMood
    let size: CGFloat

    var body: some View {
        ZStack {
            // Body
            bodyView

            // Face (eyes, nose, mouth)
            faceView

            // Mood-specific accessories
            accessoriesView
        }
        .frame(width: size, height: size)
    }

    // MARK: - Body
    @ViewBuilder
    private var bodyView: some View {
        // Main body ellipse
        Ellipse()
            .fill(bodyColor)
            .frame(width: size * 0.7, height: size * 0.85)

        // Arms
        // Legs
        // etc.
    }

    // MARK: - Face
    @ViewBuilder
    private var faceView: some View {
        switch mood {
        case .sleeping:
            SleepingFace()
        case .calm:
            CalmFace()
        case .concerned:
            ConcernedFace()
        case .worried:
            WorriedFace()
        case .overwhelmed:
            OverwhelmedFace()
        }
    }
}
```

### Step 2: Create Face Components

Create separate view builders for each mood's facial expression:
- `SleepingFace` - Closed curved lines for eyes, peaceful mouth
- `CalmFace` - Normal eyes with slight smile
- `ConcernedFace` - Raised eyebrows, worried mouth
- `WorriedFace` - Wide eyes, concerned expression
- `OverwhelmedFace` - Distressed eyes, open mouth

### Step 3: Update StressCharacterCard

Replace:
```swift
Image(systemName: mood.symbol)
    .font(.system(size: mood.symbolSize(for: size)))
```

With:
```swift
StressBuddyIllustration(mood: mood, size: 126)
```

### Step 4: Update StressBuddyMood

Remove or deprecate SF Symbol-related properties:
- `symbol` - Keep for fallback/accessibility
- `accessories` - Update for new illustration system

---

## Todo List

- [x] Create `StressBuddyIllustration.swift` with basic structure
- [x] Implement body shape with arms and legs
- [x] Create `SleepingFace` component
- [x] Create `CalmFace` component
- [x] Create `ConcernedFace` component
- [x] Create `WorriedFace` component
- [x] Create `OverwhelmedFace` component
- [x] Add mood-specific accessories (zzz, sweat drops, etc.)
- [x] Update `StressCharacterCard` to use new illustration
- [x] Add Dark Mode color variants
- [x] Test animations with new illustration

---

## Success Criteria

1. Character visually matches Figma design
2. All 5 mood states display correctly
3. Animations work with new illustration
4. Dark mode renders correctly
5. Existing tests pass (may need updates)

---

## Related Files

- `StressMonitor/Components/Character/StressBuddyIllustration.swift` (new)
- `StressMonitor/Components/Character/StressCharacterCard.swift` (modify)
- `StressMonitor/Models/StressBuddyMood.swift` (modify)
