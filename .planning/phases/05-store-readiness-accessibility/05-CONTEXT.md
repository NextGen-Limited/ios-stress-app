# Phase 5 Context: Store Readiness & Accessibility

## Objective

Get StressMonitor from "feature-complete" to "submittable" on two parallel tracks:
(1) close the store-listing mechanics (screenshots, Fastlane release lane, privacy
questionnaire) and (2) close the accessibility gaps the app's own design system
already defines but never calls.

## Pre-Resolved Decisions

- **D3 (privacy contract)**: Resolved in Phase 1. Privacy manifest completed, chat
  content declared. The ASC privacy questionnaire (SHIP-03) must be consistent with
  this resolution. Do not re-open.
- **Auto-resolve**: All grey areas take the simpler/faster path.

## Codebase Findings (Discuss Output)

### A11Y-01: Touch Target Failures

- **IAPNavBar** (`Views/Premium/Components/IAPNavBar.swift`): Back and close buttons
  are 38x38pt. Need 44x44pt minimum.
- **Chat composer send button** (`Views/Chat/ChatBottomSheetView.swift`): Send button
  is 36x36pt. Need 44x44pt minimum.
- Existing helper `.minimumTouchTarget()` in `Utilities/AccessibilityModifiers.swift`
  has **zero call sites**.

### A11Y-02: Color Contrast Failures

- **CategoryFilterChip** (`Views/History/Components/CategoryFilterChip.swift`): When
  active with `.moderate` category, text is white on yellow (#FFD60A). Contrast ratio
  ~1.07:1 — far below WCAG AA (4.5:1).
- **StressHeroCard** (`Views/Dashboard/Components/StressHeroCard.swift`): Category
  display name uses `fillColor` (yellow for `.moderate`) as foreground on card
  background (white). Yellow-on-white fails contrast.
- Root cause: `StressCategory.color` returns raw category colors. The `.moderate`
  yellow (#FFD60A) is a background/accent color, not a readable text color.

### A11Y-03: Reduce Motion Not Respected

Four `repeatForever` animations on stress-relief screens have no Reduce Motion gate:

1. `Views/Breathing/BreathingExerciseView.swift:109` — box-breathing animation loop
2. `Views/MiniWalk/MiniWalkView.swift:116` — LIVE indicator pulse
3. `Views/MiniWalk/Components/MiniWalkInstructionCard.swift:78` — avatar bob animation
4. `Views/Breathing/Components/RippleBreathingView.swift:97` — ring rotation

Existing infrastructure: `Animation+Wellness.swift` provides `.breathing(reduceMotion:)`
and `.animateIfMotionAllowed()`. These are never used by the four files above.

### A11Y-04: Dynamic Type Helpers Have Zero Call Sites

- `accessibleDynamicType()`, `scalableText()`, `adaptiveTextSize()`,
  `limitedDynamicType()` — all defined in `Utilities/DynamicTypeScaling.swift`, all
  have **zero call sites** across the app.
- 602 `.font(.system(size:))` call sites use fixed sizes that don't scale with
  Dynamic Type.
- Scope decision: Adopt on the primary user-facing screens (Dashboard, History,
  Settings, Breathing, Mini Walk, Paywall). Full 602-site migration is out of scope
  for this phase — the requirement is "adopted app-wide through existing helpers",
  meaning the helpers must be exercised on every primary screen, not every label.

### A11Y-05: Orphaned Redesign Views (Confirmed Dead Code)

Five views have **zero external references** — only used in their own `#Preview` blocks:

1. `Views/Trends/Components/WeeklyHeatmapView.swift`
2. `Views/Dashboard/Components/DailyTimelineView.swift`
3. `Views/Trends/Components/LineChartView.swift`
4. `Views/Dashboard/Components/StressChart7d.swift`
5. `Views/Trends/Components/AccessibleStressTrendChart.swift`

Delete all five.

### SHIP-01: Screenshots

- No `fastlane/screenshots/` directory exists.
- No `fastlane/metadata/` directory exists.
- Screenshots require demo mode disabled with real HealthKit data.
- **Process task** — checkpoint:human-verify.

### SHIP-02: Fastlane Release Lane

- Current `release` lane (`fastlane/Fastfile:208-232`): calls `deliver()` with
  `submit_for_review: true` and `skip_metadata: false` against empty metadata.
- This would blind-submit for review with no metadata populated.
- Fix: change to `submit_for_review: false` (upload metadata/screenshots only,
  manual ASC submission).

### SHIP-03: ASC Privacy Questionnaire

- Must be consistent with D3 (Phase 1 resolution): privacy manifest completed,
  chat content declared.
- **Process task** — checkpoint:human-verify.

## Execution Strategy

Code tasks execute first (A11Y-01 through A11Y-05 + SHIP-02 Fastlane fix).
Process tasks (SHIP-01, SHIP-03) defer as checkpoint:human-verify.

## Build Constraint

CoreSimulator/XCTestDevices is broken on this dev host. Tests compile but cannot
run via `xcodebuild test`. Verify via DEBUG build compilation only.
