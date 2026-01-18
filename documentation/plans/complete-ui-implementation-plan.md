# Complete UI Implementation Plan
# StressMonitor iOS App - All 35 Screens

> **Created by:** Phuong Doan
> **Version:** 1.0
> **Last Updated:** 2025-01-18

---

## Table of Contents

1. [Design System & Theme](#1-design-system--theme)
2. [Component Library](#2-component-library)
3. [Onboarding Flow](#3-onboarding-flow)
4. [Main Dashboard](#4-main-dashboard)
5. [History & Trends](#5-history--trends)
6. [Breathing Exercises](#6-breathing-exercises)
7. [Settings & Configuration](#7-settings--configuration)
8. [Measurement Details](#8-measurement-details)
9. [Home Screen Widgets](#9-home-screen-widgets)
10. [Error States](#10-error-states)
11. [Navigation Structure](#11-navigation-structure)
12. [Data Models](#12-data-models)
13. [Testing Requirements](#13-testing-requirements)

---

## 1. Design System & Theme

### 1.1 Color Palette

Based on design analysis, extract to `DesignTokens.swift`:

```swift
// StressMonitor/Theme/DesignTokens.swift

extension Color {
    // Primary Brand Color
    static let primary = Color(hex: "#2b7cee")

    // Stress Level Colors (WCAG Compliant)
    static let stressRelaxed = Color(hex: "#34C759")      // Green
    static let stressMild = Color(hex: "#007AFF")         // Blue
    static let stressModerate = Color(hex: "#FFD60A")     // Yellow
    static let stressHigh = Color(hex: "#FF9500")         // Orange
    static let stressSevere = Color(hex: "#FF3B30")       // Red

    // Background Colors
    static let backgroundLight = Color(hex: "#f6f7f8")
    static let backgroundDark = Color(hex: "#000000")     // Pure black for OLED
    static let cardDark = Color(hex: "#1C1C1E")           // Secondary dark gray

    // Text Colors
    static let textMain = Color(hex: "#FFFFFF")
    static let textSecondary = Color(hex: "#EBEBF5")
    static let textTertiary = Color(hex: "#9da8b9")

    // Semantic Colors
    static let healthRed = Color(hex: "#FF2D55")
    static let successGreen = Color(hex: "#34C759")
    static let warningYellow = Color(hex: "#FFB020")

    // Helper for stress color based on category
    static func stressColor(for category: StressCategory) -> Color {
        switch category {
        case .relaxed: return .stressRelaxed
        case .mild: return .stressMild
        case .moderate: return .stressModerate
        case .high: return .stressHigh
        case .severe: return .stressSevere
        }
    }
}
```

### 1.2 Typography

```swift
// StressMonitor/Theme/Typography.swift

enum Typography {
    // Large Titles
    static let largeTitle = Font.system(size: 34, weight: .bold)

    // Headers
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)

    // Body
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)

    // Secondary
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)

    // Metrics
    static let largeMetric = Font.system(size: 44, weight: .bold)
    static let metric = Font.system(size: 32, weight: .bold)
}
```

### 1.3 Spacing & Layout

```swift
// StressMonitor/Theme/Spacing.swift

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xlarge: CGFloat = 32
    static let circle: CGFloat = 9999
}
```

---

## 2. Component Library

### 2.1 Stress Ring View

**Screens using:** Dashboard Dark, Stress Dashboard Today 1&2

```swift
// StressMonitor/Views/Components/StressRingView.swift

struct StressRingView: View {
    let stressLevel: Double  // 0-100
    let category: StressCategory
    let confidence: Double?

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 18)

            // Progress arc
            Circle()
                .trim(from: 0, to: stressLevel / 100)
                .stroke(
                    Color.stressColor(for: category),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.stressColor(for: category).opacity(0.3), radius: 10)

            VStack(spacing: 4) {
                // Category icon
                Image(systemName: category.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(Color.stressColor(for: category))

                // Stress score
                Text("\(Int(stressLevel))")
                    .font(.system(size: 56, weight: .bold))

                // Category badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.stressColor(for: category))
                        .frame(width: 6, height: 6)
                    Text(category.displayName)
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Color.stressColor(for: category).opacity(0.2),
                    in: Capsule()
                )

                // Confidence indicator
                if let confidence = confidence {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                        Text("\(Int(confidence))% Confidence")
                            .font(.caption)
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(width: 256, height: 256)
    }
}
```

### 2.2 Metric Card

**Screens using:** Dashboard Dark, History & Patterns

```swift
// StressMonitor/Views/Components/MetricCard.swift

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: MetricTrend?
    let chartData: [Double]?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                .frame(width: 36, height: 36)

                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.iconName)
                    Text(trend.displayValue)
                        .font(.caption)
                        .bold()
                }
                .foregroundColor(trend.color)
            }

            if let chartData = chartData, !chartData.isEmpty {
                MetricSparkline(data: chartData, color: iconColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

enum MetricTrend {
    case up(value: String)
    case down(value: String)
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
        case .up: return .stressRelaxed  // Good trend
        case .down: return .stressHigh    // Bad trend
        case .neutral: return .textSecondary
        }
    }

    var displayValue: String {
        switch self {
        case .up(let v), .down(let v): return v
        case .neutral: return "-"
        }
    }
}
```

### 2.3 Segmented Control

**Screens using:** History & Patterns, Settings

```swift
// StressMonitor/Views/Components/SegmentedControl.swift

struct SegmentedControl: View {
    @Binding var selection: Int
    let options: [String]

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
            }
        }
        .padding(4)
        .background(Color(UIColor.systemGray5))
        .cornerRadius(10)
    }
}
```

### 2.4 Breathing Orb Animation

**Screens using:** Breathing Session Dark/Light

```swift
// StressMonitor/Views/Components/BreathingOrbView.swift

struct BreathingOrbView: View {
    let phase: BreathingPhase
    let duration: TimeInterval

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .frame(width: 192, height: 192)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 0.2)

            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                .frame(width: 256, height: 256)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .opacity(isAnimating ? 0 : 0.1)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primary,
                            Color.primary.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 96
                    )
                )
                .frame(width: 192, height: 192)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.5 : 1.0)

            // Core
            Circle()
                .fill(Color.primary.opacity(0.8))
                .frame(width: 128, height: 128)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.5 : 1.0)

            // Instruction text
            Text(phase.instructionText)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

enum BreathingPhase {
    case inhale
    case hold
    case exhale

    var instructionText: String {
        switch self {
        case .inhale: return "Inhale..."
        case .hold: return "Hold"
        case .exhale: return "Exhale..."
        }
    }
}
```

### 2.5 Settings Toggle Row

**Screens using:** App Settings, Configuration Settings

```swift
// StressMonitor/Views/Components/SettingsRow.swift

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(.body)
                .foregroundColor(.textMain)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .listRowBackground(Color.cardDark)
    }
}
```

### 2.6 Measurement List Item

**Screens using:** Measurement History List

```swift
// StressMonitor/Views/Components/MeasurementListItem.swift

struct MeasurementListItem: View {
    let measurement: StressMeasurement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement.timestamp, style: .time)
                        .font(.system(size: 18, weight: .semibold))
                    Text(measurement.timestamp, format: .dateTime.month().day())
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.stressColor(for: measurement.category))
                            .frame(width: 8, height: 8)
                        Text("\(Int(measurement.stressLevel))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("HRV: \(Int(measurement.hrv))ms")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .background(Color.cardDark)
            .cornerRadius(12)
        }
        .buttonStyle(.scaleEffect())
    }
}
```

---

## 3. Onboarding Flow

### 3.1 Welcome Step 1

**Design:** `onboarding_welcome_step_1`

```swift
// StressMonitor/Views/Onboarding/WelcomeStep1View.swift

struct WelcomeStep1View: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToStep2 = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 48, height: 6)
                .cornerRadius(3)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 32) {
                    // Hero illustration
                    VStack(spacing: 16) {
                        // Subtle pulsing background
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 256, height: 256)
                            .blur(radius: 40)

                        // Hero image/icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(0.2), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 192, height: 192)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 32)

                    // Title
                    Text("Understand Your Stress")
                        .font(.title1)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("Track your HRV and manage stress levels with professional insights.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "checkmark.circle.fill",
                            title: "Accurate monitoring",
                            color: .successGreen
                        )
                        FeatureRow(
                            icon: "checkmark.circle.fill",
                            title: "Personalized baseline",
                            color: .successGreen
                        )
                        FeatureRow(
                            icon: "checkmark.circle.fill",
                            title: "Actionable insights",
                            color: .successGreen
                        )
                    }
                    .padding(.horizontal, 32)
                }
            }

            // Bottom CTA
            VStack(spacing: 16) {
                Button(action: { navigateToStep2 = true }) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(28)
                        .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)

                Text("Already have an account? [Sign in](#)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, 32)
        }
        .background(Color.backgroundDark)
        .navigationDestination(isPresented: $navigateToStep2) {
            WelcomeStep2View()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(title)
                .font(.body)
                .foregroundColor(.textMain)
        }
    }
}
```

### 3.2 Welcome Step 2

**Design:** `onboarding_welcome_step_2`

Similar to Step 1, continue feature highlights.

### 3.3 Health Sync Permissions (2 screens)

**Design:** `onboarding_health_sync_1`, `onboarding_health_sync_2`

```swift
// StressMonitor/Views/Onboarding/HealthSyncPermissionView.swift

struct HealthSyncPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.healthKit) private var healthKit
    @State private var isLoading = false
    @State private var showError = false
    @State private var navigateToBaseline = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            ProgressDots(currentStep: 1, totalSteps: 4)
                .padding(.top, 24)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(radius: 12)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.healthRed)
                    }
                    .frame(width: 80, height: 80)

                    // Title
                    Text("Health Data Access")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)

                    // Description
                    Text("StressMonitor needs access to your HealthKit data to analyze HRV and detect stress patterns accurately.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Data types list
                    VStack(spacing: 0) {
                        SectionHeader(title: "Data Types Requested")

                        DataTypeRow(
                            icon: "waveform.path",
                            title: "Heart Rate Variability",
                            subtitle: "Essential for stress detection"
                        )

                        Divider()
                            .padding(.leading, 64)

                        DataTypeRow(
                            icon: "heart.fill",
                            title: "Resting Heart Rate",
                            subtitle: "Baseline calibration"
                        )

                        Divider()
                            .padding(.leading, 64)

                        DataTypeRow(
                            icon: "bed.double.fill",
                            title: "Sleep Analysis",
                            subtitle: "Recovery tracking"
                        )
                    }
                    .background(Color.cardDark)
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                }
            }

            // Bottom actions
            VStack(spacing: 20) {
                Button(action: requestAuthorization) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Authorize & Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.primary)
                .cornerRadius(26)
                .disabled(isLoading)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("Your health data is processed locally on your device.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundDark)
        .alert("Health Access Required", isPresented: $showError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable HealthKit access in Settings to continue.")
        }
        .navigationDestination(isPresented: $navigateToBaseline) {
            BaselineCalibrationView()
        }
    }

    private func requestAuthorization() {
        isLoading = true
        Task {
            do {
                try await healthKit.requestAuthorization()
                await MainActor.run {
                    isLoading = false
                    navigateToBaseline = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
    }
}

struct DataTypeRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.healthRed.opacity(0.1))
                Image(systemName: icon)
                    .foregroundColor(.healthRed)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.textMain)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.successGreen)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
```

### 3.4 Baseline Calibration (9 screens)

**Designs:** `onboarding_baseline_calibration_1` through `9`

```swift
// StressMonitor/Views/Onboarding/BaselineCalibrationView.swift

struct BaselineCalibrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentDay = 1
    @State private var calibrationPhase: CalibrationPhase = .learning
    @State private var navigateToSuccess = false

    enum CalibrationPhase {
        case learning    // Days 1-3
        case calibrating // Days 4-5
        case validation // Days 6-7
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            ProgressDots(currentStep: 2, totalSteps: 4)
                .padding(.top, 24)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 12) {
                        Text("Set Your Baseline")
                            .font(.title1)

                        Text("To personalize your stress insights, we need to learn your body's patterns over the next 7 days.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: Double(currentDay) / 7.0)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Image(systemName: "vital_signs")
                                .font(.system(size: 36))
                                .foregroundColor(.primary)
                            Text("Ready")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .uppercaseSmallCaps()
                        }
                    }
                    .frame(width: 192, height: 192)
                    .padding(.vertical, 32)

                    // 7-day timeline
                    VStack(spacing: 20) {
                        HStack(spacing: 4) {
                            ForEach(1...7, id: \.self) { day in
                                DayIndicator(
                                    day: day,
                                    isCompleted: day < currentDay,
                                    isCurrent: day == currentDay
                                )
                                if day < 7 {
                                    Rectangle()
                                        .fill(day < currentDay ? Color.primary.opacity(0.2) : Color.white.opacity(0.1))
                                        .frame(height: 2)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, 8)

                        // Phase descriptions
                        VStack(alignment: .leading, spacing: 16) {
                            PhaseDescription(
                                title: "Learning Phase",
                                subtitle: "(Days 1-3)",
                                description: "Analyzing your initial HRV range and resting heart rate patterns.",
                                isActive: calibrationPhase == .learning
                            )
                            PhaseDescription(
                                title: "Calibration",
                                subtitle: "(Days 4-5)",
                                description: "Identifying stress triggers and recovery moments.",
                                isActive: calibrationPhase == .calibrating
                            )
                            PhaseDescription(
                                title: "Validation",
                                subtitle: "(Days 6-7)",
                                description: "Confirming baseline accuracy before full activation.",
                                isActive: calibrationPhase == .validation
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(24)
                    .background(Color.cardDark)
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                }
            }

            // Bottom actions
            VStack(spacing: 20) {
                Button(action: { navigateToSuccess = true }) {
                    Text("Start Calibration")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.primary)
                .cornerRadius(26)

                HStack(spacing: 8) {
                    Image(systemName: "verified_user")
                        .font(.system(size: 12))
                    Text("HealthKit data stays private on your device")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundDark)
        .navigationDestination(isPresented: $navigateToSuccess) {
            OnboardingSuccessView()
        }
    }
}

struct DayIndicator: View {
    let day: Int
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted || isCurrent ? Color.primary : Color.clear)
                .frame(width: 32, height: 32)

            if !isCompleted && !isCurrent {
                Circle()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            Text("\(day)")
                .font(.system(size: 12, weight: isCompleted || isCurrent ? .bold : .medium))
                .foregroundColor(isCompleted || isCurrent ? .white : .textSecondary)
        }
        .shadow(color: isCompleted || isCurrent ? Color.primary.opacity(0.3) : .clear, radius: 8)
    }
}

struct PhaseDescription: View {
    let title: String
    let subtitle: String
    let description: String
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isActive ? Color.primary : Color.clear)
                .strokeBorder(isActive ? Color.clear : Color.white.opacity(0.3), lineWidth: 1.5)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(title) \(subtitle)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textMain)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
```

### 3.5 Onboarding Success

**Design:** `onboarding_success_completion`

```swift
// StressMonitor/Views/Onboarding/OnboardingSuccessView.swift

struct OnboardingSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false

    var body: some View {
        ZStack {
            // Confetti background
            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Success content
                VStack(spacing: 24) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.successGreen.opacity(0.2))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.successGreen)
                    }

                    // Title
                    Text("You're All Set!")
                        .font(.system(size: 34, weight: .bold))
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("Your stress baseline is being calculated. Start measuring now!")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Action cards
                VStack(spacing: 0) {
                    ActionCard(
                        icon: "heart.fill",
                        iconColor: .healthRed,
                        title: "Take Your First Measurement",
                        subtitle: "Record your initial HRV"
                    ) {
                        // Navigate to measurement
                    }

                    Divider()
                        .padding(.leading, 64)

                    ActionCard(
                        icon: "bell.fill",
                        iconColor: .warningYellow,
                        title: "Set Reminders",
                        subtitle: "Build a healthy habit"
                    ) {
                        // Navigate to reminders
                    }
                }
                .background(Color.cardDark)
                .cornerRadius(16)
                .padding(.horizontal, 16)

                // CTA button
                VStack(spacing: 16) {
                    Button(action: { navigateToDashboard = true }) {
                        Text("Go to Dashboard")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .cornerRadius(28)
                    .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundDark)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDashboard) {
            MainTabView()
        }
    }
}

struct ConfettiView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill([
                            Color.primary,
                            Color.successGreen,
                            Color.warningYellow,
                            Color.healthRed
                        ].randomElement() ?? .primary)
                        .frame(width: CGFloat.random(in: 4...8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: isAnimating ? CGFloat.random(in: 0...geometry.size.height) : -50
                        )
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
}

struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textMain)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
        }
    }
}
```

---

## 4. Main Dashboard

### 4.1 Dashboard View

**Designs:** `dashboard_dark_mode`, `stress_dashboard_today_1`, `stress_dashboard_today_2`

```swift
// StressMonitor/Views/DashboardView.swift

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ZStack {
            // Background gradient effects
            VStack {
                LinearGradient(
                    colors: [Color.primary.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 256)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    DashboardHeader(
                        userName: viewModel.userName,
                        currentDate: viewModel.currentDate
                    )

                    // Stress ring card
                    StressRingCard(
                        stressLevel: viewModel.currentStress?.level ?? 0,
                        category: viewModel.currentStress?.category ?? .moderate,
                        confidence: viewModel.currentStress?.confidence,
                        onMeasure: { viewModel.triggerMeasurement() }
                    )

                    // Quick metrics grid
                    HStack(spacing: 12) {
                        MetricCard(
                            title: "HRV",
                            value: "\(Int(viewModel.currentHRV ?? 0))",
                            subtitle: "ms",
                            icon: "waveform.path",
                            iconColor: .successGreen,
                            trend: viewModel.hrvTrend,
                            chartData: viewModel.hrvHistory
                        )

                        MetricCard(
                            title: "Resting HR",
                            value: "\(Int(viewModel.restingHR ?? 0))",
                            subtitle: "bpm",
                            icon: "heart.fill",
                            iconColor: .healthRed,
                            trend: viewModel.hrTrend,
                            chartData: nil
                        )
                    }

                    // Weekly summary
                    WeeklySummaryCard(
                        averageStress: viewModel.weeklyAverage,
                        comparisonText: viewModel.weeklyComparisonText,
                        onTap: { /* Navigate to trends */ }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 104) // Header space
                .padding(.bottom, 100) // Tab bar space
            }
        }
        .background(Color.backgroundDark)
        .ignoresSafeArea()
        .task {
            await viewModel.loadDashboardData()
        }
    }
}

struct DashboardHeader: View {
    let userName: String
    let currentDate: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentDate.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)

                Text("Good Evening, \(userName)")
                    .font(.system(size: 24, weight: .bold))
            }

            Spacer()

            Button(action: { /* Profile */ }) {
                AsyncImage(url: URL(string: userProfileImageURL)) { image in
                    image.resizable()
                } placeholder: {
                    Circle()
                        .fill(Color.cardDark)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.backgroundDark.opacity(0.8),
            in: Rectangle()
        )
        .backdropBlur()
    }
}

struct StressRingCard: View {
    let stressLevel: Double
    let category: StressCategory
    let confidence: Double?
    let onMeasure: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Stress Score")
                    .font(.system(size: 12, weight: .semibold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary)

                Spacer()

                Button(action: { /* Info */ }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.primary)
                }
            }

            StressRingView(
                stressLevel: stressLevel,
                category: category,
                confidence: confidence
            )

            Button(action: onMeasure) {
                HStack(spacing: 8) {
                    Image(systemName: "vital_signs")
                    Text("Measure Now")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .cornerRadius(28)
                .shadow(color: Color.primary.opacity(0.2), radius: 12, y: 6)
            }
        }
        .padding(32)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

struct WeeklySummaryCard: View {
    let averageStress: Double
    let comparisonText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Average")
                        .font(.system(size: 17, weight: .semibold))
                    Text(comparisonText)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding(24)
        }
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}
```

---

## 5. History & Trends

### 5.1 History View

**Designs:** `history_and_patterns_1`, `history_and_patterns_2`, `trends_view_dark_mode`

```swift
// StressMonitor/Views/HistoryView.swift

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMeasurement: StressMeasurement?

    enum TimeRange: String, CaseIterable {
        case day = "24H"
        case week = "7D"
        case month = "4W"
        case quarter = "3M"
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("History")
                            .font(.system(size: 28, weight: .bold))

                        Spacer()

                        Button(action: { /* Calendar */ }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Time range selector
                    SegmentedControl(
                        selection: Binding(
                            get: { TimeRange.allCases.firstIndex(of: selectedTimeRange) ?? 1 },
                            set: { selectedTimeRange = TimeRange.allCases[$0] }
                        ),
                        options: TimeRange.allCases.map(\.rawValue)
                    )
                    .padding(.horizontal, 16)

                    // HRV trends chart
                    HRVTrendsCard(
                        data: viewModel.hrvData,
                        average: viewModel.hrvAverage,
                        dateRange: viewModel.dateRangeText,
                        timeRange: selectedTimeRange
                    )

                    // Stats
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Average",
                            value: "\(Int(viewModel.hrvAverage)) ms",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .primary
                        )

                        StatCard(
                            title: "Range",
                            value: "\(Int(viewModel.hrvMin))-\(Int(viewModel.hrvMax)) ms",
                            icon: "arrow.up.arrow.down",
                            iconColor: .primary
                        )
                    }

                    // Stress distribution
                    StressDistributionCard(
                        distribution: viewModel.stressDistribution
                    )

                    // Weekly insight
                    if let insight = viewModel.weeklyInsight {
                        InsightCard(insight: insight)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .task {
            await viewModel.loadData(timeRange: selectedTimeRange)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(measurement: measurement)
        }
    }
}

struct HRVTrendsCard: View {
    let data: [HRVDataPoint]
    let average: Double
    let dateRange: String
    let timeRange: HistoryView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRV Trends")
                        .font(.system(size: 12, weight: .semibold))
                        .uppercaseSmallCaps()
                        .foregroundColor(.textSecondary)

                    Text("\(Int(average)) ms avg")
                        .font(.system(size: 28, weight: .bold))
                }

                Spacer()

                Button(action: { /* Info */ }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.textSecondary)
                }
            }

            Text(dateRange)
                .font(.caption)
                .foregroundColor(.textSecondary)

            // Chart
            HRVLineChart(data: data)
                .frame(height: 192)

            // X-axis labels
            HStack {
                ForEach(viewModel.xAxisLabels(for: timeRange), id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    if label != viewModel.xAxisLabels(for: timeRange).last {
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

struct HRVLineChart: View {
    let data: [HRVDataPoint]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                ForEach(0..<5) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }

                // Line and area
                Path { path in
                    guard !data.isEmpty else { return }

                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step = width / CGFloat(max(data.count - 1, 1))

                    let minHRV = data.map(\.value).min() ?? 0
                    let maxHRV = data.map(\.value).max() ?? 100
                    let range = maxHRV - minHRV

                    func y(for value: Double) -> CGFloat {
                        height - CGFloat((value - minHRV) / range) * height * 0.8 - height * 0.1
                    }

                    // Move to first point
                    path.move(to: CGPoint(x: 0, y: y(for: data[0].value)))

                    // Add lines
                    for (index, point) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: point.value)))
                    }
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Gradient fill
                // (Similar path but closed at bottom)
            }
        }
    }
}

struct StressDistributionCard: View {
    let distribution: [StressCategory: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Level Distribution")
                .font(.system(size: 17, weight: .bold))

            VStack(spacing: 12) {
                ForEach([StressCategory.relaxed, .mild, .moderate, .high], id: \.self) { category in
                    DistributionRow(
                        category: category,
                        percentage: distribution[category] ?? 0
                    )
                }
            }
        }
        .padding(20)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

struct DistributionRow: View {
    let category: StressCategory
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.stressColor(for: category).opacity(0.15))
                        Image(systemName: category.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(Color.stressColor(for: category))
                    }
                    .frame(width: 32, height: 32)

                    Text(category.displayName)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 14, weight: .bold))
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                Rectangle()
                    .fill(Color.stressColor(for: category))
                    .frame(width: max(0, (percentage / 100) * (UIScreen.main.bounds.width - 96)), height: 8)
                    .cornerRadius(4)
            }
        }
    }
}

struct InsightCard: View {
    let insight: WeeklyInsight

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.2))
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.primary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Insight")
                    .font(.system(size: 14, weight: .bold))

                Text(insight.text)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.1))
        .cornerRadius(12)
    }
}
```

### 5.2 Measurement History List

**Design:** `measurement_history_list`

```swift
// StressMonitor/Views/MeasurementHistoryListView.swift

struct MeasurementHistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MeasurementHistoryListViewModel
    @State private var selectedMeasurement: StressMeasurement?
    @State private var showFilter = false

    init(measurements: [StressMeasurement]) {
        _viewModel = State(initialValue: MeasurementHistoryListViewModel(measurements: measurements))
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { /* Back */ }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.primary)
                    }

                    Spacer()

                    Button(action: { showFilter = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.primary)
                    }

                    Button(action: { /* Delete */ }) {
                        Image(systemName: "trash")
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Text("History")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Content
                if viewModel.groupedMeasurements.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.sortedDates, id: \.self) { date in
                                Section {
                                    ForEach(viewModel.groupedMeasurements[date] ?? []) { measurement in
                                        MeasurementListItem(measurement: measurement) {
                                            selectedMeasurement = measurement
                                        }
                                    }
                                } header: {
                                    Text(date.formatted(date: .long))
                                        .font(.system(size: 11, weight: .semibold))
                                        .uppercaseSmallCaps()
                                        .foregroundColor(.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                        .background(Color.backgroundDark)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            FilterOptionsSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(measurement: measurement)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                Image(systemName: "chart.bar")
                    .font(.system(size: 36))
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 80)

            Text("No Measurements")
                .font(.system(size: 20, weight: .bold))

            Text("Take your first measurement to start tracking your stress levels history.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: { /* Measure */ }) {
                Text("Measure Now")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primary)
                    .cornerRadius(24)
            }
            .padding(.horizontal, 60)
        }
        .frame(maxHeight: .infinity)
    }
}
```

---

## 6. Breathing Exercises

### 6.1 Breathing Session View

**Designs:** `breathing_session_dark_mode`, `breathing_session_light_mode`

```swift
// StressMonitor/Views/BreathingSessionView.swift

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BreathingSessionViewModel()

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(Color.cardDark.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(24)

                Spacer()

                // Breathing orb
                BreathingOrbView(
                    phase: viewModel.phase,
                    duration: viewModel.cycleDuration
                )

                Spacer()

                // Bottom controls
                VStack(spacing: 32) {
                    // Timer
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 12, weight: .medium))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary.opacity(0.5))

                        Text(viewModel.remainingTime.formatted(date: .omitTime, time: .standard))
                            .font(.system(size: 32, weight: .light))
                            .monospacedDigit()
                    }

                    // End session button
                    Button(action: { viewModel.endSession() }) {
                        Text("End Session")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.cardDark)
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.startSession()
        }
    }
}

// ViewModel for breathing session
@Observable
class BreathingSessionViewModel {
    var phase: BreathingPhase = .inhale
    var remainingTime: TimeInterval = 120 // 2 minutes
    var cycleDuration: TimeInterval = 8 // 4-4-4-4 pattern

    private var timer: Timer?
    private var startTime: Date?

    func startSession() async {
        startTime = Date()

        // Cycle through phases
        await cyclePhases()
    }

    private func cyclePhases() async {
        let phases: [BreathingPhase] = [.inhale, .hold, .exhale, .hold]
        var index = 0

        while remainingTime > 0 {
            phase = phases[index % phases.count]
            index += 1

            try? await Task.sleep(nanoseconds: UInt64(cycleDuration / 4 * 1_000_000_000))
            remainingTime -= cycleDuration / 4
        }
    }

    func endSession() {
        timer?.invalidate()
        // Navigate to summary
    }
}
```

### 6.2 Breathing Summary View

**Designs:** `breathing_summary_dark_mode`, `breathing_summary_light_mode`

```swift
// StressMonitor/Views/BreathingSummaryView.swift

struct BreathingSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let sessionResult: BreathingSessionResult

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Session Complete")
                        .font(.system(size: 34, weight: .bold))

                    Text("Great job taking a moment for yourself.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 20) {
                        // HRV improvement card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("HRV Improvement")
                                    .font(.system(size: 12, weight: .semibold))
                                    .uppercaseSmallCaps()
                                    .foregroundColor(.textSecondary)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up")
                                    Text("+26%")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.successGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.successGreen.opacity(0.1))
                                .clipShape(Capsule())
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("+12ms")
                                    .font(.system(size: 44, weight: .bold))

                                Text("+26%")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.successGreen)
                            }

                            Text("Better than your average session")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(24)
                        .background(Color.cardDark)
                        .cornerRadius(24)

                        // Comparison chart
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("HRV Response")
                                    .font(.system(size: 17, weight: .bold))

                                Spacer()

                                Text("Session Avg: 57ms")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            HStack(alignment: .bottom, spacing: 60) {
                                // Before bar
                                VStack(spacing: 12) {
                                    Text("45ms")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.textSecondary)

                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 56, height: 100)
                                        .cornerRadius(16)

                                    Text("BEFORE")
                                        .font(.system(size: 11, weight: .semibold))
                                        .uppercaseSmallCaps()
                                        .foregroundColor(.textSecondary)
                                }

                                // After bar
                                VStack(spacing: 12) {
                                    Text("57ms")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)

                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(width: 56, height: 140)
                                        .cornerRadius(16)
                                        .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)

                                    Text("AFTER")
                                        .font(.system(size: 11, weight: .bold))
                                        .uppercaseSmallCaps()
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(height: 180)
                        }
                        .padding(24)
                        .background(Color.cardDark)
                        .cornerRadius(24)

                        // Stress level change badge
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.warningYellow.opacity(0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "vital_signs")
                                    .foregroundColor(.warningYellow)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stress Level")
                                    .font(.system(size: 9, weight: .bold))
                                    .uppercaseSmallCaps()
                                    .foregroundColor(.textSecondary)

                                HStack(spacing: 8) {
                                    Text("Elevated")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.warningYellow)
                                        .strikethrough()

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)

                                    Text("Normal")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.1))
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 32, height: 32)
                        }
                        .padding(16)
                        .background(Color.cardDark)
                        .cornerRadius(24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 200)
                }
            }

            // Bottom actions
            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .cornerRadius(28)
                .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)

                Button(action: { /* Share */ }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Result")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [Color.backgroundDark, Color.backgroundDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .navigationBarHidden(true)
    }
}

struct BreathingSessionResult {
    let hrvBefore: Double
    let hrvAfter: Double
    let stressBefore: StressCategory
    let stressAfter: StressCategory
}
```

---

## 7. Settings & Configuration

### 7.1 Settings View

**Designs:** `app_settings`, `app_configuration_settings_1`, `app_configuration_settings_2`

```swift
// StressMonitor/Views/SettingsView.swift

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings()
    @State private var showProfile = false
    @State private var showHealthAccess = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            // Profile section
            Section {
                Button(action: { showProfile = true }) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: settings.profileImageURL)) { image in
                            image.resizable()
                        } placeholder: {
                            Circle()
                                .fill(Color.cardDark)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.userName)
                                .font(.system(size: 20, weight: .semibold))

                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                Text("Baseline: \(settings.baselineRange)")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Measurements section
            Section("Measurements") {
                SettingsToggleRow(
                    icon: "watch.face",
                    iconColor: .blue,
                    title: "Auto-Measurement",
                    isOn: $settings.autoMeasurement
                )

                Button(action: { /* Reminders */ }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange)
                            Image(systemName: "alarm")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Reminders")
                            .font(.body)

                        Spacer()

                        Text(settings.reminderTime)
                            .foregroundColor(.textSecondary)

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 20))
                    }
                }
            }

            // Notifications section
            Section("Notifications") {
                SettingsToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .healthRed,
                    title: "Stress Alerts",
                    isOn: $settings.stressAlerts
                )

                Button(action: { /* Alert threshold */ }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple)
                            Image(systemName: "tuningfork")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Alert Threshold")
                            .font(.body)

                        Spacer()

                        Text(settings.alertThreshold.displayText)
                            .foregroundColor(.textSecondary)

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 20))
                    }
                }

                Text("Get notified when your stress levels exceed the configured threshold during resting periods.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .listRowInsets(EdgeInsets(top: 0, leading: 56, bottom: 8, trailing: 16))
            }

            // Display section
            Section("Display") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray)
                            Image(systemName: "moon.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Theme")
                            .font(.body)
                    }

                    // Theme picker
                    HStack(spacing: 4) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button(action: { settings.theme = theme }) {
                                Text(theme.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(settings.theme == theme ? .white : .textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        settings.theme == theme ? Color(UIColor.systemGray5) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(9)
                }
                .padding(.vertical, 4)
            }

            // Data & Privacy section
            Section("Data & Privacy") {
                Button(action: { showHealthAccess = true }) {
                    SettingsNavigationRow(
                        icon: "heart.text.square.fill",
                        iconColor: .healthRed,
                        title: "Health Access",
                        value: "Authorized"
                    )
                }

                SettingsToggleRow(
                    icon: "icloud.fill",
                    iconColor: Color(hex: "#38b7f7"),
                    title: "iCloud Sync",
                    isOn: $settings.iCloudSync
                )

                Button(action: { /* Export */ }) {
                    HStack(spacing: 12) {
                        Spacer().frame(width: 28)
                        Text("Export All Data")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.textSecondary)
                    }
                }

                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete All Data")
                            .font(.body)
                            .foregroundColor(.healthRed)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProfile) {
            ProfileSettingsView(settings: $settings)
        }
        .sheet(isPresented: $showHealthAccess) {
            HealthAccessSettingsView()
        }
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete data
            }
        } message: {
            Text("This will permanently delete all your measurements and settings. This action cannot be undone.")
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(.body)

            Spacer()

            if let value = value {
                Text(value)
                    .foregroundColor(.textSecondary)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.textSecondary)
                .font(.system(size: 20))
        }
    }
}

struct AppSettings {
    var userName: String = "John Doe"
    var profileImageURL: String = ""
    var baselineRange: String = "52-68 ms"
    var autoMeasurement: Bool = true
    var reminderTime: String = "Daily at 8 AM"
    var stressAlerts: Bool = true
    var alertThreshold: AlertThreshold = .high
    var theme: AppTheme = .dark
    var iCloudSync: Bool = true
}

enum AlertThreshold {
    case low
    case medium
    case high

    var displayText: String {
        switch self {
        case .low: return "Low (>60)"
        case .medium: return "Medium (>75)"
        case .high: return "High (>80)"
        }
    }
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
```

---

## 8. Measurement Details

### 8.1 Measurement Detail View

**Designs:** `measurement_details_view_1`, `measurement_details_view_2`, `single_measurement_detail`

```swift
// StressMonitor/Views/MeasurementDetailView.swift

struct MeasurementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let measurement: StressMeasurement
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.textSecondary)
                                .frame(width: 40, height: 40)
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("Today")
                                .font(.system(size: 12, weight: .semibold))
                                .uppercaseSmallCaps()
                                .foregroundColor(.textSecondary.opacity(0.6))

                            Text(measurement.timestamp, format: .dateTime.month().day().year())
                                .font(.system(size: 17, weight: .bold))
                        }

                        Spacer()

                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Stress level card
                    VStack(spacing: 16) {
                        Text("Stress Level")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Gauge
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.05), lineWidth: 8)

                            Circle()
                                .trim(from: 0, to: measurement.stressLevel / 100)
                                .stroke(
                                    Color.stressColor(for: measurement.category),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 4) {
                                Text("\(Int(measurement.stressLevel))")
                                    .font(.system(size: 48, weight: .bold))

                                Text("/ 100")
                                    .font(.system(size: 11, weight: .bold))
                                    .uppercaseSmallCaps()
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .frame(width: 192, height: 192)

                        // Status badge
                        HStack(spacing: 8) {
                            Image(systemName: measurement.category.iconName)
                            Text(measurement.category.displayName)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.stressColor(for: measurement.category))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.stressColor(for: measurement.category).opacity(0.1))
                        .clipShape(Capsule())

                        Text(measurement.insightText)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(Color.cardDark)
                    .cornerRadius(16)

                    // HRV analysis card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary.opacity(0.1))
                                    Image(systemName: "waveform.path")
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("HRV Analysis")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Heart Rate Variability")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }

                            Spacer()

                            if let trend = measurement.hrvTrend {
                                HStack(spacing: 4) {
                                    Image(systemName: trend.iconName)
                                    Text(trend.displayValue)
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(trend.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(measurement.hrv)) ms")
                                .font(.system(size: 32, weight: .bold))

                            // Range visualizer
                            HRVRangeVisualizer(
                                current: measurement.hrv,
                                baseline: measurement.baselineRange
                            )
                        }
                    }
                    .padding(24)
                    .background(Color.cardDark)
                    .cornerRadius(16)

                    // Contributing factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contributing Factors")
                            .font(.system(size: 12, weight: .semibold))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 8)

                        FactorRow(
                            name: "HRV Deviation",
                            value: "High",
                            percentage: 0.75,
                            color: .textMain
                        )

                        FactorRow(
                            name: "Resting HR",
                            value: "\(Int(measurement.heartRate)) bpm",
                            percentage: 0.45,
                            color: .primary
                        )

                        FactorRow(
                            name: "Sleep Quality",
                            value: "Fair",
                            percentage: 0.60,
                            color: .warningYellow
                        )

                        FactorRow(
                            name: "Activity",
                            value: "Low",
                            percentage: 0.30,
                            color: .textSecondary
                        )
                    }
                    .padding(20)
                    .background(Color.cardDark)
                    .cornerRadius(16)

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(.system(size: 12, weight: .semibold))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 8)

                        ForEach(measurement.recommendations, id: \.self) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                    .padding(20)
                    .background(Color.cardDark)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [measurement.shareText])
        }
    }
}

struct HRVRangeVisualizer: View {
    let current: Double
    let baseline: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                // Baseline range indicator
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(
                        width: (baseline.upperBound - baseline.lowerBound) / 100 * (UIScreen.main.bounds.width - 64),
                        height: 8
                    )
                    .cornerRadius(4)
                    .offset(x: (baseline.lowerBound / 100) * (UIScreen.main.bounds.width - 64))

                // Current value marker
                Circle()
                    .fill(Color.primary)
                    .frame(width: 16, height: 16)
                    .offset(x: (current / 100) * (UIScreen.main.bounds.width - 64) - 8)
                    .shadow(radius: 4)
            }

            HStack {
                Text("0ms")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("Baseline: \(Int(baseline.lowerBound))-\(Int(baseline.upperBound))ms")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .bold()

                Spacer()

                Text("100ms")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.top, 16)
    }
}

struct FactorRow: View {
    let name: String
    let value: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .medium))

                Spacer()

                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1))
                    .foregroundColor(color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                Rectangle()
                    .fill(color)
                    .frame(width: max(0, percentage * (UIScreen.main.bounds.width - 64)), height: 8)
                    .cornerRadius(4)
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: String

    var body: some View {
        Button(action: { /* Handle recommendation */ }) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Breathing Exercise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Take a 5-minute resonance breathing break.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

extension StressMeasurement {
    var shareText: String {
        """
        My Stress Measurement - StressMonitor

        Date: \(timestamp.formatted())
        Stress Level: \(Int(stressLevel))/100
        HRV: \(Int(hrv))ms

        Track your stress with HRV analysis.
        """
    }
}
```

---

## 9. Home Screen Widgets

**Designs:** `home_screen_widgets_dark`, `home_screen_widgets_light`

```swift
// StressMonitorWidget/Widgets/StressMonitorWidget.swift

struct StressMonitorWidget: Widget {
    let kind: String = "StressMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressMonitorProvider()) { entry in
            StressMonitorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stress Monitor")
        .description("Track your stress levels at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StressMonitorWidgetEntryView: View {
    var entry: StressMonitorProvider.Entry

    var body: some View {
        switch entry.family {
        case .systemSmall:
            SmallWidget(entry: entry)
        case .systemMedium:
            MediumWidget(entry: entry)
        default:
            EmptyView()
        }
    }
}

struct SmallWidget: View {
    let entry: StressMonitorProvider.Entry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.primary.opacity(0.2), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                // App icon
                HStack {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Stress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: entry.stressLevel / 100)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(entry.stressLevel))")
                            .font(.system(size: 28, weight: .bold))
                        Text(entry.category.displayName.uppercased())
                            .font(.system(size: 8))
                    }
                }
                .frame(width: 80, height: 80)

                Spacer()

                Text("Stress Score")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .padding(12)
        }
    }
}

struct MediumWidget: View {
    let entry: StressMonitorProvider.Entry

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Current stress
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "vital_signs")
                        .font(.system(size: 12))
                    Text("Current")
                        .font(.system(size: 9))
                        .uppercaseSmallCaps()
                }
                .foregroundColor(.textSecondary)

                Text("\(Int(entry.stressLevel))")
                    .font(.system(size: 28, weight: .bold))

                // Mini ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.stressLevel / 100)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "bolt.fill")
                        .foregroundColor(.white)
                }
                .frame(width: 56, height: 56)

                Spacer()

                Text("-2% vs Avg")
                    .font(.caption)
                    .foregroundColor(.successGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(12)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1)

            // Right side: HRV trend
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HRV Trend")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Last 24 Hours")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Sparkline
                HRVSparkline(data: entry.hrvHistory)
                    .frame(height: 48)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg")
                            .font(.system(size: 8))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary)
                        Text("\(Int(entry.hrvAverage))ms")
                            .font(.caption)
                            .bold()
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Max")
                            .font(.system(size: 8))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary)
                        Text("\(Int(entry.hrvMax))ms")
                            .font(.caption)
                            .bold()
                    }

                    Text("Updated 2m ago")
                        .font(.system(size: 8))
                        .foregroundColor(.textSecondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
    }
}

struct HRVSparkline: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }

                let width = geometry.size.width
                let height = geometry.size.height
                let step = width / CGFloat(max(data.count - 1, 1))

                let min = data.min() ?? 0
                let max = data.max() ?? 100
                let range = max - min

                func y(for value: Double) -> CGFloat {
                    height - CGFloat((value - min) / range) * height
                }

                path.move(to: CGPoint(x: 0, y: y(for: data[0])))

                for (index, value) in data.dropFirst().enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(index + 1) * step, y: y(for: value)))
                }
            }
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// Widget Provider
struct StressMonitorProvider: TimelineProvider {
    func placeholder(in context: Context) -> StressEntry {
        StressEntry(date: Date(), stressLevel: 45, category: .moderate)
    }

    func getSnapshot(in context: Context, completion: @escaping (StressEntry) -> Void) {
        let entry = StressEntry(date: Date(), stressLevel: 45, category: .moderate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StressEntry>) -> Void) {
        // Fetch latest data and create timeline
        let currentDate = Date()
        let entry = StressEntry(
            date: currentDate,
            stressLevel: /* fetch from app */,
            category: /* calculate */,
            hrvHistory: /* fetch */,
            hrvAverage: /* calculate */,
            hrvMax: /* calculate */
        )

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct StressEntry: TimelineEntry {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
    let hrvHistory: [Double] = []
    let hrvAverage: Double = 60
    let hrvMax: Double = 75
}
```

---

## 10. Error States

### 10.1 HealthKit Access Error

**Design:** `healthkit_access_error_state`

```swift
// StressMonitor/Views/ErrorStates/HealthKitAccessErrorView.swift

struct HealthKitAccessErrorView: View {
    @Environment(\.dismiss) private var dismiss
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                }

                // Text
                VStack(spacing: 12) {
                    Text("Health Access Required")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("StressMonitor requires access to your HealthKit data to track your HRV and stress levels accurately. Please enable permissions in Settings to continue.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    Button(action: onOpenSettings) {
                        Text("Open Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary)
                    .cornerRadius(26)
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)

                    Button(action: onRetry) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}
```

---

## 11. Navigation Structure

### 11.1 Main Tab View

```swift
// StressMonitor/Views/MainTabView.swift

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case history
        case meditate
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(Tab.dashboard)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)

            BreathingSessionView()
                .tabItem {
                    Label("Meditate", systemImage: "wind")
                }
                .tag(Tab.meditate)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.primary)
    }
}
```

---

## 12. Data Models

### 12.1 Core Models

```swift
// StressMonitor/Models/StressMeasurement.swift

@Model
final class StressMeasurement {
    var timestamp: Date
    var stressLevel: Double  // 0-100
    var hrv: Double
    var heartRate: Double
    var confidence: Double
    var category: StressCategory

    var baselineRange: ClosedRange<Double> = 50...75

    init(timestamp: Date, stressLevel: Double, hrv: Double, heartRate: Double, confidence: Double, category: StressCategory) {
        self.timestamp = timestamp
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.heartRate = heartRate
        self.confidence = confidence
        self.category = category
    }

    var insightText: String {
        switch category {
        case .relaxed:
            return "Your stress levels are lower than usual for this time of day."
        case .mild:
            return "Your stress is within a healthy range."
        case .moderate:
            return "Your stress levels are higher than usual for this time of day."
        case .high:
            return "Consider taking a break to reduce your stress levels."
        case .severe:
            return "Your stress levels are elevated. Consider a breathing exercise."
        }
    }

    var recommendations: [String] {
        switch category {
        case .relaxed, .mild:
            return ["Keep up the good work!"]
        case .moderate:
            return ["Breathing Exercise", "Take a short walk"]
        case .high, .severe:
            return ["Breathing Exercise", "Hydration", "Rest"]
        }
    }

    var hrvTrend: MetricTrend? {
        // Would compare with previous measurements
        return nil
    }
}

enum StressCategory: String, Codable {
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
}
```

---

## 13. Testing Requirements

### 13.1 UI Tests

- Verify all screens render correctly in both light and dark modes
- Test navigation flows between all screens
- Validate accessibility labels and traits
- Test Dynamic Type scaling
- Verify haptic feedback triggers

### 13.2 Component Tests

- Test StressRingView with different values
- Verify BreathingOrbView animation timing
- Test MetricCard with various data states
- Validate chart rendering with edge cases

### 13.3 Integration Tests

- Test onboarding flow from start to finish
- Verify measurement creation and display
- Test settings persistence
- Validate widget data updates

---

## Implementation Order

### Phase 1: Foundation (Week 1-2)
1. Design tokens and theme setup
2. Base components (StressRingView, MetricCard, etc.)
3. Data models and repositories
4. Navigation structure

### Phase 2: Core Features (Week 3-4)
1. Onboarding flow (all 13 screens)
2. Dashboard view
3. Settings screens
4. Error states

### Phase 3: Advanced Features (Week 5-6)
1. History and trends views
2. Measurement details
3. Breathing exercises
4. Home screen widgets

### Phase 4: Polish (Week 7-8)
1. Animations and transitions
2. Accessibility improvements
3. Performance optimization
4. Testing and bug fixes

---

## File Structure

```
StressMonitor/
├── Theme/
│   ├── Color+Extensions.swift
│   ├── DesignTokens.swift
│   ├── Typography.swift
│   └── Spacing.swift
├── Views/
│   ├── Components/
│   │   ├── StressRingView.swift
│   │   ├── MetricCard.swift
│   │   ├── SegmentedControl.swift
│   │   ├── BreathingOrbView.swift
│   │   ├── SettingsRow.swift
│   │   └── MeasurementListItem.swift
│   ├── Onboarding/
│   │   ├── WelcomeStep1View.swift
│   │   ├── WelcomeStep2View.swift
│   │   ├── HealthSyncPermissionView.swift
│   │   ├── BaselineCalibrationView.swift
│   │   └── OnboardingSuccessView.swift
│   ├── DashboardView.swift
│   ├── HistoryView.swift
│   ├── BreathingSessionView.swift
│   ├── BreathingSummaryView.swift
│   ├── SettingsView.swift
│   ├── MeasurementDetailView.swift
│   ├── MainTabView.swift
│   └── ErrorStates/
│       └── HealthKitAccessErrorView.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── BreathingSessionViewModel.swift
│   └── SettingsViewModel.swift
└── Models/
    ├── StressMeasurement.swift
    └── StressCategory.swift
```

---

## Notes

- All colors must support WCAG AA accessibility standards
- Use SF Symbols for icons, fallback to Material Symbols when needed
- All animations should respect Reduce Motion setting
- Support Dynamic Type from Extra Small to XXXL
- Haptic feedback for key interactions (measurements, milestones)
