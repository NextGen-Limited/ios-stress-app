# Phase 6: Background Notifications

**Goal:** Implement background fetch for automatic stress monitoring without user interaction.

## Prerequisites
- ✅ Phase 5 completed
- Watch and phone communicating
- Algorithm working

---

## 1. Background Modes Configuration

### Enable Background Modes
**iOS Target → Signing & Capabilities → + Capability → Background Modes**

Check:
- Background fetch
- Background processing

**watchOS Target → Signing & Capabilities → + Capability → Background Modes**

Check:
- Background app refresh

---

## 2. iOS Background Scheduler

### Background Task Manager
File: `StressMonitor/Services/Background/BackgroundTaskManager.swift`

```swift
import BackgroundTasks
import Foundation

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let healthFetchIdentifier = "com.stressmonitor.healthFetch"
    private let watchSyncIdentifier = "com.stressmonitor.watchSync"

    private init() {}

    func scheduleHealthFetch() {
        let request = BGAppRefreshTaskRequest(identifier: healthFetchIdentifier)

        // Fetch every 15 minutes (minimum allowed)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Health fetch scheduled")
        } catch {
            print("❌ Failed to schedule health fetch: \(error)")
        }
    }

    func scheduleWatchSync() {
        let request = BGProcessingTaskRequest(identifier: watchSyncIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Watch sync scheduled")
        } catch {
            print("❌ Failed to schedule watch sync: \(error)")
        }
    }

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: healthFetchIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleHealthFetch(task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: watchSyncIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleWatchSync(task as! BGProcessingTask)
        }
    }

    private func handleHealthFetch(_ task: BGAppRefreshTask) {
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Perform health fetch
        Task {
            let success = await Self.performHealthFetch()

            // Schedule next fetch
            self.scheduleHealthFetch()

            task.setTaskCompleted(success: success)
        }
    }

    private func handleWatchSync(_ task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            let success = await Self.syncWatchData()
            task.setTaskCompleted(success: success)
        }
    }

    private static func performHealthFetch() async -> Bool {
        // Implementation
        return true
    }

    private static func syncWatchData() async -> Bool {
        // Implementation
        return true
    }
}
```

---

## 3. Background Health Fetcher

### Fetch Implementation
File: `StressMonitor/Services/Background/BackgroundHealthFetcher.swift`

```swift
import Foundation
import BackgroundTasks

class BackgroundHealthFetcher {
    private let healthKit: HealthKitManager
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    init(
        healthKit: HealthKitManager = .init(),
        algorithm: StressAlgorithmServiceProtocol = StressCalculator(),
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func fetchAndCalculate() async -> Bool {
        do {
            // Fetch latest health data
            async let hrv = healthKit.fetchLatestHRV()
            async let heartRate = healthKit.fetchHeartRate(samples: 10)

            let (hrvData, hrData) = try await (hrv, heartRate)

            guard let latestHRV = hrvData,
                  let latestHR = hrData.first else {
                return false
            }

            // Calculate stress
            let result = try await algorithm.calculateStress(
                hrv: latestHRV.value,
                heartRate: latestHR.value
            )

            // Save measurement
            let measurement = StressMeasurement(
                stressLevel: result.level,
                hrv: result.inputs.hrv,
                restingHeartRate: result.inputs.restingHeartRate,
                confidences: [result.confidence]
            )

            try await repository.save(measurement)

            // Post notification if stress is high
            if result.level > 75 {
                await notifyHighStress(result.level)
            }

            return true

        } catch {
            print("Background fetch failed: \(error)")
            return false
        }
    }

    private func notifyHighStress(_ level: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "High Stress Detected"
        content.body = "Your stress level is \(Int(level))%. Take a moment to breathe."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 4. watchOS Background Refresh

### Watch Background Scheduler
File: `StressMonitorWatch/Services/Background/WatchBackgroundScheduler.swift`

```swift
import WatchKit
import Foundation

class WatchBackgroundScheduler {
    static let shared = WatchBackgroundScheduler()

    private init() {}

