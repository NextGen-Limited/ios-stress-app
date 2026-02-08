import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var exportURL: URL?

    init() {
        _viewModel = State(initialValue: SettingsViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        Form {
            Section("Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your Name", text: $viewModel.userProfile.name)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Resting HR")
                    Spacer()
                    Text("\(Int(viewModel.userProfile.restingHeartRate)) bpm")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Baseline HRV")
                    Spacer()
                    Text("\(Int(viewModel.userProfile.baselineHRV)) ms")
                        .foregroundColor(.secondary)
                }
            }

            Section("Notifications") {
                Toggle("High Stress Alerts", isOn: $viewModel.notificationSettings.highStressAlerts)
                Toggle("Daily Reminders", isOn: $viewModel.notificationSettings.dailyReminders)
                Toggle("Weekly Report", isOn: $viewModel.notificationSettings.weeklyReport)
            }

            // MARK: - Data Management Section
            Section("Data Management") {
                // CloudKit Sync Status
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(viewModel.cloudKitStatus.color)
                    Text("iCloud Sync")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.cloudKitStatus.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("iCloud sync status: \(viewModel.cloudKitStatus.statusText)")

                NavigationLink(destination: DataExportView()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primaryBlue)
                        Text("Export Data")
                    }
                }
                .accessibilityLabel("Export data")

                NavigationLink(destination: DataDeleteView()) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.error)
                        Text("Delete Data")
                            .foregroundColor(.primary)
                    }
                }
                .accessibilityLabel("Delete data")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("2025.01.19")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            viewModel = SettingsViewModel(modelContext: modelContext)
            Task { await viewModel.loadUserProfile() }
        }
        .sheet(isPresented: $showingDeleteConfirmation) {
            deleteConfirmationSheet
        }
    }

    private var deleteConfirmationSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.error)

                Text("Delete All Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This will permanently delete all your stress measurements. This action cannot be undone.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(role: .destructive, action: {
                        Task {
                            try? await viewModel.deleteAllMeasurements()
                        }
                        showingDeleteConfirmation = false
                    }) {
                        Text("Delete Everything")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.error)
                            .cornerRadius(26)
                    }

                    Button(action: { showingDeleteConfirmation = false }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(26)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Confirm Deletion")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func shareExport(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
