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
    static let appGroupID = "group.stress.ai.com"
    static let latestMeasurementKey = "latestMeasurement"
    static let widgetHistoryKey = "widgetHistory"
    static let lastUpdateKey = "lastUpdate"
}

// MARK: - Widget Publishing (main-app write side)

/// Writes the latest measurement into the App Group suite that
/// `WidgetDataProvider` (widget extension target) reads from, then reloads
/// the widget timeline. Without this, `StressWidgetProvider` always falls
/// back to its hardcoded placeholder — there was previously no call site
/// anywhere in the main app target that wrote this data.
///
/// Key names below MUST match `WidgetDataProvider.Keys` exactly — the two
/// live in separate compile targets and can't share a type (no shared
/// module in this project), so they're duplicated by convention, not code.
///
/// Scope note: publishes latest-measurement only. History (sparkline) and
/// baseline publishing are not yet wired — `StressWidgetProvider` degrades
/// gracefully to an empty trend line when history is absent, so this still
/// converts the widget from "always fake" to "shows real current data."
enum WidgetPublisher {
    private enum Keys {
        static let latestStressLevel = "latest_stress_level"
        static let latestStressCategory = "latest_stress_category"
        static let latestHRV = "latest_hrv"
        static let latestHeartRate = "latest_heart_rate"
        static let latestTimestamp = "latest_timestamp"
        static let latestConfidence = "latest_confidence"
    }

    static func publish(_ measurement: StressMeasurement) {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) else { return }

        let confidences = measurement.confidences ?? []
        let confidence = confidences.isEmpty ? 1.0 : confidences.reduce(0, +) / Double(confidences.count)

        defaults.set(measurement.stressLevel, forKey: Keys.latestStressLevel)
        defaults.set(measurement.categoryRawValue, forKey: Keys.latestStressCategory)
        defaults.set(measurement.hrv, forKey: Keys.latestHRV)
        defaults.set(measurement.restingHeartRate, forKey: Keys.latestHeartRate)
        defaults.set(confidence, forKey: Keys.latestConfidence)
        defaults.set(measurement.timestamp.timeIntervalSince1970, forKey: Keys.latestTimestamp)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Resolves whether the widget's latest measurement is fresh, stale, or absent.
///
/// Must stay byte-identical to its copy in StressWidgetProvider.swift — the two
/// live in separate compile targets and can't share a type (no shared module in
/// this project), so they're duplicated by convention, same as WidgetPublisher/
/// WidgetDataProvider.Keys.
enum WidgetDataState: Equatable, Sendable {
    case fresh, stale, empty

    static func resolve(latestTimestamp: Date?, now: Date, stalenessThreshold: TimeInterval = 24 * 3600) -> WidgetDataState {
        guard let latestTimestamp else { return .empty }
        return now.timeIntervalSince(latestTimestamp) > stalenessThreshold ? .stale : .fresh
    }
}
