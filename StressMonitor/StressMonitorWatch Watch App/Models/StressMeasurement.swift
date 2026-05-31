import Foundation
import SwiftUI

@Observable
public final class WatchStressMeasurement: Sendable {
    public let timestamp: Date
    public let stressLevel: Double
    public let hrv: Double
    public let restingHeartRate: Double
    public private(set) var categoryRawValue: String
    public let confidences: [Double]?

    public init(
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
        self.categoryRawValue = (WatchStressCategory(rawValue: Int(stressLevel)) ?? .mild).rawValue
        self.confidences = confidences
    }

    public var category: WatchStressCategory {
        get { WatchStressCategory(rawValue: Int(stressLevel)) ?? .mild }
        set { categoryRawValue = newValue.rawValue }
    }
}

public enum WatchStressCategory: Int, Sendable {
    case relaxed = 0
    case mild = 25
    case moderate = 50
    case high = 75

    public var rawValue: String {
        switch self {
        case .relaxed: return "relaxed"
        case .mild: return "mild"
        case .moderate: return "moderate"
        case .high: return "high"
        }
    }
}
