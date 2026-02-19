# Design Guidelines: Overview

**System:** iOS Human Interface Guidelines compliant
**Accessibility:** WCAG AA
**Version:** 1.0
**Last Updated:** February 2026

---

## Overview

StressMonitor's design emphasizes clarity, accessibility, and user control. All UI work must follow these guidelines to ensure consistency, usability, and WCAG AA compliance.

**Core Principles:**
1. **Dual Coding** - Color + icon + text (WCAG AA)
2. **Simplicity** - One action per screen
3. **Transparency** - Show data sources and computation
4. **Control** - Users own their data
5. **Wellness** - Calming, approachable aesthetic

## Quick Links

### Visual System
Design tokens and components:
- **[Design Guidelines: Visual](./design-guidelines-visual.md)** - Color system, typography, spacing, layout, corner radius, shadows, Stress Ring component, Category Badge, Measurement Card, iconography, dark mode, animations

### User Experience & Accessibility
Interaction design and accessibility standards:
- **[Design Guidelines: UX](./design-guidelines-ux.md)** - WCAG AA compliance, dual coding, VoiceOver, Dynamic Type, touch targets, color contrast, haptic feedback, StressBuddy character, onboarding flow, data visualization, breathing exercises, trends view, error handling, notification strategy, accessibility testing

---

## Design System Quick Reference

### Stress Level Colors

| Level | Hex | Usage |
|-------|-----|-------|
| **Relaxed** | #34C759 | 0-25 stress |
| **Mild** | #007AFF | 25-50 stress |
| **Moderate** | #FFD60A | 50-75 stress |
| **High** | #FF9500 | 75-100 stress |

**Rule:** Always use color + icon + text for dual coding (WCAG AA)

### Typography Scale

| Style | Size | Weight |
|-------|------|--------|
| Display | 32pt | Bold |
| Headline | 24pt | Semibold |
| Body | 16pt | Regular |
| Footnote | 12pt | Regular |

