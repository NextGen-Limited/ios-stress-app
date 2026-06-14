---
phase: 5
title: "Spacing & Layout: Fractional Values + Spacing Tokens"
status: pending
priority: P2
effort: "3h"
dependencies: [1, 2, 3]
---

# Phase 5: Spacing & Layout — Fractional Values + Spacing Tokens

## Overview

Fix 5 MAJOR and 22 MINOR spacing violations. Two tracks:
(A) Urgent: eliminate fractional spacing values (14.599, 10.6, 13.067, 9.333, 21.898) that cause sub-pixel blur on non-3× displays — these are Figma copy-paste artifacts.
(B) Routine: replace on-grid integer literals (8, 12, 16, 24, 32) with `Spacing.*` tokens to enforce consistency.

> ⚠️ **Red-team finding F14**: `Views/Breathing/BreathingExerciseView.swift` is edited by Phases 1, 2, 3, 5, and 6. Phase 5 must NOT run in parallel with 1/2/3 — second write stomps first. `dependencies: [1, 2, 3]` enforced in frontmatter. Can run in parallel with Phase 4 only (Phase 4 does not touch BreathingExerciseView for spacing).

## Requirements

- Functional: Zero fractional padding/spacing values in Views/
- Functional: All padding and VStack/HStack spacing uses `Spacing.*` tokens
- Non-functional: Visual layout must not shift more than 1pt from original intent when snapping fractionals

## Architecture

**Spacing token reference** (verify these exist in `DesignSystem/Spacing.swift`):
```
Spacing.xs  = 4
Spacing.sm  = 8
Spacing.md  = 16
Spacing.lg  = 24
Spacing.xl  = 32
Spacing.cardPadding = 20   (if defined)
Spacing.onboardingHorizontal = 28 (ADD if missing)
Spacing.badgePaddingH = 12  (ADD if missing)
Spacing.badgePaddingV = 6   (ADD if missing)
```

**Fractional → nearest on-grid snap table**:
| Fractional | Snap to | Token |
|------------|---------|-------|
| 14.599 | 16 | `Spacing.md` |
| 13.067 | 12 or 16 | `Spacing.sm` + 4, or `Spacing.md` (pick by context) |
| 10.6 | 8 | `Spacing.sm` |
| 21.898 | 24 | `Spacing.lg` — horizontal padding |
| 10.949 | 8 | `Spacing.sm` — vertical padding |
| 9.333 | 8 | `Spacing.sm` |

## Related Code Files

### Modify — fractional values (MAJOR — 4 files)
- `Views/Dashboard/Components/HealthStatCard.swift:14,61,62,77,78,98` — `14.599`, `10.6`, `21.898`, `10.949`
- `Views/Dashboard/Components/WatchMetricCard.swift:20,83,84` — `14.599`, `21.898`, `14.599`
- `Views/Dashboard/Components/WeekCalendarStrip.swift:23,74` — `13.067`, `9.333`
- `Views/Dashboard/Components/DashboardView.swift:34,40` — `spacing: 22` (off-grid, not fractional but needs token)

> ⚠️ **Red-team finding F8**: `ChatBottomSheetView.swift` has NO fractional values — only integer literals. Moved to MINOR on-grid sweep below.

### Modify — on-grid literals without tokens (MINOR — 16 files, includes ChatBottomSheetView)

**Off-grid snap table for integer edge cases** (no token exists for 5, 7, 10, 14, 18):
| Value | Snap to | Token |
|-------|---------|-------|
| 5 | 4 | `Spacing.xs` |
| 7 | 8 | `Spacing.sm` |
| 10 | 8 | `Spacing.sm` |
| 14 | 16 | `Spacing.md` (note: 2pt larger; verify visually) |
| 18 | 16 | `Spacing.md` (note: 2pt smaller; verify visually) |
| 22 | 24 | `Spacing.lg` |
| 23 | 24 | `Spacing.lg` |

