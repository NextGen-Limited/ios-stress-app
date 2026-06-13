import WidgetKit
import SwiftUI

// MARK: - Complication Bundle
/// WidgetKit bundle configuration for watchOS complications.
///
/// Supports 6 families:
/// - **Accessory Circular** — character face in a ring
/// - **Accessory Rectangular** — character face + mood label
/// - **Accessory Inline** — mood word only
/// - **Accessory Corner** — character emoji (watchOS 10+)
/// - **Graphic Circular** — full-circle character (legacy mod-based)
/// - **Graphic Rectangular** — wide character display (legacy mod-based)
struct ComplicationBundle: WidgetBundle {
    var body: some Widget {
        CircularComplication()
        RectangularComplication()
        InlineComplication()
        CornerComplication()
        GraphicCircularComplication()
        GraphicRectangularComplication()
    }
}

// MARK: - Corner Complication (watchOS 10+)

/// Minimal corner complication — just the character emoji.
struct CornerComplication: Widget {
    let kind: String = "CornerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CornerComplicationProvider()) { entry in
            CornerComplicationView(entry: entry)
        }
        .configurationDisplayName("Ripple")
        .description("Your stress character in the watch face corner.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct CornerComplicationEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let accentColor: Color
}

struct CornerComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CornerComplicationEntry {
        CornerComplicationEntry(date: Date(), emoji: "💧", accentColor: .blue)
    }

    func getSnapshot(in context: Context, completion: @escaping (CornerComplicationEntry) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let tier = StressTier.from(level: entry.stressLevel)
        completion(CornerComplicationEntry(date: Date(), emoji: tier.emoji, accentColor: tier.accent))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CornerComplicationEntry>) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let tier = StressTier.from(level: entry.stressLevel)
        let nextRefresh = ComplicationDataProvider.shared.nextRefreshDate()
        completion(Timeline(
            entries: [CornerComplicationEntry(date: Date(), emoji: tier.emoji, accentColor: tier.accent)],
            policy: .after(nextRefresh)
        ))
    }
}

struct CornerComplicationView: View {
    let entry: CornerComplicationEntry

    var body: some View {
        Text(entry.emoji)
            .font(.system(size: 16))
            .widgetLabel { Text("Ripple") }
    }
}

// MARK: - Graphic Circular (legacy mod-based family)

struct GraphicCircularComplication: Widget {
    let kind: String = "GraphicCircularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CircularComplicationProvider()) { entry in
            CircularComplicationView(entry: CircularComplicationEntry(date: entry.date, entry: entry.entry))
        }
        .configurationDisplayName("Ripple Ring")
        .description("Full-circle stress character.")
        .supportedFamilies([.graphicCircular])
    }
}

// MARK: - Graphic Rectangular (legacy mod-based family)

struct GraphicRectangularComplication: Widget {
    let kind: String = "GraphicRectangularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RectangularComplicationProvider()) { entry in
            RectangularStressView(entry: .init(date: entry.date, entry: entry.entry))
        }
        .configurationDisplayName("Ripple Detail")
        .description("Wide stress character display.")
        .supportedFamilies([.graphicRectangular])
    }
}

// MARK: - Supported Families Reference
extension ComplicationBundle {
    /// All supported complication families for this app.
    static var allSupportedFamilies: [WidgetFamily] {
        [
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner,
            .graphicCircular,
            .graphicRectangular
        ]
    }

    /// WidgetKit timeline refresh policy.
    /// Complications update every 30 minutes to stay within budget.
    static var timelinePolicy: TimelineReloadPolicy {
        .after(Date().addingTimeInterval(30 * 60))
    }
}
