# StressMonitor iOS

The iPhone app target. Owns the stress calculation pipeline, HealthKit reads, SwiftData persistence, CloudKit sync, LLM chat, StoreKit IAP, and the full SwiftUI UI. Entry point is `StressMonitor/StressMonitor/StressMonitorApp.swift`.

## Directory layout

```
StressMonitor/StressMonitor/
├── StressMonitorApp.swift      # @main, ModelContainer, schema migration
├── Models/                     # SwiftData @Model + value types
├── ViewModels/                 # @Observable state containers
├── Views/                      # SwiftUI screens by feature area
├── Services/                   # Algorithm, HealthKit, LLM, StoreKit, sync
├── Navigation/                 # AppRouter, Route, navigation destinations
├── Theme/                      # Design tokens, colors, fonts, asset catalogs
├── Utilities/                  # Accessibility, animation, helpers
├── Components/                 # Shared UI (CharCompanionCard, HapticManager)
└── Info.plist                  # App config, permissions
```

## App entry and environment

`StressMonitorApp` constructs the SwiftData `ModelContainer` with a versioned schema (V1: `StressMeasurement` + `CharacterUnlock`; V2 adds `Habit` via a lightweight migration stage). It seeds default `CharacterUnlock` rows for every `CharacterCreature` (free characters unlocked, premium characters locked) and sets Ripple as the active character.

Two singletons are injected into the SwiftUI environment at the root:

- `AppRouter` (`StressMonitor/StressMonitor/Navigation/AppRouter.swift`) - owns `selectedTab` and a `NavigationPath` per tab. Any view can drive programmatic navigation or deep links through `router.deepLink(to:in:)`.
- `PaywallController` (`StressMonitor/StressMonitor/Services/Premium/PaywallController.swift`) - single source of truth for presenting the paywall full-screen from anywhere. `present(reason:)` is a no-op when the user is already premium.

## Tab structure

`MainTabView` at `StressMonitor/StressMonitor/Views/MainTabView.swift` hosts four tabs, each with its own `NavigationStack` bound to a path on `AppRouter`:

| Tab | Root view | Purpose |
| --- | --- | --- |
| Home | `DashboardView` | Current stress, vitals, AI insight cards, mood check-in |
| Action | `ActionView` | Breathing, mini walk, habit tracking, recommendations |
| Trends | `TrendsView` | Charts, heatmaps, pattern insights, bio age |
| Settings | `SettingsView` | Preferences, data management, character collection, about |

Per-tab navigation paths are serialized to `@SceneStorage` so state survives scene reconnection. `AppRouter.decodePath` drops corrupt or schema-shifted data rather than crashing.

## Demo mode

In DEBUG builds, the `-demo-mode` launch argument swaps `HealthKitManager` for `SimulatorHealthKitService`, which generates dynamic HRV/HR data cycling through five stress scenarios (relaxed, mild, moderate, high, edge) every 30 seconds. The real `MultiFactorStressCalculator` and SwiftData pipeline still run, so demo mode exercises production code.

## Key source files

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitor/StressMonitorApp.swift` | `@main`, ModelContainer, schema migration, character seeding |
| `StressMonitor/StressMonitor/Views/MainTabView.swift` | Four-tab TabView with per-tab NavigationStack |
| `StressMonitor/StressMonitor/Navigation/AppRouter.swift` | Central navigation state, deep-link routing |
| `StressMonitor/StressMonitor/Services/Premium/PaywallController.swift` | Full-screen paywall presentation singleton |
| `StressMonitor/StressMonitor/Info.plist` | App permissions, StoreKit config keys |
