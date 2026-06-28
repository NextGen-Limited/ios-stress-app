# Apps

StressMonitor ships three Xcode targets that produce installable bundles. Each target owns a distinct entry point and deployment surface, and they share data through an App Group container and CloudKit private database.

| App | Target | Platform | Entry point |
| --- | --- | --- | --- |
| [StressMonitor iOS](stress-monitor-ios.md) | `StressMonitor` | iOS 17+ | `StressMonitorApp.swift` |
| [StressMonitor Watch](stress-monitor-watch.md) | `StressMonitorWatch Watch App` | watchOS 10+ | `StressMonitorWatchApp.swift` |
| [StressMonitor Widget](stress-monitor-widget.md) | `StressMonitorWidget` | iOS 17+ widget extension | `StressMonitorWidgetBundle.swift` |

The iOS app is the primary surface: it owns the stress calculation pipeline, HealthKit reads, SwiftData writes, CloudKit sync, and the full UI. The watch app runs a parallel but smaller pipeline against `WatchHealthKitManager` and mirrors state to the phone through `WatchConnectivityManager`. The widget extension renders a read-only snapshot from the shared App Group.
