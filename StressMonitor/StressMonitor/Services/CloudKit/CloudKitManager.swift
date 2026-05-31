import CloudKit
import Foundation
import Observation

@preconcurrency import CloudKit

@MainActor
@Observable
public final class CloudKitManager: CloudKitServiceProtocol {
    // MARK: - Properties

    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var lastSyncDate: Date?
    public private(set) var deviceID: String

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private var subscriptionID = "com.stressmonitor.subscription"

    // MARK: - Initialization

    public init(container: CKContainer = .default()) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.deviceID = Self.getDeviceID()
    }

    // MARK: - Device ID

    private static func getDeviceID() -> String {
        let key = "com.stressmonitor.deviceID"

        if let existingID = UserDefaults.standard.string(forKey: key) {
            return existingID
        }

        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }

    // MARK: - Save Measurement

    public func saveMeasurement(_ measurement: StressMeasurement) async throws {
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
            try await privateDatabase.save(record)
            lastSyncDate = Date()
            syncStatus = .success
        } catch let error as CKError {
            syncStatus = .error(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    // MARK: - Fetch Measurements

    public func fetchMeasurements(since date: Date? = nil) async throws -> [StressMeasurement] {
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
            let (matchResults, _) = try await privateDatabase.records(matching: query)

            var measurements: [StressMeasurement] = []
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

    public func deleteMeasurement(_ measurement: StressMeasurement) async throws {
        syncStatus = .syncing(progress: 0.0)

        // First, find the record ID
        let predicate = NSPredicate(format: "timestamp == %@ AND deviceID == %@",
                                    measurement.timestamp as NSDate,
                                    deviceID as NSString)
        let query = CKQuery(recordType: CloudKitRecordType.stressMeasurement.rawValue, predicate: predicate)

        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)

            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    try await privateDatabase.deleteRecord(withID: recordID)
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

    // MARK: - Push Subscription

    public func setupPushSubscription() async throws {
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordType.stressMeasurement.rawValue,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                privateDatabase.save(subscription) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch let error as CKError {
            if error.code == .serverRejectedRequest {
                return
            }
            throw adaptCloudKitError(error)
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

    // MARK: - Helper Methods

    private func convertRecordToMeasurement(_ record: CKRecord) -> StressMeasurement? {
        guard let timestamp = record["timestamp"] as? Date,
              let stressLevel = record["stressLevel"] as? Double,
              let hrv = record["hrv"] as? Double,
              let restingHeartRate = record["restingHeartRate"] as? Double,
              let categoryRawValue = record["category"] as? String else {
            return nil
        }

        let confidences = record["confidences"] as? [Double]

        let measurement = StressMeasurement(
            timestamp: timestamp,
            stressLevel: stressLevel,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            confidences: confidences
        )
        measurement.categoryRawValue = categoryRawValue

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

// MARK: - CloudKitError

public enum CloudKitError: Error, Sendable {
    case networkUnavailable(NetworkReason)
    case rateLimited
    case zoneNotFound
    case recordNotFound
    case unknown(Error)

    public var localizedDescription: String {
        switch self {
        case .networkUnavailable(let reason):
            switch reason {
            case .noInternet:
                return "No internet connection available"
            case .iCloudNotSignedIn:
                return "iCloud is not signed in"
            case .cloudKitDisabled:
                return "CloudKit is disabled"
            case .quotaExceeded:
                return "iCloud storage quota exceeded"
            }
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .zoneNotFound:
            return "CloudKit zone not found"
        case .recordNotFound:
            return "Record not found"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Sendable Conformance for StressMeasurement

extension StressMeasurement: @unchecked Sendable {}
