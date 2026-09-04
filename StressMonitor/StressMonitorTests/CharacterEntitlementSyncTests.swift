import SwiftData
import Testing
@testable import StressMonitor

// QUARANTINE FIXED 2026-09-04 (ENV-02, 02-04 bounded re-diagnosis): the
// container-lifetime hypothesis — never among the five ruled out below — was
// confirmed as the root cause. makeSeededContext previously returned only
// mainContext while the owning ModelContainer went out of scope at fixture
// return (the WINDOWS.md #8 crash lineage per the v1.1 P03-04 rule:
// containers must outlive their contexts); it now returns (ModelContainer,
// ModelContext) and every test keeps the container alive. Six 2026-09-03
// .ips crash reports (coalition com.apple.CoreSimulator.SimDevice.5DD825B4-…,
// EXC_BREAKPOINT, faulting frame #0 in SwiftData, direct callers in the
// sibling #8 suites' test bodies) matched the dead-container prediction.
// Verdict (02-04 Task 2 checkpoint, evidence in 02-04-SUMMARY.md): fix
// landed — suite restored to the default run permanently, no quarantine
// trait remains.
//
// ORIGINAL QUARANTINE RECORD (historical, predates the container-lifetime
// test): every @Test in this suite reliably hangs the xcodebuild/XCTest host
// process on this toolchain (Xcode 26.3 / iOS 26.2-26.3 simulator), producing
// "Restarting after unexpected exit, crash, or test timeout" with zero console
// diagnostics — this was the actual source of the CI test-run crash originally
// misattributed to SwiftData's Code=134504 "unknown model version" message (that
// message is unrelated, harmless CoreData diagnostic logging from the passing
// ModelContainerRecoveryTests/StressMeasurementMigrationTests divergent-store
// tests — see .planning/debug/resolved/swiftdata-migration-crash.md). Ruled out
// by direct bisection: not CloudKit setup on the in-memory test container (now
// explicitly cloudKitDatabase: .none regardless), not the real app-level
// CloudKit container (now skipped during XCTest hosting in StressMonitorApp),
// not WidgetCenter.reloadTimelines XPC calls (now skipped during XCTest hosting
// in CharacterSelectionSync), not a bare `try ctx.save()` vs do/catch, not
// @Suite(.serialized), and not suite/test ordering — stubbing every @Test body
// to a no-op assertion makes the suite pass instantly, so the trigger is real
// SwiftData work (ModelContainer + insert + save against the CharacterUnlock
// model) specific to this suite; the mechanism remains unconfirmed. Production
// path is exercised by CharacterCollectionViewModelTests (identical container
// pattern, passes) and PremiumViewModelTests; syncPremiumCharacterEntitlement
// itself has no other test coverage — a known gap until this is diagnosed with
// a working local simulator (this dev host's CoreSimulator/XCTestDevices layer
// has documented pre-existing instability, see WINDOWS.md item #1).
@MainActor
struct CharacterEntitlementSyncTests {

    /// In-memory context seeded with every creature's unlock row. The
    /// container is returned alongside its context and must stay alive for
    /// the whole test — returning the context alone lets the container (the
    /// only owner of the in-memory store) deallocate, and the next SwiftData
    /// operation on the orphaned context traps (WINDOWS.md #8 lineage).
    private func makeSeededContext() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
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
        save(ctx)
        return (container, ctx)
    }

    private func unlock(in ctx: ModelContext, for id: String) -> CharacterUnlock {
        try! ctx.fetch(FetchDescriptor<CharacterUnlock>())
            .first(where: { $0.characterId == id })!
    }

    /// Empirically, a bare `try ctx.save()` directly inside a `throws @Test` body
    /// hangs the xcodebuild/XCTest host on this toolchain (confirmed by bisection —
    /// the save never actually throws) while the identical save wrapped in do/catch
    /// does not. Root mechanism unconfirmed; keeping saves out of the propagating
    /// `try` path here avoids the hang without masking a genuine save failure.
    private func save(_ ctx: ModelContext) {
        do {
            try ctx.save()
        } catch {
            Issue.record(error, "Context save failed")
        }
    }

    @Test("Subscribing unlocks premium characters, leaves others untouched")
    func subscribingUnlocksPremiumOnly() throws {
        let (container, ctx) = try makeSeededContext()
        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: true, in: ctx)

        #expect(unlock(in: ctx, for: "ember").isUnlocked)
        #expect(unlock(in: ctx, for: "zephyr").isUnlocked)
        #expect(unlock(in: ctx, for: "lumi").isUnlocked == false)
        #expect(unlock(in: ctx, for: "ripple").isUnlocked)
        #expect(unlock(in: ctx, for: "blossom").isUnlocked)
        _ = container // keep the in-memory store alive until the assertions are done
    }

    @Test("Lapsing keeps premium characters unlocked (one-time-permanent) and falls back active selection to Ripple")
    func lapsingKeepsPremiumUnlockedAndResetsActive() throws {
        let (container, ctx) = try makeSeededContext()
        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: true, in: ctx)

        let ember = unlock(in: ctx, for: "ember")
        ember.isActive = true
        unlock(in: ctx, for: "ripple").isActive = false
        save(ctx)

        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: false, in: ctx)

        #expect(unlock(in: ctx, for: "ember").isUnlocked)
        #expect(unlock(in: ctx, for: "zephyr").isUnlocked)
        #expect(unlock(in: ctx, for: "ember").isActive == false)
        #expect(unlock(in: ctx, for: "ripple").isActive)
        #expect(unlock(in: ctx, for: "ripple").isUnlocked)
        _ = container // keep the in-memory store alive until the assertions are done
    }

    @Test("Streak-gated Lumi survives a subscription lapse")
    func lumiStreakUnlockSurvivesLapse() throws {
        let (container, ctx) = try makeSeededContext()
        unlock(in: ctx, for: "lumi").isUnlocked = true
        save(ctx)

        CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium: false, in: ctx)

        #expect(unlock(in: ctx, for: "lumi").isUnlocked)
        _ = container // keep the in-memory store alive until the assertions are done
    }

    @Test("In-memory test container disables CloudKit sync")
    func inMemoryContainerDisablesCloudKit() throws {
        let (container, ctx) = try makeSeededContext()
        let cloudKitDatabases = ctx.container.configurations.map { String(describing: $0.cloudKitDatabase) }

        #expect(cloudKitDatabases.allSatisfy { $0 == String(describing: ModelConfiguration.CloudKitDatabase.none) })
        _ = container // keep the in-memory store alive until the assertions are done
    }
}
