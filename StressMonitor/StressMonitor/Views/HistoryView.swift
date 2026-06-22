import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StressMeasurement.timestamp, order: .reverse) private var measurements: [StressMeasurement]
    @State private var appeared = false
    @State private var dateRange: DateRangeFilter = .thirtyDays
    @State private var selectedCategories: Set<StressCategory> = []

    private var filteredMeasurements: [StressMeasurement] {
        let cutoff = dateRange.cutoff()
        return measurements.filter { measurement in
            if let cutoff, measurement.timestamp < cutoff { return false }
            if selectedCategories.isEmpty { return true }
            return selectedCategories.contains(measurement.category)
        }
    }

    var body: some View {
        Group {
            if measurements.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("History")
        .accessibilityLabel("Stress measurement history")
        .refreshable {
            HapticManager.shared.success()
        }
        .accessibilityAction(named: "Refresh") {
            HapticManager.shared.success()
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            filterBar
            List {
                if filteredMeasurements.isEmpty {
                    Section {
                        Text("No measurements match these filters.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                } else {
                    ForEach(filteredMeasurements) { measurement in
                        NavigationLink {
                            MeasurementDetailView(measurement: measurement)
                        } label: {
                            HistoryRow(measurement: measurement)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .accessibilityLabel("Stress measurements list")
            .accessibilityHint("\(filteredMeasurements.count) measurements available")
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRangeFilter.allCases) { range in
                        DateFilterChip(range: range, selected: $dateRange)
                    }
                }
                .padding(.horizontal, 16)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StressCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(category: category, selected: $selectedCategories)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.6))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No history available", systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Stress measurements will appear here once you start tracking.")
        }
    }
}

struct HistoryRow: View {
    let measurement: StressMeasurement

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            StressGaugeMini(level: measurement.stressLevel, category: measurement.category)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(formattedTime)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(.primary)

                Text(measurement.category.rawValue.capitalized)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: measurement.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.stressColor(for: measurement.category))
                        .accessibilityHidden(true)

                    Text("\(Int(measurement.hrv)) ms")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stress measurement from \(formattedTime)")
        .accessibilityValue("\(measurement.category.rawValue.capitalized) stress, level \(Int(measurement.stressLevel)) out of 100, with \(Int(measurement.hrv)) milliseconds heart rate variability")
        .accessibilityHint("Tap for detailed information about this measurement")
    }

    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: measurement.timestamp, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: StressMeasurement.self, inMemory: true)
}
