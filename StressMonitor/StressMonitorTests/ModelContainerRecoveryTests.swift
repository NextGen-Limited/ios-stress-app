import SwiftData
import XCTest
@testable import StressMonitor

@Model
final class LegacyShape {
    var legacyValue: String
    init(legacyValue: String = "") {
        self.legacyValue = legacyValue
    }
}

final class ModelContainerRecoveryTests: XCTestCase {

    // MARK: - Technique validation (GREEN from start)

    func testMigrationPlanThrowsOnDivergentStoreThenRecovers() throws {
        let storeURL = Self.makeIsolatedStoreURL()
        defer { Self.cleanupDirectory(for: storeURL) }

        try Self.seedDivergentStore(at: storeURL)

        XCTAssertThrowsError(
            try ModelContainer(
                for: StressMonitorApp.schema,
                migrationPlan: StressMonitorApp.AppMigrationPlan.self,
                configurations: [ModelConfiguration(schema: StressMonitorApp.schema, url: storeURL)]
            )
        )

        Self.removeStoreFiles(at: storeURL)

        let recovered = try ModelContainer(
            for: StressMonitorApp.schema,
            configurations: [ModelConfiguration(schema: StressMonitorApp.schema, url: storeURL)]
        )

        let habits = try recovered.mainContext.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.count, 0)
    }

    // MARK: - App recovery via makeContainer(at:)

    func testMakeContainerRecoversFromDivergentStore() throws {
        let storeURL = Self.makeIsolatedStoreURL()
        defer { Self.cleanupDirectory(for: storeURL) }

        try Self.seedDivergentStore(at: storeURL)

        let container = StressMonitorApp.makeContainer(at: storeURL)

        let habits = try container.mainContext.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.count, 0)

        let unlocks = try container.mainContext.fetch(FetchDescriptor<CharacterUnlock>())
        let freeCharacterIds = Set(CharacterCreature.allCharacters.filter { $0.unlockType == .free }.map(\.id))
        let unlockedIds = Set(unlocks.filter(\.isUnlocked).map(\.characterId))
        XCTAssertTrue(
            freeCharacterIds.isSubset(of: unlockedIds),
            "Free characters should be re-seeded after recovery"
        )
    }

    // MARK: - Happy-path round trip via makeContainer(at:)

    func testMakeContainerHappyPathRoundTrip() throws {
        let storeURL = Self.makeIsolatedStoreURL()
        defer { Self.cleanupDirectory(for: storeURL) }

        let container = StressMonitorApp.makeContainer(at: storeURL)
        let context = container.mainContext

        let measurement = StressMeasurement(timestamp: Date(), stressLevel: 42, hrv: 55)
        context.insert(measurement)

        let testCharacterId = "test-character-\(UUID().uuidString)"
        context.insert(CharacterUnlock(characterId: testCharacterId, isUnlocked: true))

        context.insert(Habit(type: .hydration, currentValue: 1.5))
        try context.save()

        let fetchedMeasurements = try context.fetch(FetchDescriptor<StressMeasurement>())
        XCTAssertTrue(fetchedMeasurements.contains { $0.stressLevel == 42 })

        let fetchedUnlocks = try context.fetch(FetchDescriptor<CharacterUnlock>())
        XCTAssertTrue(fetchedUnlocks.contains { $0.characterId == testCharacterId })

        let fetchedHabits = try context.fetch(FetchDescriptor<Habit>())
        XCTAssertTrue(fetchedHabits.contains { $0.type == .hydration })
    }
}

// MARK: - Store helpers

private extension ModelContainerRecoveryTests {

    static func makeIsolatedStoreURL() -> URL {
        URL.temporaryDirectory
            .appending(path: "t-\(UUID().uuidString)")
            .appending(path: "default.store")
    }

    static func seedDivergentStore(at storeURL: URL) throws {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let container = try ModelContainer(
            for: LegacyShape.self,
            configurations: [ModelConfiguration(url: storeURL)]
        )
        let context = container.mainContext
        context.insert(LegacyShape(legacyValue: "stale"))
        try context.save()
    }

    static func removeStoreFiles(at storeURL: URL) {
        let directory = storeURL.deletingLastPathComponent()
        let baseName = storeURL.lastPathComponent
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: directory.appending(path: baseName + suffix))
        }
    }

    static func cleanupDirectory(for storeURL: URL) {
        removeStoreFiles(at: storeURL)
        try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
    }
}
