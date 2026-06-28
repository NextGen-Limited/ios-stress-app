# StressMonitor Watch

The watchOS app target at `StressMonitor/StressMonitorWatch Watch App/`. Runs a standalone stress monitoring pipeline against HealthKit on Apple Watch, renders a compact four-screen UI, and mirrors state to the iPhone through `WatchConnectivityManager`. Entry point is `StressMonitorWatchApp.swift`.

> The watch app was redesigned to strictly follow **iOS Design System v1.4.2**. It now reads as a sibling of the iPhone app: same light surfaces, tier names, accent budget, typography ramp, and motion curves. See [Design system](../features/design-system.md) for the canonical token definitions.

## Design system alignment

The watch previously shipped a rogue dark canvas, scoreless UI, and emoji-based faces. All of that was removed. The redesign lifts values directly from `design/css/app.css` and `design/design-system.html` (DS v1.4.2 spec), so the watch shares its visual language with the iOS app.

### Light theme surfaces

The dark `#0A0A0F` canvas is gone. The watch now uses the iOS light surface ramp:

| Token | Hex | Role |
| --- | --- | --- |
| `canvas` | `#F2F2F7` | Grouped background (page base) |
| `surface` | `#FFFFFF` | Cards, reading rows, picker items |
| `surfaceSecondary` | `#FBFBFD` | Secondary elevated surface |
| `settingsCanvas` | `#FFFDF6` | Warm cream for Watch Face Settings (iOS Settings lineage) |
| `separator` | `rgba(60,60,67,0.12)` | 0.5pt hairline dividers |

### Stress scale (5 tiers, aligned to iOS)

Scores are shown prominently (SF Pro Rounded 34-44pt on Home). Tier names, ranges, and colors match the iOS app exactly, and every color is paired with a glyph and numeric score for WCAG dual-coding.

| Tier | Range | Hex | Glyph | SF Symbol |
| --- | --- | --- | --- | --- |
| Relaxed | 0-25 | `#34C759` | ◌ | `leaf.fill` |
| Mild | 26-50 | `#007AFF` | ◎ | `circle.fill` |
| Moderate | 51-75 | `#FFD60A` | ◐ | `triangle.fill` |
| High | 76-100 | `#FF9500` | ◑ | `square.fill` |
| Severe | 100+ | `#FF3B30` | ● | `exclamationmark.octagon.fill` |

Moderate uses a darker ink (`#B59400`) for WCAG AA text contrast on light surfaces; the other tiers reuse their own color for text.

### Accent budget

Ripple blue (`--accent` `#4FC3F7`, `--accent-strong` `#0288D1`) is the only accent. It appears **at most twice per screen** - typically the active CTA and one selected/affordance state. There is no mesh gradient slop: backgrounds are low-opacity tint washes over the light canvas.

### Typography

SF Pro family only, with negative letter-spacing on display sizes and positive tracking on uppercase meta:

- **SF Pro Display** - tier labels, phase labels
- **SF Pro Text** - body copy, row labels
- **SF Pro Rounded** - numeric scores (34-44pt on Home, 36-44pt countdown in Breathe)
- **SF Pro Mono** - date/meta strings at the top of Home

### Motion

Ease-based, not spring-everything. Three durations, all honoring `accessibilityReduceMotion` (callers receive `nil` to opt out entirely):

| Token | Duration | Use |
| --- | --- | --- |
| `fast` | 150ms | Snappy state transitions (selection, tier swap) |
| `default` | 200ms | Content transitions (score, ring fill) |
| `slow` | 400-600ms | Hero / breathing ring expansions |
| `ambient` | 2.4s autoreverse | Character halo (disabled under reduce motion) |

### Other primitives

- **Hairline separators**: 0.5pt at `rgba(60,60,67,0.12)`
- **Radii**: `12` (controls), `14` (stat cards, reading rows), `18` (large cards), `22` (hero), `999` (pills)
- **Spacing scale**: 4 / 8 / 12 / 16 / 20 / 24 / 32

## Characters (5 elemental companions)

The emoji water drops were removed. The watch now ships the same five elemental companions as the iOS app (Design System §11), rendered as **inline SVG illustrations** drawn with SwiftUI shapes. Expressions adapt to the current stress tier (smile for Relaxed/Mild, neutral for Moderate, frown for High/Severe).

