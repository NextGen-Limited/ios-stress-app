# Phase 01: Layout + Component Integration

**Parent:** [plan.md](./plan.md)
**Status:** pending
**Priority:** P1 (highest)
**Effort:** 1.5h

---

## Context

- **Brainstorm:** [brainstorm-0223-2217-dashboard-ui-enhancement.md](../reports/brainstorm-0223-2217-dashboard-ui-enhancement.md)
- **Codebase:** [codebase-summary.md](../../docs/codebase-summary.md)
- **Code Standards:** [code-standards-swift.md](../../docs/code-standards-swift.md)

---

## Overview

Restructure DashboardView to use unified scroll layout with all existing dashboard components integrated in Ring-Focused order.

---

## Key Insights

1. All components already exist in `Views/Dashboard/Components/`
2. StressRingView needs size increase from 220pt → 260pt
3. ViewModel needs additional data properties for new components
4. OLED colors already defined in `Color+Extensions.swift`

---

## Requirements

### Functional
- Display all 6 components in single scrollable view
- Component order: Header → Ring → Metrics → LiveHR → Timeline → Weekly → AI Insight
- Maintain existing accessibility labels

### Non-Functional
- OLED dark theme consistency
- 60fps scroll performance (use LazyVStack)
- File size <200 LOC per file

---

## Architecture

### Current Structure
```
DashboardView
├── NavigationStack
│   ├── loadingView
│   ├── content(stress)
│   │   ├── header
│   │   ├── StressRingView (220pt)
│   │   ├── statusText
│   │   ├── MeasureButton
│   │   └── liveHeartRateCard
│   └── emptyState
```

### Target Structure
```
DashboardView
├── NavigationStack
│   └── ScrollView + LazyVStack
│       ├── greetingHeader
│       ├── StressRingView (260pt)
│       ├── metricsRow (HRV + HR cards)
│       ├── liveHeartRateCard (conditional)
│       ├── DailyTimelineView
│       ├── WeeklyInsightCard
│       └── AIInsightCard
```

---

## Related Code Files

### Modify
| File | Changes |
|------|---------|
| `Views/DashboardView.swift` | Restructure layout, integrate components |
| `Views/Dashboard/Components/StressRingView.swift` | Change frame 220 → 260pt |
| `ViewModels/StressViewModel.swift` | Add hrvHistory, todayMeasurements, weeklyData, insight properties |

### Read-Only (existing components)
- `Views/Dashboard/Components/MetricCardView.swift`
- `Views/Dashboard/Components/DailyTimelineView.swift`
- `Views/Dashboard/Components/WeeklyInsightCard.swift`
- `Views/Dashboard/Components/AIInsightCard.swift`
- `Views/Dashboard/Components/MiniLineChartView.swift`

---

## Implementation Steps

### Step 1: Update StressViewModel Properties (15 min)

Add new properties to support all components:

```swift
// In StressViewModel.swift
var hrvHistory: [Double] = []           // Last 7 HRV readings for chart
var heartRateTrend: TrendDirection = .stable
var todayMeasurements: [StressMeasurement] = []
var weeklyCurrentAvg: Double = 0
var weeklyPreviousAvg: Double = 0
var aiInsight: AIInsight?

enum TrendDirection { case up, down, stable }
```

### Step 2: Add Data Loading Methods (20 min)

```swift
func loadDashboardData() async {
    await loadCurrentStress()
    await loadTodayMeasurements()
    await loadWeeklyComparison()
    generateInsight()
}

func loadTodayMeasurements() async {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    todayMeasurements = historicalData.filter { $0.timestamp >= startOfDay }
    hrvHistory = Array(todayMeasurements.map { $0.hrv }.suffix(7))
}

func loadWeeklyComparison() async {
    // Calculate current vs previous week averages
    let calendar = Calendar.current
    let now = Date()
    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!

    let currentWeek = historicalData.filter { $0.timestamp >= weekStart }
    let prevWeek = historicalData.filter { $0.timestamp >= prevWeekStart && $0.timestamp < weekStart }

    weeklyCurrentAvg = currentWeek.isEmpty ? 0 : currentWeek.map(\.stressLevel).reduce(0,+) / Double(currentWeek.count)
    weeklyPreviousAvg = prevWeek.isEmpty ? 0 : prevWeek.map(\.stressLevel).reduce(0,+) / Double(prevWeek.count)
}

func generateInsight() {
    // Local rules engine (Phase 2 will enhance)
    guard let stress = currentStress else { return }
    aiInsight = InsightGenerator.generate(from: stress, history: historicalData)
}
```

