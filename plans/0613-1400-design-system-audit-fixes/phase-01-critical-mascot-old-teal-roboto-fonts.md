---
phase: 1
title: "Critical: Mascot + Old Teal + Roboto Fonts"
status: pending
priority: P1
effort: "4h"
dependencies: []
---

# Phase 1: Critical — Mascot + Old Teal + Roboto Fonts

## Overview

Fix all 28 CRITICAL issues. Three independent tracks that can be worked in parallel:
(A) Replace cat mascot assets with Ripple Water Otter in 5 files.
(B) Eliminate old teal #85C9C9 in Breathing/Dashboard/Settings.
(C) Replace 48 raw `Font.custom("Roboto-*")` calls with `Typography.*` tokens; add missing token variants.

## Requirements

- Functional: App must visually reference "Ripple" Water Otter everywhere, zero cat images
- Functional: No `#85C9C9` raw hex anywhere in Views/
- Functional: All Roboto font calls must go through `Typography.*` tokens; zero fractional sizes
- Non-functional: Build must succeed; existing tests must not regress

## Architecture

**Typography token additions needed** (add to `DesignSystem/Typography.swift`):

> ⚠️ **Red-team verified — read existing tokens first** before adding. Existing token actual values:
> `robotoTitle=Bold/24` ✓, `robotoHeadline=Bold/17` (not 18), `robotoBody=Bold/16` (not Regular/14), `robotoCaption=Bold/12` ✓

```swift
// NEW tokens — verified NOT to exist yet (distinct names from existing Bold variants)
static let robotoMedium        = Font.custom("Roboto-Medium", size: 14)
// Roboto-MediumItalic.ttf must be added to bundle BEFORE defining this token (see Track C step 16)
static let robotoMediumItalic  = Font.custom("Roboto-MediumItalic", size: 16)
static let robotoItalic        = Font.custom("Roboto-Italic", size: 14)
static let robotoExtraBold     = Font.custom("Roboto-ExtraBold", size: 14)
static let robotoLight         = Font.custom("Roboto-Light", size: 10)
// Regular-weight variants — use DISTINCT names to avoid collision with existing Bold tokens
static let robotoBodyRegular   = Font.custom("Roboto-Regular", size: 14)
static let robotoBodySmall     = Font.custom("Roboto-Regular", size: 13)
static let robotoCaption2      = Font.custom("Roboto-Regular", size: 10)
// Timer token — 42pt (NOT dataLarge which already exists at 48pt)
static let timerLarge          = Font.system(size: 42, weight: .bold, design: .rounded)
// ^ for MiniWalkTimerRing only — do NOT use dataLarge (48pt, different size)
```

**Token reuse map** — when replacing raw calls, check weight first:
| Raw call | Map to |
|---|---|
| `Roboto-Bold, 24` | `Typography.robotoTitle` (existing Bold/24) |
| `Roboto-Bold, 17–18` | `Typography.robotoHeadline` (existing Bold/17) |
| `Roboto-Bold, 16` | `Typography.robotoBody` (existing Bold/16) |
| `Roboto-Regular, 14` | `Typography.robotoBodyRegular` (new) |
| `Roboto-Regular, 13` | `Typography.robotoBodySmall` (new) |
| `Roboto-Bold, 12` | `Typography.robotoCaption` (existing Bold/12) |
| `Roboto-Regular, 12` | `Typography.robotoCaption` (same size; note weight differs) |
| `Roboto-Regular, 10` | `Typography.robotoCaption2` (new) |
| `Roboto-Medium, 14` | `Typography.robotoMedium` (new) |
| `Roboto-MediumItalic, 18` | `Typography.robotoMediumItalic` (new, see bundle caveat above) |
| `Roboto-Italic, 14` | `Typography.robotoItalic` (new) |
| `Roboto-ExtraBold, 14` | `Typography.robotoExtraBold` (new) |
| `Roboto-Light, 10` | `Typography.robotoLight` (new) |
| `Roboto-Bold, 42` (MiniWalk) | `Typography.timerLarge` (new, NOT dataLarge) |

