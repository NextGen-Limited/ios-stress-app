# History & Trends

> **Created by:** Phuong Doan
> **Feature:** Historical data visualization and patterns
> **Designs Referenced:** 5 screens
> - `history_and_patterns_1`, `history_and_patterns_2`
> - `trends_view_dark_mode`
> - `long-term_stress_trends`
> - `measurement_history_list`

---

## Overview

The History & Trends section allows users to:
- View historical HRV data with interactive charts
- See stress level distribution breakdown
- Access weekly insights
- Browse individual measurement history

---

## 1. History View

**Design:** `history_and_patterns_1`, `trends_view_dark_mode`

```swift
// StressMonitor/Views/HistoryView.swift

import SwiftUI
import Observation

@Observable
class HistoryViewModel {
    var selectedTimeRange: TimeRange = .week
    var hrvData: [HRVDataPoint] = []
    var hrvAverage: Double = 62
    var hrvMin: Double = 45
    var hrvMax: Double = 82
    var stressDistribution: [StressCategory: Double] = [:]
    var weeklyInsight: WeeklyInsight?
    var dateRangeText: String = "Oct 24 - Oct 30"

    private let repository: StressRepositoryProtocol

    init(repository: StressRepositoryProtocol = StressRepository()) {
        self.repository = repository
    }

    func loadData(timeRange: TimeRange) async {
        selectedTimeRange = timeRange

        // Fetch measurements for time range
        let measurements = try? await repository.fetchInTimeRange(timeRange.dateRange)

        // Calculate HRV data points
        hrvData = measurements?.map { measurement in
            HRVDataPoint(
                date: measurement.timestamp,
                value: measurement.hrv
            )
        } ?? []

        // Calculate stats
        calculateStats(from: measurements ?? [])

        // Calculate distribution
        calculateDistribution(from: measurements ?? [])

        // Generate insight
        weeklyInsight = generateInsight(from: measurements ?? [])
    }

    private func calculateStats(from measurements: [StressMeasurement]) {
        guard !measurements.isEmpty else { return }

        let hrvValues = measurements.map(\.hrv)
        hrvAverage = hrvValues.reduce(0, +) / Double(hrvValues.count)
        hrvMin = hrvValues.min() ?? 0
        hrvMax = hrvValues.max() ?? 100
    }

    private func calculateDistribution(from measurements: [StressMeasurement]) {
        let total = Double(measurements.count)

        for category in StressCategory.allCases {
            let count = Double(measurements.filter { $0.category == category }.count)
            stressDistribution[category] = (count / total) * 100
        }
    }

    private func generateInsight(from measurements: [StressMeasurement]) -> WeeklyInsight? {
        guard measurements.count >= 2 else { return nil }

        let recentAvg = measurements.suffix(7).map(\.stressLevel).reduce(0, +) / 7
        let previousAvg = measurements.dropLast(7).suffix(7).map(\.stressLevel).reduce(0, +) / 7

        let change = ((previousAvg - recentAvg) / previousAvg) * 100

        return WeeklyInsight(
            text: "Your stress levels are \(Int(change))% \(change > 0 ? "lower" : "higher") than last week. \(change > 0 ? "Great job" : "Keep tracking") maintaining your balance!"
        )
    }

    func xAxisLabels(for timeRange: TimeRange) -> [String] {
        switch timeRange {
        case .day:
            return Array(0..<24).map { "\($0):00" }
        case .week:
            return ["M", "T", "W", "T", "F", "S", "S"]
        case .month:
            return ["W1", "W2", "W3", "W4"]
        case .quarter:
            return ["Jan", "Feb", "Mar"]
        }
    }
}

enum TimeRange: String, CaseIterable {
    case day = "24H"
    case week = "7D"
    case month = "4W"
    case quarter = "3M"

    var dateRange: Range<Date> {
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now)!..<now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)!..<now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now)!..<now
        case .quarter:
            return calendar.date(byAdding: .day, value: -90, to: now)!..<now
        }
    }
}

struct HRVDataPoint {
    let date: Date
    let value: Double
}

struct WeeklyInsight {
    let text: String
}

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @State private var selectedMeasurement: StressMeasurement?

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    header

                    // Time range selector
                    timeRangeSelector

                    // HRV trends chart
                    hrvTrendsCard

                    // Stats
                    statsRow

                    // Stress distribution
                    stressDistributionCard

                    // Weekly insight
                    if let insight = viewModel.weeklyInsight {
                        InsightCard(insight: insight)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .task {
            await viewModel.loadData(timeRange: viewModel.selectedTimeRange)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(measurement: measurement)
        }
    }

    private var header: some View {
        HStack {
            Text("History")
                .font(.system(size: 28, weight: .bold))

            Spacer()

            Button(action: { /* Calendar */ }) {
                Image(systemName: "calendar")
                    .foregroundColor(.primary)
            }
        }
    }

    private var timeRangeSelector: some View {
        SegmentedControl(
            selection: Binding(
                get: { TimeRange.allCases.firstIndex(of: viewModel.selectedTimeRange) ?? 1 },
                set: { newSelection in
                    Task { await viewModel.loadData(timeRange: TimeRange.allCases[newSelection]) }
                }
            ),
            options: TimeRange.allCases.map(\.rawValue)
        )
    }

    private var hrvTrendsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRV Trends")
                        .font(.system(size: 12, weight: .semibold))
                        .uppercaseSmallCaps()
                        .foregroundColor(.textSecondary)

                    Text("\(Int(viewModel.hrvAverage)) ms avg")
                        .font(.system(size: 28, weight: .bold))
                }

                Spacer()

                Button(action: { /* Info */ }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.textSecondary)
                }
            }

            Text(viewModel.dateRangeText)
                .font(.caption)
                .foregroundColor(.textSecondary)

            // Chart
            HRVLineChart(data: viewModel.hrvData)
                .frame(height: 192)

            // X-axis labels
            HStack {
                ForEach(viewModel.xAxisLabels(for: viewModel.selectedTimeRange), id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    if label != viewModel.xAxisLabels(for: viewModel.selectedTimeRange).last {
                        Spacer()
                    }
                }
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Average",
                value: "\(Int(viewModel.hrvAverage)) ms",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .primary
            )

            StatCard(
                title: "Range",
                value: "\(Int(viewModel.hrvMin))-\(Int(viewModel.hrvMax)) ms",
                icon: "arrow.up.arrow.down",
                iconColor: .primary
            )
        }
    }

    private var stressDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Level Distribution")
                .font(.system(size: 17, weight: .bold))

            VStack(spacing: 12) {
                ForEach([StressCategory.relaxed, .mild, .moderate, .high], id: \.self) { category in
                    DistributionRow(
                        category: category,
                        percentage: viewModel.stressDistribution[category] ?? 0
                    )
                }
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
        }
        .cardPadding(.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

struct DistributionRow: View {
    let category: StressCategory
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.stressColor(for: category).opacity(0.15))
                        Image(systemName: category.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(Color.stressColor(for: category))
                    }
                    .frame(width: 32, height: 32)

                    Text(category.displayName)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 14, weight: .bold))
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                Rectangle()
                    .fill(Color.stressColor(for: category))
                    .frame(width: max(0, (percentage / 100) * (UIScreen.main.bounds.width - 96)), height: 8)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - HRV Line Chart
struct HRVLineChart: View {
    let data: [HRVDataPoint]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                ForEach(0..<5) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }

                if !data.isEmpty {
                    // Area fill
                    areaFill(for: geometry)

                    // Line stroke
                    lineStroke(for: geometry)

                    // Interactive point
                    if let lastPoint = data.last {
                        interactionPoint(for: lastPoint, in: geometry)
                    }
                }
            }
        }
    }

    private func areaFill(for geometry: GeometryProxy) -> some View {
        Path { path in
            guard !data.isEmpty else { return }

            let width = geometry.size.width
            let height = geometry.size.height
            let step = width / CGFloat(max(data.count - 1, 1))

            let min = data.map(\.value).min() ?? 0
            let max = data.map(\.value).max() ?? 100
            let range = max - min

            func y(for value: Double) -> CGFloat {
                if range == 0 { return height / 2 }
                return height - CGFloat((value - min) / range) * height * 0.7 - height * 0.15
            }

            path.move(to: CGPoint(x: 0, y: height))

            for (index, point) in data.enumerated() {
                path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: point.value)))
            }

            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color.primary.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func lineStroke(for geometry: GeometryProxy) -> some View {
        Path { path in
            guard !data.isEmpty else { return }

            let width = geometry.size.width
            let height = geometry.size.height
            let step = width / CGFloat(max(data.count - 1, 1))

            let min = data.map(\.value).min() ?? 0
            let max = data.map(\.value).max() ?? 100
            let range = max - min

            func y(for value: Double) -> CGFloat {
                if range == 0 { return height / 2 }
                return height - CGFloat((value - min) / range) * height * 0.7 - height * 0.15
            }

            path.move(to: CGPoint(x: 0, y: y(for: data[0].value)))

            for (index, point) in data.enumerated() {
                path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: point.value)))
            }
        }
        .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        .shadow(color: Color.primary.opacity(0.3), radius: 8)
    }

    private func interactionPoint(for dataPoint: HRVDataPoint, in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let step = width / CGFloat(max(data.count - 1, 1))

        let min = data.map(\.value).min() ?? 0
        let max = data.map(\.value).max() ?? 100
        let range = max - min

        func y(for value: Double) -> CGFloat {
            if range == 0 { return height / 2 }
            return height - CGFloat((value - min) / range) * height * 0.7 - height * 0.15
        }

        let index = data.firstIndex(where: { $0.date == dataPoint.date }) ?? 0
        let x = CGFloat(index) * step
        let yPos = y(for: dataPoint.value)

        return Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(Color.primary, lineWidth: 3)
            )
            .position(x: x, y: yPos)
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
```

