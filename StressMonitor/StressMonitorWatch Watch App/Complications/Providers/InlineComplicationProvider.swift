import WidgetKit
import SwiftUI

// MARK: - Inline Complication Provider
/// WidgetKit provider for inline watchOS complications
/// Displays text-only stress level for compact inline display
struct InlineComplicationProvider: TimelineProvider {

    // MARK: - TimelineProvider
    /// Placeholder entry during complication loading
    func placeholder(in context: Context) -> InlineComplicationEntry {
        InlineComplicationEntry(
            date: Date(),
            entry: ComplicationEntry.placeholder
        )
    }

    /// Snapshot for complication gallery
    func getSnapshot(in context: Context, completion: @escaping (InlineComplicationEntry) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        completion(InlineComplicationEntry(
            date: Date(),
            entry: entry
        ))
    }

    /// Timeline entries for complication display
    func getTimeline(in context: Context, completion: @escaping (Timeline<InlineComplicationEntry>) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let nextRefresh = ComplicationDataProvider.shared.nextRefreshDate()

        completion(Timeline(
            entries: [
                InlineComplicationEntry(
                    date: Date(),
                    entry: entry
                )
            ],
            policy: .after(nextRefresh)
        ))
    }
}

// MARK: - Inline Complication Entry
/// Timeline entry for inline complications
struct InlineComplicationEntry: TimelineEntry {
    let date: Date
    let entry: ComplicationEntry
}

// MARK: - Inline Complication View
/// SwiftUI view for inline complication display.
///
/// Single-line: Ripple mini glyph + numeric score + tier glyph.  Score is
/// rendered in the tier colour; the label sits in muted white.
struct InlineComplicationView: View {
    let entry: InlineComplicationEntry

    var body: some View {
        HStack(spacing: 4) {
            // Ripple mini glyph (no expression at this size)
            CharacterFaceView(creature: .ripple, category: entry.entry.category, size: 14, showsHalo: false)

            Text(entry.entry.isPlaceholder ? "—" : "\(Int(entry.entry.stressLevel.rounded()))")
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: accessory inline template — single-line system slot
                .foregroundColor(stressColor)

            Text("· \(entry.entry.category.displayName)")
                .font(.system(size: 11, weight: .medium, design: .monospaced)) // dated exception 2026-09-05: accessory inline template — single-line system slot
                .foregroundColor(.white.opacity(0.55))
        }
        .widgetURL(deepLinkURL)
    }

    // MARK: - Computed Properties
    private var stressColor: Color {
        entry.entry.category.color
    }

    private var deepLinkURL: URL? {
        URL(string: "stressmonitor://dashboard")
    }
}

// MARK: - Inline Complication Widget
/// Widget definition for inline complication family
struct InlineComplication: Widget {
    let kind: String = "InlineComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InlineComplicationProvider()) { entry in
            InlineComplicationView(entry: entry)
                .containerBackground(for: .widget) {
                    WatchFaceBackgroundView(
                        style: WatchFacePreferences.backgroundStyle,
                        theme: WatchFacePreferences.theme
                    )
                }
        }
        .configurationDisplayName("Stress Level")
        .description("Shows your current stress level at a glance")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Preview
#Preview(as: .accessoryInline) {
    InlineComplication()
} timeline: {
    InlineComplicationEntry(
        date: Date(),
        entry: ComplicationEntry(
            stressLevel: 25,
            category: .mild,
            hrv: 45,
            heartRate: 68,
            timestamp: Date()
        )
    )
}

#Preview("High Stress") {
    InlineComplicationView(entry: InlineComplicationEntry(
        date: Date(),
        entry: ComplicationEntry(
            stressLevel: 82,
            category: .high,
            hrv: 25,
            heartRate: 98,
            timestamp: Date()
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}

#Preview("Relaxed") {
    InlineComplicationView(entry: InlineComplicationEntry(
        date: Date(),
        entry: ComplicationEntry(
            stressLevel: 12,
            category: .relaxed,
            hrv: 68,
            heartRate: 54,
            timestamp: Date()
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}

#Preview("Placeholder") {
    InlineComplicationView(entry: InlineComplicationEntry(
        date: Date(),
        entry: ComplicationEntry.placeholder
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}
