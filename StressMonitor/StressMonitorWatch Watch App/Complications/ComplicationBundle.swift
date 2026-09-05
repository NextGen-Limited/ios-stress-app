import WidgetKit
import SwiftUI

// MARK: - Complication Bundle
/// WidgetKit bundle configuration for watchOS complications.
///
/// Supports 4 families, all rendered with the iOS stress scale and the
/// Ripple companion glyph.  Dark canvas here is the watchOS platform
/// convention — complications are always-on-dark by system contract, so
/// this is the one place the dark palette is acceptable.
/// - **Accessory Circular** — ring + score + tier glyph
/// - **Accessory Rectangular** — companion glyph + score + tier label
/// - **Accessory Inline** — companion glyph + score (single line)
/// - **Accessory Corner** — companion glyph + score (watchOS 10+)
struct ComplicationBundle: WidgetBundle {
    var body: some Widget {
        CircularComplication()
        RectangularComplication()
        InlineComplication()
        CornerComplication()
    }
}

// MARK: - Corner Complication (watchOS 10+)

/// Minimal corner complication — Ripple companion glyph + numeric score.
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
        .description("Your stress companion and score in the watch face corner.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct CornerComplicationEntry: TimelineEntry {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
}

struct CornerComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CornerComplicationEntry {
        CornerComplicationEntry(date: Date(), stressLevel: 0, category: .relaxed)
    }

    func getSnapshot(in context: Context, completion: @escaping (CornerComplicationEntry) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        completion(CornerComplicationEntry(
            date: Date(),
            stressLevel: entry.stressLevel,
            category: entry.category
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CornerComplicationEntry>) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let nextRefresh = ComplicationDataProvider.shared.nextRefreshDate()
        completion(Timeline(
            entries: [
                CornerComplicationEntry(
                    date: Date(),
                    stressLevel: entry.stressLevel,
                    category: entry.category
                )
            ],
            policy: .after(nextRefresh)
        ))
    }
}

struct CornerComplicationView: View {
    let entry: CornerComplicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CharacterFaceView(creature: .ripple, category: entry.category, size: 22, showsHalo: false)
            Text(ComplicationDataProvider.shared.fetchLatestEntry().isPlaceholder
                 ? "—" : "\(Int(entry.stressLevel.rounded()))")
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: accessory corner template — system-fixed slot
                .foregroundColor(entry.category.color)
        }
        .widgetLabel { Text("Ripple") }
    }
}
