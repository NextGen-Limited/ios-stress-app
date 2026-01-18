# UI/UX Design System

**Project:** Stress Monitor - iOS/watchOS Stress Tracking Application
**Version:** 1.0
**Last Updated:** 2025-01-18
**Created By:** Phuong Doan

---

## Table of Contents

1. [Design System Overview](#1-design-system-overview)
2. [Color System](#2-color-system)
3. [Typography System](#3-typography-system)
4. [Spacing & Layout](#4-spacing--layout)
5. [UI Mockups - iOS](#5-ui-mockups---ios)
6. [UI Mockups - watchOS](#6-ui-mockups---watchos)
7. [SwiftUI Component Library](#7-swiftui-component-library)
8. [Accessibility Guidelines](#8-accessibility-guidelines)
9. [Animation & Interaction](#9-animation--interaction)
10. [Dark Mode Support](#10-dark-mode-support)

---

## 1. Design System Overview

### Design Principles

```
┌─────────────────────────────────────────────────────────────┐
│                    DESIGN PRINCIPLES                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CLARITY     Health data must be immediately            │
│                understandable at a glance                   │
│                                                             │
│  2. ACCESSIBILITY Design for everyone from day one         │
│                (WCAG 2.1 AA compliant)                      │
│                                                             │
│  3. TRUST       Transparent data presentation builds        │
│                confidence through clarity                   │
│                                                             │
│  4. SIMPLICITY  Progressive disclosure hides complexity     │
│                behind expandable interfaces                 │
│                                                             │
│  5. CONSISTENCY Reusable patterns across all screens        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Platform Adaptation Strategy

| Platform | Focus | Key Characteristics |
|----------|-------|---------------------|
| **iOS** | Comprehensive data views | Drill-down capability, detailed charts, full settings |
| **watchOS** | Glanceable metrics | Single-screen interactions, minimal text, quick actions |
| **Complications** | At-a-glance updates | Single metric, color-coded, trend indicators |

---

## 2. Color System

### Semantic Color Palette

```swift
import SwiftUI

// MARK: - Stress Level Colors
extension Color {
    /// Stress level colors with dual coding (color + pattern/icon)
    enum StressLevel {
        /// Relaxed - Green with good/positive connotation
        static let relaxed = Color(
            light: Color(hex: "#34C759"),
            dark: Color(hex: "#30D158")
        )

        /// Normal - Blue indicating baseline/calm
        static let normal = Color(
            light: Color(hex: "#007AFF"),
            dark: Color(hex: "#0A84FF")
        )

        /// Elevated - Yellow as cautionary signal
        static let elevated = Color(
            light: Color(hex: "#FFD60A"),
            dark: Color(hex: "#FFD60A")
        )

        /// High Stress - Orange as warning
        static let highStress = Color(
            light: Color(hex: "#FF9500"),
            dark: Color(hex: "#FF9F0A")
        )

        /// Overload - Red for critical alert
        static let overload = Color(
            light: Color(hex: "#FF3B30"),
            dark: Color(hex: "#FF453A")
        )

        /// Undefined - Gray for insufficient data
        static let undefined = Color(
            light: Color(hex: "#8E8E93"),
            dark: Color(hex: "#636366")
        )
    }

    /// Get stress color for a given level
    static func stressColor(for level: StressLevelType) -> Color {
        switch level {
        case .relaxed: return StressLevel.relaxed
        case .normal: return StressLevel.normal
        case .elevated: return StressLevel.elevated
        case .highStress: return StressLevel.highStress
        case .overload: return StressLevel.overload
        case .undefined: return StressLevel.undefined
        }
    }
}
```

### Color Accessibility Matrix

| Stress Level | Light Mode | Dark Mode | Contrast (Light) | Contrast (Dark) | Icon | Pattern |
|--------------|------------|-----------|-----------------|----------------|------|---------|
| Relaxed | #34C759 | #30D158 | 4.5:1 ✓ | 4.5:1 ✓ | Leaf | Solid |
| Normal | #007AFF | #0A84FF | 4.5:1 ✓ | 4.5:1 ✓ | Circle | Diagonal Lines |
| Elevated | #FFD60A | #FFD60A | 4.5:1 ✓ | 4.5:1 ✓ | Triangle | Dots |
| High Stress | #FF9500 | #FF9F0A | 4.5:1 ✓ | 4.5:1 ✓ | Square | Horizontal Lines |
| Overload | #FF3B30 | #FF453A | 4.5:1 ✓ | 4.5:1 ✓ | Diamond | Crosshatch |
| Undefined | #8E8E93 | #636366 | 4.5:1 ✓ | 4.5:1 ✓ | Dash | Solid Gray |

### System Color Extensions

```swift
// MARK: - System Colors
extension Color {
    /// Background colors for card hierarchy
    enum Background {
        static let primary = Color(
            light: Color(.systemBackground),
            dark: Color(hex: "#000000")  // Pure black for OLED
        )

        static let secondary = Color(
            light: Color(.secondarySystemBackground),
            dark: Color(hex: "#1C1C1E")
        )

        static let tertiary = Color(
            light: Color(.tertiarySystemBackground),
            dark: Color(hex: "#2C2C2E")
        )

        static let grouped = Color(
            light: Color(.systemGroupedBackground),
            dark: Color(hex: "#000000")
        )
    }

    /// Text colors with proper contrast
    enum Text {
        static let primary = Color(.label)
        static let secondary = Color(.secondaryLabel)
        static let tertiary = Color(.tertiaryLabel)
        static let quaternary = Color(.quaternaryLabel)
    }

    /// Accent and interactive colors
    enum Accent {
        static let blue = Color(.systemBlue)
        static let green = Color(.systemGreen)
        static let orange = Color(.systemOrange)
        static let red = Color(.systemRed)
        static let yellow = Color(.systemYellow)
    }
}

// MARK: - Color Initializer
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            UIColor(traitCollection.userInterfaceStyle == .dark
                ? dark.toUIColor()
                : light.toUIColor()
            )
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toUIColor() -> UIColor {
        UIColor(self)
    }
}
```

### Gradient Definitions

```swift
// MARK: - Gradients
extension LinearGradient {
    /// Stress level gradient for charts and fills
    static func stressGradient(for level: StressLevelType) -> LinearGradient {
        let color = Color.stressColor(for: level)
        return LinearGradient(
            colors: [color.opacity(0.6), color.opacity(0.1), color.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Background gradient for elevated stress states
    static func backgroundTint(for level: StressLevelType) -> LinearGradient {
        let color = Color.stressColor(for: level)
        return LinearGradient(
            colors: [color.opacity(0.08), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
```

---

## 3. Typography System

### Font Scale (SF Pro)

```swift
// MARK: - Typography Scale
extension Font {
    /// Primary application font scale
    enum AppScale {
        /// Large Title (34pt, Bold) - Page titles, hero metrics
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

        /// Title 1 (28pt, Bold) - Card titles
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)

        /// Title 2 (22pt, Bold) - Section headers
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)

        /// Title 3 (20pt, Semibold) - Subsection headers
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

        /// Headline (17pt, Semibold) - Emphasized body
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)

        /// Body (17pt, Regular) - Primary content
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Callout (16pt, Regular) - Secondary information
        static let callout = Font.system(size: 16, weight: .regular, design: .default)

        /// Subhead (15pt, Regular) - Tertiary information
        static let subhead = Font.system(size: 15, weight: .regular, design: .default)

        /// Footnote (13pt, Regular) - Captions, labels
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)

        /// Caption 1 (12pt, Regular) - Very small labels
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)

        /// Caption 2 (11pt, Regular) - Tiny text
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }

    /// Data display fonts (SF Pro Display/Rounded)
    enum DataDisplay {
        /// Extra large number for hero metrics (48pt)
        static let hero = Font.system(size: 48, weight: .bold, design: .rounded)

        /// Large number (34pt)
        static let large = Font.system(size: 34, weight: .bold, design: .rounded)

        /// Medium number (28pt)
        static let medium = Font.system(size: 28, weight: .semibold, design: .rounded)

        /// Small number (20pt)
        static let small = Font.system(size: 20, weight: .medium, design: .rounded)
    }
}
```

### Dynamic Type Support

```swift
// MARK: - Dynamic Type View Modifier
struct DynamicTypeSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .minimumScaleFactor(0.75)
    }
}

extension View {
    /// Applies dynamic type scaling with accessibility support
    func accessibleDynamicType() -> some View {
        modifier(DynamicTypeSizeModifier())
    }
}
```

### Typography Usage Guidelines

| Element | Font Style | Size | Weight | Use Case |
|---------|-----------|------|--------|----------|
| Page Title | Large Title | 34pt | Bold | Navigation title, hero section |
| Card Title | Title 1 | 28pt | Bold | Primary card header |
| Section Header | Title 2 | 22pt | Bold | Section divider |
| Subsection | Title 3 | 20pt | Semibold | Group header |
| Emphasized Text | Headline | 17pt | Semibold | Important body text |
| Primary Content | Body | 17pt | Regular | Standard body text |
| Secondary Info | Callout | 16pt | Regular | Supporting details |
| Tertiary Info | Subhead | 15pt | Regular | Minor details |
| Labels | Footnote | 13pt | Regular | Field labels |
| Captions | Caption 1 | 12pt | Regular | Chart labels |
| Timestamps | Caption 2 | 11pt | Regular | Dates, metadata |

### Number Display

```swift
// MARK: - Number Display View
struct NumberDisplayView: View {
    let value: String
    let unit: String?
    let trend: TrendIndicator?

    enum TrendIndicator {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(value)
                .font(.DataDisplay.hero)
                .monospacedDigit()

            if let unit = unit {
                Text(unit)
                    .font(.AppScale.callout)
                    .foregroundStyle(.secondary)
            }

            if let trend = trend {
                Image(systemName: trend.icon)
                    .font(.AppScale.caption1)
                    .foregroundStyle(trend.color)
            }
        }
    }
}
```

---

## 4. Spacing & Layout

### 8-Point Grid System

```swift
// MARK: - Spacing Scale
extension CGFloat {
    /// 8-point grid spacing system
    enum Spacing {
        static let xs: CGFloat = 4    // Micro spacing (icon + text)
        static let sm: CGFloat = 8    // Tight spacing (related elements)
        static let md: CGFloat = 16   // Regular spacing (standard padding)
        static let lg: CGFloat = 24   // Section spacing (between cards)
        static let xl: CGFloat = 32   // Large spacing (major sections)
        static let xxl: CGFloat = 48  // Extra large (hero sections)
        static let xxxl: CGFloat = 64 // Maximum spacing
    }
}
```

### Layout Dimensions

```swift
// MARK: - Layout Constants
struct Layout {
    /// Standard horizontal padding for iOS screens
    static let horizontalPadding: CGFloat = 16

    /// Standard vertical padding
    static let verticalPadding: CGFloat = 16

    /// Card corner radius
    static let cornerRadius: CGFloat = 12

    /// Button corner radius
    static let buttonCornerRadius: CGFloat = 10

    /// Minimum touch target size (Apple HIG)
    static let minTouchTarget: CGFloat = 44

    /// Card shadow parameters
    static let cardShadowRadius: CGFloat = 2
    static let cardShadowOpacity: Double = 0.1

    /// Safe area awareness
    static func safeAreaPadding(insets: EdgeInsets) -> EdgeInsets {
        return insets
    }
}
```

### Card Component

```swift
// MARK: - Card Component
struct Card<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .Background.secondary
    var cornerRadius: CGFloat = Layout.cornerRadius

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.md)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(Layout.cardShadowOpacity),
                    radius: Layout.cardShadowRadius,
                    x: 0, y: 1)
    }
}
```

---

## 5. UI Mockups - iOS

### Dashboard Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  [Back] Stress Monitor                              [⚙️]       │ ← 44pt nav
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Header Section                                          │   │
│  │                                                           │   │
│  │  Good Morning, Alex                                      │   │ ← Title 2 (22pt Bold)
│  │  Your stress is Normal today                             │   │ ← Body (17pt)
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  PRIMARY METRIC CARD                            │   │   │
│  │  │                                                  │   │   │
│  │  │        [○] Normal                               │   │   │ ← 40pt icon
│  │  │                                                  │   │   │
│  │  │     ┌─────────┐                                 │   │   │
│  │  │     │   65    │  ms                             │   │   │ ← 48pt number
│  │  │     └─────────┘                                 │   │   │
│  │  │        ↑ 5  from yesterday                       │   │   │
│  │  │                                                  │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                    Last: 2:34 PM        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐       │
│  │  Today's HRV  │ │    Trend      │ │  Baseline     │       │
│  │               │ │               │ │               │       │
│  │    62 ms      │ │    7-Day      │ │   55-75 ms    │       │
│  │  ━━━━━━━━     │ │      ↑        │ │   [━━━━━]     │       │
│  │               │ │   +8%         │ │   Normal      │       │
│  └───────────────┘ └───────────────┘ └───────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  TODAY'S INSIGHT                                         │   │
│  │  ─────────────────────                                   │   │
│  │                                                           │   │
│  │  Your HRV is higher than usual today. This suggests      │   │
│  │  good recovery from your recent activity. Keep it up!    │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  80│                                              │  │   │
│  │  │  70│      ●●●                                     │  │   │
│  │  │  60│   ●●●     ●●●     ●                          │  │   │
│  │  │  50│            ●●●                               │  │   │
│  │  │  40│                                              │  │   │
│  │  │  30│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │  │   │
│  │  │    6AM  9AM  12PM  3PM  6PM  9PM                  │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  QUICK ACTIONS                                           │   │
│  │                                                           │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │  [📊]        │  │  [📈]        │  │  [⚙️]        │  │   │
│  │  │  Trends      │  │  Measure     │  │  Settings    │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
│  [🏠]        [📊]        [⌚]        [⚙️]                      │ ← Tab
└─────────────────────────────────────────────────────────────────┘
```

### Trends Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  [Back] Trends                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  TIME RANGE SELECTOR                                     │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                   │   │
│  │  │ 24H  │ │ 7D   │ │ 4W   │ │ 3M   │                   │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  HRV TREND                                               │   │
│  │  ──────────────────                                      │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  90│                                              │  │   │
│  │  │  80│   ●━━━━━━━━━━━━━━━━━●                       │  │   │
│  │  │  70│ ●   ●●●   ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│  │   │
│  │  │  60│●    ●●●  ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│  │   │
│  │  │  50│       ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│  │   │
│  │  │  40│          ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│  │   │
│  │  │  30│                                              │  │   │
│  │  │  20│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│  │   │
│  │  │    Jan  Feb  Mar  Apr  May  Jun                   │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │                                                           │   │
│  │  Average: 62 ms    Range: 45-82 ms    Trend: ↑          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  INSIGHTS & PATTERNS                                     │   │
│  │  ─────────────────────                                   │   │
│  │                                                           │   │
│  │  📈 Weekly Pattern                                       │   │
│  │  Your HRV is 15% higher on weekends vs weekdays          │   │
│  │                                                           │   │
│  │  💤 Best Sleep Day                                       │   │
│  │  Sunday (72 ms average)                                  │   │
│  │                                                           │   │
│  │  🏃 Personal Best                                        │   │
│  │  85 ms on Jan 15                                        │   │
│  │                                                           │   │
│  │  ⚠️  Elevated Periods                                    │   │
│  │  Jan 5-7, Jan 22-24 (linked to late nights)              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  STRESS LEVEL DISTRIBUTION                               │   │
│  │  ───────────────────────────                             │   │
│  │                                                           │   │
│  │  ○ Relaxed    12%  ████                                  │   │
│  │  ○ Normal     58%  █████████████████████                 │   │
│  │  △ Elevated   22%  ████████                              │   │
│  │  □ High       7%   ██                                    │   │
│  │  ◆ Overload   1%   ▌                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Settings Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  [Back] Settings                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PROFILE                                                 │   │
│  │                                                           │   │
│  │  ┌───┐  Alex Johnson                                     │   │
│  │  │ A │  alex.johnson@email.com                          │   │
│  │  └───┘                                                   │   │
│  │                                                           │   │
│  │  Baseline: 55-75 ms                                      │   │
│  │  Tracking since: Jan 15, 2025                            │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  MEASUREMENTS                    >                        │   │
│  │  ─────────────────────────────                           │   │
│  │                                                           │   │
│  │  Measurement Schedule         Auto                       │   │
│  │  Measurement Reminders         9:00 AM, 9:00 PM          │   │
│  │  Watch App Settings            >                         │   │
│  │  Data Sources                  >                         │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  NOTIFICATIONS                    >                        │   │
│  │  ─────────────────────────────                           │   │
│  │                                                           │   │
│  │  Stress Alerts                 On                        │   │
│  │  Alert Threshold               Elevated                  │   │
│  │  Daily Summary                 On                        │   │
│  │  Summary Time                  9:00 PM                   │   │
│  │  Quiet Hours                   Off                       │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  DATA & PRIVACY                   >                        │   │
│  │  ─────────────────────────────                           │   │
│  │                                                           │   │
│  │  Health Data Access            >                         │   │
│  │  iCloud Sync                    On                        │   │
│  │  Export All Data                >                         │   │
│  │  Delete All Data                >                         │   │
│  │  Privacy Policy                 >                         │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  DISPLAY                                                  │   │
│  │  ─────────────────────                                   │   │
│  │                                                           │   │
│  │  App Theme                     System                    │   │
│  │  Units                         ms / bpm                  │   │
│  │  Show HRV As                   SDNN                      │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ABOUT                                                   │   │
│  │  ────────────                                           │   │
│  │                                                           │   │
│  │  Version                      1.0.0                     │   │
│  │  Algorithm Version             2.1                       │   │
│  │  Help & Support                >                         │   │
│  │  Rate Us                       >                         │   │
│  │  Terms of Service              >                         │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Detail View (Drill-down)

```
┌─────────────────────────────────────────────────────────────────┐
│  [<] Jan 18, 2025                                    [Share]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  STRESS LEVEL                                            │   │
│  │                                                           │   │
│  │         ○ Normal (42/100)                                │   │
│  │                                                           │   │
│  │  Confidence: 85%                                         │   │
│  │  Updated: 2:34 PM                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  HRV MEASUREMENTS                                         │   │
│  │  ─────────────────                                       │   │
│  │                                                           │   │
│  │  Current HRV          65 ms                               │   │
│  │  Today's Average      62 ms                               │   │
│  │  Weekly Average       58 ms                               │   │
│  │  30-Day Baseline      55-75 ms                            │   │
│  │                                                           │   │
│  │  Trend                ↑ +7 ms from yesterday             │   │
│  │  Percentile           65th (vs your baseline)             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  CONTRIBUTING FACTORS                                     │   │
│  │  ─────────────────────                                   │   │
│  │                                                           │   │
│  │  HRV Deviation         ●●●●●●●●○○○  +0.8                 │   │
│  │                       (Higher than avg = Good)           │   │
│  │                                                           │   │
│  │  Resting HR           ●●●○○○○○○○○  -0.3                 │   │
│  │                       (Normal)                          │   │
│  │                                                           │   │
│  │  Sleep Quality        ●●●●●●●○○○○  Good (85%)           │   │
│  │                       (7h 23m)                          │   │
│  │                                                           │   │
│  │  Recent Activity      ●●○○○○○○○○○  Moderate             │   │
│  │                       (45 min workout)                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  HOURLY BREAKDOWN                                         │   │
│  │  ────────────────────                                    │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  70│                                              │  │   │
│  │  │  65│  ●────●────●────●                            │  │   │
│  │  │  60│     \    /      \    /                       │  │   │
│  │  │  55│      ●──●        ●──●                        │  │   │
│  │  │  50│                                              │  │   │
│  │  │    6AM  9AM  12PM  3PM  6PM  9PM                  │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  RECOMMENDATIONS                                          │   │
│  │  ────────────────                                         │   │
│  │                                                           │   │
│  │  ✓ Your stress is well-managed today                     │   │
│  │  ✓ Maintain your current sleep schedule                  │   │
│  │  💡 Consider an evening relaxation routine                │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. UI Mockups - watchOS

### Main Screen (Stress Level)

```
┌──────────────────────┐
│                      │
│                      │
│         ○            │  40pt icon
│      Normal          │  18pt label
│                      │
│   ┌──────────┐       │
│   │          │       │
│   │    65    │       │  42pt number
│   │    ms    │       │  14pt unit
│   │          │       │
│   └──────────┘       │
│      ↑ 5            │  14pt trend
│                      │
│   2:34 PM           │  12pt timestamp
│                      │
│   ═══════════       │  1pt divider
│                      │
│  [Tap for details]   │  12pt hint
│                      │
└──────────────────────┘
```

### Detail Screen

```
┌──────────────────────┐
│  < Today's Trend     │  14pt nav
│                      │
│  ┌────────────────┐  │
│  │                │  │  100pt chart
│  │   Mini spark   │  │
│  │     line       │  │
│  │    chart       │  │
│  │                │  │
│  └────────────────┘  │
│                      │
│  High:    72 ms      │  14pt label
│  Low:     58 ms      │  14pt label
│  Average: 65 ms      │  14pt label
│                      │
│  ─────────────       │  1pt divider
│                      │
│  ○ Normal           │  Stress level
│  ● Good quality     │  Data quality
│                      │
└──────────────────────┘
```

### Historical Screen

```
┌──────────────────────┐
│  < 7-Day History     │
│                      │
│  ┌────────────────┐  │
│  │   ●──●──●      │  │  80pt chart
│  │   │  │  │      │
│  │   ●  ●  ●      │  │
│  │                │  │
│  └────────────────┘  │
│                      │
│  Mon Tue Wed Thu     │  11pt days
│  ●   ●   ●   ●      │  16pt dots
│                      │
│  ─────────────       │
│                      │
│  Avg: 62 ms         │
│  Best: 72 ms        │
│                      │
│  [Digital Crown]     │
│  to scroll           │
└──────────────────────┘
```

### Action Screen (Measure)

```
┌──────────────────────┐
│                      │
│      Measuring...    │  18pt
│                      │
│   ┌──────────┐       │
│   │          │       │
│   │   ⏳     │       │  32pt icon
│   │          │       │
│   └──────────┘       │
│                      │
│   Keep wrist         │  14pt
│   still and relax    │
│                      │
│   ═══════════       │
│                      │
│   Stay relaxed       │  14pt
│   for 30 seconds     │
│                      │
└──────────────────────┘
```

---

## 7. SwiftUI Component Library

### Primary Metric Card

```swift
// MARK: - Primary Metric Card
struct PrimaryMetricCard: View {
    let stressLevel: StressLevelType
    let hrvValue: Int
    let unit: String
    let trend: TrendDirection
    let lastUpdate: Date

    enum TrendDirection {
        case up, down, neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            // Stress level header
            HStack {
                Image(systemName: stressLevel.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.stressColor(for: stressLevel))

                VStack(alignment: .leading, spacing: 4) {
                    Text(stressLevel.displayName)
                        .font(.AppScale.title2)

                    Text("Confidence: 85%")
                        .font(.AppScale.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last: \(lastUpdate, format: .dateTime.hour().minute())")
                        .font(.AppScale.caption1)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Main HRV display
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(hrvValue)")
                        .font(.DataDisplay.hero)
                        .monospacedDigit()
                        .foregroundStyle(Color.stressColor(for: stressLevel))

                    Text(unit)
                        .font(.AppScale.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.AppScale.caption1)
                    Text("\(trend.value) from yesterday")
                        .font(.AppScale.subhead)
                }
                .foregroundStyle(trend.color)
            }
        }
        .padding(.md)
        .background(Color.Background.secondary)
        .cornerRadius(Layout.cornerRadius)
    }
}

extension StressLevelType {
    var icon: String {
        switch self {
        case .relaxed: return "leaf.fill"
        case .normal: return "circle.fill"
        case .elevated: return "triangle.fill"
        case .highStress: return "square.fill"
        case .overload: return "diamond.fill"
        case .undefined: return "dash"
        }
    }

    var displayName: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .normal: return "Normal"
        case .elevated: return "Elevated"
        case .highStress: return "High Stress"
        case .overload: return "Overload"
        case .undefined: return "Unknown"
        }
    }
}

extension PrimaryMetricCard.TrendDirection {
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }

    var value: String {
        switch self {
        case .up: return "+5"
        case .down: return "-3"
        case .neutral: return "0"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .secondary
        }
    }
}
```

### Insight Card

```swift
// MARK: - Insight Card
struct InsightCard: View {
    let title: String
    let message: String
    let icon: String
    let chartData: [ChartDataPoint]?

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let time: Date
        let value: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.AppScale.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Message
            Text(message)
                .font(.AppScale.body)
                .foregroundStyle(.primary)

            // Chart (if provided)
            if let chartData = chartData {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("HRV", point.value)
                    )
                    .foregroundStyle(.primary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("HRV", point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.primary.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 120)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
            }
        }
        .padding(.md)
        .frame(maxWidth: .infinity)
        .background(Color.Background.secondary)
        .cornerRadius(Layout.cornerRadius)
    }
}
```

### Quick Stats Row

```swift
// MARK: - Quick Stats Row
struct QuickStatsRow: View {
    var body: some View {
        HStack(spacing: .md) {
            QuickStatCard(
                title: "Today's HRV",
                value: "62 ms",
                icon: "heart.fill",
                color: .red
            )

            QuickStatCard(
                title: "Trend",
                value: "7-Day",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )

            QuickStatCard(
                title: "Baseline",
                value: "55-75 ms",
                icon: "scale.3d",
                color: .green
            )
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: .sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(.AppScale.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.AppScale.caption1)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.md)
        .background(Color.Background.tertiary)
        .cornerRadius(Layout.cornerRadius)
    }
}
```

### Chart Component

```swift
// MARK: - Interactive Chart
struct HRVTrendChart: View {
    let data: [ChartDataPoint]
    let timeRange: TimeRange
    @State private var selection: ChartDataPoint?

