import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingExport = false
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

            Section("Data") {
                Button(action: { showingExport = true }) {
                    HStack {
                        Text("Export Data")
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete All Data")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
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
        .sheet(isPresented: $showingExport) {
            ExportOptionsView(settings: $viewModel.exportSettings) {
                handleExport()
            }
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

    private func handleExport() {
        showingExport = false

        // Create CSV export
        let csv = "Timestamp,HRV,Heart Rate,Stress Level\n\(Date()),65,60,42"

        if let url = createExportFile(content: csv, format: .csv) {
            exportURL = url
            shareExport(url: url)
        }
    }

    private func createExportFile(content: String, format: ExportFormat) -> URL? {
        let fileName = "stress_data_\(Int(Date().timeIntervalSince1970)).\(format == .csv ? "csv" : "json")"

        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = url.appendingPathComponent(fileName)
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        }
        return nil
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

struct ExportOptionsView: View {
    @Binding var settings: ExportSettings
    let onExport: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Data to Include") {
                    Toggle("Include HRV", isOn: $settings.includeHRV)
                    Toggle("Include Heart Rate", isOn: $settings.includeHeartRate)
                    Toggle("Include Stress Level", isOn: $settings.includeStressLevel)
                }

                Section("Date Range") {
                    Picker("Range", selection: $settings.dateRange) {
                        ForEach(ExportDateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }

                Section("Format") {
                    Picker("Format", selection: $settings.format) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }

                Section {
                    Button(action: onExport) {
                        Text("Export")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