**Mascot replacement map** (6 files — includes ChatBottomSheetView per red-team finding):
| File | Old | New |
|------|-----|-----|
| `AIChatCard.swift` | `Image("AIKitten")` | `StressBuddyIllustration` or `RippleMoodFace` |
| `AIChatCard.swift` | `"Chat with StressCat"` | `"Chat with Ripple"` |
| `SmartInsightsCard.swift` | `Image(systemName: "cat.fill")` | `RippleMoodFace(...)` |
| `IntroMessageCard.swift` | `Image(systemName: "cat.fill")` | `RippleMoodFace(...)` |
| `PremiumBannerView.swift` (Trends) | `Image("CharacterCalm")` | `StressBuddyIllustration(...)` |
| `PremiumBanner.swift` (Dashboard) | cat placeholder comment | Actual `StressBuddyIllustration` view |
| `ChatBottomSheetView.swift` | `Image("AIKitten")` ×3 (lines 130, 154, 294) | `StressBuddyIllustration` or `RippleMoodFace` |

## Related Code Files

### Modify
- `Views/DesignSystem/Typography.swift` — add missing Roboto token variants
- `Views/Dashboard/Components/AIChatCard.swift` — cat → Ripple, CTA text
- `Views/Dashboard/Components/SmartInsightsCard.swift` — cat.fill → RippleMoodFace
- `Views/Dashboard/Components/IntroMessageCard.swift` — cat.fill → RippleMoodFace
- `Views/Dashboard/Components/QuoteCard.swift` — Roboto-Italic, Roboto-ExtraBold
- `Views/Dashboard/Components/PremiumBanner.swift` — cat placeholder → Ripple asset
- `Views/Trends/Components/PremiumBannerView.swift` — CharacterCalm → StressBuddyIllustration (NOTE: Phase 4 deletes this file via consolidation — fix mascot here, but Phase 4 must re-apply adaptive background fix in unified component)
- `Views/Chat/ChatBottomSheetView.swift` — `Image("AIKitten")` ×3 at lines 130, 154, 294 → Ripple character view
- `Views/Dashboard/Components/RecommendationsCard.swift` — fractional Roboto → tokens
- `Views/Dashboard/Components/WatchMetricCard.swift` — raw Roboto → tokens
- `Views/Dashboard/Components/HealthStatCard.swift` — raw Roboto incl. fractional 23.723
- `Views/Dashboard/Components/HRVTrendCard.swift` — raw Roboto → tokens
- `Views/Dashboard/Components/WeekCalendarStrip.swift` — raw Roboto incl. fractional 12.13
- `Views/Dashboard/Components/StressSourcesCard.swift` — raw Roboto incl. fractionals
- `Views/Dashboard/Components/WidgetPromoCard.swift` — raw Roboto → tokens
- `Views/Dashboard/Components/SelfNoteCard.swift` — raw Roboto + old teal #85C9C9
- `Views/Dashboard/Components/SmartInsightsCard.swift` — raw Roboto
- `Views/Dashboard/Components/AIChatCard.swift` — raw Roboto
- `Views/Breathing/BreathingExerciseView.swift` — private tealLight/tealDark tokens, Color(red:) values
- `Views/Breathing/BreathingSessionView.swift` — Color(red:) gradient stops
- `Views/Settings/Components/NotificationsCard.swift` — #85C9C9 in gradient
- `Views/MiniWalk/Components/MiniWalkInstructionCard.swift` — Roboto-MediumItalic
- `Views/MiniWalk/Components/MiniWalkTimerRing.swift` — Roboto-Bold 42pt → `Typography.timerLarge` (NOT `dataLarge` which is 48pt)

## Implementation Steps

### Track A — Mascot (6 files — updated by red-team)

1. Read `Views/Dashboard/Components/AIChatCard.swift`; find `Image("AIKitten")` and `"StressCat"` references
2. Check if `RippleMoodFace` and `StressBuddyIllustration` components exist — `grep -r "RippleMoodFace\|StressBuddyIllustration" Views/ --include="*.swift" -l`
3. Replace `Image("AIKitten")` with the available Ripple character view; update CTA string
4. Repeat for `SmartInsightsCard.swift` and `IntroMessageCard.swift` (`cat.fill`)
5. Fix `Views/Trends/Components/PremiumBannerView.swift` — replace `Image("CharacterCalm")` (mascot only; do NOT fix color here as Phase 4 will delete this file)
6. Fix `Views/Dashboard/Components/PremiumBanner.swift` — replace placeholder comment with actual Ripple asset
7. Fix `Views/Chat/ChatBottomSheetView.swift` lines 130, 154, 294 — three `Image("AIKitten")` → Ripple character view

### Track B — Old Teal (4 files)