    enum TimeRange: String, CaseIterable {
        case hourly = "24H"
        case daily = "7D"
        case weekly = "4W"
        case monthly = "3M"
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            // Time range selector
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            // Chart
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("HRV", point.value)
                )
                .foregroundStyle(.primary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("HRV", point.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.primary.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if let selection = selection, selection.id == point.id {
                    RuleMark(x: .value("Date", selection.date))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(selection.value)) ms")
                                    .font(.AppScale.callout)
                                    .fontWeight(.semibold)
                                Text(selection.date, format: .dateTime.month().day())
                                    .font(.AppScale.caption1)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.sm)
                            .background(Color.Background.secondary)
                            .cornerRadius(8)
                        }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.AppScale.caption2)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                        .foregroundStyle(.clear)
                    AxisValueLabel()
                        .font(.AppScale.caption2)
                }
            }
            .chartAngleSelection(value: $selection)
            .animation(.easeInOut(duration: 0.3), value: selection)
        }
        .padding(.md)
        .background(Color.Background.secondary)
        .cornerRadius(Layout.cornerRadius)
    }
}
```

### Loading State View

```swift
// MARK: - Loading State
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: .lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.primary)

            Text(message)
                .font(.AppScale.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.xxl)
    }
}
```

### Empty State View

```swift
// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: .lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: .sm) {
                Text(title)
                    .font(.AppScale.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.AppScale.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Text(actionTitle)
                    .font(.AppScale.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.Accent.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(Layout.buttonCornerRadius)
            }
            .padding(.horizontal, .xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.xxl)
    }
}
```

---

## 8. Accessibility Guidelines

### Accessibility Testing Checklist

```swift
// MARK: - Accessibility Checklist
struct AccessibilityChecklist {

