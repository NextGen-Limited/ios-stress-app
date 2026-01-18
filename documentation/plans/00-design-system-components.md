# Design System & Component Library

> **Created by:** Phuong Doan
> **Feature:** Foundation for all UI screens
> **Designs Referenced:** All 35 screens

---

## Overview

This document defines the design tokens, theme, and reusable component library used across all screens in the StressMonitor app.

---

## 1. Design Tokens

### 1.1 Color Palette

Based on all design mockups (dashboard, history, settings, etc.):

```swift
// StressMonitor/Theme/Color+Extensions.swift

import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors
    static let primary = Color(hex: "#2b7cee")
    static let primaryHover = Color(hex: "#1e5bb3")

    // MARK: - Stress Level Colors (WCAG AA Compliant)
    static let stressRelaxed = Color(hex: "#34C759")    // Green
    static let stressMild = Color(hex: "#007AFF")       // Blue
    static let stressModerate = Color(hex: "#FFD60A")   // Yellow
    static let stressHigh = Color(hex: "#FF9500")       // Orange
    static let stressSevere = Color(hex: "#FF3B30")     // Red

    // MARK: - Background Colors
    static let backgroundLight = Color(hex: "#f6f7f8")
    static let backgroundDark = Color(hex: "#000000")   // Pure black for OLED
    static let cardDark = Color(hex: "#1C1C1E")         // Secondary dark gray
    static let cardLight = Color(hex: "#ffffff")

    // MARK: - Text Colors
    static let textMain = Color(hex: "#FFFFFF")
    static let textSecondary = Color(hex: "#EBEBF5")
    static let textTertiary = Color(hex: "#9da8b9")
    static let textQuaternary = Color(hex: "#606e8a")

    // MARK: - Semantic Colors
    static let healthRed = Color(hex: "#FF2D55")
    static let successGreen = Color(hex: "#34C759")
    static let warningYellow = Color(hex: "#FFB020")
    static let infoBlue = Color(hex: "#0d59f2")

    // MARK: - Separator Colors
    static let separatorLight = Color(hex: "#c6c6c8")
    static let separatorDark = Color(hex: "#38383a")

    // MARK: - Helper: Stress Color Based on Category
    static func stressColor(for category: StressCategory) -> Color {
        switch category {
        case .relaxed: return .stressRelaxed
        case .mild: return .stressMild
        case .moderate: return .stressModerate
        case .high: return .stressHigh
        case .severe: return .stressSevere
        }
    }

    // MARK: - Helper: Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Stress Category Enum
enum StressCategory: String, Codable, CaseIterable {
    case relaxed
    case mild
    case moderate
    case high
    case severe

    var displayName: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .mild: return "Normal"
        case .moderate: return "Elevated"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }

    var iconName: String {
        switch self {
        case .relaxed: return "sparkles"
        case .mild: return "checkmark.circle"
        case .moderate: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon.fill"
        case .severe: return "exclamationmark.octagon.fill"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .relaxed: return 0...25
        case .mild: return 25...50
        case .moderate: return 50...75
        case .high: return 75...90
        case .severe: return 90...100
        }
    }

    static func from(level: Double) -> StressCategory {
        for category in allCases {
            if category.range.contains(level) {
                return category
            }
        }
        return .moderate
    }
}
```

### 1.2 Typography

```swift
// StressMonitor/Theme/Typography.swift

import SwiftUI

enum Typography {
    // MARK: - Large Titles
    static let largeTitle = Font.system(size: 34, weight: .bold)

    // MARK: - Titles
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Body
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)

    // MARK: - Secondary
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Metrics (Large Numbers)
    static let largeMetric = Font.system(size: 48, weight: .bold)
    static let metric = Font.system(size: 32, weight: .bold)
    static let smallMetric = Font.system(size: 24, weight: .bold)
}

// MARK: - View Modifier for Header Styling
struct HeaderStyle: ViewModifier {
    let size: HeaderSize

    enum HeaderSize {
        case large, medium, small

        var font: Font {
            switch self {
            case .large: return .title1
            case .medium: return .title2
            case .small: return .title3
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .font(size.font)
            .foregroundColor(.textMain)
    }
}

extension View {
    func headerStyle(_ size: HeaderStyle.HeaderSize) -> some View {
        modifier(HeaderStyle(size: size))
    }
}
```

### 1.3 Spacing & Layout

```swift
// StressMonitor/Theme/Spacing.swift

import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
    static let circle: CGFloat = 9999
}

enum IconSize {
    static let xs: CGFloat = 16
    static let sm: CGFloat = 20
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 48
    static let xxl: CGFloat = 64
}

// MARK: - Standard Card Padding
struct CardPadding: ViewModifier {
    let size: CardSize

    enum CardSize {
        case compact, regular, spacious

        var value: CGFloat {
            switch self {
            case .compact: return 12
            case .regular: return 16
            case .spacious: return 24
            }
        }
    }

    func body(content: Content) -> some View {
        content.padding(size.value)
    }
}

extension View {
    func cardPadding(_ size: CardPadding.CardSize = .regular) -> some View {
        modifier(CardPadding(size: size))
    }
}
```

