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
/// SwiftUI view for rectangular complication display
struct RectangularComplicationView: View {
    let entry: RectangularComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            // Leading: Stress level indicator
            leadingSection

            Spacer(minLength: 4)

            // Middle: Current stress level
            middleSection

            Spacer(minLength: 4)

            // Trailing: HRV value
            trailingSection
        }
        .widgetURL(deepLinkURL)
    }

    // MARK: - View Sections
    /// Leading section with icon indicator
    private var leadingSection: some View {
        ZStack {
            Circle()
                .fill(stressColor.opacity(0.15))

            Image(systemName: entry.entry.category.icon)
                .font(.system(size: 10))
                .foregroundColor(stressColor)
        }
        .frame(width: 24, height: 24)
    }

    /// Middle section with stress level and label
    private var middleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Stress")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)

            if entry.entry.isPlaceholder {
                Text("--")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                Text(entry.entry.stressLevelText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(stressColor)
                    .contentTransition(.numericText(value: entry.entry.stressLevel))
            }
        }
    }

    /// Trailing section with HRV value
    private var trailingSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("HRV")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)

            if entry.entry.isPlaceholder {
                Text("--")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                Text(entry.entry.hrvText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                +
                Text(" ms")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
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
                .containerBackground(.fill.tertiary, for: .widget)
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
