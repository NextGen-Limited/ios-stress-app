import Foundation
import SwiftData
import SwiftUI

@Model
final class StressMeasurement {
    var timestamp: Date
    var stressLevel: Double
    var hrv: Double
    var heartRate: Double
    var categoryRawValue: String

    init(timestamp: Date, stressLevel: Double, hrv: Double, heartRate: Double, category: StressCategory) {
        self.timestamp = timestamp
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.heartRate = heartRate
        self.categoryRawValue = category.rawValue
    }

    var category: StressCategory {
        get { StressCategory(rawValue: categoryRawValue) ?? .mild }
        set { categoryRawValue = newValue.rawValue }
    }
}
