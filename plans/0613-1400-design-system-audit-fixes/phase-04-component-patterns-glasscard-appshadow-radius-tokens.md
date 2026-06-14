---
phase: 4
title: "Component Patterns: GlassCard + AppShadow + Radius Tokens"
status: pending
priority: P2
effort: "5h"
dependencies: [2]
---

# Phase 4: Component Patterns — GlassCard + AppShadow + Radius Tokens

## Overview

Fix 8 MAJOR and 4 MINOR component pattern violations:
- Consolidate 32 manual `RoundedRectangle` card constructions → `GlassCard`
- Route 51 inline `.shadow()` calls → `AppShadow` token helpers; add `accentGlow` and `breathingGlow` tokens
- Fix hardcoded `cornerRadius(33)` in BreathingExerciseView
- Fix 3 `.borderedProminent` button style bypasses → `PrimaryButton`
- Consolidate duplicate `PremiumBanner` + `PremiumBannerView` into one shared component
- Fix `PrivacyCard` → `SettingsCard` wrapper

Phase 2 must complete first (card backgrounds need adaptive tokens before GlassCard migration makes visual sense).

## Requirements

- Functional: Character/detail panel card surfaces use `GlassCard`; dashboard data cards use `SettingsCard` or plain `RoundedRectangle + adaptiveCardBackground` (see Architecture note)
- Functional: All drop shadows go through `AppShadow` modifiers — no inline `.shadow(color:radius:)` construction
- Functional: `cornerRadius(33)` eliminated; breathing card uses `Spacing.settingsCardRadius` (20pt); widget/settings cards use `DesignTokens.Layout.cornerRadius` (12pt) — verified values
- Functional: Button styles only from design system (`PrimaryButton`, `ScaleButtonStyle`)

## Architecture

**GlassCard migration scope** (red-team corrected):

> ⚠️ **Red-team finding F9**: `GlassCard` uses `Color.secondary.opacity(0.1)` (translucent glass), NOT `adaptiveCardBackground` (solid). Migrating dashboard data cards to `GlassCard` changes their visual appearance from solid to glass — a design decision, not a token fix.

**GlassCard — correct use cases (transparent glass effect):**
- `CharacterDetailView` (existing, correct)
- Any dark-canvas overlay panel (e.g., Trends glass cards via `trendsGlassCard()` modifier)

**Dashboard data cards — DO NOT migrate to GlassCard:**
- `HealthStatCard`, `WatchMetricCard`, `AIChatCard`, `HRVTrendCard`, etc. remain as `RoundedRectangle + adaptiveCardBackground` (solid, fixed in Phase 2)
- ✅ **Validated decision**: Skip GlassCard migration for dashboard cards entirely. No DataCard wrapper component needed.
- If a convenience wrapper is later desired, it can be a follow-up task — not in scope for this plan.

**Revised migration target: ~8 character/detail panels → GlassCard** (not 32 dashboard cards)

```swift
// Pattern for dashboard data cards (preserve solid bg from Phase 2)
RoundedRectangle(cornerRadius: Spacing.settingsCardRadius)
    .fill(Color.Wellness.adaptiveCardBackground)
    // shadow via AppShadow token (added in Part A)
```

**AppShadow new tokens to add** (`Views/DesignSystem/Shadows.swift` or `AppShadow` file):
```swift
static func accentGlow(color: Color) -> some View {
    self.shadow(color: color.opacity(0.26), radius: 16, x: 0, y: 12)
}
static func breathingGlow(color: Color) -> some View {
    self.shadow(color: color.opacity(0.3), radius: 20)
}
```

**PremiumBanner consolidation**:
- Keep: `Views/Dashboard/Components/PremiumBanner.swift` (wider usage base)
- Delete: `Views/Trends/Components/PremiumBannerView.swift` (duplicate)
- Move to: `Views/DesignSystem/Components/PremiumBanner.swift`
- Update all import/reference sites in Trends

**cornerRadius token map** (red-team verified actual values):

> ⚠️ **Red-team finding F12**: `DesignTokens.Layout.cornerRadius` = **12pt** (not 20pt). `Spacing.settingsCardRadius` = 20pt. Use the right token for the right context.

| Context | Token | Value |
|---------|-------|-------|
| Card surfaces (large) | `Spacing.settingsCardRadius` | 20pt |
| Widget/complication chips | `DesignTokens.Layout.cornerRadius` | 12pt |
| Small inner chips | `cornerRadiusSmall` — **ADD to `Spacing.swift`** | 14pt |
| Pills / CTAs | `Spacing.buttonRadius` (verify exists) | 20pt |

Add `static let cornerRadiusSmall: CGFloat = 14` to `Views/DesignSystem/Spacing.swift` (not `DesignTokens`).

## Related Code Files

