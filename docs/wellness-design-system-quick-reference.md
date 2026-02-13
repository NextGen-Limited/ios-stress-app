# Wellness Design System - Quick Reference

**For:** StressMonitor iOS App Developers
**Updated:** 2026-02-13
**Version:** 2.0

---

## Colors

### Wellness Palette

```swift
import SwiftUI

// Primary colors (adaptive light/dark)
Color.Wellness.calmBlue      // Healthcare trust
Color.Wellness.healthGreen   // Wellness/growth
Color.Wellness.gentlePurple  // Mindfulness

// Backgrounds
Color.Wellness.background    // OLED black in dark mode
Color.Wellness.surface       // Card surface
```

### Stress Category Colors

```swift
// Automatic light/dark adaptation
Color.stressColor(for: .relaxed)   // Green
Color.stressColor(for: .mild)       // Blue
Color.stressColor(for: .moderate)   // Yellow
Color.stressColor(for: .high)       // Orange/Red

// High contrast mode (WCAG AAA)
Color.accessibleStressColor(for: .relaxed, highContrast: true)
```

### Dual Coding (Accessibility)

```swift
let category: StressCategory = .mild

// Icon (SF Symbol)
category.icon  // "circle.fill"

// Pattern description
category.pattern  // "diagonal lines"

// VoiceOver description
category.accessibilityDescription
// "Mild stress level, represented by circle.fill icon with diagonal lines"
```

---

## Typography

### Custom Fonts (Lora + Raleway)

```swift
// Headings (Lora serif - organic wellness vibe)
Font.WellnessType.heroNumber     // 72pt Bold
Font.WellnessType.largeMetric    // 48pt Bold
Font.WellnessType.cardTitle      // 28pt Bold
Font.WellnessType.sectionHeader  // 22pt SemiBold

// Body (Raleway sans - elegant simplicity)
Font.WellnessType.body           // 17pt Regular
Font.WellnessType.bodyEmphasized // 17pt SemiBold
Font.WellnessType.caption        // 13pt Regular
Font.WellnessType.caption2       // 11pt Regular
```

**Note:** Automatically falls back to SF Pro if fonts not loaded.

### Dynamic Type Support

```swift
// Multi-line text with scaling
Text("Long description")
    .font(.WellnessType.body)
    .accessibleWellnessType()

// Single-line (buttons, labels)
Text("Measure")
    .accessibleWellnessTypeSingleLine()

// Limited lines
Text("Details")
    .accessibleWellnessType(lines: 3)
```

---

## Gradients

### Background Gradients

```swift
// Calm wellness gradient
VStack {
    // Content
}
.wellnessBackground()

// Mindfulness (purple to blue)
VStack { }
    .background(LinearGradient.mindfulness)

// Relaxation (green)
VStack { }
    .background(LinearGradient.relaxation)
```

### Stress Gradients

```swift
// Chart fill
LinearGradient.stressSpectrum(for: .mild)
// 60% → 30% → 10% opacity

// Card background tint
Card { }
    .stressCard(for: .moderate, baseColor: Color.Wellness.surface)

// Manual tint
VStack { }
    .stressBackground(for: .high)
```

---

## Common Patterns

### Stress Indicator with Dual Coding

```swift
HStack {
    // Icon
    Image(systemName: category.icon)
        .accessibleStressColor(for: category)

    // Text
    Text(category.displayName)
        .accessibleStressColor(for: category)
}
.accessibilityLabel(category.accessibilityDescription)
```

### Card with Wellness Background

```swift
VStack {
    Text("Card Content")
        .font(.WellnessType.cardTitle)
}
.padding()
.background(Color.Wellness.surface)
.cornerRadius(12)
.wellnessBackground()
```

### Stress Ring with Accessible Colors

```swift
Circle()
    .trim(from: 0, to: progress)
    .stroke(
        Color.accessibleStressColor(for: category),
        style: StrokeStyle(lineWidth: 12, lineCap: .round)
    )
    .accessibilityLabel(category.accessibilityValue(level: stressLevel))
```

