import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home

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
            // Content area
            Group {
                switch selectedTab {
                case .home:
                    if Self.useMockData {
                        DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
                    } else {
                        DashboardView(repository: StressRepository(modelContext: modelContext))
                    }
                case .action:
                    ActionView()
                case .trend:
                    TrendsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Stress tab bar fixed at bottom
            StressTabBarView(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: StressMeasurement.self, inMemory: true)
}
