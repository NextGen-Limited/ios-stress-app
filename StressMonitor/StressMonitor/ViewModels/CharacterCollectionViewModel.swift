import Observation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class CharacterCollectionViewModel {
    var unlocks: [CharacterUnlock] = []
    var activeCharacterId: String?
    var currentStressLevel: Double = 0

    private var modelContext: ModelContext?
    private let characterSync = CharacterSelectionSync.shared

    /// Mood derived from the latest stress reading — drives character facial expression.
    var currentMood: RippleMood {
        RippleMood.from(stressLevel: currentStressLevel)
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDefaultUnlocksIfNeeded(in: modelContext)
        fetchUnlocks()
        fetchLatestStressLevel()
    }

    func fetchUnlocks() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<CharacterUnlock>(sortBy: [SortDescriptor(\.characterId)])
        unlocks = (try? ctx.fetch(descriptor)) ?? []
        activeCharacterId = unlocks.first(where: { $0.isActive })?.characterId
    }

    func unlockStatus(for characterId: String) -> CharacterUnlock? {
        unlocks.first(where: { $0.characterId == characterId })
    }

    func selectCharacter(_ characterId: String) {
        guard let selected = unlockStatus(for: characterId), selected.isUnlocked else { return }

        for unlock in unlocks {
            unlock.isActive = (unlock.characterId == characterId)
        }
        activeCharacterId = characterId
        try? modelContext?.save()
        characterSync.saveActiveCharacter(characterId: characterId, evolution: selected.evolutionStage)
    }

    /// Fetch the latest stress reading so character mood reflects the user's actual state.
    private func fetchLatestStressLevel() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let latest = try? ctx.fetch(descriptor).first {
            currentStressLevel = latest.stressLevel
        }
    }

    private func seedDefaultUnlocksIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<CharacterUnlock>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for creature in CharacterCreature.allCharacters {
            let isFree = creature.unlockType == .free
            let unlock = CharacterUnlock(
                characterId: creature.id,
                isUnlocked: isFree,
                currentEvolution: .droplet,
                isActive: creature.id == "ripple"
            )
            context.insert(unlock)
        }

        try? context.save()
    }
}

/// Syncs active character selection to the App Group used by Watch complications.
struct CharacterSelectionSync {
    static let shared = CharacterSelectionSync()

    private let suiteName = "group.com.stressmonitor.watch"

    private enum Keys {
        static let activeCharacterId = "activeCharacterId"
        static let activeCharacterEvolution = "activeCharacterEvolution"
    }

    func saveActiveCharacter(characterId: String, evolution: EvolutionStage) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(characterId, forKey: Keys.activeCharacterId)
        defaults.set(evolution.rawValue, forKey: Keys.activeCharacterEvolution)
        defaults.synchronize()

        WidgetCenter.shared.reloadTimelines(ofKind: "CircularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "RectangularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "InlineComplication")
    }
}
