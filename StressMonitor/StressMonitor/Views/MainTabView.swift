import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home
    @State private var showSettings = false
    @State private var stressRepository: StressRepository?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabItem.home) {
                NavigationStack {
                    homeView
                        .navigationDestination(isPresented: $showSettings) {
                            SettingsView()
                        }
                }
            } label: {
                tabLabel(for: .home)
            }

            Tab(value: TabItem.action) {
                ActionView()
            } label: {
                tabLabel(for: .action)
            }

            Tab(value: TabItem.trend) {
                NavigationStack {
                    TrendsView()
                }
            } label: {
                tabLabel(for: .trend)
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
                    ),
                    onSettingsTapped: { showSettings = true }
                )
            } else {
                DashboardView(repository: repo, onSettingsTapped: { showSettings = true })
            }
            #else
            DashboardView(repository: repo, onSettingsTapped: { showSettings = true })
            #endif
        }
        // Empty until onAppear fills stressRepository (avoids throwaway repo on first body eval)
    }

    private func tabLabel(for tab: TabItem) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(selectedTab == tab ? "\(tab.iconName)-selected" : tab.iconName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        }
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
