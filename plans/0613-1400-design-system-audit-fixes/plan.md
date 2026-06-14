---
title: "Design System Audit Fixes — 145 Issues"
description: "Fix all 145 findings from the 2026-06-13 design system audit: 28 critical (mascot/color/font), 64 major (dark mode/typography/components), 53 minor (spacing/tokens/housekeeping)"
status: in-progress
priority: P1
branch: "main"
tags: [design-system, ui, colors, typography, dark-mode, components, spacing]
blockedBy: []
blocks: [0609-2338-cicd-fastlane-testflight-10k]
created: "2026-06-13T16:37:22.677Z"
createdBy: "ck:plan"
source: skill
---

# Design System Audit Fixes — 145 Issues

## Overview

The 2026-06-13 design system audit found **145 issues** (28 critical, 64 major, 53 minor) across 149 Swift files. Overall token adoption is ~30–40% — the design token files exist but are not enforced at call sites.

**Fix order** follows blast radius: start with visible breaking issues (mascot, teal, Roboto), then dark mode breaks (Color.white), then the large typography sweep, then component consolidation, then spacing housekeeping.

| Category | Critical | Major | Minor |
|----------|---------|-------|-------|
| Color | 8 | 18 | 2 |
| Typography | 15 | 6 | 6 |
| Character/Mascot | 5 | 4 | 5 |
| Component Patterns | 0 | 8 | 4 |
| Dark Mode | 0 | 23 | 14 |
| Spacing | 0 | 5 | 22 |
| **Total** | **28** | **64** | **53** |

## Source

Audit report: `docs/design/design-system-audit-report.md`
Source of truth: `docs/design/character-concept-sheet.html`

## Phases

| Phase | Name | Status | Issues | Effort |
|-------|------|--------|--------|--------|
| 1 | [Critical: Mascot + Old Teal + Roboto Fonts](./phase-01-critical-mascot-old-teal-roboto-fonts.md) | Pending | 28 critical | M |
| 2 | [Dark Mode: Color.white & backgroundLight Migration](./phase-02-dark-mode-color-white-backgroundlight-migration.md) | Pending | 23 major | M |
| 3 | [Typography: Hardcoded font(.system) + monospacedDigit](./phase-03-typography-hardcoded-font-system-monospaceddigit.md) | Pending | 12 major, 6 minor | L |
| 4 | [Component Patterns: GlassCard + AppShadow + Radius Tokens](./phase-04-component-patterns-glasscard-appshadow-radius-tokens.md) | Pending | 8 major, 4 minor | L |
| 5 | [Spacing & Layout: Fractional Values + Spacing Tokens](./phase-05-spacing-layout-fractional-values-spacing-tokens.md) | Pending | 5 major, 22 minor | M |
| 6 | [Minor Housekeeping: Token Dedup + Stress Tier Enum](./phase-06-minor-housekeeping-token-dedup-stress-tier-enum.md) | Pending | 21 minor | S |

## Execution Notes

- **Do not** run all phases simultaneously — phases 1–2 touch the same files (Breathing, Dashboard, Premium) and will conflict
- Phase 3 is the biggest (~274 call sites, not 264) — split by screen folder if parallelizing; includes Premium/IAP files
- Phase 5 depends on [1, 2, 3] — `BreathingExerciseView.swift` is edited by all four; do not parallelize with 1/2/3
- Build after each phase; fix any compile errors before proceeding
- Run existing test suite after phase 6 to verify no regressions

## Red Team Review

