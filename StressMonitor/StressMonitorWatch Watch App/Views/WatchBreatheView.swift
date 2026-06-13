import SwiftUI

/// Watch **Breathe** screen.
///
/// A guided 4-7-8 breathing exercise:
/// 1. **Inhale** for 4 seconds (ring expands)
/// 2. **Hold** for 7 seconds (ring holds)
/// 3. **Exhale** for 8 seconds (ring contracts)
///
/// The expanding ring is the visual guide; the phase label and a soft countdown
/// keep the user in sync. No stress numbers appear here.
struct WatchBreatheView: View {
    private enum Phase: String {
        case inhale, hold, exhale, idle
    }

    @State private var phase: Phase = .idle
    @State private var scale: CGFloat = 0.45
    @State private var secondsLeft: Int = 0
    @State private var cycleCount: Int = 0
    @State private var timer: Timer?

    private let inhaleSec = 4
    private let holdSec = 7
    private let exhaleSec = 8

    private var isRunning: Bool { phase != .idle }

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            ZStack {
                // Outer guide ring (static).
                Circle()
                    .stroke(StressCharacterPalette.ripple.opacity(0.2), lineWidth: 3)
                    .frame(width: 140, height: 140)

                // Animated breathing ring.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [StressCharacterPalette.ripple.opacity(0.6),
                                     StressCharacterPalette.ripple.opacity(0.1)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 70
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)

                VStack(spacing: 2) {
                    Text(phaseLabel)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)

                    if isRunning {
                        Text("\(secondsLeft)")
                            .font(.system(size: 30, weight: .bold, design: .rounded)
                                .monospacedDigit())
                            .foregroundStyle(StressCharacterPalette.ripple)
                            .contentTransition(.numericText(value: secondsLeft))
                    } else {
                        Text("💧")
                            .font(.system(size: 30))
                    }
                }
            }
            .frame(width: 150, height: 150)
            .animation(.easeInOut(duration: currentDuration), value: scale)

            Spacer(minLength: 0)

            Text(isRunning ? "Cycle \(cycleCount)" : "4·7·8 Breathing")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(StressCharacterPalette.mutedInk)

            Button {
                isRunning ? stop() : start()
            } label: {
                Label(isRunning ? "Stop" : "Begin",
                      systemImage: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.bordered)
            .tint(isRunning ? .red : StressCharacterPalette.ripple)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StressCharacterPalette.darkCanvas.ignoresSafeArea())
        .onDisappear { stop() }
    }

    // MARK: - State machine

    private var phaseLabel: String {
        switch phase {
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        case .idle:   return "Ready"
        }
    }

    private var currentDuration: Double {
        switch phase {
        case .inhale: return Double(inhaleSec)
        case .exhale: return Double(exhaleSec)
        default: return 0.4
        }
    }

    private func start() {
        cycleCount = 0
        beginInhale()
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        scale = 0.45
        secondsLeft = 0
    }

    private func beginInhale() {
        phase = .inhale
        secondsLeft = inhaleSec
        withAnimation(.easeInOut(duration: Double(inhaleSec))) {
            scale = 1.0
        }
        runCountdown { beginHold() }
    }

    private func beginHold() {
        phase = .hold
        secondsLeft = holdSec
        // Hold scale steady.
        runCountdown { beginExhale() }
    }

    private func beginExhale() {
        phase = .exhale
        secondsLeft = exhaleSec
        withAnimation(.easeInOut(duration: Double(exhaleSec))) {
            scale = 0.45
        }
        runCountdown {
            cycleCount += 1
            beginInhale() // loop until the user stops
        }
    }

    /// Counts down once per second; calls `onZero` when the phase elapses.
    private func runCountdown(onZero: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if secondsLeft > 1 {
                secondsLeft -= 1
            } else {
                t.invalidate()
                onZero()
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchBreatheView()
}
#endif