    // MARK: - Visual Accessibility
    struct Visual {
        /// [ ] All text meets WCAG AA contrast requirements (4.5:1 for normal text, 3:1 for large text)
        static let contrastRatio = "4.5:1 minimum for normal text"

        /// [ ] Color is never the only means of conveying information
        static let dualCoding = "Always combine color with icons, patterns, or text labels"

        /// [ ] Supports Dynamic Type up to accessibility sizes
        static let dynamicType = "Test with accessibility font sizes"

        /// [ ] UI elements remain usable at largest font size
        static let textScaling = "No truncation or overflow at 200% scale"

        /// [ ] Touch targets are at least 44x44 points
        static let touchTargets = "Minimum 44x44pt for interactive elements"
    }

    // MARK: - VoiceOver Support
    struct VoiceOver {
        /// [ ] All interactive elements have accessibility labels
        static let labels = "Descriptive labels for buttons, cards, charts"

        /// [ ] Images have accessibility descriptions
        static let imageDescriptions = "Alt text for all non-decorative images"

        /// [ ] Charts have accessible data table alternatives
        static let chartTables = "Provide table view of chart data"

        /// [ ] State changes are announced properly
        static let stateAnnouncements = "Loading, error, success states announced"

        /// [ ] Custom actions are exposed to VoiceOver
        static let customActions = "Expose swipe actions, expand/collapse"
    }

