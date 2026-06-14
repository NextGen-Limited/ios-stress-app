# Design System Audit Report — StressMonitor iOS
**Date:** 2026-06-13
**Scope:** StressMonitor/StressMonitor/Views/ — 149 Swift files
**Source of truth:** docs/design/character-concept-sheet.html

---

## Executive Summary

The StressMonitor design system has solid token foundations (Color+Wellness, Color+Extensions, Typography, Spacing, Shadows, DesignSystem components) but adoption across Views is critically low. The most severe issues are: (1) the primary character mascot is still rendered as a cat (`cat.fill`, `AIKitten`, `CharacterCalm`) in 5 views, contradicting the Ripple Water Otter spec; (2) 12+ dashboard and premium cards use `Color.white` as a solid non-adaptive background, breaking dark mode; and (3) 48 raw `Font.custom("Roboto-*")` calls and 264 raw `.font(.system(size:))` calls bypass the Typography token system entirely. Overall compliance is approximately 30–40% — the token systems exist but are not enforced at call sites.

---

## Summary Table

| Category | Files Checked | Issues Found | Critical | Major | Minor |
|----------|--------------|-------------|---------|-------|-------|
| Color Consistency | 149 | 34 | 8 | 18 | 2 |
| Typography | 149 | 27 | 15 | 6 | 6 |
| Character / Mascot | 149 | 14 | 5 | 4 | 5 |
| Component Patterns | 57 | 14 | 0 | 8 | 4 |
| Dark Mode / Adaptive | 149 | 37 | 0 | 23 | 14 |
| Spacing & Layout | 149 | 27 | 0 | 5 | 22 |
| **Totals** | **149** | **153** | **28** | **64** | **53** |

---

## 1. Color Consistency

### 🔴 BreathingExerciseView — Private tealLight token (#85C9C9)
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 301
- **Current:** `static let tealLight = Color(red: 0.52, green: 0.79, blue: 0.79)   // #85C9C9`
- **Expected:** `Color.Wellness.tealCard` (existing token) or new Ripple blue `#4FC3F7` if Ripple redesign intended
- **Category:** Color
- **Fix effort:** M

### 🔴 BreathingExerciseView — Private tealDark token (#73B9B9)
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 302
- **Current:** `static let tealDark  = Color(red: 0.45, green: 0.73, blue: 0.73)   // #73B9B9`
- **Expected:** Derive from `Color.Wellness.tealCard` or use a dark variant token; do not invent private teal tokens
- **Category:** Color
- **Fix effort:** M

### 🔴 NotificationsCard — Hardcoded old teal in gradient
- **File:** `Views/Settings/Components/NotificationsCard.swift`
- **Line:** 167
- **Current:** `colors: [Color(hex: "85C9C9"), Color.settingsRippleBlue]`
- **Expected:** Replace `Color(hex: "85C9C9")` with `Color.Wellness.tealCard` or `Color.settingsRippleBlue`
- **Category:** Color
- **Fix effort:** S

### 🔴 SelfNoteCard — Hardcoded old teal in gradient
- **File:** `Views/Dashboard/Components/SelfNoteCard.swift`
- **Line:** 16
- **Current:** `colors: [Color(hex: "B5FFC9"), Color(hex: "85C9C9")]`
- **Expected:** Replace `Color(hex: "85C9C9")` with `Color.Wellness.tealCard`; replace `Color(hex: "B5FFC9")` with a named wellness token
- **Category:** Color
- **Fix effort:** S

### 🔴 BreathingExerciseView — Hardcoded gray for secondary text
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 110
- **Current:** `.foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))`
- **Expected:** `.foregroundStyle(Color.Wellness.adaptiveSecondaryText)`
- **Category:** Color
- **Fix effort:** S

### 🔴 BreathingExerciseView — Hardcoded dark gray for primary text
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 140
- **Current:** `.foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))`
- **Expected:** `.foregroundStyle(Color.Wellness.adaptivePrimaryText)`
- **Category:** Color
- **Fix effort:** S

### 🔴 BreathingExerciseView — All four BoxBreathingStep dotColors hardcoded
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 288
- **Current:** `dotColor: Color(red: 0.741, green: 0.878, blue: 1.0)` (and 3 other raw `Color(red:)` values)
- **Expected:** Map to existing wellness tokens (`Color.Wellness.calmBlue`, `Color.Wellness.healthGreen`, etc.)
- **Category:** Color
- **Fix effort:** M