### Modify
- `Views/DesignSystem/Shadows.swift` (or AppShadow file) — add `accentGlow`, `breathingGlow` modifiers; add `.settingsCardDoubleShadow()` convenience modifier
- `Views/Breathing/BreathingExerciseView.swift:195` — `cornerRadius: 33` → `Spacing.settingsCardRadius` (20pt card radius, NOT `DesignTokens.Layout.cornerRadius` which is 12pt)
- `Views/Breathing/Components/BreathingCircleView.swift:34` — inline glow shadow → `.breathingGlow(color:)`
- `Views/Dashboard/Components/QuickActionCard.swift:94` — inline glow shadow → `.accentGlow(color:)`
- `Views/Dashboard/Components/HealthDataSection.swift:92` — inline shadow → `AppShadow.iapUtilityRow` or `.settingsCardDoubleShadow()`
- `Views/Dashboard/Components/AIChatCard.swift:85` — double shadow pattern → `.settingsCardDoubleShadow()`
- `Views/Dashboard/Components/WatchMetricCard.swift` — double shadow → `.settingsCardDoubleShadow()`
- `Views/Dashboard/Components/HealthStatCard.swift` — double shadow → `.settingsCardDoubleShadow()`
- `Views/Dashboard/Components/SelfNoteCard.swift` — double shadow → `.settingsCardDoubleShadow()`
- `Views/Dashboard/Components/RecommendationsCard.swift` — double shadow → `.settingsCardDoubleShadow()`
- `Views/Premium/Components/IAPHeroSection.swift:22` — raw hex shadow → `Color.iapHeaderTeal` shadow
- `Views/Characters/CharacterDetailView.swift:166,184` — `.borderedProminent` → `PrimaryButton`
- `Views/Characters/EvolutionCelebrationView.swift:64` — `.borderedProminent` → `PrimaryButton`
- `Views/Settings/Components/PrivacyCard.swift:71` — manual clipShape → `SettingsCard { }`
- `Views/Settings/Components/ComplicationWidget.swift:53` — `cornerRadius: 20` → `Spacing.settingsCardRadius`; `cornerRadius: 10.9` → `Spacing.cornerRadiusSmall` (14pt, to be added in Part A)
- All 32 files with manual `RoundedRectangle` card pattern → `GlassCard` (largest batch)

### Create
- `Views/DesignSystem/Components/PremiumBanner.swift` — unified component (moved from Dashboard)

### Delete
- `Views/Trends/Components/PremiumBannerView.swift` — after all references updated

## Implementation Steps

### Part A — Token additions
1. Read `Views/DesignSystem/Shadows.swift`; check existing token structure
2. Add `accentGlow(color:)`, `breathingGlow(color:)`, `settingsCardDoubleShadow()` modifiers
3. Add `static let cornerRadiusSmall: CGFloat = 14` to `Views/DesignSystem/Spacing.swift` (not DesignTokens)

### Part B — Quick individual fixes (fast wins)
4. Fix `BreathingExerciseView:195` cornerRadius 33 → `Spacing.settingsCardRadius` (20pt)
5. Fix `BreathingCircleView:34` glow → `.breathingGlow(color:)`
6. Fix `QuickActionCard:94` glow → `.accentGlow(color:)`
7. Fix `IAPHeroSection:22` raw hex shadow → `Color.iapHeaderTeal`
8. Fix `CharacterDetailView` and `EvolutionCelebrationView` button styles (3 instances)
9. Fix `PrivacyCard` → `SettingsCard` wrapper
10. Fix `ComplicationWidget:53` cornerRadius values

### Part C — Double shadow de-duplication (5 files)
11. Implement `.settingsCardDoubleShadow()` modifier (Step 2)
12. Apply to 5 dashboard cards: `AIChatCard`, `WatchMetricCard`, `HealthStatCard`, `SelfNoteCard`, `RecommendationsCard`

### Part D — PremiumBanner consolidation
13. Read both `PremiumBanner.swift` and `PremiumBannerView.swift` (Trends); identify differences
14. Create unified `Views/DesignSystem/Components/PremiumBanner.swift` — **MUST use `Color.Wellness.adaptiveBackground` for all background properties** (not `Color.backgroundLight` or `Color.white`); add parameters for Ripple mascot inclusion
15. Update Dashboard and Trends import sites
16. Delete old `Views/Trends/Components/PremiumBannerView.swift`

### Part E — GlassCard migration (character/detail panels only — revised from 32 files)
17. `grep -rn "GlassCard\|trendsGlassCard" Views/ --include="*.swift" -l` — confirm current users
18. Identify character/detail overlay panels that should use glass effect (translucent dark surface)
19. Dashboard data cards (`HealthStatCard`, `WatchMetricCard`, etc.) stay as `RoundedRectangle + adaptiveCardBackground` — Phase 2 fixed their background; do NOT change to GlassCard
20. For panels that DO need glass: wrap in `GlassCard { content }` — verify `GlassCard` accepts content closure and `cornerRadius` parameter
21. Build and fix each file before moving to next

### Verify
21. `grep -rn "\.shadow(color:.*radius" Views/ --include="*.swift" | wc -l` → should be ≤10 (only intentional non-token glows)
22. `grep -rn "cornerRadius(33)" Views/ --include="*.swift"` → 0 results
23. `grep -rn "borderedProminent" Views/ --include="*.swift"` → 0 results

## Success Criteria

- [ ] GlassCard used for character/detail panels; dashboard data cards keep solid `adaptiveCardBackground` (GlassCard count stays near 4–10, not 40+)
- [ ] Inline shadow calls reduced from 51 to <10
- [ ] `cornerRadius(33)` — 0 occurrences
- [ ] `.borderedProminent` — 0 occurrences in Views/
- [ ] `PremiumBannerView.swift` (Trends) deleted; Dashboard + Trends both use unified component
- [ ] Build succeeds; visual spot-check in simulator looks correct

## Risk Assessment

- **GlassCard contract**: Medium — must verify `GlassCard` accepts arbitrary content; if it only wraps specific types, migration path is different
- **PremiumBanner consolidation**: Medium — two implementations may have diverged; test both Dashboard and Trends after merge
- **Shadow removal**: Low — inline shadows that have no AppShadow equivalent yet get replaced by new tokens added in Part A
