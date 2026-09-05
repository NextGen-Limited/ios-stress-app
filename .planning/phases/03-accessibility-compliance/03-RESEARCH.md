# Phase 3: Accessibility Compliance - Research

**Researched:** 2026-09-05
**Domain:** SwiftUI accessibility remediation (touch targets, WCAG AA contrast, Reduce Motion, Dynamic Type, dead-view deletion) on iOS 18.6+ / Xcode 26.3
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Primary-Screen Scope (the sweep manifest)**
- **D-01:** The primary-screen set = the 4 tab roots — **Home (`homeView`), Action (`ActionView`), Trends (`TrendsView`), Settings (`SettingsView`)** per `MainTabView.swift` — **plus every `Route`-pushed child**, resolved from `StressMonitor/StressMonitor/Navigation/Route.swift`: `dataExport, dataManage, dataDelete, characters, appearance, about, watchFace, measurement(id), boxBreathing, miniWalk`. Measurement history is a Home child, not a tab root. Session views `breathingSession` and `breathingSummary` are exempt (session UI; their accessibility is governed by the Reduce Motion fallback decision D-11). Onboarding and Paywall are exempt this phase.
  — **Reversibility:** reversible — manifest is a doc artifact; adding/removing surfaces is a list edit, not a migration.
- **D-02:** Widget (gallery + lock-screen) and watch surfaces join the contrast/Dynamic Type sweep per D4/ROADMAP; the 44pt touch-target rule does not apply to them (not touch UI).
- **D-03:** The sweep list above is LOCKED as the audit manifest — verification (and the grep sweeps) run against exactly these surfaces, phase-2 trust-gate style (enumeration, not counts). If a surface is added later, the manifest changes with it.
  — **Reversibility:** reversible — manifest is a doc artifact; adding/removing surfaces is a list edit, not a migration.

**Contrast (A11Y-02)**
- **D-04:** AA failures are fixed by **retuning the token values in place** (`Theme/DesignTokens.swift`, `Theme/Color+Wellness.swift`): light cream canvas + dark `#121212`/`#1E1E1E` sets shift minimally to hit AA. No per-site color overrides — one source of truth, zero patchwork drift.
- **D-05:** `Utilities/HighContrastModifier.swift` (0 call sites) is **deleted** — with base tokens passing AA it is redundant dead code, the same class A11Y-05 removes.
- **D-06:** The contrast gate is a **token-pair unit test**: compute WCAG ratios from the semantic token definitions (canvas↔primary text, canvas↔secondary, card↔text, accent↔canvas, and dark-mode equivalents) and assert ≥4.5:1 for text pairs, ≥3:1 for large-text/UI pairs. Machine-checked, enumerable, runs in CI permanently.
- **D-07:** Widget contrast is verified as foreground↔**system material** pairs only (accessory/widget backgrounds Apple guarantees); wallpaper-dependent contrast is out of scope by construction and documented as platform-bounded.

**Dynamic Type (A11Y-04)**
- **D-08:** Acceptance bar at accessibility sizes is the ROADMAP SC, strict: **zero truncation** — no ellipsis-truncation, no clipping, no overlap at AX sizes; layouts adapt (stack, wrap, `ViewThatFits`, scroll). Long text wraps or scrolls rather than fitting one line.
- **D-09:** Charts (Swift Charts / SwiftUICharts) render **fixed-size** (geometry exempt) but expose an **accessibility series** — per-point labels/values plus a one-line trend summary — so VoiceOver conveys what sight shows. The gamified character UI is likewise **exempt from scaling but labeled** (accessibilityLabel + state value).
- **D-10:** Gate = two layers: (1) machine-checked adoption sweep — every manifest surface's root view applies the **reworked** `.accessibleDynamicType()` (grep over the D-03 manifest, 1:1 mapping, zero unaccounted). REWORK REQUIRED: the helper's current defaults (`DynamicTypeScaling.swift` — `minScale 0.75`, `maxDynamicTypeSize .accessibility3`) contractually contradict D-08: the AX3 cap prevents AX4/AX5 from rendering at all, and the 0.75 shrink fights scaling toward ellipsis. Reworked primary-surface adoption must scale through AX5 with no cap and no shrink (layout adapts instead); (2) human AX5 walkthrough per surface recorded in phase UAT (screenshots, light+dark).

**Reduce Motion (A11Y-03) + Orphans (A11Y-05)**
- **D-11:** Breathing exercise is motion-essential and user-initiated → **exempt with a fallback mode**: under Reduce Motion it defaults to haptic pulses + text countdown (switchable in-session). The active session/summary views are covered by this decision, not the contrast/DT sweep.
- **D-12:** All **decorative** animation (transitions, character idle, celebrations/confetti, parallax/scroll effects) blanket-stops under Reduce Motion via **one app-wide helper** (single Environment value / view modifier, e.g. `.wellnessMotion()`): transitions cross-fade, character holds a static pose, celebrations become static badge + haptic.
- **D-13:** The **65 existing scattered Reduce Motion checks** consolidate onto the single helper this phase. Trust-gate shape: grep enumerates the helper's call sites; zero raw `isReduceMotionEnabled`/`\.reduceMotion` stragglers outside the helper's definition.
- **D-14:** A11Y-05 orphan = a **compiled view type unreachable from the navigation graph** (no Route case, no navigationDestination/sheet/fullScreenCover/reference from any reachable view). Method: reachability audit outward from the 4 tab roots against Route.swift; orphans are **deleted from disk** (no `#if` hiding). The uncompiled legacy set (repo-root `StressMonitor/{Models,Services,Views}/`) is not part of this gate — recorded as separate repo hygiene.

### Claude's Discretion

(None — all 14 decisions locked; UI-SPEC assumptions 1–5 carry planner discretion within the locked contracts.)

### Deferred Ideas (OUT OF SCOPE)
- Onboarding and Paywall accessibility (exempt this phase per D-01) — candidate for a future polish phase, especially if App Review feedback ever flags the paywall.
- Deleting the uncompiled legacy source set (repo-root `StressMonitor/{Models,Services,Views}/`) — repo hygiene, not compiled-binary accessibility; separate cleanup.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-01 | All touch targets meet the 44pt minimum | `.minimumTouchTarget(_:)` helper verified (`AccessibilityModifiers.swift:12-14,50-58` — frame + contentShape); `DesignTokens.Layout.minTouchTarget = 44` verified; known risk classes enumerated in UI-SPEC (icon-only buttons, mood check-in, quick-action tiles); 52pt buttons comply by construction |
| A11Y-02 | Color contrast passes WCAG AA on primary surfaces | WCAG formula independently implemented and validated; full ratio matrix computed (current + retuned values) — retunes confirmed numerically; test mechanism designed (hosted test + `UIColor.resolvedColor(with:)`); dual-source-of-truth duplication found (`Color+Extensions.stress*` vs `StressCategory.color`) |
| A11Y-03 | Reduce Motion respected for animated views | Framework APIs verified (`accessibilityReduceMotion`, `hasMotion` auto-cross-fade iOS 17+, `accessibilityPrefersCrossFadeTransitions`); 66 raw refs / 13 files measured (baseline); consolidation surface mapped (3 helper files + 10 view files); no `simctl` Reduce Motion toggle — DEBUG launch-arg seam designed |
| A11Y-04 | Dynamic Type adopted on primary screens | Current helper defaults verified verbatim (`0.75` / `.accessibility3` at `DynamicTypeScaling.swift:126,145`); rework contract specified (no cap, no shrink, `lineLimit(nil)`); typography retrofit mechanism identified (text-style anchoring / `@ScaledMetric`); `simctl ui content_size accessibility-extra-extra-extra-large` enables scripted AX5 walkthroughs |
| A11Y-05 | Orphaned redesign views deleted | Xcode project mechanics verified — app sources are a `PBXFileSystemSynchronizedRootGroup` (delete-from-disk = out-of-build, no pbxproj surgery); Periphery 2.x pre-installed locally for a definitive cross-check (`--retain-swift-ui-previews` off = preview-only refs flagged); extension-method false-positive classes identified concretely (`StressCategory.displayName` lives in orphan-candidate `Badge.swift`; `ShimmerEffectView` live via `.shimmerLoading()`) |
</phase_requirements>