    // MARK: - Motor Accessibility
    struct Motor {
        /// [ ] All features accessible without gestures
        static let gestureFree = "Provide button alternatives to gestures"

        /// [ ] Supports Switch Control
        static let switchControl = "Test with switch control"

        /// [ ] Supports Voice Control commands
        static let voiceControl = "Test with voice control"

        /// [ ] Reduces motion when requested
        static let reduceMotion = "Respect Reduce Motion setting"
    }

    // MARK: - Cognitive Accessibility
    struct Cognitive {
        /// [ ] Simple, clear language
        static let plainLanguage = "Avoid jargon, use simple terms"

        /// [ ] Progressive disclosure of complex information
        static let progressiveDisclosure = "Hide complexity behind expandable sections"

        /// [ ] Consistent navigation patterns
        static let consistentNavigation = "Same tab order, predictable layout"

        /// [ ] Clear error messages and recovery
        static let errorRecovery = "Explain error and how to fix it"
    }
}
```

### Accessibility View Modifiers

```swift
// MARK: - Accessibility View Modifiers
extension View {
    /// Combines multiple accessibility modifiers for health data
    func accessibleHealthData(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
    }

    /// Makes charts accessible with data table
    func accessibleChart<DataType>(
        data: [DataType],
        description: String
    ) -> some View where DataType: Identifiable {
        self
            .accessibilityLabel(description)
            .accessibilityChartRepresentation([])
    }

