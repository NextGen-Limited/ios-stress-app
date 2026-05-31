import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StressMeasurement.timestamp, order: .reverse) private var measurements: [StressMeasurement]
    @State private var appeared = false

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
            // Trigger refresh action
            HapticManager.shared.success()
        }
    }

    private var listContent: some View {
        List {
            ForEach(measurements) { measurement in
                HistoryRow(measurement: measurement)
                    .accessibilityElement(children: .combine)
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityLabel("Stress measurements list")
        .accessibilityHint("\(measurements.count) measurements available")
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

                    Text("\(Int(measurement.stressLevel))")
                        .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                        .foregroundColor(Color.stressColor(for: measurement.category))
                }

                Text("\(Int(measurement.hrv)) ms")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(.secondary)
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
}