## Summary

Phase 3 is a remediation phase over an existing SwiftUI codebase whose accessibility infrastructure already exists in skeleton form — `.minimumTouchTarget(44)`, `.stressDualCoding`, `.accessibilityChart(description:value:)`, `VoiceOverLabels`, `Animation.wellness(reduceMotion:)`, `animateIfMotionAllowed` are all defined and partially adopted — but whose defaults actively contradict the phase's contracts. The three contract-contradicting defaults are verified verbatim in source: `.accessibleDynamicType(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3)` (`DynamicTypeScaling.swift:126,145`), `accessibleWellnessType()`'s `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` + `.minimumScaleFactor(0.7)` (`Font+WellnessType.swift:44-49`), and `AnyTransition.accessibleOpacity(reduceMotion:)` returning `.identity` (hard cut) where D-12 requires a cross-fade (`Animation+Wellness.swift:76-84`). The work is rework-and-adopt, not greenfield.

The contrast math is done: this research independently implemented the WCAG relative-luminance formula (validated: black/white = 21.00, thresholds per W3C G18/G145) and reproduced the UI-SPEC's full ratio matrix exactly — every current failure (secondary text 4.24/4.32 light, ripple 1.97/2.00 light, stress indicator light set 1.39–2.18) and every recommended retune (`#6B6E7B` → 4.98/5.07, ripple-light `#0891B2` → 3.62, indicator candidates 3.42–5.82) checks out numerically, and `#0891B2` already exists in the palette as `Wellness.calmBlue` light. One new finding the UI-SPEC under-specifies: white-on-`#4FC3F7` is 2.00 in **both** appearances (it is a fixed, non-adaptive color), so the "dark keep `#4FC3F7`" half of the ripple retune is safe only as stroke/glyph accent on dark backgrounds — never as a white-text fill in either appearance. The D-06 test matrix must therefore model pairs by *usage class* (text pair, large-text/UI pair, fill-with-white-text pair).

The riskiest requirement is A11Y-05's deletion audit. Three mechanics are now ground-truthed: (1) the app sources folder is a `PBXFileSystemSynchronizedRootGroup` (objectVersion 77) whose only membership exceptions are `Info.plist` and four Lato font files — so deleting a `.swift` file from disk removes it from the app target with **zero pbxproj edits**, and a dangling-pbxproj-reference risk does not exist for source files; (2) Periphery (repo moved to `peripheryapp/periphery`, 6,182 stars, active 2026-08; binary pre-installed at `/opt/homebrew/bin/periphery`) gives a compiler-grade reachability cross-check, and omitting `--retain-swift-ui-previews` flags preview-only-referenced views as unused — matching D-14's "unreachable from the navigation graph" definition; (3) the UI-SPEC's known false-positive classes are real and concretely instantiated — `StressCategory.displayName` is defined inside orphan-candidate `Badge.swift:45` while referenced by live code, and `ShimmerEffectView` reads as an orphan but is live via `.shimmerLoading()` (`AnimationPresets.swift:80`). Also corrected: `IAPPremiumView` is referenced from `PaywallView` (not an orphan).

**Primary recommendation:** Sequence the phase as (1) contrast token retunes + D-06 unit test first (self-contained, immediately machine-checkable), (2) Dynamic Type helper rework + typography anchoring + adoption sweep, (3) Reduce Motion helper consolidation, (4) orphan deletion **last** so it deletes superseded helper variants and dead views rather than colliding with in-flight edits — then close with the two trust-gate records (D-13 RM grep, D-10 DT adoption grep) mirroring the phase-2 pattern.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 44pt hit-target enforcement | App UI layer (SwiftUI views) | Design-system components | Hit areas are view-level `frame`/`contentShape` concerns; `DesignTokens.Layout.minTouchTarget` supplies the constant |
| WCAG contrast truth | Theme token layer (`Theme/`) | Unit-test target (assertion) | D-04 pins values in tokens; the test reads the tokens — single source, enforced in CI |
| Contrast *resolution* for tests | Test target (hosted, UIKit) | — | `Color(light:dark:)` resolves through `UIColor`; only the hosted test bundle can resolve both appearances |
| Reduce Motion decision | One app-wide view modifier (`Utilities/`) | SwiftUI environment | D-12: single helper owns every read of `\.accessibilityReduceMotion` |
| Reduce Motion *verification* | Simulator (human/UAT walkthrough) | DEBUG launch-arg seam | No `simctl` toggle exists; in-app seam needed for scripted checks |
| Dynamic Type scaling | View modifier + `Theme/Font` tokens | Per-view layout adaptation (stack/wrap/scroll) | Modifier sets no-cap/no-shrink contract; layout adapts per surface |
| AX5 walkthrough execution | Simulator + `simctl ui content_size` | UAT record (screenshots) | CLI-settable; light/dark via `simctl ui appearance` |
| Chart accessibility series | First-party chart views + `AccessibilityModifiers` | — | Trends charts are custom SwiftUI views (verified: `TrendsView` uses `StressBarChartView`/`HRVTrendChart`, no `import Charts`); Swift Charts appears only in Dashboard `SparklineChart`/`MiniLineChartView` |
| Orphan reachability truth | Compiler build (delete-compile) | Periphery scan (cross-check) | D-14: delete-compile is ground truth; grep BFS is the input list |
| Watch token parity | Watch target's duplicated `Theme/` | App `Theme/` (source of retunes) | No shared framework — watch has its own `StressCategory.swift`, `Color+Extensions.swift`, `WatchDesignTokens.swift` (verified on disk) |
| Widget contrast | Widget views (system `.primary`/`.secondary` on materials) | — | D-07: Apple-guaranteed pairs; `tier.accent` dual-coded, never meaning-alone |
| Widget + watch Dynamic Type anchoring | Widget views + watch `Views/` (per-site `Font.system(size:relativeTo:)` anchors) | Inline dated exceptions (accessory-template / gauge-class sites) | D-02: widget (gallery + lock-screen + Live Activity) and watch surfaces join the Dynamic Type sweep; the targets share no Theme tokens or helper with the app, so the anchor is per-site at each target's existing point sizes; 140 fixed-size sites + 9 `minimumScaleFactor` shrinks measured (30 widget Views / 8 Live Activity / 76 watch Views+Components / 26 complications incl. providers and bundle; shrinks: 5 watch Views, 4 complications) |

## Standard Stack

### Core

