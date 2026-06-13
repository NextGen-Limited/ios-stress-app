import Charts
import SwiftUI

/// Character-Reactive Bar Chart.
///
/// Each bar gets a Ripple mood face on top based on that day's stress tier.
/// Today's bar glows with an accent ring. **No numeric stress scores** —
/// faces are the only indicator.
struct StressBarChartView: View {
    let dailyStress: [DailyStressData]
    let distribution: StressDistribution
    @Binding var selectedTimeRange: TrendsTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with time range picker
            HStack {
                Text("Stress over time")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Menu {
                    ForEach(TrendsTimeRange.allCases, id: \.self) { range in
                        Button {
                            selectedTimeRange = range
                        } label: {
                            HStack {
                                Text(range.displayName)
                                if range == selectedTimeRange {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimeRange.displayName)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }

            // Bar chart with mood faces
            if dailyStress.isEmpty {
                emptyChartPlaceholder
            } else {
                chartContent
            }

            // 5-tier legend strip (no numbers)
            tierLegend
        }
        .trendsGlassCard()
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartContent: some View {
        Chart(dailyStress) { item in
            let hasData = item.averageStress > 0
            let tier = StressTier.from(level: item.averageStress)
            let isToday = item.id == dailyStress.last?.id

            BarMark(
                x: .value("Day", item.dayLabel),
                y: .value("Stress", hasData ? item.averageStress : 4)
            )
            .foregroundStyle(hasData ? tier.color : Color.white.opacity(0.1))
            .cornerRadius(6)
            .annotation(position: .top) {
                if hasData {
                    RippleMoodFace(
                        tier: tier,
                        size: isToday ? 34 : 26,
                        showsRing: isToday,
                        glow: isToday
                    )
                } else {
                    Text("·")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
        }
        .chartYScale(domain: 0...115) // headroom for face annotations
        .chartYAxis(.hidden) // no numeric stress scores
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.45))
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .frame(height: 200)
    }

    // MARK: - Legend

    private var tierLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                ForEach(StressTier.allCases, id: \.self) { tier in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(tier.color)
                        .frame(height: 8)
                }
            }

            HStack {
                Text("Calm")
                Spacer()
                Text("Overwhelmed")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Empty State

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.25))

            Text("No data yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct StressBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        StressBarChartView(
            dailyStress: [
                DailyStressData(dayLabel: "Mon", averageStress: 30),
                DailyStressData(dayLabel: "Tue", averageStress: 55),
                DailyStressData(dayLabel: "Wed", averageStress: 70),
                DailyStressData(dayLabel: "Thu", averageStress: 15),
                DailyStressData(dayLabel: "Fri", averageStress: 85),
                DailyStressData(dayLabel: "Sat", averageStress: 20),
                DailyStressData(dayLabel: "Sun", averageStress: 45)
            ],
            distribution: StressDistribution(),
            selectedTimeRange: .constant(.week)
        )
        .padding()
        .background(TrendsPalette.darkCanvas)
    }
}
