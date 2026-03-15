# SwiftUI Charts Migration Plan

## Overview

Migrate all custom Path-based charts to native SwiftUI Charts framework (iOS 16+) for better accessibility, consistency, and maintainability.

**Status:** Completed
**Priority:** Medium
**Effort:** 2 hours

---

## Current State Analysis

### Already Using Swift Charts ✅

| Chart | Location | Status |
|-------|----------|--------|
| `StressBarChartView` | Trends/Components | Done - uses `BarMark` |

### Needs Migration ⚠️

| # | Chart | Location | Current | Target |
|---|-------|----------|---------|--------|
| 1 | `LineChartView` | Trends/Components | Custom Path | `Chart + LineMark` |
| 2 | `MiniLineChartView` | Dashboard/Components | Custom Path | `Chart + LineMark` |
| 3 | `StressOverTimeChart` | Dashboard/Components | Custom HStack | `Chart + BarMark` |
| 4 | `BeforeAfterChart` | Breathing/Components | Custom GeometryReader | `Chart + BarMark` |

### Keep As-Is ⏸️

| Chart | Reason |
|-------|--------|
| `StressSourcesCard` donut | SwiftUI Charts has no native donut (iOS 16/17) |
| Canvas-based donut is acceptable for this use case |

### Delete ❌

| Chart | Reason |
|-------|--------|
| `StressSourcesDonutChart.swift` | Unused - replaced by `StressSourcesCard` |

---

## Phases

### Phase 1: Cleanup
Delete unused `StressSourcesDonutChart.swift` (DRY compliance)

### Phase 2: LineChartView Migration
Convert custom Path line chart to `Chart + LineMark + AreaMark`
- **Preserve touch interaction** via `chartOverlay` + `GeometryProxy`
- Implement point selection with `chartSelection(value:)` modifier

### Phase 3: MiniLineChartView Migration
Convert to `Chart + LineMark` for metric cards
- **Risk:** Current height is 40pt - may need layout adjustment
- Use `.chartPlotStyle` for compact rendering
- Test in HealthStatCard context

### Phase 4: StressOverTimeChart Migration
Bar chart with category coloring
- **Preserve premium gating** (PremiumLockOverlay)
- Migrate to `Chart + BarMark` with conditional coloring

### Phase 5: BeforeAfterChart Migration
Two-bar comparison chart
- Simplest migration - just two bars
- Use `BarMark` with fixed domain

---

## Technical Decisions

### 1. Import Statement
```swift
import Charts  // Required for SwiftUI Charts
```

### 2. Data Model Compatibility
Keep existing `ChartDataPoint`, `DailyStressData` models - compatible with Charts

### 3. Gradient Fills
Use `.chartPlotStyle` + `ZStack` for area fills under line charts

### 4. Touch Interaction
SwiftUI Charts supports `chartOverlay` for gesture handling

---

## Success Criteria

- [x] All 4 custom charts migrated to SwiftUI Charts
- [x] Unused `StressSourcesDonutChart.swift` deleted
- [x] No visual regressions
- [x] Accessibility improved (Charts has built-in VoiceOver support)
- [x] Build succeeds (warnings are pre-existing)

---

## Cook Command

```
/cook /Users/ddphuong/Projects/next-labs/ios-stress-app/plans/0308-swiftui-charts-migration/plan.md
```
