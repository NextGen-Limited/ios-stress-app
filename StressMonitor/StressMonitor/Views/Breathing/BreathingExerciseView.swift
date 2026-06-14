import SwiftUI

// MARK: - Box Breathing Exercise View

/// Box Breathing (4-4-4-4) exercise screen — Ripple redesign.
/// Dark canvas, Ripple breathing orb, phase pills, and Ripple guidance card.
struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRunning = false
    @State private var currentStepIndex = 0
    @State private var phaseElapsed: Double = 0
    @State private var remainingTime: TimeInterval = 180
    @State private var timer: Timer?

    private let phaseDuration: Double = 4.0
    private let sessionDuration: TimeInterval = 180

    // MARK: - Ripple Design Tokens

    private let darkCanvas = HomeCharacterDesignTokens.darkCanvas
    private let ripplePrimary = HomeCharacterDesignTokens.Ripple.primary  // #4FC3F7
    private let rippleDeep = HomeCharacterDesignTokens.Ripple.deep        // #0288D1
    private let rippleMid = HomeCharacterDesignTokens.Ripple.mid          // #81D4FA
    private let rippleLight = HomeCharacterDesignTokens.Ripple.light      // #B3E5FC

    // MARK: - Derived Values

    private var currentStep: BoxBreathingStep {
        BoxBreathingStep.steps[currentStepIndex]
    }

    private var phaseProgress: Double {
        min(phaseElapsed / phaseDuration, 1.0)
    }

    private var breathingPhase: BreathingSessionViewModel.BreathingPhase {
        switch currentStepIndex {
        case 0: return .inhale
        case 2: return .exhale
        default: return .hold
        }
    }

    private var breathingScale: Double {
        switch currentStepIndex {
        case 0: return 1.0 + phaseProgress * 0.3    // Inhale: expand
        case 1: return 1.3                           // Hold: stay expanded
        case 2: return 1.3 - phaseProgress * 0.6   // Exhale: contract
        case 3: return 0.7                           // Hold: stay contracted
        default: return 1.0
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            VStack(spacing: 0) {
                Spacer()

                // Ripple breathing orb
                RippleBreathingView(
                    phase: breathingPhase,
                    scale: isRunning ? breathingScale : 1.0,
                    size: 140
                )
                .frame(height: 220)
                .animation(.easeInOut(duration: 0.3), value: isRunning)
                .accessibilityLabel("Ripple breathing animation, currently \(currentStep.label)")

                // Time display
                Text(formattedTime)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(rippleLight)
                    .monospacedDigit()
                    .padding(.top, 4)

                // Phase pills
                phasePillsRow
                    .padding(.top, 20)

                // Instruction text
                Text(currentStep.instruction)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(rippleMid)
                    .padding(.top, 14)
                    .animation(.easeInOut, value: currentStepIndex)

                // Progress bar
                progressBarSection
                    .padding(.top, 12)

                // How Ripple guides you
                howRippleGuidesCard
                    .padding(.top, 24)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.bottom, 40)
            }
        }
        .background(darkCanvas)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onDisappear { stopTimer() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(rippleLight)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.75)
                    )
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Box Breathing")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(rippleLight)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Phase Pills

    private var phasePillsRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                let step = BoxBreathingStep.steps[index]
                let isActive = index == currentStepIndex
                VStack(spacing: 4) {
                    Text(step.emoji)
                        .font(.system(size: 22, design: .rounded))
                    Text(step.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isActive ? ripplePrimary : .white.opacity(0.4))
                    Text("\(Int(phaseDuration))s")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isActive ? ripplePrimary.opacity(0.12) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? ripplePrimary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(step.label), \(Int(phaseDuration)) seconds")
                .accessibilityValue(isActive ? "current phase" : "")
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Progress Bar

    private var progressBarSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 120/255, green: 120/255, blue: 128/255).opacity(0.12))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [ripplePrimary, rippleDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * phaseProgress, height: 10)
                    .animation(.easeInOut(duration: 0.15), value: phaseProgress)
            }
        }
        .frame(height: 10)
        .padding(.horizontal, 16)
    }

    // MARK: - How Ripple Guides You

    private var howRippleGuidesCard: some View {
        VStack(spacing: 18) {
            Text("💧 How Ripple guides you")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(rippleLight)

            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    let step = BoxBreathingStep.steps[index]
                    VStack(spacing: 6) {
                        Text(step.emoji)
                            .font(.system(size: 26, design: .rounded))
                        Text(step.label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(rippleMid)
                        Text("\(Int(phaseDuration))s")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)

                    if index < 3 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(ripplePrimary.opacity(0.5))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: toggleRunning) {
                HStack(spacing: 8) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    Text(isRunning ? "Pause" : "Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 180, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [ripplePrimary, rippleDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: ripplePrimary.opacity(0.4), radius: 12, y: 4)
            }
            .accessibilityLabel(isRunning ? "Pause session" : "Start session")

            Button(action: resetSession) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(rippleMid)
                .frame(width: 180, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .accessibilityLabel("Reset session")
        }
    }

    // MARK: - Time

    private var formattedTime: String {
        let t = max(0, remainingTime)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: - Timer Logic

    private func toggleRunning() {
        isRunning ? pauseSession() : startSession()
    }

    private func startSession() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            phaseElapsed += 0.1
            remainingTime -= 0.1

            if remainingTime <= 0 {
                remainingTime = 0
                stopTimer()
                isRunning = false
                return
            }

            if phaseElapsed >= phaseDuration {
                phaseElapsed = 0
                currentStepIndex = (currentStepIndex + 1) % 4
            }
        }
    }

    private func pauseSession() {
        stopTimer()
        isRunning = false
    }

    private func resetSession() {
        stopTimer()
        isRunning = false
        phaseElapsed = 0
        currentStepIndex = 0
        remainingTime = sessionDuration
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Box Breathing Step Info

private struct BoxBreathingStep {
    let label: String
    let instruction: String
    let emoji: String

    static let steps: [BoxBreathingStep] = [
        BoxBreathingStep(label: "Inhale", instruction: "Breathe in slowly", emoji: "🌬️"),
        BoxBreathingStep(label: "Hold", instruction: "Hold your breath", emoji: "✋"),
        BoxBreathingStep(label: "Exhale", instruction: "Breathe out slowly", emoji: "💨"),
        BoxBreathingStep(label: "Hold", instruction: "Hold your breath", emoji: "✋"),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreathingExerciseView()
    }
}
