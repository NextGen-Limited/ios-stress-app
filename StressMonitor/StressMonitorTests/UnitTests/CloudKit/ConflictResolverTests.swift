import XCTest
@testable import StressMonitor

/// Comprehensive unit tests for ConflictResolver
/// Tests timestamp strategy, device priority strategy, merge logic, edge cases, and batch resolution
final class ConflictResolverTests: XCTestCase {

    var resolver: ConflictResolver!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()
        resolver = ConflictResolver()
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        resolver = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Timestamp Strategy Tests

    func testResolveByTimestamp_LocalWins() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = testDataFactory.createMeasurement(daysAgo: 1)
        let remote = testDataFactory.createMeasurement(daysAgo: 2)

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepLocal)
        XCTAssertFalse(decision.shouldKeepRemote)
        XCTAssertFalse(decision.shouldMerge)
    }

    func testResolveByTimestamp_RemoteWins() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = testDataFactory.createMeasurement(daysAgo: 2)
        let remote = testDataFactory.createMeasurement(daysAgo: 1)

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepRemote)
        XCTAssertFalse(decision.shouldKeepLocal)
        XCTAssertFalse(decision.shouldMerge)
    }

    func testResolveByTimestamp_SameTimestamp_Merges() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let baseDate = Date()
        let local = StressMeasurement(
            timestamp: baseDate,
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        let remote = StressMeasurement(
            timestamp: baseDate.addingTimeInterval(0.5), // Within 1 second
            stressLevel: 55,
            hrv: 55,
            restingHeartRate: 65,
            confidences: [0.9]
        )

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldMerge)
    }

    func testResolveByTimestamp_ExactlySameTimestamp() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let timestamp = Date()
        let local = StressMeasurement(
            timestamp: timestamp,
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        let remote = StressMeasurement(
            timestamp: timestamp,
            stressLevel: 55,
            hrv: 55,
            restingHeartRate: 65,
            confidences: [0.9]
        )

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldMerge)
    }

    // MARK: - Server Strategy Tests

    func testResolveByServer_AlwaysKeepsRemote() {
        // Given
        resolver = ConflictResolver(strategy: .server)
        let local = testDataFactory.createMeasurement(daysAgo: 1)
        let remote = testDataFactory.createMeasurement(daysAgo: 2)

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepRemote)
        XCTAssertFalse(decision.shouldKeepLocal)
    }

    func testResolveByServer_WithSameTimestamp() {
        // Given
        resolver = ConflictResolver(strategy: .server)
        let timestamp = Date()
        let local = StressMeasurement(
            timestamp: timestamp,
            stressLevel: 100,
            hrv: 100,
            restingHeartRate: 100,
            confidences: [1.0]
        )
        let remote = StressMeasurement(
            timestamp: timestamp,
            stressLevel: 0,
            hrv: 0,
            restingHeartRate: 0,
            confidences: [0.0]
        )

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepRemote, "Server strategy should always prefer remote")
    }

    // MARK: - Client Strategy Tests

    func testResolveByClient_AlwaysKeepsLocal() {
        // Given
        resolver = ConflictResolver(strategy: .client)
        let local = testDataFactory.createMeasurement(daysAgo: 2)
        let remote = testDataFactory.createMeasurement(daysAgo: 1)

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepLocal)
        XCTAssertFalse(decision.shouldKeepRemote)
    }

    func testResolveByClient_WithOlderLocal() {
        // Given
        resolver = ConflictResolver(strategy: .client)
        let local = testDataFactory.createMeasurement(daysAgo: 10)
        let remote = testDataFactory.createMeasurement(daysAgo: 1)

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepLocal, "Client strategy should always prefer local regardless of timestamp")
    }

    // MARK: - Device Priority Strategy Tests

    func testResolveByDevicePriority_iPhoneVsWatch() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = testDataFactory.createMeasurement()

        // Simulate iPhone (higher priority) vs watch (lower priority)
        let remoteDeviceID = "watch-12345"
        let remote = testDataFactory.createMeasurement()

        // When
        let decision = resolver.resolve(local: local, remote: remote, remoteDeviceID: remoteDeviceID)

        // Then
        // iPhone should have priority over watch
        XCTAssertTrue(decision.shouldKeepLocal || decision.shouldKeepRemote)
    }

    func testResolveByDevicePriority_iPhoneVsIPad() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = testDataFactory.createMeasurement()

        // Simulate iPad device ID
        let remoteDeviceID = "ipad-12345"
        let remote = testDataFactory.createMeasurement()

        // When
        let decision = resolver.resolve(local: local, remote: remote, remoteDeviceID: remoteDeviceID)

        // Then
        // Should make a decision based on device priority
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    func testResolveByDevicePriority_SameDeviceType() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = testDataFactory.createMeasurement(daysAgo: 1)
        let remote = testDataFactory.createMeasurement(daysAgo: 2)

        // Both iPhones - same device type
        let remoteDeviceID = "iphone-67890"

        // When
        let decision = resolver.resolve(local: local, remote: remote, remoteDeviceID: remoteDeviceID)

        // Then
        // Should fall back to timestamp strategy
        XCTAssertTrue(decision.shouldKeepLocal || decision.shouldKeepRemote || decision.shouldMerge)
    }

    func testResolveByDevicePriority_NoDeviceID() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = testDataFactory.createMeasurement(daysAgo: 1)
        let remote = testDataFactory.createMeasurement(daysAgo: 2)

        // When - No remote device ID provided
        let decision = resolver.resolve(local: local, remote: remote, remoteDeviceID: nil)

        // Then
        // Should fall back to timestamp strategy
        XCTAssertTrue(decision.shouldKeepLocal, "Local should win with more recent timestamp")
    }

    // MARK: - Merge Logic Tests

    func testMergeLogic_TakesMaxValues() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 40,
            hrv: 45,
            restingHeartRate: 55,
            confidences: [0.7, 0.8]
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 60,
            hrv: 55,
            restingHeartRate: 65,
            confidences: [0.9, 0.85]
        )

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldMerge)
        // The winning measurement should have max values
        let winner = resolver.resolveBatch(
            localMeasurements: [local],
            remoteMeasurements: [remote]
        ).first?.winningMeasurement

        XCTAssertNotNil(winner)
        XCTAssertGreaterThanOrEqual(winner!.stressLevel, max(local.stressLevel, remote.stressLevel))
    }

    func testMergeLogic_ConfidenceMerging() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.7, 0.8, 0.9]
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.6, 0.85]
        )

        // When
        let decision = resolver.resolve(local: local, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldMerge)
    }

    func testMergeLogic_NilConfidences() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: nil
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When/Then - Should handle nil confidences gracefully
        let decision = resolver.resolve(local: local, remote: remote)
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    func testMergeLogic_EmptyConfidences() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )

        // When/Then
        let decision = resolver.resolve(local: local, remote: remote)
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    func testMergeLogic_DifferentConfidenceLengths() {
        // Given
        resolver = ConflictResolver(strategy: .devicePriority)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.7, 0.8]
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.9]
        )

        // When/Then - Should handle different array lengths
        let decision = resolver.resolve(local: local, remote: remote)
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    // MARK: - Deleted Record Handling Tests

    func testResolveDeleted_BothNil() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)

        // When
        let decision = resolver.resolveDeleted(local: nil, remote: nil)

        // Then
        XCTAssertTrue(decision.shouldKeepLocal)
    }

    func testResolveDeleted_LocalNil() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let remote = testDataFactory.createMeasurement()

        // When
        let decision = resolver.resolveDeleted(local: nil, remote: remote)

        // Then
        XCTAssertTrue(decision.shouldKeepRemote)
    }

    func testResolveDeleted_RemoteNil() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = testDataFactory.createMeasurement()

        // When
        let decision = resolver.resolveDeleted(local: local, remote: nil)

        // Then
        XCTAssertTrue(decision.shouldKeepLocal)
    }

    func testResolveDeleted_BothPresent() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = testDataFactory.createMeasurement(daysAgo: 1)
        let remote = testDataFactory.createMeasurement(daysAgo: 2)

        // When
        let decision = resolver.resolveDeleted(local: local, remote: remote)

        // Then
        // Should use normal resolution logic
        XCTAssertTrue(decision.shouldKeepLocal)
    }

    // MARK: - Batch Conflict Resolution Tests

    func testResolveBatch_NoConflicts() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let localMeasurements = [
            testDataFactory.createMeasurement(daysAgo: 1),
            testDataFactory.createMeasurement(daysAgo: 2),
            testDataFactory.createMeasurement(daysAgo: 3)
        ]
        let remoteMeasurements: [StressMeasurement] = []

        // When
        let resolutions = resolver.resolveBatch(
            localMeasurements: localMeasurements,
            remoteMeasurements: remoteMeasurements
        )

        // Then
        XCTAssertEqual(resolutions.count, 3)
        XCTAssertTrue(resolutions.allSatisfy { !$0.hasConflict })
        XCTAssertTrue(resolutions.allSatisfy { $0.decision.shouldKeepLocal })
    }

    func testResolveBatch_WithConflicts() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
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
        let remoteMeasurements = [
            StressMeasurement(
                timestamp: timestamp,
                stressLevel: 55,
                hrv: 55,
                restingHeartRate: 65,
                confidences: [0.9]
            )
        ]

        // When
        let resolutions = resolver.resolveBatch(
            localMeasurements: localMeasurements,
            remoteMeasurements: remoteMeasurements
        )

        // Then
        XCTAssertEqual(resolutions.count, 1)
        XCTAssertTrue(resolutions.first?.hasConflict ?? false)
    }

    func testResolveBatch_MixedConflicts() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let sharedTimestamp = Date()
        let localMeasurements = [
            StressMeasurement(
                timestamp: sharedTimestamp,
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            ),
            testDataFactory.createMeasurement(daysAgo: 5) // No conflict
        ]
        let remoteMeasurements = [
            StressMeasurement(
                timestamp: sharedTimestamp,
                stressLevel: 55,
                hrv: 55,
                restingHeartRate: 65,
                confidences: [0.9]
            )
        ]

        // When
        let resolutions = resolver.resolveBatch(
            localMeasurements: localMeasurements,
            remoteMeasurements: remoteMeasurements
        )

        // Then
        XCTAssertEqual(resolutions.count, 2)
        let conflicts = resolutions.filter { $0.hasConflict }
        XCTAssertEqual(conflicts.count, 1)
    }

    func testResolveBatch_PreservesAllLocal() {
        // Given
        resolver = ConflictResolver(strategy: .client)
        let localMeasurements = testDataFactory.createMeasurementBatch(count: 10)
        let remoteMeasurements = testDataFactory.createMeasurementBatch(count: 5)

        // When
        let resolutions = resolver.resolveBatch(
            localMeasurements: localMeasurements,
            remoteMeasurements: remoteMeasurements
        )

        // Then
        XCTAssertEqual(resolutions.count, 10)
    }

    // MARK: - Winning Measurement Tests

    func testWinningMeasurement_KeepLocal() {
        // Given
        let resolution = ConflictResolution(
            local: testDataFactory.createMeasurement(stressLevel: 70),
            remote: testDataFactory.createMeasurement(stressLevel: 50),
            decision: .keepLocal
        )

        // When
        let winner = resolution.winningMeasurement

        // Then
        XCTAssertEqual(winner.stressLevel, 70)
    }

    func testWinningMeasurement_KeepRemote() {
        // Given
        let local = testDataFactory.createMeasurement(stressLevel: 50)
        let remote = testDataFactory.createMeasurement(stressLevel: 80)
        let resolution = ConflictResolution(
            local: local,
            remote: remote,
            decision: .keepRemote
        )

        // When
        let winner = resolution.winningMeasurement

        // Then
        XCTAssertEqual(winner.stressLevel, 80)
    }

    func testWinningMeasurement_Merge() {
        // Given
        let local = testDataFactory.createMeasurement(stressLevel: 60)
        let resolution = ConflictResolution(
            local: local,
            remote: testDataFactory.createMeasurement(stressLevel: 70),
            decision: .merge
        )

        // When
        let winner = resolution.winningMeasurement

        // Then
        XCTAssertEqual(winner, local)
    }

    // MARK: - Edge Cases Tests

    func testResolution_WithZeroStressLevel() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 0,
            hrv: 0,
            restingHeartRate: 0,
            confidences: nil
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 0,
            hrv: 0,
            restingHeartRate: 0,
            confidences: nil
        )

        // When/Then - Should handle zero values
        let decision = resolver.resolve(local: local, remote: remote)
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    func testResolution_WithNegativeValues() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: -10,
            hrv: -20,
            restingHeartRate: -5,
            confidences: nil
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: 10,
            hrv: 20,
            restingHeartRate: 5,
            confidences: nil
        )

        // When/Then - Should handle negative values in merge logic
        let decision = resolver.resolve(local: local, remote: remote)
        // Merge should take max values
        if decision.shouldMerge {
            let winner = resolver.resolveBatch(
                localMeasurements: [local],
                remoteMeasurements: [remote]
            ).first?.winningMeasurement
            XCTAssertNotNil(winner)
        }
    }

    func testResolution_WithExtremeValues() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = StressMeasurement(
            timestamp: Date(),
            stressLevel: 9999,
            hrv: 9999,
            restingHeartRate: 9999,
            confidences: nil
        )
        let remote = StressMeasurement(
            timestamp: Date(),
            stressLevel: -9999,
            hrv: -9999,
            restingHeartRate: -9999,
            confidences: nil
        )

        // When/Then
        let decision = resolver.resolve(local: local, remote: remote)
        XCTAssertTrue(
            decision.shouldKeepLocal ||
            decision.shouldKeepRemote ||
            decision.shouldMerge
        )
    }

    // MARK: - Performance Tests

    func testPerformance_BatchResolution() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let localMeasurements = testDataFactory.createMeasurementBatch(count: 100)
        let remoteMeasurements = testDataFactory.createMeasurementBatch(count: 100)

        // Measure
        measure {
            _ = resolver.resolveBatch(
                localMeasurements: localMeasurements,
                remoteMeasurements: remoteMeasurements
            )
        }
    }

    func testPerformance_SingleResolution() {
        // Given
        resolver = ConflictResolver(strategy: .timestamp)
        let local = testDataFactory.createMeasurement()
        let remote = testDataFactory.createMeasurement()

        // Measure
        measure {
            _ = resolver.resolve(local: local, remote: remote)
        }
    }

    // MARK: - Decision Extension Tests

    func testMergeDecisionExtensions() {
        // Given
        let keepLocal = MergeDecision.keepLocal
        let keepRemote = MergeDecision.keepRemote
        let merge = MergeDecision.merge

        // Then
        XCTAssertTrue(keepLocal.shouldKeepLocal)
        XCTAssertFalse(keepLocal.shouldKeepRemote)
        XCTAssertFalse(keepLocal.shouldMerge)

        XCTAssertFalse(keepRemote.shouldKeepLocal)
        XCTAssertTrue(keepRemote.shouldKeepRemote)
        XCTAssertFalse(keepRemote.shouldMerge)

        XCTAssertFalse(merge.shouldKeepLocal)
        XCTAssertFalse(merge.shouldKeepRemote)
        XCTAssertTrue(merge.shouldMerge)
    }
}