---

## 2. Reusable Components

### 2.1 Stress Ring View

**Used in:** Dashboard, Stress Dashboard Today, Widgets

```swift
// StressMonitor/Views/Components/StressRingView.swift

import SwiftUI

struct StressRingView: View {
    let stressLevel: Double  // 0-100
    let category: StressCategory
    let confidence: Double?
    let size: CGFloat

    init(
        stressLevel: Double,
        category: StressCategory,
        confidence: Double? = nil,
        size: CGFloat = 256
    ) {
        self.stressLevel = stressLevel
        self.category = category
        self.confidence = confidence
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: size * 0.07)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: stressLevel / 100)
                .stroke(
                    Color.stressColor(for: category),
                    style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.stressColor(for: category).opacity(0.3),
                    radius: 10
                )

            // Inner content
            VStack(spacing: 4) {
                // Category icon
                Image(systemName: category.iconName)
                    .font(.system(size: size * 0.125))
                    .foregroundColor(Color.stressColor(for: category))

                // Stress score
                Text("\(Int(stressLevel))")
                    .font(.system(size: size * 0.22, weight: .bold))

                // Category badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.stressColor(for: category))
                        .frame(width: 6, height: 6)
                    Text(category.displayName)
                        .font(.system(size: size * 0.047, weight: .bold))
                }
                .padding(.horizontal, size * 0.047)
                .padding(.vertical, size * 0.023)
                .background(
                    Color.stressColor(for: category).opacity(0.2),
                    in: Capsule()
                )

                // Confidence indicator (optional)
                if let confidence = confidence {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: size * 0.047))
                        Text("\(Int(confidence))% Confidence")
                            .font(.caption)
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stress level: \(Int(stressLevel)) out of 100")
        .accessibilityValue("\(category.displayName)")
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.backgroundDark.ignoresSafeArea()
        StressRingView(
            stressLevel: 42,
            category: .moderate,
            confidence: 85,
            size: 256
        )
    }
}
```

### 2.2 Metric Card

**Used in:** Dashboard, History & Patterns, Measurement Details

```swift
// StressMonitor/Views/Components/MetricCard.swift

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: MetricTrend?
    let chartData: [Double]?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color,
        trend: MetricTrend? = nil,
        chartData: [Double]? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
        self.chartData = chartData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with icon and title
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: IconSize.md))
                }
                .frame(width: 36, height: 36)

                Text(title.uppercased())
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }

            // Value
            Text(value)
                .font(.metric)

            // Subtitle (if provided)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }

            // Trend (if provided)
            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.iconName)
                    Text(trend.displayValue)
                        .font(.caption1)
                        .bold()
                }
                .foregroundColor(trend.color)
            }

            // Sparkline chart (if data provided)
            if let chartData = chartData, !chartData.isEmpty {
                MetricSparkline(data: chartData, color: iconColor)
                    .frame(height: 56)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(CornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Metric Trend
enum MetricTrend {
    case up(value: String, isGood: Bool = true)
    case down(value: String, isGood: Bool = false)
    case neutral

    var iconName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up(let _, let isGood): return isGood ? .successGreen : .stressHigh
        case .down(let _, let isGood): return isGood ? .successGreen : .stressHigh
        case .neutral: return .textSecondary
        }
    }

    var displayValue: String {
        switch self {
        case .up(let v, _), .down(let v, _): return v
        case .neutral: return "-"
        }
    }
}

// MARK: - Sparkline Component
struct MetricSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let step = width / CGFloat(max(data.count - 1, 1))

            let min = data.min() ?? 0
            let max = data.max() ?? 100
            let range = max - min

            func y(for value: Double) -> CGFloat {
                if range == 0 { return height / 2 }
                return height - CGFloat((value - min) / range) * height * 0.8 - height * 0.1
            }

            ZStack {
                // Gradient fill
                Path { path in
                    guard !data.isEmpty else { return }
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line stroke
                Path { path in
                    guard !data.isEmpty else { return }
                    path.move(to: CGPoint(x: 0, y: y(for: data[0])))

                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Preview
#Preview("Metric Cards") {
    VStack(spacing: 16) {
        MetricCard(
            title: "HRV",
            value: "65",
            subtitle: "ms",
            icon: "waveform.path",
            iconColor: .successGreen,
            trend: .up(value: "+2ms"),
            chartData: [45, 52, 48, 60, 55, 62, 65, 58]
        )

        MetricCard(
            title: "Resting HR",
            value: "58",
            subtitle: "bpm",
            icon: "heart.fill",
            iconColor: .healthRed,
            trend: .down(value: "-3 bpm")
        )
    }
    .padding()
    .background(Color.backgroundDark)
}
```

### 2.3 Segmented Control

**Used in:** History & Patterns, Settings Theme Picker