- `Views/Chat/ChatBottomSheetView.swift` — 20 integer literals (moved from MAJOR; no fractional values)
- `Views/MainTabView.swift:103` — `.padding(.horizontal, 16)` → `Spacing.md`
- `Views/Settings/SettingsView.swift:65` — `.padding(.horizontal, 16)` → `Spacing.md`
- `Views/Settings/Components/NotificationsCard.swift:47–48,128–129` — 5, 7, 10, 12 literals
- `Views/Settings/Components/SettingsCharacterStatusHeader.swift:46,49` — 8, 18 → `Spacing.sm`, `Spacing.md`
- `Views/Settings/Components/WatchFaceCard.swift:16` — `spacing: 23` → `Spacing.lg` (24)
- `Views/Settings/Components/WidgetCard.swift:16` — `spacing: 23` → `Spacing.lg`
- `Views/Breathing/BreathingExerciseView.swift:132,158` — `.padding(.horizontal, 17)` → `Spacing.md`
- `Views/Premium/Components/IAPHeroSection.swift:39,47,71` — 40, 11 → `Spacing.xl`, `Spacing.sm`
- `Views/Onboarding/OnboardingWelcomeView.swift:77` — `.padding(.horizontal, 28)` → `Spacing.onboardingHorizontal`
- `Views/Onboarding/OnboardingHealthSyncView.swift:131` — `.padding(.horizontal, 28)` → `Spacing.onboardingHorizontal`
- `Views/DesignSystem/Components/Badge.swift:20–21` — 12, 6 → `Spacing.badgePaddingH`, `Spacing.badgePaddingV`
- `Views/History/MeasurementDetailView.swift:31,77–78,102,168,186,204` — 20, 16, 8 literals
- `Views/Action/ActionView.swift:120,121,166,281,359` — 10, 5, 18, 14 literals

### Modify — token additions
- `Views/DesignSystem/Spacing.swift` — add `onboardingHorizontal`, `badgePaddingH`, `badgePaddingV` if missing

## Implementation Steps

### Part A — Token additions (Spacing.swift)
1. Read `Views/DesignSystem/Spacing.swift`; verify existing token set
2. Add any missing tokens: `onboardingHorizontal = 28`, `badgePaddingH = 12`, `badgePaddingV = 6`

### Part B — Fractional values (4 files, highest priority)
3. Fix `HealthStatCard.swift` — replace all 4 fractional values with snapped tokens
4. Fix `WatchMetricCard.swift` — replace 3 fractional values
5. Fix `WeekCalendarStrip.swift` — replace 2 fractional values
6. Fix `DashboardView.swift` — `spacing: 22` → `Spacing.lg` (24pt)
7. Build — verify no sub-pixel blur regressions visually on non-3× simulator (iPhone SE 2nd gen)

### Part C — On-grid literal sweep (15 files)
9. Process each file in the MINOR list above, replacing integer literals with `Spacing.*` tokens
10. For `Badge.swift`: use new `badgePaddingH`/`badgePaddingV` tokens (propagates to all Badge usages automatically)
11. Build after each 4–5 files

### Verify
12. `grep -rn "[0-9]\+\.[0-9][0-9][0-9]" Views/ --include="*.swift" | grep "padding\|spacing\|VStack\|HStack"` → 0 results
13. `grep -rn "Spacing\." Views/ --include="*.swift" | wc -l` → should be significantly higher than before

## Success Criteria

- [ ] Zero fractional padding/spacing values in Views/
- [ ] `ChatBottomSheetView` — all 20 hardcoded values replaced with Spacing tokens
- [ ] `ActionView` — 13 literals replaced
- [ ] `Badge.swift` — padding uses named tokens (propagates everywhere)
- [ ] `Spacing.onboardingHorizontal` token added; used in both onboarding screens
- [ ] Build succeeds; visual layout preserved within 1pt

## Risk Assessment

- **Fractional snap**: Low — most snaps are 1–2pt differences; not visually noticeable
- **ChatBottomSheetView 20 literals**: Medium — many at unusual values (10, 14); snap may require visual verification
- **Badge padding change**: Low — uniform change propagates correctly; verify in dark mode
