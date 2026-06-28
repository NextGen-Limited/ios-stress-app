# StressMonitor Watch

The watchOS app target at `StressMonitor/StressMonitorWatch Watch App/`. Runs a standalone stress monitoring pipeline against HealthKit on Apple Watch, renders a compact three-view UI (home, history, breathing), and mirrors state to the iPhone through `WatchConnectivityManager`. Entry point is `StressMonitorWatchApp.swift`.

## Directory layout

```
StressMonitorWatch Watch App/
├── StressMonitorWatchApp.swift     # @main
├── ContentView.swift               # Root TabView
├── Services/
│   ├── WatchHealthKitManager.swift         # HealthKit reads (HRV, HR)
│   ├── WatchHealthKitManager+MultiFactorFetch.swift
│   ├── MultiFactorStressCalculator.swift   # Mirror of iOS calculator
│   ├── WatchConnectivityManager.swift      # Phone sync via WCSession
│   ├── WatchSharedDataStore.swift          # App Group shared snapshot
│   ├── StressCalculator.swift              # Fallback 2-factor
│   └── 5 StressFactor implementations
├── Models/                          # Mirror of iOS models (smaller subset)
├── ViewModels/
├── Views/
│   ├── WatchHomeView.swift
│   ├── WatchHistoryView.swift
│   ├── WatchBreatheView.swift
│   └── WatchFaceSettingsView.swift
├── Complications/                   # WidgetKit complications
└── Theme/
```

## How it works

The watch app duplicates the iOS stress algorithm source files rather than sharing a package, because watchOS targets cannot embed iOS framework builds. `WatchHealthKitManager` queries HRV and heart rate directly from the on-watch HealthKit store, packs them into a `StressContext`, and runs the same five-factor `MultiFactorStressCalculator` as the iPhone app.

`WatchConnectivityManager` (at `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`) opens a `WCSession` and exchanges `WatchSharedData` messages with `PhoneConnectivityManager` on the iPhone. This lets the watch display the latest phone-side measurement and vice versa.

The watch app also supports custom watch face background personalization through `WatchFacePreferences` (persisted locally) and `WatchFaceSettingsView`.

## Complications

The watch app ships WidgetKit-based complications under `StressMonitor/StressMonitorWatch Watch App/Complications/`. These are registered through `ComplicationBundle.swift` and render the current stress category and character mood onto watch face families (accessoryCircular, accessoryRectangular, accessoryInline, graphicCircular).

See [StressMonitor Widget](stress-monitor-widget.md) for the home-screen widget extension, which is a separate iOS target.

## Key source files

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift` | `@main` entry point |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift` | On-watch HealthKit reads |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` | WCSession sync to phone |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift` | App Group snapshot read/write |
| `StressMonitor/StressMonitorWatch Watch App/Complications/ComplicationBundle.swift` | WidgetKit complication registration |
