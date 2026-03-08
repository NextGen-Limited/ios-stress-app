import SwiftUI

/// Watch metric card showing health data from Apple Watch
/// Figma: 358pt × 110pt, white bg, icon + duration + metrics
struct WatchMetricCard: View {
    let iconName: String
    let iconAsset: String?
    let title: String
    let tintColor: Color
    let duration: String
    let metrics: [MetricItem]

    struct MetricItem {
        let label: String
        let value: String
        let valueColor: Color
    }

    var body: some View {
        HStack(spacing: 14.599) {
            // Left: Icon with time
            VStack(spacing: 0) {
                // Icon
                if let asset = iconAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                } else {
                    Image(systemName: iconName)
                        .font(.title)
                        .foregroundStyle(tintColor)
                        .frame(width: 65, height: 65)
                }

                // Duration below icon
                Text(duration)
                    .font(.custom("Lato-Bold", size: 12))
                    .foregroundStyle(tintColor)
                    .tracking(-0.18)
            }
            .frame(width: 65)

            // Right: Metrics
            VStack(alignment: .leading, spacing: 14) {
                // Title
                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 21.898))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                    Text(title)
                        .font(.custom("Lato-Bold", size: 14))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        .tracking(-0.21)
                }

                // Metrics row
                HStack(spacing: 0) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        VStack(alignment: .center, spacing: 0) {
                            Text(metric.label)
                                .font(.custom("Lato-Bold", size: 11))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                                .tracking(-0.165)

                            Text(metric.value)
                                .font(.custom("Lato-Bold", size: 14))
                                .foregroundStyle(metric.valueColor)
                                .tracking(-0.21)
                        }
                        .frame(maxWidth: .infinity)

                        if index < metrics.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(width: 245)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 21.898)
        .padding(.vertical, 14.599)
        .frame(width: 358, height: 110)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Convenience Initializers

extension WatchMetricCard {
    /// Sleep card with default styling
    static func sleep(duration: String, quality: String, rhr: String) -> WatchMetricCard {
        WatchMetricCard(
            iconName: "moon.zzz.fill",
            iconAsset: nil,
            title: "Sleep",
            tintColor: Color.Wellness.sleepPurple,
            duration: duration,
            metrics: [
                MetricItem(label: "Duration", value: "00h00m / 00h00m", valueColor: Color(hex: "575757")),
                MetricItem(label: "Quality", value: quality, valueColor: Color.positive),
                MetricItem(label: "RHR", value: rhr, valueColor: Color(hex: "575757"))
            ]
        )
    }

    /// Exercise card with default styling
    static func exercise(duration: String, standing: String, calories: String) -> WatchMetricCard {
        WatchMetricCard(
            iconName: "figure.run",
            iconAsset: nil,
            title: "Exercise",
            tintColor: Color.Wellness.exerciseCyan,
            duration: duration,
            metrics: [
                MetricItem(label: "Duration", value: "00h00m / 00h00m", valueColor: Color(hex: "575757")),
                MetricItem(label: "Standing", value: standing, valueColor: Color(hex: "575757")),
                MetricItem(label: "Calories", value: calories, valueColor: Color.accentOrange)
            ]
        )
    }
}

// MARK: - Preview

#Preview("WatchMetricCard") {
    VStack(spacing: 16) {
        WatchMetricCard.sleep(
            duration: "00h00m",
            quality: "Excellent",
            rhr: "50"
        )

        WatchMetricCard.exercise(
            duration: "00h00m",
            standing: "50m",
            calories: "1000"
        )
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
