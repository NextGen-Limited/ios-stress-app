import SwiftUI
import SwiftData

@main
struct StressMonitorApp: App {
    static let schema = Schema([
        StressMeasurement.self,
    ])

    static let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
