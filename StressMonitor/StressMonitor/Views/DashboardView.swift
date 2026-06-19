import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StressViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var appeared = false
    @State private var appearAnimation = false
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
                repository: StressRepository(modelContext: ModelContext((try? ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))!))
            ))
        }
        self.onSettingsTapped = onSettingsTapped
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                dashboardContent(viewModel.currentStress)

            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            if !appeared {
                appeared = true
                // Load custom fonts in background — accepted trade-off: <200ms font flash on cold start only
                // Task {} (not Task.detached) — FontBlaster inferred MainActor in Swift 6 mode
                Task(priority: .utility) {
                    FontBlaster.blast()
                }
                // Show skeleton immediately, load data async
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

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(_ stress: StressResult?) -> some View {
        StressCharacterCard(
            result: stress,
            size: .dashboard,
            isRequestingAccess: viewModel.isRequestingAccess,
            onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } },
            onSettingsTapped: onSettingsTapped
        )

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
            rhrValue: stress.map { "\($0.heartRate)" } ?? "--",
            hrvValue: stress.map { "\($0.hrv)" } ?? "--",
            rrValue: stress != nil ? "14" : "--"
        )
        .opacity(appearAnimation ? 1 : 0)

        if let bioAge = viewModel.bioAgeResult {
            BioAgeCardView(result: bioAge)
                .opacity(appearAnimation ? 1 : 0)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }

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
        // Phase 3: Run baseline + dashboard data in parallel
        async let _: () = viewModel.loadBaseline()
        await viewModel.loadDashboardData()
        viewModel.observeHeartRate()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            appearAnimation = true
        }
    }
}

// MARK: - Previews

#Preview("Dashboard - With Mock Data") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
}

#Preview("Dashboard - No Data") {
    DashboardView(repository: StressRepository(modelContext: ModelContext((try? ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))!)))
}

#Preview("Dashboard - Dark Mode") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