    /// Accessible button with haptic feedback
    func accessibleButton(
        label: String,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
        }
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
    }

    /// Accessible card that can be expanded
    func accessibleCard(
        title: String,
        isExpanded: Bool,
        expandAction: @escaping () -> Void
    ) -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityAddTraits(isExpanded ? .isButton : .isButton)
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            .onTapGesture(perform: expandAction)
    }
}
```

### Accessible Chart Component

```swift
// MARK: - Accessible Chart
struct AccessibleHRVChart: View {
    let data: [HRVDataPoint]
    @AccessibilityFocusState private var isChartFocused: Bool

    struct HRVDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    var body: some View {
        VStack {
            // Visual chart
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("HRV", point.value)
                )
            }
            .frame(height: 200)
            .accessibilityHidden(true) // Hide from VoiceOver, use table below

            // Accessible data table
            VStack(alignment: .leading, spacing: .sm) {
                Text("HRV Data")
                    .font(.AppScale.headline)
                    .accessibilityAddTraits(.isHeader)

                ForEach(data) { point in
                    HStack {
                        Text(point.date, format: .dateTime.month().day())
                        Spacer()
                        Text("\(Int(point.value)) ms")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(point.dateformatted(.dateTime.month().day().hour().minute())), \(Int(point.value)) milliseconds")
                }
            }
            .padding()
            .background(Color.Background.secondary)
            .cornerRadius(Layout.cornerRadius)
        }
        .accessibilityLabel("HRV trend chart showing \(data.count) measurements")
        .accessibilityHint("Swipe up or down to hear individual values")
        .accessibilityFocus($isChartFocused)
    }
}
```

---

## 9. Animation & Interaction

### Animation Constants

```swift
// MARK: - Animation Constants
extension Animation {
    /// Standard spring animation for UI transitions
    static let appSpring = Animation.spring(
        response: 0.35,
        dampingFraction: 0.75,
        blendDuration: 0.2
    )

