import SwiftUI

/// Health stat card for metrics like Mindfulness, Noise, Daylight, Steps
/// Figma: 169pt × 108.579pt, white bg, icon + title + value
struct HealthStatCard: View {
    let iconAsset: String
    let title: String
    let value: String
    let unit: String?
    let secondaryValue: String?
    let secondaryUnit: String?

    var body: some View {
        VStack(spacing: 14.599) {
            // Icon + Title
            HStack(spacing: 4) {
                Image(iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18.249, height: 18.249)

                Text(title)
                    .font(.custom("Lato-Bold", size: 14))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .tracking(-0.21)
            }

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 7.299) {
                Text(value)
                    .font(.custom("Lato-Bold", size: 24))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .tracking(-0.36)

                if let unit = unit {
                    Text(unit)
                        .font(.custom("Lato-Bold", size: 23.723))
                        .foregroundStyle(Color(hex: "707070"))
                }
            }

            // Secondary value (for steps)
            if let secondaryValue = secondaryValue, let secondaryUnit = secondaryUnit {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(secondaryValue)
                        .font(.custom("Lato-Bold", size: 24))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        .tracking(-0.36)

                    Text("/")
                        .font(.custom("Lato-Bold", size: 24))
                        .foregroundStyle(Color.lightGrey)

                    Text(secondaryUnit)
                        .font(.custom("Lato-Bold", size: 16))
                        .foregroundStyle(Color.lightGrey)
                }
            }
        }
        .frame(width: 169, height: 108.579)
        .padding(.horizontal, 21.898)
        .padding(.vertical, 10.949)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(unit ?? "")\(secondaryValue.map { " / \($0)\(secondaryUnit ?? "")" } ?? "")")
    }
}

// MARK: - 2×2 Grid Layout

/// 2×2 grid of health stat cards
struct HealthStatsGrid: View {
    var body: some View {
        VStack(spacing: 10.6) {
            HStack(spacing: 10.6) {
                HealthStatCard(
                    iconAsset: "tabler-flower-filled",
                    title: "Mindfulness",
                    value: "25",
                    unit: "m",
                    secondaryValue: nil,
                    secondaryUnit: nil
                )

                HealthStatCard(
                    iconAsset: "fluent-speaker-2-24-filled",
                    title: "Noise",
                    value: "High",
                    unit: nil,
                    secondaryValue: nil,
                    secondaryUnit: nil
                )
            }

            HStack(spacing: 10.6) {
                HealthStatCard(
                    iconAsset: "tabler-sun-filled",
                    title: "Daylight",
                    value: "25",
                    unit: "m",
                    secondaryValue: nil,
                    secondaryUnit: nil
                )

                HealthStatCard(
                    iconAsset: "famicons-footsteps-sharp",
                    title: "Steps",
                    value: "400",
                    unit: nil,
                    secondaryValue: "10000",
                    secondaryUnit: nil
                )
            }
        }
        .frame(width: 358)
    }
}

// MARK: - Preview

#Preview("HealthStatCard") {
    VStack(spacing: 16) {
        HealthStatsGrid()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
