import Charts
import SwiftUI

// MARK: - Chart Time Range Selector

/// Time range options for the stress chart - local to StressOverTimeChart
private enum LocalChartTimeRange: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
}

// MARK: - Stress Over Time Chart

/// Bar chart visualization for stress data over time using SwiftUI Charts
/// Shows daily stress levels with category-based coloring
struct StressOverTimeChart: View {
    @State private var selectedRange: LocalChartTimeRange = .sevenDays
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    // Mock data for chart visualization
    private let chartData: [StressDataPoint] = [
        StressDataPoint(day: "D1", value: 35, category: .mild),
        StressDataPoint(day: "D2", value: 20, category: .relaxed),
        StressDataPoint(day: "D3", value: 55, category: .moderate),
        StressDataPoint(day: "D4", value: 30, category: .mild),
        StressDataPoint(day: "D5", value: 15, category: .relaxed),
        StressDataPoint(day: "D6", value: 45, category: .mild),
        StressDataPoint(day: "D7", value: 25, category: .relaxed),
    ]

    // Legend percentages (mock data)
    private let excellentPercent = 29
    private let normalPercent = 29
    private let stressedPercent = 29

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and dropdown
            headerView

            if isPremiumUser {
                chartContent
            } else {
                chartContent
                    .overlay(PremiumLockOverlay())
            }
        }
        .padding(16)
        .frame(width: 358, height: 376)
        .background(Color.Wellness.adaptiveCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Stress over time chart")
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Text("Stress over time")
                .font(Typography.headline)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Spacer()

            Menu {
                ForEach(LocalChartTimeRange.allCases, id: \.self) { range in
                    Button {
                        selectedRange = range
                    } label: {
                        HStack {
                            Text(range.rawValue)
                            if selectedRange == range {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedRange.rawValue)
                        .font(Typography.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chart with SwiftUI Charts
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.day),
                    y: .value("Stress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint.category))
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 33, 66, 100]) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(Typography.caption1)
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .font(Typography.caption2)
                }
            }
            .frame(height: 240)

            Spacer()

            // Legend
            legendView
                .padding(.top, 16)
        }
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: Color(hex: "#00C45A"), label: "Excellent", percent: excellentPercent)
            legendItem(color: Color(hex: "#F1AE00"), label: "Normal", percent: normalPercent)
            legendItem(color: Color(hex: "#FA363D"), label: "Stressed", percent: stressedPercent)
        }
    }

    private func legendItem(color: Color, label: String, percent: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(percent)% \(label)")
                .font(Typography.caption2)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
    }

    // MARK: - Helper Methods

    private func barColor(for category: StressCategory) -> Color {
        switch category {
        case .relaxed:
            return Color(hex: "#00C45A")
        case .mild:
            return Color(hex: "#F1AE00")
        case .moderate, .high:
            return Color(hex: "#FA363D")
        }
    }
}

// MARK: - Stress Data Point Model

struct StressDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
    let category: StressCategory
}

// MARK: - Preview

#Preview("Stress Over Time Chart") {
    VStack {
        StressOverTimeChart()
            .padding()

        Spacer()
    }
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark Mode") {
    VStack {
        StressOverTimeChart()
            .padding()

        Spacer()
    }
    .background(Color.Wellness.adaptiveBackground)
    .preferredColorScheme(.dark)
}

#Preview("Non-Premium User") {
    VStack {
        StressOverTimeChart()
            .padding()

        Spacer()
    }
    .background(Color.Wellness.adaptiveBackground)
}
