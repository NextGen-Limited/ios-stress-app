import AnimatedTabBar
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home
    @State private var showSettings = false

    /// Enable mock data mode for development/simulator testing
    /// Set to true to see sample data without real HealthKit data
    static var useMockData: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
        #else
        return false
        #endif
    }()

    /// Convert TabItem to AnimatedTabBar index
    private var selectedIndex: Binding<Int> {
        Binding(
            get: { selectedTab.rawValue },
            set: { selectedTab = TabItem(rawValue: $0) ?? .home }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area with NavigationStack
            NavigationStack {
                Group {
                    switch selectedTab {
                    case .home:
                        if Self.useMockData {
                            DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel(), onSettingsTapped: {
                                showSettings = true
                            })
                        } else {
                            DashboardView(repository: StressRepository(modelContext: modelContext), onSettingsTapped: {
                                showSettings = true
                            })
                        }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar - hidden when showing Settings
            if !showSettings {
                AnimatedTabBar(
                    selectedIndex: selectedIndex,
                    prevSelectedIndex: .constant(0),
                    views: tabButtons(selectedIndex: selectedTab.rawValue)
                )
                .ballColor(.primaryBlue)
                .selectedColor(.primaryBlue)
                .unselectedColor(.gray)
                .cornerRadius(24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(.keyboard)
        .tint(.accentColor)
        .animation(.easeInOut(duration: 0.25), value: showSettings)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: StressMeasurement.self, inMemory: true)
}
