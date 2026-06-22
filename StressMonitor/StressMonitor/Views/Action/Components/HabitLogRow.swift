import SwiftUI

/// One habit row on the Action tab.
///
/// Layout: icon tile + label + value, a thin progress bar toward the daily goal,
/// a SourcePill (AUTO tinted with the Ripple accent for hydration/sunlight, LOG
/// neutral for caffeine), and a trailing chevron. The whole row is tappable for
/// manual habits to add one unit; AUTO rows are read-only.
struct HabitLogRow: View {
    let habit: Habit
    var onTap: (() -> Void)? = nil

    private var progress: Double {
        guard habit.goalValue > 0 else { return 0 }
        return min(1.0, habit.currentValue / habit.goalValue)
    }

    var body: some View {
        Button {
            // Only manual habits respond to a tap to increment.
            guard habit.source == .manual else { return }
            HapticManager.shared.buttonPress()
            onTap?()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: habit.type.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(habit.type.displayName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        SourcePill(source: habit.source, tint: tint)
                    }

                    progressBar
                }

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(valueText)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        Text("/ \(Int(habit.goalValue.rounded()))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(habit.source == .auto)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.type.displayName): \(valueText) of \(Int(habit.goalValue.rounded())) \(habit.type.unit)")
        .accessibilityHint(habit.source == .manual ? "Double tap to log one unit" : "Auto-tracked from HealthKit")
    }

    private var tint: Color {
        switch habit.type {
        case .hydration: return HomeCharacterDesignTokens.Ripple.primary
        case .sunlight:  return HomeCharacterDesignTokens.Ember.accent
        case .caffeine:  return HomeCharacterDesignTokens.Zephyr.accent
        }
    }

    private var valueText: String {
        // Whole-number habits read cleaner than "3.0"
        let rounded = (habit.currentValue * 10).rounded() / 10
        return rounded.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(rounded))"
            : String(format: "%.1f", rounded)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.14))
                Capsule()
                    .fill(tint.opacity(0.7))
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 5)
    }
}

#Preview("HabitLogRow") {
    @Previewable @State var habit = Habit(type: .hydration, currentValue: 5, goalValue: 8)
    return VStack(spacing: 10) {
        HabitLogRow(habit: habit) { habit.currentValue += 1 }
        HabitLogRow(habit: Habit(type: .sunlight, currentValue: 18, goalValue: 30))
        HabitLogRow(habit: Habit(type: .caffeine, currentValue: 2, goalValue: 4)) { }
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
