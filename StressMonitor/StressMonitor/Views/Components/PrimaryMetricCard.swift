import SwiftUI

struct PrimaryMetricCard: View {
    let stressLevel: StressCategory
    let hrvValue: Double
    let confidence: Double
    let lastUpdate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: stressLevel.icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color.stressColor(for: stressLevel))

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(stressLevel.rawValue.capitalized)
                        .font(.system(size: DesignTokens.Typography.headline, weight: .bold))
                        .foregroundColor(Color.stressColor(for: stressLevel))

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text("\(Int(confidence * 100))% confidence")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(formattedTime)
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.xs) {
                Text(String(format: "%.0f", hrvValue))
                    .font(.system(size: DesignTokens.Typography.largeTitle, weight: .medium))
                    .foregroundColor(.primary)

                Text("ms")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignTokens.Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HRV measurement")
        .accessibilityValue("\(String(format: "%.0f", hrvValue)) milliseconds, \(stressLevel.rawValue) stress level")
    }

    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        PrimaryMetricCard(
            stressLevel: .relaxed,
            hrvValue: 65,
            confidence: 0.95,
            lastUpdate: Date()
        )
        PrimaryMetricCard(
            stressLevel: .high,
            hrvValue: 25,
            confidence: 0.72,
            lastUpdate: Date().addingTimeInterval(-3600)
        )
    }
    .padding()
}
