import SwiftUI

// MARK: - Chart Time Range Selector

/// Time range options for the stress chart
/// Note: Separate from TimeRange in HistoryViewModel to avoid conflicts
enum ChartTimeRange: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
}

// MARK: - Stress Over Time Chart

/// Bar chart visualization for stress data over time
/// Shows daily stress levels with category-based coloring
struct StressOverTimeChart: View {
    @State private var selectedRange: ChartTimeRange = .sevenDays
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
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
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
            // Y-axis labels and chart area
            HStack(alignment: .top, spacing: 8) {
                // Y-axis labels
                yAxisLabels

                // Bar chart
                barChart
            }

            Spacer()

            // Legend
            legendView
                .padding(.top, 16)
        }
    }

    // MARK: - Y-Axis Labels

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach([100, 66, 33, 0], id: \.self) { value in
                Text("\(value)")
                    .font(Typography.caption1)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .frame(height: 60, alignment: .top)
            }
        }
        .frame(width: 24)
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(chartData) { dataPoint in
                VStack(spacing: 4) {
                    // Bar
                    Rectangle()
                        .fill(barColor(for: dataPoint.category))
                        .frame(width: 28, height: barHeight(for: dataPoint.value))
                        .cornerRadius(6)

                    // X-axis label
                    Text(dataPoint.day)
                        .font(Typography.caption2)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
                .frame(maxHeight: 240, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity)
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

    private func barHeight(for value: Int) -> CGFloat {
        // Max height is 240, scale proportionally
        return CGFloat(value) / 100.0 * 240.0
    }

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
