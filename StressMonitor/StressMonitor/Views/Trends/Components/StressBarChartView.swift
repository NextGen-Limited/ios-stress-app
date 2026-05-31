import Charts
import SwiftUI

/// Daily stress bar chart (Mon–Sun) using Swift Charts — replaces circular indicators
struct StressBarChartView: View {
    let dailyStress: [DailyStressData]
    let distribution: StressDistribution
    @Binding var selectedTimeRange: TrendsTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with time range picker
            HStack {
                Text("Stress over time")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                // Interactive time range picker with chevron
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
                            .font(Typography.caption1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // Bar chart
            if dailyStress.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(dailyStress) { item in
                    BarMark(
                        x: .value("Day", item.dayLabel),
                        y: .value("Stress", item.averageStress)
                    )
                    .foregroundStyle(Color.stressColor(for: item.averageStress))
                    .cornerRadius(4)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                            .font(Typography.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                            .font(Typography.caption2)
                    }
                }
                .frame(height: 180)
            }

            // Legend row
            HStack(spacing: 12) {
                legendItem(color: .stressRelaxed, label: "Relaxed", pct: distribution.relaxed)
                legendItem(color: .stressMild, label: "Normal", pct: distribution.normal)
                legendItem(color: .stressModerate, label: "Warning", pct: distribution.elevated)
                legendItem(color: .stressHigh, label: "Stressed", pct: distribution.high)
            }
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No data for this week")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String, pct: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(Typography.caption2)
                .foregroundColor(.secondary)

            Text("\(Int(pct))%")
                .font(Typography.caption2.bold())
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    @Previewable @State var timeRange: TrendsTimeRange = .week
    StressBarChartView(
        dailyStress: [
            DailyStressData(dayLabel: "Mon", averageStress: 30, distribution: StressDistributionPerDay(relaxed: 40, normal: 30, warning: 20, stressed: 10)),
            DailyStressData(dayLabel: "Tue", averageStress: 55, distribution: StressDistributionPerDay(relaxed: 20, normal: 35, warning: 30, stressed: 15)),
            DailyStressData(dayLabel: "Wed", averageStress: 70, distribution: StressDistributionPerDay(relaxed: 10, normal: 25, warning: 40, stressed: 25)),
            DailyStressData(dayLabel: "Thu", averageStress: 45, distribution: StressDistributionPerDay(relaxed: 30, normal: 40, warning: 20, stressed: 10)),
            DailyStressData(dayLabel: "Fri", averageStress: 80, distribution: StressDistributionPerDay(relaxed: 5, normal: 15, warning: 35, stressed: 45)),
            DailyStressData(dayLabel: "Sat", averageStress: 20, distribution: StressDistributionPerDay(relaxed: 60, normal: 25, warning: 10, stressed: 5)),
            DailyStressData(dayLabel: "Sun", averageStress: 25, distribution: StressDistributionPerDay(relaxed: 50, normal: 35, warning: 10, stressed: 5))
        ],
        distribution: StressDistribution(relaxed: 40, normal: 30, elevated: 20, high: 10),
        selectedTimeRange: $timeRange
    )
    .padding()
    .background(Color.backgroundLight)
}