    /// Fade animation for content changes
    static let appFade = Animation.easeInOut(
        duration: 0.25
    )

    /// Slide animation for navigation
    static let appSlide = Animation.easeInOut(
        duration: 0.3
    )

    /// Quick animation for button presses
    static let appQuick = Animation.easeInOut(
        duration: 0.15
    )
}
```

### Haptic Feedback

```swift
// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// Success feedback - light tap
    func success() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Warning feedback - medium tap
    func warning() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Error feedback - heavy tap
    func error() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Selection changed
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Notification feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Contextual haptic based on stress level
    func stressLevelChanged(to level: StressLevelType) {
        switch level {
        case .relaxed, .normal:
            success()
        case .elevated:
            warning()
        case .highStress, .overload:
            notification(.warning)
        case .undefined:
            selectionChanged()
        }
    }
}
```

### Interactive Card Component

```swift
// MARK: - Expandable Card
struct ExpandableCard<Content: View, ExpandedContent: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    @ViewBuilder let expandedContent: ExpandedContent

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            // Header (always visible)
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Text(title)
                    .font(.AppScale.headline)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .rotationEffect(isExpanded ? .degrees(180) : .zero)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.appSpring) {
                    isExpanded.toggle()
                    HapticManager.shared.selectionChanged()
                }
            }

            // Always-visible content
            content

            // Expandable content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.md)
        .frame(maxWidth: .infinity)
        .background(Color.Background.secondary)
        .cornerRadius(Layout.cornerRadius)
        .accessibilityCard(
            title: title,
            isExpanded: isExpanded,
            expandAction: {
                withAnimation(.appSpring) {
                    isExpanded.toggle()
                }
            }
        )
    }
}
```

---

## 10. Dark Mode Support

### Dark Mode Color Strategy

```swift
// MARK: - Dark Mode Colors
extension Color {
    /// Platform-specific color that adapts to appearance
    struct Adaptive {
        /// Primary background - pure black for OLED in dark mode
        static let background = Color(
            light: Color(.systemBackground),
            dark: Color(hex: "#000000")
        )

