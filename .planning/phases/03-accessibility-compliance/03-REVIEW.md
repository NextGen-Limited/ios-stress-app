---
phase: 03-accessibility-compliance
reviewed: 2026-09-05T14:55:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift
  - StressMonitor/StressMonitorTests/ContrastComplianceTests.swift
  - StressMonitor/StressMonitor/Models/StressCategory.swift
  - StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift
  - StressMonitor/StressMonitor/Views/Settings/Components/MeHeroCard.swift
  - StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift
  - StressMonitor/StressMonitor/Theme/Color+Extensions.swift
  - StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift
  - StressMonitor/StressMonitorWatch Watch App/Theme/WatchDesignTokens.swift
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: findings
---

# Phase 3: Code Review Report (Re-Review After Fix Pass)

**Reviewed:** 2026-09-05T14:55:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** findings

## Summary

Re-reviewed the 9 files touched by the fix pass (commits dd9fd6f, b52855d, 6e173aa, 0837136, 3af8973, a585b67, 57258bc, 250f990) against the original `03-REVIEW.md` findings (CR-01, WR-01..WR-07). Every contrast-ratio claim was independently recomputed from the WCAG relative-luminance formula (0.03928 threshold, lighter-luminance-first, matching `ContrastComplianceTests`'s own implementation).

**Verification verdict — 6 of 8 original findings fully close; 2 have residual gaps:**

| ID | Verdict | Note |
|----|---------|------|
| CR-01 | **CLOSED** | `DistributionBar` moderate segment now resolves text color via `@Environment(\.colorScheme)`. Recomputed: white on `#8A5A00` (light) = 5.93:1, black on `#FFD60A` (dark) = 14.9:1. Both pass. |
| WR-01 | **CLOSED (iOS scope)** | `accessibilityDescription`, `accessibilityValue`, `DistributionBar` legend, `StressBarChartView` label, `MeHeroCard.stressLabel` all now route through `displayName` ("Elevated"). Watch-side scope dispute — see new WR-08 below; the stated justification for leaving it does not hold up. |
| WR-02 | **CLOSED** | Watch `StressCategory.category(for:)` now matches iOS exactly (`..<25/..<50/..<75/..<90`/default), doc table and `scoreRange` updated to `75...90`/`90...150`. |
| WR-03 | **CLOSED** | Watch `inkColor` now `{ color }`, dropping the `#B59400` special case. Recomputed `#8A5A00` vs watch canvas `#F2F2F7` = 5.31:1. |
| WR-04 | **CLOSED** | `iapCTATeal` retuned `#4FC3F7` → `#0891B2`. Recomputed white-on-fill = 3.68:1, clears the 3:1 fill-safe bar (button text is bold ≥14pt via `Typography.iapCTA`, qualifying as large text). |
| WR-05 | **NOT FULLY CLOSED** | See new CR-03 below — the trend line/fill now pass 3:1, but the chart's own text elements still fail 4.5:1 and the new test doesn't catch it. |
| WR-06 | **CLOSED** | Residual now assigned via `days.lastIndex(where: { $0 > 0 })` — keyed off raw day counts, not rounded percentages, so a tier can only receive nonzero % if it actually has nonzero days. Verified against several rounding-overshoot/undershoot cases (e.g. days `[1,1,1,0]` → `34/33/33/0`, not `33/33/33/1`). |
| WR-07 | **CLOSED (marginal)** | `WatchDesignTokens.muted` retuned `#777986` → `#6B6E7B`. Recomputed = 4.541:1 against watch canvas `#F2F2F7` — passes 4.5:1 but by a hair; see IN-02. No call site applies extra `.opacity()` on top of it. |

**New issues found during this re-review** (not part of the original 8, discovered by reading the same files at standard depth):

## Critical Issues

### CR-01 (new): `DistributionBar`'s default white segment-label text fails contrast for relaxed/mild/high — the CR-01 fix only covered moderate

**File:** `StressMonitor/StressMonitor/Views/Trends/Components/DistributionBar.swift:94-102, 110`
**Issue:** `barSegment(color:width:label:textColor:)` defaults `textColor` to `.white` for every tier except moderate (which now resolves via `colorScheme`, per the closed CR-01). Recomputing WCAG contrast for the "NN%" label (11pt semibold — not large text, needs 4.5:1) against each tier's actual fill:

| Tier | Light fill | White-on-fill | Dark fill | White-on-fill |
|------|-----------|----------------|-----------|----------------|
| Relaxed | `#00A000` | **3.48:1 — fails** | `#30D158` | **2.02:1 — fails badly** |
| Mild | `#007AFF` | **4.02:1 — fails** | `#0A84FF` | **3.65:1 — fails** |
| High | `#B25400` | 5.05:1 — passes | `#FF9F0A` | **2.06:1 — fails badly** |

Only moderate (fixed by CR-01) and light-mode high pass. In dark mode, 3 of 4 segment labels render at ~2–3.7:1 — the relaxed and high dark-mode cases are especially severe (~2:1, the same class of failure the original CR-01 called out for moderate). None of these pairs are covered by `ContrastComplianceTests` (only the moderate pair was added). This is not a regression from the fix pass — it pre-dates the phase — but it sits in the exact function CR-01 touched and was not caught by either the original audit or the fix.
**Fix:** Extend the same `@Environment(\.colorScheme)`-driven approach (or per-tier fixed dark text where the fill is light enough) to all four segments, e.g.:
```swift
private func labelTextColor(for tier: StressCategory) -> Color {
    switch tier {
    case .high:     return colorScheme == .dark ? .black : .white   // light passes now; verify dark fill first
    case .relaxed, .mild: return .black  // both light/dark fills are too bright for white text
    case .moderate: return colorScheme == .dark ? .black : .white   // already correct
    default: return .white
    }
}
```
Recompute each pairing before shipping and add all four to `ContrastComplianceTests` (not just moderate).

### CR-02 (new, continuation of WR-05): `HRVTrendChart`'s numeral and annotation text still fail 4.5:1 after the accent retune — the new test only pins the loosened 3:1 bar

**File:** `StressMonitor/StressMonitor/Views/Trends/Components/HRVTrendChart.swift:16, 91, 127-129`; `StressMonitor/StressMonitor/Theme/Color+Extensions.swift:44-47`; `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift:221-231`
**Issue:** `hrvTrendAccent`'s light variant was retuned `#34D399` → `#0F9D6E`. Recomputed against the white `adaptiveCardBackground`: **3.46:1** (not the ~4.10:1 implied by the fix's own framing) — this only clears the 3:1 UI-component bar appropriate for the 2.4pt trend line/area-fill/halo. But `hrvColor` (== `hrvTrendAccent`) is still the literal `.foregroundStyle` for two text elements in the same file: the 22pt semibold average numeral (line 91) and the 10pt monospaced "today · NNms" annotation (line 129). Both are text, and the 10pt annotation is unambiguously "normal text" requiring 4.5:1 — it still fails at 3.46:1. The newly added `hrvAccentOnCard` test (`ContrastComplianceTests.swift:225-230`) asserts only `ratio >= 3.0`, so it passes today's value and would keep passing even if the accent regressed further toward the pre-fix 1.92:1 as long as it stayed above 3.0 — the gate does not protect the text usages at all.
**Fix:** Either (a) route the numeral/annotation through `Color.Wellness.adaptivePrimaryText`/`adaptiveSecondaryText` instead of the accent color (matching how `StressBarChartView`'s header text is handled), or (b) retune `hrvTrendAccent`'s light variant further until white/text-on-card clears 4.5:1, and add a dedicated `hrvAccentTextOnCard` test asserting `>= 4.5`, separate from the 3:1 line/fill test.

## Warnings

### WR-08 (new): WR-01's disputed watch-side justification doesn't hold — `TierNamePreferences` has zero call sites

**File:** `StressMonitor/StressMonitorWatch Watch App/Models/StressCategory.swift:76` (watch `displayName` still "Moderate"); `StressMonitor/StressMonitorWatch Watch App/Models/TierNamePreferences.swift` (cited justification)
**Issue:** The fix pass's stated reason for leaving the watch's `StressCategory.moderate.displayName` at "Moderate" (rather than aligning to iOS's "Elevated") was that renaming it "would newly contradict `TierNamePreferences` defaults" (`moderate: String = "Moderate"`). Verified: `TierNamePreferences` — its `load()`, `save()`, and `displayName(for:)` — has **no call sites anywhere** in the watch target outside its own declaration file (confirmed via repo-wide grep). It is also keyed to a different, unrelated type (`WatchStressCategory`, an `Int`-raw-value enum in `StressMeasurement.swift`), not the `StressCategory` whose `displayName` was actually the subject of WR-01. Since `TierNamePreferences` is not wired into any live UI, it cannot "contradict" anything a user currently sees — the justification is based on dead scaffolding, not a live product constraint. The original WR-01 defect (a stress score of e.g. 60 is announced/labeled "Elevated" on iPhone and "Moderate" on Watch, for the same synced measurement) remains live.
**Fix:** Either wire `TierNamePreferences` into the watch UI (in which case the naming-consistency tradeoff becomes real and worth relitigating with the user), delete it if it's unused scaffolding, or — absent either — align the watch `displayName` to iOS's "Elevated" per the original WR-01 minimum-fix guidance, since the cited blocker doesn't currently exist.

### WR-09 (new): Two Settings/Trends views define local 4-tier category mappers that never resolve `.severe`, diverging from the canonical `StressResult.category(for:)`

**File:** `StressMonitor/StressMonitor/Views/Settings/Components/MeHeroCard.swift:118-127`; `StressMonitor/StressMonitor/Views/Trends/Components/StressBarChartView.swift:141-148`
**Issue:** Both files define a private/local score→tier mapper (`StressCategory.from(score:)` in `MeHeroCard`, `stressCategory(for:)` in `StressBarChartView`) with only 4 cases — `..<25/25..<50/50..<75/default→.high` — and never produce `.severe`. The canonical resolver used everywhere else (`StressResult.category(for:) `in `StressResult.swift:33-41`, mirrored by the just-fixed watch resolver in WR-02) treats `75..<90` as `.high` and `90+` as `.severe`. A measurement of 95 therefore renders "Severe" (red, `exclamationmark.octagon.fill`) on the Dashboard but "High" (orange, `square.fill`) in the Settings Me-hero-card metric row and the Trends daily bar chart — the same class of cross-surface tier-naming disagreement WR-02 fixed for iOS-vs-watch, but occurring iOS-internally between components. Not touched by this fix pass; flagged because it's the same defect family the phase set out to close and both files are in this re-review's scope.
**Fix:** Replace both local mappers with `StressResult.category(for:)` (or `StressCategory(from:)`, the existing convenience init in `StressCategory.swift:76-78`) so all three surfaces agree above 90.

### WR-10 (new): New contrast tests use the 3:1 "large-text" bar for pairs that include genuinely normal-size text

**File:** `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift:191-231`
**Issue:** `whiteOnModerateDistributionSegmentLight`/`Dark` (11pt semibold "NN%" label — the original CR-01 finding itself said "11pt semibold is not large text" and required 4.5:1) and `hrvAccentOnCard` (10pt monospaced annotation text, see CR-02 above) are both placed under the file's `// MARK: - UI / Large-Text Accent Pairs (>= 3:1)` section and asserted at `>= 3.0`. For the moderate-segment pair the actual values (5.93:1 light / 14.9:1 dark) are high enough that this doesn't currently mask a failure, but the gate itself no longer enforces the 4.5:1 bar the original finding established for that exact text, and for the HRV pair the loose threshold does mask a real failure (CR-02). The `whiteOnIAPCTAFill` test correctly uses 3:1 for genuinely bold/large CTA text — the moderate and HRV cases are text, not "large text."
**Fix:** Split these two tests to their own text-pair section asserting `>= 4.5`, matching the original findings' own stated requirement.

## Info

### IN-01 (new): `Color.hrvAccent` (`#34D399`, non-adaptive) is now dead code alongside the new `Color.hrvTrendAccent`

**File:** `StressMonitor/StressMonitor/Theme/Color+Extensions.swift:94`
**Issue:** `hrvAccent` has zero call sites anywhere in the app (confirmed via repo-wide grep) now that `HRVTrendChart` was switched to `Color.hrvTrendAccent`. The two similarly-named tokens (`hrvAccent` vs `hrvTrendAccent`) sitting side by side is a maintenance trap for the next person who reaches for "the HRV color" and picks the failing, unmaintained one.
**Fix:** Delete `hrvAccent`, or if some other consumer is planned, note it explicitly.

### IN-02 (new): `WatchDesignTokens.muted` passes AA by 0.041 — no margin for rounding/measurement drift

**File:** `StressMonitor/StressMonitorWatch Watch App/Theme/WatchDesignTokens.swift:36-38`
**Issue:** Recomputed contrast is 4.541:1 against a 4.5:1 requirement — a 0.9% margin. Different rounding in a stricter checker, a future canvas-color tweak, or `.opacity()` added at a new call site would silently drop this below AA with no test failure until the specific pair is re-measured (the `watchMutedTokenOnCanvas` test does pin this exact pair at `>= 4.5`, so a regression would be caught — but the value itself has essentially no headroom).
**Fix:** Consider retuning slightly darker (e.g. `#666A78` or similar) for headroom, or accept as-is since the pinning test exists.

---

_Reviewed: 2026-09-05T14:55:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
