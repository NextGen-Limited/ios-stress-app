import SwiftUI

/// Root watch UI: a swipeable page tab view across the seven screens.
///
/// - **Home** — semicircle gauge hero with score + Ripple companion
/// - **Breathe** — 4-7-8 guided breathing
/// - **History** — 7-day log with stats, chart, Bio Age, and reading list
/// - **Logging** — daily habit check-in + mood picker
/// - **Workout** — live HR zone display during workout sessions
/// - **Cycle** — menstrual cycle phase tracking with stress correlation
/// - **Watch Face** — complication customization + seasonal themes + tier names
///
/// The canvas is the iOS light grouped background (`--bg #F2F2F7`); each
/// screen composes its own background on top of this base.
struct ContentView: View {
    @State private var viewModel = WatchStressViewModel()

    var body: some View {
        TabView {
            WatchHomeView(viewModel: viewModel)
                .tag(0)

            WatchBreatheView()
                .tag(1)

            NavigationStack {
                WatchHistoryView(viewModel: viewModel)
            }
            .tag(2)

            NavigationStack {
                WatchLoggingView()
            }
            .tag(3)

            NavigationStack {
                WatchWorkoutView()
            }
            .tag(4)

            NavigationStack {
                WatchCycleView()
            }
            .tag(5)

            NavigationStack {
                WatchFaceSettingsView()
            }
            .tag(6)
        }
        .tabViewStyle(.page)
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
