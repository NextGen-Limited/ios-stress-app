import SwiftUI

/// Three-column metric row displaying RHR, HRV, and RR
struct TripleMetricRow: View {
    let rhrValue: String
    let hrvValue: String
    let rrValue: String

    var body: some View {
        HStack(alignment: .top, spacing: 21) {
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
                unit: "brpm"
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

    private let cardWidth: CGFloat = 105
    private let cardHeight: CGFloat = 81
    private let cornerRadius: CGFloat = 8.928

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.Wellness.adaptiveSecondaryText)

            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Color.Wellness.adaptivePrimaryText)

            Text(unit)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.Wellness.adaptiveSecondaryText.opacity(0.39))
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.white)
        .cornerRadius(cornerRadius)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 2.85,
            x: 0,
            y: 2.85
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 5.7,
            x: 0,
            y: 5.7
        )
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
