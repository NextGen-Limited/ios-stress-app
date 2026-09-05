# Phase 3 Discussion Log — Accessibility Compliance

**Date:** 2026-09-04
**Participants:** user (visionary), Claude (builder/orchestrator via /gsd-manager)
**Mode:** default (single-question turns), areas selected via multiSelect

---

## Area 1: Primary-screen scope

**Q1. Which surfaces form the "primary screens" set for A11Y-01/02/04?**
- Options: The 4 tabs (Dashboard/Trends/History/Settings) · Tabs + Onboarding + Paywall · Everything reachable
- **Selected:** The 4 tabs

**Q2. Do widget and watch surfaces join the sweep, per D4?**
- Options: Widget + watch in (contrast/DT only; no hit-target rule) · iOS app only
- **Selected:** Widget + watch in

**Q3. Do pushed sub-screens inside the tabs inherit the sweep?**
- Options: All pushed children (Breathing/Onboarding/Paywall exempt) · Roots only
- **Selected:** All pushed children

**Q4. How is the scope list made auditable for the gate?**
- Options: Lock via Route.swift (manifest locked from Route cases) · Rule only, derive later
- **Selected:** Lock via Route.swift

**Follow-up correction (Route.swift evidence):** Breathing routes are pushed tab destinations, not modals. User re-drew the line: **intro screens (`boxBreathing`, `miniWalk`) in the sweep; session views (`breathingSession`, `breathingSummary`) exempt** — their accessibility is governed by the Reduce Motion fallback decision.

## Area 2: Contrast fix strategy

**Q1. Where do AA failures get fixed?**
- Options: Retune tokens in place · Per-site overrides · HighContrast layer only
- **Selected:** Retune tokens (cream/dark sets shift minimally; no per-site drift)

**Q2. HighContrastModifier (0 call sites) — adopt or delete?**
- Options: Delete it · Adopt as opt-in layer
- **Selected:** Delete it

**Q3. How does the AA gate stay true post-ship?**
- Options: Token-pair unit test · Manual audit only
- **Selected:** Token-pair unit test (≥4.5:1 text / ≥3:1 UI, both appearances)

**Q4. Widget text sits over user wallpaper — how is AA applied?**
- Options: Material pairs only · Simulate wallpapers too
- **Selected:** Material pairs only (wallpaper variability excluded by construction)

## Area 3: Dynamic Type bar

**Q1. Acceptance bar at AX sizes?**
- Options: Zero truncation (locked SC) · Ellipsis allowed
- **Selected:** Zero truncation

**Q2. Charts at AX sizes?**
- Options: Fixed + AX series · Table fallback at AX
- **Selected:** Fixed + AX series (labels/values per point + summary line)

**Q3. Character UI scaling?**
- Options: Exempt + labeled · Scale with text
- **Selected:** Exempt + labeled

**Q4. How is the bar verified?**
- Options: Grep sweep + AX5 UAT · Automated XCUITest at AX5
- **Selected:** Grep sweep (`.accessibleDynamicType()` 1:1 over manifest) + human AX5 walkthrough

## Area 4: Reduce Motion + orphans

**Q1. Breathing under Reduce Motion?**
- Options: Exempt + fallback mode (haptics + countdown, auto-defaulted) · Never animate
- **Selected:** Exempt + fallback mode

**Q2. Decorative animations under Reduce Motion?**
- Options: Blanket stop via one app-wide helper · Case-by-case
- **Selected:** Blanket stop (transitions cross-fade, character static, celebrations → badge + haptic)

**Q3. Orphan bar + method for A11Y-05?**
- Options: Compiled-reachability audit (delete, no #if) · Compiled + legacy set
- **Selected:** Compiled-reachability (legacy uncompiled set deferred as hygiene)

**Q4. Fate of the 65 existing scattered Reduce Motion checks?**
- Options: Consolidate all onto the helper this phase · Helper for new sites only
- **Selected:** Consolidate all (gate enumerates one construct)

---

## Claude's Discretion Items
None explicitly delegated; all decisions user-selected.

## Deferred Ideas
- Onboarding + Paywall accessibility (future polish phase)
- Legacy uncompiled source-set deletion (repo hygiene, outside SC wording)

## Session Notes
- `init.phase-op 3` failed closed (ambiguous archive-name matches from per-milestone numbering restart: v1.1 `03-sessions-preferences-quick-actions-cleanup(.1)`); expected-phase-dir fallback used per workflow (`.planning/phases/03-accessibility-compliance/`), consistent with how the 02 dir was created.
- Context budget note: CONVENTIONS.md's "only 1 file applies `.accessibleDynamicType()`" is stale — scout found 5 adopters.
