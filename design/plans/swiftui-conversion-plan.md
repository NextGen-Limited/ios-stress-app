# SwiftUI Conversion Plan — HTML Design System → iOS App

**Source of truth (HTML):** 27 screens tại `Open Design/projects/2af444ce-9930-4714-aae4-97f157003b49/screens/` + `css/app.css` + `design-system.html`
**Target (Swift):** `/Users/ddphuong/Projects/next-labs/ios-stress-app/StressMonitor/StressMonitor/`
**Date:** Jun 21, 2026 · **Author:** Phuong Doan · **Status:** Planning

---

## 1. Current iOS State (verified)

| Concern | Hiện tại | File citation |
|---|---|---|
| Min target | iOS 17+ / watchOS 10+ | `CLAUDE.md:75` |
| Architecture | MVVM + `@Observable` + Protocol-DI | `system-architecture-core.md` |
| State | `@Observable` ViewModels (11 files) | `ViewModels/` |
| Persistence | SwiftData (`StressMeasurement`, `CharacterUnlock`) + CloudKit | `StressMonitorSchema.swift` |
| Navigation | **3-tab** TabView (Home/Action/Trend) + Settings push từ Home gear | `Views/MainTabView.swift:11-36` |
| Algo | `MultiFactorStressCalculator` (5 factors: HRV/HR/Sleep/Activity/Recovery) | `Services/Algorithm/` |
| LLM | `SupabaseLLMService` (primary) + `AppleIntelligenceService` (fallback iOS 26+) | `Services/LLM/` |
| IAP | StoreKit 2 — monthly + annual + weekly | `Services/StoreKit/` |
| Character assets | **38 SVG files** với naming `{character}_{evolution}_{mood}.svg` + `CharacterAssetResolver` | `Models/Character/`, `Services/Character/` |
| Codebase size | 331+ Swift files · ~36K LOC · 250+ iOS app files | `INDEX.md` |
| Blocker | **B3** test suite rewrite (P0, chưa làm) | `KANBAN-SHIP-READINESS.md` |

**Theme tokens hiện có:**

| File | Có gì |
|---|---|
| `Theme/DesignTokens.swift` | Spacing (s1-s16) · Radius (sm/md/lg/xl/full) · Layout (minTouchTarget=44, navBarHeight=56, tabBarHeight=83) · Typography (xs-xs4) · Animation. **Đã aligned với CSS `:root`.** |
| `Theme/Color+Wellness.swift` | **Legacy** calmBlue/healthGreen/gentlePurple palette — không dùng trong redesign |
| `Theme/Color+Extensions.swift` | **Đã có redesign tokens** dòng 188-206: `inkPrimary #101223`, `muted #777986`, `appBackground #F2F2F7`, `rippleDim/rippleGlow`, `charRippleAccent #4FC3F7`, `charBlossomAccent #A5D6A7`, `charEmberAccent #FFAB91`, `charZephyrAccent #D1C4E9`, `charLumiAccent #7986CB`, `premiumGold #FE9901`, IAP palette. **Đã mirror CSS.** |
| `Theme/Font+WellnessType.swift` | **Legacy** Roboto + SF Pro fallback. **Phải migrate sang SF Pro system fonts.** |
| `Theme/HomeCharacterDesignTokens.swift` | Ripple/Blossom/Ember/Zephyr/Lumi palette (duplicate của Color+Extensions, dùng cho gradient hero) |

**Components hiện có** (`Views/Components/`):

| Component | File | Tình trạng |
|---|---|---|
| `TideGaugeView` | `TideGaugeView.swift` (39 LOC) | ✅ Có — vertical 18px×180px gauge. Cần **resize 140px** + thêm semicircle + oval variants |
| `CharCompanionCard` | `CharCompanionCard.swift` (50 LOC) | ⚠️ Dùng `character.element.emoji` — phải chuyển sang SVG render qua `CharacterAssetResolver` |
| `StreakBarView` | `StreakBarView.swift` (41 LOC) | ⚠️ Dùng 🔥 emoji — phải đổi sang `Image(systemName: "flame.fill")` |
| `SettingsGroupView` | `SettingsGroupView.swift` (27 LOC) | ✅ iOS grouped list lineage OK |
| `InsightCardView`, `MeasureButton`, `MetricTileView`, `PillSelectorView`, `StressBadgeView`, `QuickActionTile`, `ChipView`, `PrimaryMetricCard`, `DailyTipCard`, `HapticManager`, `MiniHistoryBars`, `DemoModeBannerView`, `ButtonStyles`, `ChatBubbleView` | — | Mix of legacy + redesign-ready — cần audit per-cluster |
| `TabBar/` | `TabItem.swift`, `AnimatedTabButtons.swift`, `TabBarScrollState.swift` | ⚠️ Tab icons dùng PNG `Image("\(tab.iconName)-selected")` — phải đổi sang SF Symbols |

---

## 2. Gap Analysis — HTML Design ↔ iOS Code

| # | Topic | HTML Design (source) | iOS current (target) | Action |
|---|---|---|---|---|
| G1 | **Tab count** | **4-tab** (Home/Action/Trends/Settings) | 3-tab + Settings push | Convert `MainTabView` thêm Settings tab |
| G2 | **Typography** | SF Pro Display + SF Pro Text + SF Pro Rounded (character moments) | Roboto qua `Font.WellnessType` | Migrate sang `Font.system(.title, design: .rounded)` etc. |
| G3 | **Stress levels** | **5-tier** (Relaxed/Mild/Moderate/High/Severe) | 4-tier `StressCategory` (no severe) | Thêm `.severe` case + color `#FF3B30` + icon + pattern |
| G4 | **Character render** | Inline SVG illustrated (~30 shapes/char) | Emoji `character.element.emoji` | Dùng `CharacterAssetResolver` + SVG asset (`Image(character_${e}_${m})`) |
| G5 | **Tide gauge size** | 140px (redesign 04-home) | 180px (`barHeight: CGFloat = 180`) | Parametrize `TideGaugeView(barHeight:)` |
| G6 | **Gauge shapes** | 3 variants: tide (vertical) · semicircle (arc) · oval (horizontal) | Chỉ tide | Thêm `SemicircleGaugeView` + `OvalGaugeView` |
| G7 | **Emoji as UI icon** | ZERO (SF Symbol-style SVG only) | 🔥 trong StreakBar, 😴 emoji mood, character emoji | Replace toàn bộ emoji UI bằng SF Symbols |
| G8 | **Tab icons** | SF Symbol lineage (house/plus.circle/chart.bar/gearshape) | PNG-based Image | Đổi sang `Image(systemName:)` |
| G9 | **Settings background** | `#F2F2F7` (appBackground, match Home) | `#FFFDF6` warm cream (`Color.settingsBackground`) | Đổi sang `Color.appBackground` |
| G10 | **Empty states** | 2 screens: `04-home-no-health.html` + `04-home-no-data.html` | Không có | Thêm 2 empty state views branch trong `DashboardView` |
| G11 | **Premium banner** | Frosted glass banner giữa Home screen | Không có trên dashboard | Thêm `PremiumBannerView` component |
| G12 | **Habits tracking** | 3 rows: Hydration/Caffeine/Sunlight với progress + AUTO/LOG source pills | Không có model/view | Thêm `Habit` model + `HabitLogView` component |
| G13 | **Mood check-in** | 5 mood chips (◌◎◐◑●) | Không có | Thêm `MoodCheckInView` component + `MoodEntry` model |
| G14 | **Bio Age** | Bio age card trên Home + BioAge detail screen | `BioAgeResult` model + `BioAgeCalculator` service đã có | Wire `BioAgeCardView` (đã có trong `Views/Dashboard/Components/`) |
| G15 | **Measure button** | **REMOVED** trong redesign (FAB gone) | `MeasureButton.swift` còn dùng | Deprecate / remove khỏi DashboardView |

