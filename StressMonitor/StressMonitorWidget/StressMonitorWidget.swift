import WidgetKit
import SwiftUI

// MARK: - Home Screen Widget

/// Main StressMonitor widget — character-reactive across Small / Medium / Large.
@available(iOS 17.0, *)
struct StressMonitorWidget: Widget {
    let kind: String = "StressMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressWidgetProvider()) { entry in
            StressMonitorWidgetView(entry: entry)
        }
        .configurationDisplayName("StressMonitor")
        .description("Your Ripple character reflects your stress in real time.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

@available(iOS 17.0, *)
struct StressMonitorWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: StressEntry

    var body: some View {
        switch family {
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
}