> ✅ **Validated decision**: Replace all old teal with Ripple blue **#4FC3F7** (`Color.settingsRippleBlue`). `Color.Wellness.tealCard` value will also be updated to `#4FC3F7` in Phase 6 (Step 2 of that phase). Do NOT use `tealCard` as the replacement target here — its value is still #85C9C9 until Phase 6 runs.

8. Open `Views/Breathing/BreathingExerciseView.swift`; delete private `tealLight`/`tealDark` static let lines (lines ~301–302)
9. Replace all usages of `tealLight`/`tealDark` within the same file with `Color.settingsRippleBlue` (#4FC3F7) — do NOT use `tealCard` (same hex as old teal)
10. Fix `BoxBreathingStep` `dotColor` raw `Color(red:)` values at line ~288 — map to nearest wellness tokens
11. Fix `Color(red: 0.45, 0.45, 0.45)` → `Color.Wellness.adaptiveSecondaryText` (line ~110)
12. Fix `Color(red: 0.26, 0.26, 0.26)` → `Color.Wellness.adaptivePrimaryText` (line ~140)
13. Open `Views/Breathing/BreathingSessionView.swift`; fix gradient stop `Color(red: 0.1, 0.1, 0.15)` → `Color.Wellness.backgroundDark` (line ~99)
14. Open `Views/Settings/Components/NotificationsCard.swift`; replace `Color(hex: "85C9C9")` with `Color.settingsRippleBlue` (line ~167)
15. Open `Views/Dashboard/Components/SelfNoteCard.swift`; replace `Color(hex: "85C9C9")` with `Color.settingsRippleBlue` (line ~16) — do NOT use `tealCard`

### Track C — Roboto tokens (15 files)

16. Open `Views/DesignSystem/Typography.swift`; read all existing Roboto tokens and note their actual values
17. Add ONLY new tokens using distinct names per the Token reuse map above (do NOT overwrite existing Bold tokens)
18. **Add `Roboto-MediumItalic.ttf` to bundle** — download font file, add to Xcode `Fonts/` group, register in `Info.plist` under `UIAppFonts`. Verify by running app and checking font renders correctly before defining the token.
19. Add `Typography.timerLarge` at 42pt (NOT `dataLarge` which exists at 48pt)
20. Replace raw `.custom("Roboto-*")` calls file by file using the mapping table above
21. Fix all fractional sizes: 23.723 → 24, 14.599 → 14, 13.97 → 14, 12.13 → 12, 11.99 → 12, 7.5 → 8 (nearest on-grid)
22. Build and resolve any "unknown token" compile errors

### Verify

23. `grep -r "AIKitten\|CharacterCalm\|cat.fill\|StressCat" Views/ --include="*.swift"` → must return 0 results
24. `grep -r "85C9C9\|73B9B9\|tealLight\|tealDark" Views/ --include="*.swift"` → must return 0 results
25. `grep -r '\.custom("Roboto' Views/ --include="*.swift" | wc -l` → must return 0 (note: no `Font.` prefix in grep — catches both syntaxes)
26. `grep -r "[0-9]*\.[0-9][0-9][0-9]" Views/ --include="*.swift" | grep "font\|Font\|size:"` → check for remaining fractionals

## Success Criteria

- [ ] Zero `cat.fill`, `AIKitten`, `CharacterCalm` references in Views/
- [ ] Zero `#85C9C9` / `tealLight` / `tealDark` references in Views/
- [ ] Zero raw `Font.custom("Roboto-*")` call sites in Views/ — all through Typography tokens
- [ ] Zero fractional font sizes (.723, .599, .13, etc.) anywhere in Views/
- [ ] App builds successfully
- [ ] Existing tests pass

## Risk Assessment

- **Mascot**: Medium — `StressBuddyIllustration` / `RippleMoodFace` must exist; if not, need to create placeholder or use SF Symbol otter
- **Teal migration**: Low — simple find/replace; verify tealCard token value is correct before committing
- **Roboto tokens**: Medium — existing Bold tokens (`robotoBody`, `robotoHeadline`) have different weights/sizes than plan assumed; use distinct names for new Regular variants
- **Roboto-MediumItalic**: Resolved — add `Roboto-MediumItalic.ttf` to bundle (validated decision); exact match required
- **dataLarge collision**: Resolved — `timerLarge` at 42pt is the new token; `dataLarge` at 48pt must not be touched
- **Fractional sizes**: Low — snapping to integer grid; verify visually after build
