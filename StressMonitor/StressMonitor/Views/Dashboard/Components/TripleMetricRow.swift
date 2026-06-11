import SwiftUI

/// Three-column metric row displaying RHR, HRV, and RR.
/// Redesigned for the Home tab to match the Ripple / Elemental Creatures palette.
struct TripleMetricRow: View {
    let rhrValue: String
    let hrvValue: String
    let rrValue: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MetricColumn(
                title: "Heart",
                value: rhrValue,
                unit: "bpm",
                icon: "heart.fill",
                accent: HomeCharacterDesignTokens.Ember.accent
            )

            MetricColumn(
                title: "HRV",
                value: hrvValue,
                unit: "ms",
                icon: "waveform.path.ecg",
                accent: HomeCharacterDesignTokens.Ripple.primary
            )

            MetricColumn(
                title: "Breath",
                value: rrValue,
                unit: "brpm",
                icon: "wind",
                accent: HomeCharacterDesignTokens.Zephyr.accent
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Heart rate: \(rhrValue) bpm, Heart rate variability: \(hrvValue) ms, Respiratory rate: \(rrValue) breaths per minute")
    }
}

// MARK: - Metric Column

private struct MetricColumn: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.16))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                }

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.Wellness.adaptivePrimaryText)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                Text(unit)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.Wellness.adaptiveSecondaryText.opacity(0.72))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.10), radius: 12, x: 0, y: 8)
    }
}

#Preview("TripleMetricRow") {
    VStack {
        TripleMetricRow(
            rhrValue: "72",
            hrvValue: "65",
            rrValue: "14"
        )
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