**Rule:** Support Dynamic Type scaling (user's accessibility settings)

### Spacing Scale

| Level | Size | Usage |
|-------|------|-------|
| XS | 4pt | Icon spacing |
| S | 8pt | Adjacent elements |
| M | 16pt | Section spacing |
| L | 24pt | Major sections |
| XL | 32pt | Screen padding |

### Touch Targets
- **Minimum:** 44x44 points
- **Recommended:** 50x50 points
- **Large buttons:** 60x60 points

### Animation Timing

| Type | Duration | Easing |
|------|----------|--------|
| Micro | 200ms | easeOut |
| Standard | 400ms | easeInOut |
| Entrance | 600ms | easeOut |

---

## Component Library

### Primary Components

**Stress Ring** (120-200pt diameter)
- Main measurement display
- Animated progress ring
- Category label + number
- Tap to see details

**Category Badge** (min 44pt height)
- Color + icon + text
- Background highlight
- Used in lists and cards

**Measurement Card** (full width)
- Time + stress level
- Category + confidence
- HRV and HR data
- Tap for details

### Supporting Components

- Buttons (min 44pt)
- Text fields (min 44pt)
- Toggle switches (min 44pt)
- Progress indicators
- Charts and graphs

---

## Accessibility Standards (WCAG AA)

### Mandatory Requirements

- [ ] All interactive elements: 44x44 minimum
- [ ] Text contrast: ≥4.5:1 (WCAG AA)
- [ ] Stress indicators: Dual coding (color + icon + text)
- [ ] All buttons: Accessibility labels
- [ ] Text: Minimum 75% scale factor
- [ ] Focus indicators: Visible for keyboard navigation
- [ ] VoiceOver: Logical top-to-bottom navigation
- [ ] Dynamic Type: Scales to 200% without truncation
- [ ] Color blindness: All info without color alone
- [ ] Haptics: Optional (can be disabled)

### Testing Checklist

Before committing UI code:

```
VoiceOver Testing:
[ ] All labels descriptive and concise
[ ] Navigation logical and efficient
[ ] Hints clear for complex controls
[ ] Rotor works for headings/landmarks

Dynamic Type Testing:
[ ] Smallest (85%) - readable without shrinkage
[ ] Largest (200%) - no overlap or truncation
[ ] Line length - max 60 characters for readability

Color Testing:
[ ] Protanopia (red-green colorblind)
[ ] Deuteranopia (red-green colorblind)
[ ] Tritanopia (blue-yellow colorblind)
[ ] All info visible without color

Manual Testing:
[ ] All buttons 44x44 minimum
[ ] Focus indicators visible
[ ] Keyboard navigation works
```

---

## Dark Mode

All views automatically adapt to dark mode:

```swift
// Xcode → View → Appearance → Dark
.preferredColorScheme(.dark)
```

**Guidelines:**
- Use `Color.primary` and `Color.secondary` (auto-inverted)
- Don't use pure white (#FFF) in dark mode
- Test contrast in both light and dark modes
- Verify animations visible in both modes

---

## Haptic Feedback

Use haptics to confirm user actions:

```swift
// Light tap - confirmation
HapticManager.shared.buttonPressed()

// Success - positive feedback
HapticManager.shared.stressLevelChanged(to: .relaxed)

// Warning - alert user
HapticManager.shared.warning()
```

**Rules:**
- Use consistently for same action
- Make optional (can be disabled in settings)
- Avoid overuse (max 1-2 per screen)

---

## StressBuddy Character

Animated character provides encouragement based on stress level:

| Stress | Expression | Message |
|--------|-----------|---------|
| Relaxed | 😊 | "You're doing great!" |
| Mild | 😐 | "Stay calm and breathe" |
| Moderate | 😟 | "Take a moment to relax" |
| High | 😰 | "Try a breathing exercise" |

---

## Data Visualization

### Trend Chart
- 7-day rolling average
- Color-coded by stress category
- Tap to see daily details
- Swipe to change timeframe

### Export Options
- CSV (spreadsheet-compatible)
- JSON (API-compatible)
- PDF (printable report)

---

## Layout Breakpoints

### iPhone Sizes
- **Compact:** iPhone SE, 8, 13 mini (reduce padding)
- **Standard:** Most iPhones (standard padding)
- **Large:** Max pro models (can use more space)

### Apple Watch Sizes
- **40mm:** 2 data points per screen, large touch targets
- **45mm:** 3 data points per screen, standard targets

---

## File Organization

All UI files follow this structure:

```
Views/
├── Dashboard/
│   ├── DashboardView.swift
│   ├── StressRingView.swift
│   └── MeasurementCardView.swift
├── History/
│   ├── HistoryView.swift
│   └── MeasurementDetailView.swift
├── Components/
│   ├── StressCategoryBadgeView.swift
│   ├── StressBuddyView.swift
│   └── BreathingGuidanceView.swift
└── Shared/
    ├── LoadingView.swift
    └── ErrorAlertView.swift
```

---

## Before Submitting UI Code

1. **Visual Review**
   - [ ] Follows color system
   - [ ] Uses correct typography
   - [ ] Proper spacing and alignment
   - [ ] Dark mode verified
   - [ ] All animations smooth

2. **Accessibility Review**
   - [ ] All labels present
   - [ ] Minimum touch targets (44x44)
   - [ ] Contrast ≥4.5:1
   - [ ] Dual coding for stress indicators
   - [ ] VoiceOver tested

3. **Interaction Review**
   - [ ] Haptic feedback appropriate
   - [ ] Loading states shown
   - [ ] Error messages clear
   - [ ] Edge cases handled
   - [ ] No orphaned elements

4. **Device Testing**
   - [ ] Tested on iPhone 15
   - [ ] Tested on iPhone SE
   - [ ] Tested on Apple Watch
   - [ ] Landscape orientation (if applicable)
   - [ ] Light and dark modes

---

**Enforced By:** Code review & QA testing
**Last Updated:** February 2026
