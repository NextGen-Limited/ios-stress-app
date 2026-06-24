import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StressViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var appeared = false
    @State private var appearAnimation = false

    init(viewModel: StressViewModel? = nil, repository: StressRepository? = nil) {
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
    }

    var body: some View {
        Group {
            if viewModel.isPermissionRequired {
                permissionStateView
            } else if viewModel.isLoading && viewModel.currentStress == nil {
                readingStateView
            } else {
                readyStateView
            }
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

    // MARK: - Permission Required (HealthKit notDetermined / denied)

    private var permissionStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                PermissionCardView(
                    permissionType: .healthKit,
                    isLoading: viewModel.isRequestingAccess,
                    onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } }
                )
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Reading / Loading Skeleton

    private var readingStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                NoDataCard(dataType: .stress, onAction: { Task { await viewModel.loadCurrentStress() } })
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                SkeletonBlock(height: 180)
                    .padding(.horizontal, 16)
                SkeletonBlock(height: 90)
                    .padding(.horizontal, 16)
                SkeletonBlock(height: 90)
                    .padding(.horizontal, 16)
                SkeletonBlock(height: 140)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Ready Dashboard Content

    private var readyStateView: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                dashboardContent(viewModel.currentStress)

            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Dashboard Content (9 sections, Home tab)

    @ViewBuilder
    private func dashboardContent(_ stress: StressResult?) -> some View {
        // 1. Date header + stress / streak status chips
        VStack(alignment: .leading, spacing: 12) {
            DateHeaderView()
            statusChipRow(stress)
        }
        .opacity(appearAnimation ? 1 : 0)

        // 2. Hero semicircular gauge with Ripple inside
        SemicircularGaugeView(
            stressLevel: stress?.level ?? 0,
            result: stress,
            size: 280
        )
        .opacity(appearAnimation ? 1 : 0)

        // 3. AI insight — prefer generated insight, fall back to SmartInsightsCard
        if let insight = viewModel.aiInsight {
            AIInsightCard(
                insight: insight,
                onTapAction: nil
            )
            .opacity(appearAnimation ? 1 : 0)
        } else {
            SmartInsightsCard()
                .opacity(appearAnimation ? 1 : 0)
        }

        // 4. Vitals triplet — RHR / HRV / RR (RR slot hidden when nil)
        TripleMetricRow(
            rhrValue: stress.map { "\($0.heartRate)" } ?? "--",
            hrvValue: stress.map { "\($0.hrv)" } ?? "--",
            rrValue: respiratoryDisplayValue(stress)
        )
        .opacity(appearAnimation ? 1 : 0)

        // 5. Mood check-in chips
        MoodCheckInView(selected: viewModel.mood?.level) { level in
            viewModel.setMood(level)
        }
        .opacity(appearAnimation ? 1 : 0)

        // 6. Health data — Exercise / Sleep / Daylight
        HealthDataSection()
            .opacity(appearAnimation ? 1 : 0)

        // 7. Quick actions — Box Breathing + Mini Walk cards
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionCard.boxBreathing()
                QuickActionCard.miniWalk()
            }
            .padding(.horizontal, 4)
        }
        .opacity(appearAnimation ? 1 : 0)

        // 8. Stress over 7-day chart
        StressOverTimeChart()
            .opacity(appearAnimation ? 1 : 0)

        // 9. Premium banner — tap navigates to paywall
        NavigationLink {
            IAPPremiumView(
                storeKit: StoreKitService(premiumState: PremiumState.shared),
                premiumState: PremiumState.shared
            )
        } label: {
            PremiumBanner()
        }
        .buttonStyle(.plain)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Status Chips

    @ViewBuilder
    private func statusChipRow(_ stress: StressResult?) -> some View {
        HStack(spacing: 8) {
            if let category = stress?.category {
                StatusBadgeView(category: category, style: .standard)
            } else {
                StatusBadgeView(category: .relaxed, style: .standard)
            }
            streakChip
            Spacer()
        }
    }

    private var streakChip: some View {
        HStack(spacing: 6) {
            Image(systemName: AppIconSystem.Metric.streak.sfSymbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HomeCharacterDesignTokens.Ember.accent)
            Text("\(max(1, viewModel.todayMeasurements.count)) day")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(HomeCharacterDesignTokens.Ember.accent.opacity(0.14))
        .clipShape(Capsule())
        .accessibilityLabel("Tracking streak")
    }

    /// RR display string. Returns "--" when there is no stress result OR when
    /// RR data is unavailable (simulator) so the slot reads as empty, not zero.
    private func respiratoryDisplayValue(_ stress: StressResult?) -> String {
        guard stress != nil, let rr = viewModel.respiratoryRate else { return "--" }
        return String(format: "%.0f", rr.rounded())
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
