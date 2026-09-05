# Phase 3: Accessibility Compliance - Pattern Map

**Mapped:** 2026-09-05
**Files analyzed:** 30 new/modified (grouped) + 3 utility deletions + ~81 orphan-candidate deletions
**Analogs found:** 30 / 30 groups (this is a remediation phase — nearly every target file is its own analog; genuinely new code has in-repo structural analogs)

> **Branch note (measured this session, branch `v1.2-submission-readiness`):** the UI-SPEC/RESEARCH
> "partially adopted" claims are stale for 8 helper families. Verified adopter counts on THIS branch:
> `.accessibleDynamicType()` = 7 files (the only widely-adopted helper); `minimumTouchTarget` = **0**;
> `stressDualCoding` = **0**; `accessibleWellnessType*` = **0**; `accessibleStressColor` = **0**;
> `scalableText`/`adaptiveTextSize`/`limitedDynamicType` = **0**; `animateIfMotionAllowed`/
> `Animation.wellness*`/`AnyTransition.accessible*` = **0**; `.staggeredAppear`/`.shimmerLoading()` = **0**
> (`SkeletonBlock` hand-rolls its own pulse, `Views/Dashboard/Components/SkeletonBlock.swift:17-24`).
> Consequence: A11Y-01/A11Y-04 sweeps are pure adoption of definition-only helpers (zero caller risk),
> D-12/D-13 is the only true consolidation (65 raw `reduceMotion` refs / 13 files, enumerated below),
> and rework-or-delete decisions on unadopted helpers cannot break any call site. Re-run the adoption
> greps at plan time if the branch changes.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift` (NEW) | test | batch (assertion matrix) | `StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift` | exact (Swift Testing suite, hosted, manually registered) |
| `Utilities/Motion.swift` (NEW, or rework `Animation+Wellness.swift` in place) | utility (view modifier) | event-driven (env observation) | `Utilities/Animation+Wellness.swift:43-72` `ReduceMotionAwareModifier` | role-match (consolidation of its own family) |
| `Theme/Color+Wellness.swift` | config (token) | static | itself — retune in place (D-04) | exact (self) |
| `Theme/Color+Extensions.swift` | config (token) | static | itself — retune in place (D-04) | exact (self) |
| `Theme/Font+WellnessType.swift` | config (token) + utility modifier | static/transform | itself — anchor + rework (D-10) | exact (self) |
| `Utilities/DynamicTypeScaling.swift` | utility (view modifier) | transform | itself — rework defaults (D-10) | exact (self) |
| `Utilities/AccessibilityModifiers.swift` | utility (view modifiers) | transform | itself — fix + extend (A11Y-01, D-09) | exact (self) |
| `Utilities/Animation+Wellness.swift` | utility | transform | itself — RM consolidation (D-12/D-13) | exact (self) |
| `Utilities/AnimationPresets.swift` | utility | transform | itself — route through helper (D-13) | exact (self) |
| 14 manifest surface views (DashboardView, ActionView, TrendsView, SettingsView, DataExportView, DataManageView, DataDeleteView, CharacterCollectionView, AppearanceSettingsView, AboutView, WatchFacePreferencesView, MeasurementDetailView, BreathingExerciseView, MiniWalkView) | component (view) | transform (view tree) | `Views/DashboardView.swift:40-41` (root-group `.accessibleDynamicType()` adoption) | exact (4 of 14 already adopt; 10 copy the same line) |
| `Views/Breathing/BreathingSessionView.swift` + `BreathingSummaryView.swift` + `BreathingViewModel.swift` (D-11 fallback) | component + viewmodel | event-driven (timer/state) | `Views/Breathing/BreathingExerciseView.swift:14,126` (RM gate) + `Views/Components/HapticManager.swift` | role-match (fallback UI is new; RM-gate + haptic patterns exist) |
| Chart components: `Views/Trends/Components/StressBarChartView.swift`, `HRVTrendChart.swift`, Trends chart containers | component (chart) | transform | their own `.accessibilityElement(children: .contain)` + label (StressBarChartView:31-32, HRVTrendChart:37-38) | exact (extend existing pattern) |
| `StressMonitorWidget/Views/{Small,Medium,Large,LockScreen}WidgetView.swift` | component (widget) | transform | `StressMonitorWidget/Views/LockScreenWidgetView.swift` | exact (self — D-07 platform-bounded rules) |
| Watch token mirrors: `StressMonitorWatch Watch App/Theme/Color+Extensions.swift`, `Models/StressCategory.swift` | config (token) | static | app-side originals + watch files themselves | exact (mirror convention) |
| `StressMonitor.xcodeproj/project.pbxproj` (test registration only) | config (build) | static | A026/B026 precedent at pbxproj:48,144,323,553 | exact |
| 13 RM-consolidation files (enumerated in Shared Patterns) | mixed | event-driven | `Animation+Wellness.swift` helper family | role-match |
| DELETED: `Utilities/HighContrastModifier.swift`, `PatternOverlay.swift`, `ColorBlindnessSimulator.swift` | utility | — | A11Y-05 deletion class (0 call sites, verified) | exact |
| DELETED: ~81 orphan-candidate view files (UI-SPEC appendix) | component | — | delete-compile gate (sync group = no pbxproj surgery) | exact |
| Trust-gate records (phase doc artifacts, D-10/D-13) | doc | batch (grep enumeration) | `.planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md` | exact |

---

## Pattern Assignments

### `StressMonitorTests/ContrastComplianceTests.swift` (NEW — test, batch)

**Analog:** `StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift` — the most recent manually-registered Swift Testing suite (the A026/B026 precedent file).

**Suite structure pattern** (`DataDeleterCloudKitTruthinessTests.swift:1-4, 93-95, 129, 141-142`):
```swift
import Foundation
import Testing
@testable import StressMonitor

