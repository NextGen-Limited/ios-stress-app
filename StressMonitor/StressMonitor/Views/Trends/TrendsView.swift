import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TrendsViewModel

    init() {
        _viewModel = State(initialValue: TrendsViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                    .padding(.horizontal)

                hrvTrendCard
                    .padding(.horizontal)

                summaryStatsRow
                    .padding(.horizontal)

                distributionCard
                    .padding(.horizontal)

                if let insight = viewModel.weeklyInsight {
                    InsightCard(insight: PatternInsight(icon: "💡", title: "Weekly Insight", description: insight))
                        .padding(.horizontal)
                }

                ForEach(viewModel.patternInsights, id: \.title) { pattern in
                    InsightCard(insight: pattern)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 100)
            }
            .padding(.top, 16)
        }
        .background(Color.backgroundLight)
        .task {
            await viewModel.loadTrendData()
        }
        .onAppear {
            viewModel = TrendsViewModel(modelContext: modelContext)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Trends")
                .font(Typography.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            TimeRangePicker(
                selectedRange: $viewModel.selectedTimeRange,
                options: [.day, .week, .month, .threeMonths]
            )
            .onChange(of: viewModel.selectedTimeRange) { _, _ in
                Task { await viewModel.loadTrendData() }
            }
        }
    }

    private var hrvTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HRV Trend")
                .font(Typography.title2)
                .fontWeight(.bold)

            if viewModel.isLoading {
                loadingPlaceholder
            } else if viewModel.hrvData.isEmpty {
                emptyStatePlaceholder
            } else {
                LineChartView(
                    dataPoints: viewModel.hrvData,
                    accentColor: .primaryBlue,
                    showGrid: true
                )
                .frame(height: 200)
            }

            if let selectedPoint = viewModel.selectedDataPoint {
                HStack {
                    Text("\(Int(selectedPoint.value)) ms")
                        .font(.system(size: 17, weight: .semibold))

                    Text(selectedPoint.date, style: .time)
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var summaryStatsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "chart.bar.fill",
                value: "\(Int(viewModel.averageHRV))",
                unit: "ms",
                label: "Average"
            )

            StatCard(
                icon: "arrow.up.arrow.down",
                value: "\(Int(viewModel.hrvRange.lowerBound))-\(Int(viewModel.hrvRange.upperBound))",
                unit: "ms",
                label: "Range"
            )

            StatCard(
                icon: trendIcon,
                value: trendIcon,
                label: "Trend"
            )
            .foregroundColor(trendColor)
        }
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Level Distribution")
                .font(Typography.title2)
                .fontWeight(.bold)

            let distribution = viewModel.stressDistribution

            VStack(spacing: 12) {
                DistributionBarView(
                    icon: "leaf.fill",
                    label: "Relaxed",
                    percentage: distribution.relaxed,
                    color: .stressRelaxed
                )

                DistributionBarView(
                    icon: "circle.fill",
                    label: "Normal",
                    percentage: distribution.normal,
                    color: .stressMild
                )

                DistributionBarView(
                    icon: "triangle.fill",
                    label: "Elevated",
                    percentage: distribution.elevated,
                    color: .stressModerate
                )

                DistributionBarView(
                    icon: "square.fill",
                    label: "High",
                    percentage: distribution.high,
                    color: .stressHigh
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Loading trend data...")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var emptyStatePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Need More Data")
                .font(Typography.headline)

            Text("Continue measuring for 7 days to see trends")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var trendIcon: String {
        switch viewModel.trendDirection {
        case .up: return "↑"
        case .down: return "↓"
        case .stable: return "→"
        }
    }

    private var trendColor: Color {
        switch viewModel.trendDirection {
        case .up: return .stressRelaxed
        case .down: return .stressHigh
        case .stable: return .secondary
        }
    }
}
