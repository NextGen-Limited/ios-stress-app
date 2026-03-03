# Phase 5 — Heatmap Dot Grid

**Priority:** Medium | **Effort:** Small | **Status:** Completed

## Overview

Update WeeklyHeatmapView from square cells to circular dots matching Figma. Simplify to show day rows with colored dot columns.

## Design Specs
- Title: "Daily Timeline" (existing)
- Rows: Mon-Sun (full 3-letter labels, not single letter)
- Columns: colored circles (not squares)
- Colors: stress level colors (green/teal/orange/yellow/grey for empty)
- No horizontal scroll needed — show fewer columns, larger dots

## Changes to WeeklyHeatmapView.swift

1. Change cell shape from `RoundedRectangle` to `Circle`
2. Increase `cellSize` from 12 to 14
3. Show full day labels ("Mon", "Tue" etc.) instead of single letter
4. Remove hour labels row at bottom (Figma doesn't show them)
5. Simplify to 8-10 columns instead of 24 hours (aggregate time blocks)

Key diff:
```swift
// OLD
RoundedRectangle(cornerRadius: 2)
    .fill(colorFor(day: dayIndex, hour: hour))
    .frame(width: cellSize, height: cellSize)

// NEW
Circle()
    .fill(colorFor(day: dayIndex, block: blockIndex))
    .frame(width: cellSize, height: cellSize)
```

## Files Modified
- `Views/Trends/Components/WeeklyHeatmapView.swift`

## Success Criteria
- Circular dots instead of squares
- Day labels visible as 3-letter abbreviations
- Clean grid without hour labels

## Completion Notes

Completed 2026-03-02. `WeeklyHeatmapView.swift` updated: `RoundedRectangle` cells → `Circle`, `cellSize` 12 → 14, day labels expanded to 3-letter ("Mon"/"Tue" etc.), hour-row labels removed, columns condensed to 8 time-block aggregates.
