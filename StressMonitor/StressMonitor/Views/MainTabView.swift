import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home
    @State private var stressRepository: StressRepository?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabItem.home) {
                NavigationStack {
                    homeView
                }
            } label: {
                Label {
                    Text(TabItem.home.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .home))
                }
            }

            Tab(value: TabItem.action) {
                ActionView()
            } label: {
                Label {
                    Text(TabItem.action.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .action))
                }
            }

            Tab(value: TabItem.trend) {
                NavigationStack {
                    TrendsView()
                }
            } label: {
                Label {
                    Text(TabItem.trend.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .trend))
                }
            }

            Tab(value: TabItem.settings) {
                NavigationStack {
                    SettingsView()
                }
            } label: {
                Label {
                    Text(TabItem.settings.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .settings))
                }
            }
        }
        .tabBarMinimizeOnScroll()
        .onChange(of: selectedTab) {
            HapticManager.shared.buttonPress()
        }
        .onAppear {
            if stressRepository == nil {
                stressRepository = StressRepository(modelContext: modelContext)
            }
        }
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            if DemoMode.isEnabled {
                DemoModeBannerView()
                    .padding(.trailing, 16)
                    .padding(.top, 8)
            }
            #endif
        }
    }

    @ViewBuilder
    private var homeView: some View {
        if let repo = stressRepository {
            #if DEBUG
            if DemoMode.isEnabled {
                DashboardView(
                    viewModel: StressViewModel(
                        healthKit: SimulatorHealthKitService(),
                        algorithm: MultiFactorStressCalculator(),
                        repository: repo
                    )
                )
            } else {
                DashboardView(repository: repo)
            }
            #else
            DashboardView(repository: repo)
            #endif
        }
        // Empty until onAppear fills stressRepository (avoids throwaway repo on first body eval)
    }

    /// SF Symbol for a tab, switching to the filled variant when selected.
    private func tabSymbol(for tab: TabItem) -> String {
        selectedTab == tab ? tab.sfSymbolActive : tab.sfSymbol
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [StressMeasurement.self, CharacterUnlock.self], inMemory: true)
}

private extension View {
    @ViewBuilder
    func tabBarMinimizeOnScroll() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