### Hero Metric Display

```swift
VStack(spacing: 4) {
    Text("\(Int(stressLevel))")
        .font(.WellnessType.heroNumber)
        .monospacedDigit()
        .accessibleStressColor(for: category)
        .accessibleWellnessType()

    Text("Stress Level")
        .font(.WellnessType.caption)
        .foregroundStyle(.secondary)
}
```

---

## Accessibility Checklist

### Every Interactive Element Needs:

```swift
Button("Measure") {
    measureStress()
}
.accessibilityLabel("Measure stress level")
.accessibilityHint("Fetches HRV and calculates stress")
```

### Stress Visualizations Need:

```swift
StressRingView(category: .mild)
    .accessibilityLabel(category.accessibilityDescription)
    .accessibilityValue("\(Int(stressLevel)) out of 100")
    .accessibilityHint("Current stress level indicator")
```

### Color Must Not Be Sole Indicator:

```swift
// ✅ GOOD - Color + Icon + Text
HStack {
    Image(systemName: category.icon)
    Text(category.displayName)
}
.accessibleStressColor(for: category)

// ❌ BAD - Color only
Circle()
    .fill(Color.stressColor(for: category))
```

---

## Dark Mode

All colors automatically adapt:

```swift
// Light mode: #0891B2, Dark mode: #22D3EE
Color.Wellness.calmBlue

// Light mode: #F2F2F7, Dark mode: #000000 (OLED black)
Color.Wellness.background

// Stress colors have light/dark variants
Color.stressColor(for: .relaxed)
// Light: #34C759, Dark: #30D158
```

---

## High Contrast Mode

Automatically uses darker colors for WCAG AAA compliance:

```swift
// Automatically detects system setting
Text("Stress")
    .accessibleStressColor(for: .relaxed)
// Standard: #34C759, High Contrast: #00A000
```

---

## Font Status Debugging

Check if custom fonts loaded:

```swift
// In development builds
WellnessFontLoader.printFontStatus()
// Console output:
// ✓ All wellness fonts loaded successfully
// OR
// ⚠️ Using SF Pro system fonts as fallback
```

---

## Migration from Old System

### Colors

```swift
// Old
.foregroundColor(.green)

// New
.foregroundStyle(Color.stressColor(for: .relaxed))
// OR
.accessibleStressColor(for: .relaxed)
```

### Typography

```swift
// Old
.font(.system(size: 28, weight: .bold))

// New
.font(.WellnessType.cardTitle)
.accessibleWellnessType()
```

### Backgrounds

```swift
// Old
.background(Color(.systemBackground))

// New
.background(Color.Wellness.background)
// OR
.wellnessBackground()
```

---

## File Locations

```
StressMonitor/StressMonitor/
├── Theme/
│   ├── Color+Wellness.swift      // Wellness colors
│   ├── Gradients.swift            // Gradient utilities
│   └── Font+WellnessType.swift   // Custom fonts
├── Models/
│   └── StressCategory.swift       // Enhanced with dual coding
└── Fonts/
    └── README.md                  // Font installation guide
```

---

## Resources

- **Design Guidelines:** `./docs/design-guidelines.md`
- **Implementation Report:** `./docs/implementation-phase-1-visual-foundation.md`
- **Font Installation:** `./StressMonitor/StressMonitor/Fonts/README.md`
- **UI/UX Specs:** `./documentation/references/ui-ux-design-system.md`

---

**Quick Start:**

1. Import SwiftUI
2. Use `Color.Wellness.*` for wellness colors
3. Use `Font.WellnessType.*` for typography
4. Always add `.accessibleWellnessType()` to text
5. Use dual coding (color + icon + text) for stress indicators
6. Test with VoiceOver and high contrast mode

**Questions?** See full implementation report or design guidelines.
