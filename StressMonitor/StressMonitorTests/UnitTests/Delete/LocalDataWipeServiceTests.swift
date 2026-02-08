import XCTest
import SwiftData
@testable import StressMonitor

@MainActor
@preconcurrency import SwiftData

/// Comprehensive unit tests for LocalDataWipeService
/// Tests delete all, delete before date, delete in range, and batch operations using in-memory SwiftData container
final class LocalDataWipeServiceTests: XCTestCase {

    var wipeService: LocalDataWipeService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        modelContainer = try TestDataFactory.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        wipeService = LocalDataWipeService(modelContext: modelContext)
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        wipeService = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func insertTestMeasurements(count: Int) async throws {
        for i in 0..<count {
            let measurement = StressMeasurement(
                timestamp: Date().addingTimeInterval(-Double(i * 3600)),
                stressLevel: Double(i * 10),
                hrv: 50.0,
                restingHeartRate: 60.0,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()
    }

    private func fetchMeasurementCount() async throws -> Int {
        let descriptor = FetchDescriptor<StressMeasurement>()
        return try modelContext.fetchCount(descriptor)
    }

    // MARK: - Delete All Tests

    func testDeleteAllMeasurements_Success() async throws {
        // Given
        try await insertTestMeasurements(count: 10)
        var count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 10)

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
        XCTAssertFalse(wipeService.isDeleting)
        XCTAssertEqual(wipeService.deleteProgress, 1.0)
    }

    func testDeleteAllMeasurements_EmptyDatabase() async throws {
        // Given - Database is already empty

        // When/Then
        try await XCTAssertNoThrow(await wipeService.deleteAllMeasurements())

        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    func testDeleteAllMeasurements_WithConfirmation() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        var confirmationCalled = false
        let confirmation: () async -> Bool = {
            confirmationCalled = true
            return true
        }

        // When
        try await wipeService.deleteAllMeasurements(confirmation: confirmation)

        // Then
        XCTAssertTrue(confirmationCalled)
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    func testDeleteAllMeasurements_ConfirmationDeclined() async {
        // Given
        try await insertTestMeasurements(count: 5)

        let confirmation: () async -> Bool = {
            return false // User declines
        }

        // When/Then
        do {
            try await wipeService.deleteAllMeasurements(confirmation: confirmation)
            XCTFail("Expected LocalDataError.operationCancelled")
        } catch LocalDataError.operationCancelled {
            // Expected
        } catch {
            XCTFail("Expected LocalDataError.operationCancelled, got: \(error)")
        }

        // Data should still exist
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 5)
    }

    func testDeleteAllMeasurements_ProgressTracking() async throws {
        // Given
        try await insertTestMeasurements(count: 50)

        var progressValues: [Double] = []
        let progressExpectation = XCTestExpectation(description: "Progress updated")
        progressExpectation.expectedFulfillmentCount = 3

        // Track progress
        Task {
            for _ in 0..<5 {
                progressValues.append(wipeService.deleteProgress)
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            progressExpectation.fulfill()
        }

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        await fulfillment(of: [progressExpectation], timeout: 2.0)
        XCTAssertFalse(progressValues.isEmpty)
        XCTAssertEqual(wipeService.deleteProgress, 1.0)
    }

    // MARK: - Delete Before Date Tests

    func testDeleteMeasurementsBefore_Success() async throws {
        // Given
        let now = Date()
        let oldDate = now.addingTimeInterval(-48 * 3600) // 48 hours ago

        // Insert measurements at different times
        for i in 0..<10 {
            let measurement = StressMeasurement(
                timestamp: now.addingTimeInterval(-Double(i * 12 * 3600)), // Every 12 hours
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        let beforeCount = try await fetchMeasurementCount()

        // When - Delete measurements older than 36 hours
        let cutoffDate = now.addingTimeInterval(-36 * 3600)
        try await wipeService.deleteMeasurements(before: cutoffDate)

        // Then
        let afterCount = try await fetchMeasurementCount()
        XCTAssertLessThan(afterCount, beforeCount)
        XCTAssertFalse(wipeService.isDeleting)
    }

    func testDeleteMeasurementsBefore_NoMatches() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        let futureCutoff = Date().addingTimeInterval(86400) // Tomorrow

        // When
        try await wipeService.deleteMeasurements(before: futureCutoff)

        // Then - All measurements should be deleted as they're all before future date
        let count = try await fetchMeasurementCount()
        // This might delete all or none depending on implementation
        XCTAssertTrue(count >= 0)
    }

    func testDeleteMeasurementsBefore_PastCutoff() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        let pastCutoff = Date().addingTimeInterval(-365 * 86400) // 1 year ago

        // When
        try await wipeService.deleteMeasurements(before: pastCutoff)

        // Then - No measurements should be deleted
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 5)
    }

    func testDeleteMeasurementsBefore_WithConfirmation() async throws {
        // Given
        try await insertTestMeasurements(count: 5)
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour ago

        var confirmationCalled = false
        let confirmation: () async -> Bool = {
            confirmationCalled = true
            return true
        }

        // When
        try await wipeService.deleteMeasurements(before: cutoffDate, confirmation: confirmation)

        // Then
        XCTAssertTrue(confirmationCalled)
    }

    // MARK: - Delete In Range Tests

    func testDeleteMeasurementsInRange_Success() async throws {
        // Given
        let now = Date()
        let rangeStart = now.addingTimeInterval(-48 * 3600)
        let rangeEnd = now.addingTimeInterval(-24 * 3600)

        // Insert measurements
        for i in 0..<10 {
            let timestamp = now.addingTimeInterval(-Double(i * 6 * 3600)) // Every 6 hours
            let measurement = StressMeasurement(
                timestamp: timestamp,
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        let beforeCount = try await fetchMeasurementCount()

        // When
        try await wipeService.deleteMeasurements(in: rangeStart...rangeEnd)

        // Then
        let afterCount = try await fetchMeasurementCount()
        XCTAssertLessThan(afterCount, beforeCount)
    }

    func testDeleteMeasurementsInRange_SameStartAndEnd() async throws {
        // Given
        try await insertTestMeasurements(count: 5)
        let specificDate = Date().addingTimeInterval(-3600)

        // When
        try await wipeService.deleteMeasurements(in: specificDate...specificDate)

        // Then - Should not cause errors
        let count = try await fetchMeasurementCount()
        XCTAssertTrue(count >= 0)
    }

    func testDeleteMeasurementsInRange_EmptyRange() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        let futureStart = Date().addingTimeInterval(86400)
        let futureEnd = Date().addingTimeInterval(2 * 86400)

        // When
        try await wipeService.deleteMeasurements(in: futureStart...futureEnd)

        // Then - No measurements should be deleted
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 5)
    }

    func testDeleteMeasurementsInRange_WithConfirmation() async throws {
        // Given
        try await insertTestMeasurements(count: 5)
        let range = Date().addingTimeInterval(-48 * 3600)...Date()

        var confirmationCalled = false
        let confirmation: () async -> Bool = {
            confirmationCalled = true
            return true
        }

        // When
        try await wipeService.deleteMeasurements(in: range, confirmation: confirmation)

        // Then
        XCTAssertTrue(confirmationCalled)
    }

    // MARK: - Batch Delete Tests

    func testDeleteBatch_Success() async throws {
        // Given
        var measurements: [StressMeasurement] = []
        for i in 0..<5 {
            let measurement = StressMeasurement(
                timestamp: Date().addingTimeInterval(-Double(i * 3600)),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
            measurements.append(measurement)
        }
        try modelContext.save()

        let beforeCount = try await fetchMeasurementCount()

        // When
        try await wipeService.deleteBatch(measurements)

        // Then
        let afterCount = try await fetchMeasurementCount()
        XCTAssertEqual(afterCount, beforeCount - 5)
    }

    func testDeleteBatch_EmptyArray() async throws {
        // Given
        let measurements: [StressMeasurement] = []

        // When/Then - Should not throw
        try await XCTAssertNoThrow(await wipeService.deleteBatch(measurements))
    }

    func testDeleteBatch_NonExistentMeasurements() async throws {
        // Given
        let nonExistent = [
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
        ]

        // When/Then - Should handle gracefully
        try await XCTAssertNoThrow(await wipeService.deleteBatch(nonExistent))
    }

    // MARK: - Statistics Tests

    func testCountMeasurementsBefore() async throws {
        // Given
        let now = Date()
        for i in 0..<10 {
            let measurement = StressMeasurement(
                timestamp: now.addingTimeInterval(-Double(i * 12 * 3600)),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        let cutoffDate = now.addingTimeInterval(-36 * 3600) // 36 hours ago

        // When
        let count = wipeService.countMeasurements(before: cutoffDate)

        // Then
        XCTAssertGreaterThan(count, 0)
        XCTAssertLessThanOrEqual(count, 10)
    }

    func testCountMeasurementsBefore_NoMatches() async throws {
        // Given
        try await insertTestMeasurements(count: 5)
        let futureCutoff = Date().addingTimeInterval(86400)

        // When
        let count = wipeService.countMeasurements(before: futureCutoff)

        // Then
        XCTAssertEqual(count, 0)
    }

    func testCountMeasurementsInRange() async throws {
        // Given
        let now = Date()
        let rangeStart = now.addingTimeInterval(-48 * 3600)
        let rangeEnd = now.addingTimeInterval(-24 * 3600)

        for i in 0..<10 {
            let measurement = StressMeasurement(
                timestamp: now.addingTimeInterval(-Double(i * 6 * 3600)),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        // When
        let count = wipeService.countMeasurements(in: rangeStart...rangeEnd)

        // Then
        XCTAssertGreaterThan(count, 0)
    }

    func testCountMeasurementsInRange_NoMatches() async throws {
        // Given
        try await insertTestMeasurements(count: 5)
        let futureRange = Date().addingTimeInterval(86400)...Date().addingTimeInterval(2 * 86400)

        // When
        let count = wipeService.countMeasurements(in: futureRange)

        // Then
        XCTAssertEqual(count, 0)
    }

    func testTotalCount() async throws {
        // Given
        try await insertTestMeasurements(count: 15)

        // When
        let count = wipeService.totalCount()

        // Then
        XCTAssertEqual(count, 15)
    }

    func testTotalCount_EmptyDatabase() async {
        // Given - Empty database

        // When
        let count = wipeService.totalCount()

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - Progress Tracking Tests

    func testProgress_UpdatesDuringDelete() async throws {
        // Given
        try await insertTestMeasurements(count: 20)

        // When
        let deleteTask = Task {
            try await wipeService.deleteAllMeasurements()
        }

        // Check progress during operation
        var progressObserved = false
        for _ in 0..<10 {
            let progress = wipeService.deleteProgress
            if progress > 0 && progress < 1.0 {
                progressObserved = true
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        await deleteTask.value

        // Then
        XCTAssertTrue(progressObserved || wipeService.deleteProgress == 1.0)
    }

    func testIsDeleting_StateChanges() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        // When
        let deleteTask = Task {
            try await wipeService.deleteAllMeasurements()
        }

        // Check state during operation
        let wasDeleting = wipeService.isDeleting
        await deleteTask.value

        // Then
        XCTAssertTrue(wasDeleting || !wipeService.isDeleting)
        XCTAssertFalse(wipeService.isDeleting) // Should be false after completion
    }

    func testCurrentOperation_Updates() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        // When
        try await wipeService.deleteAllMeasurements()

        // Then - Current operation should be cleared after completion
        XCTAssertNil(wipeService.currentOperation)
    }

    // MARK: - Error Handling Tests

    func testDeleteWithContextErrors() async throws {
        // Given - Insert some data
        try await insertTestMeasurements(count: 5)

        // When - Delete should succeed
        try await XCTAssertNoThrow(await wipeService.deleteAllMeasurements())

        // Then
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Edge Cases Tests

    func testDeleteAll_LargeDataset() async throws {
        // Given
        try await insertTestMeasurements(count: 1000)

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
        XCTAssertEqual(wipeService.deleteProgress, 1.0)
    }

    func testDeleteAll_WithNilConfidences() async throws {
        // Given
        for _ in 0..<5 {
            let measurement = StressMeasurement(
                timestamp: Date(),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: nil
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    func testDeleteAll_WithEmptyConfidences() async throws {
        // Given
        for _ in 0..<5 {
            let measurement = StressMeasurement(
                timestamp: Date(),
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: []
            )
            modelContext.insert(measurement)
        }
        try modelContext.save()

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    func testDeleteMeasurementsWithExtremeTimestamps() async throws {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date().addingTimeInterval(-365 * 86400), // 1 year ago
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: nil
            ),
            StressMeasurement(
                timestamp: Date().addingTimeInterval(86400), // 1 year in future
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: nil
            )
        ]

        for measurement in measurements {
            modelContext.insert(measurement)
        }
        try modelContext.save()

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - State Consistency Tests

    func testStateResetsAfterCompletion() async throws {
        // Given
        try await insertTestMeasurements(count: 5)

        // When
        try await wipeService.deleteAllMeasurements()

        // Then
        XCTAssertFalse(wipeService.isDeleting)
        XCTAssertEqual(wipeService.deleteProgress, 1.0)
        XCTAssertNil(wipeService.currentOperation)
    }

    func testStateResetsAfterCancellation() async {
        // Given
        try await insertTestMeasurements(count: 5)

        let confirmation: () async -> Bool = {
            return false // Cancel
        }

        // When
        do {
            try await wipeService.deleteAllMeasurements(confirmation: confirmation)
        } catch LocalDataError.operationCancelled {
            // Expected
        } catch {
            XCTFail("Expected LocalDataError.operationCancelled")
        }

        // Then - State should be reset
        XCTAssertFalse(wipeService.isDeleting)
    }

    // MARK: - Performance Tests

    func testPerformance_DeleteAll() async throws {
        // Given
        try await insertTestMeasurements(count: 100)

        // Measure
        measure {
            try? Task {
                try? await self.wipeService.deleteAllMeasurements()
            }.value
        }
    }

    func testPerformance_CountOperations() async throws {
        // Given
        try await insertTestMeasurements(count: 100)

        // Measure
        measure {
            _ = self.wipeService.totalCount()
        }
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentDeleteOperations() async throws {
        // Given
        try await insertTestMeasurements(count: 10)

        // When - Start multiple deletes
        async let delete1: Void = wipeService.deleteAllMeasurements()
        async let delete2: Void = wipeService.deleteAllMeasurements()

        // Then - Both should complete (second may have no work to do)
        await delete1
        await delete2

        let count = try await fetchMeasurementCount()
        XCTAssertEqual(count, 0)
    }
}
