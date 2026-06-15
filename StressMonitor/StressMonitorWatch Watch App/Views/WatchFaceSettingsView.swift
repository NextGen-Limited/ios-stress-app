import SwiftUI

// MARK: - WatchFaceSettingsView

/// Watch settings screen for customising the complication background.
///
/// Users can pick a background **style** (solid, gradient, aurora, ocean)
/// and a **colour theme** matching one of the five characters.  The
/// selection is persisted to App-Groups `UserDefaults` (via
/// `WatchFacePreferences`) so complications refresh immediately and the
/// iPhone can mirror the choice through WatchConnectivity.
struct WatchFaceSettingsView: View {

    // Reactive raw-value bindings backed by App-Groups UserDefaults.
    @AppStorage(
        WatchFacePreferences.Keys.backgroundStyle,
        store: WatchFacePreferences.defaults
    ) private var styleRaw: String = WatchFacePreferences.defaultStyle.rawValue

    @AppStorage(
        WatchFacePreferences.Keys.theme,
        store: WatchFacePreferences.defaults
    ) private var themeRaw: String = WatchFacePreferences.defaultTheme.rawValue

    private var style: WatchFaceBackgroundStyle {
        WatchFaceBackgroundStyle(rawValue: styleRaw) ?? .gradient
    }

    private var theme: WatchFaceTheme {
        WatchFaceTheme(rawValue: themeRaw) ?? .ripple
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewCard
                styleSection
                themeSection
            }
            .padding(.horizontal, 4)
        }
        .background(StressCharacterPalette.darkCanvas.ignoresSafeArea())
        .navigationTitle("Watch Face")
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        ZStack {
            WatchFaceBackgroundView(style: style, theme: theme)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            VStack(spacing: 6) {
                Text(theme.emoji)
                    .font(.system(size: 44))

                Text("Calm")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryColor)

                Text(style.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 120)
    }

    // MARK: - Style Picker

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background Style")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(StressCharacterPalette.mutedInk)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(WatchFaceBackgroundStyle.allCases, id: \.self) { option in
                    styleRow(option)
                }
            }
        }
    }

    private func styleRow(_ option: WatchFaceBackgroundStyle) -> some View {
        let isSelected = option == style

        return Button {
            styleRaw = option.rawValue
            WatchFacePreferences.setBackgroundStyle(option)
            WatchConnectivityManager.shared.syncData(
                WatchFacePreferences.connectivityPayload()
            )
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    WatchFaceBackgroundView(style: option, theme: theme)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Image(systemName: option.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }

                Text(option.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.primaryColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(StressCharacterPalette.darkCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? theme.primaryColor.opacity(0.5) : Color.white.opacity(0.05),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme Picker

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Theme")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(StressCharacterPalette.mutedInk)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(WatchFaceTheme.allCases, id: \.self) { option in
                    themeRow(option)
                }
            }
        }
    }

    private func themeRow(_ option: WatchFaceTheme) -> some View {
        let isSelected = option == theme

        return Button {
            themeRaw = option.rawValue
            WatchFacePreferences.setTheme(option)
            WatchConnectivityManager.shared.syncData(
                WatchFacePreferences.connectivityPayload()
            )
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(option.primaryColor)
                        .frame(width: 28, height: 28)

                    Text(option.emoji)
                        .font(.system(size: 14))
                }

                Text(option.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(option.primaryColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(StressCharacterPalette.darkCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? option.primaryColor.opacity(0.5) : Color.white.opacity(0.05),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        WatchFaceSettingsView()
    }
}
#endif
