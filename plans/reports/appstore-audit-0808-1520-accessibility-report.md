# Accessibility Audit — StressMonitor (App Store publish readiness)

**Date:** 2026-08-08
**Scope:** accessibility dimension across StressMonitor (iPhone), StressMonitorWatch, StressMonitorWidget
**Branch:** feature/spm-cache-integration
**Auditor:** axiom accessibility-auditor

> Persisted by the orchestrator — the audit run had no Write tool available.

## Verdict

**NON-COMPLIANT** — CRITICAL Dynamic Type gap plus <70% effective scaling coverage app-wide.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH | 4 |
| MEDIUM | 7 |
| LOW | 3 |
| **Total** | **15** |

## CRITICAL

### Dynamic Type mandate is unimplemented app-wide

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Zero `@ScaledMetric`, zero `relativeTo:`, and every purpose-built accessible-type helper has **0 call sites** | Immediate | App-wide (all 4 tabs, watch, widget) | High (systematic `Typography.swift` rework) | Very High — violates the project's own CLAUDE.md contract; WCAG 1.4.4 Level AA |

**Scale of the gap:** 743+ `.font(.system(size:))` occurrences across 155 files vs. only 18
`dynamicTypeSize`/`minimumScaleFactor` occurrences, mostly in dead code.

**Evidence:**
- `StressMonitor/StressMonitor/Views/DesignSystem/Typography.swift:6-99` — every token is
  `Font.system(size:...)`, no scaling.
- `StressMonitor/StressMonitor/Theme/Font+WellnessType.swift:13-36` — same pattern.
- `StressMonitor/StressMonitor/Utilities/DynamicTypeScaling.swift:122-148` —
  `.accessibleDynamicType()` defined, never called.
- `StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift:4-46` —
  `.stressDualCoding()`, `.minimumTouchTarget()`, `.accessibilityStressLevel()`,
  `.accessibilityChart()` all defined, all unused (0 call sites outside docs/repomix dumps).

The accessibility infrastructure this project mandates was built and then never adopted.