---

## 3. Cluster Tổ chức (10 clusters)

```
P0 (Foundation + Core tabs):
  Cluster 1 — Foundation: Design system + Navigation + Tabbar
  Cluster 2 — Onboarding & Empty States
  Cluster 3 — Home (DashboardView + 3 states + premium banner)

P1 (Secondary tabs + Flows):
  Cluster 4 — Action tab
  Cluster 5 — Trends tab
  Cluster 6 — Settings tab (now first-class tab)
  Cluster 7 — Measure flow + History + Bio Age detail
  Cluster 8 — Breathing + Mini Walk

P2 (Secondary features):
  Cluster 9 — Characters (Collection + Detail + Celebration)
  Cluster 10 — IAP + Data Management + Misc Settings
```

---

## 4. Plan chi tiết theo Cluster

### Cluster 1 — Foundation (P0, Effort: M)

**Scope:** Design system tokens + 4-tab navigation + tabbar SF Symbol icons + stress category extension.

**Files to modify:**

| File | Action |
|---|---|
| `Theme/Font+WellnessType.swift` | **REWRITE** — bỏ Roboto, dùng SF Pro: `.system(.largeTitle, design: .default)` cho display, `.system(.body)` cho body, `.system(.title, design: .rounded)` cho character moments. Giữ `accessibleWellnessType()` modifier. |
| `Theme/Color+Wellness.swift` | **DEPRECATE** calmBlue/healthGreen palette (move to deprecated section). Giữ adaptive surfaces. |
| `Theme/Color+Extensions.swift` | **EXTEND** thêm `stressSevere` đã có — verify dòng 40 |
| `Models/StressCategory.swift` | **ADD** `.severe` case + `color #FF3B30`, `icon "exclamationmark.octagon.fill"`, `pattern "solid warning"`. **Risk:** toàn bộ `switch self` trong StressCategory phải update. |
| `Views/MainTabView.swift` | **REWRITE** — đổi từ 3 Tab → 4 Tab. Settings giờ là `Tab(value: TabItem.settings) { NavigationStack { SettingsView() } }`. Remove `showSettings` state + `navigationDestination(isPresented:)`. |
| `Views/Components/TabBar/TabItem.swift` | **ADD** `.settings` case với SF Symbol `gearshape` |
| `Views/Components/TabBar/AnimatedTabButtons.swift` | **REFACTOR** — đổi `Image("\(tab.iconName)-selected")` sang `Image(systemName: selectedTab == tab ? tab.sfSymbolActive : tab.sfSymbol)`. Tabs: home→`house`/`house.fill`, action→`plus.circle`/`plus.circle.fill`, trend→`chart.bar`/`chart.bar.fill`, settings→`gearshape`/`gearshape.fill`. |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Components/Gauges/SemicircleGaugeView.swift` | Half-arc gauge (r=70, stroke 12). Math: `arc length = π·r`, `dashoffset = arc × (1 - score/100)`. Endpoint tick mark tại `(cx + r·cos(angle), cy - r·sin(angle))`. |
| `Views/Components/Gauges/OvalGaugeView.swift` | Horizontal pill gauge, same vocabulary as TideGaugeView rotated 90°. |

**Components modify:**

| Component | Action |
|---|---|
| `Views/Components/TideGaugeView.swift` | Parametrize `barHeight: CGFloat = 140` (match HTML redesign). Keep all gradient stops. |

**Acceptance criteria:**
- [ ] 4 tabs render đúng, Settings là tab độc lập
- [ ] Tab icons dùng SF Symbols (zero PNG)
- [ ] `TideGaugeView(position: 0.42)` render đúng tại 42%
- [ ] `SemicircleGaugeView(score: 42)` render arc 42% + endpoint tick
- [ ] `StressCategory.severe.color == #FF3B30`
- [ ] Build success without warnings
- [ ] Existing tests still pass (run `BioAgeCalculatorTests`, `StressCalculatorTests`)

**Risks:**
- **R1.1** — Adding `.severe` breaks existing switch statements. **Mitigate:** Grep toàn bộ `switch.*category` + `case .high:` để update.
- **R1.2** — Tab icon swap breaks `AnimatedTabButtons` animation. **Mitigate:** Keep current animation API, only swap icon source.

---

### Cluster 2 — Onboarding & Empty States (P0, Effort: M)

**Scope:** 3 onboarding screens (Welcome · HealthKit Permission · Success) + 2 empty state variants of Home.

**Files to modify:**

