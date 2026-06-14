import WidgetKit
import SwiftUI

// MARK: - Complication Bundle
/// WidgetKit bundle configuration for watchOS complications.
///
/// Supports 4 families:
/// - **Accessory Circular** — character face in a ring
/// - **Accessory Rectangular** — character face + mood label
/// - **Accessory Inline** — mood word only
/// - **Accessory Corner** — character emoji (watchOS 10+)
struct ComplicationBundle: WidgetBundle {
    var body: some Widget {
        CircularComplication()
        RectangularComplication()
        InlineComplication()
        CornerComplication()
    }
}

// MARK: - Corner Complication (watchOS 10+)

/// Minimal corner complication — just the character emoji.
struct CornerComplication: Widget {
    let kind: String = "CornerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CornerComplicationProvider()) { entry in
            CornerComplicationView(entry: entry)
                .containerBackground(for: .widget) {
                    WatchFaceBackgroundView(
                        style: WatchFacePreferences.backgroundStyle,
                        theme: WatchFacePreferences.theme
                    )
                }
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
        CornerComplicationEntry(date: Date(), emoji: "\u{1F4A7}", accentColor: .blue)
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
