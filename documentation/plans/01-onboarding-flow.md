# Onboarding Flow

> **Created by:** Phuong Doan
> **Feature:** User onboarding and app setup
> **Designs Referenced:** 13 screens
> - `onboarding_welcome_step_1`, `onboarding_welcome_step_2`
> - `onboarding_health_sync_1`, `onboarding_health_sync_2`
> - `onboarding_baseline_calibration_1` through `9`
> - `onboarding_success_completion`

---

## Overview

The onboarding flow guides new users through:
1. Welcome and app introduction
2. HealthKit permissions
3. 7-day baseline calibration setup
4. Success completion and first actions

---

## 1. Welcome Step 1

**Design:** `onboarding_welcome_step_1`

```swift
// StressMonitor/Views/Onboarding/WelcomeStep1View.swift

import SwiftUI

struct WelcomeStep1View: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToStep2 = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle (for modal presentation)
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 48, height: 6)
                .cornerRadius(3)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Hero illustration
                    heroIllustration

                    // Title
                    Text("Understand Your Stress")
                        .headerStyle(.large)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("Track your HRV and manage stress levels with professional insights.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    // Features list
                    featuresList
                }
            }

            // Bottom CTA
            bottomActions
        }
        .background(Color.backgroundDark)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToStep2) {
            WelcomeStep2View()
        }
    }

    private var heroIllustration: some View {
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
    }

    private var featuresList: some View {
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
        .padding(.horizontal, Spacing.xl)
    }

    private var bottomActions: some View {
        VStack(spacing: 16) {
            Button(action: { navigateToStep2 = true }) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)

            Text("Already have an account? [Sign in](#)")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding(.bottom, 32)
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

// MARK: - Preview
#Preview {
    WelcomeStep1View()
}
```

---

## 2. Welcome Step 2

**Design:** `onboarding_welcome_step_2`

Similar structure to Step 1, continuing feature highlights.

```swift
// StressMonitor/Views/Onboarding/WelcomeStep2View.swift

import SwiftUI

struct WelcomeStep2View: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHealthSync = false

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
                    // Hero illustration - different icon/illustration
                    heroSection

                    // Title
                    Text("Track Your Progress")
                        .headerStyle(.large)
                        .multilineTextAlignment(.center)

                    // Description
                    Text("Visualize your stress patterns over time and understand what affects your well-being.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Additional features
                    additionalFeatures
                }
            }

            // Bottom CTA
            VStack(spacing: 16) {
                Button(action: { navigateToHealthSync = true }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 24)

                Button(action: { dismiss() }) {
                    Text("Skip")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.backgroundDark)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToHealthSync) {
            HealthSyncPermissionView()
        }
    }

    private var heroSection: some View {
        ZStack {
            // Animated rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                    .frame(width: 160 + CGFloat(index * 40))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0 : 0.3)
            }

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundColor(.primary)
        }
        .frame(height: 192)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    @State private var isAnimating = false

    private var additionalFeatures: some View {
        VStack(alignment: .leading, spacing: 20) {
            FeatureRow(icon: "chart.bar.fill", title: "Detailed analytics", color: .primary)
            FeatureRow(icon: "calendar.badge.clock", title: "Historical trends", color: .primary)
            FeatureRow(icon: "bell.badge.fill", title: "Smart notifications", color: .primary)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    WelcomeStep2View()
}
```

---

## 3. Health Sync Permissions

**Designs:** `onboarding_health_sync_1`, `onboarding_health_sync_2`

