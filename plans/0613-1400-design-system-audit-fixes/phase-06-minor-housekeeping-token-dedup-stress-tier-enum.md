---
phase: 6
title: "Minor Housekeeping: Token Dedup + Stress Tier Enum"
status: pending
priority: P3
effort: "2h"
dependencies: [1, 2, 3, 4, 5]
---

# Phase 6: Minor Housekeeping — Token Dedup + Stress Tier Enum

## Overview

Final cleanup pass covering 21 MINOR issues. All phases must complete first — this phase removes redundancies, promotes local constants to global tokens, and aligns the stress tier naming/colors with the spec.

## Requirements

- Functional: `StressTier` enum in `RippleTrendsKit.swift` uses spec names and spec colors
- Functional: Duplicate tokens merged (no two tokens with same value)
- Functional: `darkCanvas` (#0A0A0F) promoted to `Color.Wellness.darkCanvas`
- Non-functional: `StressOverTimeChart` 3-tier legend updated to 5-tier spec
- Non-functional: Non-adaptive `.black.opacity(N)` shadows → `Color.primary.opacity(N)`
- Non-functional: Raw `colorScheme == .dark` branches → adaptive tokens or ViewModifiers

## Architecture

**StressTier enum rename** (multi-target — red-team finding F4):

> ⚠️ **Red-team finding F4**: watchOS target has an INDEPENDENT `StressTier` enum in `StressMonitorWatch Watch App/Theme/StressCharacter.swift` with different case names (`resting, calm, balanced, tense, overwhelmed`). Both enums must be handled. Confirm whether they should be renamed independently or kept separate.

**iOS `StressTier`** (`Views/Trends/Components/RippleTrendsKit.swift`):
```swift
// Before
enum StressTier {
    case calm, good, balanced, stressed, overwhelmed
    var label: String { ["Calm","Good","Balanced","Stressed","Overwhelmed"][...] }
    var color: Color { [#4FC3F7, #A5D6A7, #7986CB, #FF8A65, #E53935][...] }
}

// After
enum StressTier {
    case veryCalm, calm, neutral, stressed, critical
    var label: String { ["Very Calm","Calm","Neutral","Stressed","Critical"][...] }
    var color: Color { [#4CAF50, #81C784, #FFB74D, #FF8A65, #E53935][...] }
}
```

**Token deduplication** in `Theme/Color+Wellness.swift` and `Theme/Color+Extensions.swift`:

> ⚠️ **Red-team finding F15**: "Aliasing" requires deleting the `static let` and replacing with `static var { canonical }`. Simply adding an alias alongside the existing `let` causes a duplicate symbol compile error.

| Keep | Remove → Replace with computed alias |
|------|--------------------------------------|
| `textTertiary` (#808080) | Delete `static let iapTextMuted = Color(hex: "808080")`; add `static var iapTextMuted: Color { textTertiary }` |
| `settingsAmberInfo` (#FFF4D6) | Delete `static let bannerYellow = ...`; add `static var bannerYellow: Color { settingsAmberInfo }` |
| `settingsAmberInfoText` (#3A2A05) | Delete `static let bannerYellowText = ...`; add `static var bannerYellowText: Color { settingsAmberInfoText }` |

**darkCanvas promotion**:
- Remove `private static let darkCanvas = Color(hex: "#0A0A0F")` from `RippleTrendsKit.swift`
- Add `static let darkCanvas = Color(hex: "#0A0A0F")` to `Color.Wellness` in `Theme/Color+Wellness.swift`
- Update `RippleTrendsKit.swift` reference to `Color.Wellness.darkCanvas`

**`rippleBlue` canonical token** — add to `Color.Wellness`:
```swift
static let rippleBlue = Color(hex: "4FC3F7")
```
Currently scattered as `settingsRippleBlue` (Settings extension) and `accentTeal` (other extension) with no single `Color.Wellness` canonical entry.

**`tealCard` value update** (prerequisite to Phase 1 teal migration being correct):
```swift
// Theme/Color+Wellness.swift
// Before: static let tealCard = Color(hex: "#85C9C9")
// After:  static let tealCard = Color(hex: "#4FC3F7")
```
> ✅ **Validated decision**: Old teal (#85C9C9) is fully replaced by Ripple blue (#4FC3F7) throughout. `tealCard` value updated here so any remaining legacy call sites using `tealCard` automatically get the new color.

## Related Code Files

### Modify — iOS files
- `Views/Trends/Components/RippleTrendsKit.swift` — iOS StressTier enum rename + color fix + darkCanvas → `Color.Wellness.darkCanvas`
- `Views/Settings/Components/SettingsCharacterStatusHeader.swift` — exhaustive switch over old case names (lines 64–72)
- `Views/Settings/Components/ComplicationWidget.swift` — `.good`, `.balanced` case literals (lines 40, 79, 80)
- `Views/Settings/Components/WatchFaceCard.swift` — `.good`, `.balanced` case literals (lines 17–18)
- `Views/Settings/Components/WidgetCard.swift` — `.calm`, `.good` case literals (lines 17–18)
- `Views/Trends/Components/MascotSpeechBubbleView.swift` — default `tier: StressTier = .good` (line 10)
- `Views/Action/ActionView.swift` — switch on old tier cases (verify it's `StressTier`, not `MoodLevel`)
- `Views/Trends/TrendsView.swift` — type-inferred `.good` return (line ~119, no `StressTier.` prefix)

### Modify — watchOS target (✅ validated: rename in sync with iOS)
- `StressMonitorWatch Watch App/Theme/StressCharacter.swift` — rename watchOS `StressTier` cases to match iOS: `veryCalm, calm, neutral, stressed, critical`
- Run `grep -rn "StressTier\|\.resting\|\.tense\|\.balanced" "StressMonitorWatch Watch App/" --include="*.swift"` to find all watch callers before renaming
- `StressMonitorWatch Watch App/Complications/ComplicationBundle.swift` — update StressTier references
- `StressMonitorWatch Watch App/Views/WatchHomeView.swift` — update StressTier references (if used)
- Any other watch files surfaced by the pre-step grep
- `Views/Dashboard/Components/StressOverTimeChart.swift:153` — update 3-tier legend to 5-tier spec labels and colors
- `Theme/Color+Wellness.swift` — add `darkCanvas`, `rippleBlue` tokens; deduplicate
- `Theme/Color+Extensions.swift` — alias `iapTextMuted` → `textTertiary`; alias `bannerYellow` → `settingsAmberInfo`
- `Views/Breathing/BreathingExerciseView.swift:104,105` — `.black.opacity(0.1)` shadows → `Color.primary.opacity(0.1)`
- `Views/Dashboard/Components/CompactStressHeaderBar.swift` — `.black.opacity` shadow → `Color.primary.opacity`
- `Views/Components/PrimaryMetricCard.swift` — `.black.opacity` shadow → `Color.primary.opacity`
- `Views/Dashboard/Components/StressGaugeView.swift` — `.black.opacity` shadow → `Color.primary.opacity`
- `Views/Characters/CharacterGridCard.swift` — `.black.opacity` shadow → `Color.primary.opacity`
- `Views/MiniWalk/Components/MiniWalkInstructionCard.swift` ×2 — `.black.opacity` shadows → `Color.primary.opacity`
- `Views/MiniWalk/Components/MiniWalkTimerRing.swift` — `.black.opacity` shadow → `Color.primary.opacity`
- `Views/DesignSystem/Components/SettingsCard.swift:25` — raw `colorScheme == .dark` branch → adaptive Color token
- `Views/Breathing/BreathingSessionView.swift:97` — raw `colorScheme == .dark` branch → adaptive ViewModifier

### Modify — doc comment fix
- `Views/Trends/Components/RippleTrendsKit.swift:10` — doc comment tier 0–20: "Calm" → "Very Calm"

## Implementation Steps

0. **Pre-step: blast radius check** — `grep -rn "\.calm\|\.good\|\.balanced\|\.overwhelmed\|StressTier" StressMonitor/ --include="*.swift"` across ALL targets; add any unlisted files to the Modify list above
1. **StressTier enum + RippleTrendsKit** — rename enum cases, update all switch/match sites within the file, fix tier colors to spec, remove local `darkCanvas` constant, update doc comment
2. **Promote `darkCanvas` + `rippleBlue`** — add both tokens to `Color.Wellness`; update `RippleTrendsKit` to use canonical references
3. **Token deduplication** — for each duplicate: (a) delete the `static let`, (b) add `static var { canonical }` alias; do NOT add alias alongside existing `let`; grep usages of removed names before removing to verify no compile breaks
4. **StressOverTimeChart** — update 3-tier legend → 5-tier; replace `HomeCharacterDesignTokens.Blossom.accent` with spec tier colors
5. **Non-adaptive shadows** — bulk replace `.black.opacity(N)` with `Color.primary.opacity(N)` in 9 files
6. **Raw colorScheme branches** — refactor `SettingsCard.swift:25` into `Color.adaptiveShadow` token; refactor `BreathingSessionView.swift:97` into a ViewModifier
7. Build and run full test suite
8. Screenshot verification: Dashboard, Breathing, Trends, Characters in both light and dark mode

## Success Criteria

- [ ] `StressTier` cases: `veryCalm, calm, neutral, stressed, critical`
- [ ] `TrendsPalette` tier colors match spec: #4CAF50 / #81C784 / #FFB74D / #FF8A65 / #E53935
- [ ] `Color.Wellness.darkCanvas` and `Color.Wellness.rippleBlue` exist
- [ ] `iapTextMuted`, `bannerYellow`, `bannerYellowText` aliased (no raw #808080 or #FFF4D6 duplicates)
- [ ] Zero `.black.opacity` in shadow calls across Views/
- [ ] Zero raw `colorScheme == .dark` branches in Views/ card/shadow code
- [ ] All existing tests pass
- [ ] Visual spot-check: Trends screen shows correct 5-tier color legend

## Risk Assessment

- **StressTier rename blast radius**: High — 8+ iOS files + watchOS target; pre-step grep is mandatory; type-inferred case usage (`.good` without `StressTier.`) won't appear in name-based grep
- **watchOS StressTier**: Resolved — rename in sync with iOS (validated decision); pre-step grep required to find all callers
- **Token aliasing**: Low — `static var` alias is safe IF the original `static let` is deleted first; failure to delete = compile error
- **colorScheme refactor**: Low — purely cosmetic code path; verify visually in both modes
