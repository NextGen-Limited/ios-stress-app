# Plan: Replace DailyTimelineView with Weekly Dot-Matrix Design

**Status:** ✅ Completed
**Priority:** Medium
**Effort:** Small (single file replacement + caller update)
**Plan Dir:** `plans/0303-0928-daily-timeline-weekly-redesign/`

---

## Context

The Figma design shows a "Daily Timeline" chart that is actually a **7-day × N-time-slot dot matrix** (weekly heatmap), not a single-day scatter plot. The current `DailyTimelineView` is a 24-hour horizontal scatter chart used only in the Dashboard and is **not referenced** by any other view (confirmed via grep — only defined in its own file).

Separately, `WeeklyHeatmapView` already exists in Trends and implements the same concept but with a different visual style (small 14px dots, tight spacing).

**Decision:** Replace `DailyTimelineView` in-place to match the Figma design — a weekly dot-matrix grid with:
- 7 rows (Mon–Sun)
- 7 time-slot columns (labeled time periods)
- ~20px pastel colored dots
- White card, ~20px corner radius, shadow
- "Daily Timeline" title, "Last 7 days" subtitle

The `WeeklyHeatmapView` in Trends is **left unchanged** (different context, Trends tab).

---

## Phases

| Phase | File | Status |
|-------|------|--------|
| [Phase 1](phase-01-rewrite-daily-timeline-view.md) | Replace `DailyTimelineView.swift` with weekly dot-matrix | ✅ Completed |
| [Phase 2](phase-02-update-dashboard-usage.md) | Add to `StressDashboardView` + supply 7-day measurements | ✅ Completed |

---

## Key Design Specs (from Figma + image analysis)

- **Card**: white bg, 20px corner radius, subtle shadow
- **Title**: "Daily Timeline", ~18pt bold, `#363636` / system dark
- **Day labels**: "Mon"–"Sun", ~13pt bold, left column
- **Time columns**: 7 columns (approx 3-hour blocks: 12AM, 3AM, 6AM, 9AM, 12PM, 3PM, 6PM)
- **Dots**: ~19px circles, 5 colors:
  - No data: `#D9D9D9` (gray, 15% opacity secondary)
  - Relaxed (0–25): `#B0E0C6` mint green
  - Mild (26–50): `#A6D9D9` teal/blue
  - Moderate (51–75): `#F9E0A6` pastel yellow
  - High (76–100): `#F9C7A6` peach/orange
- **Gap between dots**: ~22px horizontal, ~24px vertical
- **Padding**: 24px all sides

---

## Dependencies

- `StressMeasurement` model (existing) — has `timestamp`, `stressLevel`
- `Color.stressColor(for: Double)` (existing) — maps 0–100 to stress colors
- `Color.adaptiveCardBackground` (existing) — for card background
- `Spacing.settingsCardRadius` / `AppShadow.settingsCard` (existing) — for card styling
- `Typography.title2`, `Typography.caption1` (existing)
