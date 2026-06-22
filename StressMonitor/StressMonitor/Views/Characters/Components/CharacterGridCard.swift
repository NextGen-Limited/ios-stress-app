import SwiftUI

struct CharacterGridCard: View {
    let creature: CharacterCreature
    let unlock: CharacterUnlock?
    let isActive: Bool

    private var isUnlocked: Bool { unlock?.isUnlocked ?? false }
    private var isPremium: Bool { creature.unlockType == .premium }
    private var isStreakGated: Bool { creature.unlockType == .streakGated }
    private var currentStage: EvolutionStage { unlock?.evolutionStage ?? .droplet }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(creature.element.primaryColor.opacity(0.15))
                    .frame(width: 86, height: 86)

                if isUnlocked {
                    StressBuddyIllustration(
                        characterId: creature.id,
                        evolution: currentStage,
                        mood: .serene,
                        size: 64
                    )
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(creature.element.primaryColor.opacity(0.65))
                }
            }
            .overlay(alignment: .topTrailing) {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .background(Circle().fill(Color.Wellness.adaptiveCardBackground).padding(-2))
                        .accessibilityLabel("Active character")
                }
            }

            VStack(spacing: 2) {
                Text(creature.displayName)
                    .font(Typography.headline)
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text("\(creature.element.emoji) \(creature.subtitle)")
                    .font(Typography.caption1)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if isUnlocked {
                EvolutionDots(currentStage: currentStage, color: creature.element.accentColor)
            } else {
                unlockBadge
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPadding)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isActive ? creature.element.primaryColor : Color.borderLight.opacity(0.45), lineWidth: isActive ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap for character details")
    }

    @ViewBuilder
    private var unlockBadge: some View {
        HStack(spacing: 4) {
            if isPremium {
                Image(systemName: "crown.fill")
                Text("Premium")
            } else if isStreakGated {
                Image(systemName: "flame.fill")
                Text("\(creature.streakRequired)d streak")
            }
        }
        .font(Typography.caption2)
        .foregroundStyle(isPremium ? .orange : .blue)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background((isPremium ? Color.orange : Color.blue).opacity(0.12))
        .clipShape(Capsule())
    }

    private var accessibilityLabel: String {
        let status = isUnlocked ? "unlocked" : "locked"
        let active = isActive ? ", active" : ""
        return "\(creature.displayName), \(creature.subtitle), \(status)\(active)"
    }
}
