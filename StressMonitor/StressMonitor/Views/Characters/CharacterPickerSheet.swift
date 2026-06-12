import SwiftData
import SwiftUI

struct CharacterPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<CharacterUnlock> { $0.isUnlocked }, sort: [SortDescriptor(\CharacterUnlock.characterId)])
    private var unlockedCharacters: [CharacterUnlock]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(unlockedCharacters, id: \.characterId) { unlock in
                        if let creature = CharacterCreature.find(by: unlock.characterId) {
                            compactCharacterButton(creature: creature, unlock: unlock)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.Wellness.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Choose Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func compactCharacterButton(creature: CharacterCreature, unlock: CharacterUnlock) -> some View {
        Button {
            selectCharacter(unlock.characterId)
        } label: {
            VStack(spacing: 4) {
                StressBuddyIllustration(
                    characterId: creature.id,
                    evolution: unlock.evolutionStage,
                    mood: .calm,
                    size: 52
                )

                Text(creature.displayName)
                    .font(Typography.caption1)
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(unlock.isActive ? creature.element.primaryColor.opacity(0.18) : Color.Wellness.adaptiveCardBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(unlock.isActive ? creature.element.primaryColor : Color.borderLight.opacity(0.6), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose \(creature.displayName)")
    }

    private func selectCharacter(_ characterId: String) {
        guard let selected = unlockedCharacters.first(where: { $0.characterId == characterId }) else { return }
        for unlock in unlockedCharacters {
            unlock.isActive = (unlock.characterId == characterId)
        }
        try? modelContext.save()
        CharacterSelectionSync.shared.saveActiveCharacter(characterId: characterId, evolution: selected.evolutionStage)
        dismiss()
    }
}
