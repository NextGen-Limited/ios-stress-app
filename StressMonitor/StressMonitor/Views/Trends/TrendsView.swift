import SwiftUI
import SwiftData

// MARK: - TrendsView (Light Theme Redesign)
//
// Six sections matching `06-trends.html`:
//   1. Editorial summary — computed from this week's daily stress
//   2. Daily stress bars (7d) — reuses StressBarChartView
//   3. Distribution stacked bar — DistributionBar (sums to 100%)
//   4. Calendar heatmap — MonthlyCalendarHeatmap (current month, today outlined)
//   5. HRV trend line — HRVTrendChart (52 ms reference)
//   6. Editorial insight — inline Text

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TrendsViewModel
    @State private var navigateToPremium = false

    /// Allocated once, not per view re-evaluation. `.task` swaps in the real
    /// environment `modelContext` on first appearance.
    private static let placeholderContext: ModelContext = {
        let container = try? ModelContainer(
            for: StressMeasurement.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container!)
    }()

    init() {
        _viewModel = State(initialValue: TrendsViewModel(modelContext: Self.placeholderContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    editorialHeader
                    dailyBars
                    distributionCard
                    calendarCard
                    hrvCard
                    editorialInsight
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel = TrendsViewModel(modelContext: modelContext)
                await viewModel.loadTrendData()
            }
            .navigationDestination(isPresented: $navigateToPremium) {
                IAPPremiumView(storeKit: Self.makeStoreKitService(), premiumState: PremiumState.shared)
            }
        }
    }

    #if DEBUG
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        MockStoreKitService(premiumState: PremiumState.shared)
    }
    #else
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        StoreKitService(premiumState: PremiumState.shared)
    }
    #endif

    // MARK: - 1. Editorial Summary

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your week")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)

            Text(viewModel.editorialSummary)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - 2. Daily Stress Bars (7d)

    private var dailyBars: some View {
        StressBarChartView(
            dailyStress: viewModel.dailyStressData,
            distribution: viewModel.stressDistribution,
            selectedTimeRange: $viewModel.selectedTimeRange
        )
        .onChange(of: viewModel.selectedTimeRange) { _, _ in
            Task { await viewModel.loadTrendData() }
        }
    }

    // MARK: - 3. Distribution

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribution")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            let d = viewModel.distribution
            DistributionBar(
                relaxedPercent: d.relaxed,
                mixedPercent: d.mixed,
                highPercent: d.high
            )
        }
    }

    // MARK: - 4. Monthly Calendar Heatmap

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This month")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            MonthlyCalendarHeatmap(dailyLevels: viewModel.monthlyCalendar)
        }
    }

    // MARK: - 5. HRV Trend

    private var hrvCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HRVTrendChart(dataPoints: viewModel.hrvData, referenceValue: viewModel.hrvAvg)
        }
    }

    // MARK: - 6. Editorial Insight

    private var editorialInsight: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                Text("Insight")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
            }
            Text(viewModel.weeklyInsight ?? "Keep measuring daily. Patterns surface after seven days of data.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.16), lineWidth: 1)
        )
    }
}

#Preview("Trends") {
    TrendsView()
}
