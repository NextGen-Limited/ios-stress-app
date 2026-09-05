import WidgetKit
import SwiftUI

// MARK: - Circular Complication Provider
/// WidgetKit provider for circular watchOS complications
/// Displays a full-circle stress gauge with color-coded levels
struct CircularComplicationProvider: TimelineProvider {

    // MARK: - TimelineProvider
    /// Placeholder entry during complication loading
    func placeholder(in context: Context) -> CircularComplicationEntry {
        CircularComplicationEntry(
            date: Date(),
            entry: ComplicationEntry.placeholder
        )
    }

    /// Snapshot for complication gallery
    func getSnapshot(in context: Context, completion: @escaping (CircularComplicationEntry) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        completion(CircularComplicationEntry(
            date: Date(),
            entry: entry
        ))
    }

    /// Timeline entries for complication display
    func getTimeline(in context: Context, completion: @escaping (Timeline<CircularComplicationEntry>) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let nextRefresh = ComplicationDataProvider.shared.nextRefreshDate()

        completion(Timeline(
            entries: [
                CircularComplicationEntry(
                    date: Date(),
                    entry: entry
                )
            ],
            policy: .after(nextRefresh)
        ))
    }
}

// MARK: - Circular Complication Entry
/// Timeline entry for circular complications
struct CircularComplicationEntry: TimelineEntry {
    let date: Date
    let entry: ComplicationEntry
}

// MARK: - Circular Complication View
/// SwiftUI view for circular complication display.
///
/// Dark complication canvas (watchOS convention): a ring whose fill = the
/// stress level, the numeric score in the centre in SF Pro Rounded, and the
/// tier label in SF Mono below.  Ripple glyph is omitted at this size to
/// keep the score legible; the ring colour carries the tier.
struct CircularComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: CircularComplicationEntry

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 4)

            // Stress level ring with tier colour coding
            Circle()
                .trim(from: 0, to: stressLevelFraction)
                .stroke(
                    stressColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: stressLevelFraction)

            // Centre content — score + tier label
            VStack(spacing: 0) {
                Text(entry.entry.isPlaceholder ? "—" : "\(Int(entry.entry.stressLevel.rounded()))")
                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit()) // dated exception 2026-09-05: accessory circular template — system-fixed slot
                    .foregroundColor(stressColor)
                Text(entry.entry.category.displayName.uppercased())
                    .font(.system(size: 6.5, weight: .semibold, design: .monospaced)) // dated exception 2026-09-05: accessory circular template — system-fixed slot
                    .tracking(0.06 * 6.5)
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .widgetURL(deepLinkURL)
    }

    // MARK: - Computed Properties
    private var stressLevelFraction: CGFloat {
        CGFloat(min(max(entry.entry.stressLevel, 0), 100) / 100.0)
    }

    private var stressColor: Color {
        entry.entry.category.color
    }

    private var deepLinkURL: URL? {
        URL(string: "stressmonitor://dashboard")
    }
}

// MARK: - Circular Complication Widget
/// Widget definition for circular complication family
struct CircularComplication: Widget {
    let kind: String = "CircularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CircularComplicationProvider()) { entry in
            CircularComplicationView(entry: entry)
                .containerBackground(for: .widget) {
                    WatchFaceBackgroundView(
                        style: WatchFacePreferences.backgroundStyle,
                        theme: WatchFacePreferences.theme
                    )
                }
        }
        .configurationDisplayName("Stress Ring")
        .description("Shows your current stress level as a color-coded ring")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Preview
#Preview(as: .accessoryCircular) {
    CircularComplication()
} timeline: {
    CircularComplicationEntry(
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
