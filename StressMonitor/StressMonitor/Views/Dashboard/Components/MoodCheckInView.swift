import SwiftUI

/// Subjective mood check-in row for the Home tab.
///
/// Renders five unicode mood chips (◌ ◎ ◐ ◑ ●) that the user taps to log how
/// they feel right now. The active chip fills with the level's accent color and
/// scales up; siblings stay neutral. The selected entry is reported via
/// `onSelect` so the owning view model can store it.
struct MoodCheckInView: View {
    let selected: MoodLevel?
    let onSelect: (MoodLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack(spacing: 10) {
                ForEach(MoodLevel.allCases) { level in
                    chip(for: level)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: HomeCharacterDesignTokens.Ripple.deep.opacity(0.08), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mood check-in")
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
            Text("How do you feel right now?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            Spacer()
        }
    }

    private func chip(for level: MoodLevel) -> some View {
        let isActive = selected == level
        let accent = accentColor(for: level)

        return Button {
            HapticManager.shared.buttonPress()
            onSelect(level)
        } label: {
            VStack(spacing: 6) {
                Text(level.glyph)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(isActive ? Color.white : accent)
                Text(level.displayName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(isActive ? Color.white : Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? accent : accent.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isActive ? Color.clear : accent.opacity(0.22), lineWidth: 1)
            )
            .scaleEffect(isActive ? 1.04 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood: \(level.displayName)")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private func accentColor(for level: MoodLevel) -> Color {
        switch level {
        case .veryCalm:  return HomeCharacterDesignTokens.Blossom.accent
        case .calm:      return HomeCharacterDesignTokens.Ripple.primary
        case .neutral:   return HomeCharacterDesignTokens.Zephyr.accent
        case .tense:     return HomeCharacterDesignTokens.Ember.accent
        case .veryTense: return Color.stressHigh
        }
    }
}

#Preview("MoodCheckInView") {
    @Previewable @State var selected: MoodLevel? = .neutral
    return VStack {
        MoodCheckInView(selected: selected) { selected = $0 }
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
