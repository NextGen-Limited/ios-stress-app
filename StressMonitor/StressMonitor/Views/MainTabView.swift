import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Now", systemImage: "heart.fill")
                }
                .accessibilityIdentifier("DashboardTab")
                .accessibilityLabel("Current stress level")
                .accessibilityHint("View your current stress measurement")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
                .accessibilityIdentifier("HistoryTab")
                .accessibilityLabel("Stress history")
                .accessibilityHint("View past stress measurements")

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
