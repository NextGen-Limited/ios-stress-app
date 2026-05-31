# TrendsView Enhancement Plan

## Overview
Enhance the existing TrendsView to align with Figma design (trends-home-ui.png). Current implementation has ~80% coverage; this plan addresses remaining gaps.

## Current State
- PremiumBannerView ✅
- HorizontalWeekCalendarView ✅
- MascotSpeechBubbleView ✅
- StressBarChartView ✅ (needs enhancement)
- WeeklyHeatmapView ✅
- LineChartView ✅
- StressSourcesDonutChart ✅
- SmartInsightsTeaser ✅

## Gaps Identified

### 1. Stress Category Naming
- **Current**: Relaxed, Normal, Elevated, High
- **Figma**: Relaxed, Normal, Warning, Stressed
- **Impact**: StressBarChartView legend, color constants

### 2. Interactive Time Range Filter
- **Current**: Static "Last 7 days" text
- **Figma**: Dropdown with chevron icon (Last 7 days, Last 14 days, Last 30 days)
- **Impact**: StressBarChartView, TrendsViewModel

### 3. Grouped Bar Chart Display
- **Current**: Single bar per day colored by average stress
- **Figma**: Stacked/grouped bars showing distribution of each stress level per day
- **Impact**: StressBarChartView (major redesign needed)

## Phase 1: Stress Category Naming Update
**Priority**: Low | **Effort**: Small

### Steps
1. Update `Color+Stress.swift` - rename stress categories if needed
2. Update `StressBarChartView` legend labels: Elevated → Warning, High → Stressed
3. Verify all references across codebase

### Files to Modify
- `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift`

## Phase 2: Interactive Time Range Filter
**Priority**: Medium | **Effort**: Medium

### Steps
1. Add `timeRange` state to `TrendsViewModel`
2. Add TimeRangePicker or modify existing picker component
3. Update `StressBarChartView` to accept selected time range
4. Add filtering logic for 7/14/30 days

### Files to Modify
- `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift`
- `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`
- `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift`

## Phase 3: Grouped Bar Chart Enhancement
**Priority**: High | **Effort**: Large

### Steps
1. Redesign `StressBarChartView` to show stacked bars per day
2. Each day bar shows segments for: Relaxed, Normal, Warning, Stressed
3. Update `DailyStressData` model to include distribution data
4. Update `TrendsViewModel` to compute distributions per day
5. Update legend to reflect distribution percentages

### Files to Modify
- `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift`
- `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift`

### Data Model Change
```swift
// Current
struct DailyStressData {
    let dayLabel: String
    let averageStress: Double
}

// Enhanced
struct DailyStressData {
    let dayLabel: String
    let averageStress: Double
    let distribution: StressDistribution // relaxed, normal, warning, stressed percentages
}
```

## Dependencies
- Phase 1 → Phase 2 (can be parallel)
- Phase 2, Phase 1 → Phase 3 (Phase 3 depends on updated model from Phase 2)

## Success Criteria
- [ ] Stress categories match Figma (Warning, Stressed)
- [ ] Time range filter is interactive with 7/14/30 day options
- [ ] Bar chart shows distribution per day (stacked bars)
- [ ] All components compile without errors
- [ ] UI matches Figma design screenshot

## Risk Assessment
- **Medium**: Grouped bar chart redesign may require significant ViewModel changes
- **Low**: Naming changes are straightforward string replacements

## Validation Log

| Question | Decision | Notes |
|----------|----------|-------|
| Phase 1: Update stress labels to Figma? | ✅ Yes | Use Warning, Stressed |
| Phase 2: Time range UI pattern? | ✅ Menu picker | Clean iOS pattern |
| Phase 3: Grouped bar implementation? | ✅ Stacked bars | Full Figma alignment |
| Which phases to implement? | ✅ All 3 | Full implementation |

### Validation Confirmed
- Phase 1: Update labels (Elevated→Warning, High→Stressed)
- Phase 2: Add menu picker for 7/14/30 days
- Phase 3: Implement stacked bars showing distribution per day
- All phases will be implemented in sequence
