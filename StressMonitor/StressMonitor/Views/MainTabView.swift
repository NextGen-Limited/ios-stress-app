import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

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
        TabView {
            if Self.useMockData {
                DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
                    .tabItem {
                        Label("Now", systemImage: "heart.fill")
                    }
                    .accessibilityIdentifier("DashboardTab")
                    .accessibilityLabel("Current stress level")
                    .accessibilityHint("View your current stress measurement")
            } else {
                DashboardView(repository: StressRepository(modelContext: modelContext))
                    .tabItem {
                        Label("Now", systemImage: "heart.fill")
                    }
                    .accessibilityIdentifier("DashboardTab")
                    .accessibilityLabel("Current stress level")
                    .accessibilityHint("View your current stress measurement")
            }

            MeasurementHistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
                .accessibilityIdentifier("HistoryTab")
                .accessibilityLabel("Stress history")
                .accessibilityHint("View past stress measurements")

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.xyaxis.line")
                }
                .accessibilityIdentifier("TrendsTab")
                .accessibilityLabel("Trends and patterns")
                .accessibilityHint("View your stress trends over time")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .accessibilityIdentifier("SettingsTab")
                .accessibilityLabel("Settings")
                .accessibilityHint("Configure app settings")
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: StressMeasurement.self, inMemory: true)
}
