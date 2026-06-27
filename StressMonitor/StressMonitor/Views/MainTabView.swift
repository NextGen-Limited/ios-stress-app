import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(PaywallController.self) private var paywall
    @State private var stressRepository: StressRepository?

    // Per-tab navigation restoration (Axiom nav.md Pattern 6). `Route` is
    // Codable, so each path round-trips through `NavigationPath.CodableRepresentation`.
    // Defensive decode in `AppRouter.decodePath` drops corrupt/schema-shifted data.
    @SceneStorage("nav.home")     private var homeData: Data?
    @SceneStorage("nav.action")   private var actionData: Data?
    @SceneStorage("nav.trends")   private var trendsData: Data?
    @SceneStorage("nav.settings") private var settingsData: Data?
    @SceneStorage("nav.selectedTab") private var selectedTabData: Int?
    @State private var didRestore = false

    var body: some View {
        // `@Bindable` projects the environment-owned `PaywallController` so we
        // can drive `.fullScreenCover(item:)` off the singleton's `presentation`.
        @Bindable var paywall = paywall
        TabView(selection: Binding(get: { router.selectedTab }, set: { router.selectedTab = $0 })) {
            Tab(value: TabItem.home) {
                NavigationStack(path: router.binding(for: .home)) {
                    homeView
                        .stressNavigationDestinations()
                }
            } label: {
                Label {
                    Text(TabItem.home.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .home))
                }
            }

            Tab(value: TabItem.action) {
                NavigationStack(path: router.binding(for: .action)) {
                    ActionView()
                        .stressNavigationDestinations()
                }
            } label: {
                Label {
                    Text(TabItem.action.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .action))
                }
            }

            Tab(value: TabItem.trend) {
                NavigationStack(path: router.binding(for: .trend)) {
                    TrendsView()
                        .stressNavigationDestinations()
                }
            } label: {
                Label {
                    Text(TabItem.trend.title)
                } icon: {
                    Image(systemName: tabSymbol(for: .trend))
                }
            }

            Tab(value: TabItem.settings) {
                NavigationStack(path: router.binding(for: .settings)) {
                    SettingsView()
                        .stressNavigationDestinations()
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
        .onChange(of: router.selectedTab) {
            HapticManager.shared.buttonPress()
            selectedTabData = router.selectedTab.rawValue
        }
        .onAppear {
            if stressRepository == nil {
                stressRepository = StressRepository(modelContext: modelContext)
            }
            restoreNavigationIfNeeded()
        }
        // Persist on push/pop (counts change). NavigationPath isn't Equatable,
        // but every push/pop changes `.count`, so counts are a sufficient trigger.
        .onChange(of: router.homePath.count)     { homeData     = AppRouter.encodePath(router.homePath) }
        .onChange(of: router.actionPath.count)   { actionData   = AppRouter.encodePath(router.actionPath) }
        .onChange(of: router.trendsPath.count)   { trendsData   = AppRouter.encodePath(router.trendsPath) }
        .onChange(of: router.settingsPath.count) { settingsData = AppRouter.encodePath(router.settingsPath) }
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            if DemoMode.isEnabled {
                DemoModeBannerView()
                    .padding(.trailing, 16)
                    .padding(.top, 8)
            }
            #endif
        }
        // Paywall sits ABOVE the entire TabView (all tabs + their navigation
        // stacks). The controller is owned at the app root and injected via
        // environment so any descendant can call `paywall.present(reason:)`.
        .fullScreenCover(item: $paywall.presentation) { presentation in
            PaywallView(reason: presentation.reason)
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
        router.selectedTab == tab ? tab.sfSymbolActive : tab.sfSymbol
    }

    /// One-shot restore of per-tab navigation paths + selected tab from
    /// `@SceneStorage`. Idempotent guard via `didRestore`. Decoding failures
    /// (corrupt data, schema change) yield an empty path — never a crash.
    private func restoreNavigationIfNeeded() {
        guard !didRestore else { return }
        didRestore = true
        router.homePath = AppRouter.decodePath(homeData)
        router.actionPath = AppRouter.decodePath(actionData)
        router.trendsPath = AppRouter.decodePath(trendsData)
        router.settingsPath = AppRouter.decodePath(settingsData)
        if let raw = selectedTabData, let tab = TabItem(rawValue: raw) {
            router.selectedTab = tab
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppRouter())
        .environment(PaywallController())
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
