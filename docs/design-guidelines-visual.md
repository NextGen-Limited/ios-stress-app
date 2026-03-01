# Design Guidelines: Visual System

**System:** iOS Human Interface Guidelines compliant
**Accessibility:** WCAG AA
**Section:** Colors, typography, spacing, components
**Version:** 1.0
**Last Updated:** February 2026

---

## Design Philosophy

StressMonitor emphasizes **clarity, accessibility, and user control**. The interface guides users toward understanding their stress patterns without overwhelming them with data.

**Core Principles:**
1. **Dual Coding** - Color + icon + text (WCAG AA)
2. **Simplicity** - One action per screen
3. **Transparency** - Show data sources and computation
4. **Control** - Users own their data
5. **Wellness** - Calming, approachable aesthetic

---

## Color System

### Stress Level Colors

| Level | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Relaxed** | #34C759 | (52, 199, 89) | 0-25 stress |
| **Mild** | #007AFF | (0, 122, 255) | 25-50 stress |
| **Moderate** | #FFD60A | (255, 214, 10) | 50-75 stress |
| **High** | #FF9500 | (255, 149, 0) | 75-100 stress |

**Implementation:**
```swift
extension Color {
  static func stressColor(for category: StressCategory) -> Color {
    switch category {
    case .relaxed:    return Color(red: 0.20, green: 0.78, blue: 0.35)
    case .mild:       return Color(red: 0.00, green: 0.48, blue: 1.00)
    case .moderate:   return Color(red: 1.00, green: 0.84, blue: 0.04)
    case .high:       return Color(red: 1.00, green: 0.58, blue: 0.00)
    }
  }
}
```

### Supporting Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Background** | #FFFFFF / #000000 | Light/dark mode |
| **Secondary** | #F2F2F7 | Card backgrounds |
| **Text Primary** | #000000 / #FFFFFF | Main text |
| **Text Secondary** | #666666 / #999999 | Metadata |
| **Border** | #E0E0E0 / #333333 | Dividers |

---

## Typography

### Font Families

**System Font (Default):**
- San Francisco (`.system`)
- Automatically switches for accessibility

**Monospace (for data):**
- Menlo or Courier (`.monospaced`)
- Used in export/detail screens

### Type Scale

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| **Display** | 32pt | Bold | Screen titles |
| **Headline** | 24pt | Semibold | Section headers |
| **Body** | 16pt | Regular | Body text |
| **Subheading** | 14pt | Semibold | Subsection headers |
| **Footnote** | 12pt | Regular | Metadata, timestamps |
| **Caption** | 10pt | Regular | Fine print |

**Implementation:**
```swift
extension Font {
  static let displayLarge = Font.system(size: 32, weight: .bold)
  static let headlineMedium = Font.system(size: 24, weight: .semibold)
  static let bodyRegular = Font.system(size: 16, weight: .regular)
  static let footnoteSmall = Font.system(size: 12, weight: .regular)
}
```

### Dynamic Type

