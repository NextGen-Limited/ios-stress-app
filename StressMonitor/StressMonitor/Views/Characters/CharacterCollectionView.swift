import SwiftData
import SwiftUI

struct CharacterCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CharacterCollectionViewModel()
    @State private var selectedCharacter: CharacterCreature?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(CharacterCreature.allCharacters) { creature in
                        CharacterGridCard(
                            creature: creature,
                            unlock: viewModel.unlockStatus(for: creature.id),
                            isActive: viewModel.activeCharacterId == creature.id
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture {
                            selectedCharacter = creature
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, 110)
        }
        .background(Color.Wellness.adaptiveBackground.ignoresSafeArea())
        .navigationTitle("Characters")
        .sheet(item: $selectedCharacter) { creature in
            CharacterDetailView(
                creature: creature,
                unlock: viewModel.unlockStatus(for: creature.id),
                onSelect: {
                    viewModel.selectCharacter(creature.id)
                    selectedCharacter = nil
                }
            )
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Elemental Creatures")
                .font(Typography.title1)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("Pick a buddy that reacts to your stress, grows with your habits, and follows you to Watch complications.")
                .font(Typography.callout)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        CharacterCollectionView()
    }
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
