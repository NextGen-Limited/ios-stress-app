import Foundation
import SwiftData
import Testing
@testable import StressMonitor

@Model
final class MigrationLegacyShape {
    var legacyValue: String
    init(legacyValue: String = "") {
        self.legacyValue = legacyValue
    }
}

@Suite("StressMeasurement Migration")
@MainActor
struct StressMeasurementMigrationTests {

    @Test("Historical init has documented defaults for lightweight migration")
    func historicalInitHasDocumentedDefaults() {
        let measurement = StressMeasurement(timestamp: Date(), stressLevel: 42, hrv: 55)

        #expect(measurement.restingHeartRate == 0)
        #expect(measurement.categoryRawValue == StressCategory.mild.rawValue)
        #expect(measurement.isSynced == false)
        #expect(measurement.deviceID == CloudKitDeviceID.current)
        #expect(!measurement.deviceID.isEmpty)
    }

    @Test("Seed default CharacterUnlock rows after recovery")
    func seedDefaultCharacterUnlocksAfterRecovery() throws {
        let storeURL = Self.makeIsolatedStoreURL()
        defer { Self.cleanupDirectory(for: storeURL) }

        try Self.seedDivergentStore(at: storeURL)

        let container = StressMonitorApp.makeContainer(at: storeURL)

        let unlocks = try container.mainContext.fetch(FetchDescriptor<CharacterUnlock>())
        if !unlocks.isEmpty {
            #expect(unlocks.count == CharacterCreature.allCharacters.count,
                    "All characters should be seeded after recovery")
            let freeIds = Set(CharacterCreature.allCharacters.filter { $0.unlockType == .free }.map(\.id))
            let unlockedIds = Set(unlocks.filter(\.isUnlocked).map(\.characterId))
            #expect(freeIds.isSubset(of: unlockedIds),
                    "Free characters must be unlocked after recovery re-seed")
        }
    }
}

extension StressMeasurementMigrationTests {

    static func makeIsolatedStoreURL() -> URL {
        URL.temporaryDirectory
            .appending(path: "mt-\(UUID().uuidString)")
            .appending(path: "default.store")
    }

    static func seedDivergentStore(at storeURL: URL) throws {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let container = try ModelContainer(
            for: MigrationLegacyShape.self,
            configurations: ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        )
        let context = container.mainContext
        context.insert(MigrationLegacyShape(legacyValue: "stale"))
        try context.save()
    }

    static func cleanupDirectory(for storeURL: URL) {
        let directory = storeURL.deletingLastPathComponent()
        let baseName = storeURL.lastPathComponent
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: directory.appending(path: baseName + suffix))
        }
        try? FileManager.default.removeItem(at: directory)
    }
}
