# Implementation Plan: [P1] Write Unit Tests — StressRepository & CloudKit Sync

**Task ID:** t_c602a41b  
**Branch:** `test/repository-cloudkit-sync`  
**Date:** 2025-06-10  
**Priority:** P1  

---

## 1. Objective

Write comprehensive unit tests for:
1. **StressRepository** — CRUD operations, baseline management, CloudKit sync orchestration
2. **CloudKit Sync Pipeline** — `CloudKitManager`, `CloudKitSyncEngine`, `ConflictResolver`, `SyncManager`
3. **Fix O(n) full-table scan** in `mergeRemoteMeasurement()`

---

## 2. Codebase Analysis

### 2.1 Files Under Test

| File | Role |
|------|------|
| `StressMonitor/Services/Repository/StressRepository.swift` | Main data persistence layer (491 lines). @MainActor, uses SwiftData `ModelContext`. Delegates to `CloudKitServiceProtocol?` for sync. |
| `StressMonitor/Services/CloudKit/CloudKitManager.swift` | iOS CloudKit client. @MainActor, @Observable. Uses `CKContainer.privateCloudDatabase`. |
| `StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift` | Batch upload/download with retry. @MainActor. Chunked batches (default 10). |
| `StressMonitor/Services/Sync/SyncManager.swift` | Orchestrator: account check → upload → download → conflict resolve. @MainActor, @Observable. |
| `StressMonitor/Services/Sync/ConflictResolver.swift` | Four strategies: timestamp, server, client, devicePriority. Batch O(n) via dict lookup. |
| `StressMonitor/Services/Protocols/CloudKitServiceProtocol.swift` | Protocol + SyncStatus/NetworkReason/CloudKitAccountStatus/ResolutionStrategy/MergeDecision enums. |
| `StressMonitor/Services/Protocols/StressRepositoryProtocol.swift` | Repository protocol (12 methods). |
| `StressMonitor/Services/CloudKit/CloudKitSchema.swift` | `CloudKitRecordType`, `CloudKitStressMeasurement`, `CloudKitPersonalBaseline`. |
| `StressMonitor/Models/StressMeasurement.swift` | SwiftData @Model with CloudKit sync fields (isSynced, cloudKitRecordName, deviceID, cloudKitModTime). |
| `StressMonitor/Services/Algorithm/BaselineCalculator.swift` | Standalone Sendable class. HRV outlier filtering, baseline calculation. |
| `StressMonitor/Services/MockServices.swift` | Existing `MockStressRepository`, `MockHealthKitService`, `MockStressAlgorithmService`. |

### 2.2 Key Architecture Observations

- **StressRepository** is `@MainActor`; all methods are async.
- `StressRepository.init` takes `ModelContext`, optional `BaselineCalculator`, optional `CloudKitServiceProtocol`.
- **No CloudKitServiceProtocol mock exists yet** — we must create `MockCloudKitService`.
- `mergeRemoteMeasurement()` (line 380–416) fetches **ALL** measurements via `FetchDescriptor<StressMeasurement>()` with no predicate, then filters in Swift — **O(n) scan**. This is the performance bug to fix.
- `CloudKitManager` and `SyncManager` use `@Observable` (iOS 17 Observation framework).
- `ConflictResolver` is not actor-isolated; it's a plain class — easy to unit test directly.
- Tests must run in an **in-memory SwiftData container** (`ModelConfiguration(isStoredInMemoryOnly: true)`).

### 2.3 Existing Tests (StressMonitorTests/)

- `StressHistoryTests.swift` — view-layer model tests
- `StressReadingTests.swift`, `StressPredictorTests.swift` — algorithm tests
- `MorningReadinessServiceTests.swift`, `HRVAnalyzerTests.swift` — service tests

**No repository or CloudKit sync tests exist.**

---

## 3. Bug Fix: O(n) Scan in mergeRemoteMeasurement()

