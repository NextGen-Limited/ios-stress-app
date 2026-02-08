import Foundation
import WidgetKit

// MARK: - Complication Entry (watchOS)
struct ComplicationEntry: TimelineEntry, Sendable, Codable {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
    let hrv: Double
    let heartRate: Double
    let trendData: [Double]
    let lastUpdated: Date

    var confidence: Double {
        (hrv > 20 && hrv < 200 && heartRate > 40 && heartRate < 180) ? 0.9 : 0.6
    }
}

// MARK: - Widget Entry (iOS)
struct WidgetEntry: TimelineEntry, Sendable, Codable {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
    let hrv: Double
    let heartRate: Double
    let hrvHistory: [Double]
    let lastUpdated: Date

    var hrvAverage: Double {
        guard !hrvHistory.isEmpty else { return hrv }
        return hrvHistory.reduce(0, +) / Double(hrvHistory.count)
    }

    var hrvMax: Double {
        hrvHistory.max() ?? hrv
    }

    var trend: WidgetTrend {
        guard hrvHistory.count >= 2 else { return .stable }
        let recent = hrvHistory.suffix(min(6, hrvHistory.count))
        let avg = recent.reduce(0, +) / Double(recent.count)
        let latest = recent.last ?? avg

        if latest > avg * 1.1 { return .improving }
        if latest < avg * 0.9 { return .declining }
        return .stable
    }
}

// MARK: - Widget Trend
enum WidgetTrend: String, Sendable, Codable {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "minus"
        case .declining: return "arrow.up.right"
        }
    }
}

// MARK: - Shared Data Schema (App Groups)
struct ComplicationSharedData: Codable, Sendable {
    let currentStress: WidgetStressSnapshot
    let hrvHistory: [Double]
    let lastSync: Date

    var trend: StressTrend {
        guard hrvHistory.count >= 2 else { return .stable }
        let recent = hrvHistory.suffix(6)
        let avg = recent.reduce(0, +) / Double(recent.count)
        let latest = recent.last ?? avg

        if latest > avg * 1.1 { return .improving }
        if latest < avg * 0.9 { return .declining }
        return .stable
    }
}

// Renamed to avoid conflict with StressSnapshot in ExportModels.swift
struct WidgetStressSnapshot: Codable, Sendable {
    let level: Double
    let category: String
    let hrv: Double
    let heartRate: Double
    let timestamp: Date
}

enum StressTrend: String, Codable {
    case improving
    case stable
    case declining
}

// MARK: - App Groups Constants
enum WidgetConstants {
    static let appGroupID = "group.com.stressmonitor.app"
    static let latestMeasurementKey = "latestMeasurement"
    static let widgetHistoryKey = "widgetHistory"
    static let lastUpdateKey = "lastUpdate"
}
