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
/// SwiftUI view for circular complication display
struct CircularComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: CircularComplicationEntry

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            // Stress level ring with color coding
            Circle()
                .trim(from: 0, to: stressLevelFraction)
                .stroke(
                    stressColor,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: stressLevelFraction)

            // Center content
            VStack(spacing: 0) {
                if entry.entry.isPlaceholder {
                    Text("--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                } else {
                    Text(entry.entry.stressLevelText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(stressColor)

                    Text(entry.entry.categoryText)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetURL(deepLinkURL)
    }

    // MARK: - Computed Properties
    private var stressLevelFraction: CGFloat {
        CGFloat(entry.entry.stressLevel / 100.0)
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
                .containerBackground(.fill.tertiary, for: .widget)
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
