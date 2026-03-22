import AnimatedTabBar
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home
    @State private var previousTab: TabItem = .home
    @State private var showSettings = false
    @State private var tabBarScrollState = TabBarScrollState()

    /// Demo mode: uses SimulatorHealthKitService with dynamic data
    private static var isDemoMode: Bool {
        #if DEBUG
        return DemoMode.isEnabled
        #else
        return false
        #endif
    }

    /// Convert TabItem to AnimatedTabBar index
    private var selectedIndex: Binding<Int> {
        Binding(
            get: { selectedTab.rawValue },
            set: { newValue in
                guard newValue != selectedTab.rawValue else { return }
                previousTab = selectedTab
                selectedTab = TabItem(rawValue: newValue) ?? .home
                HapticManager.shared.buttonPress()
                tabBarScrollState.resetToVisible()
            }
        )
    }

    /// Previous tab index binding for AnimatedTabBar animation
    private var previousTabIndex: Binding<Int> {
        Binding(
            get: { previousTab.rawValue },
            set: { previousTab = TabItem(rawValue: $0) ?? .home }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area with NavigationStack
            NavigationStack {
                Group {
                    switch selectedTab {
                    case .home:
                        #if DEBUG
                        if DemoMode.isEnabled {
                            DashboardView(
                                viewModel: StressViewModel(
                                    healthKit: SimulatorHealthKitService(),
                                    algorithm: MultiFactorStressCalculator(),
                                    repository: StressRepository(modelContext: modelContext)
                                ),
                                onSettingsTapped: { showSettings = true }
                            )
                        } else {
                            DashboardView(repository: StressRepository(modelContext: modelContext), onSettingsTapped: {
                                showSettings = true
                            })
                        }
                        #else
                        DashboardView(repository: StressRepository(modelContext: modelContext), onSettingsTapped: {
                            showSettings = true
                        })
                        #endif
                    case .action:
                        ActionView()
                    case .trend:
                        TrendsView()
                    }
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView()
                }
            }
            .environment(tabBarScrollState)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar - hidden when showing Settings
            if !showSettings {
                AnimatedTabBar(
                    selectedIndex: selectedIndex,
                    prevSelectedIndex: previousTabIndex,
                    views: tabButtons(selectedIndex: selectedTab.rawValue)
                )
                .selectedColor(.primaryBlue)
                .unselectedColor(.tabBarUnselected)
                .ballColor(.accentTeal)
//                .ballTrajectory(.parabolic)
                .verticalPadding(16)
                .cornerRadius(24)
                .buttonShadow()
                .padding(.horizontal, 16)
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            tabBarScrollState.tabBarHeight = proxy.size.height
                        }
                    }
                )
                .offset(y: tabBarScrollState.isVisible ? 0 : tabBarScrollState.tabBarHeight + 16)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarScrollState.isVisible)
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
}

#Preview {
    MainTabView()
        .modelContainer(for: StressMeasurement.self, inMemory: true)
}
