import SwiftUI

struct IAPBenefitsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label
            Text("WHAT PREMIUM UNLOCKS")
                .font(Typography.iapSectionHeader)
                .kerning(0.10 * 12)
                .foregroundStyle(Color.iapHeaderTeal)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            // Benefits card
            VStack(spacing: 0) {
                benefitRow(
                    icon: "waveform.path.ecg",
                    accentColor: Color.iapHeaderTeal,
                    title: "Personal daily recovery plan",
                    description: "Recommended breathing, walk, rest, and reflection actions based on today’s stress context."
                )

                Divider()
                    .background(Color.iapIconBorder.opacity(0.15))
                    .padding(.horizontal, 2)

                benefitRow(
                    icon: "sparkles",
                    accentColor: Color.iapPurple,
                    title: "Unlimited AI Wellness Coach",
                    description: "Ask what to do next, understand your body signals, and get calmer guidance in the moment."
                )

                Divider()
                    .background(Color.iapIconBorder.opacity(0.15))
                    .padding(.horizontal, 2)

                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    accentColor: Color.iapSavingsGreen,
                    title: "Long-term patterns & insights",
                    description: "See what actually affects your stress: sleep, activity, daylight, mindfulness, and noise."
                )
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.iapCardBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 18, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.iapIconBorder.opacity(0.09), lineWidth: 1)
            )
        }
    }

    // MARK: - Subcomponents

    private func benefitRow(icon: String, accentColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(0.12))
                )

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Typography.iapBenefitTitle)
                    .tracking(-0.025 * 15)
                    .foregroundStyle(Color.iapTextPrimary)

                Text(description)
                    .font(Typography.iapBenefitDescription)
                    .foregroundStyle(Color.iapTextSecondary)
                    .lineSpacing(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
    }
}

#Preview {
    ScrollView {
        IAPBenefitsCard()
            .padding(16)
    }
    .background(Color(hex: "F5F2EC"))
}
