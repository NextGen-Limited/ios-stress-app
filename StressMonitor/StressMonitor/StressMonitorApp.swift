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
    // Central navigation + paywall state. Owned here so they are available to
    // every scene, tab, sheet, and the root full-screen paywall cover.
    @State private var appRouter = AppRouter()
    @State private var paywall = PaywallController()
    // Owned once for the app's process lifetime so the Transaction.updates
    // listener started in its init runs the whole time, not just while the
    // paywall happens to be on screen. See StoreKitServiceEnvironment.swift.
    @State private var storeKitService: StoreKitServiceProtocol = Self.makeStoreKitService()
    @Environment(\.scenePhase) private var scenePhase
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
            // The `PaywallController` is owned here (true singleton) and
            // injected into the tree. The `.fullScreenCover` that consumes it
            // lives on `MainTabView`, so the paywall renders above the entire
            // TabView (all tabs + navigation stacks).
            OnboardingContainerView()
                .environment(appRouter)
                .environment(paywall)
                .environment(\.storeKitService, storeKitService)
                .preferredColorScheme(AppearanceManager.shared.colorScheme)
                #if DEBUG
                .onAppear {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - Self.initTimestamp) * 1000
                    os_signpost(.end, log: OSLog(subsystem: "com.stressmonitor.app", category: "Launch"), name: "AppInit", "%.1fms to first view appear", elapsed)
                }
                #endif
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            // Self-correct entitlement state on every foreground, not only
            // when Transaction.updates happens to deliver something while
            // the app is already running.
            guard newPhase == .active else { return }
            Task { @MainActor in
                await storeKitService.refreshEntitlements()
                CharacterCollectionViewModel.syncPremiumCharacterEntitlement(
                    isPremium: PremiumState.shared.isPremiumUser,
                    in: sharedModelContainer.mainContext
                )
            }
        }
    }

    // MARK: - StoreKit factory (DEBUG vs Release)

    #if DEBUG
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        MockStoreKitService(premiumState: .shared)
    }
    #else
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        StoreKitService(premiumState: .shared)
    }
    #endif

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
