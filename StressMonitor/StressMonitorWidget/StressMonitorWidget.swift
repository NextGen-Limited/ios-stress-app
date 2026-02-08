import WidgetKit
import SwiftUI

/// Main widget configuration for Stress Monitor
/// Configures all supported widget sizes with their respective providers and views
@main
public struct StressMonitorWidget: Widget {

    // MARK: - Widget Configuration

    public static let kind: String = "StressMonitorWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: StressWidgetProvider()) { entry in
            switch entry.family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Stress Monitor")
        .description("Monitor your stress levels, HRV trends, and receive personalized insights.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }

    // MARK: - Initialization

    public init() {}
}

// MARK: - Widget Bundle

/// Widget bundle for all stress monitoring widgets
@available(iOS 17.0, *)
public struct StressMonitorWidgetBundle: WidgetBundle {

    public var body: some Widget {
        StressMonitorWidget()
    }
}

// MARK: - Widget Deep Link Handling

/// Helper for deep linking from widget to main app
@available(iOS 17.0, *)
public enum WidgetDeepLink {

    case dashboard
    case history
    case trends
    case measurement

    var url: URL {
        switch self {
        case .dashboard:
            return URL(string: "stressmonitor://dashboard")!
        case .history:
            return URL(string: "stressmonitor://history")!
        case .trends:
            return URL(string: "stressmonitor://trends")!
        case .measurement:
            return URL(string: "stressmonitor://measurement")!
        }
    }
}
