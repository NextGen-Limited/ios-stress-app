import WidgetKit
import Foundation

/// Timeline provider for stress monitoring widgets
/// Handles refresh logic and provides timeline entries for different widget sizes
@available(iOS 17.0, *)
public struct StressWidgetProvider: TimelineProvider {

    public typealias Entry = StressEntry

    // MARK: - Placeholder Entry

    public func placeholder(in context: Context) -> StressEntry {
        StressEntry(
            date: Date(),
            latestStress: createPlaceholderStress(),
            history: createPlaceholderHistory(),
            baseline: (50.0, 60.0),
            isPlaceholder: true
        )
    }

    // MARK: - Snapshot Entry

    /// Provides a preview entry for widget gallery
    public func getSnapshot(in context: Context, completion: @escaping (StressEntry) -> Void) {
        let entry = StressEntry(
            date: Date(),
            latestStress: createSampleStress(),
            history: createSampleHistory(),
            baseline: (50.0, 60.0),
            isPlaceholder: false
        )
        completion(entry)
    }

    // MARK: - Timeline Entry

    /// Provides the actual timeline entries for widget updates
    public func getTimeline(in context: Context, completion: @escaping (Timeline<StressEntry>) -> Void) {
        let dataProvider = WidgetDataProvider.shared
        let currentDate = Date()

        // Get current stress data
        let latestStress = dataProvider.getLatestStress()
        let history = dataProvider.getHistory(limit: 20)
        let baseline = dataProvider.getBaseline()

        // Create the entry
        let entry = StressEntry(
            date: currentDate,
            latestStress: latestStress,
            history: history,
            baseline: baseline,
            isPlaceholder: latestStress == nil
        )

        // Calculate next update time (every 15 minutes)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate

        // Create timeline with policy to update at next scheduled time
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Placeholder Data

    private func createPlaceholderStress() -> StressData {
        StressData(
            level: 45,
            category: "mild",
            hrv: 50,
            heartRate: 70,
            confidence: 0.8,
            timestamp: Date()
        )
    }

    private func createPlaceholderHistory() -> [StressData] {
        (0..<8).map { i in
            StressData(
                level: Double.random(in: 20...70),
                category: "mild",
                hrv: Double.random(in: 30...70),
                heartRate: Double.random(in: 55...85),
                confidence: 0.8,
                timestamp: Date().addingTimeInterval(-Double(i * 3600))
            )
        }
    }

    // MARK: - Sample Data

    private func createSampleStress() -> StressData {
        StressData(
            level: 35,
            category: "mild",
            hrv: 55,
            heartRate: 68,
            confidence: 0.85,
            timestamp: Date()
        )
    }

    private func createSampleHistory() -> [StressData] {
        [
            StressData(level: 25, category: "relaxed", hrv: 65, heartRate: 62, confidence: 0.9, timestamp: Date().addingTimeInterval(-8 * 3600)),
            StressData(level: 40, category: "mild", hrv: 52, heartRate: 70, confidence: 0.85, timestamp: Date().addingTimeInterval(-6 * 3600)),
            StressData(level: 55, category: "moderate", hrv: 42, heartRate: 78, confidence: 0.8, timestamp: Date().addingTimeInterval(-4 * 3600)),
            StressData(level: 35, category: "mild", hrv: 58, heartRate: 65, confidence: 0.85, timestamp: Date().addingTimeInterval(-2 * 3600)),
            StressData(level: 30, category: "relaxed", hrv: 62, heartRate: 64, confidence: 0.88, timestamp: Date()),
        ]
    }
}

// MARK: - Timeline Entry

/// Represents a single timeline entry for the widget
public struct StressEntry: TimelineEntry {
    public let date: Date
    public let latestStress: StressData?
    public let history: [StressData]
    public let baseline: (hrv: Double, restingHeartRate: Double)?
    public let isPlaceholder: Bool

    /// Returns true if we have valid stress data to display
    public var hasValidData: Bool {
        latestStress != nil && !history.isEmpty
    }

    /// Average stress level from history
    public var averageStress: Double {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.level } / Double(history.count)
    }

    /// Trend direction compared to previous readings
    public var trend: TrendDirection {
        guard history.count >= 2 else { return .stable }

        let recent = history.prefix(3).reduce(0) { $0 + $1.level } / Double(min(3, history.count))
        let older = history.dropFirst(3).prefix(3).reduce(0) { $0 + $1.level } / Double(max(1, min(3, history.count - 3)))

        let diff = recent - older
        if diff > 10 { return .increasing }
        if diff < -10 { return .decreasing }
        return .stable
    }
}

// MARK: - Trend Direction

public enum TrendDirection: String, Codable {
    case increasing
    case stable
    case decreasing

    public var icon: String {
        switch self {
        case .increasing: return "arrow.up"
        case .stable: return "minus"
        case .decreasing: return "arrow.down"
        }
    }

    public var color: String {
        switch self {
        case .increasing: return "#FF9500"
        case .stable: return "#8E8E93"
        case .decreasing: return "#34C759"
        }
    }
}