### Session — 2026-06-14
**Findings:** 15 (15 accepted, 0 rejected)
**Severity breakdown:** 5 Critical, 6 High, 4 Medium

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | Typography size→token map off-by-one tier (264-site corruption) | Critical | Accept | Phase 3 |
| 2 | `dataLarge` already exists at 48pt; plan proposed 42pt (duplicate symbol) | Critical | Accept | Phase 1 |
| 3 | Track B teal fix no-op — `tealCard` IS `#85C9C9` | Critical | Accept | Phase 1 |
| 4 | StressTier rename ignores watchOS target (build failure) | Critical | Accept | Phase 6 |
| 5 | Roboto verify grep misses 42/48 calls (false-positive pass) | Critical | Accept | Phase 1 |
| 6 | `Roboto-MediumItalic.ttf` not in bundle (silent font fallback) | High | Accept | Phase 1 |
| 7 | `ChatBottomSheetView.swift` has 3 AIKitten refs not in Phase 1 | High | Accept | Phase 1 |
| 8 | Roboto token values conflict with existing (robotoBody Bold/16 ≠ Regular/14) | High | Accept | Phase 1 |
| 9 | GlassCard bg is `Color.secondary.opacity(0.1)` — Phase 4 migration makes cards translucent | High | Accept | Phase 4 |
| 10 | `Color.Wellness.background` dark = #000000; should use `adaptiveBackground` (#121212) | High | Accept | Phase 2 |
| 11 | Phase 3 omits `Views/Premium/` (8 IAP sites fail success criterion) | High | Accept | Phase 3 |
| 12 | `DesignTokens.Layout.cornerRadius` = 12pt, not 20pt | High | Accept | Phase 4 |
| 13 | Phase 2 edits `PremiumBannerView.swift` which Phase 4 deletes — dark mode fix lost | Medium | Accept | Phase 2 + 4 |
| 14 | Phase 5 `dependencies: []` — BreathingExerciseView touched by 5 phases | Medium | Accept | Phase 5 |
| 15 | Token alias requires deleting `let` before adding `var`; else compile error | Medium | Accept | Phase 6 |

### Whole-Plan Consistency Sweep
- Phase 3 size map corrected (largeTitle=34pt, title1=28pt) — no other phase references the old map
- `Color.backgroundLight → adaptiveBackground` (not `.background`) updated consistently in Phase 2 file list and implementation steps
- `BreathingExerciseView.swift` multi-phase conflict resolved: Phase 5 `dependencies: [1, 2, 3]` prevents parallel stomping
- `PremiumBannerView.swift` (Trends) removed from Phase 2 scope; Phase 4 Part D step 14 carries the adaptive bg requirement
- GlassCard migration scope reduced from 32 dashboard cards to character/detail panels only — Phase 4 success criterion updated
- watchOS target added to Phase 6 StressTier file list
- Token alias mechanism (`static var`, not alongside `static let`) explicit in Phase 6
- No remaining contradictions across plan files

## Validation Log

### Session — 2026-06-14
**Questions asked:** 6 | **Verification:** Skipped (Red Team Review present)

| # | Decision | Answer | Applied To |
|---|----------|--------|------------|
| 1 | Old teal replacement color | Ripple blue #4FC3F7 (`Color.settingsRippleBlue`) | Phase 1 Track B; Phase 6 tealCard value update |
| 2 | watchOS StressTier | Rename in sync with iOS (veryCalm/calm/neutral/stressed/critical) | Phase 6 watchOS files |
| 3 | GlassCard for dashboard cards | Skip — keep RoundedRectangle + adaptiveCardBackground | Phase 4 Part E scope reduced |
| 4 | Roboto-MediumItalic missing font | Add Roboto-MediumItalic.ttf to bundle | Phase 1 Track C step 18 |
| 5 | Phase 3 execution strategy | Sequential folder-by-folder in one session | Phase 3 (no change needed) |
| 6 | Roboto call site migration | All raw calls → Typography tokens (zero exceptions) | Phase 1 Track C (no change needed) |

### Whole-Plan Consistency Sweep (post-validation)
- Phase 1 `robotoMediumItalic` now requires bundle asset addition — sequenced before token definition in step 18
- Phase 6 `tealCard` value update added (was missing; needed to complete Ripple blue migration)
- Phase 6 watchOS file list expanded with concrete grep command
- Phase 4 GlassCard scope confirmed as character/overlay panels only — no new DataCard component created
- No unresolved contradictions — plan cleared for implementation

## Execution Log (2026-06-14) — implemented via `/ck:cook --auto, parallel`

