import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var viewModel: TrendsViewModel
    @State private var navigateToPremium = false

    init() {
        _viewModel = State(initialValue: TrendsViewModel(
            modelContext: ModelContext((try? ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))!)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Premium banner
                PremiumBannerView(action: { navigateToPremium = true })
                    .padding(.horizontal)

                // Horizontal Week Calendar with stress dots
                HorizontalWeekCalendarView(
                    selectedDate: $viewModel.selectedDate,
                    onDateSelected: { date in
                        viewModel.selectDate(date)
                    },
                    dailyTiers: viewModel.dailyStressTiers
                )
                .padding(.horizontal)

                // Ripple speech bubble — dynamic message
                MascotSpeechBubbleView(
                    message: MascotSpeechBubbleView.message(
                        stressTrendingDown: viewModel.stressTrendingDown,
                        hasData: !viewModel.dailyStressData.isEmpty
                    ),
                    tier: speechBubbleTier
                )
                .padding(.horizontal)

                // Character-reactive bar chart
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

                // 5-tier heatmap
                WeeklyHeatmapView(measurements: viewModel.weeklyMeasurements)
                    .padding(.horizontal)

                // Enhanced HRV trend card
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

                // Ripple Insights teaser
                SmartInsightsTeaser()
                    .padding(.horizontal)

                Spacer()
                    .frame(height: tabBarScrollState.tabBarHeight + 16)
            }
            .padding(.top, 16)
        }
        .trackScrollOffsetForTabBar(state: tabBarScrollState)
        .background(TrendsPalette.darkCanvas)
        .task {
            await viewModel.loadTrendData()
        }
        .onAppear {
            viewModel = TrendsViewModel(modelContext: modelContext)
        }
        .navigationDestination(isPresented: $navigateToPremium) {
            IAPPremiumView(storeKit: Self.makeStoreKitService(), premiumState: PremiumState.shared)
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

    // MARK: - Ripple Speech Bubble Tier

    /// Determines the Ripple character's mood for the speech bubble based on today's data.
    private var speechBubbleTier: StressTier {
        guard let todayData = viewModel.dailyStressData.last,
              todayData.averageStress > 0 else {
            return .good
        }
        return StressTier.from(level: todayData.averageStress)
    }

    // MARK: - Enhanced HRV Trend Card

    private var hrvTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with trend badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRV Trend")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Last 30 days")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                // Trend badge
                trendBadge
            }

            // Chart
            if viewModel.isLoading {
                loadingPlaceholder
            } else if viewModel.hrvData.isEmpty {
                emptyStatePlaceholder
            } else {
                LineChartView(
                    dataPoints: viewModel.hrvData,
                    accentColor: TrendsPalette.rippleBlue,
                    showGrid: true,
                    showYAxisLabels: true
                )
                .frame(height: 180)
            }

            // 3 stat tiles
            if !viewModel.hrvData.isEmpty {
                hrvStatTiles
            }
        }
        .trendsGlassCard()
    }

    private var trendBadge: some View {
        let isUp = viewModel.trendDirection == .up
        let isDown = viewModel.trendDirection == .down
        let badgeColor = isUp ? Color(hex: "#4CAF50") : (isDown ? Color(hex: "#FF7043") : TrendsPalette.mutedInk)

        return Text(viewModel.hrvTrendBadge)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.15))
            .overlay(Capsule().stroke(badgeColor.opacity(0.3), lineWidth: 1))
            .clipShape(Capsule())
    }

    private var hrvStatTiles: some View {
        HStack(spacing: 10) {
            statTile(
                title: "Average HRV",
                value: "\(Int(viewModel.averageHRV))",
                unit: "ms"
            )

            statTile(
                title: "vs Last Month",
                value: hrvChangeText,
                unit: nil
            )

            statTile(
                title: "Best Day",
                value: viewModel.bestHRVDayLabel ?? "—",
                unit: nil
            )
        }
    }

    private var hrvChangeText: String {
        guard let pct = viewModel.hrvChangePercent else { return "—" }
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(Int(pct))%"
    }

    private func statTile(title: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let unit {
                    Text(unit)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(TrendsPalette.rippleBlue)

            Text("Loading trend data...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private var emptyStatePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.25))

            Text("Need More Data")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Continue measuring for 7 days to see trends")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
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
