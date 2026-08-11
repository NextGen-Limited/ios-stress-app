import CloudKit
import Foundation

// MARK: - Record Types
enum CloudKitRecordType: String, Sendable {
    case stressMeasurement = "CD_StressMeasurement"
    case personalBaseline = "CD_PersonalBaseline"
    case syncMetadata = "CD_SyncMetadata"
}
