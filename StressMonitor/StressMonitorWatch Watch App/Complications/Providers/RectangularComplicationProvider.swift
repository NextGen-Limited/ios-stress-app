import WidgetKit
import SwiftUI

// MARK: - Rectangular Complication Provider
/// WidgetKit provider for rectangular watchOS complications
/// Displays stress score with HRV trend in a compact rectangular layout
struct RectangularComplicationProvider: TimelineProvider {

    // MARK: - TimelineProvider
    /// Placeholder entry during complication loading
    func placeholder(in context: Context) -> RectangularComplicationEntry {
        RectangularComplicationEntry(
            date: Date(),
            entry: ComplicationEntry.placeholder
        )
    }

    /// Snapshot for complication gallery
    func getSnapshot(in context: Context, completion: @escaping (RectangularComplicationEntry) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        completion(RectangularComplicationEntry(
            date: Date(),
            entry: entry
        ))
    }

    /// Timeline entries for complication display
    func getTimeline(in context: Context, completion: @escaping (Timeline<RectangularComplicationEntry>) -> Void) {
        let entry = ComplicationDataProvider.shared.fetchLatestEntry()
        let nextRefresh = ComplicationDataProvider.shared.nextRefreshDate()

        completion(Timeline(
            entries: [
                RectangularComplicationEntry(
                    date: Date(),
                    entry: entry
                )
            ],
            policy: .after(nextRefresh)
        ))
    }
}

// MARK: - Rectangular Complication Entry
/// Timeline entry for rectangular complications
struct RectangularComplicationEntry: TimelineEntry {
    let date: Date
    let entry: ComplicationEntry
}

// MARK: - Rectangular Complication View
/// SwiftUI view for rectangular complication display.
///
/// Dark complication canvas (watchOS convention): 3pt tier-colour bar on
/// the leading edge, the Ripple companion SVG glyph, then the numeric
/// score in SF Pro Rounded + tier glyph label.  Mirrors the watch design
/// output "Accessory Rectangular" family.
struct RectangularComplicationView: View {
    let entry: RectangularComplicationEntry

    var body: some View {
        HStack(spacing: 9) {
            // Leading: 3pt tier bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(stressColor)
                .frame(width: 3, height: 36)

            // Ripple companion glyph
            CharacterFaceView(creature: .ripple, category: entry.entry.category, size: 24, showsHalo: false)

            // Score + tier label
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.entry.isPlaceholder ? "—" : "\(Int(entry.entry.stressLevel.rounded()))")
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .tracking(-0.02 * 22)
                    .foregroundColor(stressColor)
                Text(entry.entry.isPlaceholder ? "No Data" : "\(entry.entry.category.glyph) \(entry.entry.category.displayName) · Ripple")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.04 * 9)
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
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

// MARK: - Rectangular Complication Widget
/// Widget definition for rectangular complication family
struct RectangularComplication: Widget {
    let kind: String = "RectangularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RectangularComplicationProvider()) { entry in
            RectangularComplicationView(entry: entry)
                .containerBackground(for: .widget) {
                    WatchFaceBackgroundView(
                        style: WatchFacePreferences.backgroundStyle,
                        theme: WatchFacePreferences.theme
                    )
                }
        }
        .configurationDisplayName("Stress & HRV")
        .description("Shows your current stress level and HRV measurement")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Preview
#Preview(as: .accessoryRectangular) {
    RectangularComplication()
} timeline: {
    RectangularComplicationEntry(
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
    RectangularComplicationView(entry: RectangularComplicationEntry(
        date: Date(),
        entry: ComplicationEntry(
            stressLevel: 78,
            category: .high,
            hrv: 28,
            heartRate: 92,
            timestamp: Date()
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}

#Preview("Placeholder") {
    RectangularComplicationView(entry: RectangularComplicationEntry(
        date: Date(),
        entry: ComplicationEntry.placeholder
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}