### Problem
Lines 380–416 of `StressRepository.swift`:
```swift
private func mergeRemoteMeasurement(_ remote: StressMeasurement) async {
    let descriptor = FetchDescriptor<StressMeasurement>()
    // Fetches ALL records, then filters in-memory:
    let allMeasurements = try modelContext.fetch(descriptor)
    let existing = allMeasurements.filter {
        $0.timestamp == remote.timestamp && $0.deviceID == remote.deviceID
    }
    ...
}
```
This loads the entire table into memory for every remote measurement merged. With 10,000+ measurements, merging 100 remote records causes 1,000,000+ comparisons.

### Fix
Replace the full-table scan with a **predicate-based fetch** (O(1) at the SQLite level):

```swift
private func mergeRemoteMeasurement(_ remote: StressMeasurement) async {
    let descriptor = FetchDescriptor<StressMeasurement>(
        predicate: #Predicate<StressMeasurement> {
            $0.timestamp == remote.timestamp && $0.deviceID == remote.deviceID
        }
    )

    do {
        let existing = try modelContext.fetch(descriptor)
        // ... rest of conflict resolution unchanged
    } catch {
        onSyncError?(error)
    }
}
```

**Caveat:** SwiftData `#Predicate` with `Date` equality may not match due to floating-point precision. If SwiftData doesn't support `==` on Date fields well, fall back to a narrow window:
```swift
let epsilon: TimeInterval = 1.0
let from = remote.timestamp.addingTimeInterval(-epsilon)
let to = remote.timestamp.addingTimeInterval(epsilon)
let descriptor = FetchDescriptor<StressMeasurement>(
    predicate: #Predicate<StressMeasurement> {
        $0.timestamp >= from && $0.timestamp <= to && $0.deviceID == remote.deviceID
    }
)
```

Then filter the small result set in-memory for exact match.

### Test Coverage for Fix
- `testMergeRemoteMeasurement_usesPredicateFetch_notFullScan` — verify no full-table scan (mock modelContext or use spy)
- `testMergeRemotePerformance_largeDataset` — performance test with 10k local + 100 remote measurements

---

## 4. Test Infrastructure

### 4.1 New Test Files to Create

| File | Tests |
|------|-------|
| `StressMonitorTests/StressRepositoryTests.swift` | All CRUD, baseline, sync delegation |
| `StressMonitorTests/CloudKitManagerTests.swift` | Mock-based CloudKitManager tests |
| `StressMonitorTests/CloudKitSyncEngineTests.swift` | Batch/retry logic |
| `StressMonitorTests/ConflictResolverTests.swift` | All 4 strategies, batch, edge cases |
| `StressMonitorTests/SyncManagerTests.swift` | Orchestration, lifecycle, error handling |
| `StressMonitorTests/MockCloudKitService.swift` | Mock conforming to CloudKitServiceProtocol |

### 4.2 MockCloudKitService Design

```swift
@MainActor
final class MockCloudKitService: CloudKitServiceProtocol, @unchecked Sendable {
    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?

    // Configurable behavior
    var savedMeasurements: [StressMeasurement] = []
    var fetchedMeasurements: [StressMeasurement] = []
    var deletedMeasurementIDs: [String] = []
    var shouldThrowError: Error? = nil
    var accountStatus: CloudKitAccountStatus = .available

    func saveMeasurement(_ measurement: StressMeasurement) async throws {
        if let error = shouldThrowError { throw error }
        savedMeasurements.append(measurement)
        lastSyncDate = Date()
    }

    func fetchMeasurements(since date: Date?) async throws -> [StressMeasurement] {
        if let error = shouldThrowError { throw error }
        if let date = date {
            return fetchedMeasurements.filter { $0.timestamp >= date }
        }
        return fetchedMeasurements
    }

    func deleteMeasurement(_ measurement: StressMeasurement) async throws {
        if let error = shouldThrowError { throw error }
        deletedMeasurementIDs.append(measurement.deviceID)
    }

    func sync() async throws {
        if let error = shouldThrowError { throw error }
        syncStatus = .success
        lastSyncDate = Date()
    }

    func setupPushSubscription() async throws {}
    func checkAccountStatus() async throws -> CloudKitAccountStatus { accountStatus }
}
```

