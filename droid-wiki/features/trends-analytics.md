# Trends and analytics

The third tab. Renders historical stress data as charts, heatmaps, distribution bars, and pattern insights. Long-range views (beyond 7 days) and smart insights are premium-gated.

## Views

| View | File | Purpose |
| --- | --- | --- |
| `TrendsView` | `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift` | Tab root, six-section layout |
| `TrendsViewModel` | `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift` | Data loading and aggregation (largest VM after StressViewModel) |
| `AccessibleStressTrendChart` | `StressMonitor/StressMonitor/Views/Trends/Components/AccessibleStressTrendChart.swift` | VoiceOver-friendly trend chart |
| `LineChartView` | `StressMonitor/StressMonitor/Views/Trends/Components/LineChartView.swift` | Pure-SwiftUI line chart |
| `StressBarChartView` | `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift` | Daily stress bars |
| `HRVTrendChart` | `StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift` | HRV trend line |
| `DistributionBar` | `StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift` | Stress category distribution |
| `WeeklyHeatmapView` | `StressMonitor/StressMonitor/Views/Trends/Components/WeeklyHeatmapView.swift` | Week heatmap |
| `MonthlyCalendarHeatmap` | `StressMonitor/StressMonitor/Views/Trends/Components/MonthlyCalendarHeatmap.swift` | Month heatmap |
| `HorizontalWeekCalendarView` | `StressMonitor/StressMonitor/Views/Trends/Components/HorizontalWeekCalendarView.swift` | Week strip |
| `PatternInsightsSection` | `StressMonitor/StressMonitor/Views/Trends/Components/PatternInsightsSection.swift` | Detected patterns |
| `SmartInsightsTeaser` | `StressMonitor/StressMonitor/Views/Trends/Components/SmartInsightsTeaser.swift` | Premium insights teaser |
| `TrendsStressSourcesCard` | `StressMonitor/StressMonitor/Views/Trends/Components/TrendsStressSourcesCard.swift` | Stress source breakdown over time |
| `TimeRangePicker` | `StressMonitor/StressMonitor/Views/Trends/Components/TimeRangePicker.swift` | 7d / 30d / 90d selector |
| `MascotSpeechBubbleView` | `StressMonitor/StressMonitor/Views/Trends/Components/MascotSpeechBubbleView.swift` | Character commentary |

## View model

`TrendsViewModel` (at `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift`, 22KB) loads measurements for the selected time range, computes aggregates (daily averages, category distribution, HRV trend, streaks), and derives pattern insights. The VM is also responsible for generating the data points that feed `LineChartView`, `StressBarChartView`, and the heatmap views.

## Premium gating

The time-range picker offers 7-day, 30-day, and 90-day windows. Selecting 30d or 90d triggers `paywall.present(reason: .trendsLongRange)` when the user is not premium. `SmartInsightsTeaser` is a locked card that promotes the premium smart insights feature.

## Charts

Charts are implemented in pure SwiftUI rather than the SwiftUI Charts framework, using `Path` and `Canvas` for custom shapes. `RippleTrendsKit` (at `StressMonitor/StressMonitor/Views/Trends/Components/RippleTrendsKit.swift`) provides shared rendering helpers. The June 2023 redesign (commit `db0d1d8`) removed an unsupported Chart annotation overflow strategy that was causing crashes.

## Entry points for modification

- **Add a new chart**: create a component under `Views/Trends/Components/`, feed it from `TrendsViewModel`, and add it to `TrendsView`'s section layout.
- **Change premium gating thresholds**: edit the time-range check in `TrendsView.swift`.
- **Add a new pattern insight**: extend the pattern detection logic in `TrendsViewModel`.
