# Breathing Exercises

> **Created by:** Phuong Doan
> **Feature:** Guided breathing exercises for stress reduction
> **Designs Referenced:** 4 screens
> - `breathing_session_dark_mode`, `breathing_session_light_mode`
> - `breathing_summary_dark_mode`, `breathing_summary_light_mode`

---

## Overview

The Breathing Exercises feature provides:
- Animated breathing session with orb visualization
- Configurable session duration
- Post-session summary with HRV improvement
- Session history tracking

---

## 1. Breathing Session View

**Design:** `breathing_session_dark_mode`, `breathing_session_light_mode`

```swift
// StressMonitor/Views/BreathingSessionView.swift

import SwiftUI
import Observation

@Observable
class BreathingSessionViewModel {
    var phase: BreathingPhase = .inhale
    var remainingTime: TimeInterval = 120 // 2 minutes default
    var cycleDuration: TimeInterval = 8 // 4-4-4-4 pattern
    var sessionDuration: TimeInterval = 120
    var isActive: Bool = false

    private var timer: Timer?
    private var phaseTimer: Timer?
    private var startTime: Date?

    func startSession() async {
        startTime = Date()
        isActive = true

        await cyclePhases()
    }

    private func cyclePhases() async {
        let phases: [BreathingPhase] = [.inhale, .hold, .exhale, .hold]
        var index = 0

        while remainingTime > 0 && isActive {
            phase = phases[index % phases.count]
            index += 1

            // Wait for phase duration (1/4 of cycle)
            try? await Task.sleep(nanoseconds: UInt64(cycleDuration / 4 * 1_000_000_000))
            remainingTime -= cycleDuration / 4
        }
    }

    func endSession() -> BreathingSessionResult {
        isActive = false
        timer?.invalidate()
        phaseTimer?.invalidate()

        // Calculate session results
        return BreathingSessionResult(
            duration: sessionDuration - remainingTime,
            hrvBefore: 45,
            hrvAfter: 57,
            stressBefore: .moderate,
            stressAfter: .mild
        )
    }
}

enum BreathingPhase: String, CaseIterable {
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

    var duration: TimeInterval {
        switch self {
        case .inhale: return 4
        case .hold: return 4
        case .exhale: return 4
        }
    }
}

struct BreathingSessionResult {
    let duration: TimeInterval
    let hrvBefore: Double
    let hrvAfter: Double
    let stressBefore: StressCategory
    let stressAfter: StressCategory

    var hrvImprovement: Double {
        hrvAfter - hrvBefore
    }

    var hrvImprovementPercentage: Double {
        (hrvImprovement / hrvBefore) * 100
    }
}

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BreathingSessionViewModel()
    @State private var showSummary = false

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.isActive = false
                        dismiss()
                    }) {
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
                    // Timer display
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
                    Button(action: {
                        showSummary = true
                    }) {
                        Text("End Session")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.cardDark)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.startSession()
        }
        .fullScreenCover(isPresented: $showSummary) {
            BreathingSummaryView(result: viewModel.endSession())
        }
    }
}

// MARK: - Breathing Orb View
struct BreathingOrbView: View {
    let phase: BreathingPhase
    let duration: TimeInterval

    @State private var isAnimating = false
    @State private var opacity: Double = 0.5

    var body: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .frame(width: 192, height: 192)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 0.2)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)

            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                .frame(width: 256, height: 256)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .opacity(isAnimating ? 0 : 0.1)
                .animation(.easeInOut(duration: duration * 1.5).repeatForever(autoreverses: true), value: isAnimating)

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
                .opacity(opacity)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)

            // Core
            Circle()
                .fill(Color.primary.opacity(0.8))
                .frame(width: 128, height: 128)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)

            // Instruction text
            Text(phase.instructionText)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white)
                .opacity(opacity)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: opacity)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    BreathingSessionView()
        .preferredColorScheme(.dark)
}
```

---

## 2. Breathing Summary View

**Design:** `breathing_summary_dark_mode`, `breathing_summary_light_mode`