| Companion | Subtitle | Primary | Secondary | Availability |
| --- | --- | --- | --- | --- |
| Ripple | Water Otter | `#4FC3F7` | `#0288D1` | Free (default) |
| Blossom | Forest Sprite | `#A5D6A7` | `#81C784` | Free |
| Ember | Flame Fox | `#FFAB91` | `#FF8A65` | Plus |
| Zephyr | Wind Wisp | `#D1C4E9` | `#B39DDB` | Plus |
| Lumi | Star Owl | `#7986CB` | `#5C6BC0` | 30-day streak unlock |

Ripple is the watch default and appears on Home, in complications, and in the Settings preview unless the user selects a different watch-face theme.

## Screens (7 swipeable views)

`ContentView` hosts a paged `TabView` (`.page` style) over seven screens. Each screen composes its own background on top of the shared `canvas`.

1. **Home (`WatchHomeView`)** - SF Mono date meta at top; semicircle gauge hero showing the score + tier label ("Mild · 42") with a multi-stop tier-color gradient stroke and the Ripple companion in a soft radial halo; "Measure now" pill CTA at bottom. Includes loading and error states.
2. **Breathe (`WatchBreatheView`)** - 4-7-8 guided breathing. An animated ring expands/contracts with each phase, with a phase label (SF Pro Display), tabular countdown (SF Pro Rounded 36-44pt), four phase dots (Inhale / Hold / Exhale / Hold), and Begin/End buttons. Phase colors: Inhale = accent, Hold = accent-strong, Exhale = mild to accent.
3. **History (`WatchHistoryView`)** - Bio Age card at top (estimated biological age, trend, confidence); range picker (7D / 30D / 90D); three stat cards (avg / best / peak); calendar heatmap showing daily stress intensity; 7-day bar chart with hairline gridlines, tier-colored bars, and today outlined; scrollable grouped reading list; empty state.
4. **Logging (`WatchLoggingView`)** - Daily habit check-in: three habit rings (hydration, caffeine, sunlight) with tap-to-log for manual habits (caffeine); mood picker row with five mood options (great / good / okay / stressed / awful). Habits persist via `WatchHabitViewModel` (UserDefaults); moods via `WatchMoodViewModel` (UserDefaults).
5. **Workout (`WatchWorkoutView`)** - Live workout HR zone display: big BPM number, current zone badge with zone color (5 zones based on max HR), elapsed time, per-zone time distribution mini-chart, and Stop button. Powered by `WatchWorkoutViewModel`.
6. **Cycle (`WatchCycleView`)** - Menstrual cycle phase tracking: current phase card (menstrual / follicular / ovulation / luteal), day-of-cycle indicator, next phase prediction, and stress correlation note. Powered by `WatchCycleViewModel` (UserDefaults-backed).
7. **Watch Face Settings (`WatchFaceSettingsView`)** - Warm cream background (`settingsCanvas`); live preview card; 2x2 background style picker; five-character theme picker row; navigation links to **Seasonal Themes** picker (Spring / Lunar New Year / Halloween / Holiday) and **Rename Tiers** editor (custom stress level names); selected state shown with an accent-strong border and checkmark.

## Stress primitives (reused from iOS DS)

These primitives are not invented for the watch - they are the same ones used by the iOS app, scoped to the watch canvas.

| Primitive | Description | Where used |
| --- | --- | --- |
| **Semicircle gauge** | 180° arc, open at bottom, numeric label in the gap, multi-stop tier gradient reveals more spectrum as the score climbs | Home (preferred - the vertical tide gauge is too tall for the watch) |
| **Ring** | Circular; dash-array drives fill = score/100 | Measurement flow, complications |
| **Bar chart** | 7-day stress bars, hairline gridlines, tier colors, today outlined | History |
| **Grouped list** | iOS Settings lineage - 16pt margins, 0.5pt separators, 28pt icon wells | History, Settings |

## Complications (4 WidgetKit families)

The watch ships WidgetKit-based complications under `StressMonitor/StressMonitorWatch Watch App/Complications/`, registered through `ComplicationBundle.swift`. All four families show the numeric score, use the iOS stress colors for tier encoding, and render the Ripple companion glyph. They render on the system dark complication canvas - this is correct per watchOS convention (complications are always-on-dark by platform contract), and is the one place the dark palette is acceptable.

| Family | Content |
| --- | --- |
| **Accessory Circular** | Character face / ring in tier color |
| **Accessory Rectangular** | Character glyph + score (SF Pro Rounded) + tier label + accent bar |
| **Accessory Inline** | Single line: "42 · Mild" |
| **Accessory Corner** (watchOS 10+) | Minimal character glyph + "Ripple" label |

