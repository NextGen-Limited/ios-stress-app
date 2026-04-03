import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var viewModel: StressViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var appeared = false
    @State private var appearAnimation = false
    @State private var docsURL: URL?
    var onSettingsTapped: (() -> Void)?

    init(viewModel: StressViewModel? = nil, repository: StressRepository? = nil, onSettingsTapped: (() -> Void)? = nil) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else if let repository = repository {
            _viewModel = State(initialValue: StressViewModel(
                healthKit: HealthKitManager(),
                algorithm: MultiFactorStressCalculator(),
                repository: repository
            ))
        } else {
            _viewModel = State(initialValue: StressViewModel(
                healthKit: HealthKitManager(),
                algorithm: MultiFactorStressCalculator(),
                repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
            ))
        }
        self.onSettingsTapped = onSettingsTapped
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                switch viewModel.renderState {
                case .loading:
                    loadingContent
                case .permissionRequired:
                    permissionContent
                case .noData:
                    noDataContent
                case .content(let stress):
                    dashboardContent(stress)
                }

                Spacer()
                    .frame(height: tabBarScrollState.tabBarHeight + 16)
            }
            .padding()
        }
        .trackScrollOffsetForTabBar(state: tabBarScrollState)
        .background(Color.Wellness.adaptiveBackground)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(item: $docsURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .task {
            if !appeared {
                appeared = true
                await loadInitialData()
                viewModel.startAutoRefresh()
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && viewModel.isPermissionRequired {
                Task { await viewModel.loadCurrentStress() }
            }
        }
    }

    // MARK: - Loading Content

    @ViewBuilder
    private var loadingContent: some View {
        StressCharacterCard(result: nil, size: .dashboard, onSettingsTapped: onSettingsTapped)
            .opacity(appearAnimation ? 1 : 0)

        SkeletonBlock(height: 80)
        SkeletonBlock(height: 120)
        SkeletonBlock(height: 200)
    }

    // MARK: - Permission Required Content

    @ViewBuilder
    private var permissionContent: some View {
        StressCharacterCard(
            result: nil,
            size: .dashboard,
            isRequestingAccess: viewModel.isRequestingAccess,
            onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } },
            onSettingsTapped: onSettingsTapped
        )

        SkeletonBlock(height: 80)
        SkeletonBlock(height: 120)
        SkeletonBlock(height: 200)
    }

    // MARK: - No Data Content

    @ViewBuilder
    private var noDataContent: some View {
        StressCharacterCard(
            result: nil,
            size: .dashboard,
            onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } },
            onSettingsTapped: onSettingsTapped
        )

        VStack(spacing: 16) {
            Button(action: measureFirstStress) {
                Label("Take First Measurement", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Take your first stress measurement")

            Button(action: showHelpDocumentation) {
                HStack(spacing: 4) {
                    Text("Learn How It Works")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.primaryBlue)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Learn how stress monitoring works")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(_ stress: StressResult) -> some View {
        StressCharacterCard(result: stress, size: .dashboard, onSettingsTapped: onSettingsTapped)

        if let qualityInfo = viewModel.dataQualityInfo {
            HStack {
                DataQualityBadge(qualityInfo: qualityInfo)
                Spacer()
            }
            .opacity(appearAnimation ? 1 : 0)
        }

        if let insight = viewModel.aiInsight {
            DashboardInsightCard(
                title: "Today's Insight",
                description: insight.message
            )
            .opacity(appearAnimation ? 1 : 0)
        }

        TripleMetricRow(
            rhrValue: "\(Int(stress.heartRate))",
            hrvValue: "\(Int(stress.hrv))",
            rrValue: "14"
        )
        .opacity(appearAnimation ? 1 : 0)

        SelfNoteCard()
            .opacity(appearAnimation ? 1 : 0)

        SectionHeader(title: "Your health data", icon: "heart.fill")
            .opacity(appearAnimation ? 1 : 0)

        HealthDataSection()
            .opacity(appearAnimation ? 1 : 0)

        SectionHeader(title: "Quick Action", icon: "bolt.fill")
            .opacity(appearAnimation ? 1 : 0)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionCard.miniWalk()
                QuickActionCard.boxBreathing()
                QuickActionCard.gratitude()
            }
            .padding(.horizontal, 4)
        }
        .opacity(appearAnimation ? 1 : 0)

        SectionHeader(title: "Stress over time", icon: "chart.bar.fill")
            .opacity(appearAnimation ? 1 : 0)

        StressOverTimeChart()
            .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Helpers

    private func loadInitialData() async {
        await viewModel.loadBaseline()
        await viewModel.loadDashboardData()
        viewModel.observeHeartRate()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            appearAnimation = true
        }
    }

    private func measureFirstStress() {
        Task {
            do {
                try await viewModel.calculateAndSaveStress()
                await viewModel.loadDashboardData()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private func showHelpDocumentation() {
        docsURL = DocsURL.help
    }
}

// MARK: - Previews

#Preview("Dashboard - With Mock Data") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
}

#Preview("Dashboard - Permission Required") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    viewModel.isPermissionRequired = true
    return DashboardView(viewModel: viewModel)
}

#Preview("Dashboard - Dark Mode") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
