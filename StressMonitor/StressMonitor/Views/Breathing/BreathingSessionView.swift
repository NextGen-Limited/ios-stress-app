import SwiftUI
import SwiftData

/// Live breathing session screen — Ripple redesign.
/// Dark canvas with radial glow, phase-colored text, encouragement bubble, haptics.
struct BreathingSessionView: View {
    @State private var viewModel: BreathingSessionViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showSummary = false
    @State private var showEncouragement = false

    // Ripple design tokens
    private let darkCanvas = HomeCharacterDesignTokens.darkCanvas
    private let ripplePrimary = HomeCharacterDesignTokens.Ripple.primary  // #4FC3F7
    private let rippleDeep = HomeCharacterDesignTokens.Ripple.deep        // #0288D1
    private let rippleMid = HomeCharacterDesignTokens.Ripple.mid          // #81D4FA
    private let rippleLight = HomeCharacterDesignTokens.Ripple.light      // #B3E5FC
    private let exhaleColor = Color(hex: "#26C6DA")

    var body: some View {
        ZStack {
            // Dark canvas with subtle radial glow at center
            darkCanvas.ignoresSafeArea()

            // Radial glow
            RadialGradient(
                colors: [
                    ripplePrimary.opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 240
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel?.endSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .accessibilityLabel("Close session")
                }
                .padding(.trailing, 20)
                .padding(.top, 8)

                Spacer()

                // Ripple breathing view — HUGE, fills screen
                if let viewModel = viewModel {
                    RippleBreathingView(
                        phase: viewModel.breathingPhase,
                        scale: viewModel.circleScale,
                        size: 200
                    )
                    .frame(height: 300)
                    .accessibilityLabel("Ripple is guiding your breathing, phase: \(phaseDisplayName(viewModel.breathingPhase))")
                } else {
                    Color.clear.frame(height: 300)
                }

                Spacer()

                // Phase text
                Text(phaseText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(phaseColor)
                    .animation(.easeInOut(duration: 0.4), value: viewModel?.breathingPhase)

                // Phase subtitle
                Text(subtitleText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 6)
                    .animation(.easeInOut(duration: 0.4), value: viewModel?.breathingPhase)

                // Phase progress dots
                phaseProgressDots
                    .padding(.top, 16)

                // Time remaining
                Text(timeRemainingText)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .foregroundStyle(rippleLight)
                    .monospacedDigit()
                    .padding(.top, 20)

                // Encouragement bubble (appears mid-session)
                if showEncouragement {
                    encouragementBubble
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.top, 16)
                }

                // End Session button
                Button(action: {
                    viewModel?.endSession()
                    showSummary = true
                }) {
                    Text("End Session")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#E53935"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 229/255, green: 57/255, blue: 53/255).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "#E53935").opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .accessibilityLabel("End Session")
            }
        }
        .onAppear {
            viewModel = BreathingSessionViewModel()
            viewModel?.startSession()
        }
        .onDisappear {
            viewModel?.endSession()
        }
        .onChange(of: viewModel?.breathingPhase) {
            triggerHaptic()
        }
        .onChange(of: viewModel?.remainingTime) {
            checkEncouragement()
        }
        .navigationDestination(isPresented: $showSummary) {
            if let result = viewModel?.sessionResult {
                BreathingSummaryView(result: result)
            }
        }
    }

    // MARK: - Encouragement Bubble

    private var encouragementBubble: some View {
        HStack(spacing: 12) {
            RippleCharacterView(mood: .happy, size: 44)
                .accessibilityLabel("Ripple avatar")

            Text("You are doing great! Keep going.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(rippleLight)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Phase Progress Dots

    private var phaseProgressDots: some View {
        let phases: [BreathingSessionViewModel.BreathingPhase] = [.inhale, .hold, .exhale]
        let currentPhase = viewModel?.breathingPhase ?? .inhale

        return HStack(spacing: 10) {
            ForEach(phases, id: \.self) { phase in
                let isActive = phase == currentPhase
                Capsule()
                    .fill(isActive ? ripplePrimary : Color.white.opacity(0.15))
                    .frame(width: isActive ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPhase)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Breathing phase progress")
        .accessibilityValue("Phase \(phaseIndex(currentPhase) + 1) of 3")
    }

    // MARK: - Phase Helpers

    private var phaseText: String {
        guard let viewModel = viewModel else { return "Ready" }
        switch viewModel.breathingPhase {
        case .inhale: return "Inhale"
        case .hold: return "Hold"
        case .exhale: return "Exhale"
        }
    }

    private var subtitleText: String {
        guard let viewModel = viewModel else { return "" }
        switch viewModel.breathingPhase {
        case .inhale: return "Deeply through your nose"
        case .hold: return "Gently hold"
        case .exhale: return "Slowly out through your mouth"
        }
    }

    private var phaseColor: Color {
        guard let viewModel = viewModel else { return ripplePrimary }
        switch viewModel.breathingPhase {
        case .inhale: return ripplePrimary   // #4FC3F7
        case .hold: return rippleMid         // #81D4FA
        case .exhale: return exhaleColor     // #26C6DA
        }
    }

    private func phaseDisplayName(_ phase: BreathingSessionViewModel.BreathingPhase) -> String {
        switch phase {
        case .inhale: return "inhale"
        case .hold: return "hold"
        case .exhale: return "exhale"
        }
    }

    private func phaseIndex(_ phase: BreathingSessionViewModel.BreathingPhase) -> Int {
        switch phase {
        case .inhale: return 0
        case .hold: return 1
        case .exhale: return 2
        }
    }

    // MARK: - Time

    private var timeRemainingText: String {
        guard let viewModel = viewModel else { return "02:00" }
        let minutes = Int(viewModel.remainingTime) / 60
        let seconds = Int(viewModel.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Encouragement Logic

    private func checkEncouragement() {
        guard let vm = viewModel, !showEncouragement else { return }
        // Show encouragement at ~40% through the session
        let threshold = vm.sessionDuration * 0.6
        if vm.remainingTime <= threshold {
            withAnimation(.easeInOut(duration: 0.5)) {
                showEncouragement = true
            }
            // Auto-hide after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showEncouragement = false
                }
            }
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
