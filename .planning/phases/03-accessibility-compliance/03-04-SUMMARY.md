---
phase: 03-accessibility-compliance
plan: 04
subsystem: ui
tags: [accessibility, voiceover, charts, d-09, swiftui, swift-testing, tdd]

requires:
  - phase: 03-accessibility-compliance
    provides: ContrastComplianceTests green baseline + retuned tokens (03-01)
  - phase: 03-accessibility-compliance
    provides: reworked .accessibleDynamicType() + fixed-size D-09 exemption classes defined (03-02)
provides:
  - VoiceOverLabels.trendSummary(metric:values:period:) — pure static D-09 trend-summary builder whose copy contract is machine-pinned by ChartAccessibilityTests (5/5)
  - VoiceOverLabels.chartPoint(dateText:valueText:unit:) — per-point "{date}: {value}{unit}" string shape
  - .accessibilityChart(description:summary:points:) — the chart-series container shape (contain + label + summary-as-value + per-point series + updatesFrequently)
  - Accessibility series adopted on all four chart components (StressBarChartView, HRVTrendChart, SparklineChart, MiniLineChartView); chart geometry stays fixed-size per D-09
  - StressRingView hero numeral carries .accessibilityStressLevel (gauge class conveys its score) — first adopter of the previously definition-only helper
affects: [03-05, 03-06, phase-4-verification]

actuals:
  tokens: 4771
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Chart D-09 series = container keeps .contain + descriptive label; accessibilityValue carries [trend summary] + per-point strings joined by ', ' — the summary is the VoiceOver entry, per-point labels the series detail"
    - "Trend classification: relative change between first and last values, percent rounded to whole number; exactly-zero, single-point, and rounds-to-zero changes all classify steady (never 'up 0%')"
    - "Point-label inputs restate exactly what the chart renders (day labels, MMM d timestamps, or point indices) — no data invention in VoiceOver strings (T-03-05)"

key-files:
  created:
    - StressMonitor/StressMonitorTests/ChartAccessibilityTests.swift
  modified:
    - StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift
    - StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift
    - StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/SparklineChart.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/MiniLineChartView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressRingView.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "Percent semantics pinned red-first: relative change (last-first)/first, rounded half-up to a whole number (14.58% -> 15, proving rounding not truncation); a change that ROUNDS to zero also classifies steady, so 'up 0%' is unreachable — this covers both readings of Test 5's zero-percent rule (exact first==last over multiple points, and small nonzero drift)"
  - "Zero-baseline guard (Rule 2): first==0 with last!=first makes the relative percent uncomputable and Int(inf) traps — the builder keeps the direction word and omits the percent token (same omission rule as steady), rather than inventing a percent or crashing"
  - "Empty series: the builder returns the steady form (total function), and each adoption site substitutes its own visible empty-state copy ('No data yet' / 'Need more data') as the container value when the chart has no data — the value never claims a trend the visible chart does not show"
  - "Per-point labels restate the chart's own data vocabulary: StressBarChartView uses its day labels ('Tue 22: 42%'), HRVTrendChart MMM-d dates + ms ('Sep 3: 48 ms' — the exact UI-SPEC example), SparklineChart its timestamps, MiniLineChartView its index ('Point 3: 52') because the index-only series has no dates to restate"
  - "SparklineChart/MiniLineChartView gained a defaulted metricName parameter (both are preview-only today — no live call sites to break); SparklineChart's period is computed from the span its timestamps actually cover, MiniLineChartView's period restates the point count; SparklineChart's old >5-point-threshold label machinery and its trendChange helper were deleted as superseded by the pinned contract"
  - "StressBarChartView's trend series covers only hasData days (averageStress > 0) — zero-average bars render as 'no data' tracks and must not skew the trend percent or appear as '0%' points"

patterns-established:
  - "Chart a11y adoption pattern: .accessibilityChart(description:summary:points:) on the container; summary from VoiceOverLabels.trendSummary, points from VoiceOverLabels.chartPoint"
  - "Test registration pattern reused verbatim: 4 pbxproj points (PBXBuildFile, PBXFileReference, group child, Sources) with sequential IDs — A030/B030 follow A028/B028 and A029/B029"

requirements-completed: [A11Y-04]

