import SwiftUI

// MARK: - Char Companion Card

/// A reusable companion banner card that renders a character via
/// `StressBuddyIllustration` (no emoji), matching the new design system.
///
/// Used in Settings/Dashboard to show the active character with its name,
/// subtitle, and stress-reactive mood. Replaces the legacy emoji-based card.
struct CharCompanionCard: View {
    let characterId: String
    let displayName: String
    let subtitle: String
    let mood: RippleMood
    let evolution: EvolutionStage
    var onTap: (() -> Void)? = nil

    private var element: CharacterElement {
        CharacterCreature.find(by: characterId)?.element ?? .water
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Character art (procedural, no emoji)
            ZStack {
                Circle()
                    .fill(element.primaryColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                StressBuddyIllustration(
                    characterId: characterId,
                    evolution: evolution,
                    mood: mood,
                    size: 48
                )
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(0.4)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(Spacing.cardPadding)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(element.primaryColor.opacity(0.2), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), \(subtitle)")
        .accessibilityHint("View character details")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CharCompanionCard(
            characterId: "ripple",
            displayName: "Ripple",
            subtitle: "Water Otter · Stage 1",
            mood: .serene,
            evolution: .droplet
        )
        CharCompanionCard(
            characterId: "blossom",
            displayName: "Blossom",
            subtitle: "Forest Fox · Stage 2",
            mood: .happy,
            evolution: .ripple
        )
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