### 🔴 BreathingSessionView — Hardcoded dark gradient background
- **File:** `Views/Breathing/BreathingSessionView.swift`
- **Line:** 99
- **Current:** `Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)`
- **Expected:** `Color.Wellness.backgroundDark` or `Color.Wellness.adaptiveBackground` (#121212) for dark gradient stops
- **Category:** Color
- **Fix effort:** S

### 🟡 SmartInsightsCard — Hardcoded #FFD700 for premium badge
- **File:** `Views/Dashboard/Components/SmartInsightsCard.swift`
- **Line:** 28
- **Current:** `.background(Color(hex: "#FFD700"))`
- **Expected:** `Color.Wellness.insightTitle` (#FFBF00) or define a `premiumBadge` token
- **Category:** Color
- **Fix effort:** S

### 🟡 PremiumLockOverlay — Hardcoded #FFD380 near-miss of elevatedBadge
- **File:** `Views/Dashboard/Components/PremiumLockOverlay.swift`
- **Line:** 31
- **Current:** `.background(Color(hex: "#FFD380"))`
- **Expected:** `.background(Color.Wellness.elevatedBadge)` (#FDD57A)
- **Category:** Color
- **Fix effort:** S

### 🟡 ActionView — Mixed #FFD700 with Color.premiumGold in same gradient
- **File:** `Views/Action/ActionView.swift`
- **Line:** 425
- **Current:** `colors: [Color(hex: "#FFD700"), Color.premiumGold]`
- **Expected:** `colors: [Color.premiumGold, Color.premiumGold]` or define a secondary gold token
- **Category:** Color
- **Fix effort:** S

### 🟡 PremiumBannerView — Hardcoded #F39C12 for premium banner
- **File:** `Views/Trends/Components/PremiumBannerView.swift`
- **Line:** 41
- **Current:** `.background(Color(hex: "#F39C12"))`
- **Expected:** `.background(Color.premiumGold)` or add a `premiumBannerAccent` token
- **Category:** Color
- **Fix effort:** S

### 🟡 AIChatCard — Color.white card background (dark mode broken)
- **File:** `Views/Dashboard/Components/AIChatCard.swift`
- **Line:** 83
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 SmartInsightsCard — Color.white card background
- **File:** `Views/Dashboard/Components/SmartInsightsCard.swift`
- **Line:** 43
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 WatchMetricCard — Color.white card background
- **File:** `Views/Dashboard/Components/WatchMetricCard.swift`
- **Line:** 86
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 HealthDataSection — Color.white card background
- **File:** `Views/Dashboard/Components/HealthDataSection.swift`
- **Line:** 90
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 HRVTrendCard — Color.white card background
- **File:** `Views/Dashboard/Components/HRVTrendCard.swift`
- **Line:** 62
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 HealthStatCard — Color.white card background
- **File:** `Views/Dashboard/Components/HealthStatCard.swift`
- **Line:** 63
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 WidgetPromoCard — Color.white card background
- **File:** `Views/Dashboard/Components/WidgetPromoCard.swift`
- **Line:** 35
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 IntroMessageCard — Color.white card background (×2)
- **File:** `Views/Dashboard/Components/IntroMessageCard.swift`
- **Lines:** 26, 34
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 BreathingExerciseView — Color.white screen background
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 44
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 IAPHeroSection — Color.white full-screen background (dark mode broken)
- **File:** `Views/Premium/Components/IAPHeroSection.swift`
- **Line:** 96
- **Current:** `Color.white.ignoresSafeArea()`
- **Expected:** `Color.Wellness.adaptiveBackground.ignoresSafeArea()`
- **Category:** Color
- **Fix effort:** S

### 🟡 IAPNavBar — Color.white full-screen background
- **File:** `Views/Premium/Components/IAPNavBar.swift`
- **Line:** 58
- **Current:** `Color.white.ignoresSafeArea()`
- **Expected:** `Color.Wellness.adaptiveBackground.ignoresSafeArea()`
- **Category:** Color
- **Fix effort:** S

### 🟡 IAPCTAButton — Color.white button background
- **File:** `Views/Premium/Components/IAPCTAButton.swift`
- **Line:** 53
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)` or `Color(.systemBackground)`
- **Category:** Color
- **Fix effort:** S

### 🟡 QuoteCard — Hardcoded warm beige with no dark mode variant
- **File:** `Views/Dashboard/Components/QuoteCard.swift`
- **Line:** 26
- **Current:** `.background(Color(hex: "E9DDCA"))`
- **Expected:** Add `quoteCardBackground` token with dark mode support
- **Category:** Color
- **Fix effort:** S

### 🟡 IAPBenefitsCard — Hardcoded warm background (no dark mode)
- **File:** `Views/Premium/Components/IAPBenefitsCard.swift`
- **Line:** 97
- **Current:** `.background(Color(hex: "F5F2EC"))`
- **Expected:** Define adaptive `iapCardBackground` token in Color+Extensions.swift
- **Category:** Color
- **Fix effort:** S

### 🟢 RippleTrendsKit — Local darkCanvas token should be promoted
- **File:** `Views/Trends/Components/RippleTrendsKit.swift`
- **Line:** 71
- **Current:** `static let darkCanvas = Color(hex: "#0A0A0F")`
- **Expected:** Move to `Color.Wellness.darkCanvas` or `Color.Wellness.trendsDarkBackground` in Color+Wellness.swift
- **Category:** Color
- **Fix effort:** S

### 🟢 HealthDataSection — Hardcoded hex in shadow color
- **File:** `Views/Dashboard/Components/HealthDataSection.swift`
- **Line:** 92
- **Current:** `.shadow(color: Color(red: 0.094, green: 0.153, blue: 0.294).opacity(0.04), ...)`
- **Expected:** Extract to a shadow helper or token `Color.Wellness.cardShadow`
- **Category:** Color
- **Fix effort:** S

**Token system notes:**
- `Color.Wellness.tealCard` (#85C9C9) exists but maps to the old teal — the token itself needs updating to `#4FC3F7` when migrating to Ripple blue
- `#4FC3F7` is defined as `Color.settingsRippleBlue` and `Color.accentTeal` but not as a `rippleBlue` token in `Color.Wellness`
- `#808080` is duplicated as both `textTertiary` and `iapTextMuted`; `#FFF4D6`/`#3A2A05` duplicated as both `settingsAmberInfo` and `bannerYellow`

---

## 2. Typography

### 🔴 AIChatCard — Raw Roboto font calls bypassing Typography tokens
- **File:** `Views/Dashboard/Components/AIChatCard.swift`
- **Line:** 21
- **Current:** `Font.custom("Roboto-Bold", size: 24)`, `Font.custom("Roboto-Regular", size: 14/13)`, `Font.custom("Roboto-Medium", size: 14)`, `Font.custom("Roboto-Light", size: 10)` — 5 raw calls
- **Expected:** `Typography.robotoTitle` / `Typography.robotoHeadline` / `Typography.robotoBody` / `Typography.robotoCaption`
- **Category:** Typography
- **Fix effort:** S

### 🔴 QuoteCard — Roboto-Italic and Roboto-ExtraBold (undefined tokens)
- **File:** `Views/Dashboard/Components/QuoteCard.swift`
- **Line:** 12
- **Current:** `.font(.custom("Roboto-Italic", size: 14))`, `.font(.custom("Roboto-ExtraBold", size: 14))`
- **Expected:** Add `Typography.robotoItalic` / `Typography.robotoExtraBold` tokens, then reference by token
- **Category:** Typography
- **Fix effort:** S

### 🔴 SmartInsightsCard — Raw Roboto calls
- **File:** `Views/Dashboard/Components/SmartInsightsCard.swift`
- **Line:** 10
- **Current:** `.font(.custom("Roboto-Bold", size: 18/14))`, `.font(.custom("Roboto-Regular", size: 14))`
- **Expected:** `Typography.robotoHeadline` / `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 PremiumBanner — Raw Roboto calls
- **File:** `Views/Dashboard/Components/PremiumBanner.swift`
- **Line:** 18
- **Current:** `.font(.custom("Roboto-Bold", size: 24/16))`, `.font(.custom("Roboto-Regular", size: 14))`
- **Expected:** `Typography.robotoTitle` / `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 RecommendationsCard — Fractional Roboto sizes (Figma copy-paste)
- **File:** `Views/Dashboard/Components/RecommendationsCard.swift`
- **Line:** 21
- **Current:** `.font(.custom("Roboto-Bold", size: 23.723))`, `.font(.custom("Roboto-Bold", size: 14.599))`
- **Expected:** `Typography.robotoTitle` (24pt); fractional sizes must not exist in production UI
- **Category:** Typography
- **Fix effort:** S

### 🔴 WatchMetricCard — Raw Roboto calls at 4 different sizes
- **File:** `Views/Dashboard/Components/WatchMetricCard.swift`
- **Line:** 38
- **Current:** `.font(.custom("Roboto-Bold", size: 12/14/11/14))` — 4 raw calls
- **Expected:** `Typography.robotoCaption` / `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 HealthStatCard — Raw Roboto including fractional size 23.723
- **File:** `Views/Dashboard/Components/HealthStatCard.swift`
- **Line:** 23
- **Current:** `.font(.custom("Roboto-Bold", size: 14/24/23.723/24/24/16))` — 6 raw calls
- **Expected:** `Typography.robotoTitle` / `Typography.robotoHeadline` / `Typography.robotoCaption`
- **Category:** Typography
- **Fix effort:** S

### 🔴 HRVTrendCard — Raw Roboto calls
- **File:** `Views/Dashboard/Components/HRVTrendCard.swift`
- **Line:** 14
- **Current:** `.font(.custom("Roboto-Bold", size: 18))`, `.font(.custom("Roboto-Regular", size: 12/10))` — 4 raw calls
- **Expected:** `Typography.robotoHeadline` / `Typography.robotoCaption`
- **Category:** Typography
- **Fix effort:** S

### 🔴 WeekCalendarStrip — Raw Roboto with fractional 12.13
- **File:** `Views/Dashboard/Components/WeekCalendarStrip.swift`
- **Line:** 66
- **Current:** `.font(.custom("Roboto-Bold", size: 14))`, `.font(.custom("Roboto-Medium", size: 12.13))`
- **Expected:** `Typography.robotoCaption`; add `Typography.robotoMedium` token for Roboto-Medium variant
- **Category:** Typography
- **Fix effort:** S

### 🔴 StressSourcesCard — Raw Roboto with fractionals 13.97 and 11.99
- **File:** `Views/Dashboard/Components/StressSourcesCard.swift`
- **Line:** 62
- **Current:** `.font(.custom("Roboto-Bold", size: 18/13.97/16/11.99/14))`, `.font(.custom("Roboto-Regular", size: 12))` — 6 raw calls
- **Expected:** `Typography.robotoHeadline` / `Typography.robotoCaption` / `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 WidgetPromoCard — Raw Roboto calls
- **File:** `Views/Dashboard/Components/WidgetPromoCard.swift`
- **Line:** 20
- **Current:** `.font(.custom("Roboto-Bold", size: 18))`, `.font(.custom("Roboto-Regular", size: 13))`
- **Expected:** `Typography.robotoHeadline` / `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 SelfNoteCard — Raw Roboto calls
- **File:** `Views/Dashboard/Components/SelfNoteCard.swift`
- **Line:** 27
- **Current:** `.font(.custom("Roboto-Regular", size: 13))`, `.font(.custom("Roboto-Bold", size: 16))`
- **Expected:** `Typography.robotoBody` / `Typography.robotoHeadline`
- **Category:** Typography
- **Fix effort:** S

### 🔴 IntroMessageCard — Raw Roboto call
- **File:** `Views/Dashboard/Components/IntroMessageCard.swift`
- **Line:** 21
- **Current:** `.font(.custom("Roboto-Regular", size: 14))`
- **Expected:** `Typography.robotoBody`
- **Category:** Typography
- **Fix effort:** S

### 🔴 MiniWalkInstructionCard — Roboto-MediumItalic (undefined token)
- **File:** `Views/MiniWalk/Components/MiniWalkInstructionCard.swift`
- **Line:** 10
- **Current:** `.font(.custom("Roboto-MediumItalic", size: 18))`
- **Expected:** Add `Typography.robotoMediumItalic` token or substitute with nearest defined token
- **Category:** Typography
- **Fix effort:** S

### 🔴 MiniWalkTimerRing — Raw Roboto-Bold for numeric timer display
- **File:** `Views/MiniWalk/Components/MiniWalkTimerRing.swift`
- **Line:** 47
- **Current:** `.font(.custom("Roboto-Bold", size: 42))`
- **Expected:** `Typography.dataLarge` (48pt SF Pro Rounded bold) or `Typography.dataMedium` (34pt); use data* tokens for numeric display
- **Category:** Typography
- **Fix effort:** S

### 🟡 264 hardcoded .font(.system(size:)) calls — no Dynamic Type
- **File:** `Views/` (Settings, Dashboard, DesignSystem, Breathing, History — 264 call sites)
- **Line:** various
- **Current:** `.font(.system(size: 14))`, `.font(.system(size: 7.5, weight: .bold, design: .rounded))`, `.font(.system(size: 14.9, weight: .bold))`
- **Expected:** `.font(Typography.body)`, `.font(Typography.caption1)`, etc. — map each raw size to nearest Typography token
- **Category:** Typography
- **Fix effort:** L

### 🟡 ComplicationWidget — SF Pro Rounded outside data display context
- **File:** `Views/Settings/Components/ComplicationWidget.swift`
- **Line:** 31
- **Current:** `.font(.system(size: 7.5, weight: .bold, design: .rounded))`
- **Expected:** Typography token without `design: .rounded` — SF Pro Rounded reserved for `data*` tokens only
- **Category:** Typography
- **Fix effort:** M

### 🟡 SettingsCharacterStatusHeader — SF Pro Rounded in non-numeric context
- **File:** `Views/Settings/Components/SettingsCharacterStatusHeader.swift`
- **Line:** 31
- **Current:** `.font(.system(size: 22, weight: .bold, design: .rounded))`
- **Expected:** `Typography.title3` or `Typography.headline` without `design: .rounded`
- **Category:** Typography
- **Fix effort:** S

### 🟡 DataDeleteView — SF Pro Rounded in non-numeric context
- **File:** `Views/Settings/DataManagement/DataDeleteView.swift`
- **Line:** 113
- **Current:** `.font(.system(size: 18, weight: .bold, design: .rounded))`
- **Expected:** `Typography.headline` without `design: .rounded`
- **Category:** Typography
- **Fix effort:** S

### 🟡 ExportProgressView — Inline rounded instead of data* token
- **File:** `Views/Settings/DataManagement/Components/ExportProgressView.swift`
- **Line:** 36
- **Current:** `.font(.system(size: 28, weight: .bold, design: .rounded))`
- **Expected:** `Typography.dataSmall` (28pt bold SF Pro Rounded — exact match)
- **Category:** Typography
- **Fix effort:** S

### 🟡 57 unauthorized SF Pro Rounded usages
- **Files:** Settings, Breathing, general UI
- **Current:** 57 uses of `design: .rounded` across Views vs 4 authorized `data*` token usages
- **Expected:** Only `dataHero`, `dataLarge`, `dataMedium`, `dataSmall` tokens should use `design: .rounded`
- **Category:** Typography
- **Fix effort:** M

### 🟢 BreathingSessionView — Timer display missing .monospacedDigit()
- **File:** `Views/Breathing/BreathingSessionView.swift`
- **Line:** 58
- **Current:** `Text(timeRemainingText).font(.system(size: 48, weight: .bold, design: .rounded))` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()` after `.font(...)`
- **Category:** Typography
- **Fix effort:** S

### 🟢 BreathingExerciseView — Phase progress counter missing .monospacedDigit()
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 128
- **Current:** `Text("\(Int(phaseElapsed))s/\(Int(phaseDuration))s").font(.system(size: 14))` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()`
- **Category:** Typography
- **Fix effort:** S

### 🟢 BreathingSummaryView — HRV improvement numerics missing .monospacedDigit()
- **File:** `Views/Breathing/BreathingSummaryView.swift`
- **Line:** 74
- **Current:** `Text(sign)`, `Text("\(Int(abs(result.improvement)))ms")`, `Text("(\(Int(result.percentageImprovement))%)")` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()` to all three numeric Text views
- **Category:** Typography
- **Fix effort:** S

### 🟢 StressRingView — 72pt stress score missing .monospacedDigit()
- **File:** `Views/Dashboard/Components/StressRingView.swift`
- **Line:** 40
- **Current:** `Text("\(Int(stressLevel))").font(.system(size: 72, weight: .bold, design: .rounded))` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()`; also consider `Typography.dataHero` token
- **Category:** Typography
- **Fix effort:** S

### 🟢 CompactStressHeaderBar — Stress score missing .monospacedDigit()
- **File:** `Views/Dashboard/Components/CompactStressHeaderBar.swift`
- **Line:** 45
- **Current:** `Text("\(Int(stressLevel))").font(.system(size: 13, weight: .semibold))` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()`
- **Category:** Typography
- **Fix effort:** S

### 🟢 HRVTrendCard — Chart Y-axis label missing .monospacedDigit()
- **File:** `Views/Dashboard/Components/HRVTrendCard.swift`
- **Line:** 72
- **Current:** `Text("\(value)").font(.custom("Roboto-Regular", size: 10))` — no `.monospacedDigit()`
- **Expected:** Add `.monospacedDigit()` (also fix raw Roboto usage per CRITICAL finding)
- **Category:** Typography
- **Fix effort:** S

---

## 3. Character / Mascot

### 🔴 AIChatCard — Cat assets and "StressCat" CTA
- **File:** `Views/Dashboard/Components/AIChatCard.swift`
- **Line:** 11
- **Current:** `Image("AIKitten")` / `Text("Chat with StressCat")` / `// Cat mascot — positioned top-right`
- **Expected:** Replace with `RippleMoodFace` or `StressBuddyIllustration`; rename CTA to "Chat with Ripple"
- **Category:** Character
- **Fix effort:** S

### 🔴 SmartInsightsCard — cat.fill system icon as mascot
- **File:** `Views/Dashboard/Components/SmartInsightsCard.swift`
- **Line:** 37
- **Current:** `Image(systemName: "cat.fill")` inside circle overlay
- **Expected:** Replace with `RippleMoodFace` or `StressBuddyIllustration` (Ripple Water Otter)
- **Category:** Character
- **Fix effort:** S

### 🔴 IntroMessageCard — cat.fill system icon as avatar
- **File:** `Views/Dashboard/Components/IntroMessageCard.swift`
- **Line:** 13
- **Current:** `Image(systemName: "cat.fill")`
- **Expected:** Replace with `RippleMoodFace` or `StressBuddyIllustration`
- **Category:** Character
- **Fix effort:** S

### 🔴 PremiumBannerView — Old CharacterCalm cat-era asset
- **File:** `Views/Trends/Components/PremiumBannerView.swift`
- **Line:** 17
- **Current:** `Image("CharacterCalm")` `.resizable()` `.scaledToFit()` `.frame(height: 120)` — comment says "Cat mascot anchored bottom-left"
- **Expected:** Replace with `StressBuddyIllustration` or `RippleMoodFace` referencing Ripple Water Otter
- **Category:** Character
- **Fix effort:** S

### 🔴 PremiumBanner — Cat mascot placeholder comment, no replacement
- **File:** `Views/Dashboard/Components/PremiumBanner.swift`
- **Line:** 60
- **Current:** `// Cat mascot placeholder (would be replaced with actual asset)` / `// In Figma, there's a cat illustration on the right side`
- **Expected:** Replace placeholder comment with actual `StressBuddyIllustration` or `RippleMoodFace`; update doc comment to reference Ripple
- **Category:** Character
- **Fix effort:** S

### 🟡 Dashboard — No RippleMoodFace or RippleCharacterView on primary screen
- **File:** `Views/Dashboard/` (all components)
- **Current:** `SemicircularGaugeView` uses `StressBuddyIllustration` (correct), but no other dashboard card uses any Ripple-branded character view
- **Expected:** Key dashboard cards (AIChatCard, IntroMessageCard, SmartInsightsCard) should use `RippleMoodFace` or `StressBuddyIllustration`
- **Category:** Character
- **Fix effort:** M

### 🟡 Breathing / Action / MiniWalk — Character entirely absent from therapeutic flows
- **Files:** `Views/Breathing/BreathingExerciseView.swift`, `Views/Action/`, `Views/MiniWalk/`
- **Current:** No `RippleMoodFace`, `StressBuddyIllustration`, or any mascot found on these screens
- **Expected:** Incorporate `RippleMoodFace` or `StressBuddyIllustration` to reinforce gamification on action-oriented screens
- **Category:** Character
- **Fix effort:** M

### 🟡 RippleTrendsKit — StressTier enum names do not match spec
- **File:** `Views/Trends/Components/RippleTrendsKit.swift`
- **Line:** 16
- **Current:** `case calm / good / balanced / stressed / overwhelmed` with labels "Calm" / "Good" / "Balanced" / "Stressed" / "Overwhelmed"
- **Expected:** `veryCal / calm / neutral / stressed / critical` with labels "Very Calm" / "Calm" / "Neutral" / "Stressed" / "Critical"
- **Category:** Character / Stress Tiers
- **Fix effort:** M

### 🟡 RippleTrendsKit — TrendsPalette tier colors deviate from spec
- **File:** `Views/Trends/Components/RippleTrendsKit.swift`
- **Line:** 77
- **Current:** `tierCalm=#4FC3F7` (Ripple blue, not green), `tierGood=#A5D6A7` (close, not spec `#81C784`), `tierBalanced=#7986CB` (purple — spec says `#FFB74D` amber for Neutral)
- **Expected:** Very Calm=`#4CAF50` / Calm=`#81C784` / Neutral=`#FFB74D` / Stressed=`#FF8A65` / Critical=`#E53935`
- **Category:** Character / Stress Tiers
- **Fix effort:** M

### 🟢 NotificationsCard — Old teal #85C9C9 alongside new settingsRippleBlue
- **File:** `Views/Settings/Components/NotificationsCard.swift`
- **Line:** 167
- **Current:** `colors: [Color(hex: "85C9C9"), Color.settingsRippleBlue]`
- **Expected:** Replace `Color(hex: "85C9C9")` with `Color.settingsRippleBlue` or `Color(hex: "4FC3F7")`
- **Category:** Character / Accent
- **Fix effort:** S

### 🟢 SelfNoteCard — Old teal #85C9C9 in gradient
- **File:** `Views/Dashboard/Components/SelfNoteCard.swift`
- **Line:** 16
- **Current:** `colors: [Color(hex: "B5FFC9"), Color(hex: "85C9C9")]`
- **Expected:** Replace `#85C9C9` with `#4FC3F7` (Ripple blue) to match new primary accent
- **Category:** Character / Accent
- **Fix effort:** S

### 🟢 StressOverTimeChart — 3-tier legend, wrong color tokens
- **File:** `Views/Dashboard/Components/StressOverTimeChart.swift`
- **Line:** 153
- **Current:** `legendItem(color: HomeCharacterDesignTokens.Blossom.accent, label: "Calm")` / "Mild" / "Stressed"
- **Expected:** Use spec tier labels and spec tier colors (#4CAF50 Very Calm, #81C784 Calm, etc.)
- **Category:** Character / Stress Tiers
- **Fix effort:** S

### 🟢 RippleTrendsKit — Doc comment says "Calm" for tier 0–20 (should be "Very Calm")
- **File:** `Views/Trends/Components/RippleTrendsKit.swift`
- **Line:** 10
- **Current:** `/// - 0…20   → 😴  "Calm"`
- **Expected:** `/// - 0…20   → 😴  "Very Calm"`
- **Category:** Character / Stress Tiers
- **Fix effort:** S

---

## 4. Component Patterns

### 🟡 BreathingExerciseView — Hardcoded cornerRadius(33) on card container
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 195
- **Current:** `RoundedRectangle(cornerRadius: 33)`
- **Expected:** Use `DesignTokens.Layout.cornerRadius` or `GlassCard` component
- **Category:** Component
- **Fix effort:** S

### 🟡 32 files — Manual RoundedRectangle instead of GlassCard
- **Files:** Chat, Dashboard, Breathing, Settings, Onboarding, Premium, Trends, Characters, MiniWalk, History (32 files total)
- **Current:** Manual `RoundedRectangle(cornerRadius:)` or `.clipShape(RoundedRectangle)` for card surfaces; `GlassCard` referenced only 14 times
- **Expected:** Use `GlassCard` for surfaces needing the glass-card treatment; reserve bare `RoundedRectangle` for non-card shapes
- **Category:** Component
- **Fix effort:** L

### 🟡 51 inline .shadow() calls — AppShadow tokens ignored
- **Files:** Dashboard, Breathing, Settings, Premium, Onboarding, Trends, Characters (32 files)
- **Current:** 51 inline `.shadow(color:opacity:radius:)` calls; only `MainTabView.swift:102` uses `.buttonShadow()` token helper
- **Expected:** Use `.cardShadow()`, `.elevatedShadow()`, `.buttonShadow()`, or `AppShadow` token modifiers
- **Category:** Component
- **Fix effort:** L

### 🟡 QuickActionCard — Colored glow shadow with no AppShadow token
- **File:** `Views/Dashboard/Components/QuickActionCard.swift`
- **Line:** 94
- **Current:** `.shadow(color: color.opacity(0.26), radius: 16, x: 0, y: 12)`
- **Expected:** Add `AppShadow.accentGlow` named token; create `.accentGlowShadow(color:)` modifier for consistent glow parameters
- **Category:** Component
- **Fix effort:** M

### 🟡 BreathingCircleView — Dynamic colored glow with no token
- **File:** `Views/Breathing/Components/BreathingCircleView.swift`
- **Line:** 34
- **Current:** `.shadow(color: color.opacity(0.3), radius: 20)`
- **Expected:** Extract a `BreathingCircle`-specific glow constant or add `AppShadow.breathingGlow` token
- **Category:** Component
- **Fix effort:** S

### 🟡 HealthDataSection — Raw hex in shadow approximating iapUtilityRow
- **File:** `Views/Dashboard/Components/HealthDataSection.swift`
- **Line:** 92
- **Current:** `.shadow(color: Color(red: 0.094, green: 0.153, blue: 0.294).opacity(0.04), radius: 5.7, y: 5.7)`
- **Expected:** Use `AppShadow.iapUtilityRow` or create `AppShadow.settingsCardDouble()` convenience modifier
- **Category:** Component
- **Fix effort:** M

### 🟡 CharacterDetailView + EvolutionCelebrationView — .borderedProminent bypasses design system
- **Files:** `Views/Characters/CharacterDetailView.swift` (lines 166, 184), `Views/Characters/EvolutionCelebrationView.swift` (line 64)
- **Current:** `.buttonStyle(.borderedProminent)` — 3 instances
- **Expected:** Use `PrimaryButton` (from `Buttons.swift`) or `.buttonStyle(ScaleButtonStyle())`
- **Category:** Component
- **Fix effort:** S

### 🟡 Duplicate premium banner components (PremiumBanner + PremiumBannerView)
- **Files:** `Views/Dashboard/Components/PremiumBanner.swift`, `Views/Trends/Components/PremiumBannerView.swift`
- **Current:** Two separate implementations of the same UI concept with independent layouts
- **Expected:** Consolidate into a single `PremiumBannerView` in `DesignSystem/Components/` used by both Dashboard and Trends
- **Category:** Component
- **Fix effort:** M

### 🟢 ComplicationWidget — Hardcoded cornerRadius values
- **File:** `Views/Settings/Components/ComplicationWidget.swift`
- **Line:** 53
- **Current:** `RoundedRectangle(cornerRadius: 20)` and `RoundedRectangle(cornerRadius: 10.9)`
- **Expected:** Use `DesignTokens.Layout.cornerRadius` for standard; define `DesignTokens.Layout.cornerRadiusSmall` for inner chips
- **Category:** Component
- **Fix effort:** S

### 🟢 IAPHeroSection — Raw hex in glow shadow ignores iapHeaderTeal token
- **File:** `Views/Premium/Components/IAPHeroSection.swift`
- **Line:** 22
- **Current:** `.shadow(color: Color(hex: "24B9CC").opacity(0.28), radius: 24, y: 12)`
- **Expected:** `.shadow(color: Color.iapHeaderTeal.opacity(0.28), radius: 24, y: 12)` — `IAPCTAButton.swift` already uses `Color.iapHeaderTeal`
- **Category:** Component
- **Fix effort:** S

### 🟢 5 dashboard cards — settingsCard double-shadow copy-pasted
- **Files:** `AIChatCard.swift` (line 85), `WatchMetricCard`, `HealthStatCard`, `SelfNoteCard`, `RecommendationsCard`
- **Current:** Two-layer shadow pattern copy-pasted at 5 sites
- **Expected:** Extract `.settingsCardDoubleShadow()` view modifier using `AppShadow.settingsCard` values
- **Category:** Component
- **Fix effort:** S

### 🟢 PrivacyCard — Manual clipShape instead of SettingsCard component
- **File:** `Views/Settings/Components/PrivacyCard.swift`
- **Line:** 71
- **Current:** Manual `.clipShape(RoundedRectangle(cornerRadius: 14))` + stroke overlay
- **Expected:** Wrap content in `SettingsCard { }` consistent with 9 other Settings subviews
- **Category:** Component
- **Fix effort:** S

---

## 5. Dark Mode / Adaptive

### 🟡 LoadingView — Non-adaptive Color.backgroundLight
- **File:** `Views/DesignSystem/Components/LoadingView.swift`
- **Line:** 18
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)` or `Color(uiColor: .systemBackground)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 BreathingExerciseView — Color.white hard-coded
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Line:** 44
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.surface)` or `Color(uiColor: .systemBackground)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 BreathingSummaryView — Color.backgroundLight
- **File:** `Views/Breathing/BreathingSummaryView.swift`
- **Line:** 63
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 SemicircularGaugeView — Color.backgroundLight (×2)
- **File:** `Views/Dashboard/Components/SemicircularGaugeView.swift`
- **Lines:** 158, 166
- **Current:** `.background(Color.backgroundLight)` (both instances)
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 DailyTimelineView — Color.backgroundLight (×2)
- **File:** `Views/Dashboard/Components/DailyTimelineView.swift`
- **Lines:** 129, 145
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 MeasurementHistoryView — Color.backgroundLight (×2)
- **File:** `Views/History/MeasurementHistoryView.swift`
- **Lines:** 29, 98
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 MeasurementDetailView — Color.backgroundLight
- **File:** `Views/History/MeasurementDetailView.swift`
- **Line:** 33
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 PremiumBannerView (Trends) — Color.backgroundLight
- **File:** `Views/Trends/Components/PremiumBannerView.swift`
- **Line:** 59
- **Current:** `.background(Color.backgroundLight)`
- **Expected:** `.background(Color.Wellness.background)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 IAPCTAButton — Color.white on critical purchase path
- **File:** `Views/Premium/Components/IAPCTAButton.swift`
- **Line:** 53
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.iapCardBackground)` or `Color.Wellness.adaptiveCardBackground`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 IAPUtilityRow — Color.white in IAP flow
- **File:** `Views/Premium/Components/IAPUtilityRow.swift`
- **Line:** 80
- **Current:** `.background(Color.white)`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟡 PrimaryMetricCard — Color(.systemBackground) bypasses token system
- **File:** `Views/Components/PrimaryMetricCard.swift`
- **Line:** 51
- **Current:** `.background(Color(.systemBackground))`
- **Expected:** `.background(Color.Wellness.adaptiveCardBackground)`
- **Category:** Dark Mode
- **Fix effort:** S

### 🟢 ActionView — Color.white.opacity(0.04) overlay not tokenized
- **File:** `Views/Action/ActionView.swift`
- **Line:** 160
- **Current:** `.background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))`
- **Expected:** Document as intentional glass overlay or extract to token
- **Category:** Dark Mode
- **Fix effort:** S

### 🟢 BreathingExerciseView — Black shadows not adaptive (×2)
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Lines:** 104, 105
- **Current:** `.shadow(color: .black.opacity(0.1), radius: 9, y: 3)` / `.shadow(color: .black.opacity(0.1), radius: 4, y: 5)`
- **Expected:** `Color.primary.opacity(0.10)` for adaptive shadow
- **Category:** Dark Mode
- **Fix effort:** M

### 🟢 SettingsCard — Raw colorScheme branch to suppress shadow
- **File:** `Views/DesignSystem/Components/SettingsCard.swift`
- **Line:** 25
- **Current:** `colorScheme == .dark ? Color.clear : Color.settingsCardShadowColor.opacity(0.07)`
- **Expected:** Wrap in adaptive Color token `Color.adaptiveShadow` to avoid raw `colorScheme` branches
- **Category:** Dark Mode
- **Fix effort:** M

### 🟢 BreathingSessionView — Raw colorScheme branch in view body
- **File:** `Views/Breathing/BreathingSessionView.swift`
- **Line:** 97
- **Current:** `if colorScheme == .dark {`
- **Expected:** Extract dark/light difference into an adaptive Color or ViewModifier token
- **Category:** Dark Mode
- **Fix effort:** M

### 🟢 Multiple MINOR non-adaptive shadow sites
- **Files:** `CompactStressHeaderBar.swift`, `PrimaryMetricCard.swift`, `StressGaugeView.swift`, `CharacterGridCard.swift`, `MiniWalkInstructionCard.swift` (×2), `MiniWalkTimerRing.swift`
- **Current:** `.shadow(color: .black.opacity(N), ...)` — not adaptive
- **Expected:** Replace `.black` with `Color.primary` for light/dark adaptive shadow
- **Category:** Dark Mode
- **Fix effort:** S each

---

## 6. Spacing & Layout

### 🟡 ChatBottomSheetView — 20 hardcoded padding values (worst offender)
- **File:** `Views/Chat/ChatBottomSheetView.swift`
- **Lines:** 68, 112, 169, 176, 190, 201–204, 213–215, 233–234, 254, 313–314, 328
- **Current:** Mix of 8, 10, 12, 14, 16, 24, 32 literals; off-grid values 14pt, 10pt
- **Expected:** `Spacing.md` / `Spacing.sm` / `Spacing.lg` / `Spacing.xl` for all padding
- **Category:** Spacing
- **Fix effort:** L

### 🟡 ActionView — 13 hardcoded padding values with off-grid values
- **File:** `Views/Action/ActionView.swift`
- **Lines:** 120, 121, 166, 281, 359
- **Current:** `.padding(.horizontal, 10)`, `.padding(.vertical, 5)`, `.padding(18)`, `.padding(14)`; HStack spacings 6, 10, 14
- **Expected:** `Spacing.xs` / `Spacing.sm` / `Spacing.md` tokens; off-grid 18pt → `Spacing.md` (16) or `Spacing.lg` (24)
- **Category:** Spacing
- **Fix effort:** M

### 🟡 HealthStatCard — Sub-pixel / fractional spacing (Figma copy-paste)
- **File:** `Views/Dashboard/Components/HealthStatCard.swift`
- **Lines:** 14, 61–62, 77–78, 98
- **Current:** `VStack(spacing: 14.599)`, `HStack(spacing: 10.6)`, `.padding(.horizontal, 21.898)`, `.padding(.vertical, 10.949)`
- **Expected:** `Spacing.md` (16) for intra-card; all values must be whole integers to avoid sub-pixel blur
- **Category:** Spacing
- **Fix effort:** S

### 🟡 WatchMetricCard — Fractional spacing 14.599
- **File:** `Views/Dashboard/Components/WatchMetricCard.swift`
- **Lines:** 20, 83–84
- **Current:** `HStack(spacing: 14.599)`, `.padding(.horizontal, 21.898)`, `.padding(.vertical, 14.599)`
- **Expected:** `Spacing.sm` (8) or `Spacing.md` (16); snap to 8pt grid
- **Category:** Spacing
- **Fix effort:** S

### 🟡 WeekCalendarStrip — Fractional spacing 13.067 and padding 9.333
- **File:** `Views/Dashboard/Components/WeekCalendarStrip.swift`
- **Lines:** 23, 74
- **Current:** `HStack(spacing: 13.067)`, `.padding(9.333)`
- **Expected:** `Spacing.sm` (8) or `Spacing.md` (16); padding → `Spacing.xs` (4) or `Spacing.sm` (8)
- **Category:** Spacing
- **Fix effort:** S

### 🟡 DashboardView — Off-grid 22pt LazyVStack spacing
- **File:** `Views/DashboardView.swift`
- **Lines:** 34, 40
- **Current:** `LazyVStack(spacing: 22)`, `.padding(.horizontal, 16)`
- **Expected:** `LazyVStack(spacing: Spacing.lg)` // 24pt, `.padding(.horizontal, Spacing.md)`
- **Category:** Spacing
- **Fix effort:** S

### 🟢 MainTabView — Screen padding not using Spacing token
- **File:** `Views/MainTabView.swift`
- **Line:** 103
- **Current:** `.padding(.horizontal, 16)`
- **Expected:** `.padding(.horizontal, Spacing.md)`
- **Category:** Spacing
- **Fix effort:** S

### 🟢 SettingsView — Screen padding not using Spacing token
- **File:** `Views/Settings/SettingsView.swift`
- **Line:** 65
- **Current:** `.padding(.horizontal, 16)`
- **Expected:** `.padding(.horizontal, Spacing.md)`
- **Category:** Spacing
- **Fix effort:** S

### 🟢 NotificationsCard — Off-grid 5pt, 7pt, 10pt padding
- **File:** `Views/Settings/Components/NotificationsCard.swift`
- **Lines:** 47–48, 128–129
- **Current:** `.padding(.horizontal, 10)`, `.padding(.vertical, 5)`, `.padding(.vertical, 7)`, `.padding(.horizontal, 12)`
- **Expected:** `Spacing.xs` (4) or `Spacing.sm` (8) for small insets
- **Category:** Spacing
- **Fix effort:** S

### 🟢 SettingsCharacterStatusHeader — Off-grid 18pt padding
- **File:** `Views/Settings/Components/SettingsCharacterStatusHeader.swift`
- **Lines:** 46, 49
- **Current:** `.padding(8)`, `.padding(18)` — 18pt is off-grid
- **Expected:** `.padding(Spacing.sm)`, `.padding(Spacing.md)` // 18→16
- **Category:** Spacing
- **Fix effort:** S

### 🟢 WatchFaceCard / WidgetCard — HStack spacing 23pt off-grid
- **Files:** `Views/Settings/Components/WatchFaceCard.swift` (line 16), `Views/Settings/Components/WidgetCard.swift` (line 16)
- **Current:** `HStack(spacing: 23)`
- **Expected:** `HStack(spacing: Spacing.lg)` // 24pt
- **Category:** Spacing
- **Fix effort:** S

### 🟢 BreathingExerciseView — Off-grid 17pt horizontal padding (×2)
- **File:** `Views/Breathing/BreathingExerciseView.swift`
- **Lines:** 132, 158
- **Current:** `.padding(.horizontal, 17)`
- **Expected:** `.padding(.horizontal, Spacing.md)` // 16pt
- **Category:** Spacing
- **Fix effort:** S

### 🟢 IAPHeroSection — Off-grid 40pt and 11pt padding
- **File:** `Views/Premium/Components/IAPHeroSection.swift`
- **Lines:** 39, 47, 71
- **Current:** `.padding(.horizontal, 40)`, `.padding(.horizontal, 11)`
- **Expected:** `.padding(.horizontal, Spacing.xl)` or `Spacing.xxl`; 11pt → `Spacing.sm` (8) or `Spacing.md` (16)
- **Category:** Spacing
- **Fix effort:** S

### 🟢 Onboarding screens — Consistent 28pt padding without token
- **Files:** `Views/Onboarding/OnboardingWelcomeView.swift` (line 77), `Views/Onboarding/OnboardingHealthSyncView.swift` (line 131)
- **Current:** `.padding(.horizontal, 28)` — consistent across onboarding but no token backing it
- **Expected:** Add `Spacing.onboardingHorizontal = 28` token or snap to `Spacing.xl` (32)
- **Category:** Spacing
- **Fix effort:** S

### 🟢 Badge.swift (DesignSystem component) — Hardcoded 12pt/6pt chip padding
- **File:** `Views/DesignSystem/Components/Badge.swift`
- **Lines:** 20–21
- **Current:** `.padding(.horizontal, 12)`, `.padding(.vertical, 6)`
- **Expected:** Define `Spacing.badgePaddingH = 12` / `Spacing.badgePaddingV = 6` as named tokens (propagates to all Badge usages)
- **Category:** Spacing
- **Fix effort:** S

### 🟢 MeasurementDetailView — 7 hardcoded padding values
- **File:** `Views/History/MeasurementDetailView.swift`
- **Lines:** 31, 77–78, 102, 168, 186, 204
- **Current:** `.padding(20)` × 4, `.padding(.horizontal, 16)`, `.padding(.vertical, 8)`, `.padding(.vertical, 20)`
- **Expected:** `.padding(Spacing.cardPadding)`, `.padding(.horizontal, Spacing.md)`, `.padding(.vertical, Spacing.sm)`
- **Category:** Spacing
- **Fix effort:** S

---

## 7. Screen-by-Screen Status

| Screen | Folder | Files | Status | Key Issues |
|--------|--------|-------|--------|-----------|
| Dashboard | `Views/DashboardView.swift` + `Views/Dashboard/` | 40 | 🔴 NON_COMPLIANT | Raw Roboto in 10+ components; `Color.white` on 6+ cards; cat mascot in 3 files |
| Action | `Views/Action/` | 1 | 🟡 PARTIAL | `Color.white.opacity` borders not adaptive to light mode |
| Breathing | `Views/Breathing/` | 6 | 🔴 NON_COMPLIANT | Private `#85C9C9` teal tokens; `Color.white` screen background; 7+ raw `Color(red:)` values |
| MiniWalk | `Views/MiniWalk/` | 4 | 🔴 NON_COMPLIANT | `Roboto-MediumItalic` (undefined token); `Roboto-Bold` on timer display |
| Settings | `Views/Settings/` | 20 | 🟡 PARTIAL | `Color.white` in `NotificationsCard`; manual light/dark switch in `ComplicationWidget` |
| Trends | `Views/Trends/` | 18 | 🟡 PARTIAL | `Color.white.opacity` as surface/border tint broadly; wrong StressTier enum names and colors |
| History | `Views/History/` + `Views/HistoryView.swift` | 9 | 🟢 COMPLIANT | No critical issues found |
| Characters | `Views/Characters/` | 9 | 🟢 COMPLIANT | No critical issues found |
| Chat | `Views/Chat/` | 2 | 🟢 COMPLIANT | No critical issues found |
| Premium | `Views/Premium/` | 7 | 🔴 NON_COMPLIANT | `Color.white.ignoresSafeArea()` on full paywall screen and nav bar; `Color.white` CTA button |
| Journal | `Views/Journal/` | 1 | 🟢 COMPLIANT | No critical issues found |
| Onboarding | `Views/Onboarding/` | 11 | 🟡 PARTIAL | `Color.white.opacity` overlays on dark gradients; un-tokenized 28pt horizontal padding |

---

## Priority Fix List

### 🔴 CRITICAL (fix immediately)

1. **[Character] AIChatCard** — Replace `Image("AIKitten")` with `RippleMoodFace`/`StressBuddyIllustration`; rename CTA from "StressCat" to "Ripple" (`AIChatCard.swift:11`)
2. **[Character] SmartInsightsCard** — Replace `Image(systemName: "cat.fill")` with `RippleMoodFace` (`SmartInsightsCard.swift:37`)
3. **[Character] IntroMessageCard** — Replace `Image(systemName: "cat.fill")` with `RippleMoodFace` (`IntroMessageCard.swift:13`)
4. **[Character] PremiumBannerView** — Replace `Image("CharacterCalm")` (cat-era) with `StressBuddyIllustration` (`PremiumBannerView.swift:17`)
5. **[Character] PremiumBanner** — Replace cat mascot placeholder comment with actual Ripple asset (`PremiumBanner.swift:60`)
6. **[Color] BreathingExerciseView** — Delete private `tealLight`/`tealDark` tokens (#85C9C9/#73B9B9); migrate to `Color.Wellness.tealCard` or `#4FC3F7` (`BreathingExerciseView.swift:301–302`)
7. **[Color] NotificationsCard** — Replace `Color(hex: "85C9C9")` with `Color.settingsRippleBlue` in gradient (`NotificationsCard.swift:167`)
8. **[Color] SelfNoteCard** — Replace `Color(hex: "85C9C9")` with `Color.Wellness.tealCard` in gradient (`SelfNoteCard.swift:16`)
9. **[Color] BreathingExerciseView** — Replace `Color(red: 0.45, 0.45, 0.45)` with `Color.Wellness.adaptiveSecondaryText` (`BreathingExerciseView.swift:110`)
10. **[Color] BreathingExerciseView** — Replace `Color(red: 0.26, 0.26, 0.26)` with `Color.Wellness.adaptivePrimaryText` (`BreathingExerciseView.swift:140`)
11. **[Color] BreathingExerciseView** — Replace 4 hardcoded `BoxBreathingStep` `dotColor` raw `Color(red:)` values with wellness tokens (`BreathingExerciseView.swift:288`)
12. **[Color] BreathingSessionView** — Replace `Color(red: 0.1, 0.1, 0.15)` gradient stops with `Color.Wellness.backgroundDark` (`BreathingSessionView.swift:99`)
13. **[Typography] 15 files** — Replace all 48 raw `Font.custom("Roboto-*", size:)` calls with defined `Typography.roboto*` tokens; add missing tokens for `Roboto-Italic`, `Roboto-ExtraBold`, `Roboto-Medium`, `Roboto-MediumItalic`, `Roboto-Light` variants
14. **[Typography] RecommendationsCard, HealthStatCard, WeekCalendarStrip, StressSourcesCard, WatchMetricCard** — Remove fractional font sizes (23.723, 14.599, 12.13, 13.97, 11.99) causing production rendering defects

---

### 🟡 MAJOR (fix before release)

1. **[DarkMode]** Fix 23 non-adaptive `Color.white` / `Color.backgroundLight` background usages across Dashboard, Breathing, History, Trends, Premium, DesignSystem — replace with `Color.Wellness.adaptiveCardBackground` / `Color.Wellness.background`
2. **[DarkMode] IAPHeroSection + IAPNavBar** — `Color.white.ignoresSafeArea()` makes premium paywall fully light-mode-only (critical purchase path)
3. **[Character] RippleTrendsKit** — Rename `StressTier` enum cases from `calm/good/balanced/stressed/overwhelmed` to `veryCalm/calm/neutral/stressed/critical`
4. **[Character] RippleTrendsKit** — Fix `TrendsPalette` tier colors: Very Calm=`#4CAF50`, Calm=`#81C784`, Neutral=`#FFB74D`, Stressed=`#FF8A65`, Critical=`#E53935`
5. **[Character]** Incorporate `RippleMoodFace` or `StressBuddyIllustration` on Breathing, Action, and MiniWalk screens (therapeutic flows lack any Ripple presence)
6. **[Typography]** Audit and replace 264 hardcoded `.font(.system(size:))` calls — map to Typography token scale; add Dynamic Type support
7. **[Typography]** Restrict `design: .rounded` (SF Pro Rounded) to only `data*` tokens; remove from Settings, Character, and general UI contexts (57 unauthorized usages)
8. **[Component]** Migrate 32 files from manual `RoundedRectangle` card construction to `GlassCard` design system component
9. **[Component]** Route 51 inline `.shadow()` calls through `AppShadow` token helpers; add `AppShadow.accentGlow`, `AppShadow.breathingGlow` tokens for colored glows
10. **[Component] CharacterDetailView + EvolutionCelebrationView** — Replace `.buttonStyle(.borderedProminent)` with `PrimaryButton` / `ScaleButtonStyle` (3 instances)
11. **[Component]** Consolidate `PremiumBanner` (Dashboard) and `PremiumBannerView` (Trends) into a single shared component
12. **[Spacing] ChatBottomSheetView** — Replace 20 hardcoded padding values with `Spacing` tokens; eliminate off-grid 10pt and 14pt chip paddings
13. **[Spacing] ActionView** — Replace 13 hardcoded padding/spacing values; snap off-grid 5pt, 14pt, 18pt to 8pt grid tokens
14. **[Spacing] HealthStatCard, WatchMetricCard, WeekCalendarStrip** — Fix fractional spacing values (14.599, 10.6, 13.067, 9.333, 21.898) to prevent sub-pixel blur on non-3x displays

---

### 🟢 MINOR (housekeeping)

1. **[Color] Color.Wellness** — Promote `darkCanvas` (#0A0A0F) from local file-private constant in `RippleTrendsKit.swift` to `Color.Wellness.darkCanvas`
2. **[Color] Token deduplication** — Merge `textTertiary`/`iapTextMuted` (both #808080); merge `settingsAmberInfo`/`bannerYellow` (both #FFF4D6/#3A2A05); merge `iapWarmBackground` with `settingsBackground` light value
3. **[Color] Add `rippleBlue`** token to `Color.Wellness` for `#4FC3F7` — currently scattered as `settingsRippleBlue` and `accentTeal` with no canonical `Color.Wellness` entry
4. **[Color] Update `Color.Wellness.tealCard`** value from `#85C9C9` to `#4FC3F7` once Ripple blue migration is confirmed
5. **[Typography] Add `.monospacedDigit()`** to 6 numeric Text views: `BreathingSessionView` timer, `BreathingExerciseView` phase counter, `BreathingSummaryView` HRV values, `StressRingView` score, `CompactStressHeaderBar`, `HRVTrendCard` Y-axis labels
6. **[Character] StressOverTimeChart** — Update 3-tier legend to 5-tier spec labels and colors; remove `HomeCharacterDesignTokens.Blossom.accent` from stress tier coloring
7. **[Character] RippleTrendsKit** — Fix doc comment: tier 0–20 label should be "Very Calm" not "Calm"
8. **[Component] IAPHeroSection** — Replace `Color(hex: "24B9CC")` in glow shadow with `Color.iapHeaderTeal` token
9. **[Component]** Extract `.settingsCardDoubleShadow()` view modifier to de-duplicate the two-layer shadow pattern across 5 dashboard cards
10. **[Component] PrivacyCard** — Migrate to `SettingsCard { }` wrapper to match 9 other Settings subviews
11. **[DarkMode]** Replace 9 non-adaptive `.black.opacity(N)` shadow colors with `Color.primary.opacity(N)` across Breathing, Dashboard, Character, MiniWalk views
12. **[DarkMode]** Refactor raw `colorScheme == .dark` branches in `SettingsCard.swift` and `BreathingSessionView.swift` into adaptive Color tokens or ViewModifier
13. **[Spacing] Onboarding** — Add `Spacing.onboardingHorizontal = 28` token or snap to `Spacing.xl` (32) for `OnboardingWelcomeView` and `OnboardingHealthSyncView`
14. **[Spacing] Badge.swift** — Replace hardcoded 12pt/6pt chip padding with named tokens; violation propagates to all Badge usages
15. **[Spacing]** Replace remaining on-grid 16pt literals (`MainTabView`, `SettingsView`, `IAPPremiumView`, etc.) with `Spacing.md`
16. **[Spacing] ComplicationWidget** — Replace `VStack(spacing: 3)` / `VStack(spacing: 6)` with `Spacing.xs` minimum; `HStack(spacing: 23)` → `Spacing.lg`
17. **[Spacing] WatchFaceCard / WidgetCard** — `HStack(spacing: 23)` → `Spacing.lg`

---

*Total: 28 CRITICAL · 64 MAJOR · 53 MINOR across 149 Swift files*
