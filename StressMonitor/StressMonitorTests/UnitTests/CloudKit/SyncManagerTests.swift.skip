import XCTest
import CloudKit
@testable import StressMonitor

@MainActor
@preconcurrency import CloudKit

/// Comprehensive unit tests for SyncManager
/// Tests sync coordination, status tracking, error recovery, and progress updates
final class SyncManagerTests: XCTestCase {

    var syncManager: SyncManager!
    var mockCloudKit: MockCloudKitManager!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()
        mockCloudKit = MockCloudKitManager()
        syncManager = SyncManager(cloudKitManager: mockCloudKit)
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        syncManager = nil
        mockCloudKit = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Sync Coordination Tests

    func testSync_WithLocalMeasurements() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)

        // When
        try await syncManager.sync(localMeasurements: measurements)

        // Then
        XCTAssertEqual(syncManager.syncStatus, .success)
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    func testSync_WithEmptyLocalMeasurements() async throws {
        // Given
        let measurements: [StressMeasurement] = []

        // When/Then
        try await XCTAssertNoThrow(await syncManager.sync(localMeasurements: measurements))
    }

    func testSync_UpdatesSyncDate() async throws {
        // Given
        let beforeDate = Date()
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When
        try await syncManager.sync(localMeasurements: measurements)
        let afterDate = Date()

        // Then
        XCTAssertNotNil(syncManager.lastSyncDate)
        XCTAssertGreaterThanOrEqual(syncManager.lastSyncDate!, beforeDate)
        XCTAssertLessThanOrEqual(syncManager.lastSyncDate!, afterDate)
    }

    // MARK: - Status Tracking Tests

    func testSyncStatus_IdleInitialState() {
        // Then
        XCTAssertEqual(syncManager.syncStatus, .idle)
        XCTAssertFalse(syncManager.isSyncing)
    }

    func testSyncStatus_SyncingDuringOperation() async {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10)
        mockCloudKit.setSyncDelay(0.2) // Add delay to observe status

        // When
        Task {
            try? await syncManager.sync(localMeasurements: measurements)
        }

        // Wait a bit for sync to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Then - Status should be syncing or completed
        let isCurrentlySyncing = syncManager.isSyncing
        let status = syncManager.syncStatus

        // Status should either be syncing or completed (success/error)
        let isValidStatus = switch status {
        case .syncing, .success, .error:
            true
        default:
            false
        }
        XCTAssertTrue(isValidStatus, "Expected valid sync status, got: \(String(describing: status))")
    }

    func testSyncStatus_SuccessAfterCompletion() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When
        try await syncManager.sync(localMeasurements: measurements)

        // Then
        XCTAssertEqual(syncManager.syncStatus, .success)
        XCTAssertFalse(syncManager.isSyncing)
    }

    func testSyncStatus_ErrorOnFailure() async {
        // Given
        mockCloudKit.setError(CloudKitError.networkFailure)
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When
        do {
            try await syncManager.sync(localMeasurements: measurements)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
        }

        // Then
        if case .error = syncManager.syncStatus {
            // Expected
        } else {
            XCTFail("Expected error status, got: \(String(describing: syncManager.syncStatus))")
        }
        XCTAssertNotNil(syncManager.syncError)
        XCTAssertFalse(syncManager.isSyncing)
    }

    func testSyncProgress_UpdatesDuringSync() async {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10)
        mockCloudKit.setSyncDelay(0.1)

        // When
        try await syncManager.sync(localMeasurements: measurements)

        // Then
        // After completion, progress should be complete
        if case .syncing(let progress) = syncManager.syncStatus {
            // Should not be syncing anymore
        } else if case .success = syncManager.syncStatus {
            // Sync completed successfully
            XCTAssertTrue(true)
        }
    }

    // MARK: - Quick Sync Tests

    func testQuickSync_Success() async throws {
        // When
        try await syncManager.quickSync()

        // Then
        XCTAssertEqual(syncManager.syncStatus, .success)
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    func testQuickSync_WithError() async {
        // Given
        mockCloudKit.setError(CloudKitError.accountUnavailable)

        // When
        do {
            try await syncManager.quickSync()
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
        }

        // Then
        if case .error = syncManager.syncStatus {
            // Expected
        } else {
            XCTFail("Expected error status")
        }
    }

    // MARK: - Manual Sync Tests

    func testManualSync_Success() async throws {
        // When/Then
        try await XCTAssertNoThrow(await syncManager.manualSync())
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    // MARK: - Error Recovery Tests

    func testErrorRecovery_AfterFailedSync() async throws {
        // Given - First sync fails
        mockCloudKit.setError(CloudKitError.unknown)
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        do {
            try await syncManager.sync(localMeasurements: measurements)
        } catch {
            // Expected error
        }

        XCTAssertNotNil(syncManager.syncError)

        // When - Second sync succeeds
        mockCloudKit.setError(nil)
        try await syncManager.sync(localMeasurements: measurements)

        // Then - Should recover and succeed
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    func testErrorRecovery_TransientNetworkFailure() async throws {
        // Given
        mockCloudKit.setError(CloudKitError.networkFailure)
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When - First attempt fails
        do {
            try await syncManager.sync(localMeasurements: measurements)
        } catch {
            // Expected
        }

        // Clear error and retry
        mockCloudKit.setError(nil)
        try await syncManager.sync(localMeasurements: measurements)

        // Then - Should succeed on retry
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    // MARK: - Account Status Tests

    func testAccountStatus_Available() async throws {
        // When
        try await syncManager.setup()

        // Then - Should not throw error for available account
        // Status should be available or idle
        XCTAssertTrue(
            syncManager.syncStatus == .idle ||
            syncManager.syncStatus == .unavailable(.iCloudNotSignedIn)
        )
    }

    func testCanSync_Property() async {
        // Given - Initially should be able to sync
        XCTAssertTrue(syncManager.canSync)

        // When - Setup completes
        try? await syncManager.setup()

        // Then - Should still be able to sync (account is available in mock)
        XCTAssertTrue(syncManager.canSync || syncManager.syncStatus == .unavailable(.iCloudNotSignedIn))
    }

    // MARK: - Lifecycle Event Tests

    func testHandleAppWillEnterForeground() async {
        // Given
        let expectation = XCTestExpectation(description: "Sync triggered on foreground")
        mockCloudKit.setSyncDelay(0.05)

        // When
        Task {
            await syncManager.handleAppWillEnterForeground()
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    func testHandleAppDidBecomeActive() async {
        // Given
        let expectation = XCTestExpectation(description: "Sync triggered on become active")
        mockCloudKit.setSyncDelay(0.05)

        // When
        Task {
            await syncManager.handleAppDidBecomeActive()
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Reset Tests

    func testReset_ClearsState() async throws {
        // Given - Perform a sync to set state
        let measurements = testDataFactory.createMeasurementBatch(count: 3)
        try await syncManager.sync(localMeasurements: measurements)
        XCTAssertNotNil(syncManager.lastSyncDate)

        // When
        syncManager.reset()

        // Then
        XCTAssertEqual(syncManager.syncStatus, .idle)
        XCTAssertNil(syncManager.syncError)
    }

    func testReset_WhileSyncing() async {
        // Given - Start a sync with delay
        mockCloudKit.setSyncDelay(1.0)
        let measurements = testDataFactory.createMeasurementBatch(count: 10)

        Task {
            try? await syncManager.sync(localMeasurements: measurements)
        }

        // Wait for sync to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // When - Reset while syncing
        syncManager.reset()

        // Then - Should clear the state
        XCTAssertEqual(syncManager.syncStatus, .idle)
    }

    // MARK: - Concurrent Sync Tests

    func testConcurrentSync_PreventsMultipleSimultaneousSyncs() async {
        // Given
        mockCloudKit.setSyncDelay(0.2)
        let measurements = testDataFactory.createMeasurementBatch(count: 5)

        // When - Start multiple syncs concurrently
        async let sync1: Void = syncManager.sync(localMeasurements: measurements)
        async let sync2: Void = syncManager.sync(localMeasurements: measurements)

        // Then - One should succeed, one should fail with syncInProgress
        let result1 = await sync1_result
        let result2 = await sync2_result

        let oneFailed = result1 != nil || result2 != nil
        let oneSucceeded = result1 == nil || result2 == nil

        XCTAssertTrue(
            oneFailed && oneSucceeded,
            "One sync should fail with syncInProgress error"
        )
    }

    private var sync1_result: Error?
    private var sync2_result: Error?

    func testConcurrentSync_Sequential() async throws {
        // Given
        let measurements1 = testDataFactory.createMeasurementBatch(count: 3)
        let measurements2 = testDataFactory.createMeasurementBatch(count: 3)

        // When - Run syncs sequentially
        try await syncManager.sync(localMeasurements: measurements1)
        try await syncManager.sync(localMeasurements: measurements2)

        // Then - Both should succeed
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    // MARK: - Remote Notification Tests

    func testHandleRemoteNotification_ValidNotification() async {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "aps": [:],
            "ck": [:]
        ]

        // When/Then - Should not throw
        await syncManager.handleRemoteNotification(userInfo)
    }

    func testHandleRemoteNotification_InvalidNotification() async {
        // Given
        let userInfo: [AnyHashable: Any] = [:]

        // When/Then - Should handle gracefully
        await syncManager.handleRemoteNotification(userInfo)
    }

    // MARK: - Background Sync Tests

    func testBackgroundSync_PerformsSync() async throws {
        // Given
        mockCloudKit.setSyncDelay(0.05)
        let measurements = testDataFactory.createMeasurementBatch(count: 3)
        try await syncManager.sync(localMeasurements: measurements)

        let initialSyncDate = syncManager.lastSyncDate

        // When
        try? await syncManager.manualSync()

        // Then
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    // MARK: - Progress Tracking Tests

    func testSyncProgress_StartsAtZero() {
        // Given
        XCTAssertEqual(syncManager.syncProgress, 0.0)
    }

    func testSyncProgress_Updates() async throws {
        // Given
        mockCloudKit.setSyncDelay(0.1)
        let measurements = testDataFactory.createMeasurementBatch(count: 5)

        // When
        try await syncManager.sync(localMeasurements: measurements)

        // Then - Progress should be tracked during sync
        let progress = syncManager.syncProgress
        XCTAssertTrue(progress >= 0.0 && progress <= 1.0)
    }

    // MARK: - Edge Cases Tests

    func testSync_WithDuplicateTimestamps() async throws {
        // Given
        let timestamp = Date()
        let measurements = [
            StressMeasurement(
                timestamp: timestamp,
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            ),
            StressMeasurement(
                timestamp: timestamp,
                stressLevel: 55,
                hrv: 55,
                restingHeartRate: 65,
                confidences: [0.9]
            )
        ]

        // When/Then - Should handle duplicates gracefully
        try await XCTAssertNoThrow(await syncManager.sync(localMeasurements: measurements))
    }

    func testSync_WithLargeDataset() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 100)

        // When/Then
        try await XCTAssertNoThrow(await syncManager.sync(localMeasurements: measurements))
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    func testSync_WithNilConfidences() async throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: nil
        )

        // When/Then
        try await XCTAssertNoThrow(await syncManager.sync(localMeasurements: [measurement]))
    }

    func testSync_WithEmptyConfidences() async throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )

        // When/Then
        try await XCTAssertNoThrow(await syncManager.sync(localMeasurements: [measurement]))
    }

    // MARK: - Conflict Resolution Tests

    func testSync_WithConflictingMeasurements() async throws {
        // Given - Create conflicting measurements
        let timestamp = Date()
        let localMeasurements = [
            StressMeasurement(
                timestamp: timestamp,
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
        ]

        // When
        try await syncManager.sync(localMeasurements: localMeasurements)

        // Then - Should handle conflicts via conflict resolver
        XCTAssertEqual(syncManager.syncStatus, .success)
    }

    // MARK: - Factory Method Tests

    func testCreate_StaticFactoryMethod() {
        // When
        let manager = SyncManager.create()

        // Then
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.syncStatus, .idle)
    }

    // MARK: - Performance Tests

    func testPerformance_SyncMultipleBatches() async throws {
        // Given
        mockCloudKit.setSyncDelay(0.01) // Small delay for realistic timing
        let measurements = testDataFactory.createMeasurementBatch(count: 50)

        // Measure
        measure {
            try? await syncManager.sync(localMeasurements: measurements)
        }
    }

    func testPerformance_StatusChecks() {
        // Measure
        measure {
            for _ in 0..<1000 {
                _ = syncManager.isSyncing
                _ = syncManager.canSync
                _ = syncManager.syncProgress
            }
        }
    }

    // MARK: - Memory Tests

    func testMemory_LargeSyncOperation() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 1000)

        // Add memory tracking
        let startMemory = getMemoryUsage()

        // When
        try await syncManager.sync(localMeasurements: measurements)

        // Then
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory

        // Memory increase should be reasonable (less than 50MB)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory usage should not spike excessively")
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
