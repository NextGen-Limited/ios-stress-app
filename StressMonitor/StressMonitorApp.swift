import SwiftUI
import SwiftData

@main
struct StressMonitorApp: App {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var readinessService = MorningReadinessService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(cloudKitManager)
                .environmentObject(readinessService)
        }
        // SwiftData container with CloudKit sync
        .modelContainer(StressMonitorSchema.modelContainer)
    }
}
