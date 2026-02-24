import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StressViewModel
    @State private var appeared = false
    @State private var appearAnimation = false

    init(viewModel: StressViewModel? = nil, repository: StressRepository? = nil) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else if let repository = repository {
            _viewModel = State(initialValue: StressViewModel(
                healthKit: HealthKitManager(),
                algorithm: StressCalculator(),
                repository: repository
            ))
        } else {
            // Fallback with in-memory container for previews
            _viewModel = State(initialValue: StressViewModel(
                healthKit: HealthKitManager(),
                algorithm: StressCalculator(),
                repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
            ))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.currentStress == nil {
                    loadingView
                } else if let stress = viewModel.currentStress {
                    content(stress)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Now")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
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
        // Use the existing viewModel but update its repository with the real modelContext
        // Note: We pass the repository during init in production via MainTabView
        await viewModel.loadDashboardData()
        await viewModel.loadBaseline()
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
        .background(Color.oledBackground)
    }

    private func content(_ stress: StressResult) -> some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Layout.sectionSpacing) {
                // 1. Greeting Header
                greetingHeader
                    .transition(.opacity.combined(with: .move(edge: .top)))

                // 2. Hero Stress Ring (260pt)
                StressRingView(stressLevel: stress.level, category: stress.category)
                    .frame(height: 300)
                    .scaleEffect(appearAnimation ? 1 : 0.9)
                    .opacity(appearAnimation ? 1 : 0)
                    .accessibilityLabel("Stress level indicator")
                    .accessibilityValue("\(Int(stress.level)) out of 100, \(stress.category.rawValue) stress")
                    .accessibilityHint("Visual representation of your current stress level")

                // 3. Metrics Row (HRV + HR)
                metricsRow
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)

                // 4. Live Heart Rate (conditional)
                if viewModel.liveHeartRate != nil {
                    liveHeartRateCard
                        .offset(y: appearAnimation ? 0 : 20)
                        .opacity(appearAnimation ? 1 : 0)
                }

                // 5. Daily Timeline
                DailyTimelineView(
                    measurements: viewModel.todayMeasurements,
                    isExpanded: false
                )
                .offset(y: appearAnimation ? 0 : 20)
                .opacity(appearAnimation ? 1 : 0)

                // 6. Weekly Insight
                WeeklyInsightCard(
                    currentWeekAvg: viewModel.weeklyCurrentAvg,
                    lastWeekAvg: viewModel.weeklyPreviousAvg,
                    startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                    endDate: Date()
                )
                .offset(y: appearAnimation ? 0 : 20)
                .opacity(appearAnimation ? 1 : 0)

                // 7. AI Insight (conditional)
                if let insight = viewModel.aiInsight {
                    AIInsightCard(insight: insight)
                        .offset(y: appearAnimation ? 0 : 20)
                        .opacity(appearAnimation ? 1 : 0)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(Color.oledBackground)
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(greeting)
                .font(.system(size: DesignTokens.Typography.title, weight: .bold))
                .foregroundColor(.white)
                .accessibilityLabel(greeting)
                .accessibilityAddTraits(.isHeader)

            Text("Here's your current stress level")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(Color.oledTextSecondary)
                .accessibilityLabel("Current stress level overview")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            MetricCardView.hrv(
                value: String(Int(viewModel.currentStress?.hrv ?? 0)),
                chartData: viewModel.hrvHistory
            )

            MetricCardView.heartRate(
                value: String(Int(viewModel.currentStress?.heartRate ?? 0)),
                trendValue: heartRateTrendValue,
                isDown: viewModel.heartRateTrend == .down
            )
        }
    }

    private var heartRateTrendValue: String {
        switch viewModel.heartRateTrend {
        case .up: return "+2 bpm"
        case .down: return "-2 bpm"
        case .stable: return "—"
        }
    }

    // MARK: - Live Heart Rate Card

    private var liveHeartRateCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundColor(.heartRateAccent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Live Heart Rate")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(Color.oledTextSecondary)

                Text("\(Int(viewModel.liveHeartRate ?? 0)) bpm")
                    .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(DesignTokens.Layout.cardPadding)
        .background(Color.oledCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live heart rate")
        .accessibilityValue("\(Int(viewModel.liveHeartRate ?? 0)) beats per minute")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.oledTextSecondary)
                .accessibilityHidden(true)

            Text("No stress data available")
                .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                .foregroundColor(.white)
                .accessibilityLabel("No stress data available")
                .accessibilityAddTraits(.isHeader)

            Text("Data will appear automatically when HealthKit has readings")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(Color.oledTextSecondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Stress data will refresh automatically from HealthKit")
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.oledBackground)
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