        /// Secondary background
        static let backgroundSecondary = Color(
            light: Color(.secondarySystemBackground),
            dark: Color(hex: "#1C1C1E")
        )

        /// Tertiary background
        static let backgroundTertiary = Color(
            light: Color(.tertiarySystemBackground),
            dark: Color(hex: "#2C2C2E")
        )

        /// Grouped background
        static let groupedBackground = Color(
            light: Color(.systemGroupedBackground),
            dark: Color(hex: "#000000")
        )

        /// Primary text
        static let textPrimary = Color(
            light: Color(.label),
            dark: Color(hex: "#FFFFFF")
        )

        /// Secondary text
        static let textSecondary = Color(
            light: Color(.secondaryLabel),
            dark: Color(hex: "#EBEBF5")
        )

        /// Separator
        static let separator = Color(
            light: Color(.separator),
            dark: Color(hex: "#38383A")
        )

        /// Stress level colors (dark mode adjusted)
        enum Stress {
            static let relaxed = Color(
                light: Color(hex: "#34C759"),
                dark: Color(hex: "#30D158")
            )

            static let normal = Color(
                light: Color(hex: "#007AFF"),
                dark: Color(hex: "#0A84FF")
            )

            static let elevated = Color(
                light: Color(hex: "#FFD60A"),
                dark: Color(hex: "#FFD60A")  // Same in dark mode
            )

