import SwiftData
import Testing
@testable import StressMonitor

@MainActor
struct CharacterEntitlementSyncTests {

    private func makeSeededContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext
        for creature in CharacterCreature.allCharacters {
            ctx.insert(CharacterUnlock(
                characterId: creature.id,
                isUnlocked: creature.unlockType == .free,
                currentEvolution: .droplet,
                isActive: creature.id == "ripple"
            ))
        }
        try ctx.save()
        return ctx
    }

    private func unlock(in ctx: ModelContext, for id: String) -> CharacterUnlock {
        try! ctx.fetch(FetchDescriptor<CharacterUnlock>())
            .first(where: { $0.characterId == id })!
    }

    @Test("Subscribing unlocks premium characters, leaves others untouched")
    func subscribingUnlocksPremiumOnly() throws {
        let ctx = try makeSeededContext()
        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: true, in: ctx)

        #expect(unlock(in: ctx, for: "ember").isUnlocked)
        #expect(unlock(in: ctx, for: "zephyr").isUnlocked)
        #expect(unlock(in: ctx, for: "lumi").isUnlocked == false)
        #expect(unlock(in: ctx, for: "ripple").isUnlocked)
        #expect(unlock(in: ctx, for: "blossom").isUnlocked)
    }

    @Test("Lapsing keeps premium characters unlocked (one-time-permanent) and falls back active selection to Ripple")
    func lapsingKeepsPremiumUnlockedAndResetsActive() throws {
        let ctx = try makeSeededContext()
        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: true, in: ctx)

        let ember = unlock(in: ctx, for: "ember")
        ember.isActive = true
        unlock(in: ctx, for: "ripple").isActive = false
        try ctx.save()

        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: false, in: ctx)

        #expect(unlock(in: ctx, for: "ember").isUnlocked)
        #expect(unlock(in: ctx, for: "zephyr").isUnlocked)
        #expect(unlock(in: ctx, for: "ember").isActive == false)
        #expect(unlock(in: ctx, for: "ripple").isActive)
        #expect(unlock(in: ctx, for: "ripple").isUnlocked)
    }

    @Test("Streak-gated Lumi survives a subscription lapse")
    func lumiStreakUnlockSurvivesLapse() throws {
        let ctx = try makeSeededContext()
        unlock(in: ctx, for: "lumi").isUnlocked = true
        try ctx.save()

        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: false, in: ctx)

        #expect(unlock(in: ctx, for: "lumi").isUnlocked)
    }
}
