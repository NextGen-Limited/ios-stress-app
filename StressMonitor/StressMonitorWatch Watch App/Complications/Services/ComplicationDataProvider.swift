import Foundation
import WidgetKit

// MARK: - Complication Data Provider
/// Provides stress data to complications via App Groups UserDefaults
/// Enables standalone operation without requiring iPhone connection
final class ComplicationDataProvider {

    // MARK: - Properties
    static let shared = ComplicationDataProvider()

    /// App Groups suite identifier for data sharing
    /// Must match entitlements configuration
    private let suiteName = "group.com.stressmonitor.watch"

    /// UserDefaults instance with App Groups access
    private let defaults: UserDefaults?

    /// Device identifier for standalone tracking
    private let deviceID: String

    // MARK: - Initialization
    private init() {
        // Initialize App Groups UserDefaults
        self.defaults = UserDefaults(suiteName: suiteName)

        // Get or create device identifier
        if let existingID = defaults?.string(forKey: Keys.deviceID) {
            self.deviceID = existingID
        } else {
            self.deviceID = UUID().uuidString
            defaults?.set(deviceID, forKey: Keys.deviceID)
        }
    }

    // MARK: - Public API
    /// Fetch the latest stress measurement for complication display
    /// - Returns: ComplicationEntry with current stress data or placeholder
    func fetchLatestEntry() -> ComplicationEntry {
        guard let defaults = defaults,
              let data = defaults.data(forKey: Keys.latestMeasurement),
              let measurement = try? JSONDecoder().decode(StoredMeasurement.self, from: data) else {
            return ComplicationEntry.placeholder
        }

        return ComplicationEntry(
            stressLevel: measurement.stressLevel,
            category: measurement.category,
            hrv: measurement.hrv,
            heartRate: measurement.heartRate,
            timestamp: measurement.timestamp
        )
    }

    /// Save a new stress measurement for complications
    /// - Parameter measurement: StressResult to store
    func saveMeasurement(_ measurement: StressResult) {
        guard let defaults = defaults else { return }

        let stored = StoredMeasurement(from: measurement)

        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: Keys.latestMeasurement)
            defaults.synchronize()

            // Notify WidgetKit of data change
            WidgetCenter.shared.reloadTimelines(ofKind: "CircularComplication")
            WidgetCenter.shared.reloadTimelines(ofKind: "RectangularComplication")
            WidgetCenter.shared.reloadTimelines(ofKind: "InlineComplication")
        }
    }

    /// Get the next scheduled timeline refresh date
    /// - Returns: Date for next refresh within WidgetKit budget
    func nextRefreshDate() -> Date {
        // Refresh every 30 minutes to stay within budget
        // WidgetKit allows ~50 refreshes per day per complication
        return Date().addingTimeInterval(30 * 60)
    }

    /// Check if complications should show placeholder data
    /// - Returns: Boolean indicating if no data is available
    var shouldShowPlaceholder: Bool {
        defaults?.object(forKey: Keys.latestMeasurement) == nil
    }

    /// Clear all stored complication data
    func clearData() {
        defaults?.removeObject(forKey: Keys.latestMeasurement)
        defaults?.synchronize()

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Types
    /// Storage keys for UserDefaults
    enum Keys {
        static let latestMeasurement = "latestStressMeasurement"
        static let deviceID = "complicationDeviceID"
    }

    /// Codable wrapper for stress measurements
    struct StoredMeasurement: Codable {
        let stressLevel: Double
        let category: StressCategory
        let hrv: Double
        let heartRate: Double
        let timestamp: Date

        init(from result: StressResult) {
            self.stressLevel = result.level
            self.category = result.category
            self.hrv = result.hrv
            self.heartRate = result.heartRate
            self.timestamp = result.timestamp
        }
    }
}

// MARK: - Complication Entry Model
/// Simplified stress data model for complication timeline entries
struct ComplicationEntry {
    let stressLevel: Double
    let category: StressCategory
    let hrv: Double
    let heartRate: Double
    let timestamp: Date

    /// Placeholder entry when no data is available
    static let placeholder = ComplicationEntry(
        stressLevel: 0,
        category: .relaxed,
        hrv: 0,
        heartRate: 0,
        timestamp: Date()
    )

    /// Boolean indicating if this is placeholder data
    var isPlaceholder: Bool {
        stressLevel == 0 && hrv == 0 && heartRate == 0
    }

    /// Display text for stress level
    var stressLevelText: String {
        isPlaceholder ? "--" : "\(Int(stressLevel))"
    }

    /// Display text for HRV value
    var hrvText: String {
        isPlaceholder ? "--" : String(format: "%.0f", hrv)
    }

    /// Display text for category
    var categoryText: String {
        isPlaceholder ? "No Data" : category.rawValue.capitalized
    }
}
