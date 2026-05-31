import SwiftUI

// MARK: - Inline Stress View
/// SwiftUI view component for inline stress display
/// Provides a compact, text-only view for minimal space requirements
struct InlineStressView: View {
    let stressLevel: Double
    let category: StressCategory
    let showIcon: Bool
    let showLabel: Bool

    init(
        stressLevel: Double,
        category: StressCategory,
        showIcon: Bool = true,
        showLabel: Bool = true
    ) {
        self.stressLevel = stressLevel
        self.category = category
        self.showIcon = showIcon
        self.showLabel = showLabel
    }

    var body: some View {
        HStack(spacing: 4) {
            // Optional category icon
            if showIcon {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(category.color)
            }

            // Stress display text
            if hasData {
                if showLabel {
                    Text("Stress: ")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary) +
                    Text(stressLevelText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(category.color)
                } else {
                    Text(stressLevelText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(category.color)
                }
            } else {
                if showLabel {
                    Text("Stress: --")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: - Computed Properties
    private var stressLevelText: String {
        Int(stressLevel).description
    }

    private var hasData: Bool {
        stressLevel > 0
    }
}

// MARK: - Stress Label Component
/// Alternative component showing category instead of number
struct StressLabelInlineView: View {
    let category: StressCategory
    let showIcon: Bool

    init(category: StressCategory, showIcon: Bool = true) {
        self.category = category
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(category.color)
            }

            Text(category.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(category.color)
        }
        .lineLimit(1)
    }
}

// MARK: - Preview
#Preview("Mild Stress") {
    InlineStressView(
        stressLevel: 35,
        category: .mild
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("High Stress") {
    InlineStressView(
        stressLevel: 88,
        category: .high
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Relaxed") {
    InlineStressView(
        stressLevel: 15,
        category: .relaxed
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Moderate") {
    InlineStressView(
        stressLevel: 62,
        category: .moderate
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("No Icon") {
    InlineStressView(
        stressLevel: 45,
        category: .moderate,
        showIcon: false
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Number Only") {
    InlineStressView(
        stressLevel: 50,
        category: .moderate,
        showIcon: false,
        showLabel: false
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("No Data") {
    InlineStressView(
        stressLevel: 0,
        category: .relaxed
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Category Label") {
    StressLabelInlineView(
        category: .high
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("All Categories") {
    VStack(alignment: .leading, spacing: 8) {
        InlineStressView(stressLevel: 12, category: .relaxed)
        InlineStressView(stressLevel: 35, category: .mild)
        InlineStressView(stressLevel: 58, category: .moderate)
        InlineStressView(stressLevel: 82, category: .high)
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
