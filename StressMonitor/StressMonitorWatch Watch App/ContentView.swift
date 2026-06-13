import SwiftUI

/// Root watch UI: a swipeable page tab view across the three screens.
///
/// - **Home** — character-reactive face (no score)
/// - **Breathe** — 4-7-8 guided breathing
/// - **History** — last 7 days, colour-coded
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
    }
    .tabViewStyle(.page)
    .background(StressCharacterPalette.darkCanvas.ignoresSafeArea())
  }
}

#if DEBUG
#Preview {
  ContentView()
}
#endif
