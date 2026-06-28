import SwiftUI

/// Watch **Home** screen — stress readout hero.
///
/// Light canvas with the watch-face tint, framing a single large Ripple
/// character in a radial halo with its ambient breathing scale animation,
/// centered on the watch face.
struct WatchHomeView: View {
    @Bindable var viewModel: WatchStressViewModel

    @AppStorage(
        WatchFacePreferences.Keys.theme,
        store: WatchFacePreferences.defaults
    ) private var themeRaw: String = WatchFacePreferences.defaultTheme.rawValue

    private var theme: WatchFaceTheme { WatchFaceTheme(rawValue: themeRaw) ?? .ripple }
    private var creature: CharacterCreature { theme.creature }
    private var category: StressCategory { StressCategory.category(for: viewModel.currentLevel) }

    var body: some View {
        characterHalo
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(homeBackground.ignoresSafeArea())
            .task {
                await viewModel.requestAuthorization()
                await viewModel.loadLatestStress()
            }
    }

    // MARK: - Subviews

    private var characterHalo: some View {
        CharacterFaceView(
            creature: creature,
            category: category,
            size: 110,
            showsHalo: true
        )
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
