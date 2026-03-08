import SwiftUI

// MARK: - Quick Action Card (Figma Design)

/// Horizontal scrollable action cards for wellness activities
/// Figma: 283pt × 98pt, title + description + duration badge + image
struct QuickActionCard<Destination: View>: View {
    let title: String
    let description: String
    let duration: String
    let color: Color
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack(alignment: .topLeading) {
                // Background
                color
                    .cornerRadius(20)

                // Content
                HStack(alignment: .top, spacing: 0) {
                    // Left: Title, description, duration
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.custom("Lato-Bold", size: 16))
                            .foregroundStyle(.white)
                            .tracking(-0.24)
                            .lineLimit(1)

                        Text(description)
                            .font(.custom("Lato-Regular", size: 11))
                            .foregroundStyle(.white)
                            .tracking(-0.165)
                            .lineLimit(2)
                            .frame(width: 121, alignment: .leading)

                        // Duration badge
                        Text(duration)
                            .font(.custom("Lato-Bold", size: 12))
                            .foregroundStyle(.white)
                            .tracking(-0.18)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                            .background(color.darker())
                            .cornerRadius(16.3)
                    }
                    .padding(.leading, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    Spacer()

                    // Right: Image placeholder
                    Image(systemName: "figure.mind.and.body")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 114, height: 98)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(width: 283, height: 98)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description). Duration: \(duration)")
        .accessibilityHint("Double tap to start activity")
    }
}

// MARK: - Color Extension for Darker

private extension Color {
    func darker() -> Color {
        // Create a darker version of the color for the duration badge
        UIColor(self).darkerColor.map { Color($0) } ?? self.opacity(0.6)
    }
}

private extension UIColor {
    var darkerColor: UIColor? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.7, alpha: alpha)
        }
        return nil
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
