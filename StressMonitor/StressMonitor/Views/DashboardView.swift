import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var viewModel: StressViewModel
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
            // Fallback with in-memory container for previews
            _viewModel = State(initialValue: StressViewModel(
                healthKit: HealthKitManager(),
                algorithm: MultiFactorStressCalculator(),
                repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
            ))
        }
        self.onSettingsTapped = onSettingsTapped
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.currentStress == nil {
                loadingView
            } else if let stress = viewModel.currentStress {
                content(stress)
            } else {
                emptyState
            }
        }
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
                await loadInitialData()
                viewModel.startAutoRefresh()
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private func loadInitialData() async {
        await viewModel.loadBaseline()
        await viewModel.loadDashboardData()
        viewModel.observeHeartRate()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            appearAnimation = true
        }
    }

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading stress data...")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Wellness.adaptiveBackground)
    }

    // MARK: - Main Content

    private func content(_ stress: StressResult) -> some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 1. Stress Character Card (includes date header, status, last updated)
                StressCharacterCard(result: stress, size: .dashboard, onRefresh: {
                    Task { await viewModel.loadDashboardData() }
                }, onSettingsTapped: onSettingsTapped)

                if let qualityInfo = viewModel.dataQualityInfo {
                    HStack {
                        DataQualityBadge(qualityInfo: qualityInfo)
                        Spacer()
                    }
                    .opacity(appearAnimation ? 1 : 0)
                }

                // 2. Insight Card
                if let insight = viewModel.aiInsight {
                    DashboardInsightCard(
                        title: "Today's Insight",
                        description: insight.message
                    )
                    .opacity(appearAnimation ? 1 : 0)
                }

                // 5. Triple Metric Row
                TripleMetricRow(
                    rhrValue: "\(Int(stress.heartRate))",
                    hrvValue: "\(Int(stress.hrv))",
                    rrValue: "14"
                )
                .opacity(appearAnimation ? 1 : 0)

                // 6. Self Note Card
                SelfNoteCard()
                    .opacity(appearAnimation ? 1 : 0)

                // 7. Your Health Data Section
                SectionHeader(title: "Your health data", icon: "heart.fill")
                    .opacity(appearAnimation ? 1 : 0)

                HealthDataSection()
                    .opacity(appearAnimation ? 1 : 0)

                // 8. Quick Action Section
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

                // 9. Stress Over Time Section
                SectionHeader(title: "Stress over time", icon: "chart.bar.fill")
                    .opacity(appearAnimation ? 1 : 0)

                StressOverTimeChart()
                    .opacity(appearAnimation ? 1 : 0)

                // Bottom padding for tab bar
                Spacer()
                    .frame(height: tabBarScrollState.tabBarHeight + 16)
            }
            .padding()
        }
        .trackScrollOffsetForTabBar(state: tabBarScrollState)
        .background(Color.Wellness.adaptiveBackground)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.Wellness.adaptiveSecondaryText)
                .accessibilityHidden(true)

            Text("No stress data available")
                .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .accessibilityLabel("No stress data available")
                .accessibilityAddTraits(.isHeader)

            Text("Data will appear automatically when HealthKit has readings")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Stress data will refresh automatically from HealthKit")
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Wellness.adaptiveBackground)
    }
}

// MARK: - Previews

#Preview("Dashboard - With Mock Data") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
}

#Preview("Dashboard - Empty State") {
    DashboardView()
}

#Preview("Dashboard - Dark Mode") {
    let viewModel = PreviewDataFactory.mockDashboardViewModel()
    DashboardView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
