import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            StressDashboardView()
                .tabItem {
                    Label("Now", systemImage: "heart.fill")
                }
                .accessibilityIdentifier("DashboardTab")
                .accessibilityLabel("Current stress level")
                .accessibilityHint("View your current stress measurement")

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
}
