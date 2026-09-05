import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

struct StressMonitorWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
        var moodLabel: String
        var accentHex: String
    }

    var sessionStart: Date
}

// MARK: - Live Activity Widget

/// Live Activity shows the Ripple character face during a breathing session.
struct StressMonitorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StressMonitorWidgetAttributes.self) { context in
            // Lock Screen / Banner presentation
            HStack(spacing: 12) {
                Text(context.state.emoji)
                    .font(.system(size: 44)) // dated exception 2026-09-05: gauge-class hero numeral per D-09; accessibility-labeled
                    .accessibilityLabel("Ripple character, \(context.state.moodLabel)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.moodLabel)
                        .font(.system(size: 16, weight: .bold, design: .rounded)) // dated exception 2026-09-05: Font.system(size:relativeTo:) unavailable in iOS 26 SDK; Widget-struct ScaledMetric is not environment-driven
                    Text("Breathing session active")
                        .font(.system(size: 12)) // dated exception 2026-09-05: Font.system(size:relativeTo:) unavailable in iOS 26 SDK; Widget-struct ScaledMetric is not environment-driven
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .activityBackgroundTint(Color(hex: context.state.accentHex).opacity(0.12))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded — leading
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.emoji)
                        .font(.system(size: 28)) // dated exception 2026-09-05: Dynamic Island expanded region — system-fixed slot
                }
                // Expanded — trailing
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.moodLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded)) // dated exception 2026-09-05: Dynamic Island expanded region — system-fixed slot
                        .foregroundStyle(Color(hex: context.state.accentHex))
                }
                // Expanded — bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "wind")
                            .foregroundStyle(Color(hex: context.state.accentHex))
                        Text("4·7·8 Breathing in progress")
                            .font(.system(size: 12)) // dated exception 2026-09-05: Dynamic Island expanded region — system-fixed slot
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Text(context.state.emoji)
                    .font(.system(size: 14)) // dated exception 2026-09-05: Dynamic Island compact slot — system-fixed
            } compactTrailing: {
                EmptyView()
            } minimal: {
                Text(context.state.emoji)
                    .font(.system(size: 14)) // dated exception 2026-09-05: Dynamic Island minimal slot — system-fixed
            }
        }
    }
}
