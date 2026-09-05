---
phase: 03-accessibility-compliance
reviewed: 2026-09-05T05:13:08Z
depth: standard
files_reviewed: 75
files_reviewed_list:
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - StressMonitor/StressMonitor/Components/Character/CharacterAnimationModifier.swift
  - StressMonitor/StressMonitor/Models/StressCategory.swift
  - StressMonitor/StressMonitor/Theme/Color+Extensions.swift
  - StressMonitor/StressMonitor/Theme/Color+Wellness.swift
  - StressMonitor/StressMonitor/Theme/Font+WellnessType.swift
  - StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift
  - StressMonitor/StressMonitor/Utilities/Animation+Wellness.swift
  - StressMonitor/StressMonitor/Utilities/AnimationPresets.swift
  - StressMonitor/StressMonitor/Utilities/DynamicTypeScaling.swift
  - StressMonitor/StressMonitor/Views/Action/ActionView.swift
  - StressMonitor/StressMonitor/Views/Action/Components/RippleRecommendationCard.swift
  - StressMonitor/StressMonitor/Views/Breathing/BreathingExerciseView.swift
  - StressMonitor/StressMonitor/Views/Breathing/BreathingSessionView.swift
  - StressMonitor/StressMonitor/Views/Breathing/BreathingSummaryView.swift
  - StressMonitor/StressMonitor/Views/Breathing/BreathingViewModel.swift
  - StressMonitor/StressMonitor/Views/Breathing/Components/BreathingCircle.swift
  - StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift
  - StressMonitor/StressMonitor/Views/Characters/Components/CharacterGridCard.swift
  - StressMonitor/StressMonitor/Views/Characters/Components/EvolutionStageRow.swift
  - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
  - StressMonitor/StressMonitor/Views/Dashboard/Components/MoodCheckInView.swift
  - StressMonitor/StressMonitor/Views/Dashboard/Components/NoDataCard.swift
  - StressMonitor/StressMonitor/Views/Dashboard/Components/PremiumBanner.swift
  - StressMonitor/StressMonitor/Views/Dashboard/Components/SkeletonBlock.swift
  - StressMonitor/StressMonitor/Views/Dashboard/Components/StressHeroCard.swift
  - StressMonitor/StressMonitor/Views/DashboardView.swift
  - StressMonitor/StressMonitor/Views/DesignSystem/Components/Buttons.swift
  - StressMonitor/StressMonitor/Views/History/MeasurementDetailView.swift
  - StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkView.swift
  - StressMonitor/StressMonitor/Views/Settings/AboutView.swift
  - StressMonitor/StressMonitor/Views/Settings/AppearanceSettingsView.swift
  - StressMonitor/StressMonitor/Views/Settings/Components/CompanionBanner.swift
  - StressMonitor/StressMonitor/Views/Settings/Components/PlusPill.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/Components/ExportProgressView.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift
  - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
  - StressMonitor/StressMonitor/Views/Settings/WatchFacePreferencesView.swift
  - StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift
  - StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift
  - StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift
  - StressMonitor/StressMonitor/Views/Trends/TrendsView.swift
  - StressMonitor/StressMonitorTests/ChartAccessibilityTests.swift
  - StressMonitor/StressMonitorTests/ContrastComplianceTests.swift
  - StressMonitor/StressMonitorTests/FontWellnessTypeParityTests.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/ComplicationBundle.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Providers/CircularComplicationProvider.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Providers/InlineComplicationProvider.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Providers/RectangularComplicationProvider.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Views/CircularStressView.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Views/InlineStressView.swift
  - StressMonitor/StressMonitorWatch Watch App/Complications/Views/RectangularStressView.swift
  - StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift
  - StressMonitor/StressMonitorWatch Watch App/Theme/Color+Extensions.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/CalendarHeatmapView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/CompactStressView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/HabitRingView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/MoodPickerRow.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/RangePickerRow.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/Components/StressBarChart.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchBioAgeCardView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchBreatheView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchCycleView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchHistoryView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchHomeView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchLoggingView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchMenuView.swift
  - StressMonitor/StressMonitorWatch Watch App/Views/WatchWorkoutView.swift
  - StressMonitor/StressMonitorWidget/StressMonitorWidgetLiveActivity.swift
  - StressMonitor/StressMonitorWidget/Views/LargeWidgetView.swift
  - StressMonitor/StressMonitorWidget/Views/LockScreenWidgetView.swift
  - StressMonitor/StressMonitorWidget/Views/MediumWidgetView.swift
  - StressMonitor/StressMonitorWidget/Views/SmallWidgetView.swift
findings:
  critical: 1
  warning: 7
  info: 6
  total: 14
status: findings
---

# Phase 3: Code Review Report

