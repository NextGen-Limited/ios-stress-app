import SwiftUI

/// Watch **Breathe** screen — 4-7-8 guided breathing.
///
/// Light canvas. A breathing ring expands/contracts with each phase; the
/// phase label rides above in SF Pro Display, the countdown in SF Pro
/// Rounded tabular numerals, and four phase dots track progress.  Phase
/// colours follow the iOS Breathing lineage:
///   - Inhale  → accent  `#4FC3F7`
///   - Hold    → strong  `#0288D1`
///   - Exhale  → mild    `#007AFF`  (transitions back toward accent)
struct WatchBreatheView: View {
    private enum Phase: String, Hashable {
        case idle, inhale, hold, exhale
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .idle
    @State private var ringScale: CGFloat = 0.55
    @State private var secondsLeft: Int = 0
    @State private var cycleCount: Int = 0
    @State private var timer: Timer?
    @State private var ringFill: Double = 0    // 0…1 progress within phase

    private let inhaleSec = 4
    private let holdSec   = 7
    private let exhaleSec = 8

    private var isRunning: Bool { phase != .idle }

    @ScaledMetric(relativeTo: .caption2) private var caption2Scale: CGFloat = 1
    @ScaledMetric(relativeTo: .footnote) private var footnoteScale: CGFloat = 1
    var body: some View {
        VStack(spacing: WatchDesignTokens.Spacing.xs) {
            Spacer(minLength: 0)

            phaseLabel

            breathingRing

            phaseDots
                .padding(.top, 2)

            Spacer(minLength: 0)

            footBlock
        }
        .padding(.horizontal, WatchDesignTokens.contentSidePadding)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .onDisappear { stop() }
    }

    // MARK: - Subviews

    private var phaseLabel: some View {
        Text(phaseTitle)
            .font(.system(size: 13 * footnoteScale, weight: .semibold, design: .default))
            .tracking(-0.01 * 13)
            .foregroundStyle(phaseColor)
            .contentTransition(.opacity)
            .animation(WatchDesignTokens.motion(WatchDesignTokens.Motion.fast, reduceMotion: reduceMotion), value: phase)
    }

    private var breathingRing: some View {
        ZStack {
            // Track ring (static)
            Circle()
                .stroke(WatchDesignTokens.separator, lineWidth: 10)
            // Phase progress ring
            Circle()
                .trim(from: 0, to: ringFill)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(WatchDesignTokens.motion(WatchDesignTokens.Motion.default, reduceMotion: reduceMotion), value: ringFill)

            // Centered countdown overlay (matches HTML ring-center)
            countdownBlock
        }
        .frame(width: 110, height: 110)
        .scaleEffect(ringScale)
        .animation(WatchDesignTokens.motion(WatchDesignTokens.Motion.slow, reduceMotion: reduceMotion), value: ringScale)
    }

    private var countdownBlock: some View {
        VStack(spacing: 1) {
            if isRunning {
                Text("\(secondsLeft)")
                    .font(.system(size: 36, weight: .semibold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: countdown numeral inside fixed 110pt breathing ring
                    .tracking(-0.028 * 36)
                    .foregroundStyle(phaseColor)
                    .contentTransition(.numericText(value: Double(secondsLeft)))
            } else {
                Text("—")
                    .font(.system(size: 36, weight: .semibold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: countdown numeral inside fixed 110pt breathing ring
                    .foregroundStyle(WatchDesignTokens.muted)
            }
            Text(isRunning ? "sec" : "Ready")
                .font(.system(size: 9, weight: .semibold, design: .monospaced)) // dated exception 2026-09-05: countdown numeral inside fixed 110pt breathing ring
                .tracking(0.06 * 9)
                .foregroundStyle(WatchDesignTokens.muted)
        }
    }

    private var phaseDots: some View {
        let phases: [Phase] = [.inhale, .hold, .exhale]
        return HStack(spacing: 6) {
            ForEach(phases, id: \.self) { p in
                dot(for: p)
            }
        }
    }

    @ViewBuilder
    private func dot(for p: Phase) -> some View {
        let status = dotStatus(for: p)
        Group {
            if status == .active {
                Capsule().fill(WatchDesignTokens.accent).frame(width: 16, height: 6)
            } else {
                Circle().fill(status == .done ? WatchDesignTokens.accent.opacity(0.45) : WatchDesignTokens.separatorStrong)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private enum DotStatus { case upcoming, active, done }

    private func dotStatus(for p: Phase) -> DotStatus {
        let order: [Phase] = [.inhale, .hold, .exhale]
        guard let current = order.firstIndex(of: phase),
              let target = order.firstIndex(of: p) else { return .upcoming }
        if target < current { return .done }
        if target == current { return .active }
        return .upcoming
    }

    private var footBlock: some View {
        VStack(spacing: 8) {
            Text(isRunning ? "CYCLE \(cycleCount)" : "4 · 7 · 8 BREATHING")
                .font(.system(size: 8.5 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.08 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)
            pillButton
        }
        .frame(maxWidth: .infinity)
    }

    private var pillButton: some View {
        Button {
            isRunning ? stop() : start()
        } label: {
            Text(isRunning ? "End" : "Begin")
                .font(.system(size: 12 * footnoteScale, weight: .semibold, design: .rounded))
                .tracking(-0.01 * 12)
                .foregroundStyle(isRunning ? WatchDesignTokens.accentStrong : .white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)
                .background(
                    Capsule(style: .continuous)
                        .fill(isRunning ? AnyShapeStyle(WatchDesignTokens.surface) : AnyShapeStyle(WatchDesignTokens.accentStrong))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(WatchDesignTokens.separatorStrong, lineWidth: isRunning ? 0.5 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - State machine

    private var phaseTitle: String {
        switch phase {
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        case .idle:   return "Breathe"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .inhale: return WatchDesignTokens.accent
        case .hold:   return WatchDesignTokens.accentStrong
        case .exhale: return Color.stressMild
        case .idle:   return WatchDesignTokens.muted
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
        ringScale = 0.55
        secondsLeft = 0
        ringFill = 0
    }

    private func beginInhale() {
        phase = .inhale
        secondsLeft = inhaleSec
        ringFill = 0
        if !reduceMotion {
            withAnimation(.easeInOut(duration: Double(inhaleSec))) { ringScale = 1.0 }
        }
        runPhase(duration: inhaleSec) { beginHold() }
    }

    private func beginHold() {
        phase = .hold
        secondsLeft = holdSec
        ringFill = 1.0
        runPhase(duration: holdSec) { beginExhale() }
    }

    private func beginExhale() {
        phase = .exhale
        secondsLeft = exhaleSec
        ringFill = 1.0
        if !reduceMotion {
            withAnimation(.easeInOut(duration: Double(exhaleSec))) { ringScale = 0.55 }
        }
        runPhase(duration: exhaleSec) {
            cycleCount += 1
            beginInhale() // loop until the user stops
        }
    }

    /// Drives both the per-second countdown and the smooth ring fill.
    private func runPhase(duration: Int, onZero: @escaping () -> Void) {
        let total = Double(duration)
        timer?.invalidate()
        var ticks = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            ticks += 1
            if secondsLeft > 1 {
                secondsLeft -= 1
                ringFill = Double(ticks) / total
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
