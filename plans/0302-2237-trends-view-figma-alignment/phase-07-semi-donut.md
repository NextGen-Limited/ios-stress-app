# Phase 7 — Semi-Donut Chart

**Priority:** Medium | **Effort:** Medium | **Status:** Completed

## Overview

Redesign StressSourcesDonutChart from full donut to semi-donut (half-circle) with percentages on chart and 6-category legend below.

## Design Specs
- Title: "Stress sources" (left)
- Semi-circle donut (top half only) — 180° arc
- 3 visible segments: Health 50% (yellow), Finance 35% (teal), Relationship 15% (orange)
- Percentage labels positioned on/near segments
- Center text: "Last 30 days"
- Legend below: 2 rows × 3 columns — Finance, Relationship, Health, Family, Work, Environment
- Each legend item: colored circle + label

## Changes to StressSourcesDonutChart.swift

1. Change `ArcShape` to render only upper 180° (from -180° to 0°)
2. Reposition donut to center top, with legend below
3. Add percentage labels positioned around the arc
4. Expand to 6 categories with legend grid
5. Change center text from "30 days" to "Last 30 days"

### Layout change:
```
VStack {
    Title row
    Semi-donut with percentage labels (centered)
    Legend grid (3 cols × 2 rows)
}
```

### ViewModel — expand stressSources default to 6:
```swift
var stressSources: [StressSource] = [
    StressSource(name: "Finance", percentage: 35, color: Color(hex: "#00BFA5")),
    StressSource(name: "Relationship", percentage: 15, color: Color(hex: "#FF9800")),
    StressSource(name: "Health", percentage: 50, color: Color(hex: "#FFD60A")),
    StressSource(name: "Family", percentage: 0, color: .stressRelaxed),
    StressSource(name: "Work", percentage: 0, color: .primaryBlue),
    StressSource(name: "Environment", percentage: 0, color: .stressSevere),
]
```

## Files Modified
- `Views/Trends/Components/StressSourcesDonutChart.swift` — semi-donut + legend grid
- `Views/Trends/TrendsViewModel.swift` — expand stressSources to 6

## Success Criteria
- Half-circle donut rendered (not full circle)
- Percentages displayed near segments
- 6-item legend in grid below chart

## Completion Notes

Completed 2026-03-02. `StressSourcesDonutChart.swift` rewritten: `ArcShape` constrained to 180° (−π to 0), chart repositioned to top-center, percentage labels placed near segments, legend changed to 2×3 grid. `TrendsViewModel.swift` `stressSources` expanded to 6 categories (Finance/Relationship/Health/Family/Work/Environment).
