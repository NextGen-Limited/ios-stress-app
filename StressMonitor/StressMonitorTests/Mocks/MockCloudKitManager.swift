import Foundation
import CloudKit
import UIKit
@testable import StressMonitor

@preconcurrency import CloudKit

class MockCloudKitManager: CloudKitServiceProtocol {
    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?

    private var storedMeasurements: [CloudKitStressMeasurement] = []
    private var shouldThrowError = false
    private var errorToThrow: Error? = nil
    private var syncDelay: TimeInterval = 0

    // MARK: - Test Configuration

    func setSyncDelay(_ delay: TimeInterval) {
        self.syncDelay = delay
    }

    func setError(_ error: Error?) {
        self.shouldThrowError = error != nil
        self.errorToThrow = error
    }

    func setStoredMeasurements(_ measurements: [CloudKitStressMeasurement]) {
        self.storedMeasurements = measurements
    }

    // MARK: - CloudKitServiceProtocol

    nonisolated func saveMeasurement(_ measurement: StressMeasurement) async throws {
        if shouldThrowError { throw errorToThrow ?? CloudKitError.unknown }

        if syncDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
        }

        await MainActor.run {
            syncStatus = .syncing(progress: 0.5)
        }

        let recordID = CKRecord.ID(recordName: UUID().uuidString)

        // Create a CKRecord to extract the CloudKitStressMeasurement
        let record = CKRecord(recordType: CloudKitRecordType.stressMeasurement.rawValue, recordID: recordID)
        record["timestamp"] = measurement.timestamp
        record["stressLevel"] = measurement.stressLevel
        record["hrv"] = measurement.hrv
        record["restingHeartRate"] = measurement.restingHeartRate
        record["category"] = measurement.category.rawValue
        record["confidences"] = measurement.confidences ?? []
        record["deviceID"] = UIDevice.current.identifierForVendor?.uuidString ?? "test-device"
        record["isDeleted"] = false

        guard let ckMeasurement = CloudKitStressMeasurement(record: record) else {
            throw CloudKitError.unknown
        }

        await MainActor.run {
            storedMeasurements.append(ckMeasurement)
            syncStatus = .success
            lastSyncDate = Date()
        }
    }

    nonisolated func fetchMeasurements(since date: Date?) async throws -> [StressMeasurement] {
        if shouldThrowError { throw errorToThrow ?? CloudKitError.unknown }

        if syncDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
        }

        await MainActor.run {
            syncStatus = .syncing(progress: 0.5)
        }

        let filtered = await storedMeasurements.filter { measurement in
            if let since = date {
                return measurement.timestamp >= since
            }
            return true
        }

        await MainActor.run {
            syncStatus = .success
        }

        return filtered.map { ckMeasurement in
            StressMeasurement(
                timestamp: ckMeasurement.timestamp,
                stressLevel: ckMeasurement.stressLevel,
                hrv: ckMeasurement.hrv,
                restingHeartRate: ckMeasurement.restingHeartRate,
                confidences: ckMeasurement.confidences
            )
        }
    }

    nonisolated func deleteMeasurement(_ measurement: StressMeasurement) async throws {
        if shouldThrowError { throw errorToThrow ?? CloudKitError.unknown }

        await MainActor.run {
            storedMeasurements.removeAll { $0.timestamp == measurement.timestamp }
        }
    }

    nonisolated func sync() async throws {
        if shouldThrowError { throw errorToThrow ?? CloudKitError.unknown }

        await MainActor.run {
            syncStatus = .syncing(progress: 0.5)
        }

        if syncDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
        }

        await MainActor.run {
            syncStatus = .success
            lastSyncDate = Date()
        }
    }

    nonisolated func setupPushSubscription() async throws {
        // Mock implementation
    }

    nonisolated func checkAccountStatus() async throws -> CloudKitAccountStatus {
        return .available
    }

    // MARK: - Test Helpers

    func reset() {
        storedMeasurements.removeAll()
        syncStatus = .idle
        lastSyncDate = nil
        shouldThrowError = false
        errorToThrow = nil
        syncDelay = 0
    }
}

enum CloudKitError: Error {
    case unknown
    case networkFailure
    case quotaExceeded
    case accountUnavailable
}
