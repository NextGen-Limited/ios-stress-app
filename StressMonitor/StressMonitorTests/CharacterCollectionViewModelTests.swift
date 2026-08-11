import SwiftData
import Testing
@testable import StressMonitor

@MainActor
struct CharacterCollectionViewModelTests {
    @Test("Fetch unlocks returns persisted data")
    func fetchUnlocks() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext

        let ripple = CharacterUnlock(characterId: "ripple", isUnlocked: true, isActive: true)
        ctx.insert(ripple)

        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)

        #expect(vm.unlocks.count == 1)
        #expect(vm.activeCharacterId == "ripple")
    }

    @Test("Select character updates active state")
    func selectCharacter() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext

        let ripple = CharacterUnlock(characterId: "ripple", isUnlocked: true, isActive: true)
        let blossom = CharacterUnlock(characterId: "blossom", isUnlocked: true)
        ctx.insert(ripple)
        ctx.insert(blossom)

        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)
        vm.selectCharacter("blossom")

        #expect(vm.activeCharacterId == "blossom")
        #expect(ripple.isActive == false)
        #expect(blossom.isActive == true)
    }

    @Test("Unlock status returns nil for unknown character")
    func unknownCharacterReturnsNil() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext

        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)

        #expect(vm.unlockStatus(for: "nonexistent") == nil)
    }

    @Test("In-memory test container disables CloudKit sync")
    func inMemoryContainerDisablesCloudKit() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let cloudKitDatabases = container.configurations.map { String(describing: $0.cloudKitDatabase) }

        #expect(cloudKitDatabases.allSatisfy { $0 == String(describing: ModelConfiguration.CloudKitDatabase.none) })
    }
}
