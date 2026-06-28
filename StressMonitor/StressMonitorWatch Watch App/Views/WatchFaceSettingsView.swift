import SwiftUI

// MARK: - WatchFaceSettingsView

/// Watch Face customization screen.
///
/// Cream canvas (`--settings-bg #FFFDF6`) matching the iOS Settings
/// lineage. A live preview at top shows the active companion in a themed
/// tile, followed by a 2×2 background-style picker and a 5-character
/// theme row.  Selected state is signalled by an accent-strong border and
/// a checkmark.
struct WatchFaceSettingsView: View {

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
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                previewCard
                styleSection
                themeSection
                customizationSection
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.settingsCanvas.ignoresSafeArea())
        .navigationTitle("Watch Face")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Customization Section (Seasonal + Tier Names)

    private var customizationSection: some View {
        VStack(spacing: WatchDesignTokens.Spacing.xs) {
            NavigationLink {
                WatchSeasonalPickerView()
            } label: {
                settingsRow(
                    icon: "sparkles",
                    title: "Seasonal Themes",
                    subtitle: "Spring, Lunar, Halloween, Holiday"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                TierNameEditorView()
            } label: {
                settingsRow(
                    icon: "textformat",
                    title: "Rename Tiers",
                    subtitle: "Customize stress level names"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WatchDesignTokens.accentStrong)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchDesignTokens.ink)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchDesignTokens.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 4) {
            Text("PREVIEW")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                .tracking(0.05 * 7.5)
                .foregroundStyle(WatchDesignTokens.muted)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(previewFill)
                    .frame(width: 56, height: 56)

                Text("42")
                    .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    private var previewFill: AnyShapeStyle {
        switch style {
        case .solid:
            return AnyShapeStyle(theme.primaryColor)
        case .gradient:
            return AnyShapeStyle(LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .aurora:
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: theme.primaryColor, location: 0.0),
                    .init(color: theme.secondaryColor, location: 0.5),
                    .init(color: theme.primaryColor.opacity(0.7), location: 1.0)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .ocean:
            return AnyShapeStyle(LinearGradient(
                colors: [theme.secondaryColor, theme.primaryColor],
                startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: - Background Style Picker (2 × 2)

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("BACKGROUND STYLE")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                ForEach(WatchFaceBackgroundStyle.allCases, id: \.self) { option in
                    styleItem(option)
                }
            }
        }
    }

    private func styleItem(_ option: WatchFaceBackgroundStyle) -> some View {
        let isSelected = option == style
        return Button {
            styleRaw = option.rawValue
            WatchFacePreferences.setBackgroundStyle(option)
            WatchConnectivityManager.shared.syncData(WatchFacePreferences.connectivityPayload())
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(styleSwatch(option))
                    .frame(height: 22)
                Text(option.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(0.04 * 8)
                    .foregroundStyle(WatchDesignTokens.inkSecondary)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(WatchDesignTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? WatchDesignTokens.accentStrong : .clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.displayName) background style\(isSelected ? ", selected" : "")")
    }

    private func styleSwatch(_ option: WatchFaceBackgroundStyle) -> Color {
        // Distinct, recognisable swatches per style using the active theme.
        switch option {
        case .solid:
            return WatchDesignTokens.canvas
        case .gradient:
            return theme.primaryColor
        case .aurora:
            return theme.secondaryColor
        case .ocean:
            return theme.primaryColor.opacity(0.7)
        }
    }

    // MARK: - Theme Picker (5 companions)

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("COMPANION THEME")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            HStack(spacing: 4) {
                ForEach(WatchFaceTheme.allCases, id: \.self) { option in
                    themeItem(option)
                }
            }
        }
    }

    private func themeItem(_ option: WatchFaceTheme) -> some View {
        let isSelected = option == theme
        return Button {
            themeRaw = option.rawValue
            WatchFacePreferences.setTheme(option)
            WatchConnectivityManager.shared.syncData(WatchFacePreferences.connectivityPayload())
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(option.primaryColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().stroke(WatchDesignTokens.separator, lineWidth: 0.5)
                        )
                    if isSelected {
                        // Accent-strong checkmark dot.
                        Circle()
                            .fill(WatchDesignTokens.accentStrong)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
                Text(option.displayName.prefix(3).uppercased())
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .tracking(0.02 * 7)
                    .foregroundStyle(WatchDesignTokens.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? WatchDesignTokens.accentSoft : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? option.primaryColor : .clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.displayName) theme\(isSelected ? ", selected" : "")")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchFaceSettingsView()
    }
}
#endif
