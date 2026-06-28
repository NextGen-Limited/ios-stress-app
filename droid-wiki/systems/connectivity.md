# Connectivity

Phone-to-watch data exchange via `WatchConnectivity`. The iPhone and Apple Watch exchange `WidgetSharedData`-style dictionaries over `WCSession` so each device can surface the other's latest measurement without re-running the full HealthKit pipeline.

## Key abstractions

| Type | File | Description |
| --- | --- | --- |
| `PhoneConnectivityManager` | `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` | iPhone-side `WCSession` delegate. Singleton. |
| `WatchConnectivityManager` | `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` | watchOS-side `WCSession` delegate. |
| `WatchSharedDataStore` | `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift` | App Group snapshot read/write on the watch. |
| `WidgetSharedData` | `StressMonitor/StressMonitor/Models/WidgetSharedData.swift` | Shared snapshot model (stress level, category, character, timestamp). |

## Message flow

`PhoneConnectivityManager` activates `WCSession.default` on the iPhone and adopts the delegate role. It tracks `isWatchPaired`, `isWatchAppInstalled`, and `isReachable` as `@Published` properties so settings views can show connection state.

When a measurement arrives from the watch (via `session(_:didReceiveUserInfo:)`), the manager unpacks the dictionary, constructs a `StressMeasurement`, inserts it into the SwiftData `ModelContext`, and saves. The watch payload carries: `stressLevel`, `category`, `confidence`, `hrv`, `heartRate`, and `timestamp`.

In the other direction, the phone writes its latest snapshot to the App Group through `WidgetSharedData`, which the widget extension and (transitively) the watch can read.

## Activation lifecycle

Both managers follow the standard `WCSession` lifecycle:

1. Check `WCSession.isSupported()`.
2. Set `WCSession.default.delegate`.
3. Call `WCSession.default.activate()`.
4. Conform to `WCSessionDelegate`'s `activationDidCompleteWith`, `sessionDidBecomeInactive`, and `sessionDidDeactivate`.
5. On `sessionDidDeactivate`, re-activate to support switching between watches.

## Entry points for modification

- **Add a new payload field**: add it to the dictionary keys in both managers, to `WidgetSharedData`, and to `WatchSharedDataStore`.
- **Add a real-time message channel** (in addition to the background `userInfo` transfer): use `sendMessage(_:replyHandler:)` in `PhoneConnectivityManager` and `WatchConnectivityManager`, gated on `isReachable`.
