import Foundation
import SwiftData
import SwiftUI

@Model
public final class StressMeasurement {
  public var timestamp: Date
  public var stressLevel: Double
  public var hrv: Double
  public var restingHeartRate: Double
  public var categoryRawValue: String
  public var confidences: [Double]?

  // MARK: - CloudKit Sync Properties
  public var isSynced: Bool
  public var cloudKitRecordName: String?
  public var deviceID: String
  public var cloudKitModTime: Date?

  public init(
    timestamp: Date,
    stressLevel: Double,
    hrv: Double,
    restingHeartRate: Double,
    confidences: [Double]? = nil,
    isSynced: Bool = false,
    cloudKitRecordName: String? = nil,
    deviceID: String = CloudKitDeviceID.current,
    cloudKitModTime: Date? = nil
  ) {
    self.timestamp = timestamp
    self.stressLevel = stressLevel
    self.hrv = hrv
    self.restingHeartRate = restingHeartRate
    self.categoryRawValue = StressResult.category(for: stressLevel).rawValue
    self.confidences = confidences
    self.isSynced = isSynced
    self.cloudKitRecordName = cloudKitRecordName
    self.deviceID = deviceID
    self.cloudKitModTime = cloudKitModTime
  }

  public var category: StressCategory {
    get { StressCategory(rawValue: categoryRawValue) ?? .mild }
    set { categoryRawValue = newValue.rawValue }
  }
}

// MARK: - CloudKit Device ID Helper

public enum CloudKitDeviceID {
  private static let key = "com.stressmonitor.deviceID"

  public static var current: String {
    if let existingID = UserDefaults.standard.string(forKey: key) {
      return existingID
    }

    let newID = UUID().uuidString
    UserDefaults.standard.set(newID, forKey: key)
    return newID
  }
}
