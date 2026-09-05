# Phase 3 — A11Y UAT Apparatus (per-surface human verification)

**Produced by:** plan 03-06 Task 3 · **Date:** 2026-09-05
**Purpose:** the end-of-phase `/gsd-verify-work 3` walkthrough sheet, checked against the FINAL post-deletion tree (commit `632db50`). Every row is executed by a human with the app running; results are recorded in the Result column when the walkthrough runs.
**Surface set:** the 14 D-03 manifest surfaces (03-CONTEXT D-01), cross-checked against 03-03's per-surface enumeration (its "Per-Surface Enumeration" table is the Inspector-scan input; reproduced per row below).

## How to run (mechanics)

```bash
# Boot + launch ( argent MCP or Xcode; app scheme StressMonitor, demo mode allowed )
# Set AX5:
xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large
# Appearance light/dark:
xcrun simctl ui <device> appearance light   # then: dark
# Reset when done:
xcrun simctl ui <device> content_size large
```

- **Reduce Motion:** NO simctl subcommand exists on Xcode 26.3 — use the Settings toggle (Settings → Accessibility → Motion → Reduce Motion) or the DEBUG launch-arg seam.
- **VoiceOver focus order / hit targets:** Accessibility Inspector (Xcode → Open Developer Tool) — Audit → Hit Targets; the 03-03 enumeration column below states what was already fixed at source level.
- **Widgets:** set AX5 on the iPhone simulator, then FORCE A RE-RENDER — relaunch the host app or re-edit the widget — because widget snapshots cache at the rendered size; a size change alone will not re-render an existing snapshot.

## 1. The 14 manifest surfaces — AX5 / Inspector / Reduce Motion

Per surface: (a) AX5 walkthrough light+dark — zero truncation, zero clipping, zero overlap; stacked/wrapped content keeps default-size reading order; (b) Inspector hit-target scan vs the 03-03 enumeration; (c) RM walkthrough — no looping/scaling/parallax animation plays; VoiceOver focus follows visual reading order.

| # | Surface (file) | AX5 light+dark (zero truncation/overlap, reading order) | Inspector scan vs 03-03 enumeration | RM walkthrough | Result |
|---|----------------|----------------------------------------------------------|-------------------------------------|----------------|--------|
| 1 | DashboardView (`Views/DashboardView.swift`) | ☐ | ☐ PremiumBanner full-card Button + NoDataCard action (44pt floor) | ☐ | _pending_ |
| 2 | ActionView (`Views/Action/ActionView.swift`) | ☐ | ☐ RippleRecommendationCard CTA pill upgraded; reflect/ActionGroup/HabitLog rows 44pt | ☐ | _pending_ |
| 3 | TrendsView (`Views/Trends/TrendsView.swift`) | ☐ | ☐ Range chips Week/Month/3-Months/Year upgraded | ☐ (incl. zero-data NoDataCard branch) | _pending_ |
| 4 | SettingsView (`Views/Settings/SettingsView.swift`) | ☐ | ☐ 3 Toggles + 2 AI-coach Pickers upgraded; navRows combined+labeled | ☐ | _pending_ |
| 5 | DataExportView (`Views/Settings/DataManagement/DataExportView.swift`) | ☐ | ☐ Form rows system ≥44; Cancel toolbar labeled | ☐ | _pending_ |
| 6 | DataManageView (`Views/Settings/DataManagement/DataManageView.swift`) | ☐ | ☐ 4 row Buttons combined + action-named labels | ☐ (zero-rows state: static hub, count renders 0 gracefully) | _pending_ |
| 7 | DataDeleteView (`Views/Settings/DataManagement/DataDeleteView.swift`) | ☐ | ☐ Delete/Cancel labeled + hinted | ☐ | _pending_ |
| 8 | CharacterCollectionView (`Views/Characters/CharacterCollectionView.swift`) | ☐ | ☐ Grid + Lumi cards carry D-09 label/value package; locked cards dim illustration only | ☐ | _pending_ |
| 9 | AppearanceSettingsView (`Views/Settings/AppearanceSettingsView.swift`) | ☐ | ☐ Scheme buttons labeled + isSelected traits | ☐ | _pending_ |
| 10 | AboutView (`Views/Settings/AboutView.swift`) | ☐ | ☐ Link rows labeled | ☐ | _pending_ |
| 11 | WatchFacePreferencesView (`Views/Settings/WatchFacePreferencesView.swift`) | ☐ | ☐ Companion/style rows labeled + isSelected | ☐ | _pending_ |
| 12 | MeasurementDetailView (`Views/History/MeasurementDetailView.swift`) | ☐ | ☐ Share toolbar button labeled "Share measurement"; action bars 66pt | ☐ | _pending_ |
| 13 | BreathingExerciseView (`Views/Breathing/BreathingExerciseView.swift`) | ☐ | ☐ Back toolbar button already labeled; Begin 50pt / Cancel 44pt | ☐ → also run §2 breathing fallback | _pending_ |
| 14 | MiniWalkView (`Views/MiniWalk/MiniWalkView.swift`) | ☐ | ☐ Pause/Resume/End 48pt; complete-screen buttons 50-56pt | ☐ | _pending_ |

