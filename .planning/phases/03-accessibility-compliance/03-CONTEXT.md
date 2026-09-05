# Phase 3: Accessibility Compliance - Context

**Gathered:** 2026-09-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the primary surfaces operable under assistive settings: 44pt touch targets (A11Y-01), WCAG AA contrast in light and dark appearances (A11Y-02), Reduce Motion respected (A11Y-03), Dynamic Type at accessibility sizes (A11Y-04), and removal of orphaned redesign views (A11Y-05). The phase also establishes the standing a11y gates (contrast unit test, adoption sweeps, Reduce Motion helper) so compliance survives future changes.

Scope anchor: ROADMAP v1.2 Phase 3. Widget surfaces are in scope for contrast/Dynamic Type because D4 (Phase 1) kept the widget.

</domain>

<decisions>
## Implementation Decisions

### Primary-Screen Scope (the sweep manifest)
- **D-01:** The primary-screen set = the 4 tab roots — **Home (`homeView`), Action (`ActionView`), Trends (`TrendsView`), Settings (`SettingsView`)** per `MainTabView.swift` — **plus every `Route`-pushed child**, resolved from `StressMonitor/StressMonitor/Navigation/Route.swift`: `dataExport, dataManage, dataDelete, characters, appearance, about, watchFace, measurement(id), boxBreathing, miniWalk`. Measurement history is a Home child, not a tab root. Session views `breathingSession` and `breathingSummary` are exempt (session UI; their accessibility is governed by the Reduce Motion fallback decision D-11). Onboarding and Paywall are exempt this phase.
  — **Reversibility:** reversible — manifest is a doc artifact; adding/removing surfaces is a list edit, not a migration.
- **D-02:** Widget (gallery + lock-screen) and watch surfaces join the contrast/Dynamic Type sweep per D4/ROADMAP; the 44pt touch-target rule does not apply to them (not touch UI).
- **D-03:** The sweep list above is LOCKED as the audit manifest — verification (and the grep sweeps) run against exactly these surfaces, phase-2 trust-gate style (enumeration, not counts). If a surface is added later, the manifest changes with it.
  — **Reversibility:** reversible — manifest is a doc artifact; adding/removing surfaces is a list edit, not a migration.

### Contrast (A11Y-02)
- **D-04:** AA failures are fixed by **retuning the token values in place** (`Theme/DesignTokens.swift`, `Theme/Color+Wellness.swift`): light cream canvas + dark `#121212`/`#1E1E1E` sets shift minimally to hit AA. No per-site color overrides — one source of truth, zero patchwork drift.
- **D-05:** `Utilities/HighContrastModifier.swift` (0 call sites) is **deleted** — with base tokens passing AA it is redundant dead code, the same class A11Y-05 removes.
- **D-06:** The contrast gate is a **token-pair unit test**: compute WCAG ratios from the semantic token definitions (canvas↔primary text, canvas↔secondary, card↔text, accent↔canvas, and dark-mode equivalents) and assert ≥4.5:1 for text pairs, ≥3:1 for large-text/UI pairs. Machine-checked, enumerable, runs in CI permanently.
- **D-07:** Widget contrast is verified as foreground↔**system material** pairs only (accessory/widget backgrounds Apple guarantees); wallpaper-dependent contrast is out of scope by construction and documented as platform-bounded.

### Dynamic Type (A11Y-04)
- **D-08:** Acceptance bar at accessibility sizes is the ROADMAP SC, strict: **zero truncation** — no ellipsis-truncation, no clipping, no overlap at AX sizes; layouts adapt (stack, wrap, `ViewThatFits`, scroll). Long text wraps or scrolls rather than fitting one line.
- **D-09:** Charts (Swift Charts / SwiftUICharts) render **fixed-size** (geometry exempt) but expose an **accessibility series** — per-point labels/values plus a one-line trend summary — so VoiceOver conveys what sight shows. The gamified character UI is likewise **exempt from scaling but labeled** (accessibilityLabel + state value).
- **D-10:** Gate = two layers: (1) machine-checked adoption sweep — every manifest surface's root view applies the **reworked** `.accessibleDynamicType()` (grep over the D-03 manifest, 1:1 mapping, zero unaccounted). REWORK REQUIRED: the helper's current defaults (`DynamicTypeScaling.swift` — `minScale 0.75`, `maxDynamicTypeSize .accessibility3`) contractually contradict D-08: the AX3 cap prevents AX4/AX5 from rendering at all, and the 0.75 shrink fights scaling toward ellipsis. Reworked primary-surface adoption must scale through AX5 with no cap and no shrink (layout adapts instead); (2) human AX5 walkthrough per surface recorded in phase UAT (screenshots, light+dark).

