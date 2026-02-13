import SwiftUI

// MARK: - Stress Character Card

/// Character-based stress level visualization with animations
/// Displays Stress Buddy mascot with mood-based appearance
/// Full Reduce Motion support with static fallbacks
struct StressCharacterCard: View {
    let mood: StressBuddyMood
    let stressLevel: Double
    let hrv: Double?
    let size: StressBuddyMood.CharacterContext

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Character with animation
            characterView
                .accessibilityLabel(mood.accessibilityDescription)
                .accessibilityValue("Stress level: \(Int(stressLevel))")

            // Stress level
            Text("\(Int(stressLevel))")
                .font(fontForSize())
                .foregroundStyle(mood.color)
                .monospacedDigit()

            // Mood label
            Text(mood.displayName)
                .font(labelFontForSize())
                .foregroundStyle(.secondary)

            // HRV value (optional)
            if let hrv = hrv {
                Text("HRV: \(Int(hrv))ms")
                    .font(captionFontForSize())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
    }

    // MARK: - Character View

    @ViewBuilder
    private var characterView: some View {
        ZStack {
            // Main character symbol
            Image(systemName: mood.symbol)
                .font(.system(size: mood.symbolSize(for: size)))
                .foregroundStyle(mood.color)
                .symbolRenderingMode(.hierarchical)
                .characterAnimation(for: mood)

            // Accessories
            accessoriesView
        }
    }

    @ViewBuilder
    private var accessoriesView: some View {
        if !mood.accessories.isEmpty {
            ForEach(Array(mood.accessories.enumerated()), id: \.offset) { index, accessory in
                Image(systemName: accessory)
                    .font(.system(size: mood.accessorySize(for: size)))
                    .foregroundStyle(mood.color.opacity(0.7))
                    .offset(accessoryOffset(for: index, total: mood.accessories.count))
                    .accessoryAnimation(index: index)
            }
        }
    }

    // MARK: - Layout Helpers

    /// Position accessories around the character
    private func accessoryOffset(for index: Int, total: Int) -> CGSize {
        let radius = mood.symbolSize(for: size) * 0.6
        let angle = (Double(index) / Double(total)) * 2 * Double.pi

        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }

    // MARK: - Typography Helpers

    private func fontForSize() -> Font {
        switch size {
        case .dashboard:
            return Typography.dataLarge
        case .widget:
            return Typography.dataMedium
        case .watchOS:
            return Typography.dataSmall
        }
    }

    private func labelFontForSize() -> Font {
        switch size {
        case .dashboard:
            return Typography.headline
        case .widget:
            return Typography.callout
        case .watchOS:
            return Typography.footnote
        }
    }

    private func captionFontForSize() -> Font {
        switch size {
        case .dashboard:
            return Typography.footnote
        case .widget:
            return Typography.caption1
        case .watchOS:
            return Typography.caption2
        }
    }
}

// MARK: - Convenience Initializers

extension StressCharacterCard {
    /// Create character card from StressResult
    init(result: StressResult, size: StressBuddyMood.CharacterContext) {
        self.mood = StressBuddyMood.from(stressLevel: result.level)
        self.stressLevel = result.level
        self.hrv = result.hrv
        self.size = size
    }

    /// Create character card with minimal data
    init(stressLevel: Double, size: StressBuddyMood.CharacterContext) {
        self.mood = StressBuddyMood.from(stressLevel: stressLevel)
        self.stressLevel = stressLevel
        self.hrv = nil
        self.size = size
    }
}

// MARK: - Preview

#Preview("All Moods - Dashboard") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach([0.0, 5.0, 15.0, 35.0, 60.0, 85.0], id: \.self) { level in
                StressCharacterCard(
                    mood: .from(stressLevel: level),
                    stressLevel: level,
                    hrv: 65,
                    size: .dashboard
                )
                .background(Color.Wellness.surface)
                .cornerRadius(DesignTokens.Layout.cornerRadius)
            }
        }
        .padding()
        .background(Color.Wellness.background)
    }
}

#Preview("Widget Size") {
    VStack(spacing: 16) {
        StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .widget
        )
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)

        StressCharacterCard(
            mood: .worried,
            stressLevel: 60,
            hrv: 45,
            size: .widget
        )
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }
    .padding()
    .background(Color.Wellness.background)
}

#Preview("watchOS Size") {
    VStack(spacing: 12) {
        StressCharacterCard(
            mood: .sleeping,
            stressLevel: 5,
            hrv: nil,
            size: .watchOS
        )
        .frame(width: 200, height: 200)
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }
    .padding()
    .background(Color.Wellness.background)
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 90,
            hrv: 30,
            size: .dashboard
        )
        .background(Color.Wellness.surface)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }
    .padding()
    .background(Color.Wellness.background)
    .preferredColorScheme(.dark)
}
