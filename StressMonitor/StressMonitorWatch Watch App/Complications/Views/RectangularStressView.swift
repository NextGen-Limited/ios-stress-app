import SwiftUI

// MARK: - Rectangular Stress View
/// SwiftUI view component for rectangular stress display
/// Provides a reusable view for showing stress metrics in a compact layout
struct RectangularStressView: View {
    let stressLevel: Double
    let category: StressCategory
    let hrv: Double
    let heartRate: Double
    let width: CGFloat
    let height: CGFloat

    init(
        stressLevel: Double,
        category: StressCategory,
        hrv: Double,
        heartRate: Double,
        width: CGFloat = 160,
        height: CGFloat = 80
    ) {
        self.stressLevel = stressLevel
        self.category = category
        self.hrv = hrv
        self.heartRate = heartRate
        self.width = width
        self.height = height
    }

    var body: some View {
        HStack(spacing: horizontalSpacing) {
            // Left: Stress level indicator
            stressIndicator

            Spacer(minLength: 4)

            // Center: Current stress level
            stressLevelDisplay

            Spacer(minLength: 4)

            // Right: Health metrics
            healthMetrics
        }
        .frame(width: width, height: height)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    // MARK: - View Components
    /// Stress level indicator with icon
    private var stressIndicator: some View {
        ZStack {
            Circle()
                .fill(category.color.opacity(0.15))

            Image(systemName: category.icon)
                .font(.system(size: iconSize))
                .foregroundColor(category.color)
        }
        .frame(width: indicatorSize, height: indicatorSize)
    }

    /// Stress level number display
    private var stressLevelDisplay: some View {
        VStack(alignment: .leading, spacing: verticalTextSpacing) {
            Text("Stress")
                .font(.system(size: labelSize, weight: .medium))
                .foregroundColor(.secondary)

            Text(stressLevelText)
                .font(.system(size: valueSize, weight: .bold, design: .rounded))
                .foregroundColor(category.color)
        }
    }

    /// Health metrics (HRV and heart rate)
    private var healthMetrics: some View {
        VStack(alignment: .trailing, spacing: verticalTextSpacing) {
            Text("HRV")
                .font(.system(size: metricLabelSize, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                Text(hrvText)
                    .font(.system(size: metricValueSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("ms")
                    .font(.system(size: unitSize, weight: .regular))
                    .foregroundColor(.secondary)
            }

            // Heart rate (optional, shown if space allows)
            if height >= 70 {
                HStack(spacing: 2) {
                    Text(heartRateText)
                        .font(.system(size: metricValueSize, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("bpm")
                        .font(.system(size: unitSize, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Layout Constants (computed from size)
    private var horizontalSpacing: CGFloat { width * 0.05 }
    private var horizontalPadding: CGFloat { width * 0.04 }
    private var verticalPadding: CGFloat { height * 0.05 }

    private var indicatorSize: CGFloat { min(width, height) * 0.25 }
    private var iconSize: CGFloat { min(width, height) * 0.10 }

    private var labelSize: CGFloat { height * 0.14 }
    private var valueSize: CGFloat { height * 0.24 }
    private var metricLabelSize: CGFloat { height * 0.12 }
    private var metricValueSize: CGFloat { height * 0.18 }
    private var unitSize: CGFloat { height * 0.11 }
    private var verticalTextSpacing: CGFloat { height * 0.04 }

    // MARK: - Computed Properties
    private var stressLevelText: String {
        hasData ? Int(stressLevel).description : "--"
    }

    private var hrvText: String {
        hasData ? String(format: "%.0f", hrv) : "--"
    }

    private var heartRateText: String {
        hasData ? String(format: "%.0f", heartRate) : "--"
    }

    private var hasData: Bool {
        stressLevel > 0 || hrv > 0
    }
}

// MARK: - Preview
#Preview("Mild Stress") {
    RectangularStressView(
        stressLevel: 32,
        category: .mild,
        hrv: 48,
        heartRate: 72
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("High Stress") {
    RectangularStressView(
        stressLevel: 85,
        category: .high,
        hrv: 22,
        heartRate: 95
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Relaxed") {
    RectangularStressView(
        stressLevel: 18,
        category: .relaxed,
        hrv: 65,
        heartRate: 58
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("No Data") {
    RectangularStressView(
        stressLevel: 0,
        category: .relaxed,
        hrv: 0,
        heartRate: 0
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Compact") {
    RectangularStressView(
        stressLevel: 45,
        category: .moderate,
        hrv: 38,
        heartRate: 78,
        width: 140,
        height: 60
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Large") {
    RectangularStressView(
        stressLevel: 62,
        category: .moderate,
        hrv: 35,
        heartRate: 82,
        width: 200,
        height: 100
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
