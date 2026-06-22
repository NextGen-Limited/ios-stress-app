import SwiftData
import SwiftUI

/// Characters collection card for Settings — shows active buddy + collection progress.
/// Replaces the former Characters tab as the entry point to CharacterCollectionView.
struct CharactersCard: View {
    var onTap: (() -> Void)? = nil

    @Query(filter: #Predicate<CharacterUnlock> { $0.isUnlocked })
    private var unlockedCharacters: [CharacterUnlock]

    @Query(filter: #Predicate<CharacterUnlock> { $0.isActive })
    private var activeUnlocks: [CharacterUnlock]

    private var activeCreature: CharacterCreature {
        activeUnlocks.first
            .flatMap { CharacterCreature.find(by: $0.characterId) }
            ?? CharacterCreature.allCharacters[0]
    }

    private var activeEvolution: EvolutionStage {
        activeUnlocks.first?.evolutionStage ?? .droplet
    }

    private var collectedCount: Int {
        unlockedCharacters.count
    }

    private var totalCount: Int {
        CharacterCreature.allCharacters.count
    }

    var body: some View {
        Button(action: { onTap?() }) {
            SettingsCard {
                HStack(spacing: 16) {
                    // Active character preview
                    ZStack {
                        Circle()
                            .fill(activeCreature.element.primaryColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        StressBuddyIllustration(
                            characterId: activeCreature.id,
                            evolution: activeEvolution,
                            mood: .serene,
                            size: 44
                        )
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Characters")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(-0.27)
                            .foregroundColor(.primary)

                        Text("\(activeCreature.emoji) \(activeCreature.displayName) • \(collectedCount)/\(totalCount) collected")
                            .font(.system(size: 13, weight: .regular))
                            .tracking(-0.195)
                            .foregroundColor(.textDescriptive)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(activeCreature.element.accentColor)
                }
                .padding(.horizontal, 5)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Characters. \(activeCreature.displayName) active. \(collectedCount) of \(totalCount) collected.")
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        CharactersCard()
    }
    .padding()
    .background(Color.adaptiveSettingsBackground)
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
