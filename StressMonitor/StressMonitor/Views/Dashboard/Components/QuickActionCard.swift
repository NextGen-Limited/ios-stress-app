import SwiftUI

// MARK: - Quick Action Card

/// Horizontal scrollable action cards for wellness activities
struct QuickActionCard<Destination: View>: View {
    let title: String
    let description: String
    let duration: String
    let color: Color
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Title
                Text(title)
                    .font(Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Description (13pt, 2 lines max)
                Text(description)
                    .font(Typography.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                Spacer()

                // Duration badge and image placeholder
                HStack {
                    // Duration badge
                    Text(duration)
                        .font(Typography.caption1)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)

                    Spacer()

                    // Image placeholder
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(DesignTokens.Layout.cardPadding)
            .frame(width: 268, height: 98)
            .background(color)
            .cornerRadius(DesignTokens.Layout.cornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description). Duration: \(duration)")
        .accessibilityHint("Double tap to start activity")
    }
}

// MARK: - Convenience Static Methods

extension QuickActionCard where Destination == PlaceholderDestination {
    /// Gratitude journaling activity card
    static func gratitude() -> QuickActionCard<PlaceholderDestination> {
        QuickActionCard<PlaceholderDestination>(
            title: "Gratitude",
            description: "Take a moment to reflect on what you're grateful for",
            duration: "0:45s",
            color: Color.Wellness.gratitudePurple,
            destination: { PlaceholderDestination(title: "Gratitude") }
        )
    }

    /// Mini walk activity card
    static func miniWalk() -> QuickActionCard<PlaceholderDestination> {
        QuickActionCard<PlaceholderDestination>(
            title: "Mini Walk",
            description: "A short walk to refresh your mind and body",
            duration: "3 mins",
            color: Color.Wellness.miniWalkBlue,
            destination: { PlaceholderDestination(title: "Mini Walk") }
        )
    }
}

extension QuickActionCard where Destination == BreathingExerciseView {
    /// Box breathing exercise card
    static func boxBreathing() -> QuickActionCard<BreathingExerciseView> {
        QuickActionCard<BreathingExerciseView>(
            title: "Box Breathing",
            description: "A calming breathing technique for stress relief",
            duration: "3 mins",
            color: Color.Wellness.boxBreathingPurple,
            destination: { BreathingExerciseView() }
        )
    }
}

// MARK: - Placeholder Destination

/// Placeholder view for activities not yet implemented
struct PlaceholderDestination: View {
    let title: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(Color.Wellness.calmBlue)

            Text(title)
                .font(Typography.title2)
                .fontWeight(.bold)

            Text("Coming soon")
                .font(Typography.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Wellness.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                QuickActionCard.gratitude()
                QuickActionCard.miniWalk()
                QuickActionCard.boxBreathing()
            }
            .padding()
        }
    }
}
