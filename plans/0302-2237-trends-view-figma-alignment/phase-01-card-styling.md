# Phase 1 — Card Styling & Remove Header

**Priority:** High | **Effort:** Small | **Status:** Completed

## Overview

Remove standalone "Trends" title + TimeRangePicker. Unify all card backgrounds to match Settings screen pattern (white bg, rounded corners, shadow).

## Changes

### TrendsView.swift
1. Remove `headerSection` computed property entirely
2. Remove `headerSection.padding(.horizontal)` from VStack
3. Replace all card backgrounds from `Color.secondary.opacity(0.1)` to reusable card style
4. Keep `.background(Color.backgroundLight)` on ScrollView (matches Figma beige bg)

### Card Background Pattern
Replace inline card backgrounds:
```swift
// OLD
.background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.1)))

// NEW
.background(Color.adaptiveCardBackground)
.clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
.shadow(AppShadow.settingsCard)
```

Apply to: `stressOverTimeCard`, `hrvTrendCard` (inline cards in TrendsView), plus `WeeklyHeatmapView`, `StressSourcesDonutChart`, `InsightCard` (component files).

## Files Modified
- `Views/Trends/TrendsView.swift` — remove header, update card backgrounds
- `Views/Trends/Components/WeeklyHeatmapView.swift` — card background
- `Views/Trends/Components/StressSourcesDonutChart.swift` — card background
- `Views/Trends/Components/InsightCard.swift` — card background

## Success Criteria
- No "Trends" title or time picker visible
- All cards have consistent white bg, rounded corners, subtle shadow
- Background is light beige (`backgroundLight`)

## Completion Notes

Completed 2026-03-02. Removed `headerSection` and `TimeRangePicker`. Applied `adaptiveCardBackground` + `settingsCardRadius` + `AppShadow.settingsCard` to all cards in `TrendsView`, `WeeklyHeatmapView`, `StressSourcesDonutChart`, and `InsightCard`.
