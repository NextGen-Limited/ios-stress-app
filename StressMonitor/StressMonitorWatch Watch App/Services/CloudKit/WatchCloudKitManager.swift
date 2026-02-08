import CloudKit
import Foundation
import Observation

@MainActor
@Observable
public final class WatchCloudKitManager: CloudKitServiceProtocol {
    // MARK: - Properties

    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var lastSyncDate: Date?

    private let container: CKContainer
    private let sharedDatabase: CKDatabase
    private let deviceID: String
    private let syncThrottleInterval: TimeInterval

    private var lastSyncAttempt: Date?
    private var subscriptionID = "com.stressmonitor.watch.subscription"

    // MARK: - Initialization

    public init(
        container: CKContainer = .default(),
        syncThrottleInterval: TimeInterval = 300.0 // 5 minutes
    ) {
        self.container = container
        self.sharedDatabase = container.sharedCloudDatabase
        self.deviceID = Self.getWatchDeviceID()
        self.syncThrottleInterval = syncThrottleInterval
    }

    // MARK: - Watch Device ID

    private static func getWatchDeviceID() -> String {
        let key = "com.stressmonitor.watch.deviceID"

        if let existingID = UserDefaults.standard.string(forKey: key) {
            return existingID
        }

        // Prefix with watch- for device priority resolution
        let newID = "watch-\(UUID().uuidString)"
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }

    // MARK: - Save Measurement

