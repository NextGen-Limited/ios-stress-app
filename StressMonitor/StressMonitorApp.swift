import SwiftUI
import SwiftData

@main
struct StressMonitorApp: App {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(cloudKitManager)
        }
        // SwiftData container with CloudKit sync
        .modelContainer(StressMonitorSchema.modelContainer)
    }
}
