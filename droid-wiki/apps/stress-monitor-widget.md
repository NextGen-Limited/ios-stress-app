# StressMonitor Widget

The WidgetKit extension target at `StressMonitor/StressMonitorWidget/`. Provides home-screen widgets in three sizes (small, medium, large), a lock-screen widget, and a Live Activity. Entry point is `StressMonitorWidgetBundle.swift`.

## Directory layout

```
StressMonitorWidget/
├── StressMonitorWidgetBundle.swift       # @main WidgetBundle
├── StressMonitorWidget.swift             # Home-screen widget (S/M/L)
├── StressMonitorWidgetControl.swift      # Lock Screen control widget
├── StressMonitorWidgetLiveActivity.swift # Live Activity for active sessions
├── AppIntent.swift                       # Configuration intent
├── Providers/
│   └── StressWidgetProvider.swift        # Timeline entry provider
├── Models/
│   └── WidgetDataProvider.swift          # Reads WidgetSharedData from App Group
├── Views/
│   ├── SmallWidgetView.swift
│   ├── MediumWidgetView.swift
│   ├── LargeWidgetView.swift
│   └── LockScreenWidgetView.swift
├── WidgetStressCharacter.swift           # Character rendering for widgets
└── Intents/
```

## How it works

Widgets are read-only and cannot query HealthKit directly. The iPhone app writes a compact `WidgetSharedData` snapshot (current stress level, category, timestamp, character ID, evolution stage) to the shared App Group container after each measurement. `WidgetDataProvider` reads that snapshot and falls back to placeholder data in previews and when no measurement exists yet.

`StressWidgetProvider` produces a timeline of entries. Each widget view renders the stress category color, the numeric level, and a small character glyph via `WidgetStressCharacter`. The Live Activity widget surfaces active breathing or mini-walk sessions with a countdown timer.

## Key source files

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitorWidget/StressMonitorWidgetBundle.swift` | `@main` bundle registering all widget types |
| `StressMonitor/StressMonitorWidget/Providers/StressWidgetProvider.swift` | Timeline provider with snapshot/placeholder entries |
| `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift` | App Group snapshot reader |
| `StressMonitor/StressMonitorWidget/StressMonitorWidgetLiveActivity.swift` | Live Activity for breathing/walk sessions |
| `StressMonitor/StressMonitorWidget/WidgetStressCharacter.swift` | Character asset rendering for widget sizes |
