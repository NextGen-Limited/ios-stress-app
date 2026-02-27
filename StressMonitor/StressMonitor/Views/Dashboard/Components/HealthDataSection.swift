import SwiftUI

// MARK: - Health Data Section

/// Health stats display showing exercise, sleep, and daylight data
struct HealthDataSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Section header
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("Your health data")
                    .font(Typography.headline)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                Button(action: {
                    HapticManager.shared.buttonPress()
                    // TODO: Show health data info
                }) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
                .accessibilityLabel("Health data information")
            }

            // Health data items
            HStack(spacing: DesignTokens.Spacing.md) {
                HealthDataItem(
                    icon: "figure.run",
                    label: "Exercise",
                    value: "32",
                    unit: "min",
                    color: Color.Wellness.exerciseCyan
                )

                HealthDataItem(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: "7.5",
                    unit: "hrs",
                    color: Color.Wellness.sleepPurple
                )

                HealthDataItem(
                    icon: "sun.max.fill",
                    label: "Daylight",
                    value: "45",
                    unit: "min",
                    color: Color.Wellness.daylightYellow
                )
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Health Data Item

/// Individual health metric display with circular progress indicator placeholder
struct HealthDataItem: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Circular progress indicator placeholder with icon
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 48, height: 48)

                // Progress arc placeholder (static for now)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            // Value and unit
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(unit)
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)
            }

            // Label
            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

// MARK: - Preview

#Preview {
    HealthDataSection()
        .padding()
        .background(Color.Wellness.background)
}