Risk-class components (not separate surfaces, walk them where they appear): MoodCheckInView chips (64pt, triple-coded, dated-exception shrink marker at :66) and QuickActionGrid tiles (minHeight 108) — both on Dashboard/Action hosts.

### Backstop checks carried per surface (from the plan's must_haves)

- AX5: no label truncates, clips, or overlaps another element — screenshot per surface, light + dark.
- AX5 stacked/wrapped layouts: content order matches default-size reading order.
- Inspector: adjacent interactive controls retain separate, non-overlapping hit regions — no shared tap points.
- VoiceOver: focus order follows visual reading order.
- RM: no looping, scaling, or parallax animation plays.
- TrendsView async-load failure UI follows the operation-title + next-step shape ("Couldn't load…" / "Try Again") — force via airplane mode if needed.
- Chart extremes (Trends/Dashboard): single-point series → steady summary (no percent token); many-point series → up/down variant (machine-pinned by ChartAccessibilityTests from 03-04; visual confirm here).

## 2. Breathing fallback walkthrough (D-11)

Reduce Motion ON, then start a breathing session:

| Step | Expected | Result |
|------|----------|--------|
| Session starts with RM ON | Animated guide starts OFF by default; haptic pulses + text countdown carry the phase rhythm (`BreathingViewModel` D-11 default) | _pending_ |
| In-session switch | Animated guide can be switched back on explicitly (motion-essential, user-initiated — D-11 allows) | _pending_ |
| Rings under RM | Breathing rings hold static mid-scale positions (no looping scale) | _pending_ |

## 3. Widget surfaces — AX5, light + dark (forced re-render each size)

Set AX5 on the iPhone simulator, then **force a widget re-render** (relaunch host app or re-edit the widget) before screenshotting — snapshots cache at the rendered size. Verify anchored text scales without overflow and every dated exception from 03-02 Task 4's enumeration still renders legibly (its 58-site register is the checklist).

| Surface | Anchored sites to verify scale | Dated exceptions to verify legible | Light | Dark | Result |
|---------|-------------------------------|-------------------------------------|-------|------|--------|
| Gallery Small (SmallWidgetView) | 6 `@ScaledMetric` sites | — | ☐ | ☐ | _pending_ |
| Gallery Medium (MediumWidgetView) | 9 sites | — | ☐ | ☐ | _pending_ |
| Gallery Large (LargeWidgetView) | 10 sites | — | ☐ | ☐ | _pending_ |
| Lock Screen widget (LockScreenWidgetView) | — | 5 system-fixed accessory-slot sites (:16,18,23,42,46) | ☐ | ☐ | _pending_ |
| Live Activity (StressMonitorWidgetLiveActivity) | — | 44pt hero emoji (a11y-labeled, :26); DI/compact/minimal system slots (:47,52,61,67,72); banner text (:31,33) | ☐ | ☐ | _pending_ |

## 4. Watch surfaces — AX5, light + dark

Set AX5 on the watch simulator via `xcrun simctl ui <watch-device> content_size accessibility-extra-extra-extra-large` where supported; else watch Settings → Accessibility → Larger Text. Same checks: anchored text scales, no truncation/overflow, dated exceptions legible.

| Surface | Anchored sites | Dated exceptions | Light | Dark | Result |
|---------|----------------|------------------|-------|------|--------|
| Watch home (WatchHomeView) | — | 3 fixed hero-composition sites (:65,71,76; readout a11y-labeled) | ☐ | ☐ | _pending_ |
| Watch menu (WatchMenuView) | 5 sites | icon in fixed circular well (:156) | ☐ | ☐ | _pending_ |
| Watch cycle (WatchCycleView) | 15 sites | icon in fixed well (:49) | ☐ | ☐ | _pending_ |
| Watch history (WatchHistoryView) | 9 sites | 3-across stat micro-labels (:119) | ☐ | ☐ | _pending_ |
| Watch workout (WatchWorkoutView) | 10 sites | chart-geometry label (:148) | ☐ | ☐ | _pending_ |
| One complication family (e.g. Rectangular via watch face) | — | accessory-template system-fixed slots (RectangularStressView :58,68,72,81,86,90,98,102) | ☐ | ☐ | _pending_ |

(Breathing/BioAge/logging watch surfaces: WatchBreatheView countdown-in-ring :94,100,104; WatchBioAgeCardView 7 sites + wrap-adopted trend column; WatchLoggingView 6 sites + kept shrink :93.)

## 5. Verdict

Zero unaccounted: 14 app surfaces × (AX5 light+dark + Inspector + RM) + breathing fallback (3 steps) + 5 widget surfaces + 6 watch rows — every row above carries an explicit expectation and a Result column; none is silently passed. This apparatus is the input to `/gsd-verify-work 3`.

---
*Apparatus generated 2026-09-05 by plan 03-06 Task 3 against commit `632db50` (post-deletion tree).*