@Suite("CloudKit Delete Truthiness")
@MainActor
struct DataDeleterCloudKitTruthinessTests {

    @Test("a genuine CloudKit failure propagates as DeletionError.cloudKitError with the underlying error preserved")
    func genuineFailurePropagatesAsCloudKitError() async throws {
        ...
        #expect(underlying.localizedDescription == ...)
        Issue.record("Expected DeletionError.cloudKitError, got \(error)")
```

Copy: named `@Suite("...")` + named `@Test("...")` string titles (these titles appear in the trust-gate suite enumeration — `02-TRUST-GATE-RECORD.md:48-96` enumerates by exactly these names), `#expect` assertions, doc-comment header explaining the contract under test. The new suite needs `import UIKit` for `UIColor.resolvedColor(with:)` (hosted test target, `TEST_HOST` verified in pbxproj).

**Token-under-test pattern** — what the test resolves. `Color(light:dark:)` dynamic provider (`Theme/Color+Extensions.swift:28-32`):
```swift
init(light: Color, dark: Color) {
    self.init(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
    })
}
```
Resolve via `UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))` per RESEARCH Pattern 1; the A2 fallback (assert on the hex literals) reads the same constants defined at `Color+Wellness.swift:58-79` and `Color+Extensions.swift:104-130`.

**Registration pattern** — `project.pbxproj` 4-point manual registration, byte-identical shape to the A026/B026 precedent (verified present on this branch at `StressMonitor/StressMonitor.xcodeproj/project.pbxproj:48,144,323,553`):
```text
line  48:  F1A1B2C3D4E500000000B026 /* DataDeleterCloudKitTruthinessTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = F1A1B2C3D4E500000000A026 ... };
line 144:  F1A1B2C3D4E500000000A026 /* ... */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = ...; path = StressMonitorTests/...; sourceTree = "<group>"; };
line 323:  (PBXGroup children entry — fileRef ID)
line 553:  (PBXSourcesBuildPhase entry — buildFile ID)
```
Use two fresh unique 24-hex-char IDs (pattern `F1A1B2C3D4E5...`-style or any unique hex); app sources are a `PBXFileSystemSynchronizedRootGroup` but `StressMonitorTests` is NOT — manual registration is required.

---

### `Utilities/Motion.swift` or reworked `Utilities/Animation+Wellness.swift` (utility — the D-12 single helper)

**Analog:** `Utilities/Animation+Wellness.swift` — the consolidation target itself. Planner's open question (RESEARCH OQ-2): reworking in place preserves the file's role; a new `Motion.swift` follows repo one-type-per-file convention.

**Env-reading modifier pattern to own ALL RM reads** (`Animation+Wellness.swift:43-58, 66-72`):
```swift
struct ReduceMotionAwareModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

extension View {
    func animateIfMotionAllowed<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(ReduceMotionAwareModifier(animation: animation, value: value))
    }
}
```
This modifier shape is correct (env-read inside the modifier, value-driven) — but has **0 adopters** on this branch. The helper keeps this shape; the explicit-`Bool` statics above it (`Animation.wellness/breathing/fidget/shake/dizzy(reduceMotion:)`, lines 12-37 — the scatter source) are deleted or folded in.

**Transition rework** (`Animation+Wellness.swift:76-84` — `.identity` hard cut violates D-12):
```swift
// Current (REWORK): returns .identity under RM
static func accessibleOpacity(reduceMotion: Bool) -> AnyTransition {
    if reduceMotion {
        return .identity // No transition
    } else {
        return .opacity
    }
}
```
Rework: return `.opacity` under RM (cross-fade, D-12 wording: "fades are allowed; hard `.identity` cuts are not the goal").

**DEBUG launch-arg seam pattern** (for scripted RM verification — `\.\accessibilityReduceMotion` is read-only, no `simctl` toggle). Copy `MockIAPMode` (`StressMonitorApp.swift:6-27`), the strongest precedent because it is injectable for tests:
```swift
#if DEBUG
enum MockIAPMode {
    static let launchArgument = "-mock-iap"
    static func isEnabled(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(launchArgument)
    }
}
#endif
```
The `-a11y-reduce-motion` seam follows this exactly: `#if DEBUG` enum, injectable `arguments`, OR'd into the helper's motion-allowed decision. (Weaker precedent: `DemoMode.isEnabled`, `StressMonitorApp.swift:7-9`, non-injectable.)

---

### `Theme/Color+Wellness.swift` (config/token — D-04 retune in place)

**Analog:** itself. Adaptive-pair declaration pattern (lines 58-79) — retune values only, structure unchanged:
```swift
static let adaptiveBackground = Color(
    light: Color(hex: "#FFFDF6"),
    dark: Color(hex: "#121212")
)
static let adaptiveCardBackground = Color(
    light: Color.white,
    dark: Color(hex: "#1E1E1E")
)
static let adaptivePrimaryText = Color(
    light: Color(hex: "#101223"),
    dark: Color.white
)
static let adaptiveSecondaryText = Color(
    light: Color(hex: "#777986"),   // RETUNE → #6B6E7B (4.98 canvas / 5.07 card)
    dark: Color(hex: "#9CA3AF")
)
```
`accessibleStressColor(for:highContrast:)` (lines 137-157): fix `moderate` `#FFA500` (1.94:1) in the highContrast set and the false "WCAG AAA (7:1)" comment at line 139. Note `Color.Wellness.calmBlue` light is already `#0891B2` (line 11) — the recommended ripple-light retune value already exists in the palette.

### `Theme/Color+Extensions.swift` (config/token — D-04 retune in place)

**Analog:** itself. Retune targets verified: `settingsBackground` dark `#0A0A0F` → `#121212` (line 107), `settingsRippleBlue` + `accentTeal` fixed `#4FC3F7` → adaptive light `#0891B2` (lines 109, 111), `textTertiary` `#808080` / `textDescriptive` `#848484` → alias `adaptiveSecondaryText` light (lines 120, 122 — follow the existing computed-alias precedent `bannerYellow`, line 130: `static var bannerYellow: Color { settingsAmberInfo }`).

**Dual-source-of-truth hazard** (lines 36-40): `stressRelaxed…stressSevere` duplicate `StressCategory.color` (`Models/StressCategory.swift:13-26`) value-for-value. Whatever the D-06 test pins as source, the other dies (A11Y-05-class cleanup). `Color.stressColor(for:)` already delegates (lines 183-186) — keep that delegation shape.

### `Theme/Font+WellnessType.swift` (config/token + utility — D-10 anchor)

**Analog:** itself. Tokens to anchor (lines 13-36, all bare `Font.system(size:)`):
```swift
static var heroNumber: Font { .system(size: 72, weight: .bold, design: .rounded) }
static var largeMetric: Font { .system(size: 48, weight: .bold, design: .rounded) }
static var cardTitle: Font { .system(size: 28, weight: .bold, design: .default) }
static var sectionHeader: Font { .system(size: 22, weight: .semibold, design: .default) }
static var body: Font { .system(size: 17, weight: .regular, design: .default) }
static var bodyEmphasized: Font { .system(size: 17, weight: .semibold, design: .default) }
static var caption: Font { .system(size: 13, weight: .regular, design: .default) }
static var caption2: Font { .system(size: 11, weight: .regular, design: .default) }
```
Anchor to text styles (`.title`=28, `.title2`=22, `.body`=17, `.headline`=17 semibold, `.footnote`=13, `.caption2`=11 — executor verifies byte-identical parity at Large, RESEARCH A1). `heroNumber`/`largeMetric` stay fixed (gauge class, D-09). The `accessibleWellnessType*` modifiers (lines 44-67, AX3 cap + 0.7 shrink) have **0 adopters on this branch** — delete outright rather than rework (UI-SPEC's "surviving callers" list is stale; verified by grep).

### `Utilities/DynamicTypeScaling.swift` (utility — D-10 rework)

**Analog:** itself. Rework target (lines 122-148, verified verbatim):
```swift
public struct AccessibleDynamicTypeModifier: ViewModifier {
    let minimumScale: CGFloat
    let maxDynamicTypeSize: DynamicTypeSize

    public init(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3) { ... }

    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...maxDynamicTypeSize)
            .minimumScaleFactor(minimumScale)
            .lineLimit(nil)
    }
}
```
Reworked body: `content.lineLimit(nil)` only — no cap, no shrink. `AdaptiveTextSizeModifier` (lines 35-98, hand-rolled 12-step multiplier table + 0.7 shrink) and `scalableText` (lines 7-30) have **0 adopters** — delete. `limitedDynamicType()` (lines 104-117) survives for dated exceptions only.

### `Utilities/AccessibilityModifiers.swift` (utility — A11Y-01 mechanism + D-09 extension + fixes)

**Analog:** itself. The A11Y-01 mechanism to adopt everywhere (lines 50-58):
```swift
struct MinimumTouchTargetModifier: ViewModifier {
    let minSize: CGFloat
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}
```
Assert against `DesignTokens.Layout.minTouchTarget` (`Theme/DesignTokens.swift:16` — `static let minTouchTarget: CGFloat = 44`; note: 0 current users of both the token and the helper — pure adoption).

Fix while touching: `StressDualCodingModifier` renders caption text in the stress hue (lines 39-41: `Text(category.displayName).font(.caption).foregroundColor(category.color)`) — must become `adaptivePrimaryText`/`adaptiveSecondaryText` (UI-SPEC contrast rule). `AccessibleAnimationModifier` animates on every body eval via `value: UUID()` (line 70) — fold into the D-12 helper or fix the value.

Chart-series extension point (lines 137-143, **0 adopters** — D-09 adopts + extends this shape):
```swift
func accessibilityChart(description: String, value: String) -> some View {
    self
        .accessibilityElement(children: .combine)
        .accessibilityLabel(description)
        .accessibilityValue(value)
        .accessibilityAddTraits(.updatesFrequently)
}
```

### 14 manifest surface views (component — D-10 adoption + A11Y-01 + contrast sweep)

**Analog:** `Views/DashboardView.swift:40-41` — the root-group adoption pattern already shipping on 4 of 14 surfaces:
```swift
var body: some View {
    Group {
        if viewModel.isPermissionRequired { permissionStateView }
        else if ... { readingStateView }
        else { readyStateView }
    }
    .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
    .accessibleDynamicType()      // ← the adoption line; copy at the root container of each surface
```
Existing adopters (verified): `DashboardView.swift:41`, `SettingsView.swift:56`, `BreathingExerciseView.swift:45`, `MiniWalkView.swift:98` (plus orphan/exempt `MeasurementHistoryView.swift:22`, `IAPPremiumView.swift:98`, `PaywallView.swift:72`). The 10 missing surfaces copy the same single line at their root container.

**Error-alert copy shape** (DashboardView:42-50 — the UI-SPEC error rule's rework target):
```swift
.alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) { ... }
```
Retitle to the failing operation + "Try Again" action per UI-SPEC copywriting contract.

### Breathing session views — D-11 fallback (component, event-driven)

**Analog:** `Views/Breathing/BreathingExerciseView.swift` — RM gate pattern (line 14: `@Environment(\.accessibilityReduceMotion) private var reduceMotion`; line 126: `.onAppear { if !reduceMotion { animateBox = true } }`) and `BoxBreathingStep` vocabulary (lines 298-307: `Inhale`/`Hold`/`Exhale`/`Hold` shortNames — the fallback status line "Inhale — 3" reuses exactly these). Haptics via `Views/Components/HapticManager.swift` (centralized — never call `UIImpactFeedbackGenerator` directly). Targets: `BreathingSessionView.swift`, `BreathingSummaryView.swift`, `BreathingViewModel.swift` (all in `Views/Breathing/`). The intro view's decorative `boxPatternAnimation` (lines 91-127) routes through the D-12 helper; the session animation itself is the D-11 carve-out.

### Chart components — D-09 accessibility series (component, transform)

**Analog:** the charts' own existing container-level a11y (verified — this is the live pattern to extend, NOT the unadopted `.accessibilityChart` helper alone):
```swift
// Views/Trends/Components/StressBarChartView.swift:31-32
.accessibilityElement(children: .contain)
.accessibilityLabel("Daily stress bar chart. Average \(averageValue) on a 0 to 100 scale.")

// Views/Trends/Components/HRVTrendChart.swift:37-38
.accessibilityElement(children: .contain)
.accessibilityLabel( ... )
```
Extend with the trend-summary line ("{Metric} {up|down|steady} {percent}% in the last {period}") + per-point `VoiceOverLabels.timelinePoint`-shaped strings (`Utilities/AccessibilityModifiers.swift:112-114` — the existing per-point string shape: `"At \(hour) hours, stress level was \(Int(stress)) percent"`). Charts render fixed-size (D-09 geometry exempt); Swift Charts appears only in Dashboard `SparklineChart`/`MiniLineChartView`.

### Widget views — D-07 (component, transform)

**Analog:** `StressMonitorWidget/Views/LockScreenWidgetView.swift` — system-material + tier dual-coding pattern:
```swift
// LockScreenRectangularView (lines 12-20): tier.emoji + tier.label + tier.accent —
// accent never alone; background via .containerBackground(.fill.tertiary, for: .widget)
```
D-07 rule: verify foreground↔system-material pairs only; wallpaper-dependent accent contrast is out of scope by construction. Widget files: `SmallWidgetView.swift`, `MediumWidgetView.swift`, `LargeWidgetView.swift`, `LockScreenWidgetView.swift`.

### Watch token mirrors (config/token)

**Analog:** `StressMonitorWatch Watch App/Theme/Color+Extensions.swift:43-47` — the watch's own duplicated stress hexes that must mirror app retunes:
```swift
static let stressRelaxed  = Color(hex: "#34C759")
static let stressMild     = Color(hex: "#007AFF")
static let stressModerate = Color(hex: "#FFD60A")
static let stressHigh     = Color(hex: "#FF9500")
static let stressSevere   = Color(hex: "#FF3B30")
```
Note watch `Color(light:dark:)` resolves light-only (lines 32-38 — "watchOS does not expose UIColor(dynamicProvider:)"). Also mirror `Models/StressCategory.swift` watch-side (`StressMonitorWatch Watch App/Models/StressCategory.swift`, 140 lines).

### Deletions (A11Y-05 / D-05)

**Analog:** none needed — mechanics verified. App sources are a `PBXFileSystemSynchronizedRootGroup` (only `Info.plist` + 4 Lato fonts excepted) → delete-from-disk removes from build, zero pbxproj surgery. Ground truth = delete-compile of all 3 targets. `Utilities/HighContrastModifier.swift`, `PatternOverlay.swift`, `ColorBlindnessSimulator.swift`: 0 call sites verified this session.

**Relocation trap** (`Views/DesignSystem/Components/Badge.swift:40-54`): the `StressCategory.displayName` extension lives in orphan-candidate `Badge.swift` and IS consumed by live code (`StressBadge` at line 33 uses it; `StressCategory.accessibilityDescription` references it in its doc comment). Before deleting any candidate, grep each `extension` member it declares; move live members, then delete.

---

## Shared Patterns

### Reduce Motion consolidation — the 13 files (D-12/D-13)

**Measured this session (branch `v1.2-submission-readiness`): 65 refs / 13 files** (UI-SPEC recorded 65/13; RESEARCH measured 66/13 — re-baseline at gate time):

| File | Refs |
|------|------|
| `Utilities/Animation+Wellness.swift` | 19 |
| `Components/Character/CharacterAnimationModifier.swift` | 12 |
| `Views/Breathing/Components/BreathingCircle.swift` | 5 |
| `Utilities/AnimationPresets.swift` | 4 |
| `Utilities/AccessibilityModifiers.swift` | 4 |
| `Views/Dashboard/Components/SkeletonBlock.swift` | 4 |
| `Views/Dashboard/Components/StressRingView.swift` | 3 |
| `Views/Dashboard/Components/MetricCardView.swift` | 3 (orphan candidate — delete first shrinks the sweep) |
| `Views/Dashboard/Components/LearningPhaseCard.swift` | 3 |
| `Views/Breathing/BreathingExerciseView.swift` | 2 (D-11 carve-out) |
| `Views/Breathing/Components/RippleBreathingView.swift` | 2 (orphan candidate) |
| `Views/MiniWalk/MiniWalkView.swift` | 2 |
| `Views/MiniWalk/Components/MiniWalkInstructionCard.swift` | 2 |

Apply to all: replace raw `@Environment(\.accessibilityReduceMotion)` reads with the single helper; `BreathingExerciseView`/session views get the explicit D-11 disposition. Trust-gate grep shape is in RESEARCH Code Examples and mirrors `02-TRUST-GATE-RECORD.md` §3 (paste output, enumerate by file+construct, never counts).

### Adaptive color declaration (all token work)

**Source:** `Theme/Color+Extensions.swift:28-32` + `Color+Wellness.swift:58-79`
**Apply to:** every retuned token — values change, `Color(light:dark:)` shape never does; light-dark pairs must BOTH be considered (ripple white-on-fill fails 2.00 in both appearances).

### Launch-argument DEBUG seams (RM verification)

**Source:** `StressMonitorApp.swift:6-27` (`DemoMode` + injectable `MockIAPMode`)
**Apply to:** the `-a11y-reduce-motion` seam inside the D-12 helper — `#if DEBUG`, injectable `arguments:` parameter.

### Trust-gate record (D-10 adoption grep + D-13 RM grep artifacts)

**Source:** `.planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md`
**Apply to:** both phase-3 gate records — dated header, pasted command output, per-file enumeration table, verdict section with explicit zero-unaccounted statement.

### Test-file conventions (all new tests)

**Source:** `DataDeleterCloudKitTruthinessTests.swift`
**Apply to:** `ContrastComplianceTests.swift` (+ optional breathing-fallback suite) — Swift Testing (`import Testing`), named `@Suite`/`@Test` titles, `#expect`/`Issue.record`, `@testable import StressMonitor`, no GSD_CI gates (the suite must be CI-visible by default).

---

## No Analog Found

| File / Piece | Role | Data Flow | Reason |
|------|------|-----------|--------|
| WCAG relative-luminance + ratio computation inside `ContrastComplianceTests.swift` | test util | transform | No contrast/luminance math exists anywhere in the repo (grep verified — only prose "WCAG" comments). Use RESEARCH Pattern 1's W3C G18/G145 formula; validated black/white = 21.00. |
| Hosted `UIColor.resolvedColor(with:)` resolution | test util | transform | No precedent in the test target (all existing suites are logic/data tests). RESEARCH A2 documents the hex-literal fallback if provider resolution misbehaves. |
| Breathing RM fallback UI ("Breathing animation" switch + haptic/text-countdown mode) | component | event-driven | The state machine is new (D-11); nearest pieces are the RM gate (`BreathingExerciseView:14,126`), `HapticManager`, and `BoxBreathingStep` vocabulary — composition, not a copy source. |
| Watch view/complication Dynamic Type anchors (03-02 Task 4) | component | transform | No codebase analog: both targets use only bare `Font.system(size:)` (zero `relativeTo:`/text-style usage — grep verified), so there is nothing in-repo to copy. Follow the RESEARCH Pattern 3 anchor rule: preserved point size + `relativeTo:` nearest text style; the dated-exception marker mirrors the `limitedDynamicType` dated-note convention instead. |

## Metadata

**Analog search scope:** `StressMonitor/StressMonitor/{Theme,Utilities,Views,Models,StressMonitorApp.swift}`, `StressMonitor/StressMonitorTests/`, `StressMonitor/StressMonitorWidget/Views/`, `StressMonitor/StressMonitorWatch Watch App/{Theme,Models}/`, `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`, `.planning/phases/02-*/`
**Files scanned:** 21 read in full/targeted; adoption greps over the whole app target
**Tracked-source gate:** every analog named is `git ls-files`-verified on branch `v1.2-submission-readiness` (note: `FactoryResetSweepCompletenessTests.swift` from phase 2 does NOT exist on this branch — the A026/B026 pbxproj precedent does, in `DataDeleterCloudKitTruthinessTests.swift`)
**Pattern extraction date:** 2026-09-05