### 4.3 Shared Test Helpers

Create a `StressMonitorTests/TestHelpers.swift`:
```swift
import Foundation
import SwiftData
@testable import StressMonitor

enum TestHelper {
    @MainActor
    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: StressMeasurement.self,
            configurations: config
        )
    }

    @MainActor
    static func makeRepository(
        cloudKit: CloudKitServiceProtocol? = nil,
        baselineCalculator: BaselineCalculator? = nil
    ) -> StressRepository {
        let container = makeInMemoryContainer()
        let context = ModelContext(container)
        return StressRepository(
            modelContext: context,
            baselineCalculator: baselineCalculator,
            cloudKitManager: cloudKit
        )
    }

    static func makeMeasurement(
        timestamp: Date = Date(),
        stressLevel: Double = 35.0,
        hrv: Double = 50.0,
        heartRate: Double = 72.0,
        deviceID: String = "test-device"
    ) -> StressMeasurement {
        StressMeasurement(
            timestamp: timestamp,
            stressLevel: stressLevel,
            hrv: hrv,
            restingHeartRate: heartRate,
            confidences: [0.85],
            deviceID: deviceID
        )
    }
}
```

---

## 5. Detailed Test Cases

### 5.1 StressRepositoryTests (~30 test methods)

#### CRUD — Save Operations
- **testSave_singleMeasurement** — save one measurement, verify it's fetchable via `fetchRecent(limit: 1)`
- **testSave_persistsToModelContext** — save then fetch confirms count == 1
- **testSave_throwsOnModelContextError** — simulate save failure, verify `RepositoryError.saveFailed`
- **testSave_triggersCloudKitSync** — save with mock CloudKit, verify `saveMeasurement` called
- **testSave_doesNotTriggerCloudKit_whenNil** — save without CloudKit, no crash
- **testSaveBatch_multipleMeasurements** — save 5 measurements, verify all persisted
- **testSaveBatch_triggersCloudKitBatchSync** — verify batch sync called on CloudKit mock

#### CRUD — Fetch Operations
- **testFetchRecent_returnsLimitedResults** — insert 10, fetch limit 3, verify 3 returned
- **testFetchRecent_returnsInDescendingOrder** — verify newest first
- **testFetchRecent_emptyStore** — verify empty array
- **testFetchAll_returnsAllMeasurements** — insert 20, fetch all, verify 20
- **testFetchAll_descendingOrder** — verify sort order
- **testFetchMeasurements_dateRange** — insert measurements across 3 days, fetch range covering 1 day, verify correct subset
- **testFetchMeasurements_inclusiveBoundaries** — measurements at exact boundary dates included
- **testFetchUnsyncedMeasurements** — insert synced + unsynced, verify only unsynced returned
- **testFetchUnsyncedMeasurements_allSynced** — verify empty array

#### CRUD — Delete Operations
- **testDelete_singleMeasurement** — save then delete, verify empty
- **testDelete_marksUnsyncedBeforeCloudKitDelete** — verify `isSynced == false` during process
- **testDelete_deletesFromCloudKit** — mock CloudKit, verify `deleteMeasurement` called
- **testDelete_continuesLocalDeletion_onCloudKitFailure** — CloudKit throws, local still deleted
- **testDeleteOlderThan** — insert 5 measurements across dates, delete older than midpoint, verify 2 remain
- **testDeleteOlderThan_deletesFromCloudKit** — verify CloudKit delete called for each
- **testDeleteAllMeasurements** — insert 10, delete all, verify empty
- **testDeleteAllMeasurements_clearsBaselineCache** — verify `cachedBaseline` is nil after