| File | Action |
|---|---|
| `Views/Onboarding/OnboardingWelcomeView.swift` | **REFACTOR** — match `01-welcome.html`: hero illustration (Ripple curious mood SVG) + value prop + "Get Started". Replace generic text với real copy từ HTML. |
| `Views/Onboarding/OnboardingHealthSyncView.swift` | **REFACTOR** — match `02-health-permission.html`: 4 data types list (HRV/HR/Sleep/Steps) + privacy pill "ON-DEVICE" + "Connect Apple Health" CTA. |
| `Views/Onboarding/OnboardingSuccessView.swift` | **REFACTOR** — match `03-onboarding-complete.html`: Ripple unlock visual + 7d trial + "Start tracking" CTA. |
| `Views/Onboarding/OnboardingStepLayout.swift` | **EXTEND** — thêm variant cho empty state layout (centered hero + bottom CTA) |
| `Views/Dashboard/DashboardView.swift` | **BRANCH** — render 1 trong 3 states: `.noHealthKit` (match `04-home-no-health.html`), `.reading` (match `04-home-no-data.html`), `.data(viewModel)` (current). Branch dựa trên `viewModel.healthKitState`. |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Onboarding/Components/PermissionHeroCard.swift` | Ripple 120px curious mood + eyebrow STEP x OF 3 + title + 4 data types list + privacy pill + CTA + skip link |
| `Views/Onboarding/Components/ReadingHeroCard.swift` | Progress arc 38% + Ripple 70px breathing mood (closed-eye arcs, breath aura) + ETA chip "30-60 seconds" |
| `Views/Components/SkeletonCard.swift` | Shimmer placeholder với `redacted(reason: .placeholder)` + custom gradient animation. Heights match real cards để tránh layout jump. |
| `Views/Components/PulseDotIndicator.swift` | 3 pulse dots animation cho "READING" chip, respects `prefersReducedMotion` |

**Models:**
- **NO new models** — `viewModel.healthKitState: HealthKitState` enum mới (`.notDetermined`, `.denied`, `.reading`, `.ready`)

**Acceptance criteria:**
- [ ] Welcome → HealthKit → Success flow mượt
- [ ] DashboardView render `PermissionHeroCard` khi chưa grant HealthKit
- [ ] DashboardView render `ReadingHeroCard` + 3 skeleton cards trong 30-60s đầu
- [ ] Skeleton shimmer respects `accessibilityReduceMotion`
- [ ] Tap "Connect Apple Health" → mở `HKAuthorizationRequestController`

**Risks:**
- **R2.1** — Onboarding chưa integrate properly (per `KANBAN H1`). **Mitigate:** Wire `@AppStorage("hasCompletedOnboarding")` check trong `StressMonitorApp.swift` hoặc `MainTabView.onAppear`.
- **R2.2** — CharacterAssetResolver chưa support `curious` / `breathing` moods. **Mitigate:** Extend enum + thêm SVG assets nếu missing (verify trong `Assets.xcassets/Characters/`).

---

### Cluster 3 — Home (DashboardView) (P0, Effort: L)

**Scope:** Redesign DashboardView theo `04-home.html` (9 sections) + premium banner.

**Files to modify:**

| File | Action |
|---|---|
| `Views/DashboardView.swift` (231 LOC) | **REWRITE body** — 9 sections theo HTML redesign: (1) Date row + 2 status chips, (2) Hero semicircle arc + Ripple inside arc opening, (3) AI insight, (4) Vitals triplet HRV/HR/RR, (5) Mood check-in chips, (6) Health data Exercise/Sleep/Daylight, (7) Quick actions Box Breathing + Mini Walk, (8) Stress over time bar chart 7d, (9) Premium banner. **Remove** `MeasureButton` usage + `QuickActionsGrid` (replace bằng #7). |
| `Views/Dashboard/DashboardViewModel.swift` | **EXTEND** — thêm `rr: Double?` (respiratory rate), `sleep: SleepData?`, `exercise: ActivityData?`, `daylight: TimeInterval?`, `mood: MoodEntry?` |
| `Views/Dashboard/Components/BioAgeCardView.swift` | **KEEP** — đã có |

**Components new:**

| Component | Purpose | HTML ref |
|---|---|---|
| `Views/Dashboard/Components/ArcStage.swift` | Semicircle arc 180×90 với Ripple 70px nested bên trong opening | `04-home.html` hero |
| `Views/Dashboard/Components/VitalsTriplet.swift` | HRV / HR / RR vertical hairline dividers, mỗi vital có trend context "+8 vs avg" | `04-home.html` section 4 |
| `Views/Dashboard/Components/MoodCheckInView.swift` | 5 mood chips ◌◎◐◑● tier-colored, active state với fill | `04-home.html` section 5 |
| `Views/Dashboard/Components/HealthDataRow.swift` | Exercise / Sleep / Daylight với SF Symbol icon + value + delta | `04-home.html` section 6 |
| `Views/Dashboard/Components/QuickActionCard.swift` | Box Breathing blue + Mini Walk green, 2 cards grid | `04-home.html` section 7 |
| `Views/Dashboard/Components/StressChart7d.swift` | Bar chart 7 ngày thật với gridlines 25/50/75, today outlined | `04-home.html` section 8 |
| `Views/Dashboard/Components/PremiumBanner.swift` | Frosted glass banner (`.ultraThinMaterial` + `blur`) với 3 character heads peek + copy + chevron → push `IAPPremiumView` | `04-home.html` section 9 |
| `Views/Components/StatusChip.swift` | Reusable chip: bio / streak / waiting / reading variants |

**Models new:**

```swift
// Models/MoodEntry.swift
enum MoodLevel: Int, CaseIterable, Codable { case veryCalm=1, calm, neutral, tense, veryTense }
struct MoodEntry: Identifiable, Codable {
    let id: UUID; let timestamp: Date; let level: MoodLevel
}
```

**Acceptance criteria:**
- [ ] DashboardView render 9 sections đúng thứ tự
- [ ] Semicircle arc gauge fill đúng score (verified: dashoffset 127.55 = 219.91 × 0.58 cho score 42)
- [ ] Ripple 70px nested bên trong arc opening
- [ ] VitalsTriplet show HRV 52ms / HR 68bpm / RR 16 (respiratory rate default)
- [ ] Premium banner tap → `path.append(Route.paywall)` hoặc sheet
- [ ] No emoji as UI icon (✓ verified: ◌◎◐◑● là unicode stress vocabulary không phải emoji)
- [ ] Cross-screen consistency: Alex · Tue Apr 22 9:32 AM · bio 26/28 · streak 7d

**Risks:**
- **R3.1** — RR (respiratory rate) không có trong HealthKitManager. **Mitigate:** Add `fetchRespiratoryRate()` extension hoặc skip nếu không available (graceful degradation).
- **R3.2** — Daylight metric cần iOS 15+ `HKQuantityTypeIdentifier.timeInDaylight`. **Mitigate:** Already iOS 17+ target → OK.

---

### Cluster 4 — Action tab (P1, Effort: M)

**Scope:** Redesign ActionView theo `05-action.html` (6 sections).

**Files to modify:**

| File | Action |
|---|---|
| `Views/Action/ActionView.swift` | **REWRITE** — 6 sections: (1) Header "What helps right now" + eyebrow Mild 42·2:14 PM, (2) Ripple recommendation hero, (3) Breathe group, (4) Move group, (5) Reflect group, (6) Today's habits. Replace bento grid + dark-canvas theme bằng light theme iOS grouped lists. |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Action/Components/RippleRecommendationCard.swift` | Ripple 84px + voice + inline CTA + tint border Ripple blue |
| `Views/Action/Components/ActionGroupRow.swift` | iOS grouped list row: SF Symbol icon + title + subtitle + chevron |
| `Views/Action/Components/HabitLogRow.swift` | Habit row: icon + label + AUTO/LOG source pill + progress bar + value + chevron |

**Models new:**

```swift
// Models/Habit.swift
enum HabitSource: String, Codable { case auto, manual } // AUTO / LOG
struct Habit: Identifiable, Codable {
    let id: UUID
    let type: HabitType  // .hydration, .caffeine, .sunlight
    var currentValue: Double
    var goalValue: Double?
    var source: HabitSource
}
enum HabitType: String, CaseIterable, Codable { case hydration, caffeine, sunlight }
```

**ViewModels:**
- **NEW** `ViewModels/HabitViewModel.swift` — quản lý `@Observable var habits: [Habit]` + persistence (UserDefaults hoặc SwiftData `@Model`).

**Acceptance criteria:**
- [ ] 6 sections render đúng
- [ ] Habit rows: Hydration 70% (1.4/2.0L), Sunlight 84% (42/50min), Caffeine "2 cups" text-only
- [ ] Source pills: AUTO tinted accent-soft blue, LOG tinted neutral
- [ ] Tap Box Breathing → push `BreathingExerciseView`
- [ ] No gradient bento tiles, no icon-wrap circles

---

### Cluster 5 — Trends tab (P1, Effort: M)

**Scope:** Redesign TrendsView theo `06-trends.html` (6 sections).

**Files to modify:**

