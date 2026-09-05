import SwiftUI

/// Watch **Home** screen — stress readout hero.
///
/// Full-bleed light canvas with the watch-face tint. A semicircle gauge
/// halo arcs above the Ripple otter; the rounded stress score and tier
/// label sit beneath the character, followed by an "out of 100" caption.
/// Mirrors the Open Design Home screen (semicircle gauge + otter hero +
/// compact readout).
struct WatchHomeView: View {
    @Bindable var viewModel: WatchStressViewModel

    @AppStorage(
        WatchFacePreferences.Keys.theme,
        store: WatchFacePreferences.defaults
    ) private var themeRaw: String = WatchFacePreferences.defaultTheme.rawValue

    private var theme: WatchFaceTheme { WatchFaceTheme(rawValue: themeRaw) ?? .ripple }
    private var creature: CharacterCreature { theme.creature }
    private var category: StressCategory { StressCategory.category(for: viewModel.currentLevel) }
    private var score: Int { Int(viewModel.currentLevel.rounded()) }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)

            // Semicircle gauge halo + character layered together so the
            // arc reads as a halo behind the otter.
            ZStack {
                SemicircleStressGauge(
                    score: viewModel.currentLevel,
                    radius: 55,
                    strokeWidth: 10
                )
                .offset(y: -6)

                CharacterFaceView(
                    creature: creature,
                    category: category,
                    size: 112,
                    showsHalo: true
                )
            }

            Spacer(minLength: 0)

            readout
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(homeBackground.ignoresSafeArea())
        .task {
            await viewModel.requestAuthorization()
            await viewModel.loadLatestStress()
        }
    }

    // MARK: - Subviews

    /// Compact numeric readout: big rounded score in tier ink, mono
    /// uppercase tier label in tier colour, and an "out of 100" caption.
    private var readout: some View {
        VStack(spacing: 3) {
            Text("\(score)")
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: fixed full-bleed hero composition, no scroll container; readout accessibility-labeled
                .tracking(-0.028 * 42)
                .foregroundStyle(category.inkColor)
                .contentTransition(.numericText(value: Double(score)))

            Text(category.displayName.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced)) // dated exception 2026-09-05: fixed full-bleed hero composition, no scroll container; readout accessibility-labeled
                .tracking(0.08 * 9)
                .foregroundStyle(category.color)

            Text("out of 100")
                .font(.system(size: 9.5, weight: .regular, design: .default)) // dated exception 2026-09-05: fixed full-bleed hero composition, no scroll container; readout accessibility-labeled
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .accessibilityElement()
        .accessibilityLabel(category.accessibilityValue(level: viewModel.currentLevel))
    }

    // MARK: - Helpers

    private var homeBackground: some View {
        ZStack {
            WatchDesignTokens.canvas
            WatchFaceBackgroundView(
                style: WatchFacePreferences.backgroundStyle,
                theme: theme
            )
            .opacity(0.5)
        }
    }
}

#if DEBUG
#Preview {
    WatchHomeView(viewModel: WatchStressViewModel())
}
#endif