### Reduce Motion (A11Y-03) + Orphans (A11Y-05)
- **D-11:** Breathing exercise is motion-essential and user-initiated → **exempt with a fallback mode**: under Reduce Motion it defaults to haptic pulses + text countdown (switchable in-session). The active session/summary views are covered by this decision, not the contrast/DT sweep.
- **D-12:** All **decorative** animation (transitions, character idle, celebrations/confetti, parallax/scroll effects) blanket-stops under Reduce Motion via **one app-wide helper** (single Environment value / view modifier, e.g. `.wellnessMotion()`): transitions cross-fade, character holds a static pose, celebrations become static badge + haptic.
- **D-13:** The **65 existing scattered Reduce Motion checks** consolidate onto the single helper this phase. Trust-gate shape: grep enumerates the helper's call sites; zero raw `isReduceMotionEnabled`/`\.reduceMotion` stragglers outside the helper's definition.
- **D-14:** A11Y-05 orphan = a **compiled view type unreachable from the navigation graph** (no Route case, no navigationDestination/sheet/fullScreenCover/reference from any reachable view). Method: reachability audit outward from the 4 tab roots against Route.swift; orphans are **deleted from disk** (no `#if` hiding). The uncompiled legacy set (repo-root `StressMonitor/{Models,Services,Views}/`) is not part of this gate — recorded as separate repo hygiene.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope & Navigation
- `StressMonitor/StressMonitor/Navigation/Route.swift` — the D-03 sweep manifest source: every Route case = one auditable surface; `View.stressNavigationDestinations()` resolves them
- `StressMonitor/StressMonitor/Views/MainTabView.swift` — the four tab roots (Home/Action/Trends/Settings) and their NavigationStacks
- `.planning/ROADMAP.md` §Phase 3 — phase goal, success criteria (zero-truncation bar), dependency note binding widget surfaces via D4

### Tokens & Theme
- `StressMonitor/StressMonitor/Theme/DesignTokens.swift` — `Spacing.Layout.minTouchTarget` (44pt token, currently 1 adopter), typography tokens
- `StressMonitor/StressMonitor/Theme/Color+Wellness.swift`, `Theme/Gradients.swift` — semantic color pairs the contrast unit test computes from
- Settings redesign decision (2026-09-02, commit `2b84862`): cream canvas `#FFFDF6`, plain surface cards, dark set `#121212`/`#1E1E1E` — the approved design contrast fixes must preserve

### Existing Accessibility Assets
- `StressMonitor/StressMonitor/Utilities/DynamicTypeScaling.swift` — defines `.accessibleDynamicType()` (5 adopters today; needs rework per D-10 before manifest-wide adoption) and `limitedDynamicType()` (AX3 cap — usable only with an explicit dated exception if the planner finds an unfixable surface)
- `StressMonitor/StressMonitor/Utilities/HighContrastModifier.swift` — to be deleted per D-05
- `StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift` — existing a11y helper inventory
- `StressMonitor/StressMonitor/Views/Breathing/BreathingExerciseView.swift` — the D-11 motion-essential surface; 65 existing reduceMotion references across the target are the D-13 consolidation input

### Gate Pattern Precedent
- `.planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md` — enumeration-not-counts trust-gate pattern the a11y gates mirror

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.accessibleDynamicType()` (DynamicTypeScaling.swift): defined and adopted on 5 views, but must be REWORKED before manifest-wide adoption — its defaults (AX3 cap + 0.75 minimumScaleFactor) contradict the zero-truncation bar (see D-10)
- `DesignTokens.Spacing.Layout.minTouchTarget` (44): exists as the constant hit-target audits should assert against
- 92 view files already carry `accessibilityLabel` — labeling baseline is broad; audit depth (values/traits/series) is the gap, not presence
- `Utilities/PatternOverlay.swift`, `ColorBlindnessSimulator.swift` — audit whether they duplicate HighContrastModifier's fate (dead) during orphan work

### Established Patterns
- Value-typed navigation (Route enum + one `stressNavigationDestinations()`): reachability auditing and manifest derivation are mechanical
- Phase-2 trust gate (enumeration over counts, dated dispositions): the template every a11y gate here follows
- Token-first theming (DesignTokens + Color.stressColor): retuning values propagates everywhere without view edits

### Integration Points
- Widget timeline views (`StressMonitorWidget/Views/`) and watch complications consume app-shared theme where duplicated per target — token retunes must be mirrored watch-side (no shared framework convention)
- CI (`_test.yml`, canonical invocation per 02-05): the new contrast unit test + adoption greps join the default suite; SwiftLint config may gain the a11y-related opt-ins only if the planner deems them enforceable

</code_context>

<specifics>
## Specific Ideas

- Breathing fallback under Reduce Motion: haptic pulses + text countdown, auto-defaulted ON when Reduce Motion is enabled, switchable in-session — the animation remains opt-in for users who want the visual guide.
- Charts' one-line trend summary ("HRV trending up 12%") doubles as the VoiceOver entry point before per-point detail.

</specifics>

<deferred>
## Deferred Ideas

- Onboarding and Paywall accessibility (exempt this phase per D-01) — candidate for a future polish phase, especially if App Review feedback ever flags the paywall.
- Deleting the uncompiled legacy source set (repo-root `StressMonitor/{Models,Services,Views}/`) — repo hygiene, not compiled-binary accessibility; separate cleanup.

</deferred>

---

*Phase: 03-Accessibility Compliance*
*Context gathered: 2026-09-04*