#### Baseline Operations
- **testGetBaseline_emptyStore_returnsDefaultBaseline** — no measurements, verify `PersonalBaseline()` default
- **testGetBaseline_withMeasurements_calculatesBaseline** — insert 30+ measurements, verify baseline computed
- **testGetBaseline_cachesResult** — call twice, verify second call returns cached
- **testGetBaseline_withPersistedBaseline_mergesMetadata** — set persisted baseline, verify factorWeights/hourlyHRV merged
- **testUpdateBaseline_persistsToUserDefaults** — update baseline, verify UserDefaults contains data
- **testUpdateBaseline_updatesCache** — verify cached value matches

#### Statistics
- **testFetchAverageHRV_hours** — insert measurements over 48h, fetch 24h average, verify correct
- **testFetchAverageHRV_days** — insert measurements over 14 days, fetch 7 day average
- **testFetchAverageHRV_emptyStore** — verify returns 0.0

#### Sync Operations
- **testSyncPendingMeasurements_noCloudKit_throws** — verify `RepositoryError.cloudKitUnavailable`
- **testSyncPendingMeasurements_syncsAll** — insert 5 unsynced, sync, verify all marked synced
- **testSyncPendingMeasurements_reportsProgress** — verify `onSyncStatusChange` called with progress
- **testFetchFromCloudKit_mergesRemote** — mock fetches remote, verify merged into local store
- **testFetchFromCloudKit_handlesCKError** — mock throws CKError, verify adapted error
- **testPerformFullSync_pushThenPull** — verify order: syncPending then fetchFromCloudKit
- **testCheckCloudKitStatus_delegates** — verify passes through to CloudKit manager
- **testSyncStatusCallbacks_onSyncStatusChange** — verify callback invoked at correct stages
- **testSyncStatusCallbacks_onSyncError** — verify error callback on failure

#### mergeRemoteMeasurement (the O(n) fix)
- **testMergeRemote_noLocal_insertsRemote** — remote measurement with new timestamp/deviceID gets inserted
- **testMergeRemote_existingLocal_remoteNewer_updatesLocal** — remote has later `cloudKitModTime`, local updated
- **testMergeRemote_existingLocal_localNewer_keepsLocal** — local has later mod time, not overwritten
- **testMergeRemote_existingLocal_noModTime_keepsLocal** — missing mod times, no overwrite
- **testMergeRemote_marksSynced** — inserted remote measurement has `isSynced == true`
- **testMergeRemotePerformance_largeDataset** — measure performance with 10k local, 50 remote

#### Error Adaptation
- **testAdaptCloudKitError_networkFailure** — CKError.networkFailure → .networkUnavailable(.noInternet)
- **testAdaptCloudKitError_notAuthenticated** → .networkUnavailable(.iCloudNotSignedIn)
- **testAdaptCloudKitError_quotaExceeded** → .networkUnavailable(.quotaExceeded)
- **testAdaptCloudKitError_rateLimited** → .rateLimited
- **testAdaptCloudKitError_zoneNotFound** → .zoneNotFound
- **testAdaptCloudKitError_unknownItem** → .recordNotFound

---

### 5.2 ConflictResolverTests (~20 test methods)

#### Timestamp Strategy
- **testResolveByTimestamp_localNewer_keepsLocal**
- **testResolveByTimestamp_remoteNewer_keepsRemote**
- **testResolveByTimestamp_sameTimestamp_merges**
- **testResolveByTimestamp_mergeTakesMaxValues** — verify merged stress/hrv/hr are max of both

#### Server Strategy
- **testResolveByServer_alwaysKeepsRemote**

#### Client Strategy
- **testResolveByClient_alwaysKeepsLocal**

#### Device Priority Strategy
- **testResolveByDevicePriority_iPhoneOverWatch** — iPhone wins over watch
- **testResolveByDevicePriority_iPadOverWatch** — iPad wins over watch
- **testResolveByDevicePriority_sameDevice_fallsBackToTimestamp**
- **testResolveByDevicePriority_noRemoteDeviceID_fallsBackToTimestamp**