See [StressMonitor Widget](stress-monitor-widget.md) for the home-screen widget extension, which is a separate iOS target.

## How it works

The watch app duplicates the iOS stress algorithm source files rather than sharing a package, because watchOS targets cannot embed iOS framework builds. `WatchHealthKitManager` queries HRV and heart rate directly from the on-watch HealthKit store, packs them into a `StressContext`, and runs the same five-factor `MultiFactorStressCalculator` as the iPhone app.

`WatchConnectivityManager` (at `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`) opens a `WCSession` and exchanges `WatchSharedData` messages with `PhoneConnectivityManager` on the iPhone. This lets the watch display the latest phone-side measurement and vice versa. The watch app also supports custom watch face background personalization through `WatchFacePreferences` (persisted locally) and `WatchFaceSettingsView`.

### Bio Age, Habits, and Mood (parity with iOS)

The watch mirrors the iOS app's BioAge infrastructure. `BioAgeCalculator` (at `Services/BioAgeCalculator.swift`) estimates biological age from HRV, resting heart rate, and sleep efficiency using age-group norm tables. The result (`BioAgeResult`) includes a trend direction, confidence score, and character expression. The watch version adapts the iOS `hasEnoughData(measurements:)` check to use `WatchStressMeasurement`.

Daily habits (hydration, caffeine, sunlight) are tracked via `WatchHabitViewModel` with UserDefaults persistence (the watch does not use SwiftData). `WatchMoodViewModel` stores mood logs with optional stress-level snapshots, capped at 100 entries.

### Workout, Cycle, and Customization (watch-native)

**Workout HR Zones**: `WatchWorkoutViewModel` tracks live heart rate during workouts and maps it to 5 zones (Recovery / Endurance / Tempo / Threshold / Max) based on max HR (220 - age). Zone time distribution is tracked in real time.

**Cycle Tracking**: `WatchCycleViewModel` stores menstrual cycle data in UserDefaults, predicting the current phase (menstrual / follicular / ovulation / luteal) and surfacing stress correlations for each phase.

**Seasonal Themes**: `SeasonalTheme` enum provides four costume overlay themes (Spring / Lunar New Year / Halloween / Holiday) selectable via `WatchSeasonalPickerView`.

**Tier Rename**: `TierNamePreferences` lets users customize the display names for each stress tier (Relaxed / Mild / Moderate / High), persisted via UserDefaults and surfaced everywhere via `displayName(for:)`.

### What did NOT change

The redesign touched only the visual layer. The following were preserved as-is:

- `WatchHealthKitManager` and `WatchHealthKitManager+MultiFactorFetch` (HealthKit reads)
- `MultiFactorStressCalculator`, `StressCalculator`, and the five `StressFactor` implementations
- `WatchConnectivityManager` (WCSession sync)
- `WatchSharedDataStore` (App Group snapshot)
- `WatchStressViewModel` logic and the rest of `ViewModels/`
- Complication data providers and timeline logic

## Directory layout

