import SwiftUI

// MARK: - Circular Stress View
/// SwiftUI view component for circular stress display
/// Provides a reusable view that can be used in both complications and the main app
struct CircularStressView: View {
    let stressLevel: Double
    let category: StressCategory
    let showLabel: Bool
    let size: CGFloat

    init(
        stressLevel: Double,
        category: StressCategory,
        showLabel: Bool = true,
        size: CGFloat = 120
    ) {
        self.stressLevel = stressLevel
        self.category = category
        self.showLabel = showLabel
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background ring (full circle, subtle gray)
            Circle()
                .stroke(
                    Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )

            // Stress level ring (color-coded, partial fill)
            Circle()
                .trim(from: 0, to: stressFraction)
                .stroke(
                    category.color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stressFraction)

            // Center content
            VStack(spacing: verticalSpacing) {
                // Stress level number
                Text(stressLevelText)
                    .font(.system(size: textSize, weight: .bold, design: .rounded))
                    .foregroundColor(category.color)
                    .contentTransition(.numericText(value: stressLevel))

                // Category label (optional)
                if showLabel {
                    Text(category.label)
                        .font(.system(size: labelSize, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Layout Constants
    private var ringWidth: CGFloat { size * 0.08 }
    private var textSize: CGFloat { size * 0.22 }
    private var labelSize: CGFloat { size * 0.10 }
    private var verticalSpacing: CGFloat { size * 0.02 }

    // MARK: - Computed Properties
    private var stressFraction: CGFloat {
        CGFloat(min(max(stressLevel, 0), 100) / 100.0)
    }

    private var stressLevelText: String {
        Int(stressLevel).description
    }
}

// MARK: - Stress Category Extension
extension StressCategory {
    /// Human-readable label for the category
    var label: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

// MARK: - Preview
#Preview("Relaxed") {
    CircularStressView(
        stressLevel: 15,
        category: .relaxed
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Mild") {
    CircularStressView(
        stressLevel: 35,
        category: .mild
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Moderate") {
    CircularStressView(
        stressLevel: 60,
        category: .moderate
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("High") {
    CircularStressView(
        stressLevel: 85,
        category: .high
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Compact") {
    CircularStressView(
        stressLevel: 45,
        category: .mild,
        showLabel: false,
        size: 60
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Watch Size") {
    HStack(spacing: 20) {
        CircularStressView(
            stressLevel: 25,
            category: .relaxed,
            size: 80
        )

        CircularStressView(
            stressLevel: 50,
            category: .moderate,
            size: 80
        )

        CircularStressView(
            stressLevel: 75,
            category: .high,
            size: 80
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