---

## 2. Measurement History List

**Design:** `measurement_history_list`

```swift
// StressMonitor/Views/MeasurementHistoryListView.swift

import SwiftUI

struct MeasurementHistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MeasurementHistoryListViewModel
    @State private var selectedMeasurement: StressMeasurement?
    @State private var showFilter = false

    init(measurements: [StressMeasurement]) {
        _viewModel = State(initialValue: MeasurementHistoryListViewModel(measurements: measurements))
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Title
                Text("History")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Content
                if viewModel.groupedMeasurements.isEmpty {
                    emptyState
                } else {
                    measurementsList
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            FilterOptionsSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(measurement: measurement)
        }
    }

    private var header: some View {
        HStack {
            Button(action: { /* Back */ }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.primary)
            }

            Spacer()

            Button(action: { showFilter = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.primary)
            }

            Button(action: { /* Delete */ }) {
                Image(systemName: "trash")
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var measurementsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    Section {
                        ForEach(viewModel.groupedMeasurements[date] ?? []) { measurement in
                            MeasurementListItem(measurement: measurement) {
                                selectedMeasurement = measurement
                            }
                        }
                    } header: {
                        Text(date.formatted(date: .long))
                            .font(.system(size: 11, weight: .semibold))
                            .uppercaseSmallCaps()
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.backgroundDark)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                Image(systemName: "chart.bar")
                    .font(.system(size: 36))
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 80)

            Text("No Measurements")
                .font(.system(size: 20, weight: .bold))

            Text("Take your first measurement to start tracking your stress levels history.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: { /* Measure */ }) {
                Text("Measure Now")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 60)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - ViewModel
@Observable
class MeasurementHistoryListViewModel {
    var groupedMeasurements: [Date: [StressMeasurement]] = [:]
    var sortedDates: [Date] = []

    init(measurements: [StressMeasurement]) {
        groupMeasurements(measurements)
    }

    private func groupMeasurements(_ measurements: [StressMeasurement]) {
        let calendar = Calendar.current

        groupedMeasurements = Dictionary(grouping: measurements) { measurement in
            calendar.startOfDay(for: measurement.timestamp)
        }

        sortedDates = groupedMeasurements.keys.sorted(by: >)
    }
}

// MARK: - Measurement List Item
struct MeasurementListItem: View {
    let measurement: StressMeasurement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement.timestamp, style: .time)
                        .font(.system(size: 18, weight: .semibold))
                    Text(measurement.timestamp, format: .dateTime.month().day())
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.stressColor(for: measurement.category))
                            .frame(width: 8, height: 8)
                        Text("\(Int(measurement.stressLevel))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("HRV: \(Int(measurement.hrv))ms")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .cardPadding(.regular)
        }
        .buttonStyle(.scaleEffect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Measurement at \(measurement.timestamp.formatted(date: .omitted, time: .standard)), stress level \(Int(measurement.stressLevel))")
    }
}

struct ScaleEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.cardDark)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleEffectButtonStyle {
    static var scaleEffect: ScaleEffectButtonStyle { .init() }
}

// MARK: - Filter Sheet
struct FilterOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MeasurementHistoryListViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Filter options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time Range")
                        .font(.headline)

                    Picker("Time Range", selection: .constant(1)) {
                        Text("All Time").tag(0)
                        Text("Today").tag(1)
                        Text("This Week").tag(2)
                        Text("This Month").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MeasurementHistoryListView(measurements: [])
}
```