#### Batch Resolution
- **testResolveBatch_pairsByTimestamp** — verify matching logic
- **testResolveBatch_noConflicts_keepsLocal** — all local-only → keepLocal
- **testResolveBatch_mixedConflicts** — some conflict, some don't

#### Deleted Record Handling
- **testResolveDeleted_localNil_remoteExists_keepsRemote**
- **testResolveDeleted_localExists_remoteNil_keepsLocal**
- **testResolveDeleted_bothNil_keepsLocal**
- **testResolveDeleted_bothExist_resolvesByStrategy**

#### MergeDecision Extensions
- **testMergeDecision_shouldKeepLocal**
- **testMergeDecision_shouldKeepRemote**
- **testMergeDecision_shouldMerge**

#### ConflictResolution Model
- **testConflictResolution_hasConflict_trueWhenRemoteExists**
- **testConflictResolution_hasConflict_falseWhenRemoteNil**
- **testConflictResolution_winningMeasurement_keepLocal**
- **testConflictResolution_winningMeasurement_keepRemote**
- **testConflictResolution_winningMeasurement_merge**

---

### 5.3 CloudKitSyncEngineTests (~10 test methods)

- **testUploadMeasurements_emptyArray_returnsImmediately**
- **testUploadMeasurements_singleBatch** — 5 items, batchSize 10, verify one batch
- **testUploadMeasurements_multipleBatches** — 25 items, batchSize 10, verify 3 batches
- **testUploadMeasurements_retriesOnFailure** — mock fails twice, succeeds third time
- **testUploadMeasurements_exhaustsRetries_throws** — mock always fails, verify CloudKitSyncError.uploadFailed
- **testDownloadMeasurements_success** — mock returns measurements
- **testDownloadMeasurements_retriesOnFailure** — retry logic
- **testSync_bidirectional** — verify upload then download order
- **testPerformBackgroundSync_usesLastSyncDate** — verifies since date calculation
- **testReset_clearsState** — verify progress/error/isSyncing reset

---

### 5.4 CloudKitManagerTests (~10 test methods)

> Note: These test the real `CloudKitManager` but with a **mock CKContainer** injected via init. In practice, CKContainer cannot be easily mocked, so these will use `MockCloudKitService` to test the **protocol-level contract** that StressRepository relies on, plus a few integration tests that skip if CloudKit is unavailable.

- **testSaveMeasurement_convertsToCKRecord** — verify field mapping (requires CKContainer mock or skip)
- **testFetchMeasurements_withSinceDate_usesPredicate**
- **testFetchMeasurements_throwsOnCKError_adaptsError**
- **testDeleteMeasurement_findsAndDeletes**
- **testCheckAccountStatus_mapsCorrectly**
- **testSync_callsFetchMeasurements**
- **testSetupPushSubscription_succeeds**
- **testSetupPushSubscription_ignoresServerRejected**

**Alternative approach:** Since `CKContainer.default()` can't be mocked in unit tests, focus these tests on verifying the **error adaptation** and **record conversion** logic by extracting those into testable pure functions. The protocol conformance tests are covered via `MockCloudKitService`.

---

### 5.5 SyncManagerTests (~12 test methods)

- **testSync_checksAccountStatusFirst**
- **testSync_accountNotAvailable_setsUnavailable**
- **testSync_performsBidirectionalSync**
- **testSync_resolvesConflicts**
- **testSync_alreadyInProgress_throwsSyncInProgress**
- **testQuickSync_callsCloudKitSync**
- **testQuickSync_onError_setsSyncError**
- **testHandleRemoteNotification_validNotification_triggersSync**
- **testHandleRemoteNotification_invalidNotification_ignores**
- **testManualSync_delegatesToSync**
- **testReset_cancelsTaskAndClearsState**
- **testSetup_setsUpSubscriptionAndChecksAccount**
- **testIsSyncing_trueDuringSync**
- **testCanSync_falseWhenUnavailable**

