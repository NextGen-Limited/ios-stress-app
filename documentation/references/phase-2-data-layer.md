# Phase 2: Data Layer

**Goal:** Implement HealthKit integration for fetching HRV/heart rate data and SwiftData for local persistence.

## Prerequisites
- ✅ Phase 1 completed
- HealthKit capability enabled
- SwiftData models defined

---

## 1. HealthKit Service Implementation

### Create HealthKit Manager
File: `StressMonitor/Services/HealthKit/HealthKitManager.swift`

```swift
import HealthKit
import Foundation

@Observable
class HealthKitManager: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    // Define data types
    private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

    func requestAuthorization() async throws {
        let typesToRead: Set = [hrvType, heartRateType]

        try await healthStore.requestAuthorization(toShare: nil, read: typesToRead)
    }

    func fetchLatestHRV() async throws -> HRVMeasurement {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            // Handle response
        }

        healthStore.execute(query)
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        // Implementation
    }
}
```

---

## 2. SwiftData Models

### Stress Measurement Model
File: `StressMonitor/Models/StressMeasurement.swift`

```swift
import SwiftData
import Foundation

@Model
final class StressMeasurement {
    var timestamp: Date
    var stressLevel: Double
    var hrv: Double
    var restingHeartRate: Double
    var confidences: [Double]
    var isSynced: Bool

    init(stressLevel: Double, hrv: Double, restingHeartRate: Double, confidences: [Double]) {
        self.timestamp = Date()
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.confidences = confidences
        self.isSynced = false
    }
}
```

### Configuration
File: `StressMonitor/App/StressMonitorApp.swift`

```swift
import SwiftData
import SwiftUI

@main
struct StressMonitorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([StressMeasurement.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

---

## 3. Repository Pattern

### Repository Protocol
File: `StressMonitor/Services/Repository/StressRepositoryProtocol.swift`

```swift
import Foundation

protocol StressRepositoryProtocol {
    func save(_ measurement: StressMeasurement) async throws
    func fetchLatest(limit: Int) async throws -> [StressMeasurement]
    func fetch(for date: Date) async throws -> [StressMeasurement]
}
```

### Implementation
File: `StressMonitor/Services/Repository/StressRepository.swift`

```swift
import SwiftData
import Foundation

@Observable
class StressRepository: StressRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ measurement: StressMeasurement) async throws {
        modelContext.insert(measurement)
        try modelContext.save()
    }

    func fetchLatest(limit: Int) async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }
}
```

---

## 4. Health Data Background Fetching

### Background Scheduler
File: `StressMonitor/Services/Background/HealthBackgroundScheduler.swift`

```swift
import BackgroundTasks
import Foundation

class HealthBackgroundScheduler {
    static let shared = HealthBackgroundScheduler()
    private let taskIdentifier = "com.stressmonitor.health-fetch"

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }

    func handleBackgroundTask(task: BGAppRefreshTask) {
        // Fetch health data in background
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Schedule next fetch
        schedule()
    }
}
```

---

## 5. watchOS Data Sync

### WatchConnectivity Session
File: `StressMonitorWatch/Services/Connectivity/WatchConnectivityManager.swift`

```swift
import WatchConnectivity
import Foundation

@Observable
class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    var isReachable = false
    var hasDataSync = false

    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func syncData(_ data: [String: Any]) {
        WCSession.default.transferUserInfo(data)
    }

    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        isReachable = state == .activated
    }
}
```

---

## Testing Checklist

### HealthKit
- [ ] Authorization request prompts correctly
- [ ] Can fetch HRV samples
- [ ] Can fetch heart rate samples
- [ ] Handles permission denial gracefully
- [ ] Background fetch works

### SwiftData
- [ ] Can save stress measurements
- [ ] Can retrieve measurements
- [ ] Queries work correctly
- [ ] Data persists across app launches

### Repository
- [ ] Save operations work
- [ ] Fetch operations return correct data
- [ ] Error handling works properly

### watchOS Sync
- [ ] Watch can send data to phone
- [ ] Phone receives watch data
- [ ] Handles connectivity failures

---

## Estimated Time

**4-5 hours**

- HealthKit integration: 2 hours
- SwiftData setup: 1 hour
- Repository pattern: 1 hour
- Background fetching: 1 hour

---

## Next Steps

Once this phase is complete, proceed to **Phase 3: Core Algorithm** to implement the stress calculation logic.
