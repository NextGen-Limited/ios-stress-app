import Foundation
import SwiftData
import CloudKit

/// SwiftData model for CloudKit-synced stress measurements.
/// Compound index on (timestamp, deviceID) enables O(1) lookups during merge.
@Model
final class StressMeasurement {
    // MARK: - Properties
    
    /// Unique identifier for the measurement
    var id: UUID
    
    /// When the measurement was taken
    var timestamp: Date
    
    /// Device that recorded the measurement (for dedup across devices)
    var deviceID: String
    
    /// Computed stress level 0.0 - 1.0
    var stressLevel: Double
    
    /// Heart Rate Variability (SDNN) in milliseconds
    var hrv: Double
    
    /// Heart rate in BPM
    var heartRate: Double
    
    /// How the measurement was sourced
    var source: String  // "appleWatch", "manual", "estimated"
    
    /// When this record was last synced from CloudKit
    var lastSyncedAt: Date?
    
    /// CloudKit record metadata (encoded as Data for portability)
    @Attribute(.externalStorage) 
    var cloudKitMetadata: Data?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        deviceID: String = StressMeasurement.currentDeviceID,
        stressLevel: Double,
        hrv: Double,
        heartRate: Double,
        source: String = "appleWatch",
        lastSyncedAt: Date? = nil,
        cloudKitMetadata: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.deviceID = deviceID
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.heartRate = heartRate
        self.source = source
        self.lastSyncedAt = lastSyncedAt
        self.cloudKitMetadata = cloudKitMetadata
    }
    
    // MARK: - Helpers
    
    /// Current device identifier (stable across app launches)
    static var currentDeviceID: String {
        #if os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "unknown-watch"
        #elseif os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-iphone"
        #else
        return "unknown-device"
        #endif
    }
    
    /// Convert from the legacy StressReading struct
    static func from(reading: StressReading) -> StressMeasurement {
        StressMeasurement(
            id: reading.id,
            timestamp: reading.timestamp,
            stressLevel: reading.level,
            hrv: reading.hrv,
            heartRate: reading.heartRate,
            source: reading.source.rawValue
        )
    }
    
    /// Convert to the legacy StressReading struct
    func toReading() -> StressReading {
        StressReading(
            id: id,
            timestamp: timestamp,
            level: stressLevel,
            hrv: hrv,
            heartRate: heartRate,
            source: StressReading.DataSource(rawValue: source) ?? .estimated
        )
    }
}

// MARK: - CloudKit Record Type

extension StressMeasurement {
    /// CloudKit record type name
    static let recordType = "StressMeasurement"
    
    /// Convert to a CloudKit record for manual sync operations
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["timestamp"] = timestamp
        record["deviceID"] = deviceID
        record["stressLevel"] = stressLevel
        record["hrv"] = hrv
        record["heartRate"] = heartRate
        record["source"] = source
        return record
    }
}

// MARK: - WatchKit import (conditional)

#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif
