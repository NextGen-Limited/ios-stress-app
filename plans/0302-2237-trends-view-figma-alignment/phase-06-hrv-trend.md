# Phase 6 — Polish HRV Trend Card

**Priority:** Low | **Effort:** Small | **Status:** Completed

## Overview

Minor polish to HRV Trend card: add "Last 30 days" subtitle, Y-axis labels, "Today" label.

## Design Specs
- Title: "HRV Trend" (bold)
- Subtitle: "Last 30 days" (grey, below title)
- Y-axis: labels at 0, 50, 100, 150
- X-axis: "Today" label at far right
- Line chart with circular data points (current LineChartView already does this)

## Changes

### TrendsView.swift — hrvTrendCard
1. Add "Last 30 days" subtitle below title
2. Add Y-axis labels overlay on left side of chart
3. Add "Today" label below chart on right

```swift
// After title
Text("Last 30 days")
    .font(Typography.caption1)
    .foregroundColor(.secondary)

// After chart
HStack {
    Spacer()
    Text("Today")
        .font(Typography.caption2)
        .foregroundColor(.secondary)
}
```

### LineChartView.swift — Add Y-axis labels
Add optional Y-axis label display:
- Overlay VStack with values [150, 100, 50, 0] on left edge
- Light grey dashed grid lines already exist

## Files Modified
- `Views/Trends/TrendsView.swift` — subtitle + "Today" label
- `Views/Trends/Components/LineChartView.swift` — optional Y-axis labels

## Success Criteria
- "Last 30 days" subtitle visible
- Y-axis numbers (0, 50, 100, 150) on left
- "Today" label at bottom right

## Completion Notes

Completed 2026-03-02. `TrendsView.swift` `hrvTrendCard` updated: "Last 30 days" subtitle added below title, "Today" trailing label added below chart. `LineChartView.swift` updated with optional Y-axis overlay rendering [150, 100, 50, 0] on left edge.
