# Home Screen Widgets

> **Created by:** Phuong Doan
> **Feature:** iOS 17+ home screen widgets
> **Designs Referenced:** 2 screens
> - `home_screen_widgets_dark`, `home_screen_widgets_light`

---

## Overview

Home screen widgets provide at-a-glance stress monitoring without opening the app:
- **Small widget:** Current stress score with ring
- **Medium widget:** Stress score + HRV trend chart
- Uses WidgetKit (iOS 14+) with iOS 17 enhancements

---

## 1. Widget Bundle Configuration

```swift
// StressMonitorWidget/StressMonitorWidgetBundle.swift

import WidgetKit
import SwiftUI

@main
struct StressMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        StressMonitorWidget()
    }
}
```

---

## 2. Widget Entry & Provider

```swift
// StressMonitorWidget/StressMonitorWidget.swift

import WidgetKit
import SwiftUI

struct StressMonitorWidget: Widget {
    let kind: String = "StressMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressMonitorProvider()) { entry in
            StressMonitorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stress Monitor")
        .description("Track your stress levels at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider
struct StressMonitorProvider: TimelineProvider {
    func placeholder(in context: Context) -> StressEntry {
        StressEntry(date: Date(), stressLevel: 45, category: .moderate)
    }

    func getSnapshot(in context: Context, completion: @escaping (StressEntry) -> Void) {
        let entry = StressEntry(
            date: Date(),
            stressLevel: 45,
            category: .moderate,
            hrvHistory: [45, 52, 48, 60, 55, 62, 58],
            hrvAverage: 54,
            hrvMax: 62
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StressEntry>) -> Void) {
        // Fetch latest data
        Task {
            let latestMeasurement = try? await fetchLatestMeasurement()
            let hrvHistory = try? await fetchHRVHistory(limit: 24)

            let entry = StressEntry(
                date: Date(),
                stressLevel: latestMeasurement?.stressLevel ?? 50,
                category: latestMeasurement?.category ?? .moderate,
                hrvHistory: hrvHistory ?? [],
                hrvAverage: hrvHistory?.reduce(0, +) / Double(hrvHistory?.count ?? 1) ?? 60,
                hrvMax: hrvHistory?.max() ?? 75
            )

            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchLatestMeasurement() async throws -> StressMeasurement? {
        // Fetch from App Group container or via AppIntent
        // Implementation depends on your data sharing strategy
        return nil
    }

    private func fetchHRVHistory(limit: Int) async throws -> [Double] {
        // Fetch last N HRV values
        return []
    }
}

// MARK: - Widget Entry
struct StressEntry: TimelineEntry {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
    let hrvHistory: [Double]
    let hrvAverage: Double
    let hrvMax: Double
}
```

---

## 3. Small Widget

**Design:** `home_screen_widgets_dark` (left widget)

```swift
// StressMonitorWidget/SmallWidgetView.swift

import SwiftUI

struct SmallWidgetView: View {
    let entry: StressEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.primary.opacity(0.2), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                // App icon (top right)
                HStack {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Stress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: entry.stressLevel / 100)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(entry.stressLevel))")
                            .font(.system(size: 28, weight: .bold))

                        Text(entry.category.displayName.uppercased())
                            .font(.system(size: 8))
                    }
                }
                .frame(width: 80, height: 80)

                Spacer()

                // Bottom label
                Text("Stress Score")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .padding(12)
        }
        .background(Color.cardDark)
    }
}

// MARK: - Preview
#Preview("Small Widget") {
    SmallWidgetView(
        entry: StressEntry(
            date: Date(),
            stressLevel: 42,
            category: .mild,
            hrvHistory: [],
            hrvAverage: 60,
            hrvMax: 75
        )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}
```

---

## 4. Medium Widget

**Design:** `home_screen_widgets_dark` (right widget)