No new app dependencies. This phase is entirely first-party Swift/SwiftUI/UIKit + one optional dev-only CLI. (Project decision: "Dependencies: None (system only)".)

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| SwiftUI a11y APIs (`accessibilityReduceMotion`, `dynamicTypeSize`, `@ScaledMetric`, accessibility modifiers) | iOS 18.6 SDK (Xcode 26.3) | All four requirement areas | First-party; verified against Apple docs |
| `TransitionProperties.hasMotion` | iOS 17+ | Auto cross-fade under Reduce Motion | Framework-native path for D-12's cross-fade rule [CITED: developer.apple.com/documentation/swiftui/transitionproperties/hasmotion] |
| UIKit `UIColor.resolvedColor(with:)` | iOS 13+ | Resolve `Color(light:dark:)` dynamic providers per appearance inside the hosted contrast unit test | Standard mechanism; test target is hosted (`TEST_HOST` app binary, verified in pbxproj) |
| XCTest / Swift Testing (`import Testing`) | existing | D-06 contrast suite | Repo already mixes both (verified in `StressMonitorTests/`) |
| Periphery (dev-only, pre-installed) | local binary | D-14 cross-check reachability audit | Compiler-grade unused-declaration analysis; `--retain-swift-ui-previews` off matches D-14 |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `xcrun simctl ui <dev> content_size accessibility-extra-extra-extra-large` | Xcode 26.3 (verified locally) | Set AX5 for walkthroughs | Per-surface UAT; reset to `large` after |
| `xcrun simctl ui <dev> appearance light\|dark` | Xcode 26.3 (verified locally) | Appearance flips for contrast/AX5 screenshots | UAT light+dark pairs |
| `xcrun simctl ui <dev> increase_contrast enabled` | Xcode 26.3 (verified locally) | Optional Increased-Contrast pass | Only if validating `colorSchemeContrast` paths (`AccessibilityContrastModifier` reads it) |
| Accessibility Inspector (Xcode bundled) | Xcode 26.3 | Hit-target audit per surface (A11Y-01) | UAT record per UI-SPEC verification row |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Token-pair unit test (D-06) | Snapshot/screenshot color sampling | Rejected by D-06 — screenshots are not enumerable or deterministic in CI; tokens are |
| Periphery cross-check | Pure grep BFS only | Periphery uses the compiler's index; catches protocol/extension reachability grep misses. Keep grep BFS as the *input* list, Periphery + delete-compile as judges |
| `.environment(\.accessibilityReduceMotion, true)` injection for tests | DEBUG launch-arg seam | Injection is not available — the env value is read-only (`{ get }`) [CITED: developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion]; the seam follows the repo's `DemoMode` / `-mock-iap` launch-arg precedent |
| Text-style-anchored fonts (`Font.system(.title2).weight(.semibold)`) | `@ScaledMetric` per view | Tokens are static `Font` values — `@ScaledMetric` is a view-level wrapper and cannot live in `Font.WellnessType` statics; use text-style anchoring at the token level, `@ScaledMetric` only for per-view layout values (paddings, gauges) |

**Installation:** none (`brew install periphery` only if the local binary is ever missing — it is present at `/opt/homebrew/bin/periphery`).

**Version verification (this session):** Xcode 26.3 (Build 17C529); Periphery binary runs (`periphery scan --help` verified); simulator inventory includes iPhone 16 (78AEB511…, the CI destination) and iPhone 17 (5DD825B4…, the `config.json` destination) — both available.

## Package Legitimacy Audit

> This phase installs **no app packages**. One dev-only tool was examined.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| periphery (dev CLI, optional) | Homebrew | ~7 yrs (repo active, pushed 2026-08-12) | 6,182 GitHub stars | github.com/peripheryapp/periphery (moved from peripheryio) | OK | Approved — dev tool only, never shipped |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*Note: `chartAccessibility` — a Swift Charts modifier remembered from training data — was probed against the SDK and **does not exist** in Xcode 26.3 (`Charts.swiftmodule/*.swiftinterface` grepped across 4 platform variants: zero occurrences). It is excluded from all recommendations. This corrects a would-be hallucinated API before it reached a plan.*

## Architecture Patterns

### System Architecture Diagram

```
                      ┌────────────────────────────────────────────────┐
                      │  GATES (phase artifacts, phase-2 trust-gate    │
                      │  pattern: enumeration, not counts)             │
                      │  1. Contrast suite green (CI, permanent)       │
                      │  2. DT adoption grep = 14/14 manifest surfaces │
                      │  3. RM grep: 0 raw refs outside helper def     │
                      │  4. Delete-compile clean (3 targets)           │
                      └───────────────▲────────────────▲───────────────┘
                                      │                │
  ┌───────────────────────┐   ┌───────┴──────┐  ┌──────┴────────────┐
  │ A11Y-02 Contrast      │   │ A11Y-04 DT   │  │ A11Y-03 RM        │
  │                       │   │              │  │                   │
  │ Theme tokens ─────────┼──▶│ Font tokens  │  │ .wellnessMotion() │
  │  retune in place      │   │  + reworked  │  │  (ONE helper)     │
  │  (D-04)               │   │  .accessible-│  │   reads env once; │
  │        │              │   │  DynamicType │  │   views call it   │
  │        ▼              │   │  (D-10)      │  │   (D-12/D-13)     │
  │ ContrastUnitTests     │   │        │     │  │        ▲          │
  │  resolve light/dark   │   │        ▼     │  │  66 raw refs → 0  │
  │  via UIColor, assert  │   │ adoption     │  │  (13 files)       │
  │  4.5:1 / 3:1 (D-06)   │   │ sweep grep   │  │        │          │
  └───────────────────────┘   └───────┬──────┘  └──────┬────────────┘
                                      │                │
                              ┌───────▼────────────────▼───────┐
                              │ 14 manifest surfaces (D-01/D-03)│
                              │ 4 tab roots + 10 Route children │
                              │ + widget/watch contrast pairs   │
                              └───────┬────────────────────────┘
                                      │
  ┌───────────────────────────────────▼───────────────────────────────┐
  │ A11Y-05: orphan deletion (LAST)                                   │
  │ UI-SPEC 81 candidates ──▶ grep BFS input                          │
  │   + Periphery scan (--retain-swift-ui-previews off) cross-check   │
  │   + extension-method false-positive screen (displayName in        │
  │     Badge.swift; ShimmerEffectView live via .shimmerLoading())    │
  │   ▼ delete from disk (sync group ⇒ auto-out-of-build)             │
  │ delete-compile all 3 targets = ground truth                       │
  └───────────────────────────────────────────────────────────────────┘

  A11Y-01 runs across the same 14 surfaces: .minimumTouchTarget(44) /
  intrinsic ≥44pt controls; Accessibility Inspector scan recorded in UAT.
```

### Recommended Project Structure

```
StressMonitor/StressMonitor/
├── Theme/
│   ├── DesignTokens.swift            # unchanged values; A11Y-01 constant lives here
│   ├── Color+Wellness.swift          # D-04 retunes: adaptiveSecondaryText light, ripple adaptive
│   ├── Color+Extensions.swift        # D-04 retunes: settingsRippleBlue/accentTeal adaptive,
│   │                                 #   textTertiary/textDescriptive alias, settingsBackground dark unify
│   └── Font+WellnessType.swift       # D-10: anchor tokens to text styles; rework accessibleWellnessType*
├── Utilities/
│   ├── AccessibilityModifiers.swift  # A11Y-01 mechanism + D-09 series extension; fix caption-in-hue text
│   ├── DynamicTypeScaling.swift      # D-10 rework (delete AX3 cap + shrink defaults)
│   ├── Motion.swift (new, or rework Animation+Wellness.swift)  # D-12 single helper
│   ├── AnimationPresets.swift        # route statics through the helper (D-13)
│   ├── HighContrastModifier.swift    # DELETED (D-05)
│   ├── PatternOverlay.swift          # 0 call sites — audit for deletion (A11Y-05 class)
│   └── ColorBlindnessSimulator.swift # 0 call sites — audit for deletion (A11Y-05 class)
└── StressMonitorTests/
    └── ContrastComplianceTests.swift (new; manual pbxproj registration)
```

