import SwiftUI

/// Watch **Seasonal Picker** screen — carousel of `SeasonalTheme` options.
///
/// Each option is presented as a preview tile showing its SF Symbol on a
/// theme-coloured swatch plus the display name. The selected theme is
/// persisted to `UserDefaults` via `@AppStorage`.
struct WatchSeasonalPickerView: View {
    @AppStorage("watch.seasonalTheme") private var selectionRaw: String = SeasonalTheme.none.rawValue

    private var selection: SeasonalTheme {
        SeasonalTheme(rawValue: selectionRaw) ?? .none
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                Text("SEASONAL THEME")
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .tracking(0.06 * 8.5)
                    .foregroundStyle(WatchDesignTokens.muted)

                VStack(spacing: WatchDesignTokens.Spacing.xxs) {
                    ForEach(SeasonalTheme.allCases, id: \.self) { theme in
                        themeRow(theme)
                    }
                }
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("Seasonal")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Row

    private func themeRow(_ theme: SeasonalTheme) -> some View {
        let isSelected = theme == selection
        return Button {
            selectionRaw = theme.rawValue
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: theme.primaryColorHex))
                        .frame(width: 28, height: 28)
                    Image(systemName: theme.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(theme.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchDesignTokens.ink)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WatchDesignTokens.accentStrong)
                }
            }
            .padding(.horizontal, WatchDesignTokens.Spacing.xs)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                    .fill(WatchDesignTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                    .stroke(
                        isSelected ? WatchDesignTokens.accentStrong : .clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme\(isSelected ? ", selected" : "")")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchSeasonalPickerView()
    }
}
#endif
