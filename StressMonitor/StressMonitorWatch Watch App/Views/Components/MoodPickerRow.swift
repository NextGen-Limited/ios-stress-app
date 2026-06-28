import SwiftUI

// MARK: - MoodPickerRow

/// Horizontal row of 5 mood buttons used on the Logging tab.
///
/// Each mood is rendered as a compact SF Symbol inside a circular well.
/// The selected mood gets an accent-strong border and soft tinted
/// background; unselected moods are hairlined. Tap behaviour is delegated
/// to the `onSelected` callback so the parent owns the source of truth.
///
/// Colour is never the only signal — each button also grows slightly and
/// shows a bolded label glyph when selected (WCAG dual-coding).
struct MoodPickerRow: View {
    @Binding var selectedMood: WatchMood?
    let onSelected: (WatchMood) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(WatchMood.allCases) { mood in
                moodButton(mood)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private func moodButton(_ mood: WatchMood) -> some View {
        let isSelected = selectedMood == mood
        return Button {
            selectedMood = mood
            onSelected(mood)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: mood.icon)
                    .font(.system(size: isSelected ? 18 : 15, weight: .semibold))
                    .foregroundStyle(isSelected ? WatchDesignTokens.accentStrong : WatchDesignTokens.ink)
                Text(mood.displayName.prefix(3).uppercased())
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .tracking(0.03 * 7)
                    .foregroundStyle(isSelected ? WatchDesignTokens.accentStrong : WatchDesignTokens.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                Circle()
                    .fill(isSelected ? WatchDesignTokens.accentSoft : WatchDesignTokens.surface)
            )
            .overlay(
                Circle()
                    .stroke(
                        isSelected ? WatchDesignTokens.accentStrong : WatchDesignTokens.separator,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(
                WatchDesignTokens.motion(WatchDesignTokens.Motion.fast, reduceMotion: reduceMotion),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mood.displayName) mood\(isSelected ? ", selected" : "")")
    }
}

#if DEBUG
#Preview("Mood picker") {
    struct PreviewWrapper: View {
        @State private var mood: WatchMood?
        var body: some View {
            MoodPickerRow(selectedMood: $mood) { _ in }
                .padding()
                .background(WatchDesignTokens.canvas)
        }
    }
    return PreviewWrapper()
}
#endif