coverage:
  - id: D1
    description: "Trend-summary copy contract pinned red-first by ChartAccessibilityTests — steady omits the percent token; single-point, exactly-flat, and zero-percent changes classify steady; up/down carry a whole-number percent"
    requirement: A11Y-04
    verification:
      - kind: unit
        ref: StressMonitorTests/ChartAccessibilityTests.swift#Chart Accessibility (5/5) — RED 5/5 against the stub (commit 0589b57), GREEN 5/5 after implementation (commit 469abc7)
        status: pass
    human_judgment: false
  - id: D2
    description: "All four chart components carry accessibilityValue built from the trend-summary builder plus per-point label strings; StressRingView's hero numeral carries the stress-level accessibility value; no Dynamic Type scaling applied to chart geometry"
    requirement: A11Y-04
    verification:
      - kind: other
        ref: grep VoiceOverLabels.trendSummary -> 4 adoption sites (one per chart component); grep VoiceOverLabels.chartPoint -> 4; grep accessibilityStressLevel StressRingView.swift:57; grep dynamicTypeSize|ScaledMetric|accessibleDynamicType|minimumScaleFactor over the 5 chart files -> 0; xcodebuild build -> ** BUILD SUCCEEDED **; ContrastComplianceTests re-run -> ** TEST SUCCEEDED **
        status: pass
    human_judgment: true
    rationale: "What VoiceOver actually speaks for each chart in the running app is a runtime property verified per surface in the phase UAT walkthrough (03-06 Accessibility Inspector scan); source-level adoption and the pinned copy contract are machine-proven"

duration: 10min
completed: 2026-09-05
status: complete
---

# Phase 03 Plan 04: Chart Accessibility Series Summary

**D-09 charts speak: pinned trend-summary copy contract + accessibility series (summary + per-point labels) on all four chart components, and the stress-ring gauge numeral carries its score**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-05T02:22:47Z
- **Completed:** 2026-09-05T02:33:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- ChartAccessibilityTests pins the UI-SPEC Copywriting Contract exactly — "{Metric} {up|down|steady} {percent}% in the last {period}", steady omits the percent token — RED-first (all five cases failed against the empty stub before any implementation existed)
- `VoiceOverLabels.trendSummary` implemented for real; `.accessibilityChart` extended with the series shape; all four chart components (StressBarChartView, HRVTrendChart, SparklineChart, MiniLineChartView) now speak summary + per-point series while keeping fixed-size geometry
- StressRingView's hero numeral carries `.accessibilityStressLevel` — the previously definition-only helper has its first adopter
- App scheme `** BUILD SUCCEEDED **`; ContrastComplianceTests full re-run green (no regression from the modifier-file edits)

## TDD Gate Evidence

**RED (commit 0589b57)** — all five cases failed against the stub (`summary → ""`):

```
✘ Test "a single-point series yields a steady summary with no percent token" ... Expectation failed: (summary → "") == "HRV steady in the last 7 days"
✘ Test "an upward multi-point series yields the up variant with the percent rounded to a whole number" ... (summary → "") == "HRV up 15% in the last 7 days"
✘ Test "a downward multi-point series yields the down variant" ... (summary → "") == "HRV down 19% in the last 7 days"
✘ Test "an exactly-flat multi-point series yields the steady variant" ... (summary → "") == "Stress steady in the last 7 days"
✘ Test "a zero-percent change over multiple points yields steady, not up 0%" ... (summary → "") == "Stress steady in the last 7 days"
✘ Test run with 5 tests in 1 suite failed after 0.008 seconds with 5 issues.
```

**GREEN (commit 469abc7)** — 5/5 passed (`** TEST SUCCEEDED **`):

```
✔ Test "a single-point series yields a steady summary with no percent token" passed
✔ Test "an upward multi-point series yields the up variant with the percent rounded to a whole number" passed
✔ Test "a downward multi-point series yields the down variant" passed
✔ Test "an exactly-flat multi-point series yields the steady variant" passed
✔ Test "a zero-percent change over multiple points yields steady, not up 0%" passed
✔ Suite "Chart Accessibility" passed
```

**Adoption-site grep (Task 2 acceptance):**

