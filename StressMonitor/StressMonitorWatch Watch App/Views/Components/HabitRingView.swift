import SwiftUI

// MARK: - HabitRingView

/// Circular progress ring for a single daily habit.
///
/// Renders the habit icon centered, a tier-coloured progress arc bounded
/// by a hairline track, and a `current / goal` count beneath the icon.
/// Designed for the Logging tab where 3 habit rings sit side-by-side.
///
/// The arc fill uses the Ripple accent ramp so all habits read as a
/// single positive-progress family (no per-habit colours). Colour is
/// always paired with the numeric ratio for WCAG compliance.
struct HabitRingView: View {
    let habit: WatchHabit
    var size: CGFloat = 76

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ringWidth: CGFloat { max(5, size * 0.085) }
    private var fraction: CGFloat {
        let goal = max(habit.goalValue, 1)
        return CGFloat(min(max(habit.currentValue / goal, 0), 1))
    }
    private var isComplete: Bool { habit.currentValue >= habit.goalValue }
    private var displayCurrent: String {
        habit.type == .hydration
            ? String(format: "%.1f", habit.currentValue)
            : "\(Int(habit.currentValue))"
    }
    private var displayGoal: String {
        habit.type == .hydration
            ? String(format: "%.1f", habit.goalValue)
            : "\(Int(habit.goalValue))"
    }

    var body: some View {
        ZStack {
            track
            progressArc
            centerStack
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Subviews

    private var track: some View {
        Circle()
            .stroke(WatchDesignTokens.separator, lineWidth: ringWidth)
    }

    private var progressArc: some View {
        Circle()
            .trim(from: 0, to: fraction)
            .stroke(
                arcColor,
                style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(
                WatchDesignTokens.motion(WatchDesignTokens.Motion.default, reduceMotion: reduceMotion),
                value: fraction
            )
    }

    private var centerStack: some View {
        VStack(spacing: 1) {
            Image(systemName: habit.type.icon)
                .font(.system(size: size * 0.22, weight: .semibold)) // dated exception 2026-09-05: ring geometry — font proportional to ring diameter
                .foregroundStyle(isComplete ? WatchDesignTokens.accentStrong : WatchDesignTokens.ink)
            Text("\(displayCurrent)/\(displayGoal)")
                .font(.system(size: size * 0.16, weight: .semibold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: ring geometry — font proportional to ring diameter
                .foregroundStyle(WatchDesignTokens.inkSecondary)
                .minimumScaleFactor(0.7) // dated exception 2026-09-05: ring-interior count; slot geometry is proportional to ring size
                .lineLimit(1)
        }
    }

    // MARK: - Helpers

    private var arcColor: Color {
        isComplete ? WatchDesignTokens.accentStrong : WatchDesignTokens.accent
    }

    private var accessibilitySummary: String {
        let pct = Int(fraction * 100)
        let status = isComplete ? ", goal reached" : ""
        return "\(habit.type.displayName), \(displayCurrent) of \(displayGoal) \(habit.type.unit)\(status), \(pct) percent."
    }
}

#if DEBUG
private struct HabitRingPreviewData {
    static let habits: [WatchHabit] = [
        WatchHabit(type: .hydration, currentValue: 1.4, goalValue: 2.0),
        WatchHabit(type: .caffeine, currentValue: 1, goalValue: 3),
        WatchHabit(type: .sunlight, currentValue: 42, goalValue: 60)
    ]
}

#Preview("Habit rings") {
    HStack(spacing: 12) {
        ForEach(HabitRingPreviewData.habits) { habit in
            HabitRingView(habit: habit)
        }
    }
    .padding()
    .background(WatchDesignTokens.canvas)
}
#endif