```swift
// StressMonitorWidget/MediumWidgetView.swift

import SwiftUI

struct MediumWidgetView: View {
    let entry: StressEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Current stress
            leftSection

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1)

            // Right side: HRV trend
            rightSection
        }
        .background(Color.cardDark)
    }

    private var leftSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "vital_signs")
                    .font(.system(size: 12))
                Text("Current")
                    .font(.system(size: 9))
                    .uppercaseSmallCaps()
            }
            .foregroundColor(.textSecondary)

            Text("\(Int(entry.stressLevel))")
                .font(.system(size: 28, weight: .bold))

            // Mini ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.stressLevel / 100)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: "bolt.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            .frame(width: 56, height: 56)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10))
                Text("-2% vs Avg")
                    .font(.caption)
            }
            .foregroundColor(.successGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }

    private var rightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HRV Trend")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Last 24 Hours")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text("\(Int(entry.hrvAverage))ms")
                    .font(.system(size: 18, weight: .bold))
            }

            Spacer()

            // Sparkline
            HRVSparkline(data: entry.hrvHistory)
                .frame(height: 48)

            // Footer metrics
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg")
                        .font(.system(size: 8))
                        .uppercaseSmallCaps()
                        .foregroundColor(.textSecondary)
                    Text("\(Int(entry.hrvAverage))ms")
                        .font(.caption)
                        .bold()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Max")
                        .font(.system(size: 8))
                        .uppercaseSmallCaps()
                        .foregroundColor(.textSecondary)
                    Text("\(Int(entry.hrvMax))ms")
                        .font(.caption)
                        .bold()
                }

                Text("Updated 2m ago")
                    .font(.system(size: 8))
                    .foregroundColor(.textSecondary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

// MARK: - Widget Entry View
struct StressMonitorWidgetEntryView: View {
    var entry: StressMonitorProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: - Sparkline (Widget Version)
struct HRVSparkline: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let step = width / CGFloat(max(data.count - 1, 1))

            let min = data.min() ?? 0
            let max = data.max() ?? 100
            let range = max - min

            func y(for value: Double) -> CGFloat {
                if range == 0 { return height / 2 }
                return height - CGFloat((value - min) / range) * height
            }

            Path { path in
                guard !data.isEmpty else { return }

                // Area fill
                path.move(to: CGPoint(x: 0, y: height))

                for (index, value) in data.enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.primary.opacity(0.5), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Line stroke
            Path { path in
                guard !data.isEmpty else { return }
                path.move(to: CGPoint(x: 0, y: y(for: data[0])))

                for (index, value) in data.enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                }
            }
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

// MARK: - Preview
#Preview("Medium Widget") {
    MediumWidgetView(
        entry: StressEntry(
            date: Date(),
            stressLevel: 38,
            category: .mild,
            hrvHistory: [42, 45, 48, 44, 50, 52, 48, 45],
            hrvAverage: 46.75,
            hrvMax: 52
        )
    )
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}
```

---

## 5. Widget Deep Link

```swift
// StressMonitorWidget/StressMonitorWidget.swift

import WidgetKit
import SwiftUI

// Add to StressMonitorWidgetEntryView
struct StressMonitorWidgetEntryView: View {
    var entry: StressMonitorProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetFamilySize) var familySize

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: - Deep Link Support
extension StressMonitorWidget {
    var deepLinkURL: URL {
        URL(string: "stressmonitor://measurement")!
    }
}

// In app main scene, handle the URL
struct StressMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    handleWidgetURL(url)
                }
        }
    }

    private func handleWidgetURL(_ url: URL) {
        // Navigate based on URL
        if url.host == "measurement" {
            // Navigate to measurement flow
        }
    }
}
```

---

## 6. Widget Configuration (iOS 17+)

```swift
// StressMonitorWidget/StressMonitorWidget.swift

struct StressMonitorWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressMonitorProvider()) { entry in
            StressMonitorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stress Monitor")
        .description("Track your stress levels at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
```

---

## 7. App Intent for Widget Updates

```swift
// StressMonitor/Intents/UpdateWidgetIntent.swift

import AppIntents

@available(iOS 16.0, *)
struct UpdateWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Widget"
    static var description = IntentDescription("Updates the stress monitor widget with latest data.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        // Refresh widget data
        // This can be triggered from the app to update the widget
        return .result(value: true)
    }
}

// In the widget provider, add:
// struct StressMonitorAppIntentTimelineProvider: AppIntentTimelineProvider {
//     func getTimeline(for configuration: StressMonitorAppIntentTimelineConfiguration, in context: Context) async -> Timeline<StressEntry> {
//         // Fetch data and return timeline
//     }
// }
```

---

## File Structure

```
StressMonitorWidget/
├── StressMonitorWidget.swift
├── StressMonitorWidgetBundle.swift
├── SmallWidgetView.swift
├── MediumWidgetView.swift
├── HRVSparkline.swift
└── Info.plist
```

---

## Dependencies

- **WidgetKit:** iOS 14+ widget framework
- **AppIntents:** For iOS 16+ interactive widgets
- **App Groups:** For sharing data between app and widget
- **Design System:** Colors, tokens from `00-design-system-components.md`

---

## Widget Sizes

| Size | Dimensions | Contents |
|------|------------|----------|
| Small | 16x16 modules (approx 158x158 pts) | Stress ring + score |
| Medium | 32x16 modules (approx 338x158 pts) | Stress score + HRV chart |

---

## Timeline Refresh Policy

- **Normal refresh:** Every 15 minutes
- **After measurement:** Immediate update via AppIntent
- **Low power mode:** Extended refresh intervals