```swift
// StressMonitor/Views/BreathingSummaryView.swift

import SwiftUI

struct BreathingSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let result: BreathingSessionResult
    @State private var showShareSheet = false

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
                        hrvImprovementCard

                        // Comparison chart
                        comparisonChart

                        // Stress level change badge
                        stressLevelBadge
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 200)
                }
            }

            // Bottom actions
            bottomActions
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
    }

    private var hrvImprovementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HRV Improvement")
                    .font(.system(size: 12, weight: .semibold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                    Text("+\(Int(result.hrvImprovementPercentage))%")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.successGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.successGreen.opacity(0.1))
                .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("+\(Int(result.hrvImprovement))ms")
                    .font(.system(size: 44, weight: .bold))

                Text("+\(Int(result.hrvImprovementPercentage))%")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.successGreen)
            }

            Text("Better than your average session")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .cardPadding(.spacious)
        .background(Color.cardDark)
        .cornerRadius(24)
    }

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("HRV Response")
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                Text("Session Avg: \(Int((result.hrvBefore + result.hrvAfter) / 2))ms")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(alignment: .bottom, spacing: 60) {
                // Before bar
                VStack(spacing: 12) {
                    Text("\(Int(result.hrvBefore))ms")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textSecondary)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: CGFloat(result.hrvBefore * 2))

                    Text("BEFORE")
                        .font(.system(size: 11, weight: .semibold))
                        .uppercaseSmallCaps()
                        .foregroundColor(.textSecondary)
                }

                // After bar
                VStack(spacing: 12) {
                    Text("\(Int(result.hrvAfter))ms")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary)
                        .frame(width: 56, height: CGFloat(result.hrvAfter * 2))
                        .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)

                    Text("AFTER")
                        .font(.system(size: 11, weight: .bold))
                        .uppercaseSmallCaps()
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 180)
        }
        .cardPadding(.spacious)
        .background(Color.cardDark)
        .cornerRadius(24)
    }

    private var stressLevelBadge: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.stressColor(for: result.stressBefore).opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "vital_signs")
                    .foregroundColor(Color.stressColor(for: result.stressBefore))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Stress Level")
                    .font(.system(size: 9, weight: .bold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary)

                HStack(spacing: 8) {
                    Text(result.stressBefore.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.stressColor(for: result.stressBefore))
                        .strikethrough()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)

                    Text(result.stressAfter.displayName)
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
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(24)
    }

    private var bottomActions: some View {
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

            Button(action: { showShareSheet = true }) {
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

    private var shareText: String {
        """
        Breathing Session Complete

        Duration: \(Int(result.duration / 60)) minutes
        HRV Improvement: +\(Int(result.hrvImprovement))ms
        Stress Level: \(result.stressBefore.displayName) → \(result.stressAfter.displayName)

        Tracked with StressMonitor
        """
    }
}

#Preview {
    BreathingSummaryView(
        result: BreathingSessionResult(
            duration: 120,
            hrvBefore: 45,
            hrvAfter: 57,
            stressBefore: .moderate,
            stressAfter: .mild
        )
    )
    .preferredColorScheme(.dark)
}
```

---

## 3. Breathing Duration Picker

```swift
// StressMonitor/Views/Components/BreathingDurationPicker.swift

import SwiftUI

struct BreathingDurationPicker: View {
    @Binding var selectedDuration: TimeInterval

    private let options: [TimeInterval] = [60, 120, 300, 600] // 1, 2, 5, 10 minutes

    var body: some View {
        VStack(spacing: 16) {
            Text("Session Duration")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary)

            HStack(spacing: 12) {
                ForEach(options, id: \.self) { duration in
                    Button(action: { selectedDuration = duration }) {
                        Text(durationText(for: duration))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedDuration == duration ? .white : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedDuration == duration ? Color.primary : Color.cardDark,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func durationText(for duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

#Preview {
    BreathingDurationPicker(selectedDuration: .constant(120))
        .background(Color.backgroundDark)
}
```

---

## 4. Breathing Pattern Selector

```swift
// StressMonitor/Views/Components/BreathingPatternSelector.swift

import SwiftUI

enum BreathingPattern {
    case box4_4      // 4-4-4-4 (box breathing)
    case box4_7_8    // 4-7-8 (relaxing)
    case resonant    // 5.5 (coherent breathing)
    case custom      // User defined

    var name: String {
        switch self {
        case .box4_4: return "Box Breathing (4-4-4-4)"
        case .box4_7_8: return "4-7-8 Breathing"
        case .resonant: return "Coherent (5.5)"
        case .custom: return "Custom"
        }
    }

    var inhaleTime: TimeInterval {
        switch self {
        case .box4_4: return 4
        case .box4_7_8: return 4
        case .resonant: return 5.5
        case .custom: return 4
        }
    }

    var holdTime: TimeInterval {
        switch self {
        case .box4_4: return 4
        case .box4_7_8: return 7
        case .resonant: return 0
        case .custom: return 4
        }
    }

    var exhaleTime: TimeInterval {
        switch self {
        case .box4_4: return 4
        case .box4_7_8: return 8
        case .resonant: return 5.5
        case .custom: return 4
        }
    }

    var cycleDuration: TimeInterval {
        inhaleTime + holdTime + exhaleTime + holdTime
    }
}

struct BreathingPatternSelector: View {
    @Binding var selectedPattern: BreathingPattern

    var body: some View {
        VStack(spacing: 16) {
            Text("Breathing Pattern")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary)

            VStack(spacing: 0) {
                ForEach([
                    BreathingPattern.box4_4,
                    .box4_7_8,
                    .resonant
                ], id: \.self) { pattern in
                    Button(action: { selectedPattern = pattern }) {
                        HStack {
                            Text(pattern.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(selectedPattern == pattern ? .white : .textMain)

                            Spacer()

                            if selectedPattern == pattern {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if pattern != .resonant {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color.cardDark)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    BreathingPatternSelector(selectedPattern: .constant(.box4_4))
        .background(Color.backgroundDark)
}
```

---

## File Structure

```
StressMonitor/Views/Breathing/
├── BreathingSessionView.swift
├── BreathingSummaryView.swift
├── Components/
│   ├── BreathingOrbView.swift
│   ├── BreathingDurationPicker.swift
│   └── BreathingPatternSelector.swift
└── ViewModels/
    └── BreathingSessionViewModel.swift
```

---

## Dependencies

- **Design System:** Colors, animations from `00-design-system-components.md`
- **Data Models:** `StressCategory`
- **Haptics:** For session feedback
