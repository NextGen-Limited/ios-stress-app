import SwiftUI

// MARK: - Breathing Exercise View

/// 4-7-8 Breathing Exercise Screen
/// Implements: 4s inhale, 7s hold, 8s exhale, 1s pause between cycles
/// Full Reduce Motion support with static circle and text instructions
struct BreathingExerciseView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dismiss) var dismiss
    @State private var phase: BreathingPhase = .inhale
    @State private var cycleCount: Int = 0
    @State private var isPaused: Bool = false
    @State private var timer: Timer?
    @State private var progress: Double = 0
    @State private var isCancelled = false

    private let totalCycles = 4
    private let maxCycles = 4

    var body: some View {
        ZStack {
            Color.Wellness.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    headerSection

                    breathingCircleSection

                    progressSection

                    instructionSection

                    tipsSection

                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
            }

            controlButtons
        }
        .onAppear {
            startBreathingSession()
        }
        .onDisappear {
            stopBreathingSession()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Button(action: {
                    HapticManager.shared.buttonPress()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: DesignTokens.Layout.minTouchTarget, height: DesignTokens.Layout.minTouchTarget)
                .accessibilityLabel("Close breathing exercise")

                Spacer()

                Text("Breathing Exercise")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                Color.clear
                    .frame(width: DesignTokens.Layout.minTouchTarget, height: DesignTokens.Layout.minTouchTarget)
            }

            Text("4-7-8 Breathing Technique")
                .font(Typography.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Breathing Circle Section

    private var breathingCircleSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if reduceMotion {
                staticBreathingCircle
            } else {
                animatedBreathingCircle
            }

            Text(phase.displayText)
                .font(Typography.title1)
                .fontWeight(.bold)
                .foregroundStyle(phase.color)
                .accessibilityLabel("Breathing phase: \(phase.displayText)")
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(height: 300)
    }

    @ViewBuilder
    private var staticBreathingCircle: some View {
        ZStack {
            Circle()
                .fill(phase.color.opacity(0.2))
                .frame(width: 200, height: 200)

            Circle()
                .stroke(phase.color, lineWidth: 4)
                .frame(width: 200, height: 200)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: phase.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(phase.color)

                Text(phase.instruction)
                    .font(Typography.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.displayText). \(phase.instruction)")
    }

    @ViewBuilder
    private var animatedBreathingCircle: some View {
        ZStack {
            Circle()
                .fill(phase.color.opacity(0.2))
                .frame(width: 200, height: 200)
                .scaleEffect(circleScale)

            Circle()
                .stroke(phase.color, lineWidth: 4)
                .frame(width: 200, height: 200)
                .scaleEffect(circleScale)

            Image(systemName: phase.icon)
                .font(.system(size: 60))
                .foregroundStyle(phase.color)
        }
        .accessibilityHidden(true)
    }

    private var circleScale: CGFloat {
        switch phase {
        case .inhale:
            return progress
        case .hold:
            return 1.2
        case .exhale:
            return 1.2 - (progress * 0.4)
        case .pause:
            return 0.8
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Cycle \(cycleCount + 1) of \(totalCycles)")
                    .font(Typography.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(progress * phase.duration))s")
                    .font(Typography.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            ProgressView(value: progress)
                .tint(phase.color)
                .accessibilityLabel("Cycle progress: \(cycleCount + 1) of \(totalCycles)")
                .accessibilityValue("\(Int(progress * 100)) percent complete")
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }

    // MARK: - Instruction Section

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Breathing Pattern")
                .font(Typography.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                patternRow(icon: "arrow.down.circle.fill", text: "Inhale for 4 seconds", color: .blue)
                patternRow(icon: "pause.circle.fill", text: "Hold for 7 seconds", color: .purple)
                patternRow(icon: "arrow.up.circle.fill", text: "Exhale for 8 seconds", color: .green)
                patternRow(icon: "moon.circle.fill", text: "Pause for 1 second", color: .secondary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Breathing pattern: Inhale 4 seconds, Hold 7 seconds, Exhale 8 seconds, Pause 1 second")
    }

    private func patternRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: DesignTokens.Layout.minTouchTarget)

            Text(text)
                .font(Typography.callout)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Tips")
                .font(Typography.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                tipRow(icon: "heart.fill", text: "Focus on slow, deep breaths")
                tipRow(icon: "figure.mind.and.body", text: "Relax your shoulders and jaw")
                tipRow(icon: "moon.stars.fill", text: "Find a quiet, comfortable place")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.Wellness.calmBlue)
                .frame(width: 30)

            Text(text)
                .font(Typography.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        VStack {
            Spacer()

            Button(action: togglePause) {
                HStack {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)

                    Text(isPaused ? "Resume" : "Pause")
                        .font(Typography.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.Wellness.calmBlue)
                .cornerRadius(26)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xl)
            .accessibilityLabel(isPaused ? "Resume breathing exercise" : "Pause breathing exercise")
        }
    }

    // MARK: - Breathing Logic

    private func startBreathingSession() {
        guard !isPaused else { return }

        cycleCount = 0
        phase = .inhale
        progress = 0

        startPhaseTimer()
    }

    private func stopBreathingSession() {
        isCancelled = true
        timer?.invalidate()
        timer = nil
    }

    private func togglePause() {
        HapticManager.shared.buttonPress()
        isPaused.toggle()

        if isPaused {
            timer?.invalidate()
        } else {
            startPhaseTimer()
        }
    }

    private func startPhaseTimer() {
        timer?.invalidate()

        let updateInterval = 0.1
        var elapsed: Double = 0

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            guard !isCancelled && !isPaused else { return }

            elapsed += updateInterval
            progress = min(elapsed / phase.duration, 1.0)

            if elapsed >= phase.duration {
                advancePhase()
                elapsed = 0
                progress = 0
            }
        }
    }

    private func advancePhase() {
        HapticManager.shared.breathingCue()

        switch phase {
        case .inhale:
            phase = .hold
        case .hold:
            phase = .exhale
        case .exhale:
            phase = .pause
        case .pause:
            cycleCount += 1
            if cycleCount >= totalCycles {
                sessionComplete()
            } else {
                phase = .inhale
            }
        }
    }

    private func sessionComplete() {
        timer?.invalidate()
        HapticManager.shared.success()

        // Show completion state
        isPaused = true
    }
}

// MARK: - Breathing Phase

enum BreathingPhase {
    case inhale
    case hold
    case exhale
    case pause

    var duration: Double {
        switch self {
        case .inhale: return 4.0
        case .hold: return 7.0
        case .exhale: return 8.0
        case .pause: return 1.0
        }
    }

    var displayText: String {
        switch self {
        case .inhale: return "Inhale"
        case .hold: return "Hold"
        case .exhale: return "Exhale"
        case .pause: return "Pause"
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly through your nose"
        case .hold: return "Hold your breath gently"
        case .exhale: return "Breathe out slowly through your mouth"
        case .pause: return "Relax and prepare"
        }
    }

    var icon: String {
        switch self {
        case .inhale: return "arrow.down.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.up.circle.fill"
        case .pause: return "moon.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .inhale: return .blue
        case .hold: return .purple
        case .exhale: return .green
        case .pause: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    BreathingExerciseView()
}
