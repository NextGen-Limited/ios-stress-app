import Foundation
import SwiftData
import SwiftUI

@Model
final class StressMeasurement {
  var timestamp: Date
  var stressLevel: Double
  var hrv: Double
  var restingHeartRate: Double
  var categoryRawValue: String
  var confidences: [Double]?

  init(
    timestamp: Date,
    stressLevel: Double,
    hrv: Double,
    restingHeartRate: Double,
    confidences: [Double]? = nil
  ) {
    self.timestamp = timestamp
    self.stressLevel = stressLevel
    self.hrv = hrv
    self.restingHeartRate = restingHeartRate
    self.categoryRawValue = StressResult.category(for: stressLevel).rawValue
    self.confidences = confidences
  }

  var category: StressCategory {
    get { StressCategory(rawValue: categoryRawValue) ?? .mild }
    set { categoryRawValue = newValue.rawValue }
  }
}
