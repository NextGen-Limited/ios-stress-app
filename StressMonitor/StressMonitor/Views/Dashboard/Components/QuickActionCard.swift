import SwiftUI

// MARK: - Quick Action Card (Home Redesign)

/// Horizontal scrollable action cards for wellness activities.
/// Redesigned with Elemental Creature colors from the concept sheet.
struct QuickActionCard<Destination: View>: View {
    let title: String
    let description: String
    let duration: String
    let color: Color
    let icon: String
    let destination: () -> Destination

    init(
        title: String,
        description: String,
        duration: String,
        color: Color,
        icon: String = "figure.mind.and.body",
        destination: @escaping () -> Destination
    ) {
        self.title = title
        self.description = description
        self.duration = duration
        self.color = color
        self.icon = icon
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.98), color.opacity(0.72), color.darker().opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 124, height: 124)
                    .offset(x: 190, y: -34)

                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: 1)
                    .frame(width: 72, height: 72)
                    .offset(x: 226, y: 42)

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(duration)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())

                        Text(title)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(-0.24)
                            .lineLimit(1)

                        Text(description)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
                            .tracking(-0.12)
                            .lineLimit(2)
                            .frame(width: 165, alignment: .leading)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.22))
                            .frame(width: 56, height: 56)
                        Image(systemName: icon)
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(18)
            }
            .frame(width: 292, height: 118)
            .shadow(color: color.opacity(0.26), radius: 16, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
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
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.74, alpha: alpha)
        }
        return nil
    }
}

// MARK: - Convenience Static Methods

extension QuickActionCard where Destination == PlaceholderDestination {
    static func gratitude() -> QuickActionCard<PlaceholderDestination> {
        QuickActionCard<PlaceholderDestination>(
            title: "Gratitude",
            description: "Help Blossom grow with one good note",
            duration: "0:45s",
            color: HomeCharacterDesignTokens.Blossom.accent,
            icon: "leaf.fill",
            destination: { PlaceholderDestination(title: "Gratitude") }
        )
    }
}

extension QuickActionCard where Destination == MiniWalkView {
    static func miniWalk() -> QuickActionCard<MiniWalkView> {
        QuickActionCard<MiniWalkView>(
            title: "Mini Walk",
            description: "Let Ripple reset your nervous system",
            duration: "0:45s",
            color: HomeCharacterDesignTokens.Ripple.primary,
            icon: "figure.walk.circle.fill",
            destination: { MiniWalkView() }
        )
    }
}

extension QuickActionCard where Destination == BreathingExerciseView {
    static func boxBreathing() -> QuickActionCard<BreathingExerciseView> {
        QuickActionCard<BreathingExerciseView>(
            title: "Box Breathing",
            description: "Zephyr guides slow, steady breaths",
            duration: "3 mins",
            color: HomeCharacterDesignTokens.Zephyr.accent,
            icon: "wind",
            destination: { BreathingExerciseView() }
        )
    }
}

// MARK: - Placeholder Destination

struct PlaceholderDestination: View {
    let title: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: AppIconSystem.Action.bodyScan.sfSymbol)
                .font(.system(size: 60))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)

            Text(title)
                .font(Typography.title2)
                .fontWeight(.bold)

            Text("Coming soon")
                .font(Typography.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HomeCharacterDesignTokens.homeBackground)
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
        .background(HomeCharacterDesignTokens.homeBackground)
    }
}