**Reviewed:** 2026-09-05T05:13:08Z
**Depth:** standard
**Files Reviewed:** 75
**Status:** findings

## Summary

Reviewed all 75 scoped files (iOS app, watch app, widget target, 3 test suites, pbxproj) at standard depth, cross-referencing the phase diff (`a8fe2ef^..HEAD`) to separate phase-introduced defects from pre-existing ones. Contrast ratios below were independently recomputed from the WCAG relative-luminance formula used by `ContrastComplianceTests`.

**What is sound:** the DEBUG-only `-a11y-reduce-motion` seam is correctly compiled out of Release (`#if DEBUG` on both the enum and the check — T-03-06 verified); the iOS Reduce Motion consolidation is genuinely complete (Animation+Wellness.swift is the sole `accessibilityReduceMotion` reader in the iOS + widget targets); the 84-file orphan deletion left zero dead references (all 84 deleted type names grepped clean); the pbxproj change is additions-only with unique IDs wired into the StressMonitorTests target (folder-synced groups explain the absence of view registrations); the contrast test matrix math is correct (0.03928 threshold, lighter-first ordering per G18/G145) and the plan-authorized `#6B6E7B` secondary text passes 4.5:1 at 5.0:1; `trendSummary` percent math matches its pinned tests and callers pass oldest-first data.

**Key concerns:** one phase-introduced WCAG regression in `DistributionBar` (moderate retune changed the fill but not the in-segment text color rule), a moderate-tier naming contradiction ("Elevated" vs "Moderate") that makes VoiceOver announcements disagree across and within surfaces, and a set of contrast failures the new test matrix does not cover (IAP CTA fill, chart accents, watch tier ink).

## Critical Issues

### CR-01: Moderate retune made DistributionBar's in-segment label fail contrast in light mode (~2.7:1)

**File:** `StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift:87-90, 104-114`
**Issue:** The phase changed `StressCategory.moderate.color` light variant from `#FFD60A` (bright yellow) to `#8A5A00` (dark amber). `DistributionBar.barSegment` still hardcodes `darkText: true` for the moderate segment (`Color.black.opacity(0.65)`), which was correct only against the old yellow. In light mode the visible "NN%" label now renders black-on-`#8A5A00` at ~2.67:1 — failing 4.5:1 (11pt semibold is not large text) and even 3:1. Dark mode is unaffected (`#FFD60A` + black). White text on `#8A5A00` measures 5.9:1 and passes. This is a regression introduced by this phase's own token retune; the segment-label pair is not covered by `ContrastComplianceTests`.
**Fix:** Make the label color tier/appearance-aware instead of hardcoded — e.g. use white for the light variant:
```swift
if width > 32 {
    Text(label)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(Color.white)
}
```
(or resolve `darkText` from `@Environment(\.colorScheme)`: dark scheme + moderate → black, otherwise white.) Add the segment-label pair to `ContrastComplianceTests`.

## Warnings

### WR-01: Moderate tier is announced as two different names ("Elevated" vs "Moderate") — VoiceOver label contradicts hint on the same surface

**File:** `StressMonitor/StressMonitor/Models/StressCategory.swift:57-60, 84-86`; `StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift:128`
**Issue:** This phase relocated `displayName` into `StressCategory` with `.moderate` → "Elevated", while `accessibilityDescription` in the same type derives from `rawValue.capitalized` → "Moderate". A VoiceOver user on the dashboard hears the label "Elevated stress level" (`stressDualCoding`) and, where `accessibilityStressLevel` is applied (`AccessibilityModifiers.swift:127`), the hint "Moderate stress level, represented by triangle.fill…". The Trends screens hardcode "Moderate" (DistributionBar legend, StressBarChartView rawValue labels), and the watch `displayName` is "Moderate". The same score therefore changes name between screens and even between the label and hint of one element — an accessibility label that contradicts the visible text elsewhere.
**Fix:** Pick one canonical name. Either rename `.moderate` display to "Moderate" everywhere (change `displayName` and keep rawValue-derived copy), or update `accessibilityDescription` to use `displayName`, the DistributionBar legend, StressBarChartView labels, and the watch `displayName` to "Elevated". Minimum fix: `accessibilityDescription` should use `displayName` so label and hint agree.

### WR-02: iOS and watch tier boundaries disagree — a score of 90-100 is "Severe" on iPhone but "High" on Watch

