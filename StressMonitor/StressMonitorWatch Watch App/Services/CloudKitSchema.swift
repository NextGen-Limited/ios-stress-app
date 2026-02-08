import CloudKit
import Foundation

// MARK: - Record Types
public enum CloudKitRecordType: String, Sendable {
    case stressMeasurement = "CD_StressMeasurement"
    case personalBaseline = "CD_PersonalBaseline"
    case syncMetadata = "CD_SyncMetadata"
}

// MARK: - StressMeasurement Record
public struct CloudKitStressMeasurement: Sendable {
    let recordID: CKRecord.ID
    let timestamp: Date
    let stressLevel: Double
    let hrv: Double
    let restingHeartRate: Double
    let category: String
    let confidences: [Double]
    let deviceID: String
    let isDeleted: Bool
    let cloudKitModTime: Date?

    init?(record: CKRecord) {
        guard record.recordType == CloudKitRecordType.stressMeasurement.rawValue else {
            return nil
        }

        self.recordID = record.recordID
        self.timestamp = record["timestamp"] as? Date ?? Date()
        self.stressLevel = record["stressLevel"] as? Double ?? 0
        self.hrv = record["hrv"] as? Double ?? 0
        self.restingHeartRate = record["restingHeartRate"] as? Double ?? 0
        self.category = record["category"] as? String ?? ""
        self.confidences = record["confidences"] as? [Double] ?? []
        self.deviceID = record["deviceID"] as? String ?? ""
        self.isDeleted = record["isDeleted"] as? Bool ?? false
        self.cloudKitModTime = record["cloudKitModTime"] as? Date
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.stressMeasurement.rawValue, recordID: recordID)
        record["timestamp"] = timestamp
        record["stressLevel"] = stressLevel
        record["hrv"] = hrv
        record["restingHeartRate"] = restingHeartRate
        record["category"] = category
        record["confidences"] = confidences
        record["deviceID"] = deviceID
        record["isDeleted"] = isDeleted
        return record
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
