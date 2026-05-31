import SwiftUI

// MARK: - Box Breathing Exercise View

/// Box Breathing (4-4-4-4) exercise screen.
/// Figma: node 3438:755 — Inhale 4s → Hold 4s → Exhale 4s → Hold 4s, session 3:00
struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRunning = false
    @State private var currentStepIndex = 0
    @State private var phaseElapsed: Double = 0
    @State private var remainingTime: TimeInterval = 180
    @State private var timer: Timer?

    private let phaseDuration: Double = 4.0
    private let sessionDuration: TimeInterval = 180

    private var currentStep: BreathingStepInfo {
        BreathingStepInfo.steps[currentStepIndex]
    }

    private var phaseProgress: Double {
        min(phaseElapsed / phaseDuration, 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer()
            circularTimerSection
            phaseIndicatorRow
                .padding(.top, 16)
            instructionLabel
                .padding(.top, 4)
            progressBarSection
                .padding(.top, 16)
            howItWorksCard
                .padding(.top, 24)
            Spacer()
            actionButtons
                .padding(.bottom, 40)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onDisappear { stopTimer() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 0.75)
                    )
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Box Breathing")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.gray)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Circular Timer

    private var circularTimerSection: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(Color.tealLight.opacity(0.2), lineWidth: 2)
                .frame(width: 210, height: 210)

            // Progress arc — fills per phase
            Circle()
                .trim(from: 0, to: isRunning ? phaseProgress : 0)
                .stroke(
                    Color.tealLight,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 156, height: 156)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: phaseProgress)

            // Background circle
            Circle()
                .fill(Color.white)
                .frame(width: 156, height: 156)
                .shadow(color: .black.opacity(0.1), radius: 9, y: 3)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 5)

            // Time display
            Text(formattedTime)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                .monospacedDigit()
        }
    }

    private var formattedTime: String {
        let t = max(0, remainingTime)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: - Phase Indicator

    private var phaseIndicatorRow: some View {
        HStack {
            Text(currentStep.label)
                .font(.system(size: 14))
                .foregroundStyle(Color.tealDark)
            Spacer()
            Text("\(Int(phaseElapsed))s/\(Int(phaseDuration))s")
                .font(.system(size: 14))
                .foregroundStyle(Color.tealDark)
        }
        .padding(.horizontal, 17)
    }

    // MARK: - Instruction

    private var instructionLabel: some View {
        Text(currentStep.instruction)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))
    }

    // MARK: - Progress Bar

    private var progressBarSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.34, green: 0.34, blue: 0.34))
                    .frame(height: 11)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.tealLight)
                    .frame(width: geo.size.width * phaseProgress, height: 11)
                    .animation(.linear(duration: 0.1), value: phaseProgress)
            }
        }
        .frame(height: 11)
        .padding(.horizontal, 17)
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        VStack(spacing: 20) {
            Text("How it works:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))

            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    let step = BreathingStepInfo.steps[index]
                    VStack(spacing: 4) {
                        Circle()
                            .fill(step.dotColor)
                            .frame(width: 20, height: 20)
                        Text(step.label)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.tealDark)
                        Text("4s")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.tealDark)
                    }
                    .frame(maxWidth: .infinity)

                    if index < 3 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.tealDark)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 33)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 7, y: 7)
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 5)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: toggleRunning) {
                HStack(spacing: 8) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    Text(isRunning ? "Pause" : "Start")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 152, height: 58)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.tealLight))
            }

            Button(action: resetSession) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(Color.tealLight)
                .frame(width: 152, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
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

// MARK: - Breathing Step Info

private struct BreathingStepInfo {
    let label: String
    let instruction: String
    let dotColor: Color

    static let steps: [BreathingStepInfo] = [
        BreathingStepInfo(label: "Inhale", instruction: "Breathe in slowly",
                          dotColor: Color(red: 0.741, green: 0.878, blue: 1.0)),
        BreathingStepInfo(label: "Hold", instruction: "Hold your breath",
                          dotColor: Color(red: 0.902, green: 0.902, blue: 0.980)),
        BreathingStepInfo(label: "Exhale", instruction: "Breathe out slowly",
                          dotColor: Color(red: 0.780, green: 0.961, blue: 0.780)),
        BreathingStepInfo(label: "Hold", instruction: "Hold your breath",
                          dotColor: Color(red: 1.0, green: 0.875, blue: 0.729)),
    ]
}

// MARK: - Teal Color Helpers

private extension Color {
    static let tealLight = Color(red: 0.52, green: 0.79, blue: 0.79)   // #85C9C9
    static let tealDark  = Color(red: 0.45, green: 0.73, blue: 0.73)   // #73B9B9
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreathingExerciseView()
    }
}
