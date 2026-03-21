import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var viewModel: SettingsViewModel
    @State private var navigateToExport = false
    @State private var navigateToDelete = false
    @State private var docsURL: URL? = nil

    init() {
        _viewModel = State(initialValue: SettingsViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.settingsCardSpacing) {
                // Widget CTA
                PremiumCard()
                    .padding(.top, 8)

                // Watch face & Complications
                WatchFaceCard()

                // iOS Widget
                WidgetCard()

                // Health Data
                HealthDataCard(onSyncNow: {
                    Task { await viewModel.loadUserProfile() }
                })

                // Notifications
                NotificationsCard(
                    snapshotTipsEnabled: $viewModel.notificationSettings.snapshotTipsEnabled,
                    morningPreviewEnabled: $viewModel.notificationSettings.morningPreviewEnabled,
                    notificationIntensity: $viewModel.notificationSettings.intensity,
                    quietHoursStart: $viewModel.notificationSettings.quietHoursStart,
                    quietHoursEnd: $viewModel.notificationSettings.quietHoursEnd
                )

                // Privacy
                PrivacyCard(
                    iCloudSyncEnabled: $viewModel.iCloudSyncEnabled,
                    onExportCSV: { navigateToExport = true }
                )

                // About and Support
                AboutCard(
                    onHelp: { docsURL = DocsURL.help },
                    onContactSupport: { openURLString("mailto:support@stressmonitor.app") },
                    onPrivacyPolicy: { docsURL = DocsURL.privacy },
                    onTermsOfService: { docsURL = DocsURL.terms }
                )
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
        .sheet(item: $docsURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Helpers

    private func openURLString(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
