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
                StressTabBarView(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
