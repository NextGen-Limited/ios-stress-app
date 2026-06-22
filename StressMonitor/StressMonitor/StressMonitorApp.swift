import SwiftData
import SwiftUI
#if DEBUG
import os
#endif

#if DEBUG
enum DemoMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo-mode")
}
#endif

@main
struct StressMonitorApp: App {
    // MARK: - Versioned Schema (V1 → V2 adds Habit)
    //
    // SwiftData can silently wipe an existing store on iOS 17.0–17.3 when the
    // model set changes without an explicit migration plan. We declare V1 (the
    // shipping schema through Phase 2) and V2 (adds Habit) plus a lightweight
    // stage so the on-disk store is migrated in place rather than reset.

    enum AppSchemaV1: VersionedSchema {
        static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

        static var models: [any PersistentModel.Type] {
            [StressMeasurement.self, CharacterUnlock.self]
        }

        static func modelProvider() -> Schema {
            Schema(models)
        }
    }

    enum AppSchemaV2: VersionedSchema {
        static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

        static var models: [any PersistentModel.Type] {
            [StressMeasurement.self, CharacterUnlock.self, Habit.self]
        }

        static func modelProvider() -> Schema {
            Schema(models)
        }
    }

    enum AppMigrationPlan: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] {
            [AppSchemaV1.self, AppSchemaV2.self]
        }

        static var stages: [MigrationStage] {
            [MigrationStage.lightweight(fromVersion: AppSchemaV1.self, toVersion: AppSchemaV2.self)]
        }
    }

    static let schema: Schema = AppSchemaV2.modelProvider()

    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            seedDefaultCharacterUnlocks(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        #if DEBUG
        os_signpost(.begin, log: OSLog(subsystem: "com.stressmonitor.app", category: "Launch"), name: "AppInit")
        #endif
        // FontBlaster.blast() removed — fonts now load async in DashboardView
    }

    var body: some Scene {
        WindowGroup {
            OnboardingContainerView()
                .preferredColorScheme(AppearanceManager.shared.colorScheme)
                #if DEBUG
                .onAppear {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - Self.initTimestamp) * 1000
                    os_signpost(.end, log: OSLog(subsystem: "com.stressmonitor.app", category: "Launch"), name: "AppInit", "%.1fms to first view appear", elapsed)
                }
                #endif
        }
        .modelContainer(sharedModelContainer)
    }

    #if DEBUG
    private static let initTimestamp = CFAbsoluteTimeGetCurrent()
    #endif

    private static func seedDefaultCharacterUnlocks(in context: ModelContext) {
        let descriptor = FetchDescriptor<CharacterUnlock>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingIds = Set(existing.map(\.characterId))

        for creature in CharacterCreature.allCharacters where !existingIds.contains(creature.id) {
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

        if let ripple = CharacterCreature.find(by: "ripple") {
            CharacterSelectionSync.shared.saveActiveCharacter(characterId: ripple.id, evolution: .droplet)
        }
    }
}