```swift
// StressMonitor/Views/Onboarding/HealthSyncPermissionView.swift

import SwiftUI
import HealthKit

struct HealthSyncPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.healthKit) private var healthKit
    @State private var isLoading = false
    @State private var showError = false
    @State private var navigateToBaseline = false
    @State private var currentStep = 1

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            ProgressDots(currentStep: currentStep, totalSteps: 4)
                .padding(.top, 24)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    permissionIcon

                    // Title
                    Text("Health Data Access")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)

                    // Description
                    permissionDescription

                    // Data types list
                    dataTypesList
                }
            }

            // Bottom actions
            bottomActions
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

    private var permissionIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 12)

            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(.healthRed)

            // Status dot
            Circle()
                .fill(.healthRed)
                .frame(width: 24, height: 24)
                .offset(x: 40, y: -40)
        }
        .frame(width: 80, height: 80)
    }

    private var permissionDescription: some View {
        Text("StressMonitor needs access to your HealthKit data to analyze HRV and detect stress patterns accurately.")
            .font(.body)
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }

    private var dataTypesList: some View {
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

    private var bottomActions: some View {
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

            privacyNote
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
            Text("Your health data is processed locally on your device.")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.textSecondary.opacity(0.6))
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

#Preview {
    HealthSyncPermissionView()
}
```

---

## 4. Baseline Calibration (7-Day Flow)

**Designs:** `onboarding_baseline_calibration_1` through `9`

```swift
// StressMonitor/Views/Onboarding/BaselineCalibrationView.swift

import SwiftUI

struct BaselineCalibrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentDay = 1
    @State private var calibrationPhase: CalibrationPhase = .learning
    @State private var navigateToSuccess = false

    enum CalibrationPhase {
        case learning    // Days 1-3
        case calibrating // Days 4-5
        case validation // Days 6-7

        var daysRange: ClosedRange<Int> {
            switch self {
            case .learning: return 1...3
            case .calibrating: return 4...5
            case .validation: return 6...7
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            ProgressDots(currentStep: 3, totalSteps: 4)
                .padding(.top, 24)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    titleSection

                    // Progress ring
                    progressRing

                    // 7-day timeline
                    dayTimeline

                    // Phase descriptions
                    phaseDescriptions
                }
            }

            // Bottom actions
            bottomActions
        }
        .background(Color.backgroundDark)
        .navigationDestination(isPresented: $navigateToSuccess) {
            OnboardingSuccessView()
        }
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Set Your Baseline")
                .headerStyle(.large)

            Text("To personalize your stress insights, we need to learn your body's patterns over the next 7 days.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var progressRing: some View {
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
    }

    private var dayTimeline: some View {
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
        }
        .padding(24)
        .background(Color.cardDark)
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    private var phaseDescriptions: some View {
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
        .padding(.bottom, 8)
    }

    private var bottomActions: some View {
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

#Preview {
    BaselineCalibrationView()
}
```

---

## 5. Calibration Day Screens (Days 1-9)

Each day shows a progress update and encourages measurement.

```swift
// StressMonitor/Views/Onboarding/CalibrationDayView.swift

import SwiftUI

struct CalibrationDayView: View {
    let dayNumber: Int
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToNext = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            ProgressDots(currentStep: 3, totalSteps: 4)
                .padding(.top, 24)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 32) {
                    // Day badge
                    dayBadge

                    // Progress message
                    progressMessage

                    // Encouragement
                    encouragementCard

                    // Take measurement CTA
                    measurementCTA
                }
                .padding(.horizontal, 24)
            }

            // Skip button
            skipButton
        }
        .background(Color.backgroundDark)
    }

    private var dayBadge: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 120, height: 120)

            VStack(spacing: 4) {
                Text("Day")
                    .font(.caption)
                    .uppercaseSmallCaps()
                    .foregroundColor(.primary)

                Text("\(dayNumber)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 32)
    }

    private var progressMessage: some View {
        VStack(spacing: 12) {
            Text(dayNumber <= 3 ? "Learning Phase" : dayNumber <= 5 ? "Calibrating" : "Validation")
                .font(.title2)
                .foregroundColor(.primary)

            Text(dayNumber <= 3 ? "Building your baseline profile..." : "Fine-tuning your stress patterns...")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var encouragementCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warningYellow)
                Text("Tip for Today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                Spacer()
            }

            Text(encouragementText)
                .font(.subheadline)
                .foregroundColor(.textMain)
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var encouragementText: String {
        switch dayNumber {
        case 1:
            return "Take your first measurement at a consistent time each day for best results."
        case 2:
            return "Try to measure at the same time as yesterday to establish a pattern."
        case 3:
            return "Your initial data is being collected. Keep up the consistency!"
        case 4:
            return "We're now identifying your personal stress triggers."
        case 5:
            return "Continue measuring to help us understand your recovery patterns."
        case 6:
            return "We're validating your baseline. Almost there!"
        case 7:
            return "Final day! This measurement completes your baseline."
        default:
            return "Keep measuring to refine your personalized insights."
        }
    }

    private var measurementCTA: some View {
        Button(action: { /* Trigger measurement */ }) {
            HStack(spacing: 12) {
                Image(systemName: "vital_signs")
                Text("Take Measurement")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.primary)
            .cornerRadius(28)
            .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)
        }
    }

    private var skipButton: some View {
        Button(action: { dismiss() }) {
            Text("Skip for now")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding(.bottom, 32)
    }
}

#Preview("Day 1") {
    CalibrationDayView(dayNumber: 1)
}

#Preview("Day 5") {
    CalibrationDayView(dayNumber: 5)
}
```

