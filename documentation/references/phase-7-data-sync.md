# Phase 7: Data Sync

**Goal:** Implement CloudKit for iCloud sync and ensure data consistency across devices.

## Prerequisites
- ✅ Phase 6 completed
- Background tasks working
- iCloud account available

---

## 1. CloudKit Setup

### Enable CloudKit Capability
**iOS Target → Signing & Capabilities → + Capability → iCloud**

Check:
- CloudKit

**Create or select CloudKit container:**
- `iCloud.com.yourcompany.StressMonitor`

---

## 2. CloudKit Models

### CloudKit Record Types
**Define in CloudKit Dashboard:**

#### StressMeasurement Record
- Fields:
  - `timestamp`: Date/Time (indexed)
  - `stressLevel`: Double
  - `hrv`: Double
  - `restingHeartRate`: Double
  - `confidences`: List
  - `deviceID`: String (indexed)
  - `isDeleted`: Bool

---

## 3. CloudKit Manager

### CloudKit Service
File: `StressMonitor/Services/CloudKit/CloudKitManager.swift`

```swift
import CloudKit
import Foundation

@Observable
class CloudKitManager {
    static let shared = CloudKitManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let subscriptionID = "stressMeasurementsSubscription"

    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?

    private init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Sync Status

    enum SyncStatus {
        case idle
        case syncing
        case error(Error)
        case success
    }

    // MARK: - Save Measurement

    func saveMeasurement(_ measurement: StressMeasurement) async throws {
        syncStatus = .syncing

        let record = CKRecord(recordType: "StressMeasurement")
        record["timestamp"] = measurement.timestamp
        record["stressLevel"] = measurement.stressLevel
        record["hrv"] = measurement.hrv
        record["restingHeartRate"] = measurement.restingHeartRate
        record["confidences"] = measurement.confidences
        record["deviceID"] = UIDevice.current.identifierForVendor?.uuidString
        record["isDeleted"] = false

        try await privateDatabase.save(record)

        syncStatus = .success
        lastSyncDate = Date()
    }

    // MARK: - Fetch Measurements

    func fetchMeasurements(since date: Date? = nil) async throws -> [StressMeasurement] {
        var predicate: NSPredicate

        if let date = date {
            predicate = NSPredicate(format: "timestamp >= %@", date as NSDate)
        } else {
            predicate = NSPredicate(value: true)
        }

        let query = CKQuery(recordType: "StressMeasurement", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let result = try await privateDatabase.records(matching: query)

        return result.matchResults.compactMap { _, recordResult in
            guard case .success(let record) = recordResult else {
                return nil
            }
            return recordToMeasurement(record)
        }
    }

    // MARK: - Delete Measurement

    func deleteMeasurement(_ measurement: StressMeasurement) async throws {
        // Soft delete
        guard let recordID = measurement.cloudKitRecordID else {
            return
        }

        let record = try await privateDatabase.record(for: recordID)
        record["isDeleted"] = true

        try await privateDatabase.save(record)
    }

    // MARK: - Sync

    func sync() async throws {
        syncStatus = .syncing
        defer {
            if case .idle = syncStatus {
                // Keep syncing if still idle
            }
        }

        // Fetch remote changes
        let remoteMeasurements = try await fetchMeasurements(since: lastSyncDate)

        // Merge with local data
        for measurement in remoteMeasurements {
            // Check if local exists
            // If not, save locally
            // If yes, compare timestamps and keep newer
        }

        // Upload local changes
        let localMeasurements = try await fetchLocalUnsyncedMeasurements()
        for measurement in localMeasurements {
            try await saveMeasurement(measurement)
        }

        syncStatus = .success
        lastSyncDate = Date()
    }

    // MARK: - Subscriptions

    func setupSubscription() async throws {
        let subscription = CKQuerySubscription(
            recordType: "StressMeasurement",
            predicate: NSPredicate(format: "isDeleted == 0"),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        try await privateDatabase.save(subscription)
    }

    // MARK: - Helpers

    private func recordToMeasurement(_ record: CKRecord) -> StressMeasurement {
        return StressMeasurement(
            stressLevel: record["stressLevel"] as! Double,
            hrv: record["hrv"] as! Double,
            restingHeartRate: record["restingHeartRate"] as! Double,
            confidences: record["confidences"] as! [Double]
        )
    }

    private func fetchLocalUnsyncedMeasurements() async throws -> [StressMeasurement] {
        // Fetch from SwiftData where isSynced == false
        return []
    }
}

extension StressMeasurement {
    var cloudKitRecordID: CKRecord.ID? {
        // Store record ID when synced
        return nil
    }
}
```

---

## 4. Sync Manager

### Orchestrate Sync
File: `StressMonitor/Services/Sync/SyncManager.swift`

