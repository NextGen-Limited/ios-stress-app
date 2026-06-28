import SwiftUI

// MARK: - WatchLoggingView

/// Watch **Logging** screen — daily habit check-in and mood picker.
///
/// Layout:
///  - Title "Today" + date sublabel at the top
///  - 3 habit rings (hydration, caffeine, sunlight) in an HStack
///  - A compact mood picker row with 5 SF Symbol buttons
///
/// All colours and spacing come from `WatchDesignTokens` so this screen
/// reads as a sibling of the Home and History canvases. Habits owned by
/// `WatchHabitViewModel`, mood owned by `WatchMoodViewModel`.
struct WatchLoggingView: View {
    @State private var habitViewModel = WatchHabitViewModel()
    @State private var moodViewModel = WatchMoodViewModel()
    @State private var selectedMood: WatchMood?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                header
                habitsSection
                moodSection
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedMood = moodViewModel.latest?.mood }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Today")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(WatchDesignTokens.ink)
            Text(headerDate)
                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE · MMM d"
        return fmt.string(from: Date()).uppercased()
    }

    // MARK: - Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("HABITS")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            HStack(spacing: WatchDesignTokens.Spacing.xs) {
                ForEach(HabitType.allCases) { type in
                    if let habit = habitViewModel.habit(for: type) {
                        habitCard(habit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func habitCard(_ habit: WatchHabit) -> some View {
        let isManual = habit.type.source == .manual
        Button {
            if isManual { habitViewModel.logManual(habit.type, amount: 1) }
        } label: {
            VStack(spacing: 4) {
                HabitRingView(habit: habit, size: 60)
                Text(habit.type.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(0.03 * 8)
                    .foregroundStyle(WatchDesignTokens.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isManual {
                    Text("+1")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(WatchDesignTokens.accentStrong)
                } else {
                    Text("AUTO")
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .tracking(0.04 * 7)
                        .foregroundStyle(WatchDesignTokens.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                    .fill(WatchDesignTokens.surface)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isManual)
        .accessibilityLabel("\(habit.type.displayName), \(habit.currentValue) of \(habit.goalValue) \(habit.type.unit)")
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("MOOD")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            MoodPickerRow(
                selectedMood: $selectedMood,
                onSelected: { mood in moodViewModel.log(mood: mood) }
            )
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchLoggingView()
    }
}
#endif
