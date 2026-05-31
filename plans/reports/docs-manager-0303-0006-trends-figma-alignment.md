# Docs Update: Trends View Figma Alignment

**Date:** 2026-03-03
**Trigger:** Trends View Figma alignment implementation (8 phases + 2 bug fixes)

---

## Current State Assessment

4 docs warranted updates. 12 docs unaffected (architecture, deployment, code-standards, etc.).

---

## Changes Made

### 1. `docs/codebase-summary.md`

- Replaced stale "Trends Module (6 files, ~420 LOC)" table with accurate 13-file/~1,070 LOC table
- Added all new/updated component rows: `StressBarChartView`, `LineChartView`, `WeeklyHeatmapView`, `StressSourcesDonutChart`, `PremiumBannerView`, `MascotSpeechBubbleView`, `SmartInsightsTeaser`
- Noted removal of global NavigationStack/TimeRangePicker from `TrendsView`
- Added card design note (Mar 2026 pattern)
- Cleaned up `(NEW)` tags in `StressViewModel` properties (no longer new)
- Added simulator guard note to `startAutoRefresh()` description
- Updated `Last Updated` → March 3, 2026

### 2. `docs/design-guidelines-visual.md`

- Renamed "Settings Card Shadow (NEW Mar 2026)" → "Settings Card Shadow (Mar 2026)"
- Added new **Standard Card Pattern** section documenting `adaptiveCardBackground` + `settingsCardRadius` + shadow as the canonical card style for all screens (Settings, Trends, and new screens)

### 3. `docs/design-guidelines-ux.md`

- Rewrote **Trends Analysis View** section to reflect Mar 2026 Figma layout
- Added card inventory table (component name, chart type) for each of the 6 cards
- Documented removal of global header/filter
- Referenced Standard Card Pattern in visual guidelines
- Documented `MascotSpeechBubbleView` component

### 4. `docs/project-roadmap.md`

- Added Trends Figma alignment checklist under "User Interface" (Mar 2026), listing all 9 components/changes
- Split "Settings screen" and "Trend analytics" into explicit line items
- Added 2 new bug fix entries:
  - Fixed invalid NavigationStack wrapper in `StressMonitorApp.swift`
  - Added simulator guard in `StressViewModel.startAutoRefresh()`
- Updated Last Review → March 3, 2026

---

## Validation

- 34 internal links: all OK
- 44 code-reference warnings: pre-existing across other docs; none introduced by these changes
- `StressBarChartView` / `WeeklyHeatmapView` validator warnings are false positives (validator scans `src/`, project uses Xcode structure under `StressMonitor/`)

---

## Gaps Identified

- `docs/design-guidelines-ux.md` previously described filter options (Today/Week/Month/etc.) that are now per-card; the old filter description was replaced — if per-card time range options still exist in some cards, those should be documented per-card in a future pass
- `CircularStressIndicatorView.swift` still exists in codebase but is superseded; no deprecation notice in code

## Unresolved Questions

- None
