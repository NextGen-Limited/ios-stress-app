import SwiftData
import SwiftUI

struct CharacterCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CharacterCollectionViewModel()
    @State private var selectedCharacter: CharacterCreature?
    @State private var selectedElement: CharacterElement?
    @State private var navigateToExport = false

    // MARK: - Computed

    private var unlockedCreatures: [CharacterCreature] {
        CharacterCreature.allCharacters.filter { creature in
            viewModel.unlockStatus(for: creature.id)?.isUnlocked ?? false
        }
    }

    private var lockedCreatures: [CharacterCreature] {
        CharacterCreature.allCharacters.filter { creature in
            !(viewModel.unlockStatus(for: creature.id)?.isUnlocked ?? false)
        }
    }

    private var activeCreature: CharacterCreature? {
        guard let activeId = viewModel.activeCharacterId,
              let creature = CharacterCreature.find(by: activeId) else { return nil }
        return creature
    }

    private var activeUnlock: CharacterUnlock? {
        guard let activeId = viewModel.activeCharacterId else { return nil }
        return viewModel.unlockStatus(for: activeId)
    }

    private var collectedCount: Int { unlockedCreatures.count }
    private var totalCount: Int { CharacterCreature.allCharacters.count }
    private var collectionProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(collectedCount) / Double(totalCount)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                collectionHero
                elementFilterChips

                if let creature = activeCreature {
                    activeBuddySection(creature)
                }

                if !unlockedCreatures.isEmpty {
                    unlockedSection
                }

                if !lockedCreatures.isEmpty {
                    lockedSection
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, 40)
        }
        .background(Color.Wellness.adaptiveBackground.ignoresSafeArea())
        .navigationTitle("Characters")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigateToExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.primaryBlue)
                }
                .accessibilityLabel("Export all character illustrations")
            }
        }
        .navigationDestination(isPresented: $navigateToExport) {
            CharacterIllustrationExportView()
        }
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

    // MARK: - Collection Hero

    private var collectionHero: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                // Circular progress with active character inside
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 8)
                        .frame(width: 96, height: 96)

                    Circle()
                        .trim(from: 0, to: max(collectionProgress, 0.001))
                        .stroke(
                            AngularGradient(
                                colors: [Color.primaryBlue, Color(hex: "#A5D6A7"), Color.primaryBlue],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: collectionProgress)

                    if let creature = activeCreature {
                        StressBuddyIllustration(
                            characterId: creature.id,
                            evolution: activeUnlock?.evolutionStage ?? .droplet,
                            mood: .calm,
                            size: 56
                        )
                    } else {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(collectedCount) of \(totalCount)")
                        .font(Typography.dataMedium)
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                    Text("Characters Collected")
                        .font(Typography.callout)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                    if let creature = activeCreature {
                        Text("\(creature.emoji) \(creature.displayName) active")
                            .font(Typography.caption1)
                            .foregroundStyle(creature.element.accentColor)
                            .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(Spacing.cardPadding)
            .background(
                LinearGradient(
                    colors: [
                        Color.primaryBlue.opacity(0.08),
                        Color.Wellness.adaptiveCardBackground,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primaryBlue.opacity(0.12), lineWidth: 1)
            )
        }
    }

    // MARK: - Element Filter Chips

    private var elementFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                filterChip(title: "All", element: nil, icon: nil)

                ForEach(CharacterElement.allCases, id: \.self) { element in
                    filterChip(title: element.displayName, element: element, icon: element.emoji)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(title: String, element: CharacterElement?, icon: String?) -> some View {
        let isSelected = selectedElement == element
        let color = element?.primaryColor ?? Color.primaryBlue

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedElement = element
            }
            HapticManager.shared.buttonPress()
        } label: {
            HStack(spacing: 4) {
                if let icon { Text(icon) }
                Text(title)
            }
            .font(Typography.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : Color.Wellness.adaptivePrimaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.Wellness.adaptiveCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
    }

    // MARK: - Active Buddy

    @ViewBuilder
    private func activeBuddySection(_ creature: CharacterCreature) -> some View {
        if shouldShow(creature) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Active Buddy", icon: "star.fill")

                if let unlock = activeUnlock {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(creature.element.primaryColor.opacity(0.15))
                                .frame(width: 72, height: 72)

                            StressBuddyIllustration(
                                characterId: creature.id,
                                evolution: unlock.evolutionStage,
                                mood: .calm,
                                size: 56
                            )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(creature.displayName)
                                    .font(Typography.headline)
                                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                                Text(creature.subtitle)
                                    .font(Typography.caption1)
                                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                            }

                            HStack(spacing: 8) {
                                Label("\(unlock.streakDays)d streak", systemImage: "flame.fill")
                                    .font(Typography.caption2)
                                    .foregroundStyle(.orange)

                                Label("\(unlock.sessionsCompleted) sessions", systemImage: "figure.mind.and.body")
                                    .font(Typography.caption2)
                                    .foregroundStyle(.teal)
                            }

                            EvolutionDots(currentStage: unlock.evolutionStage, color: creature.element.accentColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(Spacing.cardPadding)
                    .background(Color.Wellness.adaptiveCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(creature.element.primaryColor.opacity(0.3), lineWidth: 1.5)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                    .onTapGesture { selectedCharacter = creature }
                }
            }
        }
    }

    // MARK: - Unlocked Section

    @ViewBuilder
    private var unlockedSection: some View {
        let creatures = filteredCreatures(unlockedCreatures)
        if !creatures.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Your Buddies", icon: "heart.fill")

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(creatures) { creature in
                        CharacterGridCard(
                            creature: creature,
                            unlock: viewModel.unlockStatus(for: creature.id),
                            isActive: viewModel.activeCharacterId == creature.id
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture { selectedCharacter = creature }
                    }
                }
            }
        }
    }

    // MARK: - Locked Section

    @ViewBuilder
    private var lockedSection: some View {
        let creatures = filteredCreatures(lockedCreatures)
        if !creatures.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "To Discover", icon: "lock.fill")

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(creatures) { creature in
                        CharacterGridCard(
                            creature: creature,
                            unlock: viewModel.unlockStatus(for: creature.id),
                            isActive: false
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture { selectedCharacter = creature }
                    }
                }
            }
        }
    }

    // MARK: - Filtering Helper

    private func shouldShow(_ creature: CharacterCreature) -> Bool {
        guard let selectedElement else { return true }
        return creature.element == selectedElement
    }

    private func filteredCreatures(_ creatures: [CharacterCreature]) -> [CharacterCreature] {
        guard let selectedElement else { return creatures }
        return creatures.filter { $0.element == selectedElement }
    }
}

#Preview {
    NavigationStack {
        CharacterCollectionView()
    }
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
