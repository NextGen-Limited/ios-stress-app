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
        StressMeasurement.self
    ])

    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
}