### Pattern 1: Contrast unit test — resolve tokens, assert by usage class

**What:** One hosted Swift Testing suite resolves each semantic token in both appearances and asserts a ratio floor per *usage class* (text 4.5:1, large-text/UI 3:1, white-on-fill 3:1-large only).
**When to use:** The D-06 permanent gate.

```swift
// Source: W3C G18/G145 formula (w3.org/WAI/GL/WCAG20/TECHS-general/G18.html) —
// luminance L = 0.2126R + 0.7152G + 0.0722B (sRGB linearized);
// ratio = (L1 + 0.05) / (L2 + 0.05), L1 lighter. Validated: black/white = 21.00.
func contrastRatio(_ fg: UIColor, on bg: UIColor) -> CGFloat { /* implement once */ }

func resolved(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
    UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
}

@Test("Secondary text passes AA on canvas, both appearances", arguments: [.light, .dark])
func secondaryTextOnCanvas(style: UIUserInterfaceStyle) {
    let ratio = contrastRatio(resolved(Color.Wellness.adaptiveSecondaryText, style),
                              on: resolved(Color.Wellness.adaptiveBackground, style))
    #expect(ratio >= 4.5)
}
```

The matrix to assert (from `Color+Wellness.swift:58-79`, `Color+Extensions.swift:104-130`):

| Pair | Class | Light (cur → retuned) | Dark (cur → retuned) |
|------|-------|----------------------|----------------------|
| `adaptivePrimaryText` / `adaptiveBackground` | text 4.5 | 18.21 (pass) | 18.73 (pass) |
| `adaptivePrimaryText` / `adaptiveCardBackground` | text 4.5 | 18.54 (pass) | 16.67 (pass) |
| `adaptiveSecondaryText` / canvas | text 4.5 | **4.24 FAIL → `#6B6E7B` = 4.98** | 7.38 (pass) |
| `adaptiveSecondaryText` / card | text 4.5 | **4.32 FAIL → 5.07** | 6.57 (pass) |
| `textTertiary` `#808080` / cream | text 4.5 | **3.88 FAIL → alias secondary** | — |
| `textDescriptive` `#848484` / cream | text 4.5 | **3.67 FAIL → alias secondary** | — |
| `primaryBlue` / canvas | UI 3.0 | 3.95 (pass) | 5.14 (pass) |
| white / `primaryBlue` fill | large-text 3.0 | 4.02 (pass) | 3.65 (pass) |
| ripple / canvas | UI 3.0 | **1.97 FAIL → light `#0891B2` = 3.62** | 9.35 (pass, keep `#4FC3F7`) |
| white / ripple fill | large-text 3.0 | **2.00 FAIL both modes → light fill `#0891B2` = 3.68** | **2.00 — dark fill must NOT stay `#4FC3F7` under white text** |

Stress indicators (3:1 UI bar, on cream): current relaxed `#34C759` 2.18 / moderate `#FFD60A` 1.39 / high `#FF9500` 2.16 all FAIL; candidates verified: relaxed `#00A000` 3.42, moderate `#8A5A00` 5.82 or `#9A5B00` 5.33, high `#B25400` 4.96 or `#CC0000` 5.78; mild `#007AFF` 3.95 and severe `#FF3B30` 3.49 pass as-is. Dark set all pass (5.14–13.27). `Color.accessibleStressColor`'s `highContrast` moderate `#FFA500` = 1.94 on cream (fails even 3:1) — fix value and the false "WCAG AAA (7:1)" comment at `Color+Wellness.swift:139`. All numbers [VERIFIED: local computation, formula per CITED W3C G18/G145].

**Dual-source-of-truth hazard:** `Color+Extensions.swift:36-40` (`stressRelaxed…stressSevere`) duplicates `StressCategory.color` (`Models/StressCategory.swift:13-26`) value-for-value. The test must pin whichever survives as the source; deleting the duplicate constants is an A11Y-05-class cleanup if grep confirms no remaining direct users.

### Pattern 2: Reworked `.accessibleDynamicType()` — no cap, no shrink

**What:** Defaults flip from contract-violating to contract-satisfying:

```swift
// Current (DynamicTypeScaling.swift:126,145 — VERIFIED verbatim):
public init(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3)
public func accessibleDynamicType(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3) -> some View

// Reworked (D-10): scales through AX5, never shrinks, always wraps
func accessibleDynamicType() -> some View {
    modifier(AccessibleDynamicTypeModifier())
}
// body: content.lineLimit(nil)   — no .dynamicTypeSize(...) range, no .minimumScaleFactor
```

**When to use:** every manifest surface root (adoption gate, 1:1 vs the D-03 manifest; current adopters of the old form: `DashboardView:41`, `SettingsView:56`, `MiniWalkView:98`, `BreathingExerciseView:45`, `MeasurementHistoryView:22` — orphan, `IAPPremiumView:98`/`PaywallView:72` — exempt).
**Also in the same file:** delete or rework `AdaptiveTextSizeModifier` (`DynamicTypeScaling.swift:35-98`) — it hand-rolls a 12-step multiplier table (0.8…2.6) plus `minimumScaleFactor(0.7)`, duplicating what text-style scaling does natively; and `.limitedDynamicType()` (AX3 cap, `:104-117`) survives only behind a dated exception note per D-10.

### Pattern 3: Typography retrofit — text-style anchoring

**What:** `Font.WellnessType` statics are bare `Font.system(size:)` (verified `Font+WellnessType.swift:13-36`) and ignore Dynamic Type. Anchor each to the text style whose default size equals today's rendered size:

| Token (current, verified) | Anchored replacement | Default-size anchor |
|---------------------------|----------------------|---------------------|
| `cardTitle` 28 bold | `Font.system(.title).weight(.bold)` | `.title` = 28 [ASSUMED] |
| `sectionHeader` 22 semibold | `Font.system(.title2).weight(.semibold)` | `.title2` = 22 [ASSUMED] |
| `body` 17 regular | `Font.system(.body)` | `.body` = 17 [ASSUMED] |
| `bodyEmphasized` 17 semibold | `Font.system(.headline)` | `.headline` = 17 semibold [ASSUMED] |
| `caption` 13 regular | `Font.system(.footnote)` | `.footnote` = 13 [ASSUMED] |
| `caption2` 11 regular | `Font.system(.caption2)` | `.caption2` = 11 [ASSUMED] |
| `heroNumber` 72 / `largeMetric` 48 rounded bold | unchanged — gauge class (D-09), labeled via `.accessibilityStressLevel` | exempt |

**Byte-identical-at-default is a UI-SPEC hard rule.** The ramp sizes above are training-data values — the executor MUST verify rendered size parity at the Large (default) setting before adopting (one `#Preview` with both old and new font side-by-side, or an `ImageRenderer` measurement). If a style's default drifts on this SDK, compensate with a `@ScaledMetric`-scaled point size on the specific token instead.

### Pattern 4: One Reduce Motion helper

**What:** D-12's `.wellnessMotion()` owns every read of `\.accessibilityReduceMotion`. Baseline measured this session: **66 raw references across 13 files** (UI-SPEC recorded 65 — 1-ref drift; re-baseline at execution):

