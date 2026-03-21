import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var viewModel: TrendsViewModel

    init() {
        _viewModel = State(initialValue: TrendsViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Premium banner
                PremiumBannerView()
                    .padding(.horizontal)

                // Horizontal Week Calendar
                HorizontalWeekCalendarView(
                    selectedDate: $viewModel.selectedDate,
                    onDateSelected: { date in
                        viewModel.selectDate(date)
                    }
                )
                .padding(.horizontal)

                // Mascot speech bubble
                MascotSpeechBubbleView(
                    message: "I've been keeping an eye on your days! Want to see how stress changed this week?"
                )
                .padding(.horizontal)

                // Stress over time bar chart
                StressBarChartView(
                    dailyStress: viewModel.dailyStressData,
                    distribution: viewModel.stressDistribution,
                    selectedTimeRange: $viewModel.selectedTimeRange
                )
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTimeRange) { _, _ in
                    Task {
                        await viewModel.loadTrendData()
                    }
                }

                // Daily timeline heatmap
                WeeklyHeatmapView(measurements: viewModel.weeklyMeasurements)
                    .padding(.horizontal)

                // HRV Trend chart
                hrvTrendCard
                    .padding(.horizontal)

                // Stress sources card
                StressSourcesCard(
                    sources: viewModel.stressSources.map {
                        StressSourcesCard.StressSourceData(
                            name: $0.name,
                            percentage: $0.percentage / 100.0,
                            color: $0.color,
                            icon: iconForSource($0.name)
                        )
                    },
                    totalDays: 30
                )
                .padding(.horizontal)

                // Smart Insights teaser
                SmartInsightsTeaser()
                    .padding(.horizontal)

                Spacer()
                    .frame(height: tabBarScrollState.tabBarHeight + 16)
            }
            .padding(.top, 16)
        }
        .trackScrollOffsetForTabBar(state: tabBarScrollState)
        .background(Color.backgroundLight)
        .task {
            await viewModel.loadTrendData()
        }
        .onAppear {
            viewModel = TrendsViewModel(modelContext: modelContext)
        }
    }

    private var hrvTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HRV Trend")
                .font(Typography.title2)
                .fontWeight(.bold)

            // Phase 6: subtitle
            Text("Last 30 days")
                .font(Typography.caption1)
                .foregroundColor(.secondary)

            if viewModel.isLoading {
                loadingPlaceholder
            } else if viewModel.hrvData.isEmpty {
                emptyStatePlaceholder
            } else {
                LineChartView(
                    dataPoints: viewModel.hrvData,
                    accentColor: .primaryBlue,
                    showGrid: true,
                    showYAxisLabels: true
                )
                .frame(height: 200)
            }

            // Phase 6: "Today" label
            HStack {
                Spacer()
                Text("Today")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
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
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
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

    // MARK: - Helpers

    private func iconForSource(_ name: String) -> String {
        switch name {
        case "Finance": return "dollarsign.circle.fill"
        case "Relationship": return "heart.fill"
        case "Health": return "cross.case.fill"
        case "Family": return "house.fill"
        case "Work": return "briefcase.fill"
        case "Environment": return "leaf.fill"
        default: return "circle.fill"
        }
    }
}
