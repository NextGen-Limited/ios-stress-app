---
phase: 03-accessibility-compliance
plan: 03
subsystem: ui
tags: [accessibility, wcag, touch-targets, voiceover, swiftui, dual-coding, empty-states]

requires:
  - phase: 03-accessibility-compliance
    provides: ContrastComplianceTests green baseline + retuned tokens + dual-coding caption on the adaptive secondary token (03-01)
  - phase: 03-accessibility-compliance
    provides: reworked .accessibleDynamicType() adopted on all 14 D-03 surfaces + dated-exception marker convention (03-02)
provides:
  - 44pt touch-target floor adopted via .minimumTouchTarget(DesignTokens.Layout.minTouchTarget) on every sub-44 control found on the 14 D-03 surfaces (10 control classes upgraded)
  - Zero unlabeled icon-only interactive controls on the swept surfaces
  - .stressDualCoding adopted at every category display on the manifest surfaces (3 sites; modifier extended with showsCaption for name-bearing sites)
  - Dashboard error alert states the failing operation + Try Again; Trends zero-data branch renders NoDataCard(.trends)
  - Locked-character dimming scoped to the illustration only — card text at full token contrast
  - D-09 character a11y package (label + evolution-stage value) on grid cards and the Lumi streak card
  - All 7 app-side minimumScaleFactor sites dispositioned per D-10 with dated exception markers
  - 03-01 residuals closed: StressHeroCard readableTextColor text (#B8860B) and AIChatCard #808080 literals token-bound
affects: [03-04, 03-05, 03-06, phase-4-verification]

actuals:
  tokens: 5600
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Hit-area expansion wraps the Button OUTSIDE its label (after .buttonStyle) so the visual glyph stays small while the contentShape covers >=44pt — the hit area may exceed the glyph without changing the visual"
    - "stressDualCoding(_:showsCaption:) — pass false where the content already renders the display name; the symbol channel + combined label still apply (no duplicated visible name)"
    - "Empty-state triage outcome vocabulary: NoDataCard branch (surface can render zero rows) vs recorded disposition (static content / seeded at launch)"
    - "D-10 shrink disposition: fixed-size fonts (Font.system(size:)) are not on the DT ramp, so a minimumScaleFactor there is a width guard, not a Dynamic Type shrink — marked, not removed, where geometry cannot wrap"

key-files:
  created: []
  modified:
    - StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift
    - StressMonitor/StressMonitor/Views/DashboardView.swift
    - StressMonitor/StressMonitor/Views/Trends/TrendsView.swift
    - StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift
    - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
    - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift
    - StressMonitor/StressMonitor/Views/History/MeasurementDetailView.swift
    - StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift
    - StressMonitor/StressMonitor/Views/Characters/Components/CharacterGridCard.swift
    - StressMonitor/StressMonitor/Views/Breathing/BreathingExerciseView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/NoDataCard.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressHeroCard.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/AIChatCard.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/MoodCheckInView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/PremiumBanner.swift
    - StressMonitor/StressMonitor/Views/Settings/Components/PlusPill.swift
    - StressMonitor/StressMonitor/Views/Settings/Components/CompanionBanner.swift
    - StressMonitor/StressMonitor/Views/Action/Components/RippleRecommendationCard.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/BioAgeCardView.swift
    - StressMonitor/StressMonitor/Views/Dashboard/Components/StressSourcesCard.swift
    - StressMonitor/StressMonitor/Views/History/BioAgeDetailView.swift
    - StressMonitor/StressMonitor/Views/Characters/CharacterPickerSheet.swift
    - StressMonitor/StressMonitor/Views/Characters/Components/EvolutionStageRow.swift

key-decisions:
  - "Hit-area expansion is applied outside the Button label: the frame/contentShape modifier wraps the whole button, so capsule chips, pills, and icon glyphs keep their visual size while gaining a 44pt target — never the reverse"
  - "StressDualCodingModifier extended with showsCaption (default true, byte-identical for the default) because every category display found on the manifest surfaces already renders the display name — bare adoption would have shown the name twice"
  - "StressHeroCard state label switched from category.readableTextColor to category.color: the retuned moderate #8A5A00 passes 4.5:1 even at body size, closing the 03-01 #B8860B (3.20:1) residual without a visual redesign; readableTextColor is now zero-adopter (deletion dispositioned to 03-06)"
  - "D-09 value copy uses 'Evolution stage {n} of 3' per code truth (EvolutionStage has 3 cases; the in-app banner says 'Each character evolves 3 stages') — the UI-SPEC's 'of 5' contradicts the enum and would mislead VoiceOver users"
  - "TrendsView confirmed capable of rendering zero rows (repository-backed async read starting from empty arrays) -> NoDataCard(.trends) branch added; ActionView and DataManageView confirmed structurally non-empty -> recorded dispositions, no invented branches"

patterns-established:
  - "Touch-target adoption pattern: <control>.buttonStyle(.plain).minimumTouchTarget(DesignTokens.Layout.minTouchTarget)"
  - "Icon-only control contract: minimumTouchTarget + accessibilityLabel naming the action ('Share measurement', 'Back') — decorative icons inside labeled rows stay accessibilityHidden/combined"

requirements-completed: [A11Y-01]

coverage:
  - id: D1
    description: "44pt touch-target floor on every sub-44 interactive control across the 14 D-03 surfaces + risk-class components, with every icon-only control labeled"
    requirement: A11Y-01
    verification:
      - kind: other
        ref: grep -rn "minimumTouchTarget(" StressMonitor/StressMonitor/Views -> 10 sites, 0 non-token arguments; chart-file diff check 0; xcodebuild build -> ** BUILD SUCCEEDED **; swiftlint -> no new violations on added lines
        status: pass
    human_judgment: true
    rationale: "Intrinsic-size compliance of Form rows/system controls and adjacency non-overlap are runtime properties verified per surface in the 03-06 Accessibility Inspector scan; source-level adoption is machine-proven but not the whole of A11Y-01"
  - id: D2
    description: "Dual coding adopted at every category display on the manifest surfaces (hue + SF Symbol + display name together via the shared modifier)"
    verification:
      - kind: other
        ref: grep stressDualCoding in Views -> 3 sites (StressHeroCard, MeasurementDetailView, DistributionBar); build SUCCEEDED
        status: pass
    human_judgment: true
    rationale: "Whether every hue-bearing element on each surface carries an adjacent symbol/name is a per-surface visual judgment; chart-internal indicators are 03-04 ownership and verified there"
  - id: D3
    description: "State-shape triage: operation-titled Dashboard alert with Try Again, Trends NoDataCard zero-data branch, Action/DataManage recorded cannot-render-empty dispositions, locked-character dimming scoped to illustration, D-09 character label/value package"
    verification:
      - kind: other
        ref: triage greps (Couldn't load health data=1, Try Again=1, NoDataCard TrendsView=1, Evolution stage=1) + build SUCCEEDED
        status: pass
    human_judgment: false
  - id: D4
    description: "D-10 shrink sweep: all 7 app-side minimumScaleFactor sites dispositioned (dated exception markers, reasons enumerated)"
    verification:
      - kind: other
        ref: grep "dated exception" across the 6 files -> 7 markers, all <=119 chars (lint-clean)
        status: pass
    human_judgment: true
    rationale: "'Genuinely cannot wrap' is a layout judgment; the 03-06 AX5 walkthrough is the backstop that renders these sites at accessibility sizes"

duration: 20 min
completed: 2026-09-05
status: complete
---

# Phase 3 Plan 03: Touch-Target + Label Sweep Summary

**44pt token-backed hit areas on every sub-44 control across the 14 manifest surfaces (10 control classes), dual coding at every category display via an extended shared modifier, the three state gaps closed with documented patterns (operation-titled alert, NoDataCard(.trends), illustration-only locked dimming), and all 7 app-side D-10 shrink sites dispositioned**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-05T01:54:32Z
- **Completed:** 2026-09-05T02:15:08Z
- **Tasks:** 3 (all auto)
- **Files modified:** 23 (1 shared modifier + 22 view files)

## Accomplishments
- A11Y-01 sweep: 10 control classes upgraded to `.minimumTouchTarget(DesignTokens.Layout.minTouchTarget)` — Trends range chips, Settings toggles + AI-coach menu pickers, MeasurementDetail share toolbar button, Breathing back toolbar button, NoDataCard action, PlusPill, CompanionBanner Switch, RippleRecommendationCard CTA, PremiumBanner CTA pill. Every icon-only interactive control on the swept surfaces now carries an action-named label.
- Dual coding adopted at all 3 category displays found on the manifest surfaces (dashboard hero label, measurement-detail hero label, Trends tier legend); the shared modifier gained `showsCaption` so name-bearing sites adopt without a duplicated visible name.
- State gaps closed: Dashboard alert retitled "Couldn't load health data" + "Try Again"; TrendsView gained the NoDataCard zero-data branch (`.trends` case with per-surface copy); locked character cards dim the illustration block only; grid + Lumi cards carry the D-09 label/value package.
- 03-01 residuals closed: StressHeroCard state label left `readableTextColor` (#B8860B, 3.20:1) for `category.color` (#8A5A00, 5.82:1 — passes even body-size AA); AIChatCard's four `#808080` literals token-bound to `adaptiveSecondaryText`.
- All 7 app-side `minimumScaleFactor` sites dispositioned per D-10 with lint-length-safe dated-exception markers.

## Per-Surface Enumeration (the phase-UAT Inspector scan input)

| # | Surface | Controls upgraded to 44pt | Labels added | Intrinsically compliant (left unchanged) |
|---|---------|---------------------------|--------------|------------------------------------------|
| 1 | DashboardView | (via components below) | — | PremiumBanner full-card Button; NoDataCard action (converted to helper) |
| 2 | ActionView | RippleRecommendationCard CTA pill (~35pt) | — | reflectRow minHeight 44; ActionGroupRow minHeight 44; HabitLogRow minHeight 44 (all already combine + labeled) |
| 3 | TrendsView | Range chips Week/Month/3-Months/Year (~30pt tall) | — | — |
| 4 | SettingsView | 3 notification/preference Toggles; 2 AI-coach menu Pickers | — | navRows (48pt by 28pt badge + padding, combined + labeled); iconBadges decorative-hidden |
| 5 | DataExportView | — | — | Form rows (system >=44): segmented picker, DatePickers, Toggles, format row, Export button row; Cancel toolbar button text-labeled |
| 6 | DataManageView | — | 4 row Buttons gained `.combine` + action-named labels (decorative icon/chevron noise suppressed) | Form rows >=44; rowLabels have visible title+subtitle |
| 7 | DataDeleteView | — | — | Form rows >=44; Delete/Cancel labeled + hinted |
| 8 | CharacterCollectionView | — (grid/Lumi cards far exceed 44pt) | Grid + Lumi tap cards gained the D-09 label/value package (Task 3) | onTapGesture cards with contentShape |
| 9 | AppearanceSettingsView | — | — | Form rows >=44; scheme buttons labeled + isSelected traits |
| 10 | AboutView | — | — | Form rows >=44; link rows labeled |
| 11 | WatchFacePreferencesView | — | — | Form rows >=44 (36pt asset + padding = 44); companion/style rows labeled + isSelected |
| 12 | MeasurementDetailView | Share toolbar button (icon-only, ~20pt glyph) | "Share measurement" | Action bar buttons ~66pt with visible text |
| 13 | BreathingExerciseView | Back toolbar button (icon-only, ~16pt glyph) | — (already had "Back") | Begin Session 50pt; Cancel 44pt |
| 14 | MiniWalkView | — | — | Pause/Resume + End Session 48pt; MiniWalkCompleteView buttons 50-56pt |
| R | Risk-class components | MoodCheckInView chips — intrinsically 64pt tall; QuickActionGrid tiles — minHeight 108 | Mood chips already labeled ("Mood: …" + isSelected) | Both carry glyph+name+color (triple-coded) |

Component files swept beyond the plan list (floor-not-ceiling): NoDataCard, PlusPill, CompanionBanner, RippleRecommendationCard, PremiumBanner, ActionGroupRow, HabitLogRow, MeHeroCard, MiniWalkCompleteView, FormatPickerRow, RecommendationCard (last five verified compliant, no change needed).

## Dual-Coding Adoption Sites

| Surface | Element | Form |
|---------|---------|------|
| Dashboard (StressHeroCard) | Current-reading category label (30pt bold) | `category.color` (was `readableTextColor`) + `.stressDualCoding(category, showsCaption: false)` — symbol joins the name; hue stays on arc + label + icon |
| MeasurementDetailView | Hero category name (20pt semibold) | `.stressDualCoding(category, showsCaption: false)` — symbol channel added |
| TrendsView (DistributionBar) | Tier legend swatches (4) | `.stressDualCoding(tier, showsCaption: false)` on each swatch — symbol sits between swatch and the existing tier name + day count |

Dual-coding dispositions (verified, not adoption sites): DistributionBar stacked-bar segments and MonthlyCalendarHeatmap cells are chart geometry named by the adjacent legend / combined a11y label (03-04 owns chart-internal accessibility); StressOverTimeChart's tier legend lives inside the chart file (03-04 file ownership); MeasurementDetail stress-scale bar carries numeric labels + hero name adjacency; ActionView's header category mention is text-only (no hue element — already fully redundant); MoodCheckInView chips map MoodLevel (not StressCategory) and are glyph+name+color triple-coded by construction; DataManageView renders no category column.

## State-Shape Triage Record

| Surface | Probe outcome | Resolution |
|---------|---------------|------------|
| DashboardView error alert | Generic "Error"/OK with bare localizedDescription | Retitled "Couldn't load health data" + "Try Again" (reload) / "Cancel"; genuine no-data path unchanged — NoDataCard's action remains its next step |
| TrendsView | CAN render zero rows (repository-backed async read; `weeklyMeasurements` empty on fresh install) | NoDataCard branch: `.trends` case ("No Trends Yet" / "Measure stress for a few days to see your patterns here." / "Refresh"); chips stay visible |
| ActionView | Confirmed probe: static quick-action tiles + mood check-in writes; habit rows always render over the fixed HabitType set; no async read path | Disposition: cannot render empty — static content. No branch added |
| DataManageView | Static Form hub; records row renders count 0 gracefully | Disposition: cannot render empty — static hub. No branch added |
| CharacterCollectionView | Confirmed probe: CharacterUnlock rows seeded at app launch over the fixed 5-character set | Disposition: seeded at launch. Grid/Lumi cards always render |
| Locked character cards | 0.65 opacity + 0.5 saturation applied to the WHOLE grid card (text included) — lumi card already dimmed illustration-only | Dimming moved to the illustration ZStack only; name/subtitle/badge/stage text at full token contrast |

## D-10 Shrink Dispositions (7 sites, all kept behind dated markers)

| File:Line | Site | Reason (full form; marker on line is lint-length-shortened) |
|-----------|------|-------|
| MoodCheckInView:66 | 10pt chip label, 0.7 | Single-word label in a fixed-height 64pt 5-across chip cannot wrap; font is fixed-size (not on the DT ramp), so this is a width guard, not a Dynamic Type shrink |
| BioAgeCardView:80 | 56pt hero numeral, 0.8 | Gauge-class numeral (D-09 fixed size, not on the DT ramp); 3-digit width overflow clamp |
| StressSourcesCard:152 | 12pt legend label, 0.7 | Label inside a fixed 65pt-wide legend cell (N-across); single word cannot wrap; fixed-size font |
| BioAgeDetailView:67 | 96pt hero numeral, 0.5 | Gauge-class numeral (D-09); width overflow clamp only |
| CharacterPickerSheet:65 | 13pt name, 0.8 | Single-word name under a fixed 52pt illustration in an N-across picker grid; Typography token is fixed-size, not on the DT ramp |
| EvolutionStageRow:55 | 12pt stage name, 0.7 | Single-word stage name in an N-across 3-column row cannot wrap; fixed-size font |
| EvolutionStageRow:64 | 9pt mono caption, 0.7 | Last-resort clamp after the 2-line wrap inside a fixed N-across card; fixed-size font |

Common principle: none of the 7 fonts ride the DT ramp (all bare `Font.system(size:)`), so the shrink factors cannot truncate Dynamic Type growth — they are static width guards in unwrappable geometry. BioAgeCardView / BioAgeDetailView / CharacterPickerSheet read as orphan candidates (03-05 audit owns their deletion decision).

## Task Commits

Each task was committed atomically:

1. **Task 1: Touch-target + icon-only-label sweep on the 13 non-character surfaces and risk-class components** - `8b18e97` (fix)
2. **Task 2: Dual-coding adoption wherever a stress category shows** - `07dee28` (fix)
3. **Task 3: State-shape triage — error alert copy, empty states, locked-character dimming, probe dispositions** - `4aa2a5f` (fix)

**Plan metadata:** (docs commit follows this summary)

## Files Created/Modified
- `Utilities/AccessibilityModifiers.swift` - stressDualCoding gains showsCaption (default true, byte-identical)
- `Views/DashboardView.swift` - operation-titled error alert with Try Again
- `Views/Trends/TrendsView.swift` - chip hit areas + zero-data NoDataCard branch
- `Views/Trends/Components/DistributionBar.swift` - tier legend dual coding
- `Views/Settings/SettingsView.swift` - Toggle/Picker hit areas
- `Views/Settings/DataManagement/DataManageView.swift` - row button combine + labels
- `Views/History/MeasurementDetailView.swift` - share button target + label; hero dual coding
- `Views/Characters/CharacterCollectionView.swift` - Lumi card D-09 package
- `Views/Characters/Components/CharacterGridCard.swift` - illustration-only dimming + D-09 label/value
- `Views/Breathing/BreathingExerciseView.swift` - back button target
- `Views/Dashboard/Components/NoDataCard.swift` - helper-converted target + `.trends` case
- `Views/Dashboard/Components/StressHeroCard.swift` - category.color + dual coding
- `Views/Dashboard/Components/AIChatCard.swift` - #808080 -> adaptiveSecondaryText (orphan candidate; fixed per 03-01 handoff)
- `Views/Dashboard/Components/MoodCheckInView.swift`, `PremiumBanner.swift`, `BioAgeCardView.swift`, `StressSourcesCard.swift` - target / marker work
- `Views/Settings/Components/PlusPill.swift`, `CompanionBanner.swift` - hit areas
- `Views/Action/Components/RippleRecommendationCard.swift` - CTA hit area
- `Views/History/BioAgeDetailView.swift`, `Views/Characters/CharacterPickerSheet.swift`, `Views/Characters/Components/EvolutionStageRow.swift` - D-10 markers

## Decisions Made
- See key-decisions in frontmatter. Notably: hit-area expansion wraps buttons from the outside (visual glyph unchanged); `showsCaption` default preserves the modifier's 03-01-proven behavior; "of 3" over the UI-SPEC's "of 5" per code truth.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] StressDualCodingModifier extended with `showsCaption`**
- **Found during:** Task 2 (site reading)
- **Issue:** Every category display found on the manifest surfaces already renders the display name (hero labels, legend items). Bare `.stressDualCoding(_:)` adoption appends icon + name caption after the content, producing a duplicated visible name ("Elevated [icon] Elevated") — a UI regression the plan's adoption instruction did not account for.
- **Fix:** Added `showsCaption: Bool = true` parameter (default path byte-identical; 03-01's proven caption binding untouched). Name-bearing sites adopt with `showsCaption: false`, receiving the symbol channel + combined a11y label without duplication.
- **Files modified:** Utilities/AccessibilityModifiers.swift
- **Verification:** Build SUCCEEDED; default-parameter path renders the same HStack (compiler-checked `if showsCaption` branch); 3 adoption sites green
- **Committed in:** `07dee28`

**2. [Rule 1 - Bug] D-09 value copy corrected to "Evolution stage {n} of 3"**
- **Found during:** Task 3 (CharacterCollectionView work)
- **Issue:** UI-SPEC copy says "Evolution stage {n} of 5", but `EvolutionStage` has exactly 3 cases (droplet/ripple/tidal) and the in-app evolution banner says "Each character evolves 3 stages". Shipping "of 5" would state a falsehood to VoiceOver users.
- **Fix:** Value renders "Evolution stage {n} of 3" via `EvolutionStage.allCases.count` (self-maintaining if the enum grows). Label copy ("{name}, {stage} stage" / "{name}, locked") is verbatim from the UI-SPEC.
- **Files modified:** CharacterGridCard.swift, CharacterCollectionView.swift
- **Verification:** grep "Evolution stage" = 1 site per file; build SUCCEEDED
- **Committed in:** `4aa2a5f`

**Total deviations:** 2 auto-fixed (1 Rule 3 blocker, 1 Rule 1 spec-vs-truth correction). **Impact:** Both required to land the plan's own contract (dual-coding everywhere; honest D-09 copy). No scope creep — the modifier extension is behavior-preserving by default.

## Issues Encountered
None. App scheme BUILD SUCCEEDED after each task; ContrastComplianceTests re-run TEST SUCCEEDED on the final tree; SwiftLint reports no new violations on added lines (pre-existing warnings in touched files — DataManageView long rowLabel lines, StressHeroCard SemicircleArc short identifiers, SettingsView file length — predate this plan and are untouched).

## Known Stubs
None. (Note: AIChatCard is an orphan candidate — only its own preview references it — but its contrast literals were fixed per the explicit 03-01 handoff; its deletion is 03-05's call.)

## Next Phase Readiness
- 03-04 (charts/D-09): chart-internal indicators left untouched per file ownership — StressOverTimeChart's tier legend, MonthlyCalendarHeatmap cells, DistributionBar segments, MeasurementDetail scale bar each need their accessibility series treatment; the showsCaption:false pattern is available for their legends.
- 03-05 (orphans): AIChatCard, BioAgeCardView, BioAgeDetailView, CharacterPickerSheet confirmed unreferenced from the surfaces swept here (grep 2026-09-05); StressSourcesCard referenced only by TrendsStressSourcesCard (chain needs the D-14 audit).
- 03-06 (final gate): `readableTextColor` is now zero-adopter (deletion candidate, mirrors the stressRelaxed… statics disposition); the 7 dated-exception markers above are the D-10 grep's expected output; the per-surface enumeration table is the Accessibility Inspector scan checklist.

## Self-Check: PASSED
