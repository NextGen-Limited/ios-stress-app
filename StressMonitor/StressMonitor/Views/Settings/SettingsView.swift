import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var navigateToExport = false
    @State private var navigateToDelete = false

    init() {
        _viewModel = State(initialValue: SettingsViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.settingsCardSpacing) {
                // Premium Card
                PremiumCard()
                    .padding(.top, 8)

                // Watch Face Card
                WatchFaceCard()

                // Data Sharing Card with navigation
                DataSharingCard()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigateToExport = true
                    }

                // Data Management Section
                dataManagementSection

                // Version Footer
                versionFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.adaptiveSettingsBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = SettingsViewModel(modelContext: modelContext)
            Task { await viewModel.loadUserProfile() }
        }
        .navigationDestination(isPresented: $navigateToExport) {
            DataExportView()
        }
        .navigationDestination(isPresented: $navigateToDelete) {
            DataDeleteView()
        }
        .sheet(isPresented: $showingDeleteConfirmation) {
            deleteConfirmationSheet
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(
                    icon: "externaldrive.badge.icloud",
                    title: "Data Management"
                )

                // CloudKit Sync Status
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(viewModel.cloudKitStatus.color)
                        .frame(width: 24)
                    Text("iCloud Sync")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.cloudKitStatus.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("iCloud sync status: \(viewModel.cloudKitStatus.statusText)")

                Divider()

                // Export Data
                Button {
                    navigateToExport = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primaryBlue)
                            .frame(width: 24)
                        Text("Export Data")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .accessibilityLabel("Export data")

                Divider()

                // Delete Data
                Button {
                    navigateToDelete = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.error)
                            .frame(width: 24)
                        Text("Delete Data")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .accessibilityLabel("Delete data")
            }
        }
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("StressMonitor")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textTertiary)
            Text("Version 1.0.0 (2025.01.19)")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Delete Confirmation Sheet

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
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
