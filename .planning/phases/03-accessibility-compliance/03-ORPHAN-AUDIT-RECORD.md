# Phase 3 — D-14 Orphan Audit Record (A11Y-05)

**Date:** 2026-09-05
**Auditor:** plan 03-06 Task 1 (regenerated mechanical audit; nothing deleted in this task)
**Status:** deletion set FINAL — awaiting the Task 2 blocking decision checkpoint
**Scope:** app target `StressMonitor/StressMonitor/` view files (D-14: "compiled view type unreachable from the navigation graph"). Repo-root legacy source set (`StressMonitor/{Models,Services,Views}/`) is EXCLUDED per D-14. Watch target files are NOT touched (mirror convention — every name collision found is a separate-module declaration, not an orphan).

---

## 1. Method

**Step 1 — Regenerated BFS (input rebuilt, not trusted from UI-SPEC).** File-level breadth-first reachability over view-constructor edges (`Type(` and `Type {`) across all 299 app-target `.swift` files, with `#Preview` macro blocks and `PreviewProvider` conformances stripped before edge extraction. Seeds: app entry (`StressMonitorApp`), tab container (`MainTabView`), `Route.swift` + `View+NavigationDestinations.swift`, the four tab roots (DashboardView / ActionView / TrendsView / SettingsView), and every Route destination (DataExport, DataManage, DataDelete, CharacterCollection, Appearance, About, WatchFacePreferences, MeasurementDetail via `MeasurementDetailDestination`, BreathingExercise, MiniWalk, BreathingSession, BreathingSummary). All seeds resolved on disk. Deletion universe: view files (`Views/**`, `Components/**` — 177 files). Non-view files (Services, Models, Theme, Utilities, ViewModels, Navigation) are ambient-live edge sources, never candidates.

**Result: 177 view files → 91 reachable, 86 orphan candidates** (BFS output regenerated 2026-09-05; scripts were throwaway `/tmp` passes, method documented here).

**Step 2 — False-positive screens (before any file entered the delete set):**

1. **Word-boundary reference screen** (new class discovered by this audit): BFS constructor edges are blind to **static/namespace member access** — `HapticManager.shared`, `Typography.caption1`, `Spacing.cardPadding`. Every candidate's declared types were re-grepped with `\bType\b` across ALL live files. Five candidates were rescued by this screen (see §4). Homonym hits were individually resolved to comments/strings/markers (documented per row in §5).
2. **Extension-member screen** (the plan's trap class a): every `extension` declared in a candidate was parsed and each member grepped against live files. Verified instance found and confirmed: `StressCategory.displayName` + `StressCategory.init(from:)` live inside candidate `Badge.swift` while live code consumes them (displayName in 46 files; `init(from:)` at `Services/MockServices.swift:76`). Disposition: **relocate-then-delete** (§3). Second genuine instance: `View.characterAnimation(for:)` in candidate `CharacterAnimationModifier.swift`, consumed by live `StressBuddyIllustration.swift:60` → file retained.
3. **In-file helper usage** (trap class b): `ShimmerEffectView` is NOT an orphan-file case in this regeneration — 03-05 already moved it into `Utilities/Animation+Wellness.swift` (decl :202, live via `.shimmerLoading()` :289), an ambient-live Utilities file that was never a candidate. Confirmed current-shape, no action.
4. **Exempt-surface references** (trap class c): `IAPPremiumView` is reachable from exempt `PaywallView` (`PaywallView.swift:30`) — and was already in the BFS reachable set. Not an orphan; untouched.
5. **Test-target screen**: every candidate's declared types grepped across `StressMonitor/StressMonitorTests/` and root `StressMonitorTests/`. Only hit: `Trend` (MetricCardView.swift's nested enum) — homonym of BioAge `trend` properties and `TrendDirection`; zero `MetricCardView.`-qualified references in any test. **No candidate type is referenced by the test target.**
6. **Widget/watch screen**: candidate type names grepped across `StressMonitorWidget/` and `StressMonitorWatch Watch App/`. All collisions (`Source`, `Spacing`, `StressTier`, `Trend`) are those targets' OWN declarations in their OWN files (e.g. watch `Theme/WatchDesignTokens.swift`, widget `WidgetStressCharacter.swift`). No app-target view file is shared into widget/watch target membership — corroborated by the pbxproj synchronized-root-group structure (research-verified). Delete-compile of all three schemes is the standing judge.