---

## 3. Long-Term Trends View

**Design:** `long-term_stress_trends`

```swift
// StressMonitor/Views/LongTermTrendsView.swift

import SwiftUI

struct LongTermTrendsView: View {
    @State private var selectedPeriod: TrendPeriod = .threeMonths
    @State private var selectedMetric: TrendMetric = .stressLevel

    enum TrendPeriod {
        case week, month, threeMonths, sixMonths, year
    }

    enum TrendMetric {
        case stressLevel, hrv, heartRate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period selector
                periodSelector

                // Metric tabs
                metricTabs

                // Main chart
                mainTrendChart

                // Stats summary
                statsSummary

                // Key insights
                keyInsights
            }
            .padding()
        }
        .background(Color.backgroundDark)
        .navigationTitle("Long-Term Trends")
        .navigationBarTitleDisplayMode(.large)
    }

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([
                    TrendPeriod.week, .month, .threeMonths,
                    .sixMonths, .year
                ], id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        Text(period.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedPeriod == period ? .white : .textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period ? Color.primary : Color.cardDark,
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var metricTabs: some View {
        HStack(spacing: 0) {
            ForEach([
                TrendMetric.stressLevel, .hrv, .heartRate
            ], id: \.self) { metric in
                Button(action: { selectedMetric = metric }) {
                    Text(metric.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedMetric == metric ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedMetric == metric ? Color.primary.opacity(0.2) : Color.clear
                        )
                }
            }
        }
        .background(Color.cardDark)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var mainTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedMetric.displayName + " Over Time")
                .font(.headline)

            // Multi-line chart with average line
            MultiLineTrendChart(
                data: generateChartData(),
                showAverage: true
            )
            .frame(height: 200)
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var statsSummary: some View {
        HStack(spacing: 12) {
            TrendStatCard(
                title: "Average",
                value: averageValue,
                change: percentageChange
            )

            TrendStatCard(
                title: "Best",
                value: bestValue
            )

            TrendStatCard(
                title: "Worst",
                value: worstValue
            )
        }
        .padding(.horizontal)
    }

    private var keyInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                InsightItem(
                    icon: "calendar.badge.checkmark",
                    title: "Best Day",
                    description: "Your stress is typically lowest on Sundays"
                )

                InsightItem(
                    icon: "clock.badge.exclamationmark",
                    title: "Peak Stress",
                    description: "Highest stress levels occur between 2-4 PM"
                )

                InsightItem(
                    icon: "chart.line.flattrend.xyaxis",
                    title: "Improvement",
                    description: "Overall trend: 12% improvement over this period"
                )
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Helper computed properties
    private var averageValue: String {
        "52"
    }

    private var percentageChange: String {
        "-12%"
    }

    private var bestValue: String {
        "38"
    }

    private var worstValue: String {
        "78"
    }

    private func generateChartData() -> [TrendDataPoint] {
        // Generate sample data
        return []
    }
}

struct TrendDataPoint {
    let date: Date
    let value: Double
    let average: Double
}

struct TrendStatCard: View {
    let title: String
    let value: String
    var change: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .uppercaseSmallCaps()
                .foregroundColor(.textSecondary)

            Text(value)
                .font(.system(size: 24, weight: .bold))

            if let change = change {
                Text(change)
                    .font(.caption)
                    .foregroundColor(.successGreen)
            }
        }
        .cardPadding(.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardDark)
        .cornerRadius(12)
    }
}

struct InsightItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Extensions
extension TrendPeriod {
    var displayName: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        }
    }
}

extension TrendMetric {
    var displayName: String {
        switch self {
        case .stressLevel: return "Stress Level"
        case .hrv: return "HRV"
        case .heartRate: return "Heart Rate"
        }
    }
}

// MARK: - Multi-line Chart
struct MultiLineTrendChart: View {
    let data: [TrendDataPoint]
    let showAverage: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !data.isEmpty {
                    // Daily data line
                    Path { path in
                        // Draw daily values
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2))

                    if showAverage {
                        // Average line
                        Path { path in
                            // Draw average line
                        }
                        .stroke(Color.successGreen, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LongTermTrendsView()
    }
    .preferredColorScheme(.dark)
}
```

---

## File Structure

```
StressMonitor/Views/History/
├── HistoryView.swift
├── MeasurementHistoryListView.swift
├── LongTermTrendsView.swift
├── Components/
│   ├── StatCard.swift
│   ├── DistributionRow.swift
│   ├── HRVLineChart.swift
│   ├── MeasurementListItem.swift
│   ├── TrendStatCard.swift
│   └── InsightItem.swift
└── ViewModels/
    └── HistoryViewModel.swift
```

---

## Dependencies

- **Design System:** Colors, charts, components from `00-design-system-components.md`
- **Data Models:** `StressMeasurement`, `StressCategory`
- **Navigation:** For drill-down to measurement details
