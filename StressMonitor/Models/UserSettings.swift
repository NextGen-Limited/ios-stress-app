import Foundation

/// User-configurable settings persisted via UserDefaults (@AppStorage).
/// Covers notification preferences, stress thresholds, baseline overrides,
/// display preferences, and data management toggles.
struct UserSettings {

    // MARK: - Notification Preferences

    /// Whether stress level alerts are enabled
    static let notificationsEnabledKey = "notificationsEnabled"
    /// Stress threshold (0.0–1.0) that triggers a high-stress alert
    static let alertThresholdKey = "alertStressThreshold"
    /// Whether to send daily stress summary notifications
    static let dailySummaryEnabledKey = "dailySummaryEnabled"

    // MARK: - Baseline Configuration

    /// Whether to use manual baselines instead of auto-computed ones
    static let useManualBaselineKey = "useManualBaseline"
    /// User-configured baseline HRV (SDNN in ms)
    static let manualBaselineHRVKey = "manualBaselineHRV"
    /// User-configured baseline heart rate (BPM)
    static let manualBaselineHeartRateKey = "manualBaselineHeartRate"
    /// Stress score threshold for "high stress" category override
    static let highStressThresholdKey = "highStressThreshold"

    // MARK: - Display Preferences

    /// Preferred stress display style: "gauge", "number", or "compact"
    static let displayStyleKey = "stressDisplayStyle"
    /// History window in days for charts
    static let historyDaysKey = "historyWindowDays"
    /// Whether to show HRV raw values in the UI
    static let showHRVRawKey = "showHRVRawValues"

    // MARK: - Data Management

    /// Whether CloudKit sync is enabled
    static let cloudSyncEnabledKey = "cloudSyncEnabled"
    /// Auto-export frequency: "off", "daily", "weekly"
    static let autoExportKey = "autoExportFrequency"

    // MARK: - Defaults

    static let defaultAlertThreshold: Double = 0.7
    static let defaultManualBaselineHRV: Double = 60.0
    static let defaultManualBaselineHeartRate: Double = 65.0
    static let defaultHighStressThreshold: Double = 0.6
    static let defaultHistoryDays: Int = 7
}

/// Enum for stress display styles
enum StressDisplayStyle: String, CaseIterable, Identifiable {
    case gauge = "gauge"
    case number = "number"
    case compact = "compact"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gauge:   return "Circular Gauge"
        case .number:  return "Number + Color"
        case .compact: return "Compact Bar"
        }
    }
}

/// Enum for auto-export frequency
enum AutoExportFrequency: String, CaseIterable, Identifiable {
    case off = "off"
    case daily = "daily"
    case weekly = "weekly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:    return "Off"
        case .daily:  return "Daily"
        case .weekly: return "Weekly"
        }
    }
}
