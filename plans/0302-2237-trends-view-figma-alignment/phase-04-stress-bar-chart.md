# Phase 4 — Stress Over Time Bar Chart

**Priority:** High | **Effort:** Large | **Status:** Completed

## Overview

Replace the 4 circular stress indicators with a proper bar chart (Mon-Sun) matching Figma. Use Swift Charts (iOS 16+, project targets 17+).

## Design Specs
- Title: "Stress over time" (bold) + "Last 7 days" dropdown (right)
- Vertical bar chart: 7 bars (Mon-Sun), Y-axis 0-100
- Bars have rounded tops, colored by stress level
- Below chart: 4 color-coded legend items (Relaxed/Normal/Warning/Stressed with %)
- Light grey dashed horizontal grid lines at 25, 50, 75, 100

## New Component — StressBarChartView.swift

Uses `import Charts` (Swift Charts framework).

```swift
struct StressBarChartView: View {
    let dailyStress: [DailyStressData] // 7 items, one per day
    let distribution: StressDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Stress over time")
                    .font(Typography.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("Last 7 days")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            // Bar chart using Swift Charts
            Chart(dailyStress) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value("Stress", item.averageStress)
                )
                .foregroundStyle(Color.stressColor(for: item.averageStress))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis { ... }
            .frame(height: 180)

            // Legend row
            HStack(spacing: 16) {
                legendItem(color: .stressRelaxed, label: "Relaxed", pct: distribution.relaxed)
                legendItem(color: .stressMild, label: "Normal", pct: distribution.normal)
                legendItem(color: .stressModerate, label: "Warning", pct: distribution.elevated)
                legendItem(color: .stressHigh, label: "Stressed", pct: distribution.high)
            }
        }
    }
}
```

### DailyStressData model
Add to TrendsViewModel.swift:
```swift
struct DailyStressData: Identifiable {
    let id = UUID()
    let dayLabel: String   // "Mon", "Tue", etc.
    let averageStress: Double
}
```

### TrendsViewModel changes
- Add `var dailyStressData: [DailyStressData] = []`
- In `loadTrendData()`, compute daily averages grouped by weekday
- Remove dependency on circular indicators in view

### TrendsView changes
- Replace `stressOverTimeCard` with `StressBarChartView`
- Remove `CircularStressIndicatorView` usage from TrendsView

## Files
- **New:** `Views/Trends/Components/StressBarChartView.swift`
- **Modified:** `Views/Trends/TrendsViewModel.swift` — add dailyStressData, DailyStressData model
- **Modified:** `Views/Trends/TrendsView.swift` — replace stressOverTimeCard

## Notes
- `CircularStressIndicatorView.swift` and `DistributionBarView.swift` may become unused — keep for now, can clean up later
- Import `Charts` in StressBarChartView only

## Success Criteria
- 7-bar chart visible (Mon-Sun)
- Bars colored by stress level
- Legend row with 4 categories + percentages below chart

## Completion Notes

Completed 2026-03-02. New `StressBarChartView.swift` using Swift Charts `BarMark` with `cornerRadius(4)`, Y-axis 0–100, dashed grid lines at 25/50/75. `DailyStressData` model added to `TrendsViewModel.swift`. `loadTrendData()` computes weekly averages grouped by weekday. `stressOverTimeCard` in `TrendsView.swift` replaced with `StressBarChartView`. 4-item color-coded legend with distribution %s rendered below chart.