    public func saveMeasurement(_ measurement: WatchStressMeasurement) async throws {
        syncStatus = .syncing(progress: 0.0)

        let record = CKRecord(recordType: CloudKitRecordType.stressMeasurement.rawValue)
        record["timestamp"] = measurement.timestamp
        record["stressLevel"] = measurement.stressLevel
        record["hrv"] = measurement.hrv
        record["restingHeartRate"] = measurement.restingHeartRate
        record["category"] = measurement.categoryRawValue
        record["confidences"] = measurement.confidences ?? []
        record["deviceID"] = deviceID
        record["isDeleted"] = false
        record["cloudKitModTime"] = Date()

        do {
            try await sharedDatabase.save(record)
            lastSyncDate = Date()
            syncStatus = .success
        } catch let error as CKError {
            syncStatus = .error(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Fetch Measurements

    public func fetchMeasurements(since date: Date? = nil) async throws -> [WatchStressMeasurement] {
        // Throttle sync requests to save battery
        if let lastAttempt = lastSyncAttempt,
           Date().timeIntervalSince(lastAttempt) < syncThrottleInterval {
            return []
        }

        lastSyncAttempt = Date()
        syncStatus = .syncing(progress: 0.0)

        let predicate: NSPredicate
        if let sinceDate = date {
            predicate = NSPredicate(format: "timestamp >= %@", sinceDate as NSDate)
        } else {
            predicate = NSPredicate(value: true)
        }

        let query = CKQuery(recordType: CloudKitRecordType.stressMeasurement.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let (matchResults, _) = try await sharedDatabase.records(matching: query)

            var measurements: [WatchStressMeasurement] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let measurement = self.convertRecordToMeasurement(record) {
                        measurements.append(measurement)
                    }
                case .failure:
                    continue
                }
            }

            lastSyncDate = Date()
            syncStatus = .success
            return measurements
        } catch let error as CKError {
            syncStatus = .error(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Delete Measurement

    public func deleteMeasurement(_ measurement: WatchStressMeasurement) async throws {
        syncStatus = .syncing(progress: 0.0)

        let predicate = NSPredicate(format: "timestamp == %@ AND deviceID == %@",
                                    measurement.timestamp as NSDate,
                                    deviceID as NSString)
        let query = CKQuery(recordType: CloudKitRecordType.stressMeasurement.rawValue, predicate: predicate)

        do {
            let (matchResults, _) = try await sharedDatabase.records(matching: query)

            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    try await sharedDatabase.deleteRecord(withID: recordID)
                case .failure:
                    continue
                }
            }

            lastSyncDate = Date()
            syncStatus = .success
        } catch let error as CKError {
            syncStatus = .error(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Sync

    public func sync() async throws {
        syncStatus = .syncing(progress: 0.0)

        do {
            _ = try await fetchMeasurements()
            lastSyncDate = Date()
            syncStatus = .success
        } catch let error as CKError {
            syncStatus = .error(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Batch Operations (Smaller for Watch)

    public func saveBatchMeasurements(_ measurements: [WatchStressMeasurement]) async throws {
        guard !measurements.isEmpty else { return }

        // Watch uses smaller batch size (5 instead of 10)
        let batchSize = 5
        let batches = measurements.chunked(into: batchSize)

        for batch in batches {
            try await saveBatch(batch)
        }
    }

    private func saveBatch(_ batch: [WatchStressMeasurement]) async throws {
        let records = batch.map { measurement -> CKRecord in
            let record = CKRecord(recordType: CloudKitRecordType.stressMeasurement.rawValue)
            record["timestamp"] = measurement.timestamp
            record["stressLevel"] = measurement.stressLevel
            record["hrv"] = measurement.hrv
            record["restingHeartRate"] = measurement.restingHeartRate
            record["category"] = measurement.categoryRawValue
            record["confidences"] = measurement.confidences ?? []
            record["deviceID"] = deviceID
            record["isDeleted"] = false
            record["cloudKitModTime"] = Date()
            return record
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            sharedDatabase.add(operation)
        }
    }

    // MARK: - Push Subscription

    public func setupPushSubscription() async throws {
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordType.stressMeasurement.rawValue,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.alertBody = "New stress measurements available"
        subscription.notificationInfo = notificationInfo

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sharedDatabase.save(subscription) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Account Status

    public func checkAccountStatus() async throws -> CloudKitAccountStatus {
        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                return .available
            case .noAccount:
                return .noAccount
            case .restricted:
                return .restricted
            case .couldNotDetermine:
                return .unknown
            case .temporarilyUnavailable:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch let error as CKError {
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Standalone Operation Support

    public func canPerformStandaloneSync() async -> Bool {
        let accountStatus = try? await checkAccountStatus()
        return accountStatus == .available
    }

    // MARK: - Battery-Aware Sync

    public func shouldSyncNow() async -> Bool {
        // Check if enough time has passed since last sync
        guard let lastSync = lastSyncDate else {
            return true
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync >= syncThrottleInterval
    }

    // MARK: - Helper Methods

    private func convertRecordToMeasurement(_ record: CKRecord) -> WatchStressMeasurement? {
        guard let timestamp = record["timestamp"] as? Date,
              let stressLevel = record["stressLevel"] as? Double,
              let hrv = record["hrv"] as? Double,
              let restingHeartRate = record["restingHeartRate"] as? Double else {
            return nil
        }

        let confidences = record["confidences"] as? [Double]

        let measurement = WatchStressMeasurement(
            timestamp: timestamp,
            stressLevel: stressLevel,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            confidences: confidences
        )

        return measurement
    }

    // MARK: - Error Handling

    private func adaptCloudKitError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .networkFailure, .networkUnavailable:
            return CloudKitError.networkUnavailable(.noInternet)
        case .notAuthenticated:
            return CloudKitError.networkUnavailable(.iCloudNotSignedIn)
        case .quotaExceeded:
            return CloudKitError.networkUnavailable(.quotaExceeded)
        case .requestRateLimited:
            return CloudKitError.rateLimited
        case .zoneNotFound:
            return CloudKitError.zoneNotFound
        case .unknownItem:
            return CloudKitError.recordNotFound
        default:
            return CloudKitError.unknown(error)
        }
    }
}

// MARK: - Batch Chunking Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Watch CloudKit Error

public enum WatchCloudKitError: Error, Sendable {
    case syncThrottled
    case batteryLow
    case notPaired
    case companionAppNotInstalled

    public var localizedDescription: String {
        switch self {
        case .syncThrottled:
            return "Sync is throttled to conserve battery"
        case .batteryLow:
            return "Battery too low for sync"
        case .notPaired:
            return "Watch is not paired with iPhone"
        case .companionAppNotInstalled:
            return "Companion app is not installed"
        }
    }
}
