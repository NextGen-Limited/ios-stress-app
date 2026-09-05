import SwiftUI
import WidgetKit

// MARK: - Lock Screen: Accessory Rectangular

/// Lock Screen rectangular widget — character emoji + mood label, no score.
@available(iOS 17.0, *)
struct LockScreenRectangularView: View {
    let entry: StressEntry

    var body: some View {
        if let stress = entry.latestStress {
            let tier = WidgetStressTier.from(level: stress.level)
            HStack(spacing: 6) {
                Text(tier.emoji)
                    .font(.system(size: 14)) // dated exception 2026-09-05: lock-screen accessory slot — system-fixed template
                Text(tier.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded)) // dated exception 2026-09-05: lock-screen accessory slot — system-fixed template
                    .foregroundColor(tier.accent)
            }
        } else {
            Text("💧")
                .font(.system(size: 14)) // dated exception 2026-09-05: lock-screen accessory slot — system-fixed template
        }
    }
}

// MARK: - Lock Screen: Accessory Circular

/// Lock Screen circular widget — character face only.
@available(iOS 17.0, *)
struct LockScreenCircularView: View {
    let entry: StressEntry

    var body: some View {
        if let stress = entry.latestStress {
            let tier = WidgetStressTier.from(level: stress.level)
            ZStack {
                Circle()
                    .stroke(tier.accent.opacity(0.3), lineWidth: 2)
                Text(tier.emoji)
                    .font(.system(size: 18)) // dated exception 2026-09-05: lock-screen accessory slot — system-fixed template
            }
        } else {
            Text("💧")
                .font(.system(size: 18)) // dated exception 2026-09-05: lock-screen accessory slot — system-fixed template
        }
    }
}

// MARK: - Lock Screen: Accessory Inline

/// Lock Screen inline widget — single emoji, minimal footprint.
@available(iOS 17.0, *)
struct LockScreenInlineView: View {
    let entry: StressEntry

    var body: some View {
        if let stress = entry.latestStress {
            let tier = WidgetStressTier.from(level: stress.level)
            Text("\(tier.emoji) \(tier.label)")
        } else {
            Text("💧 StressMonitor")
        }
    }
}

// MARK: - Lock Screen Widget Definition

/// Lock Screen widget supporting accessoryRectangular, accessoryCircular, accessoryInline.
@available(iOS 17.0, *)
struct LockScreenStressWidget: Widget {
    let kind: String = "LockScreenStressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressWidgetProvider()) { entry in
            LockScreenStressWidgetView(entry: entry)
        }
        .configurationDisplayName("Ripple")
        .description("Your stress character on the Lock Screen.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

@available(iOS 17.0, *)
struct LockScreenStressWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: StressEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)

        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)

        case .accessoryInline:
            LockScreenInlineView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)

        default:
            LockScreenRectangularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