```swift
import Foundation

@Observable
class SyncManager {
    static let shared = SyncManager()

    private let cloudKit: CloudKitManager
    private let repository: StressRepositoryProtocol

    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: Error?

    init(cloudKit: CloudKitManager = .shared, repository: StressRepositoryProtocol) {
        self.cloudKit = cloudKit
        self.repository = repository
    }

    func sync() async {
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch local unsynced measurements
            let localUnsynced = try await repository.fetchUnsynced()

            // Upload to CloudKit
            for measurement in localUnsynced {
                try await cloudKit.saveMeasurement(measurement)

                // Mark as synced
                measurement.isSynced = true
                try await repository.save(measurement)
            }

            // Fetch remote changes
            let remoteMeasurements = try await cloudKit.fetchMeasurements(since: lastSyncDate)

            // Merge remote data
            for measurement in remoteMeasurements {
                try await repository.save(measurement)
            }

            lastSyncDate = Date()
            syncError = nil

        } catch {
            syncError = error
        }
    }

    func scheduleSync() {
        // Schedule periodic sync
        // Can use background tasks or timer
    }
}
```

---

## 5. Conflict Resolution

### Merge Strategy
File: `StressMonitor/Services/Sync/ConflictResolver.swift`

```swift
import Foundation

class ConflictResolver {

    enum ResolutionStrategy {
        case timestamp // Keep newer
        case server // Always trust server
        case client // Always trust client
        case highestStress // Keep measurement with highest stress
    }

    static func resolve(
        local: StressMeasurement,
        remote: StressMeasurement,
        strategy: ResolutionStrategy = .timestamp
    ) -> StressMeasurement {
        switch strategy {
        case .timestamp:
            return local.timestamp > remote.timestamp ? local : remote

        case .server:
            return remote

        case .client:
            return local

        case .highestStress:
            return local.stressLevel > remote.stressLevel ? local : remote
        }
    }
}
```

---

## 6. Watch-Phone CloudKit Sync

### Watch CloudKit Sharing
File: `StressMonitorWatch/Services/CloudKit/WatchCloudKitManager.swift`

```swift
import CloudKit
import Foundation

@Observable
class WatchCloudKitManager {
    static let shared = WatchCloudKitManager()

    private let container: CKContainer
    private let sharedDatabase: CKDatabase

    var syncStatus: CloudKitManager.SyncStatus = .idle

    private init() {
        self.container = CKContainer.default()
        self.sharedDatabase = container.sharedCloudDatabase
    }

    func saveMeasurement(_ measurement: StressMeasurement) async throws {
        syncStatus = .syncing

        let record = CKRecord(recordType: "StressMeasurement")
        record["timestamp"] = measurement.timestamp
        record["stressLevel"] = measurement.stressLevel
        record["hrv"] = measurement.hrv
        record["restingHeartRate"] = measurement.restingHeartRate
        record["confidences"] = measurement.confidences
        record["deviceID"] = "watch"
        record["isDeleted"] = false

        try await sharedDatabase.save(record)

        syncStatus = .success
    }

    func fetchLatestMeasurements(limit: Int = 10) async throws -> [StressMeasurement] {
        let predicate = NSPredicate(format: "isDeleted == 0")
        let query = CKQuery(recordType: "StressMeasurement", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let result = try await sharedDatabase.records(matching: query)
        result.results.limit = limit

        return result.matchResults.compactMap { _, recordResult in
            guard case .success(let record) = recordResult else {
                return nil
            }
            return recordToMeasurement(record)
        }
    }

    private func recordToMeasurement(_ record: CKRecord) -> StressMeasurement {
        return StressMeasurement(
            stressLevel: record["stressLevel"] as! Double,
            hrv: record["hrv"] as! Double,
            restingHeartRate: record["restingHeartRate"] as! Double,
            confidences: record["confidences"] as! [Double]
        )
    }
}
```

---

## 7. Sync UI

### Sync Status Indicator
File: `StressMonitor/Views/Components/SyncStatusIndicator.swift`

```swift
import SwiftUI

struct SyncStatusIndicator: View {
    @State private var syncManager = SyncManager.shared

    var body: some View {
        HStack(spacing: 6) {
            if syncManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: syncIcon)
                    .foregroundStyle(syncColor)
            }

            if let error = syncManager.syncError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
    }

    private var syncIcon: String {
        if let lastSync = syncManager.lastSyncDate {
            return Date().timeIntervalSince(lastSync) < 300 ? "checkmark.icloud" : "icloud"
        }
        return "icloud"
    }

    private var syncColor: Color {
        if let lastSync = syncManager.lastSyncDate {
            return Date().timeIntervalSince(lastSync) < 300 ? .green : .gray
        }
        return .gray
    }
}
```

---

## Testing Checklist

### CloudKit Setup
- [ ] Container configured
- [ ] Record types defined
- [ ] Schema deployed
- [ ] Subscription working

### Sync Functionality
- [ ] Can save to CloudKit
- [ ] Can fetch from CloudKit
- [ ] Local changes sync up
- [ ] Remote changes sync down
- [ ] Conflict resolution works
- [ ] Handles errors gracefully

### Cross-Device
- [ ] iPhone to iPhone sync
- [ ] Watch to iPhone sync
- [ ] iPhone to Watch sync
- [ ] Data consistency maintained

### UI
- [ ] Sync status shows
- [ ] Last sync time displays
- [ ] Errors shown to user
- [ ] Manual sync button works

---

## Estimated Time

**3-4 hours**

- CloudKit setup: 30 min
- CloudKit Manager: 1.5 hours
- Sync Manager: 1 hour
- Conflict resolution: 30 min
- Testing: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 8: Testing & Polish** for comprehensive testing and refinement.