`CharacterAnimationModifier`, `AccessibilityModifiers`, `Animation+Wellness`, `AnimationPresets`, `BreathingExerciseView`, `BreathingCircle`, `RippleBreathingView`(orphan candidate), `LearningPhaseCard`, `MetricCardView`(orphan candidate), `SkeletonBlock`, `StressRingView`, `MiniWalkInstructionCard`, `MiniWalkView` [VERIFIED: grep, app target]

**Framework-native pieces to prefer inside the helper** [CITED: Apple docs via Context7]:
- `TransitionProperties.hasMotion` (iOS 17+): custom transitions declaring `hasMotion` are **automatically replaced by opacity** under Reduce Motion — use for transition behaviors instead of branching.
- Cross-fade rule (D-12) — the existing `AnyTransition.accessibleOpacity/Scale/Slide(reduceMotion:)` return `.identity` under RM (`Animation+Wellness.swift:76-102`) — a hard cut, which D-12 explicitly rejects ("fades are allowed; hard `.identity` cuts are not the goal"). The rework returns `.opacity` under RM.
- `Animation.wellness/breathing/fidget/shake/dizzy(reduceMotion:)` (`:12-37`) take an explicit `Bool` — every caller must first read the env, which is the 66-ref scatter source. Rework to env-reading modifiers or delete in favor of the single helper.
- `AnimationPresets` statics (`micro/quick/standard/emphasis/springy/stiffSpring/slowSpring/smooth`, `:5-29`) are RM-unaware — route through the helper.

**Verification seam (designed):** `\.\accessibilityReduceMotion` is read-only (`{ get }`) [CITED] and `simctl` cannot toggle it — so add a DEBUG-only launch argument (`-a11y-reduce-motion`, DemoMode/`-mock-iap` precedent) that the helper ORs into its motion-allowed decision. That makes RM behavior scriptable for screenshots without touching Release paths.

**Ordering note:** run deletion (A11Y-05) either before consolidation or re-grep after it — `RippleBreathingView` and `MetricCardView` are both orphan candidates and RM-ref files; deleting first shrinks the consolidation set.

### Pattern 5: D-14 orphan audit pipeline

1. **Input:** UI-SPEC's 81-file candidate list (working notes).
2. **Screen known false-positive classes (verified instances):**
   - Extension members defined in orphan-candidate files but used by live code: `StressCategory.displayName` lives in `Badge.swift:45` [VERIFIED] while `StressDualCodingModifier` and `StressCategory.accessibilityDescription` use it → move the extension, then delete the file.
   - In-file helper usage: `ShimmerEffectView` is live via `.shimmerLoading()` (`AnimationPresets.swift:80`) [VERIFIED] — a file-level constructor grep marks it orphan; it is not.
   - Cross-references from exempt surfaces: `IAPPremiumView` ← `PaywallView` [VERIFIED] — not an orphan.
3. **Cross-check:** `periphery scan --workspace StressMonitor/StressMonitor.xcodeproj --schemes StressMonitor --targets StressMonitor` (also `StressMonitorWidgetExtension`, watch target) with **`--retain-swift-ui-previews` NOT set**, `--report-exclude` for anything intentionally retained. Diff Periphery's unused-set against the candidate list; every disagreement is a hand-review row in the audit record.
4. **Delete from disk** — the app folder is a `PBXFileSystemSynchronizedRootGroup` whose only membership exceptions are `Info.plist` and 4 Lato fonts [VERIFIED: pbxproj `PBXFileSystemSynchronizedBuildFileExceptionSet` section] → no pbxproj surgery for source deletions.
5. **Ground truth:** delete-compile of all three targets (app/watch/widget) per batch; mirror nothing watch-side unless the watch target declares its own copy (it does for `StressCategory`, `Color+Extensions` — verified on disk).
6. **Record:** dated audit artifact (UI-SPEC's "phase working notes"), enumeration + per-file disposition, phase-2 trust-gate style.

### Anti-Patterns to Avoid

- **Per-site color patches** — D-04 forbids; retune tokens only. The 424 inline `Color(hex:)` sites are out of scope except where a manifest surface's inline color fails the sweep (then it moves to a token).
- **`minimumScaleFactor` as a truncation fix** — it shrinks first, truncates second; both violate D-08. The reworked modifier has none.
- **`content.animation(animation, value: UUID())`** — `AccessibleAnimationModifier` (`AccessibilityModifiers.swift:62-73`) animates on *every body evaluation* because `UUID()` is fresh each time; fix or fold into the helper.
- **Caption text in the stress hue** — `StressDualCodingModifier` renders `Text(category.displayName).font(.caption).foregroundColor(category.color)` (`:39-41`); UI-SPEC contrast rule: category label text must render in `adaptivePrimaryText`/`adaptiveSecondaryText`, never the hue.
- **`.identity` transitions under RM** — hard cuts; use `.opacity` (D-12).
- **Keeping dead helpers "just in case"** — `HighContrastModifier` (0 refs, verified), `PatternOverlay`, `ColorBlindnessSimulator` (0 refs, verified) are the D-05/A11Y-05 deletion class.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-view RM branching | 66 scattered env reads | One `.wellnessMotion()` helper + `hasMotion` transitions | D-12/D-13 contract; framework auto-cross-fades `hasMotion` transitions |
| Custom DT multiplier tables | `AdaptiveTextSizeModifier`'s 12-row switch | Text-style-anchored fonts / `@ScaledMetric` | Native scaling follows the real system curve (including future ramps); the table drifts |
| Chart audio-graph/per-point exploration engine | Custom gesture/VoiceOver machinery | Plain `accessibilityLabel`/`accessibilityValue`/`accessibilityElement(children:)` on chart containers + `VoiceOverLabels` per-point strings | `chartAccessibility` does not exist in this SDK (verified) — and the app's `.accessibilityChart(description:value:)` + `timelinePoint` shape already works |
| Hit-target sizing per control | Ad-hoc `frame(width: 44, height: 44)` | `.minimumTouchTarget(DesignTokens.Layout.minTouchTarget)` | Existing helper adds `contentShape(Rectangle())`; token is the assertable constant |
| Reachability analysis by grep alone | Bigger/better grep | Periphery + delete-compile | Grep misses extension members and preview-only refs (both instantiated above); the compiler's index does not |

**Key insight:** every mechanism this phase needs already exists in the repo in skeleton form — the work is correcting defaults, adopting, and deleting the superseded variants, not inventing.

## Runtime State Inventory

> Phase involves refactor-class changes (deletions, helper consolidation, token value changes). Canonical question: after every file edit, what runtime systems still hold the old state?

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no persisted schema, key, or user defaults value changes (verified: phase touches only view code + `Theme/` values, which are not persisted) | None |
| Live service config | None — no external service consumes these tokens; widget data hand-off (`WidgetDataProvider` latest_* keys) untouched by this phase's surfaces (widget *views* change only) | None |
| OS-registered state | None — no task scheduler/pm2/launchd registrations; no entitlements changes | None |
| Secrets/env vars | None — no config keys touched (`SUPABASE_*`, `STOREKIT_*` unaffected) | None |
| Build artifacts | 1) Deleted orphan files self-remove from the app target (synchronized group, verified) — but the **watch target keeps its own duplicated copies** (`StressCategory.swift`, `Color+Extensions.swift`, `WatchDesignTokens.swift`): token retunes must be mirrored there or the two targets diverge; 2) new `ContrastComplianceTests.swift` needs **manual 4-point pbxproj registration** (BuildFile + FileReference + group child + Sources phase — the phase-2 `A026/B026` precedent at `project.pbxproj:48,144,323,553`), because the `StressMonitorTests` target has NO synchronized groups; 3) DerivedData/`build/` staleness after mass deletion — clean build of all targets before the delete-compile verdict | Mirror watch tokens; register test file manually; clean rebuild |

