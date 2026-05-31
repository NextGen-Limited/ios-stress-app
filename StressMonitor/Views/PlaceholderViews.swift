import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("Stress history will appear here")
                .navigationTitle("History")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings will appear here")
                .navigationTitle("Settings")
        }
    }
}
