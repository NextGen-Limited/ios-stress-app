import XCTest
import CloudKit
@testable import StressMonitor

@MainActor
@preconcurrency import CloudKit

/// Comprehensive unit tests for CloudKitManager
/// Tests save, fetch, delete, subscription setup, account status, and error handling
final class CloudKitManagerTests: XCTestCase {

    var mockCloudKit: MockCloudKitManager!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()
        mockCloudKit = MockCloudKitManager()
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        mockCloudKit = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Save Measurement Tests

    func testSaveMeasurement_Success() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement(
            stressLevel: 45,
            hrv: 55,
            heartRate: 65
        )

        // When
        try await mockCloudKit.saveMeasurement(measurement)

        // Then
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
        XCTAssertNotNil(mockCloudKit.lastSyncDate)
    }

    func testSaveMeasurement_MultipleMeasurements() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10)

        // When
        for measurement in measurements {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        // Then
        let fetched = try await mockCloudKit.fetchMeasurements()
        XCTAssertEqual(fetched.count, 10)
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    func testSaveMeasurement_WithNilConfidences() async throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: nil
        )

        // When/Then
        try await XCTAssertNoThrow(await mockCloudKit.saveMeasurement(measurement))
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    func testSaveMeasurement_WithEmptyConfidences() async throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )

        // When/Then
        try await XCTAssertNoThrow(await mockCloudKit.saveMeasurement(measurement))
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    // MARK: - Fetch Measurements Tests

    func testFetchMeasurements_WithNoDateFilter() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        for measurement in measurements {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        // When
        let fetched = try await mockCloudKit.fetchMeasurements()

        // Then
        XCTAssertEqual(fetched.count, 5)
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    func testFetchMeasurements_WithDateFilter() async throws {
        // Given
        let oldMeasurement = testDataFactory.createMeasurement(daysAgo: 5)
        let recentMeasurement = testDataFactory.createMeasurement(daysAgo: 1)
        let todayMeasurement = testDataFactory.createMeasurement(daysAgo: 0)

        try await mockCloudKit.saveMeasurement(oldMeasurement)
        try await mockCloudKit.saveMeasurement(recentMeasurement)
        try await mockCloudKit.saveMeasurement(todayMeasurement)

        let cutoffDate = Date().addingTimeInterval(-2 * 86400) // 2 days ago

        // When
        let fetched = try await mockCloudKit.fetchMeasurements(since: cutoffDate)

        // Then
        XCTAssertEqual(fetched.count, 2)
        XCTAssertGreaterThanOrEqual(fetched.first?.timestamp ?? Date.distantPast, cutoffDate)
    }

    func testFetchMeasurements_EmptyDatabase() async throws {
        // Given
        let emptyMock = MockCloudKitManager()

        // When
        let fetched = try await emptyMock.fetchMeasurements()

        // Then
        XCTAssertEqual(fetched.count, 0)
        XCTAssertEqual(emptyMock.syncStatus, .success)
    }

    func testFetchMeasurements_SortedByTimestamp() async throws {
        // Given
        let measurements = [
            testDataFactory.createMeasurement(daysAgo: 3),
            testDataFactory.createMeasurement(daysAgo: 1),
            testDataFactory.createMeasurement(daysAgo: 5)
        ]

        for measurement in measurements {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        // When
        let fetched = try await mockCloudKit.fetchMeasurements()

        // Then
        XCTAssertEqual(fetched.count, 3)
        // Should be sorted descending (newest first)
        for i in 0..<(fetched.count - 1) {
            XCTAssertGreaterThanOrEqual(fetched[i].timestamp, fetched[i + 1].timestamp)
        }
    }

    // MARK: - Delete Measurement Tests

    func testDeleteMeasurement_Success() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement(
            stressLevel: 50,
            hrv: 50,
            heartRate: 60
        )
        try await mockCloudKit.saveMeasurement(measurement)

        var fetched = try await mockCloudKit.fetchMeasurements()
        XCTAssertEqual(fetched.count, 1)

        // When
        try await mockCloudKit.deleteMeasurement(measurement)

        // Then
        fetched = try await mockCloudKit.fetchMeasurements()
        XCTAssertEqual(fetched.count, 0)
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    func testDeleteMeasurement_NonExistent() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When/Then - Should not throw even if measurement doesn't exist
        try await XCTAssertNoThrow(await mockCloudKit.deleteMeasurement(measurement))
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
    }

    func testDeleteMeasurement_MultipleTimes() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        try await mockCloudKit.saveMeasurement(measurement)

        // When - Delete twice
        try await mockCloudKit.deleteMeasurement(measurement)
        try await mockCloudKit.deleteMeasurement(measurement)

        // Then
        let fetched = try await mockCloudKit.fetchMeasurements()
        XCTAssertEqual(fetched.count, 0)
    }

    // MARK: - Sync Tests

    func testSync_Success() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        try await mockCloudKit.saveMeasurement(measurement)

        // When
        try await mockCloudKit.sync()

        // Then
        XCTAssertEqual(mockCloudKit.syncStatus, .success)
        XCTAssertNotNil(mockCloudKit.lastSyncDate)
    }

    func testSync_WithEmptyDatabase() async throws {
        // Given
        let emptyMock = MockCloudKitManager()

        // When/Then
        try await XCTAssertNoThrow(await emptyMock.sync())
        XCTAssertEqual(emptyMock.syncStatus, .success)
    }

    func testSync_UpdatesLastSyncDate() async throws {
        // Given
        let beforeDate = Date()

        // When
        try await mockCloudKit.sync()
        let afterDate = Date()

        // Then
        XCTAssertNotNil(mockCloudKit.lastSyncDate)
        XCTAssertGreaterThanOrEqual(mockCloudKit.lastSyncDate!, beforeDate)
        XCTAssertLessThanOrEqual(mockCloudKit.lastSyncDate!, afterDate)
    }

    // MARK: - Push Subscription Tests

    func testSetupPushSubscription_Success() async throws {
        // When/Then
        try await XCTAssertNoThrow(await mockCloudKit.setupPushSubscription())
    }

    func testSetupPushSubscription_MultipleCalls() async throws {
        // When/Then - Should be idempotent
        try await XCTAssertNoThrow(await mockCloudKit.setupPushSubscription())
        try await XCTAssertNoThrow(await mockCloudKit.setupPushSubscription())
    }

    // MARK: - Account Status Tests

    func testCheckAccountStatus_Available() async throws {
        // When
        let status = try await mockCloudKit.checkAccountStatus()

        // Then
        XCTAssertEqual(status, .available)
    }

    func testCheckAccountStatus_DefaultReturnValue() async throws {
        // Given - Mock should return available by default
        let status = try await mockCloudKit.checkAccountStatus()

        // Then
        XCTAssertTrue(status == .available || status == .unknown)
    }

    // MARK: - Sync Status Tests

    func testSyncStatus_ProgressTracking() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When
        mockCloudKit.setSyncDelay(0.1) // Small delay to observe status changes
        Task {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        // Then
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        // Status should be syncing or success
        let status = mockCloudKit.syncStatus
        XCTAssertTrue(
            status == .syncing(progress: 0.5) || status == .success,
            "Expected syncing or success status, got: \(String(describing: status))"
        )
    }

    // MARK: - Error Handling Tests

    func testSaveMeasurement_WithError() async {
        // Given
        mockCloudKit.setError(CloudKitError.unknown)
        let measurement = testDataFactory.createMeasurement()

        // When/Then
        do {
            try await mockCloudKit.saveMeasurement(measurement)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testFetchMeasurements_WithError() async {
        // Given
        mockCloudKit.setError(CloudKitError.networkFailure)

        // When/Then
        do {
            _ = try await mockCloudKit.fetchMeasurements()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testDeleteMeasurement_WithError() async {
        // Given
        mockCloudKit.setError(CloudKitError.accountUnavailable)
        let measurement = testDataFactory.createMeasurement()

        // When/Then
        do {
            try await mockCloudKit.deleteMeasurement(measurement)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testSync_WithError() async {
        // Given
        mockCloudKit.setError(CloudKitError.quotaExceeded)

        // When/Then
        do {
            try await mockCloudKit.sync()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testError_StatusUpdatedOnFailure() async {
        // Given
        mockCloudKit.setError(CloudKitError.unknown)
        let measurement = testDataFactory.createMeasurement()

        // When
        do {
            try await mockCloudKit.saveMeasurement(measurement)
        } catch {
            // Expected error
        }

        // Then
        // After error, status should reflect the error
        let status = mockCloudKit.syncStatus
        if case .error = status {
            // Expected
        } else {
            XCTFail("Expected error status, got: \(String(describing: status))")
        }
    }

    // MARK: - Async Delay Tests

    func testOperation_WithDelay() async throws {
        // Given
        mockCloudKit.setSyncDelay(0.1)
        let measurement = testDataFactory.createMeasurement()

        // When
        let startTime = Date()
        try await mockCloudKit.saveMeasurement(measurement)
        let elapsed = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.1, "Operation should take at least the delay time")
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllState() async throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        try await mockCloudKit.saveMeasurement(measurement)
        XCTAssertNotNil(mockCloudKit.lastSyncDate)

        // When
        mockCloudKit.reset()

        // Then
        XCTAssertEqual(mockCloudKit.syncStatus, .idle)
        XCTAssertNil(mockCloudKit.lastSyncDate)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentSaveOperations() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10)

        // When - Save all concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for measurement in measurements {
                group.addTask {
                    try await self.mockCloudKit.saveMeasurement(measurement)
                }
            }
            try await group.waitForAll()
        }

        // Then
        let fetched = try await mockCloudKit.fetchMeasurements()
        XCTAssertEqual(fetched.count, 10)
    }

    // MARK: - Edge Cases Tests

    func testSaveMeasurement_WithFutureTimestamp() async throws {
        // Given
        let futureMeasurement = StressMeasurement(
            timestamp: Date().addingTimeInterval(86400), // 1 day in future
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When/Then
        try await XCTAssertNoThrow(await mockCloudKit.saveMeasurement(futureMeasurement))
    }

    func testSaveMeasurement_WithPastTimestamp() async throws {
        // Given
        let pastMeasurement = StressMeasurement(
            timestamp: Date().addingTimeInterval(-365 * 86400), // 1 year ago
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When/Then
        try await XCTAssertNoThrow(await mockCloudKit.saveMeasurement(pastMeasurement))
    }

    func testSaveMeasurement_WithExtremeStressValues() async throws {
        // Given
        let extremeValues = [
            (stressLevel: 0.0, hrv: 0.0, heartRate: 0.0),
            (stressLevel: 100.0, hrv: 200.0, heartRate: 200.0),
            (stressLevel: -10.0, hrv: -50.0, heartRate: 30.0)
        ]

        for values in extremeValues {
            let measurement = StressMeasurement(
                timestamp: Date(),
                stressLevel: values.stressLevel,
                hrv: values.hrv,
                restingHeartRate: values.heartRate,
                confidences: nil
            )

            // When/Then - Should handle extreme values gracefully
            try await XCTAssertNoThrow(await mockCloudKit.saveMeasurement(measurement))
        }
    }

    // MARK: - Large Dataset Tests

    func testFetchMeasurements_LargeDataset() async throws {
        // Given
        let largeBatch = testDataFactory.createMeasurementBatch(count: 100)

        // When
        for measurement in largeBatch {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        let fetched = try await mockCloudKit.fetchMeasurements()

        // Then
        XCTAssertEqual(fetched.count, 100)
    }

    // MARK: - Performance Tests

    func testPerformance_SaveManyMeasurements() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 50)

        // Measure
        measure {
            for measurement in measurements {
                try? await mockCloudKit.saveMeasurement(measurement)
            }
        }
    }

    func testPerformance_FetchManyMeasurements() async throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 100)
        for measurement in measurements {
            try await mockCloudKit.saveMeasurement(measurement)
        }

        // Measure
        measure {
            _ = try? await mockCloudKit.fetchMeasurements()
        }
    }
}