## HIGH

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Sub-44pt touch targets in the live purchase flow — `IAPNavBar` back/close at 38×38 (`IAPNavBar.swift:14,39`) | Soon | Every paywall presentation (all upsell entry points) | Low | High |
| Sub-44pt touch targets in the live AI Chat composer — mic 32×32, send 36×36 (`ChatBottomSheetView.swift:328,348`) | Soon | Chat sheet (Action tab + Settings) | Low | High |
| Color contrast: system yellow (#FFD60A) as text/foreground for "Moderate" — white-on-yellow chip fill (`CategoryFilterChip.swift:24,29,45`, used in `HistoryView.swift:133`, `MeasurementHistoryView.swift:87`) and yellow 30pt bold state label (`StressHeroCard.swift:120-123,142-144`, Home tab hero) | Soon | History filters + Home hero state label | Low-Med | High — WCAG 1.4.3 AA |
| Reduce Motion not respected for persistent looping animations — box-pulse `repeatForever` (`BreathingExerciseView.swift:107-112`) and "LIVE" pulsing dot (`MiniWalkView.swift:116`); no `accessibilityReduceMotion` guard in either file | Soon | Breathing intro + active Mini Walk session | Low | Med-High — WCAG 2.3.3 |

Note on the Reduce Motion finding: the affected screens are the *stress-relief* features. A
looping pulse animation that cannot be disabled is a poor fit for users with vestibular
sensitivity on a screen specifically intended to calm them.

## MEDIUM

1. `StressOverTimeChart.swift` (live, Dashboard hero chart) — per-bar `barColumn` (`:97-118`) has
   no individual `accessibilityLabel`; VoiceOver gets only an aggregate tier-percentage summary,
   losing per-day values.
2. Widget Lock Screen circular/inline views rely on emoji + color with no explicit
   `accessibilityLabel` — `StressMonitorWidget/Views/LockScreenWidgetView.swift:32-49`.
3. `MediumWidgetView.swift:72-85` sparkline `Chart` has zero accessibility label/descriptor.
4. Watch complications (`CircularStressView.swift`, `InlineStressView.swift` under
   `StressMonitorWatch Watch App/Complications/Views/`) never call `.accessibilityLabel` —
   VoiceOver reads fragmented pieces instead of a coherent "Stress 62, Moderate".
5. `CalendarHeatmapView.swift` (watch, live in `WatchHistoryView.swift:75`) — cells are color-only
   for sighted users. Per-cell VoiceOver labels exist, but there is no on-cell text/icon for
   color-blind users at a glance.
6. Dead-code accessibility landmines that would regress the dual-coding/VoiceOver contract if ever
   re-wired: `WeeklyHeatmapView.swift` (self-documented "colour *is* the indicator", zero
   accessibility elements), `DailyTimelineView.swift` (color-only dot grid, dots individually
   `accessibilityHidden`), `HorizontalWeekCalendarView.swift` `DayCell` (gesture-only
   `.onTapGesture`, zero accessibility), `LineChartView.swift` / `StressChart7d.swift` /
   `AccessibleStressTrendChart.swift` (all orphaned, none reachable from any live
   `NavigationStack` — verified via usage grep, only self-referencing `#Preview`s).
7. `SettingsSectionHeader.swift:24` — custom `Image(imageName)` ("watch-icon") not marked
   `.accessibilityHidden`. Mitigated by parent `.accessibilityElement(children: .combine)`, but
   still hygiene debt.

## LOW

1. `Typography.lato(_:size:)` (`Typography.swift:62-63`) uses `.custom(name:size:)` without
   `relativeTo:` — currently 0 call sites, dead infra.
2. Many superseded "redesign generation" view files (Trends/Dashboard heatmaps, charts) remain in
   the target with real accessibility debt but no live call site — recommend deletion to stop
   future regressions.
3. `HRVTrendChart.swift` (live, Trends) has only a container summary label, no per-point VoiceOver
   access. Acceptable minimum; could add `accessibilityChartDescriptor` for richer navigation.

## What's Working Well (verified)

- `HapticManager.shared.stressLevelChanged(to:)` correctly wired exactly once, at the right call
  site (`StressViewModel.swift:561`) — the CLAUDE.md haptics contract is respected.
- **Dual coding is largely well-implemented in live screens.** `StressRingView`,
  `StressHeroCard`, `StatusBadgeView`/`StressStatusBadge`, `MoodCheckInView`,
  `StressBarChartView`, `DistributionBar`, `MonthlyCalendarHeatmap`, `HabitLogRow`, `PlanCard`,
  and `QuickActionGrid` all pair color with text/icon/number and carry proper
  `accessibilityLabel`/`accessibilityHint`. The project's dual-coding mandate is being honored
  where it matters most.
- Onboarding uses SF Symbols exclusively (auto-labeled) — no custom-image label gaps.

## Recommendations

1. **Immediate:** Fix the four HIGH items first — they are all low-effort and touch revenue
   (paywall targets) and core UX (chat composer, Home hero contrast, Reduce Motion). Roughly a
   day's work in total.
2. **Systematic:** Rework `Typography.swift` and `Font+WellnessType.swift` onto `relativeTo:` /
   `@ScaledMetric`, then adopt the existing `.accessibleDynamicType()` helper at call sites. This
   is the CRITICAL item and the only one requiring real scheduling.
3. **Hygiene:** Delete the orphaned redesign-generation view files rather than fixing their
   accessibility — they are unreachable and only create future regression risk.

## Unresolved Questions

1. Is the Dynamic Type rework in scope for this release, or is shipping non-compliant with the
   project's own stated contract an accepted trade-off for v1?
2. Should the orphaned chart/heatmap views be deleted now, or are they staged for a planned
   redesign?