**File:** `StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift:126-133`; `StressMonitor/StressMonitor/Models/StressResult.swift:33-41`
**Issue:** iOS `StressResult.category(for:)` resolves `.high` at `75..<90` and `.severe` at `90+`; the watch resolves `.high` at `76...100` and `.severe` only above 100 (its `category(for:)` pre-dates this phase, but the phase aligned only the colors and left the header claiming "Aligned exactly with the iOS app's StressCategory"). Boundary values also differ (25/50/75 vs 26/51/76). The same synced measurement therefore shows a different tier name, color, and glyph on watch vs phone in the 25.0-25.99, 50.x, 75.x, and 90-100 bands — 95 reads Severe (red) on the phone and High (orange) on the watch.
**Fix:** Mirror the iOS boundaries in the watch resolver:
```swift
public static func category(for level: Double) -> StressCategory {
    switch level {
    case ..<25:  return .relaxed
    case ..<50:  return .mild
    case ..<75:  return .moderate
    case ..<90:  return .high
    default:     return .severe
    }
}
```
and update the doc table/scoreRange accordingly.

### WR-03: Watch `inkColor` (#B59400) is obsolete and failing (2.6:1) after the moderate retune

**File:** `StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift:39-46`; used at `WatchHomeView.swift:67`, `WatchHistoryView.swift:117,182`, `CompactStressView.swift:33`, `WatchMenuView.swift:60`
**Issue:** `inkColor` special-cases `.moderate` to `#B59400` ("yellow needs a darker ink") — measured 2.61:1 on the watch canvas `#F2F2F7`, failing even the 3:1 large-text bar for the 42pt home score. This phase's retune made the tier's own light color `#8A5A00`, which passes at 5.3:1 — the special case now produces strictly worse contrast than the default. (The value pre-dates the phase, but the phase retuned exactly this tier's color and swept these files, making the fix trivial.)
**Fix:** Delete the moderate special case so ink falls back to `color` (`#8A5A00`), or retune `stressModerateInk` to the `#8A5A00` family.

### WR-04: `iapCTATeal` (#4FC3F7) still carries white CTA text at 2.0:1, violating the new invariant stated in the same file

**File:** `StressMonitor/StressMonitor/Theme/Color+Extensions.swift:159-160` (token), consumed at `Views/Premium/Components/IAPCTAButton.swift:34`
**Issue:** This phase's doc comment on `settingsRippleBlue` states "The legacy fixed #4FC3F7 must never carry white text as a fill in either appearance (2.00:1)" (verified: 2.003:1), and `whiteOnRippleFill` now guards the ripple token. But `iapCTATeal` remains `#4FC3F7` and is the leading gradient stop of the paywall's primary "Unlock Premium" button with `.foregroundStyle(.white)` — the app's main conversion button renders at 2.0:1. The token was not retuned and the pair is not in the test matrix. (Value pre-dates the phase; flagged because the phase established the invariant and its contrast gate in this file.)
**Fix:** Retune `iapCTATeal` to `#0891B2` (matching the ripple token; white passes 3.67:1) or another fill-safe value, and add `whiteOnIAPCTAFill` to `ContrastComplianceTests`.

### WR-05: HRVTrendChart accent (#34D399) measures 1.92:1 on the white light-mode card

**File:** `StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift:16, 89-99, 127-129, 187`
**Issue:** The chart card background is `Color.Wellness.adaptiveCardBackground` (white in light mode), and `hrvColor` is the fixed `#34D399`. In light mode the 2.4pt trend line (UI component, needs 3:1), the 22pt semibold average numeral, and the 10pt "today · NNms" annotation all render at 1.92:1. Dark mode passes (8.7:1). The phase added the D-09 accessibility series to this chart but the accent pair was not added to the contrast matrix, so the failure is unguarded. (Accent pre-dates the phase; the file and its contrast posture are in scope.)
**Fix:** Make the accent adaptive (`light: #0F9D6E`-family dark green, `dark: #34D399`) or move it to `Color.Wellness.healthGreen` with a light variant that passes 3:1, and pin the pair in `ContrastComplianceTests`.

### WR-06: DistributionBar assigns the rounding residual to "high" even when highDays == 0

**File:** `StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift:21-31`
**Issue:** The comment says "Last non-zero segment absorbs the rounding residual", but the implementation computes `hPct = max(0, 100 - rPct - mPct - moPct)` unconditionally. With e.g. 1/1/1/0 days, the rounded percentages sum to 99 and `high` receives 1% — an orange sliver renders while the legend directly below shows "High, 0 days" (dimmed), and the VoiceOver label announces "High 1 percent". Contradictory visible/spoken data.
**Fix:** Assign the residual to the last non-zero tier:
```swift
let raw = [rPct, mPct, moPct]
var pcts = raw
if let lastNonZero = pcts.lastIndex(where: { $0 > 0 }) {
    pcts[lastNonZero] += 100 - pcts.reduce(0, +)
} else {
    return (0, 0, 0, 0)
}
```
(then map to the four-tuple with `high` receiving only its true rounded share).

### WR-07: Watch micro-label ramp (`muted` #777986) measures 3.86:1 on the watch canvas — systemic AA failure under the dated-exception sweep

**File:** `StressMonitor/StressMonitorWatch Watch App/Theme/WatchDesignTokens.swift:36` (token); e.g. `WatchHistoryView.swift:286`, `WatchLoggingView.swift:416`, `WatchCycleView.swift:174`, `WatchBreatheView.swift:146`
**Issue:** `muted` measures 3.86:1 against `canvas` `#F2F2F7` — below the 4.5:1 required for the 7-9pt micro-labels that use it throughout the watch screens this phase swept with dated Dynamic Type exceptions. The iOS-side equivalents were retuned (adaptive secondary text now passes at 5.0:1), but the watch canvas was left out of the contrast gate — `ContrastComplianceTests` covers only iOS tokens, so nothing pins or catches this.
**Fix:** Retune `WatchDesignTokens.muted` to the `#6B6E7B` family (5.0:1, the same authorized override used on iOS), and add a watch-token contrast test if the watch target can host one (otherwise pin the pair from the iOS test target via shared constants).

## Info

### IN-01: High-contrast stress variants are only tested on the light canvas and are non-adaptive

**File:** `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift:217-227`; `StressMonitor/StressMonitor/Theme/Color+Wellness.swift:137-153`
**Issue:** `highContrastStressVariantsOnLightCanvas` resolves only `.light`; the variant hexes are fixed (non-adaptive) and are applied regardless of appearance by `AccessibilityContrastModifier`, so the dark + increased-contrast path is unverified (spot-check shows it passes ~3.2:1, but nothing pins it).
**Fix:** Add a parameterized dark-appearance variant of the test.

### IN-02: Dead motion API surface added this phase

**File:** `StressMonitor/StressMonitor/Utilities/Animation+Wellness.swift:227-242, 283-291`
**Issue:** `AnyTransition.accessibleOpacity/accessibleScale/accessibleSlide`, `staggeredAppear(index:total:delay:)`, `shimmerLoading()`, and `pressEffect()` have zero call sites in the app (`ScaleButtonStyle` typealias is live; `animateIfMotionAllowed`, `startMotionIfAllowed`, `onMotionDecision`, `motionAwareTransition`, `accessibleAnimation` all have callers). `accessibleOpacity(motionReduced:)` also ignores its parameter entirely. `StaggeredAppearModifier.totalItems` is stored but unused.
**Fix:** Remove the uncalled helpers (or note them as intentional forward API); if `accessibleOpacity` stays, drop the unused parameter.

### IN-03: Unused reduce-motion environment declarations left behind after consolidation

**File:** `StressMonitor/StressMonitorWatch Watch App/Views/WatchLoggingView.swift:19`; `StressMonitor/StressMonitorWatch Watch App/Views/WatchHistoryView.swift:13`
**Issue:** Both files declare `@Environment(\.accessibilityReduceMotion) private var reduceMotion` with no remaining readers (1 mention each = declaration only). Harmless but dead, and contradicts the single-owner rule the iOS side now enforces.
**Fix:** Delete the declarations (or route them through a watch-side helper if watch consolidation is planned).

### IN-04: Watch `stressModerateInk` token is unused with a stale doc comment

**File:** `StressMonitor/StressMonitorWatch Watch App/Theme/Color+Extensions.swift:50-51`
**Issue:** Zero usages; the comment still says "WCAG-safe against the pale yellow" although the base token is no longer pale yellow (and the value itself fails, see WR-03).
**Fix:** Delete the token.

### IN-05: Fidget timer no longer re-checks the motion decision per tick

**File:** `StressMonitor/StressMonitor/Components/Character/CharacterAnimationModifier.swift:58-74`
**Issue:** The consolidation replaced the per-tick `guard !self.reduceMotion` inside the fidget `Timer` with start-gating only. If Reduce Motion is enabled while a `.focused`-mood character is on screen, the fidget animation continues until the view disappears (the offset gate is by mood, not by motion). Minor: affects only the decorative fidget and only mid-session setting changes.
**Fix:** Re-add a per-tick check via `onMotionDecision` state, or invalidate the timer when the decision flips.

### IN-06: Watch `scoreRange` contradicts the resolver at exactly 100

**File:** `StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift:99-108`
**Issue:** `.high` is `76...100` and `.severe` is `100...150` (overlapping at 100), while `category(for:)` matches `76...100` first, so 100.0 resolves `.high`. No callers currently use `scoreRange` (dead metadata), but it will mislead the next consumer.
**Fix:** Correct to `101...150` (or remove `scoreRange` with the WR-02 boundary fix).

---

_Reviewed: 2026-09-05T05:13:08Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