| File | Action |
|---|---|
| `Views/Trends/TrendsView.swift` | **REWRITE** — 6 sections: (1) Editorial summary "18% calmer. Hardest day Sat (62), best Mon (18).", (2) Daily stress bars 7d với date labels, (3) Distribution stacked bar 29/43/28%, (4) Calendar heatmap full month circles, (5) HRV trend line với avg reference + endpoint halo, (6) Editorial insight. |
| `Views/Trends/TrendsViewModel.swift` | **EXTEND** — thêm `distribution: StressDistribution` (computed từ `weeklyStressValues`), `monthlyCalendar: [Day?]` (verified 30 days), `hrvAvg: Double` (= 52 baseline) |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Trends/Components/DistributionBar.swift` | Stacked horizontal bar + legend với verified math (29+43+28=100%) |
| `Views/Trends/Components/MonthlyCalendarHeatmap.swift` | 5 weeks × 7 days grid với circles stress-color, today outlined |
| `Views/Trends/Components/HRVTrendChart.swift` | SVG line chart + avg reference line dashed + endpoint halo dot |

**Acceptance criteria:**
- [ ] Math verified: bars sum 288/7=41 · distribution 29+43+28=100%
- [ ] Calendar circles Apple-Cal lineage
- [ ] HRV reference line tại 52ms
- [ ] No `.cc-avg` giant number stat-tile
- [ ] Editorial summary có real context (Sat 62, Mon 18)

---

### Cluster 6 — Settings tab (P1, Effort: M)

**Scope:** Redesign SettingsView theo `10-settings.html` (8 sections) + Settings as first-class tab.

**Files to modify:**

| File | Action |
|---|---|
| `Views/Settings/SettingsView.swift` | **REWRITE** — 8 sections theo HTML redesign: (1) Me-hero consolidated card (avatar + name + Plus pill + 3-metric snapshot Bio/Stress/Streak), (2) Active companion banner (Ripple mini 44px), (3) Companion group, (4) Sync & devices, (5) Habits & tracking with progress bars, (6) Notifications, (7) Preferences (merged Membership + Widgets), (8) Data & support. **Critical:** đổi background từ `Color.settingsBackground` warm cream sang `Color.appBackground` (#F2F2F7) cho cross-screen consistency. |
| `Views/Settings/SettingsViewModel.swift` | **EXTEND** — thêm `habits: [Habit]` (match Cluster 4), `activeCompanion: CharacterCreature` |
| `Views/Settings/Components/ProfileCard.swift` | **REFACTOR** — thành Me-hero card. Bỏ gradient avatar, dùng flat surface + hairline 0.5px border + initial "A" accent color. |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Settings/Components/MeHeroCard.swift` | Consolidated: avatar + name/email + Plus pill top / 3-metric snapshot bottom (Bio 26 · 42 Mild · 7d) với vertical hairline dividers |
| `Views/Settings/Components/CompanionBanner.swift` | Ripple mini 44px SVG + eyebrow ACTIVE COMPANION + "Ripple · Water Otter" + Switch link |
| `Views/Settings/Components/HabitProgressRow.swift` | Reuse từ Cluster 4 HabitLogRow (chia sẻ component) |
| `Views/Settings/Components/PlusPill.swift` | Tinted pill (gold #FE9901 14% opacity) + "Plus" text + "Try free ›" link |
| `Views/Settings/Components/SourcePill.swift` | AUTO (accent-soft blue tinted) / LOG (neutral) — pill radius 999px |

**Acceptance criteria:**
- [ ] Settings tab active khi selected (không còn Home active workaround)
- [ ] Background = `Color.appBackground` (#F2F2F7)
- [ ] All grouped rows single-line (no chevron wrap) — cần flex layout hoặc `HStack` với `Spacer()` thay vì grid
- [ ] Habit progress bars functional (water 70%, sunlight 84%)
- [ ] Plus pill type-led (no gradient, no icon-wrap circle)

**Bug fix:** Fix layout bug ở HTML version (chevron xuống dòng) — Swift dùng `HStack { ... Spacer() }` tự nhiên không bug.

---

### Cluster 7 — Measure flow + History + Bio Age detail (P1, Effort: M)

**Scope:** 4 screens — Measurement Result (`07-measurement.html`), History Timeline (`11-history.html`), Measurement Detail (`12-measurement-detail.html`), Bio Age Detail (`18-bio-age.html`).

**Files to modify:**

| File | Action |
|---|---|
| `Views/History/MeasurementDetailView.swift` | **REFACTOR** — match `12-measurement-detail.html`: big stress score + category + 5-factor breakdown bars + confidence + stress gauge. Sử dụng `factorBreakdown: FactorBreakdown` đã có trong `StressResult`. |
| `Views/History/MeasurementHistoryView.swift` | **REFACTOR** — match `11-history.html`: chronological list + date/category filter chips + tap row → push `MeasurementDetailView`. |
| `Views/History/HistoryViewModel.swift` | **EXTEND** — thêm `filter: HistoryFilter` (date range, category) |
| `Views/Dashboard/Components/BioAgeCardView.swift` | **KEEP** — đã có |
| **NEW** `Views/History/BioAgeDetailView.swift` | Match `18-bio-age.html`: bio age big number + delta vs chronological + 7-day min + 3 input cards (HRV / HR / Sleep) + algorithm explainer |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/History/Components/FactorBreakdownRow.swift` | Per-factor row: icon + name + bar (weight %) + value + confidence |
| `Views/History/Components/StressGaugeMini.swift` | Semicircle gauge mini variant cho history rows |
| `Views/History/Components/DateFilterChip.swift` | 7d / 30d / 90d / All chips |
| `Views/History/Components/CategoryFilterChip.swift` | Relaxed/Mild/Moderate/High/Severe chips toggle |

**Acceptance criteria:**
- [ ] MeasurementDetailView show 5 factors với weight bars
- [ ] HistoryView filter by date range + category
- [ ] BioAgeDetailView show real `BioAgeResult` data (HRV/HR/Sleep inputs)
- [ ] Cross-screen: bio age 26 (chrono 28) consistent với Home + Settings

---

### Cluster 8 — Breathing + Mini Walk (P1, Effort: M)

**Scope:** 4 screens — Breathing Intro (`13-breathing-intro.html`), Breathing Active (`08-breathing-active.html`), Breathing Summary (`14-breathing-summary.html`), Mini Walk (`15-walk.html`).

**Files to modify:**

| File | Action |
|---|---|
| `Views/Breathing/BreathingExerciseView.swift` | **REFACTOR** intro mode — match `13-breathing-intro.html`: 4-4-4-4 pattern explainer + before HRV + "Begin" |
| `Views/Breathing/BreathingSessionView.swift` | **REFACTOR** active mode — match `08-breathing-active.html`: animated breathing circle + phase label "INHALE 4s" + timer + progress ring + Ripple breathing mood side |
| `Views/Breathing/BreathingSummaryView.swift` | **REFACTOR** summary — match `14-breathing-summary.html`: session stats + before/after HRV chart + effectiveness "14 ms saved" + Ripple serene mood |
| `Views/Breathing/BreathingViewModel.swift` | **EXTEND** — thêm `phase: BreathingPhase` enum (.inhale, .holdIn, .exhale, .holdOut) + `secondsRemaining: Int` |
| `Views/MiniWalk/MiniWalkView.swift` | **REFACTOR** — match `15-walk.html`: circular timer + step count + pace + pause/stop controls |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Breathing/Components/BreathingCircle.swift` | Animating circle: scale 0.6↔1.0 theo phase + color tint theo phase + breath aura concentric arcs |
| `Views/Breathing/Components/PhaseLabel.swift` | Large SF Pro Rounded "INHALE" 4s countdown |
| `Views/Breathing/Components/BeforeAfterHRVChart.swift` | 2-bar comparison chart trước/sau HRV |
| `Views/MiniWalk/Components/WalkTimer.swift` | Circular timer với step count center + pace below |

**Acceptance criteria:**
- [ ] Box breathing 4-4-4-4 loop mượt
- [ ] `BreathingCircle` scale animation respects `prefersReducedMotion`
- [ ] Summary show "14 ms HRV lift" (real delta từ before/after)
- [ ] Mini Walk timer pause/resume đúng

---

### Cluster 9 — Characters (P2, Effort: M)

**Scope:** 3 screens — Character Collection (`16-characters.html`), Character Detail (`17-character-detail.html`), Evolution Celebration (implicit). Plus AI Chat (`09-chat.html`) grouped here vì Ripple Coach.

**Files to modify:**

| File | Action |
|---|---|
| `Views/Characters/CharacterCollectionView.swift` | **REFACTOR** — match `16-characters.html`: grid 5 characters với unlock status (free/premium/streak) + evolution stage dots + tap → push `CharacterDetailView` |
| `Views/Characters/CharacterDetailView.swift` | **REFACTOR** — match `17-character-detail.html`: hero character 160px + 3 evolution stages row + 5 mood previews + unlock progress bar + "Set as active" CTA |
| `Views/Characters/EvolutionCelebrationView.swift` | **KEEP/EXTEND** — verify match concept (Ripple evolves → Droplet→Ripple→Tidal) |
| `Views/Chat/ChatBottomSheetView.swift` | **REFACTOR** — match `09-chat.html`: bottom sheet + message stream + 4 quick action chips + Ripple avatar với mood state reactive |

**Components modify:**

| Component | Action |
|---|---|
| `Views/Components/CharCompanionCard.swift` | **REWRITE** — bỏ emoji, dùng `Image(uiImage: CharacterAssetResolver.shared.image(for: character, evolution: .stage1, mood: .serene))` hoặc `Image("Ripple_stage1_serene")` trực tiếp từ asset catalog |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Characters/Components/CharacterGridCard.swift` | Grid card: character SVG + name + element + unlock badge (free/Plus/30d) + evolution dots |
| `Views/Characters/Components/EvolutionStageRow.swift` | Horizontal row 3 stages: small character SVG + stage name + state (unlocked/locked) |
| `Views/Characters/Components/MoodPreviewButton.swift` | 5 mood preview circles trong character detail |

**Services:**
- **VERIFY** `Services/Character/CharacterAssetResolver.swift` đã có — check API: `image(for:evolution:mood:)` trả về asset name. Nếu chưa có mood variants cho curious/breathing → extend.

**Acceptance criteria:**
- [ ] 5 characters render với real SVG (Ripple/Blossom free, Ember/Zephyr Plus, Lumi@30d)
- [ ] Tap character → push detail với 3 evolution stages
- [ ] Premium characters locked behind StoreKit entitlement check
- [ ] Chat sheet render Ripple avatar với mood = stress state (serene khi Mild, furrowed khi High)
- [ ] Zero emoji in character rendering

---

### Cluster 10 — IAP + Data Management + Misc Settings (P2, Effort: L)

**Scope:** 7 screens — Paywall (`19-paywall.html`), Purchase Success (`20-purchase-success.html`), Data Export (`21-export.html`), Data Management (`22-manage.html`), Appearance (`23-appearance.html`), Watch Face (`24-watch-face.html`), About (`25-about.html`).

**Files to modify:**

| File | Action |
|---|---|
| `Views/Premium/IAPPremiumView.swift` | **REWRITE** — match `19-paywall.html`: (1) Hero Ripple transformation (stressed→serene 2 mini SVGs side-by-side), (2) Features list lead với Trends (không phải realtime), (3) 3-tier pricing (Annual $4.99/mo SAVE 45% · Monthly $7.99 "Most Popular" · Weekly $2.99), (4) CTA "Start 7-day free trial", (5) Credibility row (4.8★ + iOS 17 + Family Sharing). **NO countdown timer** (Apple HIG). |
| `Views/Premium/Components/` (folder) | Audit existing components vs HTML — likely cần rewrite PlanCard, TrustRow, CTAButton |
| **NEW** `Views/Premium/PurchaseSuccessView.swift` | Match `20-purchase-success.html`: confirmation + unlocked characters (Ember/Zephyr/Lumi SVGs) + "Restore" + back to Home |
| **NEW** `Views/Settings/DataManagement/DataExportView.swift` | Match `21-export.html`: format picker (CSV/JSON) + date range + share |
| **NEW** `Views/Settings/DataManagement/DataManageView.swift` | Match `22-manage.html`: delete by range/category/all + confirmation dialog |
| **NEW** `Views/Settings/AppearanceSettingsView.swift` | Match `23-appearance.html`: Light/Dark/System + text size + haptics toggle |
| **NEW** `Views/Settings/WatchFacePreferencesView.swift` | Match `24-watch-face.html`: background style picker + sync status |
| **NEW** `Views/Settings/AboutView.swift` | Match `25-about.html`: version + privacy + open source + contact |

**Components new:**

| Component | Purpose |
|---|---|
| `Views/Premium/Components/RippleTransformationHero.swift` | 2 Ripple SVGs side-by-side: High state (furrowed brows, sweat drop) → Serene state (closed eyes, smile). Caption: "From frazzled to focused — in 2 minutes." |
| `Views/Premium/Components/PlanCard.swift` | Pricing tier card: name + price + period + "SAVE 45%" badge + "Most Popular" pill + select state |
| `Views/Premium/Components/TrustRow.swift` | Row: SF Symbol icon + text ("4.8★ from 12K users" / "Designed for iOS 17" / "Family Sharing") |
| `Views/Settings/Components/FormatPickerRow.swift` | CSV / JSON radio selection |
| `Views/Settings/Components/DeleteConfirmationSheet.swift` | Destructive action confirmation sheet với "Delete permanently" red button |

**ViewModels:**
- `PremiumViewModel.swift` đã có — extend với `selectedPlan: SubscriptionPeriod?`, `isTrialAvailable: Bool`
- `DataManagementViewModel.swift` đã có — verify API `export(format:dateRange:)` + `deleteAll()` + `deleteRange(start:end:)`

**Acceptance criteria:**
- [ ] Paywall: monthly "Most Popular" badge per Stresswatch contrarian anchor research
- [ ] 7-day trial advertised rõ (not hidden like Stresswatch weakness)
- [ ] No countdown timer (HIG compliance)
- [ ] Purchase Success unlocks Ember/Zephyr/Lumi trong `CharacterUnlock` SwiftData
- [ ] Data Export generates real CSV/JSON via `DataExporter` service
- [ ] Data Manage destructive action requires double confirmation
- [ ] Cross-screen: pricing $4.99/$7.99/$2.99 consistent across paywall + premium banner

---

## 5. Cross-Cluster Consistency Rules

### 5.1 Data consistency (must hold across all clusters)

| Field | Value | Set in |
|---|---|---|
| User name | Alex Chen | `SettingsViewModel.userProfile.name` |
| Email | alex.chen@icloud.com | `SettingsViewModel.userProfile.email` |
| Chronological age | 28 | Computed from `userProfile.birthDate` |
| Bio age | 26 (= 28 − 2) | `BioAgeCalculator` |
| Streak | 7 days (23 to Lumi@30) | `StreakCalculator` |
| Today's stress | 42 Mild | `StressViewModel.currentStress` |
| HRV baseline | 52ms | `PersonalBaseline.hrvBaseline` |
| HR resting | 68 bpm | `PersonalBaseline.restingHR` |
| Active companion | Ripple (Water Otter, free) | `CharacterCollectionViewModel.activeCharacter` |
| Date context | Tuesday April 22, 2026, 9:32 AM | System date (demo mode fixed) |
| Plus subscription | Not subscribed (until Paywall cluster) | `PremiumState.shared.isPremium` |

### 5.2 Component reuse map

| Component | Used by clusters |
|---|---|
| `TideGaugeView` | 3 (Home hero option) |
| `SemicircleGaugeView` | 3 (Home hero), 7 (Measurement Detail) |
| `OvalGaugeView` | 7 (History rows mini) |
| `RippleIllustration` (new) | 1 (foundation), 2 (onboarding), 3 (home), 4 (action), 8 (breathing), 9 (characters), 10 (paywall) |
| `SettingsGroupView` | 6 (Settings), 10 (sub-screens) |
| `HabitLogRow` / `HabitProgressRow` | 4 (Action), 6 (Settings) |
| `StatusChip` | 3 (Home), 6 (Settings), 7 (History filters) |
| `PlusPill` | 6 (Settings), 10 (Paywall) |
| `SourcePill` (AUTO/LOG) | 4 (Action), 6 (Settings) |
| `SkeletonCard` | 2 (Onboarding reading state), 3 (Home loading), 5 (Trends loading) |
| `PremiumBanner` | 3 (Home), optional 5 (Trends) |

### 5.3 Color budget per screen

| Color role | Hex | Max uses per screen |
|---|---|---|
| `charRippleAccent` | `#4FC3F7` | 2-3 (accent + active state) |
| `stressRelaxed` | `#34C759` | ≤ 1 (success/relaxed) |
| `stressMild` | `#007AFF` | ≤ 1 (current state if Mild) |
| `stressModerate` | `#FFD60A` | ≤ 1 (warning state) |
| `stressHigh` | `#FF9500` | ≤ 1 (alert state) |
| `stressSevere` | `#FF3B30` | ≤ 1 (critical state) |
| `premiumGold` | `#FE9901` | ≤ 2 (Plus pill + premium banner) |
| `charEmberAccent` / `charZephyrAccent` / `charLumiAccent` | per character | ≤ 1 each (character tile) |

---

## 6. Phase Sequencing (recommended)

```
Phase 1 (1-2 weeks) — Foundation:
  Cluster 1 (Foundation) → unblocks all others
  Then Cluster 2 (Onboarding + Empty States) → validate state branching

Phase 2 (2-3 weeks) — Core tabs in parallel:
  Cluster 3 (Home) + Cluster 4 (Action) + Cluster 5 (Trends) + Cluster 6 (Settings)
  - Can run by 1 dev sequentially or 2-4 devs in parallel (different View files, minimal conflict)
  - Sync daily on shared components (StatusChip, SourcePill, PlusPill)

Phase 3 (1-2 weeks) — Secondary flows:
  Cluster 7 (Measure/History/BioAge) + Cluster 8 (Breathing/Walk) in parallel

Phase 4 (1-2 weeks) — Premium + Characters + Data:
  Cluster 9 (Characters) → Cluster 10 (IAP/Data) sequentially
  (Characters needs to land before Paywall transformation hero)

Phase 5 (1 week) — Polish:
  - Cross-screen consistency audit (data values, color budget, component reuse)
  - VoiceOver pass (M4 from KANBAN)
  - Dynamic Type verification (M4)
  - Test suite rewrite (B3 — required before ship)
```

**Total estimate:** 6-10 weeks for 1-2 developers, 4-6 weeks for 2-4 developers in parallel.

---

## 7. Out-of-Scope (not in this plan)

- **B3 test suite rewrite** — separate effort, tracked in `KANBAN-SHIP-READINESS.md`. Should run in parallel with Phase 4-5.
- **CloudKit E2E encryption (H3)** — separate P1 effort, no UI impact.
- **ConflictResolver merge bug (H2)** — backend fix, no UI impact.
- **Apple Intelligence strategy (H4)** — uncomment cloud-first in `ChatViewModel`, no UI redesign.
- **Watch app redesign** — out of scope. Watch app has its own target `StressMonitorWatch Watch App/`.
- **Widget redesign** — out of scope. Widgets trong `StressMonitorWidget/` đãno-number policy per KANBAN.
- **Localization** — v1.1 per roadmap, English-only for v1.0.

---

## 8. Critical Risks & Mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | Adding `.severe` to `StressCategory` breaks switches | HIGH — compile errors across codebase | Grep `case .high` và update từng file. Use compiler to catch all. |
| R2 | Removing Roboto breaks views using `Font.WellnessType.*` | HIGH — many call sites | Migration script: sed `Font.WellnessType.heroNumber` → `Font.system(size: 72, weight: .bold, design: .rounded)`. Run after Phase 1. |
| R3 | `CharacterAssetResolver` missing mood variants (curious, breathing) | MEDIUM — empty states & breathing screen broken | Verify assets trong `Assets.xcassets/Characters/`. Export missing SVGs từ HTML library (đã có `character-illustration-library-2.html` reference tại repo root). |
| R4 | SwiftData migration khi add `Habit` model | MEDIUM — existing users lose data | Use lightweight migration: thêm `Habit` model mới không phá existing `StressMeasurement` schema. Test với TestFlight build. |
| R5 | 4-tab conversion breaks existing `path`/navigation | MEDIUM — Settings route lost | Replace `showSettings` boolean + `navigationDestination` với direct Tab switch. Existing Settings deep links từ outside (widgets, notifications) cần re-route. |
| R6 | `MeasureButton` removal breaks existing FAB behavior | LOW — Dashboard loses measure entry | Compensate bằng "Measure" CTA trong quick-actions hoặc Insight card. Update tests. |
| R7 | RR (respiratory rate) HealthKit availability on simulator | LOW — demo mode blocks | `SimulatorHealthKitService` extend với mock RR. Real device iOS 17+ supports `HKQuantityTypeIdentifier.respiratoryRate`. |
| R8 | Character SVG render performance (38 assets) | LOW — SwiftUI `Image` handles efficiently | Use Asset Catalog với PDF/SVG (single-scale). Lazy load via `AsyncImage` nếu cần. |

---

## 9. Acceptance Gates (per phase)

**Phase 1 exit:**
- [ ] `MainTabView` shows 4 tabs
- [ ] `StressCategory.severe` compiles + tested
- [ ] `TideGaugeView(barHeight: 140)` renders
- [ ] `SemicircleGaugeView(score: 42)` renders
- [ ] Empty states render when HealthKit denied

**Phase 2 exit:**
- [ ] All 4 tab screens match HTML redesign
- [ ] Cross-screen data consistency verified (Alex · 42 Mild · 7d streak · bio 26/28)
- [ ] No emoji as UI icon (lint pass)
- [ ] No Roboto font references (lint pass)

**Phase 3 exit:**
- [ ] Measurement detail shows 5-factor breakdown
- [ ] Breathing exercise cycles through 4-4-4-4
- [ ] Mini Walk tracks steps + pause/resume

**Phase 4 exit:**
- [ ] Paywall shows real StoreKit products
- [ ] Purchase success unlocks characters
- [ ] Data export generates valid CSV/JSON
- [ ] Character detail shows evolution stages

**Phase 5 exit (ship-ready):**
- [ ] B3 test suite rewrite complete
- [ ] VoiceOver audit passed on all screens
- [ ] Dynamic Type audit passed
- [ ] Cross-screen consistency final pass
- [ ] Build success on `StressMonitor + StressMonitorWatch + StressMonitorWidget` targets

---

## 10. References

### Source of truth (HTML design)
- Workspace: `Open Design/projects/2af444ce-9930-4714-aae4-97f157003b49/`
- `index.html` — launcher grid 27 screens
- `design-system.html` — design system doc (15 sections)
- `css/app.css` — shared stylesheet (580+ LOC, mirror vào `DesignTokens.swift` + `Color+Extensions.swift`)
- `screens/01-welcome.html` → `screens/25-about.html` — 25 primary screens
- `screens/04-home-no-health.html` + `screens/04-home-no-data.html` — 2 empty states

### Target iOS codebase
- Root: `/Users/ddphuong/Projects/next-labs/ios-stress-app/`
- App target: `StressMonitor/StressMonitor/`
- Entry: `StressMonitorApp.swift` (20 LOC)
- Docs: `docs/INDEX.md` (246 LOC) — **read first** per `AGENTS.md`
- KANBAN: `docs/KANBAN-SHIP-READINESS.md` (201 LOC)
- Character asset reference: `character-illustration-library-2.html` (repo root)
- Stresswatch research: `stresswatch-ui-report.html` (repo root) — applied trong Cluster 5 (Trends), Cluster 6 (Settings), Cluster 10 (Paywall)

### Documentation to update post-conversion
- `docs/codebase-summary.md` — update "Recent Updates" section
- `docs/system-architecture-core.md` — update 3-tab → 4-tab notation
- `docs/design-guidelines-visual.md` — update Roboto → SF Pro notation
- `docs/KANBAN-SHIP-READINESS.md` — move B3 to RESOLVED, add new items if any
- `CLAUDE.md` line 158 "3-Tab Navigation" → "4-Tab Navigation"
- `AGENTS.md` line 106-116 "3-Tab Navigation" → "4-Tab Navigation"

---

## 11. Codebase Reality Check (post-exploration)

**Method:** Explore subagent failed 3× with `ProviderModelNotFoundError`. Fell back to direct `Read` of every critical file. This section captures verified findings that **refine** (not replace) gaps in §2 — many "gaps" are partially or fully built already.

### 11.1 What's already built (revise §2 gap pessimism)

| Original gap | Reality | File citation |
|---|---|---|
| **G3** Add `.severe` to StressCategory | **PARTIAL groundwork.** `Color.stressSevere = #FF3B30` đã có. `stressColor(for: level:)` đã return severe cho level >100. Chỉ thiếu enum case + icon/pattern/displayName. | `Theme/Color+Extensions.swift:40,210-218` · `Models/StressCategory.swift:3-7` (4 cases only) |
| **G6** Add Semicircle + Oval gauges | **SEMICIRCLE ALREADY EXISTS.** `SemicircularGaugeView` 167 LOC, v1 already places character inside arc (matches HTML redesign `04-home.html`). `StressRingView` cũng có. **Only `.oval-gauge` (horizontal pill) missing.** | `Views/Dashboard/Components/SemicircularGaugeView.swift:1-167` · `StressRingView.swift` |
| **G10** Build empty states | **BOTH EXIST.** `PermissionCardView` (145 LOC, 3 variants: healthKit/heartRate/hrv with grant CTA + Settings deep link). `NoDataCard` cho sync/loading state. `SkeletonBlock` cho shimmer. | `Views/Dashboard/Components/PermissionCardView.swift:1-145` · `NoDataCard.swift` · `SkeletonBlock.swift` |
| **G4** Character SVGs | **Ripple is gold-standard SwiftUI shape view.** `RippleCharacterView` 573 LOC, pure SwiftUI shapes (Ellipse/Path/Circle), 8 moods (serene/focused/relaxed/happy/celebrating/worried/determined/tired) với distinct eyes/mouth per mood. Blossom/Ember/Zephyr/Lumi go through `CharacterAssetResolver` (expects PDF/SVG assets `*_droplet_calm` đã placeholder). | `Components/Character/RippleCharacterView.swift:1-60` · `RippleMood.swift:1-47` · `Services/CharacterAssetResolver.swift:14-63` |
| **G1** Tab count 3→4 | **Confirmed 3-tab.** Uses iOS 17 `Tab(value:)` API. Settings pushed via `NavigationStack` + `onSettingsTapped` closure (not a tab). | `Views/MainTabView.swift:11-36` |
| **G2** Roboto → SF Pro | **Confirmed Roboto.** `Font.WellnessType` hardcodes `"Roboto"` với SF Pro fallback nếu font not loaded. | `Theme/Font+WellnessType.swift:9-49` |
| Character palette | **Already shipped tất cả 5.** `HomeCharacterDesignTokens` defines Ripple/Blossom/Ember/Zephyr/Lumi palettes (primary/mid/light/deep/accent). Duplicated trong `Color+Extensions` dòng 202-206. | `Theme/HomeCharacterDesignTokens.swift:1-62` |

### 11.2 Architecture verified

| Layer | Implementation | File |
|---|---|---|
| Entry | `@main struct StressMonitorApp` · SwiftData `ModelContainer` seeded với `CharacterUnlock` defaults · Ripple set as active | `StressMonitorApp.swift:13-82` |
| Root view | `OnboardingContainerView()` (wraps `MainTabView` after onboarding complete) | `StressMonitorApp.swift:44` |
| State | `@Observable` macro (iOS 17+) · `@MainActor` trên VMs | per `CLAUDE.md:248-263` |
| Persistence | SwiftData với 2 `@Model`: `StressMeasurement`, `CharacterUnlock` | `StressMonitorApp.swift:15-18` |
| DI | Constructor injection — `HealthKitManager()`, `MultiFactorStressCalculator()`, `StressRepository(modelContext:)` | `Views/DashboardView.swift:21-25` |
| HealthKit | `HealthKitManager` + `SimulatorHealthKitService` (DEBUG demo mode) via `HealthKitServiceProtocol` | `CLAUDE.md:213-218` |
| Algo | `MultiFactorStressCalculator` 5 factors (HRV highest / HR / Sleep / Activity / Recovery low). Legacy `StressCalculator` HRV×0.7+HR×0.3 fallback. | `CLAUDE.md:119-143` |
| LLM | `LLMServiceProtocol` Sendable · `SupabaseLLMService` primary + `AppleIntelligenceService` fallback | `CLAUDE.md:227-231` |
| CloudKit | `SyncManager` + `ConflictResolver` + `CloudKitSyncEngine` | `Services/Sync/`, `Services/CloudKit/` |
| StoreKit | `StoreKitService` + `MockStoreKitService` · monthly + annual products via `StoreKitProductCatalog` | `Services/StoreKit/` |
| Watch | `StressMonitorWatch Watch App/` target + `PhoneConnectivityManager` (WatchConnectivity) | per `CLAUDE.md:89` |
| Widget | `StressMonitorWidget/` target (WidgetKit — Smart Stack, Live Activities) | per `CLAUDE.md:195` |

### 11.3 Two mood systems coexist (must consolidate)

| Enum | Cases | Used by | File |
|---|---|---|---|
| `StressBuddyMood` | 5: sleeping/calm/concerned/worried/overwhelmed | `SemicircularGaugeView`, `CharacterAssetResolver`, dashboard fallbacks | `Models/StressBuddyMood.swift:5-10` |
| `RippleMood` | 8: serene/focused/relaxed/happy/celebrating/worried/determined/tired | `RippleCharacterView` (Action subscreens) | `Components/Character/RippleMood.swift:5-13` |

**Decision needed trong Phase 1:** unify thành 1 system (recommend giữ 8-case RippleMood vì nhiều emotional granularity hơn — relaxed/celebrating/determined/tired không map 1-1 vào 5 StressBuddyMood cases). Khi unificate, cập nhật `CharacterAssetResolver.resolvedAssetName` + `SemicircularGaugeView.mood` + `StressBuddyIllustration`.

### 11.4 Settings architecture reality

**HTML redesign** (`screens/10-settings.html`): 8 grouped sections với me-hero consolidated + companion banner.

**iOS current** (`Views/Settings/SettingsView.swift:21-70`): 9 card-stack — `ProfileCard`, `PremiumCard`, `CharactersCard`, `WatchFaceCard`, `WidgetCard`, `HealthDataCard`, `NotificationsCard`, `PrivacyCard`, `AboutCard`. Mỗi card là 1 file riêng trong `Views/Settings/Components/`.

**Gap:** Card-stack pattern không match HTML grouped-list pattern. Phải chọn:
- **Option A (recommend):** Refactor `SettingsView` dùng `SettingsGroupView` (đã có, 27 LOC) cho 8 groups — discard individual card files
- **Option B:** Keep card files nhưng restyle từng card để visual match HTML grouped rows

**Verified missing features:**
- ❌ Habits tracking section (Hydration/Caffeine/Sunlight với AUTO/LOG source pills) — không có trong iOS
- ❌ Active companion banner (Ripple mini + switch link) — không có
- ❌ Me-hero snapshot row (Bio/Stress/Streak vertical hairline dividers) — không có
- ✅ Appearance, haptics, notifications, privacy, export, manage, about — all có

### 11.5 Onboarding architecture reality

**HTML:** 3 steps (Welcome · HealthKit Permission · Complete) + 2 empty state variants.

**iOS current** (`Views/Onboarding/`): 4 main steps + 1 error view:
- `OnboardingWelcomeView` ← maps to HTML 01
- `OnboardingHealthSyncView` ← maps to HTML 02
- `OnboardingBaselineCalibrationView` ← **NEW step không có trong HTML** (collects baseline HRV samples)
- `OnboardingSuccessView` ← maps to HTML 03
- `HealthKitErrorView` + `HealthKitErrorViewModel` ← maps to HTML 04-home-no-health

**Gap:** Baseline calibration step có trong iOS nhưng không có trong HTML. **Recommend giữ nguyên iOS step** — đó là differentiator vs competitor. HTML có thể bổ sung sau nếu cần.

### 11.6 Dashboard components inventory (39 files)

Tất cả files trong `Views/Dashboard/Components/` đã tồn tại — **không cần tạo mới**, chỉ cần rewire layout:

| Component group | Files | HTML redesign section |
|---|---|---|
| Hero / gauge | `SemicircularGaugeView`, `StressRingView`, `CompactStressHeaderBar`, `StressStatusBadge`, `StatusBadgeView` | §2 hero (arc + Ripple inside) |
| AI insight | `AIInsightCard`, `AIChatCard`, `SmartInsightsCard`, `DashboardInsightCard`, `WeeklyInsightCard`, `RecommendationsCard`, `IntroMessageCard`, `QuoteCard`, `SelfNoteCard` | §3 AI summary |
| Vitals | `TripleMetricRow`, `MetricCardView`, `QuickStatCard`, `HealthStatCard`, `WatchMetricCard`, `HRVTrendCard`, `BioAgeCardView`, `DataQualityBadge` | §4 vitals triplet |
| Mood / journal | (search required — có thể nằm trong `Views/Journal/`) | §5 mood check-in |
| Health data | `HealthDataSection` | §6 health data row |
| Quick actions | `QuickActionCard` | §7 quick actions |
| Charts | `StressOverTimeChart`, `MiniLineChartView`, `SparklineChart`, `WeekCalendarStrip`, `DailyTimelineView` | §8 stress chart |
| Premium | `PremiumBanner`, `PremiumLockOverlay`, `WidgetPromoCard` | §9 premium banner |
| Empty states | `NoDataCard`, `PermissionCardView`, `SkeletonBlock`, `LearningPhaseCard` | (HTML 04-home-no-health + 04-home-no-data) |
| Misc | `DateHeaderView`, `CurvedBottomBackground`, `MiniHistoryBars` (referenced trong DashboardView) | (cross-cutting) |

**Action:** Phase 2 Cluster 3 (Home) không phải build mới — chỉ **reorder + rewire** existing components theo HTML IA. Linear scale.

### 11.7 Risks refined từ §7

| Original risk | Reality check |
|---|---|
| **R1** Adding `.severe` breaks switches | **LOW risk.** Grep toàn bộ `case .high` — chỉ có ~3-5 call sites. Compiler catch 100%. Color tokens đã có sẵn. 1-hour task. |
| **R2** Removing Roboto breaks views | **MEDIUM risk.** `Font.WellnessType.heroNumber/largeMetric/cardTitle/sectionHeader/body/bodyEmphasized/caption/caption2` được dùng rộng rãi. Migration: thay body của `WellnessType` returns `.system(..., design: .rounded)` cho character moments + `.system(..., design: .default)` cho UI — không cần đổi call sites. |
| **R3** CharacterAssetResolver missing mood variants | **CONFIRMED.** Placeholder set chỉ có 5 chars × 1 mood (`*_droplet_calm`). Cần export SVGs từ `character-illustration-library-2.html` cho 5 chars × 8 moods × 3 evolutions = 120 assets. OR rewrite Blossom/Ember/Zephyr/Lumi bằng SwiftUI shapes theo `RippleCharacterView` pattern (gold standard). |
| **NEW R4** Mood system unification | `StressBuddyMood` (5) vs `RippleMood` (8) — pick 1 + migrate. Touches `SemicircularGaugeView`, `CharacterAssetResolver`, `StressBuddyIllustration`. ~4-hour task. |
| **NEW R5** Settings card-stack → grouped-list | 9 card files trong `Views/Settings/Components/` phải refactor hoặc discard. Không break functionality, chỉ visual. ~6-hour task. |

### 11.8 Recommended Phase 1 sequencing (refined)

Thay vì build từ scratch, Phase 1 là **audit + parametrize + unify**:

| Sub-phase | Tasks | Effort |
|---|---|---|
| **P1.1 Stress tier** | Add `.severe` case vào `StressCategory` (color/icon/pattern/accessibility/displayName) | 1h |
| **P1.2 Mood unify** | Decide `RippleMood` (8) làm canonical, deprecate `StressBuddyMood`, migrate 3 call sites | 4h |
| **P1.3 Font migrate** | Override `WellnessType` internals sang `.system(..., design: .rounded/.default)`, keep public API stable | 2h |
| **P1.4 Tab 4th** | Add `.settings` case vào `TabItem`, add 4th `Tab(value:)` trong `MainTabView`, remove Settings push từ Home gear | 3h |
| **P1.5 Gauge parametrize** | `SemicircularGaugeView` đã có — validate match HTML. Add `OvalGaugeView` mới (~80 LOC, follow RippleCharacterView pattern) | 4h |
| **P1.6 Character build-out** | Quyết định strategy: (A) export 120 SVGs từ `character-illustration-library-2.html`, OR (B) build 4 SwiftUI shape views (BlossomCharacterView, EmberCharacterView, ZephyrCharacterView, LumiCharacterView) theo `RippleCharacterView` pattern | 1-3 days |

**P1 total:** ~3-5 ngày (vs 1-2 tuần trong §6 estimate) — vì nhiều components đã có.

### 11.9 Documentation updates needed

| Doc | Update | Section |
|---|---|---|
| `CLAUDE.md` | "3-Tab Navigation" → "4-Tab Navigation" + add Settings row | line 106-116 |
| `CLAUDE.md` | "Stress Categories (0–100)" → add "Severe (100+)" | line 141 |
| `CLAUDE.md` | "Tech Stack → UI" → note SF Pro Rounded cho character moments | line 80-91 |
| `AGENTS.md` | Mirror `CLAUDE.md` updates | tbd |
| `docs/system-architecture-core.md` | Update navigation diagram + mood system notation | tbd |
| `docs/design-guidelines-visual.md` | Roboto references → SF Pro system fonts | tbd |

---

**Plan version:** 1.1 · **Last updated:** Jun 21, 2026 · **Maintained by:** Phuong Doan · **Changelog:** §11 added — codebase reality check từ direct file inspection (3 explore agents failed với model error, fell back to direct Read)
