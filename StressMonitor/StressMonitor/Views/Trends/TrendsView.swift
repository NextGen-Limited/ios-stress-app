import SwiftUI
import SwiftData

// MARK: - TrendsView (Light Theme Redesign)
//
// Six sections matching `06-trends.html`:
//   1. Editorial summary — computed from this week's daily stress
//   2. Daily stress bars (7d) — StressBarChartView
//   3. Distribution stacked bar — DistributionBar (4-tier day counts)
//   4. Calendar heatmap — MonthlyCalendarHeatmap (current month, today outlined)
//   5. HRV trend line — HRVTrendChart (52 ms reference)
//   6. Editorial insight — pattern detected card

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TrendsViewModel

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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Chip row — Week / Month / 3 Months / Year
                chipRow
                editorialSummary
                dailyBars
                distributionCard
                calendarCard
                hrvCard
                editorialInsight
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel = TrendsViewModel(modelContext: modelContext)
            await viewModel.loadTrendData()
        }
    }

    // MARK: - Chip Row

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TrendsChip.allCases, id: \.self) { chip in
                    chipView(chip)
                }
            }
            .padding(.bottom, 2)
        }
    }

    private func chipView(_ chip: TrendsChip) -> some View {
        let isActive = chip.toTrendsTimeRange == viewModel.selectedTimeRange
        return Button {
            viewModel.selectedTimeRange = chip.toTrendsTimeRange
            Task { await viewModel.loadTrendData() }
        } label: {
            Text(chip.title)
                .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                .foregroundStyle(
                    isActive
                        ? Color.white
                        : Color.Wellness.adaptiveSecondaryText
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isActive
                        ? AnyShapeStyle(Color(hex: "#0288D1"))
                        : AnyShapeStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.08))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1. Editorial Summary

    private var editorialSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vs last week")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))

            if let delta = viewModel.editorialDelta {
                // Build: "You're [18% calmer]. Hardest day..."
                let summary = viewModel.editorialSummary
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("You're ")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text(delta)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#34C759"))
                    Text(".")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                }
                // Remaining text after the period
                if let remainder = summary.components(separatedBy: ". ").dropFirst().joined(separator: ". ") as String?, !remainder.isEmpty {
                    Text(remainder + ".")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        .lineSpacing(4)
                }
            } else {
                Text(viewModel.editorialSummary)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - 2. Daily Stress Bars (7d)

    private var dailyBars: some View {
        StressBarChartView(
            dailyStress: viewModel.dailyStressData,
            averageValue: viewModel.dailyStressAverage
        )
    }

    // MARK: - 3. Distribution

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Time spent by tier")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Spacer()
                Text("7 days")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
            }
            let d = viewModel.distributionDays
            DistributionBar(
                relaxedDays: d.relaxed,
                mildDays: d.mild,
                moderateDays: d.moderate,
                highDays: d.high,
                comment: viewModel.distributionComment
            )
        }
    }

    // MARK: - 4. Monthly Calendar Heatmap

    private var calendarCard: some View {
        MonthlyCalendarHeatmap(dailyLevels: viewModel.monthlyCalendar)
    }

    // MARK: - 5. HRV Trend

    private var hrvCard: some View {
        HRVTrendChart(
            dataPoints: viewModel.hrvData,
            referenceValue: viewModel.hrvAvg,
            deltaText: viewModel.hrvDeltaText
        )
    }

    // MARK: - 6. Editorial Insight

    private var editorialInsight: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pattern detected")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))

            Text("Tuesday stand-ups run hot")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .padding(.bottom, 2)

            Text(viewModel.weeklyInsight ?? "Stress peaks mid-week — walking meetings could help balance your recovery.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Chip Enum

enum TrendsChip: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var title: String { rawValue }

    var toTrendsTimeRange: TrendsTimeRange {
        switch self {
        case .week:         return .week
        case .month:        return .month
        case .threeMonths:  return .threeMonths
        case .year:         return .threeMonths // closest available
        }
    }
}

#Preview("Trends") {
    NavigationStack {
        TrendsView()
            .stressNavigationDestinations()
    }
    .environment(AppRouter())
    .modelContainer(for: [StressMeasurement.self], inMemory: true)
}