**Scout first revealed the audit was partially stale**: commit `bd9b465 refactor(design): global Roboto font + teal color cleanup` + Ripple redesign commits landed AFTER the 2026-06-13 audit, so several findings were already resolved. Plan re-scoped to current code reality; verified with grep + 7 incremental builds (0 errors).

| Phase | Done | Deferred / Skipped | Reason |
|-------|------|--------------------|--------|
| 1 Mascot | ✅ AIKitten/cat.fill/CharacterCalm → `RippleCharacterView`; cat strings → "Ripple" (6 files) | — | — |
| 1 Teal | ✅ `tealCard` + `iapCTATeal` → #4FC3F7 | — | `accentTeal` already #4FC3F7; tealLight/tealDark already gone |
| 1 Roboto tokens | ⏭️ SKIPPED | Track C entirely | **0 raw `Font.custom("Roboto-*)` callers** — already migrated; tokens are SF-Rounded aliases. Adding Roboto-MediumItalic.ttf for 0 callers = bundle bloat (YAGNI) |
| 2 Dark mode | ✅ 18 `Color.white` card/screen bgs + 8 `Color.backgroundLight` → adaptive tokens (16 files) | — | — |
| 3 monospacedDigit | ✅ 8 numeric displays (timer, counters, score, chart axis) | Bulk ~490 `.font(.system)`→token centralization | Tokens are also fixed-size `Font.system` → **no Dynamic Type/accessibility gain, no visual change** for exact matches; pure centralization, low value/high volume; exact-match-only covers few, snapping risks regressions |
| 3 `design:.rounded` | ⏭️ deferred | 168 raw rounded usages | roboto*/data* tokens legitimately use `.rounded`; bulk cleanup is centralization |
| 4 Shadows | ✅ new `settingsCardDoubleShadow()` modifier, dedup'd 5 cards | GlassCard/glow tokens | Already correctly scoped out per plan; low centralization value |
| 4 Buttons | ⏭️ SKIPPED | 3 `.borderedProminent` sites | `PrimaryButton` is a full-width CTA View (fixed blue, `title:String` only) — NOT a drop-in; sites use dynamic `.tint()`, `Label`, `.controlSize`; forcing it regresses |
| 4 PremiumBanner | ✅ in-place mascot+bg fix | delete+rewire consolidation | In-place fix achieves dark-mode/mascot goals safely; deletion = risk for marginal DRY |
| 5 Fractionals | ✅ 18 padding/spacing fractionals snapped to grid (5 files) | on-grid literal→Spacing token centralization; `WeekCalendarStrip 2.8` micro-gap | Centralization low value; 2.8→4 would loosen calendar cell 43% |
| 6 Token dedup | ✅ `iapTextMuted`→`textTertiary`, `bannerYellow`→`settingsAmberInfo` aliases | — | — |
| 6 StressTier rename | ✅ DONE (iOS + watchOS) | — | Renamed both per-target enums → veryCalm/calm/neutral/stressed/critical; spec colors (#4CAF50/#81C784/#FFB74D/#FF8A65/#E53935); labels updated. rawValues (0-4) preserved so `from()`/`fillFraction` logic intact. Build's exhaustive-switch checking caught 2 type-inferred literals grep missed (HorizontalWeekCalendarView dict value, MascotSpeechBubbleView preview). iOS + watchOS both build clean. |
| 6 `.black.opacity` shadows | ⏭️ SKIPPED | → `Color.primary` | Would make dark-mode shadows **white glow** (Color.primary=white in dark) — regresses; debatable design, not a clear fix |

**Verification (grep):** AIKitten/cat.fill/CharacterCalm=0 · 85C9C9=0 · `.background(Color.white)` in Views=0 · `Color.backgroundLight` in Views=0 · `cornerRadius(33)`=0 · `.monospacedDigit()`=13 · `settingsCardDoubleShadow()`=5 · token aliases present.

**Build:** iOS sim (iPhone 17 / iOS 26.5) — 7× SUCCEEDED, 0 errors. **Tests:** runner hit a pre-existing environmental "no test bundles available to test" build-for-testing issue (tests don't reference any changed symbols; not a regression).