**Nothing-else found in categories 1–4 — verified by reading the phase's touched-file classes (SwiftUI views, `Theme/`, `Utilities/`, test target) and confirming none are persisted, registered, or remotely consumed.**

## Common Pitfalls

### Pitfall 1: The AX3 cap hides every AX-size failure
**What goes wrong:** With `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` at the root, AX4/AX5 render *as AX3* — a walkthrough at AX5 "passes" while the real user setting is unreachable.
**Why it happens:** The current helper defaults (verified at `DynamicTypeScaling.swift:126,145` and adopted on 4 manifest surfaces) were written as layout protection.
**How to avoid:** Rework defaults first, re-adopt, then run the walkthrough. Any surface that genuinely cannot adapt gets `.limitedDynamicType()` + a dated exception (D-10).
**Warning signs:** Screenshots at AX5 look identical to AX3; `simctl ui content_size` prints `accessibility-extra-extra-extra-large` but text doesn't grow.

### Pitfall 2: Ripple retune fixes light, silently keeps a dark fill failure
**What goes wrong:** `settingsRippleBlue`/`accentTeal` are fixed `#4FC3F7` (`Color+Extensions.swift:109,111`); white-on-`#4FC3F7` = 2.00 in **both** appearances. Making the token adaptive (light `#0891B2`) fixes the light fill but if any dark-mode fill keeps `#4FC3F7` under white text it still fails.
**Why it happens:** The UI-SPEC accent table only lists the light fill failure; my computation shows the dark-mode white-on-fill is the same 2.00.
**How to avoid:** The D-06 matrix asserts white-on-fill pairs for **both** appearances of every fill token (usage-class modeling).
**Warning signs:** Contrast test asserts only `accent-on-background` pairs, never `white-on-accent-fill`.

### Pitfall 3: Deleting `Badge.swift` breaks live code via the extension member
**What goes wrong:** `Badge.swift` is an A11Y-05 orphan candidate, but `StressCategory.displayName` is defined there (`Badge.swift:45`) and consumed by live `StressDualCodingModifier`/`accessibilityDescription`.
**Why it happens:** File-level constructor-grep reachability (the UI-SPEC scan method) cannot see extension-property usage.
**How to avoid:** Before deleting any candidate, grep for each `extension` member it declares; relocate live members. Periphery's index-based analysis catches most of these; the delete-compile catches the rest.
**Warning signs:** Delete-compile fails with "no member 'displayName'" after a "clean" deletion.

### Pitfall 4: Deletion/consolidation ordering collisions
**What goes wrong:** Consolidating 66 RM refs while orphan files still exist wastes work on files about to die (`RippleBreathingView`, `MetricCardView`); conversely deleting first without re-baselining invalidates the D-13 count.
**Why it happens:** Two large mechanical sweeps over the same file space.
**How to avoid:** Delete first (shrinks the sweep), then consolidate, then run both trust-gate greps against the final tree; every gate records its own dated baseline.
**Warning signs:** RM grep baseline (66/13) cited from research instead of re-measured at gate time.

### Pitfall 5: Screenshot-based contrast "verification"
**What goes wrong:** Pixel-sampled contrast checks flake across simulators/appearances and cannot run per-commit.
**Why it happens:** Contrast feels visual; but the values live in tokens.
**How to avoid:** D-06 unit test only — resolve `UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle:))` in the hosted test and assert the formula.
**Warning signs:** Any plan step that validates contrast via screenshot diffing.

### Pitfall 6: The "65 refs" number is already stale
**What goes wrong:** Trust gate compares against a wrong baseline and either blocks on phantom refs or passes on unaccounted ones.
**Why it happens:** This research measured 66/13 (UI-SPEC recorded 65); more drift lands during the phase.
**How to avoid:** Gates enumerate *by file and construct*, never by count (the phase-2 pattern); re-run the grep at gate time and paste output into the record.
**Warning signs:** A trust-gate table with counts but no pasted grep output.

## Code Examples

### Verified current-state quotes (the rework contracts)

```swift
// Utilities/DynamicTypeScaling.swift:122-148 — the D-10 rework target [VERIFIED]
public struct AccessibleDynamicTypeModifier: ViewModifier {
    let minimumScale: CGFloat
    let maxDynamicTypeSize: DynamicTypeSize

    public init(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3) {
        self.minimumScale = minimumScale
        self.maxDynamicTypeSize = maxDynamicTypeSize
    }

    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...maxDynamicTypeSize)
            .minimumScaleFactor(minimumScale)
            .lineLimit(nil)
    }
}
```

```swift
// Utilities/AccessibilityModifiers.swift:11-14, 50-58 — the A11Y-01 mechanism [VERIFIED]
func minimumTouchTarget(_ size: CGFloat = 44) -> some View {
    modifier(MinimumTouchTargetModifier(minSize: size))
}
struct MinimumTouchTargetModifier: ViewModifier {
    let minSize: CGFloat
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}
```

```swift
// Theme/Color+Wellness.swift:57-79 — retune targets [VERIFIED]
static let adaptiveBackground = Color(light: Color(hex: "#FFFDF6"), dark: Color(hex: "#121212"))
static let adaptiveCardBackground = Color(light: Color.white, dark: Color(hex: "#1E1E1E"))
static let adaptivePrimaryText = Color(light: Color(hex: "#101223"), dark: Color.white)
static let adaptiveSecondaryText = Color(light: Color(hex: "#777986"), dark: Color(hex: "#9CA3AF"))
```

### Trust-gate grep shapes (mirror `02-TRUST-GATE-RECORD.md`)

```bash
# D-10 layer 1 — DT adoption: every manifest surface enumerated, 1:1
for f in Views/DashboardView.swift Views/Action/ActionView.swift Views/Trends/TrendsView.swift \
         Views/Settings/SettingsView.swift Views/Settings/DataManagement/DataExportView.swift \
         Views/Settings/DataManagement/DataManageView.swift Views/Settings/DataManagement/DataDeleteView.swift \
         Views/Characters/CharacterCollectionView.swift Views/Settings/AppearanceSettingsView.swift \
         Views/Settings/AboutView.swift Views/Settings/WatchFacePreferencesView.swift \
         Views/History/MeasurementDetailView.swift Views/Breathing/BreathingExerciseView.swift \
         Views/MiniWalk/MiniWalkView.swift; do
  grep -L "accessibleDynamicType()" "StressMonitor/StressMonitor/$f" && echo "MISSING: $f"
done   # target: zero MISSING lines

# D-13 — RM consolidation: zero raw refs outside the helper's own definition
grep -rn "reduceMotion\|isReduceMotionEnabled\|accessibilityReduceMotion" \
  StressMonitor/StressMonitor --include="*.swift" \
  | grep -v "Utilities/<helper-file>.swift"
# target: zero output (helper file + BreathingExerciseView D-11 carve-out explicitly dispositioned)
```

### AX5 / appearance walkthrough (verified subcommands, Xcode 26.3)

