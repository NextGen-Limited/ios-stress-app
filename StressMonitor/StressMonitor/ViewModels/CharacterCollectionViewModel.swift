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
        var descriptor = FetchDescriptor<StressMeasurement>(
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

    /// Reconciles premium-character unlocks with live subscription status.
    /// Premium unlocks are one-time-permanent: subscribing grants them, but a
    /// subscription lapse does NOT re-lock them. Active selection of a premium
    /// character falls back to Ripple on lapse so the user lands on a free char.
    @MainActor
    static func syncPremiumCharacterEntitlement(isPremium: Bool, in context: ModelContext) {
        let descriptor = FetchDescriptor<CharacterUnlock>()
        let unlocks = (try? context.fetch(descriptor)) ?? []

        let premiumIds = Set(CharacterCreature.allCharacters.filter { $0.unlockType == .premium }.map(\.id))

        var activeReLocked = false
        for unlock in unlocks where premiumIds.contains(unlock.characterId) {
            if isPremium {
                unlock.isUnlocked = true
            }
            if !isPremium && unlock.isActive {
                unlock.isActive = false
                activeReLocked = true
            }
        }

        if activeReLocked, let ripple = unlocks.first(where: { $0.characterId == "ripple" }) {
            ripple.isActive = true
            CharacterSelectionSync.shared.saveActiveCharacter(characterId: ripple.characterId, evolution: ripple.evolutionStage)
        }

        try? context.save()
    }
}

/// Syncs active character selection to the App Group used by Watch complications.
struct CharacterSelectionSync {
    static let shared = CharacterSelectionSync()

    private let suiteName = "group.stress.ai.com"

    private enum Keys {
        static let activeCharacterId = "activeCharacterId"
        static let activeCharacterEvolution = "activeCharacterEvolution"
    }

    /// XCTest sets this on every test-host launch. WidgetCenter's reload call is an
    /// XPC round-trip to a system daemon that has nothing to reload in a unit-test
    /// host (no widget extension is actually installed there) and can back up badly
    /// when called repeatedly across a test run, so it's skipped under XCTest.
    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func saveActiveCharacter(characterId: String, evolution: EvolutionStage) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(characterId, forKey: Keys.activeCharacterId)
        defaults.set(evolution.rawValue, forKey: Keys.activeCharacterEvolution)
        defaults.synchronize()

        guard !isRunningUnitTests else { return }

        WidgetCenter.shared.reloadTimelines(ofKind: "CircularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "RectangularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "InlineComplication")
    }
}