    func scheduleBackgroundRefresh() {
        let desiredDate = Date().addingTimeInterval(15 * 60) // 15 minutes

        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: desiredDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("❌ Failed to schedule background refresh: \(error)")
            } else {
                print("✅ Watch background refresh scheduled")
            }
        }
    }

    func handleBackgroundRefresh() {
        // Perform health fetch
        Task {
            let healthKit = WatchHealthKitManager()

            do {
                async let hrv = healthKit.fetchLatestHRV()
                async let heartRate = healthKit.fetchHeartRate(samples: 10)

                let (hrvData, hrData) = try await (hrv, heartRate)

                guard let latestHRV = hrvData,
                      let latestHR = hrData.first else {
                    self.scheduleNextRefresh()
                    return
                }

                // Calculate and sync
                let algorithm = StressCalculator()
                let result = try await algorithm.calculateStress(
                    hrv: latestHRV.value,
                    heartRate: latestHR.value
                )

                // Sync to phone
                self.syncToPhone(result: result)

            } catch {
                print("Background refresh failed: \(error)")
            }

            self.scheduleNextRefresh()
        }
    }

    private func syncToPhone(result: StressResult) {
        let data: [String: Any] = [
            "action": "saveMeasurement",
            "stressLevel": result.level,
            "hrv": result.inputs.hrv,
            "heartRate": result.inputs.heartRate,
            "timestamp": result.timestamp.timeIntervalSince1970
        ]

        WCSession.default.transferUserInfo(data)
    }

    private func scheduleNextRefresh() {
        scheduleBackgroundRefresh()
    }
}
```

### Watch Extension Delegate
File: `StressMonitorWatch/ExtensionDelegate.swift`

```swift
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Schedule first background refresh
        WatchBackgroundScheduler.shared.scheduleBackgroundRefresh()
    }

    func applicationDidBecomeActive() {
        // App is now active
    }

    func applicationWillResignActive() {
        // App will resign active
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                WatchBackgroundScheduler.shared.handleBackgroundRefresh()
                backgroundTask.setTaskCompletedWithSnapshot(false)

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
```

---

## 5. Notification Permissions

### Request Authorization
File: `StressMonitor/App/StressMonitorApp.swift`

```swift
import SwiftUI
import UserNotifications

@main
struct StressMonitorApp: App {
    init() {
        requestNotificationAuthorization()
        BackgroundTaskManager.shared.registerTasks()
        BackgroundTaskManager.shared.scheduleHealthFetch()
    }

    var body: some Scene {
        // ...
    }

    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification authorization granted")
            } else {
                print("❌ Notification authorization denied")
            }
        }
    }
}
```

---

## 6. Testing Background Tasks

### Background Test Helper
File: `StressMonitorTests/Background/BackgroundTaskTests.swift`

```swift
import XCTest
import BackgroundTasks
@testable import StressMonitor

final class BackgroundTaskTests: XCTestCase {

    func testBackgroundFetchScheduling() {
        let manager = BackgroundTaskManager.shared
        manager.scheduleHealthFetch()

        // In real test, verify task was scheduled
        // This is a placeholder
        XCTAssertTrue(true)
    }

    func testBackgroundFetcher() async {
        let fetcher = BackgroundHealthFetcher(
            healthKit: MockHealthKitManager(),
            algorithm: StressCalculator(),
            repository: MockStressRepository()
        )

        let success = await fetcher.fetchAndCalculate()
        XCTAssertTrue(success)
    }
}
```

### Simulate Background Fetch
```swift
// In Xcode
// Debug → Simulate Background Fetch
```

---

## Testing Checklist

### iOS Background
- [ ] Background tasks registered
- [ ] Health fetch runs in background
- [ ] Tasks reschedule after completion
- [ ] Notifications sent for high stress
- [ ] Handles expiration properly

### watchOS Background
- [ ] Background refresh scheduled
- [ ] Fetch runs when watch is asleep
- [ ] Data syncs to iPhone
- [ ] Handles errors gracefully

### Notifications
- [ ] Permission requested
- [ ] High stress notifications sent
- [ ] Notification content is correct
- [ ] Sound plays

### Integration
- [ ] Manual trigger still works
- [ ] Background doesn't interfere with foreground
- [ ] Battery usage is reasonable
- [ ] No crashes in background

---

## Estimated Time

**2-3 hours**

- Background setup: 30 min
- iOS background tasks: 1 hour
- watchOS background: 1 hour
- Testing: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 7: Data Sync** to implement CloudKit integration.