```bash
xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large   # AX5
xcrun simctl ui <device> content_size large                                    # reset
xcrun simctl ui <device> appearance dark
# NOTE: there is NO `simctl ui ... reduce-motion` on Xcode 26.3 — verified by probe.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `if reduceMotion` branches per view | `TransitionProperties.hasMotion` auto-opacity (iOS 17+) | iOS 17 | Transitions cross-fade without branching; helper still needed for loops/scale/parallax |
| `UIAccessibility.isReduceMotionEnabled` UIKit checks | `@Environment(\.accessibilityReduceMotion)` in SwiftUI | iOS 13/14 | Environment is testable in previews per-view; UIKit global remains for non-view code |
| ClockKit complications | WidgetKit (this repo already migrated) | watchOS 9+ | Widget D-07 rules apply to widget-family surfaces |
| `chartAccessibility`-style chart modifiers (never existed in this SDK) | Plain SwiftUI accessibility on chart containers + per-point label strings | verified 2026-09-05 | Do not hunt for a charts-specific a11y API — the app's `.accessibilityChart` pattern is the mechanism |

**Deprecated/outdated:**
- `Animation.wellness/breathing/fidget/shake/dizzy(reduceMotion:)` explicit-Bool signatures — superseded by the D-12 helper (env-reading), delete after consolidation.
- `AnyTransition.accessible*(reduceMotion:)` `.identity` fallbacks — superseded by `.opacity` fallbacks (D-12 wording).
- `accessibleWellnessType*` AX3-cap + 0.7-shrink modifiers — superseded by the reworked `.accessibleDynamicType()` (UI-SPEC: "same rework or deleted in favor of one modifier").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | iOS text-style default ramp at Large: largeTitle 34, title 28, title2 22, title3 20, headline 17 (semibold), body 17, callout 16, subheadline 15, footnote 13, caption 12, caption2 11 | Typography retrofit | Tokens anchored to a style whose default differs render at a different size at the default setting — violates the byte-identical rule. Executor verifies parity with a side-by-side preview before adopting; `@ScaledMetric` fallback compensates |
| A2 | `UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle:))` resolves `Color(light:dark:)` dynamic providers correctly in a hosted unit test | Pattern 1 | If resolution fails, fall back to asserting the token's hex constants directly (test reads the same literals the `Color(hex:)` inits consume) — a design fallback, not a blocker |
| A3 | Swift Charts renders an automatic aggregate accessibility element per chart (audio graph claims unverifiable; per-mark VoiceOver exploration unverified) | Pattern 5 / D-09 | If aggregate a11y is absent, the app's container-level `.accessibilityChart(description:value:)` + trend-summary label already carries the requirement — no dependency on framework behavior |
| A4 | `xcrun simctl ui content_size` affects SwiftUI `@Environment(\.dynamicTypeSize)` in a running app (subcommand verified; the app-side propagation is standard behavior, not probed) | Walkthrough | If the app needs relaunch to pick up the change, relaunch after setting — minor |
| A5 | The UI-SPEC's 81-file orphan candidate list (living in "phase working notes") is accessible to the executor | Pattern 5 | If the notes artifact is missing, the grep BFS from tab roots + Route destinations regenerates it mechanically (UI-SPEC documents the method) |
| A6 | Periphery's index build succeeds against this project (proxy SPM products, spm-cache umbrella) | Pattern 5 | If the tool chokes on the proxy setup, the delete-compile ground truth alone closes the audit; Periphery is a cross-check, not a dependency |
| A7 | `accessibilityPrefersCrossFadeTransitions` (verified `{ get set }`) is a usable additional signal on iOS; its exact iOS semantics (RM ∧ cross-fade setting) are from docs digested via Context7 | Pattern 4 | If redundant with `hasMotion`, skip it — the helper's contract only needs `accessibilityReduceMotion` |

**Claims NOT assumed (verified this session):** all token hex values and helper defaults (Read from source with line refs); WCAG ratios (local computation, formula validated); RM ref baseline 66/13 (grep); pbxproj sync-group/exception mechanics (Read); `chartAccessibility` absence (SDK interface grep); `simctl ui` subcommand inventory (local probe); Periphery availability and flags (local binary + `--help` + gh api); test-target manual registration requirement (pbxproj Read); watch-side file duplication (ls + grep); orphan-audit false positives (`displayName` in `Badge.swift`, `IAPPremiumView` ← `PaywallView`, `ShimmerEffectView` via `.shimmerLoading()` — grep).

## Open Questions (RESOLVED)

1. **Trends/Action/DataManage empty states and locked-character 0.65-opacity text** (UI-SPEC unresolved rows)
   - What we know: flagged as planner assumptions in the UI-SPEC; locked-character dimming may drop card text below 4.5:1.
   - What's unclear: whether those surfaces can render zero rows in practice.
   - Recommendation: triage during the per-surface sweep with the documented NoDataCard shape; for locked characters, dim the illustration only, never the text (UI-SPEC's stated remedy).
   - **RESOLVED by 03-03 Task 3** (state-shape triage: NoDataCard branch or a recorded cannot-render-empty disposition per surface; locked-character dimming scoped to the illustration only, character a11y labels per D-09).
2. **Where does `Motion.swift` (the D-12 helper) live — new file vs reworked `Animation+Wellness.swift`?**
   - What we know: consolidation inputs span 3 utility files; repo convention is one-type-per-file with `Type+Feature` extensions.
   - Recommendation: planner's discretion; reworking `Animation+Wellness.swift` in place avoids a new file and preserves the `animateIfMotionAllowed` call sites already correct.
   - **RESOLVED by 03-05 Task 1** (rework `Animation+Wellness.swift` in place — no new `Motion.swift` file; the existing env-reading modifier shape is kept and becomes the single owner).
3. **Should `StressDualCodingModifier`'s caption text move to `adaptiveSecondaryText` before or after the token retune lands?**
   - What we know: both are contrast-sweep items; order doesn't affect correctness, only test sequencing.
   - Recommendation: land the retune + D-06 test first (green baseline), then the modifier change keeps the test honest.
   - **RESOLVED by 03-01 sequencing** (Tasks 1-2 land the retune + D-06 suite green first; Task 3 moves the caption onto the adaptive secondary token after the green baseline — the recommended order is the plan's task order).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / iOS SDK | build, delete-compile | ✓ | 26.3 (17C529) | — |
| iPhone 16 simulator | CI-parity test invocation (`_test.yml` destination) | ✓ | iOS 26.x (78AEB511-…) | iPhone 17 also installed (5DD825B4-…) — `config.json` destination |
| iPhone 17 simulator | `config.json` build/test commands | ✓ | (5DD825B4-…) | iPhone 16 (CI uses it) |
| Periphery | D-14 cross-check | ✓ | local binary `/opt/homebrew/bin/periphery` | delete-compile ground truth alone |
| `xcrun simctl ui content_size` | AX5 walkthroughs | ✓ | Xcode 26.3 (probed) | Manual Settings app |
| `simctl ui` Reduce Motion toggle | RM scripted verification | ✗ | — (no subcommand on 26.3 — verified) | DEBUG `-a11y-reduce-motion` launch-arg seam (designed in Pattern 4); manual Settings toggle for UAT |
| Accessibility Inspector | A11Y-01 hit-target audit | ✓ | bundled with Xcode 26.3 | Manual ruler on screenshots (weaker) |
| Hosted test bundle (UIKit) | `UIColor` resolution in D-06 test | ✓ | `TEST_HOST` app binary (pbxproj verified) | Assert on hex literals (A2 fallback) |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `simctl` Reduce Motion toggle → launch-arg seam / manual toggle.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, primary) + XCTest (legacy/root suites); both hosted in the app binary |
| Config file | none — canonical invocation pinned in `AGENTS.md:27-38` and `.github/workflows/_test.yml:181-190` |
| Quick run command | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -derivedDataPath build -skipPackagePluginValidation -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -only-testing:StressMonitorTests/ContrastComplianceTests` |
| Full suite command | same without `-only-testing` (the AGENTS.md canonical form; last recorded run: 229 tests / 43 suites, exit 0) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| A11Y-02 | Token pairs ≥4.5:1 (text) / ≥3:1 (UI, large text) in both appearances | unit (hosted) | `-only-testing:StressMonitorTests/ContrastComplianceTests` | ❌ Wave 0 (new file + manual pbxproj registration, A026/B026 pattern) |
| A11Y-04 | `.accessibleDynamicType()` reworked defaults (no cap/shrink) | unit | `-only-testing:StressMonitorTests/DynamicTypeReworkTests` (asserts modifier composition where introspectable; primary gate is the grep below) | ❌ Wave 0 (optional — only if the modifier is factored testably; the adoption sweep is the binding gate) |
| A11Y-04 | Adoption: 14/14 manifest surfaces apply the modifier | grep gate (trust-gate record) | `for f in <14 files>; grep -L …` (Code Examples) | n/a (gate artifact, dated) |
| A11Y-03 | Consolidation: zero raw RM refs outside helper | grep gate (trust-gate record) | `grep -rn … \| grep -v <helper>` (Code Examples) | n/a (gate artifact, dated) |
| A11Y-03 | Breathing RM fallback defaults to haptic+text | unit (logic) + UAT walkthrough | `-only-testing:StressMonitorTests/<BreathingFallbackTests>` (pure decision-logic test if the fallback state is a testable function) | ❌ Wave 0 (only if extracted as pure logic; else manual-only) |
| A11Y-01 | Hit targets ≥44pt | manual-only (Accessibility Inspector scan per surface) — justified: hit-area geometry is a rendered-tree property; no unit seam | recorded in phase UAT | n/a |
| A11Y-05 | Orphans deleted; binary builds clean | build gate | `xcodebuild build` for app + watch + widget schemes after each deletion batch (delete-compile) | n/a |
| Regression guard | Full suite stays green | full suite | canonical full-suite command | ✓ (229 tests / 43 suites baseline) |