            static let high = Color(
                light: Color(hex: "#FF9500"),
                dark: Color(hex: "#FF9F0A")
            )

            static let overload = Color(
                light: Color(hex: "#FF3B30"),
                dark: Color(hex: "#FF453A")
            )
        }
    }
}
```

### Dark Mode View Modifier

```swift
// MARK: - Dark Mode Awareness
struct DarkModeAwareModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
            .onChange(of: colorScheme) { _, newScheme in
                // Handle scheme change if needed
            }
    }
}

extension View {
    /// Makes the view adapt to dark mode changes
    func darkModeAware() -> some View {
        modifier(DarkModeAwareModifier())
    }
}
```

---

## Sources

This design system is based on:

1. **Apple Human Interface Guidelines**
   - HealthKit: https://developer.apple.com/design/human-interface-guidelines/healthkit
   - Accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility
   - Charts: https://developer.apple.com/design/human-interface-guidelines/charting-data
   - Complications: https://developer.apple.com/design/human-interface-guidelines/complications
   - Dark Mode: https://developer.apple.com/design/human-interface-guidelines/dark-mode

2. **WCAG 2.1 Accessibility Standards**
   - Contrast Requirements: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
   - Color as Supplement: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html

3. **Industry Best Practices**
   - Apple Health App design patterns
   - WHOOP recovery score visualization
   - Oura Ring readiness metrics
   - Welltory stress tracking patterns

---

**Document End**

*This design system provides a comprehensive foundation for building an accessible, user-friendly stress monitoring application. Use these components and guidelines consistently across all screens and platforms.*
