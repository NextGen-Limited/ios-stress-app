# Phase 1: Design Tokens & Colors

<!-- Updated: Validation Session 1 - Added dark mode color variants -->

## Overview
Add Figma-derived design tokens to the existing design system with dark mode support.

## Requirements

### Colors to Add

```swift
// In Color+Extensions.swift

// MARK: - Settings Screen Colors
static let settingsBackground = Color(hex: "F3F4F8")
static let accentTeal = Color(hex: "85C9C9")
static let premiumGold = Color(hex: "FE9901")
static let textTertiary = Color(hex: "808080")
static let textDescriptive = Color(hex: "848484")
static let borderLight = Color(hex: "DBDBDB")
static let widgetBorder = Color(hex: "C0C0C0")

// MARK: - Settings Screen Colors (Dark Mode)
static let settingsBackgroundDark = Color(hex: "1C1C1E")  // System background dark
static let cardBackgroundDark = Color(hex: "2C2C2E")      // Elevated surface
static let accentTealDark = Color(hex: "6DB3B3")          // Slightly brighter for dark
```

### Semantic Color Helpers

```swift
// Add computed properties for automatic light/dark adaptation

extension Color {
    static var adaptiveSettingsBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "1C1C1E")
                : UIColor(hex: "F3F4F8")
        })
    }

    static var adaptiveCardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "2C2C2E")
                : UIColor.white
        })
    }
}
```

### Shadow Configuration

```swift
// In Shadows.swift or new SettingsShadows.swift

struct SettingsShadow {
    static let card = ShadowStyle(
        color: Color(hex: "18274B").opacity(0.08),
        radius: 5.71,
        x: 0,
        y: 2.85
    )
}
```

### Spacing Additions

```swift
// In Spacing.swift

// MARK: - Settings Card Spacing
static let settingsCardPadding: CGFloat = 20
static let settingsCardSpacing: CGFloat = 14
static let settingsCardRadius: CGFloat = 20
static let widgetRadius: CGFloat = 20
static let buttonRadius: CGFloat = 20
```

## Implementation Steps

- [x] 1. Open `Color+Extensions.swift`
- [x] 2. Add `// MARK: - Settings Screen Colors` section
- [x] 3. Add all 7 new color static properties
- [x] 4. Open `Spacing.swift`
- [x] 5. Add settings-specific spacing constants
- [x] 6. Build to verify no errors

## Status: ✅ Complete

## Files to Modify

| File | Changes |
|------|---------|
| `Theme/Color+Extensions.swift` | Add 7 new colors |
| `Views/DesignSystem/Spacing.swift` | Add 5 new spacing constants |

## Validation
- [x] Colors appear in autocomplete
- [x] Build succeeds
- [x] No Swift warnings
