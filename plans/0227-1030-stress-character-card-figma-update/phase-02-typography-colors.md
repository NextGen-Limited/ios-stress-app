# Phase 2: Typography & Colors

## Overview
Update typography to use Lato font and verify color accuracy against Figma design.

**Priority:** Medium
**Status:** Pending
**Estimated Effort:** 1 hour

---

## Requirements

### Typography (Figma)
| Element | Font | Size | Weight | Letter Spacing |
|---------|------|------|--------|----------------|
| Day name | Lato | 28px | Bold (700) | -1.5% |
| Full date | Lato | 14px | Bold (700) | -1.5% |
| Status label | Lato | 26px | Bold (700) | -1.5% |
| Timestamp | Lato | 13px | Bold (700) | -1.5% |

### Colors (Figma)
| Element | Light Mode | Usage |
|---------|------------|-------|
| Primary text | `#101223` | Day, date |
| Status (Relaxed) | `#86CECD` | "Relaxed" label |
| Secondary text | `#777986` | Timestamp |
| Icon gray | `#717171` | Settings icon |

---

## Implementation Steps

### Step 1: Add Lato Font (Optional)

If using custom font:
1. Add `Lato-Bold.ttf` to project
2. Register in Info.plist under `UIAppFonts`
3. Create font extension

```swift
extension Font {
    static func lato(size: CGFloat) -> Font {
        .custom("Lato-Bold", size: size)
    }
}
```

**Alternative:** Use system font with similar weight:
```swift
// System font alternative (no external dependency)
.font(.system(size: 28, weight: .bold, design: .rounded))
```

### Step 2: Update DateHeaderView

```swift
Text(dayName)
    .font(.system(size: 28, weight: .bold)) // or .lato(size: 28)
    .foregroundStyle(Color(hex: "#101223"))

Text(fullDate)
    .font(.system(size: 14, weight: .bold))
    .foregroundStyle(Color(hex: "#101223"))
```

### Step 3: Update StressCharacterCard

```swift
// Status label
Text(mood.displayName)
    .font(.system(size: 26, weight: .bold))
    .foregroundStyle(moodColor)

// Timestamp
Text("Last Updated: \(lastUpdated, style: .relative)")
    .font(.system(size: 13, weight: .bold))
    .foregroundStyle(Color(hex: "#777986"))
```

### Step 4: Add Color Extensions

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### Step 5: Update Color.Wellness Extensions

Verify existing colors match Figma or add new ones:
```swift
extension Color.Wellness {
    // Figma-specified colors
    static let figmaPrimaryText = Color(hex: "#101223")
    static let figmaSecondaryText = Color(hex: "#777986")
    static let figmaRelaxedTeal = Color(hex: "#86CECD") // Matches existing exerciseCyan
    static let figmaIconGray = Color(hex: "#717171")
}
```

---

## Todo List

- [ ] Decide: Lato font vs system font
- [ ] If Lato: Add font files and register
- [ ] Update `DateHeaderView` typography
- [ ] Update `StressCharacterCard` typography
- [ ] Add `Color(hex:)` extension if not present
- [ ] Verify color values match Figma
- [ ] Test Dark Mode color variants

---

## Success Criteria

1. Typography matches Figma specifications
2. Colors match Figma hex values
3. Dark mode works correctly
4. Dynamic Type support maintained

---

## Related Files

- `StressMonitor/Views/Dashboard/Components/DateHeaderView.swift`
- `StressMonitor/Components/Character/StressCharacterCard.swift`
- `StressMonitor/Extensions/Color+Extensions.swift` (if needed)