### Step 3: Update StressRingView Size (10 min)

```swift
// In StressRingView.swift, change:
.frame(width: 220, height: 220)
// To:
.frame(width: 260, height: 260)
```

### Step 4: Restructure DashboardView Layout (45 min)

Replace current `content()` with unified scroll:

```swift
private func content(_ stress: StressResult) -> some View {
    ScrollView {
        LazyVStack(spacing: DesignTokens.Layout.sectionSpacing) {
            // 1. Greeting Header
            greetingHeader

            // 2. Hero Stress Ring (260pt)
            StressRingView(stressLevel: stress.level, category: stress.category)
                .frame(height: 300)  // Accommodate 260pt ring + padding
                .accessibilityLabel("Stress level")
                .accessibilityValue("\(Int(stress.level)) out of 100, \(stress.category.rawValue)")

            // 3. Metrics Row (HRV + HR)
            metricsRow

            // 4. Live Heart Rate (conditional)
            if viewModel.liveHeartRate != nil {
                liveHeartRateCard
            }

            // 5. Daily Timeline
            DailyTimelineView(
                measurements: viewModel.todayMeasurements,
                isExpanded: false
            )

            // 6. Weekly Insight
            WeeklyInsightCard(
                currentWeekAvg: viewModel.weeklyCurrentAvg,
                lastWeekAvg: viewModel.weeklyPreviousAvg,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                endDate: Date()
            )

            // 7. AI Insight (conditional)
            if let insight = viewModel.aiInsight {
                AIInsightCard(insight: insight)
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(Color.oledBackground)
}

private var metricsRow: some View {
    HStack(spacing: DesignTokens.Spacing.md) {
        MetricCardView.hrv(
            value: String(Int(viewModel.currentStress?.hrv ?? 0)),
            chartData: viewModel.hrvHistory
        )

        MetricCardView.heartRate(
            value: String(Int(viewModel.currentStress?.heartRate ?? 0)),
            trendValue: "-2 bpm",  // Calculate from history
            isDown: true
        )
    }
}
```

---

## Todo List

- [ ] Add new properties to StressViewModel
- [ ] Implement `loadDashboardData()` method
- [ ] Implement `loadTodayMeasurements()` method
- [ ] Implement `loadWeeklyComparison()` method
- [ ] Create `InsightGenerator` service with basic rules
- [ ] Update StressRingView frame to 260pt
- [ ] Restructure DashboardView content() with unified scroll
- [ ] Add metricsRow computed property
- [ ] Update greetingHeader for OLED dark
- [ ] Verify all components render correctly
- [ ] Run compile check

---

## Success Criteria

- [ ] All 6 components visible in unified scroll
- [ ] StressRing at 260pt
- [ ] Metrics row shows HRV + HR side-by-side
- [ ] Timeline shows today's measurements
- [ ] Weekly card shows comparison
- [ ] AI insight card appears when insight available
- [ ] OLED dark theme consistent
- [ ] No compile errors

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing data for components | Medium | Each component handles empty state |
| Layout overflow | Low | Test on SE and Pro Max sizes |
| Performance with LazyVStack | Low | LazyVStack optimized for scrolling |

---

## Security Considerations

- No security concerns for layout changes
- Health data already protected by HealthKit permissions

---

## Next Steps

After completion:
1. Run compile check
2. Test on simulator
3. Proceed to Phase 02 (Auto-Refresh)
