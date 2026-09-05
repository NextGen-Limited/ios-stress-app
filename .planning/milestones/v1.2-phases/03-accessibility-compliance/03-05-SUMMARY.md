---
phase: 03-accessibility-compliance
plan: 05
subsystem: ui
tags: [accessibility, reduce-motion, d-11, d-12, d-13, breathing, swiftui]

requires:
  - phase: 03-accessibility-compliance
    provides: ContrastComplianceTests green baseline + retuned tokens (03-01)
  - phase: 03-accessibility-compliance
    provides: reworked .accessibleDynamicType() + manifest adoption (03-02)
  - phase: 03-accessibility-compliance
    provides: chart accessibility series + gauge value (03-04)
provides:
  - WellnessMotion — pure motion decision (environment value OR'd with the DEBUG seam); the single owner of every reduce-motion read in the app target
  - A11yReduceMotionMode — DEBUG-only "-a11y-reduce-motion" launch-arg seam (MockIAPMode-shaped injectable arguments), the scripted path for RM verification (simctl has no RM toggle on Xcode 26.3)
  - Helper View API — animateIfMotionAllowed(_:value:), onMotionDecision(_:), startMotionIfAllowed(_:), motionAwareTransition(_:), accessibleAnimation(_:value:), pressEffect(), staggeredAppear, shimmerLoading, MotionAwareScaleButtonStyle
  - AnyTransition accessible family reworked to cross-fade (.opacity) under Reduce Motion — the hard-cut identity fallbacks are deleted
  - D-11 breathing fallback — animation-enabled session state + pure resolvedAnimationEnabled(motionReduced:userChoice:), "Breathing animation" in-session switch, "Inhale — 3" countdown line, HapticManager phase pulses
  - Deleted symbols — the explicit-Bool Animation.wellness/breathing/fidget/shake/dizzy factories; AccessibleAnimationModifier's per-body UUID bug folded away
affects: [03-06, phase-4-verification]

actuals:
  tokens: 13573
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One motion helper (Animation+Wellness.swift) owns every \\.accessibilityReduceMotion read; views that need the boolean capture it once via .onMotionDecision { } instead of reading the environment"
    - "Decorative starters run through .startMotionIfAllowed { }; value-driven animations run through .animateIfMotionAllowed(_:value:); transitions run through .motionAwareTransition(_:) which cross-fades under RM"
    - "DEBUG verification seam = #if DEBUG enum with launchArgument + injectable isEnabled(arguments:) OR'd into the pure decision (MockIAPMode precedent; Release path compiles the seam out entirely)"
    - "D-11 carve-out: breathing session views never read the blanket decision in-body — the session's isAnimationEnabled state (initialized from the decision, user-togglable, non-persistent) gates their motion"

key-files:
  created: []
  modified:
    - StressMonitor/StressMonitor/Utilities/Animation+Wellness.swift
    - StressMonitor/StressMonitor/Utilities/AnimationPresets.swift
    - StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift
    - StressMonitor/StressMonitor/Components/Character/CharacterAnimationModifier.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingExerciseView.swift
    - StressMonitor/StressMonitor/Views/Breathing/Components/BreathingCircle.swift
    - StressMonitor/StressMonitor/Views/Breathing/Components/RippleBreathingView.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingSessionView.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingSummaryView.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingViewModel.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/SkeletonBlock.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressRingView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/MetricCardView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/LearningPhaseCard.swift
    - StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkView.swift
    - StressMonitor/StressMonitor/Views/MiniWalk/Components/MiniWalkInstructionCard.swift
    - StressMonitor/StressMonitor/Views/DesignSystem/Components/Buttons.swift
    - StressMonitor/StressMonitor/Views/Settings/DataManagement/Components/ExportProgressView.swift

key-decisions:
  - "Helper home (OQ-2 as resolved by planning): Animation+Wellness.swift reworked in place — no Motion.swift; all env-reading motion modifiers (ReduceMotionAware, MotionDecision, MotionAllowedStart, MotionAwareTransition, reworked AccessibleAnimation, PressEffect, StaggeredAppear, ShimmerLoading + MotionAwareScaleButtonStyle) now live in that one file, so the gate holds by construction"
  - "onMotionDecision(_:) added as the sanctioned escape hatch for views that need the boolean rather than a modifier — StressRingView/MetricCardView branch on captured @State motionReduced, preserving their exact prior RM branches (linear-vs-spring ring fill, .identity numericText) with zero env reads"
  - "AnimationPresets statics (0 adopters) kept as inert values carrying the apply-via-helper routing contract in their doc comment rather than deleted — the plan's acceptance says 'route through the helper', and animateIfMotionAllowed(.preset, value:) is that route; the plan's deleted-symbols list does not include them"
  - "BreathingCircle takes isAnimated (default true) instead of reading the environment — the session view drives it from vm.isAnimationEnabled, making the D-11 carve-out a single-parameter hand-off; Task 2 landed it with a defaulted parameter so the Task-3 session wiring stayed a one-line change"
  - "Phase-transition haptics fire for every session (hapticFeedback-config-gated via HapticManager.breathingCue) — the screen's own footer copy ('Haptic + heartbeat on each transition') already promised them; the fallback mode simply relies on them instead of the animation"
  - "Two truth-mandated files beyond the 13-file list were swept: ScaleButtonStyle aliased to MotionAwareScaleButtonStyle (must-have 'stops press-scale effects'; UI-SPEC names it) and ExportProgressView's two progress animations routed through animateIfMotionAllowed (must-have: progress persists, tweening stops)"
  - "StressRingView restructure: trim now animates via .animateIfMotionAllowed(.spring, value: trimFraction) on appear and on stressLevel change — under RM the ring jumps straight to the value (state still conveyed); the decorative symbolEffect(.bounce) is additionally gated (previously it ran under RM)"

requirements-completed: [A11Y-03]

coverage:
  - id: D1
    description: "Single D-12 helper with cross-fade fallbacks and the DEBUG seam — AnyTransition accessible family returns .opacity under RM (identity fallbacks gone); the -a11y-reduce-motion seam is #if DEBUG-wrapped with injectable arguments; presets route through the helper"
    requirement: A11Y-03
    verification:
      - kind: command
        ref: "grep identity Utilities/Animation+Wellness.swift -> 0 lines; grep -c a11y-reduce-motion -> 2; xcodebuild build -> ** BUILD SUCCEEDED ** (commit b9f03d6)"
        status: pass
    human_judgment: false
  - id: D2
    description: "13-file consolidation to zero raw reduce-motion reads outside the helper (D-13), re-baselined at execution: 18 ref lines / 13 files (17 @Environment(\\.accessibilityReduceMotion) reads + 1 doc-comment mention in BreathingCircle) — the plan's research baseline of 66/13 and UI-SPEC's 65/13 both stale"
    requirement: A11Y-03
    verification:
      - kind: command
        ref: "post-sweep gate: grep -rn 'accessibilityReduceMotion\\|isReduceMotionEnabled' StressMonitor/StressMonitor --include='*.swift' | grep -v Utilities/Animation+Wellness.swift -> ZERO result lines before RM_GATE_DONE (re-verified green after Task 3); xcodebuild build -> ** BUILD SUCCEEDED ** (commit f32b9ea)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-11 breathing fallback — session defaults to haptic pulses + the 'Inhale — 3' text countdown under Reduce Motion, with the 'Breathing animation' switch (auto-OFF under RM, user-togglable ON, nothing persisted); fallback default is a pure view-model function"
    requirement: A11Y-03
    verification:
      - kind: command
        ref: "grep -c 'Breathing animation' BreathingSessionView -> 1; grep -c 'Inhale — |Hold — |Exhale — ' -> 5; grep -c HapticManager -> VM 1 / SessionView 2; grep UserDefaults Views/Breathing/ -> 0; xcodebuild build -> ** BUILD SUCCEEDED ** (commit 935d607)"
        status: pass
      - kind: command
        ref: "regression re-run: TEST_RUNNER_GSD_CI=1 xcodebuild test -only-testing ContrastComplianceTests -only-testing ChartAccessibilityTests -> ** TEST SUCCEEDED ** (exit 0)"
        status: pass
    human_judgment: true
    rationale: "A Reduce Motion user completing a breathing session with haptic + countdown feedback and opting back into the animated guide is runtime behavior — the phase UAT walkthrough (03-06, via the -a11y-reduce-motion seam or the Settings toggle) is where that is observed; source-level wiring, copy, and non-persistence are machine-proven above"
---

# Phase 3 Plan 5: Reduce Motion Consolidation + Breathing Fallback Summary

One D-12 motion helper (reworked Animation+Wellness.swift) owns every reduce-motion read in the app target (gate grep zero), cross-fades transitions and stops decorative loops under Reduce Motion, and breathing sessions fall back to haptic pulses plus the "Inhale — 3" countdown with an in-session animation switch.

**Duration:** 31 min (2026-09-05T03:05:02Z → 2026-09-05T03:36:53Z)
**Tasks:** 3/3 complete · **Files:** 18 modified · **Commits:** b9f03d6, f32b9ea, 935d607

## Accomplishments

- **Task 1 (b9f03d6)** — Animation+Wellness.swift reworked into the single motion helper: WellnessMotion pure decision, #if DEBUG `-a11y-reduce-motion` seam (injectable arguments), AnyTransition family cross-fading under RM, AccessibleAnimationModifier folded (caller-driven Equatable value — the per-body UUID bug is gone), PressEffectModifier stops scaling, staggered/shimmer moved in decision-routed, AnimationPresets statics carry the apply-via-helper contract, AccessibilityModifiers slimmed motion-free. Legacy explicit-Bool factories retained one task for compiler ordering, as the plan allows.
- **Task 2 (f32b9ea)** — Consolidation sweep: re-baselined 18 ref lines / 13 files (17 env reads + 1 doc comment) → gate grep prints zero lines outside the helper. CharacterAnimationModifier migrated off the deleted factories (idle holds a static pose under RM); breathing intro box, MiniWalk bob, and ripple ring start via startMotionIfAllowed; skeleton pulse + LIVE dot via animateIfMotionAllowed; MiniWalk completion overlay cross-fades; StressRingView/MetricCardView capture the decision once; LearningPhaseCard progress stays visible untweened; ScaleButtonStyle + ExportProgressView swept per must-haves.
- **Task 3 (935d607)** — D-11 breathing fallback: resolvedAnimationEnabled(motionReduced:userChoice:) pure default, in-session "Breathing animation" toggle, "Inhale — 3"-style countdown line over static rings, HapticManager.breathingCue on every phase advance (hapticFeedback-gated), buttonPress feedback on session buttons, success haptic at summary, phase-track dot bounce follows the session animation state. No persistence added.
- **Regression re-run** — ContrastComplianceTests + ChartAccessibilityTests: `** TEST SUCCEEDED **` (exit 0) on iPhone 17 simulator.

## Task 2 re-baseline enumeration (pre-sweep, by file and construct)

Grep: `grep -rn "accessibilityReduceMotion\|isReduceMotionEnabled" StressMonitor/StressMonitor --include="*.swift"` — 18 lines / 13 files:

| File | Construct | Refs |
|------|-----------|------|
| Utilities/Animation+Wellness.swift | @Environment read inside ReduceMotionAwareModifier (the helper's own) | 1 |
| Components/Character/CharacterAnimationModifier.swift | @Environment reads ×2 (Character + Accessory modifiers) | 2 |
| Utilities/AccessibilityModifiers.swift | @Environment reads ×2 (AccessibleAnimation + PressEffect) | 2 |
| Utilities/AnimationPresets.swift | @Environment reads ×2 (StaggeredAppear + ShimmerLoading) | 2 |
| Views/Breathing/BreathingExerciseView.swift | @Environment read (intro box gate) | 1 |
| Views/Breathing/Components/BreathingCircle.swift | @Environment read + doc-comment mention (reworded) | 2 |
| Views/Breathing/Components/RippleBreathingView.swift | @Environment read (ring rotation gate) | 1 |
| Views/Dashboard/Components/LearningPhaseCard.swift | @Environment read (progress tweens ×2) | 1 |
| Views/Dashboard/Components/MetricCardView.swift | @Environment read (numericText + spring) | 1 |
| Views/Dashboard/Components/SkeletonBlock.swift | @Environment read (pulse loop) | 1 |
| Views/Dashboard/Components/StressRingView.swift | @Environment read (ring/text/icon) | 1 |
| Views/MiniWalk/MiniWalkView.swift | @Environment read (LIVE dot) | 1 |
| Views/MiniWalk/Components/MiniWalkInstructionCard.swift | @Environment read (bob loop) | 1 |

## Task 2 post-sweep gate output (verbatim)

```
$ grep -rn "accessibilityReduceMotion\|isReduceMotionEnabled" StressMonitor/StressMonitor --include="*.swift" | grep -v "Utilities/Animation+Wellness.swift"; echo RM_GATE_DONE
RM_GATE_DONE
```

Zero result lines before RM_GATE_DONE — re-run after Task 3 (breathing fallback added no environment reads): `RM_GATE_STILL_CLEAN`, zero lines. All builds: `** BUILD SUCCEEDED **`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Two must-have-mandated files swept beyond the 13-file list**
- **Found during:** Task 2
- **Issue:** must_haves truths name two behaviors whose sites are not in the plan's 13-file enumeration — "stops press-scale effects" (ScaleButtonStyle in Views/DesignSystem/Components/Buttons.swift, also named by UI-SPEC A11Y-03) and "Data-export progress keeps conveying state under Reduce Motion — only its decorative loops stop through the helper" (ExportProgressView)
- **Fix:** ScaleButtonStyle became a typealias of MotionAwareScaleButtonStyle (helper-owned, RM-gated press-scale); ExportProgressView's two progress tweens route through animateIfMotionAllowed so the values still convey progress without tweening under RM
- **Files modified:** Buttons.swift, ExportProgressView.swift
- **Verification:** build green; gate grep unchanged (neither file had an env read)
- **Commit:** f32b9ea

**2. [Rule 3 - Blocker] Task-1 build failed on the seam call site**
- **Found during:** Task 1
- **Issue:** `A11yReduceMotionMode.isEnabled` referenced as a property; it is a function — "function produces expected type 'Bool'"
- **Fix:** `isEnabled()` call
- **Files modified:** Utilities/Animation+Wellness.swift
- **Verification:** BUILD SUCCEEDED
- **Commit:** b9f03d6

**3. [Rule 1 - Bug] Scope note: StressRingView ring animation restructure**
- **Found during:** Task 2
- **Issue:** the old ring animated via withAnimation wrappers in onAppear/onChange plus a .animation(value: animateRing) modifier — porting that shape onto the helper would have required reading the decision inside onAppear with modifier-ordering hazards
- **Fix:** trim now targets a computed trimFraction and animates via .animateIfMotionAllowed(.spring, value: trimFraction); under RM the ring jumps straight to the value (state still conveyed — previously a 0.3s linear tween); the previously-ungated symbolEffect(.bounce) is now gated
- **Files modified:** StressRingView.swift
- **Verification:** build green; behavior preserved-or-improved per D-12
- **Commit:** f32b9ea

**Total deviations:** 3 auto-fixed (1 Rule 2, 1 Rule 3, 1 Rule 1 scope-note). **Impact:** none on the gate or regression suites; behavior under normal motion unchanged.

## Authentication Gates

None.

## Known Stubs

None — the fallback mode is a complete implementation (haptics, countdown copy, toggle, static rings), not a placeholder.

## Issues Encountered

- **Harness shell outage (mid-execution):** the Bash tool failed (every command exit 1, no output) for a window between the Task-3 commit and the regression-suite completion; the xcodebuild test run had been dispatched to background before the outage and completed `** TEST SUCCEEDED **` (exit 0). The shell recovered; close-out proceeded. No work was lost.
- **Out-of-scope discovery (logged to deferred-items.md):** four files carry unguarded repeatForever decorative loops (LoadingView, BioAgeCardView, SmartInsightsTeaser, ChatBottomSheetView) — they have no reduce-motion read, so they are invisible to the D-13 gate, and they were not in the plan's set. Several are 03-06 orphan candidates; survivors should adopt the helper then.

## Next Plan Readiness

Ready for 03-06 (orphan deletion + phase trust gates) — the RM gate is clean by construction and must be re-run there against the post-deletion tree, per the plan's flagged assumption.

## TDD Gate Compliance

Not a TDD plan; no tdd="true" tasks. The plan's pure fallback-default function (BreathingSessionViewModel.resolvedAnimationEnabled) is unit-testable in principle per the plan text but the plan required no new suite; phase regression suites re-ran green.

## Self-Check: PASSED

- Commit b9f03d6 exists (feat(03-05): single D-12 motion helper) — `git log` verified
- Commit f32b9ea exists (refactor(03-05): consolidate all reduce-motion reads) — `git log` verified
- Commit 935d607 exists (feat(03-05): D-11 breathing fallback) — `git log` verified
- All 18 key-files.modified exist on disk
- Gate grep zero (verbatim output above); builds SUCCEEDED ×3; regression suites TEST SUCCEEDED