**Step 3 — Periphery cross-check: FAILED to index, A6 fallback recorded.** Periphery 2.21.2, three genuine attempts:
1. `periphery scan --project … --schemes StressMonitor --targets StressMonitor` (own build): pipeline ran, but its index DataStore contains **0 records / 0 units** → analysis of an empty graph, not a clean bill.
2. `--skip-build --index-store-path <default DerivedData v5 DataStore>`: populated store (7,560 files) unreadable — Periphery 2.21.2 cannot read the Xcode 26.3 **v5** index format; result again `[]`.
3. Manual `xcodebuild` with `COMPILER_INDEX_STORE_ENABLE=YES INDEX_ENABLE_DATA_STORE=NO` into a fresh DerivedData: Xcode 26.3 emits **no index store at all** in the legacy format.

**Disagreement rows: none possible** — Periphery produced no usable set either way. Per research A6 and the plan's precondition fallback: the audit closes on **grep-BFS + false-positive screens + delete-compile ground truth alone**. The compiler is the judge.

**Step 4 — Drift vs UI-SPEC 81-file candidate list.** UI-SPEC scan (2026-09-05, pre-wave execution): 158 view-declaring files → 77 reachable / 81 candidates. This regeneration: 177 view files → 91 reachable / 86 candidates. Drift sources: (a) this audit's universe includes `Components/**` (20 files) the UI-SPEC count did not break out; (b) the tree changed during waves 1–5 (03-05 moved `ShimmerEffectView` into `Animation+Wellness.swift`; views added earlier in the milestone). The regenerated set is authoritative; the UI-SPEC number is cross-reference only. Coincidentally the final DELETE set is also 81 view files — a different set than the UI-SPEC's 81 (5 files rescued by screens are replaced by candidates the UI-SPEC under-counted).

---

## 2. Summary disposition

| Class | Count | Disposition |
|-------|-------|-------------|
| BFS orphan candidates | 86 | 81 DELETE, 5 RETAIN (false-positive screens) |
| Zero-call-site Utilities (D-05 class) | 3 | DELETE (`HighContrastModifier.swift`, `PatternOverlay.swift`, `ColorBlindnessSimulator.swift` — 0 refs outside own files re-verified 2026-09-05) |
| Live extension members in orphan file | 1 file | Badge.swift: **relocate** `StressCategory.displayName` + `init(from:)` → `Models/StressCategory.swift`, THEN delete file |
| Duplicate color statics (`Color+Extensions.swift:36-40`) | 5 statics | **Retained-because**: direct live consumers exist — `WeeklyInsightCard:18-20`, `VitalsTriplet:66,103`, `HealthDataSection:105`, `HomeHeaderBar:82`, `MoodCheckInView:89-93`, `FactorBreakdownRow:34,37`, `DetailViewModel:215-216`, `MeasurementDetailView:344-348` — plus the delegating `Color.stressColor(for:)` (:186, preserved). Not zero-adopter; delete condition not met. |
| Zero-adopter member in live file | 1 member | `StressCategory.readableTextColor` (`Models/StressCategory.swift:45`) — zero adopters app+tests (03-03 made it zero-adopter). DELETE member. |
| Knock-on zero-adopter member | 1 member | `StressCategory.overlayTextColor` — currently used only by candidate `CategoryFilterChip.swift:34`. DELETE member in the same batch IF post-deletion grep confirms zero remaining adopters (mechanical condition, checked at execution). |
| Deferred-items unguarded `repeatForever` loops | 4 sites | 3 die with deleted files (`LoadingView` ~100, `BioAgeCardView` ~43, `SmartInsightsTeaser` ~88). 1 SURVIVOR: `ChatBottomSheetView.swift` ~541 — adopts the WellnessMotion helper (`animateIfMotionAllowed`) during the Task 3 gate re-run per the 03-05 handoff. |
| App-side shrink-gate baseline (7 sites / 6 files) | — | 4 sites die with deleted files (BioAgeCardView:80, StressSourcesCard:152, BioAgeDetailView:67, CharacterPickerSheet:65 + their dated markers). Survivors with markers: `MoodCheckInView:66`, `EvolutionStageRow:55,64`. Gate re-baselines at execution. |