---

## 6. Implementation Order

### Phase 1: Infrastructure (est. 1 hour)
1. Create branch `test/repository-cloudkit-sync`
2. Create `StressMonitorTests/MockCloudKitService.swift`
3. Create `StressMonitorTests/TestHelpers.swift`
4. Verify in-memory container works with a smoke test

### Phase 2: StressRepository Tests (est. 2 hours)
1. CRUD tests (save, fetch, delete)
2. Baseline tests
3. Statistics tests
4. Sync delegation tests
5. Error adaptation tests

### Phase 3: ConflictResolver Tests (est. 1 hour)
1. Per-strategy tests
2. Batch resolution tests
3. Edge case tests

### Phase 4: CloudKitSyncEngine Tests (est. 1 hour)
1. Upload/download tests
2. Retry logic tests
3. Batch chunking tests

### Phase 5: SyncManager Tests (est. 1 hour)
1. Orchestration tests
2. Lifecycle tests
3. Error handling tests

### Phase 6: Bug Fix — mergeRemoteMeasurement O(n) (est. 30 min)
1. Write failing performance test
2. Apply predicate-based fix
3. Verify all existing tests still pass
4. Verify performance test passes

### Phase 7: CloudKitManager Tests (est. 30 min)
1. Record conversion tests (extract to pure function if needed)
2. Error adaptation tests
3. Protocol conformance verification

---

## 7. Estimated Totals

- **~72 test methods** across 5 test files
- **1 mock file** (`MockCloudKitService.swift`)
- **1 helper file** (`TestHelpers.swift`)
- **1 bug fix** in `StressRepository.mergeRemoteMeasurement()`
- **Estimated effort:** ~7 hours

---

## 8. Acceptance Criteria

- [ ] All tests pass on iOS 17 Simulator (iPhone 15)
- [ ] Code coverage ≥ 80% for StressRepository, ConflictResolver, CloudKitSyncEngine
- [ ] `mergeRemoteMeasurement()` uses predicate-based fetch instead of full-table scan
- [ ] Performance test: merging 50 remote into 10,000 local measurements completes in < 2 seconds
- [ ] No test depends on real CloudKit/network (all mocked)
- [ ] All new test files added to `StressMonitorTests` target in Xcode project

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| SwiftData `#Predicate` with Date equality may not work | Use narrow time-window predicate + in-memory exact match fallback |
| `@MainActor` isolation requires careful test setup | All test helper methods marked `@MainActor`; use `await` in tests |
| `@Observable` classes need iOS 17 test target | Ensure test target deployment target matches app (iOS 17+) |
| `CloudKitManager` uses real `CKContainer` which can't be mocked | Focus on protocol-level tests via `MockCloudKitService`; extract pure functions for unit testing |
| `StressMeasurement` is a SwiftData `@Model` — can't easily compare equality | Compare individual fields or use wrapper equality checks |
| `SyncStatus.error(Error)` is not `Equatable` | Use pattern matching or compare associated values |

---

## 10. File Tree After Implementation

```
StressMonitorTests/
├── StressRepositoryTests.swift          # NEW — ~30 tests
├── CloudKitManagerTests.swift           # NEW — ~10 tests
├── CloudKitSyncEngineTests.swift        # NEW — ~10 tests
├── ConflictResolverTests.swift          # NEW — ~22 tests
├── SyncManagerTests.swift               # NEW — ~14 tests
├── MockCloudKitService.swift            # NEW — mock implementation
├── TestHelpers.swift                    # NEW — shared helpers
├── StressReadingTests.swift             # EXISTING
├── StressPredictorTests.swift           # EXISTING
├── StressHistoryTests.swift             # EXISTING
├── MorningReadinessServiceTests.swift   # EXISTING
└── HRVAnalyzerTests.swift               # EXISTING

StressMonitor/StressMonitor/Services/Repository/
└── StressRepository.swift               # MODIFIED — fix mergeRemoteMeasurement()
```