```
StressBarChartView.swift:49  return VoiceOverLabels.trendSummary(metric: "Daily stress", values: values, period: "7 days")
HRVTrendChart.swift:54       return VoiceOverLabels.trendSummary(        [metric "HRV", values, period "7 days"]
SparklineChart.swift:88      return VoiceOverLabels.trendSummary(        [metric metricName, period from timestamp span]
MiniLineChartView.swift:55   return VoiceOverLabels.trendSummary(        [metric metricName, period "\(count) points"]
StressRingView.swift:57      .accessibilityStressLevel(stressLevel, category: category)
Dynamic Type scaling on chart geometry: 0 occurrences across all five chart files
```

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — ChartAccessibilityTests pins the trend-summary copy contract** — `0589b57` (test)
2. **Task 2: GREEN — implement the builder + apply the accessibility series to charts and the gauge value** — `469abc7` (feat)

**Plan metadata:** see final docs commit below.

## Files Created/Modified

- `StressMonitor/StressMonitorTests/ChartAccessibilityTests.swift` — 5-case suite pinning the D-09 copy contract (registered, pbxproj IDs A030/B030, 4 points)
- `StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift` — `trendSummary` + `chartPoint` builders in `VoiceOverLabels`; extended `.accessibilityChart(description:summary:points:)`
- `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift` — container series; trend covers hasData days only
- `StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift` — container series; "Sep 3: 48 ms" per-point shape (the UI-SPEC example)
- `StressMonitor/StressMonitor/Views/Dashboard/Components/SparklineChart.swift` — `metricName` param; series replaces the old threshold-label machinery (deleted with its `trendChange` helper)
- `StressMonitor/StressMonitor/Views/Dashboard/Components/MiniLineChartView.swift` — `metricName` param; index-based point labels
- `StressMonitor/StressMonitor/Views/Dashboard/Components/StressRingView.swift` — `.accessibilityStressLevel` replaces the manual accessibilityValue
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — test registration (A030/B030, 4 points)

## Decisions Made

See `key-decisions` in the frontmatter — the six decisions above cover percent semantics, the zero-baseline guard, empty-series handling, per-point vocabulary per chart, the `metricName` parameter additions, and the hasData filter.

Additional execution note: **no interactive legend controls exist in the five chart-component files** (verified by reading each file — no `Button`/`onTapGesture`/tap targets anywhere in them), so the chart-file slice of the A11Y-01 touch-target requirement had nothing to adopt; surface files were 03-03's ownership.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Zero-baseline input validation in the trend-summary builder**
- **Found during:** Task 2 (GREEN implementation)
- **Issue:** A series whose first value is 0 with a different last value makes the relative percent `infinity`; `Int(Double.infinity.rounded())` traps, crashing any chart fed such a series. The plan specified only the first/last relative-change math, not this input class.
- **Fix:** `guard first != 0` — the builder keeps the direction word and omits the percent token (the same omission rule steady uses); no percent is invented for an uncomputable baseline.
- **Files modified:** StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift
- **Verification:** ChartAccessibilityTests 5/5 green; build succeeded; the guard branch is exercised by inspection (stress series are pre-filtered to hasData values, so live charts cannot reach it — the guard makes the pure builder total)
- **Committed in:** 469abc7 (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Validation-only guard at the pure-function boundary; no contract change, no scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- A11Y-04's chart half is machine-pinned (03-02 owned the Dynamic Type half; both plans are now summarized, so the shared requirement ID can be marked complete)
- 03-05 (Reduce Motion consolidation) and 03-06 (orphan deletion + Accessibility Inspector scan) can proceed; note for 03-06's orphan audit: `SparklineChart` and `MiniLineChartView` currently have no live call sites (preview-only) — this plan adopted their accessibility series per the manifest, and any deletion decision remains 03-06's per D-14
- The phase UAT walkthrough should VoiceOver-check one chart per surface to confirm runtime conveyance (the D2 coverage rationale)

## Self-Check: PASSED

- StressMonitor/StressMonitorTests/ChartAccessibilityTests.swift exists (FOUND)
- Commits 0589b57 (test) and 469abc7 (feat) exist in git log (FOUND)
- pbxproj grep count for ChartAccessibilityTests: 4 (>= 4 required)
- ChartAccessibilityTests 5/5 green; app build `** BUILD SUCCEEDED **`; ContrastComplianceTests re-run green

---
*Phase: 03-accessibility-compliance*
*Completed: 2026-09-05*
