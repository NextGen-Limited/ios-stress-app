import CloudKit
import Foundation

// MARK: - Record Types
enum CloudKitRecordType: String, Sendable {
    case stressMeasurement = "CD_StressMeasurement"
    case personalBaseline = "CD_PersonalBaseline"
    case syncMetadata = "CD_SyncMetadata"
}

// MARK: - StressMeasurement Record
struct CloudKitStressMeasurement: Sendable {
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

// MARK: - PersonalBaseline Record
struct CloudKitPersonalBaseline: Sendable {
    let recordID: CKRecord.ID
    let restingHeartRate: Double
    let baselineHRV: Double
    let lastUpdated: Date

    init?(record: CKRecord) {
        guard record.recordType == CloudKitRecordType.personalBaseline.rawValue else {
            return nil
        }

        self.recordID = record.recordID
        self.restingHeartRate = record["restingHeartRate"] as? Double ?? 60
        self.baselineHRV = record["baselineHRV"] as? Double ?? 50
        self.lastUpdated = record["lastUpdated"] as? Date ?? Date()
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.personalBaseline.rawValue, recordID: recordID)
        record["restingHeartRate"] = restingHeartRate
        record["baselineHRV"] = baselineHRV
        record["lastUpdated"] = lastUpdated
        return record
    }
}