All text must support Dynamic Type scaling (user's accessibility settings):

```swift
Text("Stress Level")
  .font(.headline)
  .dynamicTypeSize(...(.accessibility3))  // iOS 15+ range

// For more control
Text("Stress Level")
  .font(.headline)
  .minimumScaleFactor(0.75)  // Don't shrink below 75%
  .lineLimit(nil)            // Allow wrapping
```

---

## Spacing & Layout

### Spacing Scale

| Level | Points | Usage |
|-------|--------|-------|
| **XS** | 4pt | Icon spacing |
| **S** | 8pt | Adjacent elements |
| **M** | 16pt | Section spacing |
| **L** | 24pt | Major sections |
| **XL** | 32pt | Screen padding |

**Implementation:**
```swift
struct DesignTokens {
  static let spacing_xs: CGFloat = 4
  static let spacing_s: CGFloat = 8
  static let spacing_m: CGFloat = 16
  static let spacing_l: CGFloat = 24
  static let spacing_xl: CGFloat = 32
}

// Usage
VStack(spacing: DesignTokens.spacing_m) {
  stressRing
  statsSection
}
.padding(DesignTokens.spacing_xl)
```

### Corner Radius

| Radius | Usage |
|--------|-------|
| **0pt** | Edges, dividers |
| **8pt** | Small cards, buttons |
| **12pt** | Medium cards, input fields |
| **16pt** | Large cards, modals |
| **20pt** | Settings cards, widgets (NEW Mar 2026) |
| **24pt** | Stress ring, avatar |

### Shadows

**Subtle Shadow** (cards, buttons):
```swift
.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
```

**Medium Shadow** (popovers):
```swift
.shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
```

**Elevated Shadow** (modals):
```swift
.shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
```

**Settings Card Shadow** (NEW Mar 2026):
```swift
// Per Figma spec for Settings screen
.shadow(color: Color.settingsCardShadowColor.opacity(0.08),
        radius: 5.71, x: 0, y: 2.85)
```

---

## Components

### Stress Ring (Primary CTA)

**Size:** 120pt diameter (default) → 200pt (large)

**Anatomy:**
```
┌─────────────────────┐
│    Stress Level     │  ← Text overlay
│        45           │  ← Large number
│    Mild Stress      │  ← Category label
│      ◯◯◯◯◯◯◯       │  ← Progress ring
└─────────────────────┘
```

**Implementation:**
```swift
struct StressRingView: View {
  let stressLevel: Double
  let category: StressCategory

  var body: some View {
    ZStack {
      // Background circle
      Circle()
        .stroke(Color.secondary.opacity(0.2), lineWidth: 8)

      // Progress ring
      Circle()
        .trim(from: 0, to: stressLevel / 100)
        .stroke(Color.stressColor(for: category), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeInOut(duration: 0.6), value: stressLevel)

      // Center text
      VStack(spacing: 4) {
        Text(String(format: "%.0f", stressLevel))
          .font(.system(size: 48, weight: .bold))
          .foregroundColor(Color.stressColor(for: category))
        Text(category.label)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .frame(width: 200, height: 200)
  }
}
```

### Category Badge

**Size:** Flexible, min 44pt height

**Anatomy:**
```
🟢 Relaxed
```

**Implementation:**
```swift
struct StressCategoryBadgeView: View {
  let category: StressCategory

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: category.iconName)
        .foregroundColor(Color.stressColor(for: category))
      Text(category.label)
        .font(.headline)
      Spacer()
    }
    .padding()
    .background(Color.stressColor(for: category).opacity(0.1))
    .cornerRadius(12)
  }
}
```

### Measurement Card

**Anatomy:**
```
┌──────────────────────────────┐
│ 45                   2:30 PM │
│ Mild Stress                  │
│ Confidence: 95%              │
│ HRV: 52ms | HR: 72 bpm       │
└──────────────────────────────┘
```

**Implementation:**
```swift
struct MeasurementCardView: View {
  let measurement: StressMeasurement

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(String(format: "%.0f", measurement.stressLevel))
          .font(.system(size: 32, weight: .bold))
        Spacer()
        Text(measurement.timestamp.formatted(date: .omitted, time: .shortened))
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      Text(measurement.category.label)
        .font(.subheading)
        .foregroundColor(Color.stressColor(for: measurement.category))
      HStack(spacing: 16) {
        Label("Confidence: \(Int(measurement.confidence * 100))%", systemImage: "checkmark.circle")
        Spacer()
      }
      .font(.footnote)
    }
    .padding()
    .background(Color.secondary.opacity(0.05))
    .cornerRadius(12)
  }
}
```

---

## Animations

### Timing

| Animation | Duration | Easing |
|-----------|----------|--------|
| **Micro** | 200ms | easeOut |
| **Standard** | 400ms | easeInOut |
| **Entrance** | 600ms | easeOut |
| **Transition** | 300ms | linear |

### Spring Animations (iOS 17+)

Use the new spring API with parameters:

```swift
// iOS 17+ spring animation
.animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: stressLevel)

// Or using Animation initializer
Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)
```

### Stress Ring Animation

Animates from 0 to current stress level on load:

```swift
// iOS 17+ recommended approach
@State private var animatedLevel: Double = 0

var body: some View {
  Circle()
    .trim(from: 0, to: animatedLevel / 100)
    .stroke(stressColor, lineWidth: 8)
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedLevel)
    .onAppear { animatedLevel = stressLevel }
}
```

### List Item Animation

Stagger animation for list items:

```swift
ForEach(measurements) { measurement in
  MeasurementCardView(measurement)
    .transition(.opacity.combined(with: .move(edge: .top)))
}
.animation(.easeInOut(duration: 0.3), value: measurements)
```

---

## Dark Mode Support

All views automatically adapt to dark mode. Test with:

```swift
// Xcode → View → Appearance → Dark
// Or programmatically
.preferredColorScheme(.dark)
```

**Guidelines:**
- Don't use pure white (#FFF) in dark mode
- Use Color.primary and Color.secondary (automatically inverted)
- Test contrast in both modes

---

## Layout Breakpoints

### iPhone

**Compact Height** (SE, 8, 13 mini):
- Reduce padding: 16pt → 12pt
- Single column layouts

**Regular Height** (standard):
- Standard padding: 16pt
- Single column, multi-section

### Apple Watch

**Small Screen** (40mm):
- Minimum 2 data points per screen
- Large touch targets (≥48pt)
- Horizontal scrolling for details

**Large Screen** (45mm):
- Can show more information
- 3 data points per screen
- Vertical scrolling preferred

---

## Iconography

Use **SF Symbols** exclusively for consistency:

| Icon | Symbol | Usage |
|------|--------|-------|
| Measure | `waveform.circle.fill` | Primary action |
| History | `list.bullet` | Timeline |
| Trends | `chart.line.uptrend.xyaxis` | Analytics |
| Breathing | `lungs.fill` | Exercises |
| Settings | `gearshape.fill` | Configuration |
| Health | `heart.fill` | HealthKit |
| Cloud | `icloud.fill` | CloudKit |
| Success | `checkmark.circle.fill` | Confirmation |
| Error | `exclamationmark.circle.fill` | Problems |

**Size Scale:**
- Icons: 16pt-24pt (most common)
- Large icons: 32pt-48pt (hero elements)
- Tiny icons: 12pt (inline labels)

---

## Performance Animation Targets

- **Animation frame rate:** 60 FPS (120 FPS preferred)
- **Duration:** 300-600ms for standard animations
- **Easing:** Prefer easeInOut or easeOut

Test with Xcode's Core Animation tool:
```
Xcode → Debug → View Debugging → Core Animation
```

---

**Next:** See `design-guidelines-ux.md` for accessibility, haptics, animations, and StressBuddy character.
**Design System Version:** 1.1
**Last Updated:** March 1, 2026
**Maintained By:** Phuong Doan