**Final deletion set: 84 files** (81 view files + 3 Utilities files) + 2 member-level deletions + 1 relocation.

---

## 3. Relocation-first work order (Badge.swift trap)

`Views/DesignSystem/Components/Badge.swift` declares:
- `Badge` / `StressBadge` views — orphan (zero live constructor refs; the three live-file word-hits are comments: `CharacterGridCard.swift:96` MARK, `ChatContextBuilder.swift:92` doc note, `StressCategory.swift:77` doc note).
- `extension StressCategory { init(from level: Double); var displayName: String }` — **LIVE** (displayName consumed by 46 files incl. SettingsView, ActionView, StressHeroCard, EvolutionStageRow, StoreKitService, CharacterIllustrationExporter; `StressCategory(from:)` by `Services/MockServices.swift:76`).

**Order:** (1) move the extension verbatim into `Models/StressCategory.swift` (its type's home; the file is live and already documents the extension at :77 — comment updated); (2) build the app scheme to prove the relocation; (3) only then delete `Badge.swift` in the DesignSystem batch. Prohibition honored: no deletion before relocation compiles.

---

## 4. Retained-because set (5 view files rescued from the BFS candidate list)

| File | Retained because (live reference named) |
|------|------------------------------------------|
| `Views/Components/HapticManager.swift` | Singleton static access `HapticManager.shared.*` from 23+ live files (e.g. `ActionView.swift:182,195`, `StressViewModel`) — invisible to constructor-edge BFS |
| `Views/DesignSystem/Spacing.swift` | Static namespace `Spacing.*` consumed by live `PermissionCardView`, `SkeletonBlock:13`, `SettingsCard`, `PaywallView`, `NoteEntryView` |
| `Views/DesignSystem/Typography.swift` | Static namespace `Typography.*` consumed by ~15 live files (`PaywallView:45`, `IAPPremiumView`, IAP* premium components, `Buttons`, `RecommendationCard`, `PermissionCardView`, `PremiumLockOverlay`, `NoteEntryView`) |
| `Components/Character/CharacterAnimationModifier.swift` | `View.characterAnimation(for:)` consumed by live `StressBuddyIllustration.swift:60` (itself used by AboutView, CompanionBanner, ChatBottomSheetView, BreathingSummaryView). `AccessoryAnimationModifier` is a dead in-file member — noted, left in place (surgical-change rule) |
| `Views/Trends/Components/RippleTrendsKit.swift` | `StressTier` + `TrendsPalette` consumed by live `TrendsViewModel.swift:57,64,71` (`TrendsPalette.rippleBlue`, `StressTier.from(level:)`) |

Retained members in live files: the five `stressRelaxed…stressSevere` statics (§2), `Color.stressColor(for:)`.

---

## 5. Per-file disposition table — all 86 regenerated candidates

### Character illustration (Components/Character)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Components/Character/BlossomCharacterView.swift` | **DELETE** | zero refs outside candidate set (only other Character candidates declare same-named face shapes) |
| `Components/Character/CharacterAnimationModifier.swift` | **RETAIN** | extension `View.characterAnimation(for:)` consumed by live StressBuddyIllustration.swift:60 (used by AboutView/CompanionBanner/ChatBottomSheetView/BreathingSummaryView); AccessoryAnimationModifier is a dead in-file member, noted not removed |
| `Components/Character/DecorativeTriangleView.swift` | **DELETE** | zero live refs; referenced only by candidate StressCharacterCard |
| `Components/Character/EmberCharacterView.swift` | **DELETE** | zero live refs |
| `Components/Character/LumiCharacterView.swift` | **DELETE** | zero live refs |
| `Components/Character/RippleCharacterView.swift` | **DELETE** | referenced only by candidate BlossomCharacterView |
| `Components/Character/RippleHomeCharacterGlyph.swift` | **DELETE** | zero live refs |
| `Components/Character/StressCharacterCard.swift` | **DELETE** | referenced only by candidates DecorativeTriangleView/CharacterPickerSheet |
| `Components/Character/ZephyrCharacterView.swift` | **DELETE** | zero live refs |

### Dashboard classic-card generation (Views/Dashboard/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Dashboard/Components/AIChatCard.swift` | **DELETE** | zero live refs (03-03 confirmed orphan candidate) |
| `Views/Dashboard/Components/ArcStage.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/BioAgeCardView.swift` | **DELETE** | zero live refs (03-03 confirmed; deferred-items pulse loop dies with it) |
| `Views/Dashboard/Components/CompactStressHeaderBar.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/CurvedBottomBackground.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/DashboardInsightCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/DataQualityBadge.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/DateHeaderView.swift` | **DELETE** | referenced only by candidate StressCharacterCard |
| `Views/Dashboard/Components/HRVTrendCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/HealthDataRow.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/HealthStatCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/IntroMessageCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/LearningPhaseCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/MetricCardView.swift` | **DELETE** | zero live refs; the `Trend` word-hits in live files are homonyms (StressViewModel.TrendDirection, BioAge trend property) — no `MetricCardView.` qualified use anywhere incl. tests |
| `Views/Dashboard/Components/MiniLineChartView.swift` | **DELETE** | preview-only (03-04); referenced only by candidate MetricCardView |
| `Views/Dashboard/Components/QuickStatCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/QuoteCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/RecommendationsCard.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/SelfNoteCard.swift` | **DELETE** | zero live refs (03-03 confirmed) |
| `Views/Dashboard/Components/SparklineChart.swift` | **DELETE** | preview-only (03-04); the 03-04 accessibility-series work on it is deleted with the view — ChartAccessibilityTests pins the live-chart variant; weigh: zero live call sites, keep nothing |
| `Views/Dashboard/Components/StatusBadgeView.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/StatusChip.swift` | **DELETE** | zero live refs; bioAge/streak member hits were parser noise from common property names |
| `Views/Dashboard/Components/StressRingView.swift` | **DELETE** | zero live refs (D-13 baseline file; deletion shrinks the RM surface) |
| `Views/Dashboard/Components/StressSourcesCard.swift` | **DELETE** | referenced only by candidate TrendsStressSourcesCard; its 03-03 dated shrink marker dies with it |
| `Views/Dashboard/Components/StressStatusBadge.swift` | **DELETE** | zero live refs |
| `Views/Dashboard/Components/WatchMetricCard.swift` | **DELETE** | zero live refs; sleep member hit was parser noise |
| `Views/Dashboard/Components/WeekCalendarStrip.swift` | **DELETE** | zero live refs; was an accentTeal fill site (token itself retained in Color+Extensions) |
| `Views/Dashboard/Components/WidgetPromoCard.swift` | **DELETE** | zero live refs |

### DesignSystem generation (Views/DesignSystem)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/DesignSystem/Components/Badge.swift` | **DELETE (relocate first)** | Badge/StressBadge structs zero live constructor refs; but `extension StressCategory { init(from:), displayName }` is live — displayName consumed by 46 files, init(from:) by MockServices.swift:76. RELOCATE the extension to Models/StressCategory.swift, then delete the file |
| `Views/DesignSystem/Components/EmptyStateView.swift` | **DELETE** | zero live refs; `init` hits were `.init(` homonym noise |
| `Views/DesignSystem/Components/GlassCard.swift` | **DELETE** | zero live refs |
| `Views/DesignSystem/Components/LoadingView.swift` | **DELETE** | zero live refs; deferred-items unguarded shimmer loop dies with it |
| `Views/DesignSystem/Components/SectionHeader.swift` | **DELETE** | zero live refs |
| `Views/DesignSystem/Components/StatCard.swift` | **DELETE** | zero live refs |
| `Views/DesignSystem/Spacing.swift` | **RETAIN** | static namespace `Spacing.*` consumed by live PermissionCardView, SkeletonBlock, SettingsCard, PaywallView, NoteEntryView — namespace member access is invisible to constructor-edge BFS |
| `Views/DesignSystem/Typography.swift` | **RETAIN** | static namespace `Typography.*` consumed by ~15 live files (PaywallView:45 iapPlanName, IAPPremiumView, IAP* premium components, Buttons, RecommendationCard, PermissionCardView, PremiumLockOverlay, NoteEntryView) |

### Unused gauges (Views/Components/Gauges)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Components/Gauges/OvalGaugeView.swift` | **DELETE** | zero live refs; references candidate TideGaugeView |
| `Views/Components/Gauges/TideGaugeView.swift` | **DELETE** | referenced only by candidate OvalGaugeView |

### Legacy History cluster (Views/History*)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/History/BioAgeDetailView.swift` | **DELETE** | zero live refs (03-03 confirmed) |
| `Views/History/Components/CategoryFilterChip.swift` | **DELETE** | referenced only by candidates MeasurementHistoryView/HistoryView |
| `Views/History/Components/DateFilterChip.swift` | **DELETE** | referenced only by candidates MeasurementHistoryView/HistoryView/HistoryViewModel |
| `Views/History/Components/FactorProgressBar.swift` | **DELETE** | zero live refs |
| `Views/History/Components/StressGaugeMini.swift` | **DELETE** | zero live refs; `Arc` hit in StressHeroCard:79 is a MARK comment |
| `Views/History/Components/StressGaugeView.swift` | **DELETE** | zero live refs |
| `Views/History/HistoryViewModel.swift` | **DELETE** | referenced only by candidate MeasurementHistoryView |
| `Views/History/MeasurementHistoryView.swift` | **DELETE** | referenced only by candidate HistoryView; its 03-02 accessibleDynamicType adoption dies with it |
| `Views/HistoryView.swift` | **DELETE** | zero live refs; no Route case resolves it (measurement(id:) resolves MeasurementDetailView) |

### Characters screens (Views/Characters)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Characters/CharacterIllustrationExportView.swift` | **DELETE** | zero live refs (dev-export tool view; the CharacterIllustrationExporter service is ambient-live and stays) |
| `Views/Characters/CharacterPickerSheet.swift` | **DELETE** | referenced only by candidate StressCharacterCard (03-03 confirmed; dated shrink marker dies with it) |
| `Views/Characters/Components/EvolutionDots.swift` | **DELETE** | zero live refs |
| `Views/Characters/Components/EvolutionTimelineRow.swift` | **DELETE** | zero live refs |
| `Views/Characters/Components/StatItem.swift` | **DELETE** | zero live refs |
| `Views/Characters/EvolutionCelebrationView.swift` | **DELETE** | zero live refs |

### Onboarding stragglers (Views/Onboarding)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Onboarding/HealthKitErrorView.swift` | **DELETE** | zero live refs; OnboardingContainerView does not construct it |
| `Views/Onboarding/HealthKitErrorViewModel.swift` | **DELETE** | referenced only by candidate HealthKitErrorView |
| `Views/Onboarding/OnboardingBaselineCalibrationView.swift` | **DELETE** | zero live refs |
| `Views/Onboarding/OnboardingBaselineCalibrationViewModel.swift` | **DELETE** | referenced only by candidate OnboardingBaselineCalibrationView |

### Premium components (Views/Premium/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Premium/Components/IAPHeroSection.swift` | **DELETE** | zero live refs; IAPPremiumView does not construct it |
| `Views/Premium/Components/PlanSelectionCard.swift` | **DELETE** | zero live refs |

### Settings components (Views/Settings/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Settings/Components/SettingsSectionHeader.swift` | **DELETE** | zero live refs; SettingsView uses SettingsCard instead |

### Trends components (Views/Trends/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Trends/Components/CircularStressIndicatorView.swift` | **DELETE** | zero live refs (refs shown are in its own #Preview) |
| `Views/Trends/Components/DistributionBarView.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/FullDonutSegmentShape.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/HorizontalWeekCalendarView.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/InsightCard.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/MascotSpeechBubbleView.swift` | **DELETE** | zero live refs; message hit was common-word noise |
| `Views/Trends/Components/PatternInsightsSection.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/PremiumBannerView.swift` | **DELETE** | zero live refs; its AppShadow use was the only other Shadows reference — PermissionCardView keeps Shadows live |
| `Views/Trends/Components/RippleTrendsKit.swift` | **RETAIN** | `StressTier` + `TrendsPalette` consumed by live TrendsViewModel.swift:57,64,71 (TrendsPalette.rippleBlue, StressTier.from(level:)); MonthlyCalendarHeatmap:142 is a comment mention |
| `Views/Trends/Components/SmartInsightsTeaser.swift` | **DELETE** | zero live refs (deferred-items pulse loop dies with it) |
| `Views/Trends/Components/TimeRangePicker.swift` | **DELETE** | zero live refs |
| `Views/Trends/Components/TrendsStressSourcesCard.swift` | **DELETE** | zero live refs; `Source` word-hits were a MARK comment (StressCategory.swift:96) and a string literal (SourcePill.swift:25) |

### Breathing (Views/Breathing/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Breathing/Components/RippleBreathingView.swift` | **DELETE** | zero live refs (ripple-era breathing; BreathingCircle is the live one); D-13 baseline file |

### MiniWalk (Views/MiniWalk/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/MiniWalk/Components/MiniWalkInstructionCard.swift` | **DELETE** | zero live refs; D-13 baseline file |

### Misc components (Views/Components)

| File | Disposition | Evidence |
|------|-------------|----------|
| `Views/Components/CharCompanionCard.swift` | **DELETE** | zero live refs |
| `Views/Components/PrimaryMetricCard.swift` | **DELETE** | zero live refs |
| `Views/Components/HapticManager.swift` | **RETAIN** | singleton `HapticManager.shared.*` static access from 23+ live files (StressViewModel, ActionView:182,195, ...) — singleton access is invisible to constructor-edge BFS |

**Coverage check: 86/86 candidates dispositioned (script-verified: missing=[], extra=[]).**

### Utilities (outside the view-file universe, named by the plan)

| File | Disposition | Evidence |
|------|-------------|----------|
| `StressMonitor/StressMonitor/Utilities/HighContrastModifier.swift` | **DELETE** | D-05; 0 refs outside own file (re-verified: `HighContrastModifier`/`HighContrast` greps) |
| `StressMonitor/StressMonitor/Utilities/PatternOverlay.swift` | **DELETE** | 0 call sites (re-verified: `PatternOverlay`/`Crosshatch`/`DiagonalLines` greps) |
| `StressMonitor/StressMonitor/Utilities/ColorBlindnessSimulator.swift` | **DELETE** | verified zero-call-site class (re-verified: `ColorBlindnessSimulator`/`ColorBlindness` greps) |

---

## 6. Views/DesignSystem component-inventory provenance (UI-SPEC Dimension 7 anchor)

Dated liveness verdict for every `Views/DesignSystem/` component — this section is the provenance anchor the UI-SPEC component inventory lacked:

| Component file | Verdict | Live reference |
|----------------|---------|----------------|
| `Components/Badge.swift` | DELETE (after relocation) | only its `StressCategory` extension is live (§3) |
| `Components/Buttons.swift` | LIVE | `SecondaryButton(title:action:)` at `PermissionCardView.swift:96` (`PrimaryButton`, `DestructiveButton` are dead in-file members — noted, retained) |
| `Components/EmptyStateView.swift` | DELETE | zero live refs |
| `Components/GlassCard.swift` | DELETE | zero live refs |
| `Components/LoadingView.swift` | DELETE | zero live refs |
| `Components/SectionHeader.swift` | DELETE | zero live refs |
| `Components/SettingsCard.swift` | LIVE | `SettingsCard {` at `SettingsView.swift:132,164,207,235,270,319,398`, `MeHeroCard.swift:18`, `CompanionBanner.swift:12` |
| `Components/StatCard.swift` | DELETE | zero live refs |
| `Shadows.swift` | LIVE | `AppShadow`/`ShadowDefinition` at `PermissionCardView.swift:103` (+ `.cardShadow()`/`.elevatedShadow()` extension family) |
| `Spacing.swift` | LIVE | §4 retained-because row |
| `Typography.swift` | LIVE | §4 retained-because row |

---

## 7. Deletion batches for Task 3 (delete-compile protocol)

App sources are a `PBXFileSystemSynchronizedRootGroup` — deleting a `.swift` from disk removes it from the target with zero pbxproj surgery. Test target untouched (no candidate is referenced by tests — §1 screen 5). Watch/widget targets compile their own folders only; they are proven by the final three-scheme clean build.

| Batch | Contents | Files |
|-------|----------|-------|
| 0 | **Relocation** (not a deletion): move `StressCategory` extension → `Models/StressCategory.swift`; fix the `:77` comment; app-scheme build proves it | 1 edit |
| 1 | Utilities trio + member deletions (`readableTextColor`; `overlayTextColor` if post-grep confirms) | 3 files + 1–2 members |
| 2 | DesignSystem components (Badge, EmptyStateView, GlassCard, LoadingView, SectionHeader, StatCard) | 6 |
| 3 | Dashboard classic cards | 28 |
| 4 | Character illustration | 8 |
| 5 | Legacy History + gauges | 11 |
| 6 | Characters screens + Onboarding + Premium + Settings stragglers | 13 |
| 7 | Trends + Breathing + MiniWalk + Misc | 15 |
| — | Survivor adoption: `ChatBottomSheetView` ~541 repeatForever → WellnessMotion helper | 1 edit |
| — | **Final pass: clean build directory, all three schemes + canonical full suite** | — |

Per-batch break = restore the file + add a retained-because row (missed live reference) or relocate + retry (missed relocation); the compiler is ground truth, the record is amended — never the build settings.

---

## 8. Decision record (Task 2 checkpoint fills this in)

> **PENDING — blocking-human decision required before Task 3 touches any file.**
>
> Options: `approve-full-set` (all 84 files + 2 members as audited) · `approve-trimmed` (name the families to defer) · `reject` (no deletion this phase; audit stands as documented debt).

| Field | Value |
|-------|-------|
| Decision | _awaiting user_ |
| Date/timestamp | _awaiting user_ |
| Approved set | _awaiting user_ |

---

*Audit generated 2026-09-05 by plan 03-06 Task 1. Ground truth: the Task 3 delete-compile (all three schemes, clean build directory) + canonical full suite.*
