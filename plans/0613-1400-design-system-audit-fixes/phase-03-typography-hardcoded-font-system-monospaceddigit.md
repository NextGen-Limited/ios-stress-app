---
phase: 3
title: "Typography: Hardcoded font(.system) + monospacedDigit"
status: pending
priority: P2
effort: "6h"
dependencies: [1]
---

# Phase 3: Typography — Hardcoded font(.system) + monospacedDigit

## Overview

Tackle the 264 hardcoded `.font(.system(size:))` call sites that bypass Typography tokens and Dynamic Type. Also fix 57 unauthorized `design: .rounded` usages, and add `.monospacedDigit()` to 6 numeric displays.

Phase 1 must complete first (Typography.swift may need new tokens added there).

## Requirements

- Functional: Every text style goes through a `Typography.*` token — zero raw `.font(.system(size:))` in Views/
- Functional: `design: .rounded` only on `data*` tokens (dataHero, dataLarge, dataMedium, dataSmall)
- Functional: All timer/counter/numeric Text views use `.monospacedDigit()`
- Non-functional: Dynamic Type scaling works for all text on all screens

## Architecture

**Typography token size map** (verified against `Views/DesignSystem/Typography.swift`):

> ⚠️ **Red-team finding F1**: Original table was off-by-one tier throughout. Corrected below.

| Raw size | Weight | Token | Actual token size |
|----------|--------|-------|-------------------|
| 34 | bold | `Typography.largeTitle` | 34pt |
| 28 | bold/semibold | `Typography.title1` | 28pt |
| 22 | bold | `Typography.title2` | 22pt |
| 20 | semibold | `Typography.title3` | 20pt |
| 17–18 | semibold/bold | `Typography.headline` | 17pt |
| 17 | regular | `Typography.body` | 17pt |
| 15–16 | regular/medium | `Typography.callout` | 16pt |
| 13–14 | regular | `Typography.subheadline` | 15pt |
| 13 | regular | `Typography.footnote` | 13pt |
| 12 | regular | `Typography.caption1` | 12pt |
| 11 | regular | `Typography.caption2` | 11pt |

**data* tokens** (only ones allowed to use `design: .rounded`):
- `Typography.dataHero` — 72pt bold rounded (StressRingView score)
- `Typography.dataLarge` — 48pt bold rounded
- `Typography.dataMedium` — 34pt bold rounded
- `Typography.dataSmall` — 28pt bold rounded

**Strategy for ~274 sites** — scan by folder (red-team corrected: 264 was undercounted):

> ⚠️ **Red-team finding F11**: Original folder list omitted Premium, Onboarding, Action, Characters, Chat — ~92 additional sites. Corrected count ~274.

| Folder | ~Sites | Notes |
|--------|--------|-------|
| `Views/Dashboard/` | ~80 | Largest folder |
| `Views/Settings/` | ~70 | |
| `Views/Onboarding/` | ~44 | Previously omitted |
| `Views/Action/` | ~35 | Previously omitted |
| `Views/Breathing/` | ~40 | |
| `Views/History/` + `Views/Trends/` | ~40 | |
| `Views/Premium/` | ~8 | Previously omitted; use IAP-specific tokens (`iapHeroHeadline`, `iapNavTitle`, `iapCTA`) |
| `Views/DesignSystem/` + `Views/Components/` | ~34 | |
| `Views/Chat/` + `Views/Characters/` | ~5 | Previously omitted |

## Related Code Files

### Modify — monospacedDigit (6 files, fast wins)
- `Views/Breathing/BreathingSessionView.swift:58` — timer display
- `Views/Breathing/BreathingExerciseView.swift:128` — phase counter
- `Views/Breathing/BreathingSummaryView.swift:74` — HRV values ×3
- `Views/Dashboard/Components/StressRingView.swift:40` — 72pt score
- `Views/Dashboard/Components/CompactStressHeaderBar.swift:45` — inline stress score
- `Views/Dashboard/Components/HRVTrendCard.swift:72` — chart Y-axis label

### Modify — unauthorized design: .rounded (57 sites across Settings, Breathing, general UI)
Key files:
- `Views/Settings/Components/ComplicationWidget.swift:31` — `size: 7.5, design: .rounded` → `Typography.caption2` (no rounded)
- `Views/Settings/Components/SettingsCharacterStatusHeader.swift:31` — `size: 22, design: .rounded` → `Typography.title3`
- `Views/Settings/DataManagement/DataDeleteView.swift:113` — `size: 18, design: .rounded` → `Typography.headline`
- `Views/Settings/DataManagement/Components/ExportProgressView.swift:36` — `size: 28, design: .rounded` → `Typography.dataSmall` (this one IS a data token — keep rounded)
- Remaining 53 sites: remove `design: .rounded` from non-data contexts

### Modify — hardcoded .font(.system) bulk sweep
All files in Views/ matching `\.font(\.system(size:` that are NOT already using Typography tokens.

## Implementation Steps

### Part A — monospacedDigit (fast, 6 files)
1. Add `.monospacedDigit()` after `.font(...)` in each of the 6 files listed above
2. Verify build compiles

### Part B — Unauthorized design: .rounded
3. `grep -rn "design: \.rounded" Views/ --include="*.swift"` — list all 57+ sites
4. For each site: if it's a `data*` token context (large numeric display) → keep `design: .rounded`; otherwise remove it and map to a non-rounded Typography token
5. `ExportProgressView.swift:36` is correct (28pt bold rounded = `Typography.dataSmall`) — leave it, but switch to the token reference

### Part C — Hardcoded .font(.system) bulk sweep (264 sites)
6. For each folder batch, run: `grep -rn "\.font(\.system(size:" Views/Dashboard/ --include="*.swift"`
7. Map each raw size/weight combo to the closest Typography token using the size map above
8. Edge cases:
   - `size: 7.5` → snap to `Typography.caption2` (10pt); note this is a widget-specific tiny size — verify visually
   - `size: 14.9` → round to 15 → `Typography.callout`
   - Where exact size doesn't match any token, pick nearest and add inline comment explaining the intent
9. After each folder batch, build and fix compile errors before moving to next batch
10. Final grep to verify zero remaining `.font(.system(size:` in Views/

## Success Criteria

- [ ] `grep -r '\.font(\.system(size:' Views/ --include="*.swift" | wc -l` returns 0
- [ ] `grep -r 'design: \.rounded' Views/ --include="*.swift"` returns only `dataHero`, `dataLarge`, `dataMedium`, `dataSmall` token definitions and call sites
- [ ] 6 numeric Text views have `.monospacedDigit()` modifier
- [ ] Build succeeds
- [ ] No Dynamic Type regressions (verify with Accessibility Inspector in simulator at xLarge size)

## Risk Assessment

- **Scale**: High — ~274 sites (not 264) is the largest single-phase change; mistakes compound across files
- **Mitigation**: Work folder-by-folder; build after each batch; keep a sed/replace log for easy rollback
- **Size mismatches**: Medium — `7.5` ComplicationWidget may look wrong at integer snap; test in simulator
- **Authorization boundary**: Low — clear rule: `design: .rounded` only in `data*` contexts