---

## 6. Onboarding Success

**Design:** `onboarding_success_completion`

```swift
// StressMonitor/Views/Onboarding/OnboardingSuccessView.swift

import SwiftUI

struct OnboardingSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti background
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Success content
                VStack(spacing: 24) {
                    // Success icon
                    successIcon

                    // Title and subtitle
                    VStack(spacing: 12) {
                        Text("You're All Set!")
                            .font(.system(size: 34, weight: .bold))

                        Text("Your stress baseline is being calculated. Start measuring now!")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // Action cards
                actionCards

                // CTA button
                ctaButton
            }
        }
        .background(Color.backgroundDark)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDashboard) {
            MainTabView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
                showConfetti = true
            }
        }
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.successGreen.opacity(0.2))
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.successGreen)
        }
    }

    private var actionCards: some View {
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
    }

    private var ctaButton: some View {
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

// MARK: - Confetti Effect
struct ConfettiView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    Circle()
                        .fill([
                            Color.primary,
                            Color.successGreen,
                            Color.warningYellow,
                            Color.healthRed
                        ].randomElement() ?? .primary)
                        .frame(width: CGFloat.random(in: 4...8))
                        .offset(
                            x: isAnimating ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                            y: isAnimating ? CGFloat.random(in: 0...geometry.size.height) : -50
                        )
                        .opacity(isAnimating ? 0 : 1)
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

#Preview {
    OnboardingSuccessView()
}
```

---

## File Structure

```
StressMonitor/Views/Onboarding/
├── WelcomeStep1View.swift
├── WelcomeStep2View.swift
├── HealthSyncPermissionView.swift
├── BaselineCalibrationView.swift
├── CalibrationDayView.swift
├── OnboardingSuccessView.swift
└── Components/
    ├── FeatureRow.swift
    ├── DataTypeRow.swift
    ├── DayIndicator.swift
    ├── PhaseDescription.swift
    ├── ActionCard.swift
    └── ConfettiView.swift
```

---

## Onboarding Flow Summary

| Step | Screen | Description |
|------|--------|-------------|
| 1 | Welcome Step 1 | App introduction and key features |
| 2 | Welcome Step 2 | Progress tracking overview |
| 3 | Health Sync | HealthKit permissions request |
| 4 | Baseline Setup | 7-day calibration explanation |
| 5-11 | Calibration Days 1-7 | Daily measurement prompts |
| 12 | Success | Completion and first actions |

---

## Dependencies

- **Design System:** Colors, typography, spacing from `00-design-system-components.md`
- **HealthKit:** For requesting and accessing health data
- **Navigation:** Uses `NavigationStack` for iOS 16+