### Sampling Rate
- **Per task commit:** targeted `-only-testing` of the touched suite (e.g. ContrastComplianceTests) + SwiftLint on changed files
- **Per wave merge:** full canonical suite + all three target builds (delete-compile coverage)
- **Phase gate:** full suite green, both grep trust-gates recorded with pasted output, per-surface AX5 + light/dark walkthrough screenshots in UAT, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift` — covers A11Y-02 (new; manual pbxproj registration in 4 places, precedent `project.pbxproj:48,144,323,553`)
- [ ] Optional: breathing-fallback decision-logic test file — covers A11Y-03 (D-11) if extracted pure
- [ ] No framework install needed — infra exists

## Security Domain

`security_enforcement: true`, ASVS level 1. This phase adds no network, auth, crypto, or persistence surface — it modifies view code, theme token values, and deletes dead views. ASVS applicability:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | untouched this phase |
| V3 Session Management | no | untouched |
| V4 Access Control | no | untouched |
| V5 Input Validation | no | no new inputs; new strings are static UI copy |
| V6 Cryptography | no | untouched |
| V14 Config (tangential) | yes (reduced) | A11Y-05 deletion of ~half the dead view layer reduces compiled attack surface and binary size; delete-compile of all targets verifies no live path depended on deleted code |

### Known Threat Patterns for SwiftUI remediation phases

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dead code shipped in binary (reconnaissance aid, larger attack surface) | Information Disclosure | A11Y-05 deletes orphans from disk; delete-compile gate |
| DEBUG-only a11y launch-arg seam leaking into Release | Elevation of Abuse | Gate the `-a11y-reduce-motion` override with `#if DEBUG` (repo precedent: `SimulatorHealthKitService`, `MockIAPMode`) |
| Test file registration churn breaking CI trust | Repudiation | Follow the A026/B026 4-point registration pattern exactly; full-suite gate before merge |

## Sources

### Primary (HIGH confidence)
- In-repo source reads (all values quoted verbatim with line refs): `Utilities/DynamicTypeScaling.swift`, `Utilities/AccessibilityModifiers.swift`, `Utilities/Animation+Wellness.swift`, `Utilities/AnimationPresets.swift`, `Theme/Color+Wellness.swift`, `Theme/Color+Extensions.swift`, `Theme/Font+WellnessType.swift`, `Theme/DesignTokens.swift`, `Models/StressCategory.swift`, `Navigation/Route.swift`, `Views/MainTabView.swift`, `Views/Breathing/BreathingExerciseView.swift`, `StressMonitor.xcodeproj/project.pbxproj`
- Local computations & probes: WCAG ratio matrix (formula validated 21.00 black/white); `xcrun simctl ui` subcommand inventory; `Charts.swiftmodule` interface greps (4 platforms); Periphery binary + `scan --help`; simulator inventory; grep baselines (66 RM refs / 13 files; 7 `.accessibleDynamicType` adopters; 0 refs for HighContrastModifier/PatternOverlay/ColorBlindnessSimulator)
- gh api: `repos/peripheryapp/periphery` (6,182 stars, pushed 2026-08-12)

### Secondary (MEDIUM-HIGH confidence)
- Context7 `/websites/developer_apple_swiftui`: `accessibilityReduceMotion` (`{ get }`), `accessibilityPrefersCrossFadeTransitions` (`{ get set }`), `TransitionProperties.hasMotion` (iOS 17+, auto-opacity under RM), `DynamicTypeSize.accessibility5`, `.dynamicTypeSize(_:…)` range syntax, `@ScaledMetric` — [CITED: developer.apple.com URLs emitted by Context7]
- Context7 `/w3c/wcag` (techniques G18/G145): relative-luminance formula, 4.5:1/3:1 thresholds, large text = ≥18pt or ≥14pt bold — [CITED: w3.org techniques]
- Phase artifacts: `03-UI-SPEC.md` (approved contract), `02-TRUST-GATE-RECORD.md` (gate pattern), `AGENTS.md` (canonical test invocation)

### Tertiary (LOW confidence — flagged in Assumptions Log)
- iOS text-style default point ramp at Large setting (A1)
- Swift Charts automatic aggregate accessibility/audio-graph behavior (A3)

## Metadata

**Confidence breakdown:**
- Contrast (A11Y-02): HIGH — formula independently implemented, all ratios recomputed, retunes numerically confirmed, test mechanism verified against project structure
- Dynamic Type (A11Y-04): HIGH on current-state and rework contract; MEDIUM on typography anchor sizes (A1) pending the executor's byte-identical parity check
- Reduce Motion (A11Y-03): HIGH — framework APIs cited, baseline measured, consolidation surface enumerated, verification seam designed
- Orphans (A11Y-05): HIGH on mechanics (sync-group deletion, Periphery availability, false-positive classes); MEDIUM on the candidate list itself (regenerated/validated by the D-14 audit by design)

**Research date:** 2026-09-05
**Valid until:** 2026-10-05 (stable domain; token values and counts are session-pinned — re-baseline greps at gate time)
