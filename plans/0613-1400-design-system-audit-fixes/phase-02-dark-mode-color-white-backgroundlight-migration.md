---
phase: 2
title: "Dark Mode: Color.white & backgroundLight Migration"
status: pending
priority: P1
effort: "3h"
dependencies: []
---

# Phase 2: Dark Mode — Color.white & backgroundLight Migration

## Overview

Fix 23 MAJOR dark mode breaks. Replace all non-adaptive `Color.white` and `Color.backgroundLight` backgrounds across Dashboard, Breathing, History, Trends, Premium, and DesignSystem. The Premium IAP paywall (full-screen `Color.white.ignoresSafeArea()`) is the highest priority — it's the purchase conversion path.

## Requirements

- Functional: Every screen background and card background must adapt correctly in dark mode
- Functional: IAP paywall must not be pure white in dark mode
- Non-functional: No `Color.white` as a main/card background anywhere in Views/ (only acceptable: overlays/borders at very low opacity)

## Architecture

**Token mapping** (audit-verified):

| Old (broken) | New (adaptive) |
|---|---|
| `Color.white` (card bg) | `Color.Wellness.adaptiveCardBackground` |
| `Color.white.ignoresSafeArea()` (screen bg) | `Color.Wellness.adaptiveBackground.ignoresSafeArea()` |
| `Color.backgroundLight` (screen bg) | `Color.Wellness.adaptiveBackground` ⚠️ NOT `.background` (dark=#000000 OLED black) |
| `Color(.systemBackground)` (bypasses tokens) | `Color.Wellness.adaptiveCardBackground` |

> ⚠️ **Red-team finding F10**: `Color.Wellness.background` resolves to `#000000` in dark mode (OLED black). Use `Color.Wellness.adaptiveBackground` (dark=`#121212`) for screen-level backgrounds to preserve visual depth.

**Acceptable `Color.white` usages** (do NOT replace):
- `.foregroundStyle(Color.white)` — text on colored backgrounds
- `Color.white.opacity(0.04)` — glass overlay tint (ActionView)
- `Color.white.opacity(0.1)` or lower — subtle borders/tints

## Related Code Files

### Modify
- `Views/DesignSystem/Components/LoadingView.swift:18` — `Color.backgroundLight` → `Color.Wellness.adaptiveBackground`
- `Views/Breathing/BreathingExerciseView.swift:44` — `Color.white` → `Color.Wellness.adaptiveBackground`
- `Views/Breathing/BreathingSummaryView.swift:63` — `Color.backgroundLight` → `Color.Wellness.adaptiveBackground`
- `Views/Dashboard/Components/SemicircularGaugeView.swift:158,166` — `Color.backgroundLight` ×2 → `Color.Wellness.adaptiveBackground`
- `Views/Dashboard/Components/DailyTimelineView.swift:129,145` — `Color.backgroundLight` ×2 → `Color.Wellness.adaptiveBackground`
- `Views/Dashboard/Components/AIChatCard.swift:83` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/SmartInsightsCard.swift:43` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/WatchMetricCard.swift:86` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/HealthDataSection.swift:90` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/HRVTrendCard.swift:62` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/HealthStatCard.swift:63` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/WidgetPromoCard.swift:35` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Dashboard/Components/IntroMessageCard.swift:26,34` — `Color.white` ×2 → `Color.Wellness.adaptiveCardBackground`
- `Views/History/MeasurementHistoryView.swift:29,98` — `Color.backgroundLight` ×2 → `Color.Wellness.adaptiveBackground`
- `Views/History/MeasurementDetailView.swift:33` — `Color.backgroundLight` → `Color.Wellness.adaptiveBackground`
- ~~`Views/Trends/Components/PremiumBannerView.swift:59`~~ — **REMOVED from Phase 2 scope**: Phase 4 deletes this file entirely. The unified PremiumBanner component created in Phase 4 must use `Color.Wellness.adaptiveBackground` (enforced in Phase 4 Part D step 14).
- `Views/Premium/Components/IAPHeroSection.swift:96` — `Color.white.ignoresSafeArea()` → `Color.Wellness.adaptiveBackground.ignoresSafeArea()`
- `Views/Premium/Components/IAPNavBar.swift:58` — `Color.white.ignoresSafeArea()` → `Color.Wellness.adaptiveBackground.ignoresSafeArea()`
- `Views/Premium/Components/IAPCTAButton.swift:53` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Premium/Components/IAPUtilityRow.swift:80` — `Color.white` → `Color.Wellness.adaptiveCardBackground`
- `Views/Components/PrimaryMetricCard.swift:51` — `Color(.systemBackground)` → `Color.Wellness.adaptiveCardBackground`

## Implementation Steps

1. Verify token availability — `grep -rn "adaptiveCardBackground\|adaptiveBackground\b\|Wellness.background\b\|Wellness.surface" StressMonitor/Theme/ --include="*.swift"` — confirm all tokens exist before bulk replacing
2. If `Color.Wellness.surface` is missing, use `Color.Wellness.adaptiveBackground` as the screen-level fallback
3. **IAP paywall first** — fix `IAPHeroSection.swift` and `IAPNavBar.swift` (highest impact, purchase path)
4. Fix remaining Dashboard card backgrounds (8 files — all share same `Color.white` pattern, batch-editable)
5. Fix Breathing screens (`BreathingExerciseView`, `BreathingSummaryView`)
6. Fix History screens (`MeasurementHistoryView`, `MeasurementDetailView`)
7. ~~Fix Trends premium banner~~ — skipped; `PremiumBannerView.swift` is deleted in Phase 4; adaptive background enforced there
8. Fix IAP remaining (`IAPCTAButton`, `IAPUtilityRow`)
9. Fix `LoadingView`, `SemicircularGaugeView`, `DailyTimelineView`, `PrimaryMetricCard`
10. Spot-check: build in dark mode simulator and screenshot Dashboard, Breathing, and Premium

## Success Criteria

- [ ] Zero `Color.white` main/card backgrounds in Dashboard, Breathing, History, Trends, Premium
- [ ] Zero `Color.backgroundLight` usages across Views/
- [ ] Zero `Color(.systemBackground)` usages in Views/ (replaced by token)
- [ ] IAP paywall renders correctly in both light and dark mode
- [ ] Build succeeds; no regressions

## Risk Assessment

- **IAPHeroSection/IAPNavBar**: Low — single-line token swap; test visually in dark mode
- **Dashboard card backgrounds**: Low — batch swap; color token must exist first (Step 1)
- **Token availability**: Medium — if `adaptiveCardBackground` is not yet in Color+Wellness.swift, must add it first
