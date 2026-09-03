# Phase 1 WIRE-01 — Widget Evidence (simulator fallback path + findings)

**Produced by:** plan 01-04 Task 3 · **Date:** 2026-09-03
**Verification path of record:** the CONTEXT-sanctioned fallback — simulator widget gallery + documented evidence. The physical-device parity check is surfaced as an end-of-phase human item (see §6). This note discloses the data source honestly (§1) and records a material discovery about the widget's write path (§7) that reframes what the device check should verify.

**Evidence environment:** iPhone 17 simulator (iOS 26.3, UDID 5DD825B4-…), Debug build of the `StressMonitor` scheme (demo mode is `#if DEBUG`-gated — the Release archive does not contain `SimulatorHealthKitService`), launched via `xcrun simctl launch <udid> stress.ai.com -demo-mode`. Interaction and discovery via the argent MCP tools (`describe` before every tap; coordinates from AX frames only); screenshots via `xcrun simctl io screenshot` (file output; this session's model runtime cannot render images into context, so on-screen values were verified through the accessibility tree and are quoted below).

---

## 1. Data source disclosure — DEMO MODE

**The dashboard data in this evidence is demo-mode-generated, not HealthKit-live.** No HealthKit data exists on a simulator; the `-demo-mode` launch argument activates `SimulatorHealthKitService`, whose synthetic readings feed the **real** calculation and UI pipeline (the same `StressViewModel` → `MultiFactorStressCalculator` 5-factor path users get). No claim of live HealthKit provenance is made anywhere in this note.

One further honesty note: the demo service's scenario switcher is currently hardcoded to the `edgeLowHRV` scenario (`SimulatorHealthKitService.currentScenario` returns `.edgeLowHRV` with the cycling index commented out), so the observed values sit in the high-stress band (HRV 13–16 ms, HR 104–106 bpm → "Elevated / Tense · busy") rather than cycling all five levels.

## 2. Screenshots

| File | Captured | Shows |
|------|----------|-------|
| `StressMonitor/build/wire-01/app-dashboard.png` | 2026-09-03 17:05:17 (pair partner captured 17:05:08 — 9 s apart) | In-app dashboard, "DEMO MODE" badge, Current stress **"Elevated · Tense · busy"**, `measured 17:03`, vitals **HRV 13 ms / HR 105 bpm**, tab bar |
| `StressMonitor/build/wire-01/widget-home-screen.png` | 2026-09-03 17:05:08 | Home screen with the StressMonitor small widget (top-left 2×2 slot) rendering **"💧 No Data / Open app to measure"** |

**Value-match statement (honest):** the pair does **not** show matching stress values, because the widget renders its contract **empty state**. This is not a screenshot-timing artifact — it is the correct `WidgetDataState.empty` behavior for a suite that has never been written (see §7: no live code path writes the widget's `latest_*` keys). The dashboard shows a live demo-mode reading; the widget shows the empty state; both were captured in the same 9-second window.

## 3. Suite-keys check (machine-verified)

`WidgetPublisherKeyMatchingTests` — **2/2 passed, TEST SUCCEEDED** (run this session, plan 01-04 Task 1): `WidgetPublisher.publish` opens `UserDefaults(suiteName: "group.stress.ai.com")` non-nil, writes all six `latest_*` keys, values round-trip. The suite-writing parts of the DataDeletion suites (4/4, incl. "clears App Group widget cache") are likewise green. Additionally, the widget extension process **launched and rendered without crashing** — `WidgetDataProvider.init` `fatalError`s if the suite cannot be opened, so a rendered widget (even the empty state) proves the shared container opened. The widget was added through the real gallery flow (long-press → Edit → Add Widget → search "Stress" → StressMonitor page → Add Widget → Done), all discovery-driven.

## 4. Widget present in the phase-final archive

`StressMonitor/build/Phase1-Final.xcarchive/Products/Applications/StressMonitor.app/PlugIns/` contains **`StressMonitorWidgetExtension.appex`** (verified in Task 2; D4 — the widget stays in the build). The `.appex` ships the corrected README copy (`group.stress.ai.com`).

## 5. Frozen-contract note (unchanged this phase)

`WidgetDataState.resolve` behaves exactly as v1.0 shipped and this phase did not touch it (git diff for `WidgetDataState.swift` + `WidgetDataStateTests.swift` = empty): timestamp age **≤ 24 h → fresh**, **> 24 h → stale**, **missing timestamp → empty**. The widget screenshot in §2 is a live rendering of the `empty` branch. The displayed value is read verbatim from the suite keys (`WidgetDataProvider.getLatestStress` — no re-derivation/rounding between `publish` and the entry), pinned by `WidgetPublisherKeyMatchingTests`.

## 6. Physical-device verification — PENDING (end-of-phase human item)

**Human item (unresolved, surfaced — not dropped):** on a physical device with real HealthKit data, add the widget, take a measurement, refresh, and confirm the **widget score equals the app dashboard score**. Intended executor: the user on hardware, or the end-of-phase human verification session. **Expected outcome per §7:** on a stock install the widget will show "No Data" there too, until the write-path gap below is wired; the device check is the right place to confirm that expectation on real hardware (and to re-verify once a fix lands).

## 7. ⚠ Material discovery — the widget's write path has NO live call site (surfaced, not fixed)

Task 3's step 1 assumes "let at least one stress save fire (the demo cycle produces a fresh timestamp)". **That assumption is false in the shipped app.** `WidgetPublisher.publish` (the only writer of the widget's `latest_*` suite keys) is called from exactly one place — `StressRepository.save` (line 57) — and a repo-wide call-graph audit this session found every caller of `repository.save` is dead in live usage:

| Caller | State |
|--------|-------|
| `StressViewModel.calculateAndSaveStress()` (StressViewModel.swift:325) | **Zero call sites** — dead since its introduction (commit bba996a). The demo 15 s auto-refresh calls `loadCurrentStress()`, which calculates and updates UI only — it never saves. |
| `DashboardViewModel.refreshStressLevel()` (DashboardViewModel.swift:67) | `DashboardViewModel` is constructed **only in SwiftUI previews** (`PreviewDataFactory.mockDashboardViewModel()`) — not reachable in the live app. |
| `HealthBackgroundScheduler.fetchAndCalculateStress()` (line 90) | `HealthBackgroundScheduler` is **never instantiated** — `registerBackgroundTask`/`scheduleBackgroundRefresh` have no call sites, and the app declares no `UIBackgroundModes` (the 01-03 deferred finding — background fetch/processing is absent from every shipped plist). |

The watch app writes **different** keys (`watch.latestStress` / `watch.stressHistory` via `WatchSharedDataStore`) and never feeds `latest_*`. Net effect: **on any device — simulator or physical — the iOS widget renders "No Data" forever**, because nothing in the shipped binary ever writes its data source. The write→read path is fully built, unit-tested (`WidgetPublisherKeyMatchingTests` green), and entitlement-wired (all three bundles dump the identical suite); it is simply never invoked — the same "correct code written, then never wired up" pattern the milestone audit flagged as this codebase's systemic integration gap.

**Consequences for the phase's truth claims:**
- BUILD-02 (one suite, entitlements chain) is unaffected — proven at source, golden-artifact, and test level.
- WIRE-01 ("widget renders live data, not placeholder") is **not met by the shipped binary** — the requirement stays open pending a product decision on wiring a save trigger (candidates: call `calculateAndSaveStress` from the demo/foreground refresh path, instantiate + register `HealthBackgroundScheduler`, or a foreground save on `loadCurrentStress`). Wiring any of these is an app-behavior change — deliberately NOT done in this evidence-only plan (Rule 4: architectural decision for the user).
- D4's "keep the widget and make it true" gains a concrete meaning: the missing piece is one call site, not the widget itself.

**Executor deviation trail for this task** (auto-fixes that were attempted and legitimately ruled out): re-signing the simulator build with embedded entitlements (fixes nothing — the gap is call-graph, not entitlements; also the manual ad-hoc re-sign broke SpringBoard launch trust and was reverted to the stock xcodebuild product); the argent simulator-server touch pipeline wedged mid-session and was restored via `stop-simulator-server` (skill-documented remedy).

**Evidence artifacts:** screenshots §2; describe-tree readings quoted per section; tests §3; archive check §4.