```swift
// StressMonitor/Views/Components/SegmentedControl.swift

import SwiftUI

struct SegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    var backgroundColor: Color = Color(UIColor.systemGray5)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: { selection = index }) {
                    Text(option)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selection == index ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selection == index ? Color.primary : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(backgroundColor)
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Options: \(options.joined(separator: ", "))")
        .accessibilityValue(options[selection])
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SegmentedControl(
            selection: .constant(1),
            options: ["24H", "7D", "4W", "3M"]
        )

        SegmentedControl(
            selection: .constant(2),
            options: ["System", "Light", "Dark"]
        )
    }
    .padding()
    .background(Color.backgroundDark)
}
```

### 2.4 Settings Toggle Row

**Used in:** App Settings, Configuration Settings

```swift
// StressMonitor/Views/Components/SettingsRow.swift

import SwiftUI

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: IconSize.sm))
            }
            .frame(width: 32, height: 32)

            // Title
            Text(title)
                .font(.body)
                .foregroundColor(.textMain)

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .listRowBackground(Color.cardDark)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    var action: (() -> Void)?

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: IconSize.sm))
                }
                .frame(width: 32, height: 32)

                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.textMain)

                Spacer()

                // Value (if provided)
                if let value = value {
                    Text(value)
                        .foregroundColor(.textSecondary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
                    .font(.system(size: IconSize.sm))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (value.map { ": \($0)" } ?? ""))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        SettingsToggleRow(
            icon: "watch.face",
            iconColor: .blue,
            title: "Auto-Measurement",
            isOn: .constant(true)
        )

        SettingsNavigationRow(
            icon: "alarm",
            iconColor: .orange,
            title: "Reminders",
            value: "Daily at 8 AM"
        )
    }
    .background(Color.cardDark)
}
```

### 2.5 Progress Dots (Onboarding)

**Used in:** All onboarding screens

```swift
// StressMonitor/Views/Components/ProgressDots.swift

import SwiftUI

struct ProgressDots: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == currentStep {
                    // Active dot (wide)
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 24, height: 6)
                        .cornerRadius(3)
                } else {
                    // Inactive dot (small)
                    Circle()
                        .fill(step < currentStep ? Color.primary : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ProgressDots(currentStep: 1, totalSteps: 4)
        ProgressDots(currentStep: 2, totalSteps: 4)
        ProgressDots(currentStep: 3, totalSteps: 4)
        ProgressDots(currentStep: 4, totalSteps: 4)
    }
    .padding()
    .background(Color.backgroundDark)
}
```

### 2.6 List Section Header

**Used in:** Settings, History, Measurement Details

```swift
// StressMonitor/Views/Components/ListSectionHeader.swift

import SwiftUI

struct ListSectionHeader: View {
    let title: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textSecondary)
            .uppercaseSmallCaps()
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 0) {
        ListSectionHeader(title: "Measurements")
        Rectangle()
            .fill(Color.cardDark)
            .frame(height: 60)
    }
    .background(Color.backgroundDark)
}
```

---

## 3. View Modifiers

### 3.1 Glass Effect Modifier

```swift
// StressMonitor/Theme/ViewModifiers.swift

import SwiftUI

struct GlassEffect: ViewModifier {
    var opacity: Double = 0.8

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .opacity(opacity)
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardDark)
            .cornerRadius(CornerRadius.large)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassEffect(opacity: Double = 0.8) -> some View {
        modifier(GlassEffect(opacity: opacity))
    }

    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
```

### 3.2 Button Styles

```swift
// StressMonitor/Theme/ButtonStyles.swift

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.primary)
            .cornerRadius(28)
            .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.cardDark)
            .cornerRadius(26)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { .init() }
}
```

---

## 4. Accessibility Helpers

```swift
// StressMonitor/Theme/Accessibility.swift

import SwiftUI

extension View {
    // Accessibility for stress levels (dual coding: color + icon)
    func stressAccessibility(level: Double, category: StressCategory) -> some View {
        self
            .accessibilityLabel("Stress level: \(Int(level))")
            .accessibilityHint("\(category.displayName)")
            .accessibilityValue(category.displayName)
    }

    // Combine child accessibility elements
    func combineAccessibility() -> some View {
        self.accessibilityElement(children: .combine)
    }

    // Accessibility for interactive elements
    func interactiveAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}
```

---

## 5. Animation Constants

```swift
// StressMonitor/Theme/Animations.swift

import SwiftUI

enum AnimationDuration {
    static let fast: TimeInterval = 0.2
    static let normal: TimeInterval = 0.35
    static let slow: TimeInterval = 0.5
    static let breathingCycle: TimeInterval = 8.0
}

struct AppAnimations {
    static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let breathing = Animation.easeInOut(duration: AnimationDuration.breathingCycle).repeatForever(autoreverses: true)
}
```

---

## File Structure

```
StressMonitor/Theme/
├── Color+Extensions.swift
├── Typography.swift
├── Spacing.swift
├── ViewModifiers.swift
├── ButtonStyles.swift
├── Accessibility.swift
└── Animations.swift

StressMonitor/Views/Components/
├── StressRingView.swift
├── MetricCard.swift
├── SegmentedControl.swift
├── SettingsRow.swift
├── ProgressDots.swift
├── ListSectionHeader.swift
└── MetricSparkline.swift
```
