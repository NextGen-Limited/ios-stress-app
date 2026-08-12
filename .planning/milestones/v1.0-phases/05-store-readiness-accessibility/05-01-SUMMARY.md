---
phase: 5
plan: 01
subsystem: accessibility, store-readiness
tags: [a11y, wcag, dynamic-type, reduce-motion, fastlane, dead-code-removal]
requires: []
provides: [accessible-touch-targets, wcag-color-contrast, reduce-motion-gates, dynamic-type-adoption, manual-asc-submission-lane]
affects: [StressCategory, DashboardView, MeasurementHistoryView, SettingsView, BreathingExerciseView, MiniWalkView, IAPPremiumView, Fastfile]
tech-stack:
  added: []
  patterns: [accessibleDynamicType, overlayTextColor/readableTextColor, reduceMotion-gated-animations]
key-files:
  created: []
  modified:
    - StressMonitor/StressMonitor/Models/StressCategory.swift
    - StressMonitor/StressMonitor/Views/Premium/Components/IAPNavBar.swift
    - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
    - StressMonitor/StressMonitor/Views/History/Components/CategoryFilterChip.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressHeroCard.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingExerciseView.swift
    - StressMonitor/StressMonitor/Views/Breathing/Components/RippleBreathingView.swift
    - StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkView.swift
    - StressMonitor/StressMonitor/Views/MiniWalk/Components/MiniWalkInstructionCard.swift
    - StressMonitor/StressMonitor/Views/DashboardView.swift
    - StressMonitor/StressMonitor/Views/History/MeasurementHistoryView.swift
    - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
    - StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift
    - fastlane/Fastfile
  deleted:
    - StressMonitor/StressMonitor/Views/Trends/Components/WeeklyHeatmapView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/DailyTimelineView.swift
    - StressMonitor/StressMonitor/Views/Trends/Components/LineChartView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressChart7d.swift
    - StressMonitor/StressMonitor/Views/Trends/Components/AccessibleStressTrendChart.swift
decisions:
  - Moderate-stress yellow (#FFD60A) gets two accessible variants: dark amber (#B8860B) for text-on-light, dark navy (#1A1A2E) for text-on-yellow-fill
  - Dynamic Type applied at screen root level via .accessibleDynamicType() rather than per-label migration (602 fixed-size sites are out of scope)
  - Fastlane release lane uploads metadata only; review submission is manual in ASC for this first submission
metrics:
  duration: 11m
  completed: 2026-08-11
status: complete
actuals:
  tokens: 31000
  tasks: 6
  commits: 6
---

# Phase 5 Plan 01: Store Readiness & Accessibility Summary

WCAG touch-target, color-contrast, Reduce Motion, and Dynamic Type gaps closed across six primary screens; five orphaned redesign views deleted; Fastlane release lane changed to manual ASC submission.

## What Was Done

### Task 1: Delete orphaned redesign views (A11Y-05)

Removed five SwiftUI view files with zero external references — each was only used
in its own `#Preview` block:

- `WeeklyHeatmapView.swift`
- `DailyTimelineView.swift`
- `LineChartView.swift` (Trends)
- `StressChart7d.swift`
- `AccessibleStressTrendChart.swift`

**Commit:** `85460aa`

### Task 2: Fix touch target sizes (A11Y-01)

- **IAPNavBar** back/close buttons: 38pt to 44pt frame
- **ChatBottomSheetView** send button: 36pt to 44pt frame

Both now meet the 44x44pt WCAG minimum.

**Commit:** `9fb03be`

### Task 3: Fix color contrast failures (A11Y-02)

Added two accessible color variants to `StressCategory`:

- `readableTextColor`: dark amber (#B8860B) for `.moderate` used as text on light surfaces; unchanged for other categories
- `overlayTextColor`: dark navy (#1A1A2E) for text drawn on `.moderate` yellow fills; white for other categories

Applied in:

- `CategoryFilterChip`: active chip text uses `overlayTextColor` instead of hardcoded white
- `StressHeroCard`: category display name uses `readableTextColor` instead of raw `fillColor`

**Commit:** `252f89a`

### Task 4: Respect Reduce Motion on stress-relief animations (A11Y-03)

Added `@Environment(\.accessibilityReduceMotion)` and gated four `repeatForever`
animations:

- `BreathingExerciseView`: box-breathing loop (animateBox only set when motion allowed)
- `MiniWalkView`: LIVE indicator pulse (nil animation when reduceMotion)
- `MiniWalkInstructionCard`: avatar bob (startBobAnimation skipped when reduceMotion)
- `RippleBreathingView`: ring rotation (startRingRotation skipped when reduceMotion)

**Commit:** `8654b3b`

### Task 5: Adopt Dynamic Type on primary screens (A11Y-04)

Applied `.accessibleDynamicType()` to the root view of six primary screens:

- Dashboard (`DashboardView`)
- History (`MeasurementHistoryView`)
- Settings (`SettingsView`)
- Breathing Exercise (`BreathingExerciseView`)
- Mini Walk (`MiniWalkView`)
- Paywall (`IAPPremiumView`)

This exercises the existing `AccessibleDynamicTypeModifier` that had zero call sites.
The modifier scales text up to `.accessibility3` with a 0.75 minimum scale factor.

**Commit:** `89450f2`

### Task 6: Fix Fastlane release lane (SHIP-02)

Changed `deliver()` call in the `release` lane:

- `submit_for_review`: `true` to `false`
- Lane description and messages updated to reflect manual ASC submission path

This prevents a blind `deliver --submit_for_review` against empty metadata.

**Commit:** `e538f72`

## Deferred Tasks (checkpoint:human-verify)

### SHIP-01: iPhone screenshot capture

Screenshots require a real device or simulator with real HealthKit data and demo
mode disabled. No `fastlane/screenshots/` or `fastlane/metadata/` directories
exist yet. This is a manual process task that cannot be automated.

### SHIP-03: ASC privacy questionnaire

Must be answered in App Store Connect, consistent with the D3 resolution from
Phase 1: privacy manifest completed, chat content declared. HealthKit data stays
on-device (NOT collected); only stress-context coaching context is sent to backend
under JWT auth.

## Deviations from Plan

None — plan executed exactly as written. All six code tasks completed
successfully with DEBUG build verification after each task.

## Verification

All tasks verified with `xcodebuild build -configuration Debug` (BUILD SUCCEEDED)
after each commit. CoreSimulator is broken on this host, so test execution is not
available — compilation verification only.

## Self-Check: PASSED

All created/modified files verified present in working tree. All commit hashes
verified in git log.
