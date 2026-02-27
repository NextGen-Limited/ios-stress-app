import SwiftUI

/// Three-column metric row displaying RHR, HRV, and RR
struct TripleMetricRow: View {
    let rhrValue: String
    let hrvValue: String
    let rrValue: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MetricColumn(
                title: "RHR",
                value: rhrValue,
                unit: "bpm"
            )

            MetricColumn(
                title: "HRV",
                value: hrvValue,
                unit: "ms"
            )

            MetricColumn(
                title: "RR",
                value: rrValue,
                unit: "br/min"
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resting heart rate: \(rhrValue) bpm, Heart rate variability: \(hrvValue) ms, Respiratory rate: \(rrValue) breaths per minute")
    }
}

// MARK: - Metric Column

private struct MetricColumn: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.Wellness.adaptiveSecondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.Wellness.adaptivePrimaryText)

                Text(unit)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("TripleMetricRow") {
    VStack {
        TripleMetricRow(
            rhrValue: "62",
            hrvValue: "45",
            rrValue: "14"
        )
        Spacer()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
