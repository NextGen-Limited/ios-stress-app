import SwiftUI
import SwiftData
import CloudKit

/// Shared SwiftData schema for the app.
/// Defines the CloudKit-synced container configuration.
enum StressMonitorSchema {
    /// The shared schema with all model types
    static let schema = Schema([
        StressMeasurement.self,
    ])
    
    /// SwiftData model container configured for CloudKit sync.
    /// Uses the private CloudKit database for user data isolation.
    @MainActor
    static let modelContainer: ModelContainer = {
        do {
            // CloudKit container identifier (must match your Xcode capability)
            let cloudKitContainerID = "iCloud.com.stressmonitor.app"
            
            let config = ModelConfiguration(
                schema: schema,
                cloudKitContainer: .identifier(cloudKitContainerID)
            )
            
            return try ModelContainer(
                for: schema,
                configurations: config
            )
        } catch {
            // Fallback: local-only storage if CloudKit unavailable
            // (e.g., simulator, no iCloud account, development)
            do {
                let fallbackConfig = ModelConfiguration(schema: schema)
                return try ModelContainer(
                    for: schema,
                    configurations: fallbackConfig
                )
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()
}
