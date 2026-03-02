# Plan: Enhance Trends Screen to Match Figma Design

## Context

Enhance TrendsView to match new Figma design with premium upsell banner, circular stress indicators, weekly heatmap, and stress sources donut chart.

**User Confirmed:**
- Premium Banner: Implement now with placeholder action
- Stress Sources: Use mock data

---

## Implementation Phases

### Phase 1: Premium Banner Component
**File:** `Views/Trends/Components/PremiumBannerView.swift`

```
- Blue background (#5DADE2)
- "UNLOCK PREMIUM" title + subtitle
- Orange "Upgrade Now" button (#F39C12)
- Crown icon
```

### Phase 2: Circular Stress Indicators
**File:** `Views/Trends/Components/CircularStressIndicatorView.swift`

```
- Replace horizontal DistributionBarView with circular progress
- 4 indicators: Relaxed, Neutral, Working, Stressed
- Each shows icon + percentage in circle
- 60x60pt circles, 6pt stroke
```

### Phase 3: Weekly Heatmap
**File:** `Views/Trends/Components/WeeklyHeatmapView.swift`

```
- 7 days × 24 hours grid
- Cell size: 12×12pt
- Color by stress level (gray if no data)
- Day labels on left (M, T, W, T, F, S, S)
```

### Phase 4: Stress Sources Donut
**File:** `Views/Trends/Components/StressSourcesDonutChart.swift`

```
- Donut chart with segments
- Mock data: Work 50%, Finance 30%, Relationship 15%, Health 5%
- Legend on right side
- Center shows "30 days"
```

### Phase 5: Integrate in TrendsView
**File:** `Views/Trends/TrendsView.swift`

Layout order:
1. PremiumBannerView
2. Header + TimeRangePicker
3. Stress over time card (with circular indicators)
4. WeeklyHeatmapView
5. HRV Trend chart (existing)
6. StressSourcesDonutChart
7. Smart Insights

### Phase 6: Update ViewModel
**File:** `Views/Trends/TrendsViewModel.swift`

```
- Add weeklyMeasurements property
- Add stressSources mock data
- Process heatmap data in loadTrendData()
```

---

## Files

| File | Action |
|------|--------|
| `Views/Trends/Components/PremiumBannerView.swift` | CREATE |
| `Views/Trends/Components/CircularStressIndicatorView.swift` | CREATE |
| `Views/Trends/Components/WeeklyHeatmapView.swift` | CREATE |
| `Views/Trends/Components/StressSourcesDonutChart.swift` | CREATE |
| `Views/Trends/TrendsView.swift` | MODIFY |
| `Views/Trends/TrendsViewModel.swift` | MODIFY |

---

## Verification

1. Build: Xcode build StressMonitor scheme
2. Run: Navigate to Trends tab
3. Check:
   - Premium banner at top
   - Circular indicators (not bars)
   - 7×24 heatmap grid
   - Donut chart with legend
   - Consistent 16pt corner radius