```
StressMonitorWatch Watch App/
├── StressMonitorWatchApp.swift     # @main
├── ContentView.swift               # Root paged TabView (7 screens)
├── Services/
│   ├── WatchHealthKitManager.swift         # HealthKit reads (HRV, HR)
│   ├── WatchHealthKitManager+MultiFactorFetch.swift
│   ├── MultiFactorStressCalculator.swift   # Mirror of iOS calculator
│   ├── BioAgeCalculator.swift              # Mirror of iOS Bio Age (HRV/RHR/Sleep)
│   ├── WatchConnectivityManager.swift      # Phone sync via WCSession
│   ├── WatchSharedDataStore.swift          # App Group shared snapshot
│   ├── StressCalculator.swift              # Fallback 2-factor
│   └── 5 StressFactor implementations
├── Models/
│   ├── StressMeasurement.swift             # WatchStressMeasurement (observable)
│   ├── BioAgeResult.swift                  # Bio Age result + trend enum
│   ├── Habit.swift                         # WatchHabit + HabitType + HabitSource
│   ├── Mood.swift                          # WatchMood enum + WatchMoodLog
│   ├── WorkoutZone.swift                   # 5 HR zones + WorkoutReading
│   ├── CyclePhase.swift                    # Menstrual phases + CycleData
│   ├── SeasonalTheme.swift                 # 4 seasonal costume themes
│   └── TierNamePreferences.swift           # Custom tier display names
├── ViewModels/
│   ├── WatchStressViewModel.swift          # Main stress measurement
│   ├── WatchHabitViewModel.swift           # Daily habits (UserDefaults)
│   ├── WatchMoodViewModel.swift            # Mood logs (UserDefaults)
│   ├── WatchWorkoutViewModel.swift         # Live workout HR zones
│   └── WatchCycleViewModel.swift           # Cycle phase tracking
├── Views/
│   ├── WatchHomeView.swift
│   ├── WatchHistoryView.swift              # + Bio Age card, heatmap, range picker
│   ├── WatchBreatheView.swift
│   ├── WatchLoggingView.swift              # Habits + mood check-in
│   ├── WatchWorkoutView.swift              # Live HR zone display
│   ├── WatchCycleView.swift                # Cycle phase tracking
│   ├── WatchBioAgeCardView.swift           # Bio Age summary card
│   ├── WatchFaceSettingsView.swift         # + Seasonal + Tier rename links
│   ├── Settings/
│   │   ├── WatchSeasonalPickerView.swift   # Seasonal theme carousel
│   │   └── TierNameEditorView.swift        # Custom tier name form
│   └── Components/
│       ├── SemicircleStressGauge.swift     # Signature Home gauge
│       ├── StressBarChart.swift            # Bar chart
│       ├── HabitRingView.swift             # Circular habit progress ring
│       ├── MoodPickerRow.swift             # 5-button mood selector
│       ├── CalendarHeatmapView.swift       # Stress intensity grid
│       ├── RangePickerRow.swift            # 7D / 30D / 90D segmented control
│       └── CompactStressView.swift
├── Complications/                   # 4 WidgetKit complication families
│   ├── ComplicationBundle.swift
│   ├── Providers/
│   ├── Views/
│   └── Services/
└── Theme/
    ├── WatchDesignTokens.swift
    ├── StressCharacter.swift
    ├── WatchFaceBackgroundStyle.swift
    └── Color+Extensions.swift
```

## Key source files

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift` | `@main` entry point |
| `StressMonitor/StressMonitorWatch Watch App/ContentView.swift` | Root paged `TabView` across the four screens |
| `StressMonitor/StressMonitorWatch Watch App/Theme/WatchDesignTokens.swift` | iOS-aligned tokens: light surfaces, radii (12/14/18/22), motion timings (150/200/400-600ms), spacing (4/8/12/16/20/24/32) |
| `StressMonitor/StressMonitorWatch Watch App/Theme/StressCharacter.swift` | Five elemental companions as inline SVG illustrations + light palette |
| `StressMonitor/StressMonitorWatch Watch App/Theme/WatchFaceBackgroundStyle.swift` | Four background styles (Solid/Gradient/Aurora/Ocean) rendered as light soft tints |
| `StressMonitor/StressMonitorWatch Watch App/Theme/Color+Extensions.swift` | `Color(hex:)` initializer and stress tier accessor |
| `StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift` | 5-tier enum aligned to iOS (Relaxed/Mild/Moderate/High/Severe) with dual-coding glyphs |
| `StressMonitor/StressMonitorWatch Watch App/Views/WatchHomeView.swift` | Semicircle gauge hero + Ripple companion + "Measure now" CTA |
| `StressMonitor/StressMonitorWatch Watch App/Views/WatchBreatheView.swift` | 4-7-8 guided breathing with animated ring and phase dots |
| `StressMonitor/StressMonitorWatch Watch App/Views/WatchHistoryView.swift` | Stat cards + 7-day bar chart + grouped reading list |
| `StressMonitor/StressMonitorWatch Watch App/Views/WatchFaceSettingsView.swift` | Watch face preview, background style picker, character theme picker |
| `StressMonitor/StressMonitorWatch Watch App/Views/Components/SemicircleStressGauge.swift` | Signature 180° Home gauge (new) |
| `StressMonitor/StressMonitorWatch Watch App/Views/Components/StressBarChart.swift` | 7-day stress bar chart (new) |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift` | On-watch HealthKit reads |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` | WCSession sync to phone |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift` | App Group snapshot read/write |
| `StressMonitor/StressMonitorWatch Watch App/Services/MultiFactorStressCalculator.swift` | iOS-mirrored stress algorithm (unchanged) |
| `StressMonitor/StressMonitorWatch Watch App/Complications/ComplicationBundle.swift` | WidgetKit registration for all 4 families (Corner lives inline here) |
