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
    static let schema = Schema([
        StressMeasurement.self,
        CharacterUnlock.self,
    ])

    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
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
            MainTabView()
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
