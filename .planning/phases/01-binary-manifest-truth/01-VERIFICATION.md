---
phase: 01-binary-manifest-truth
verified: 2026-09-03T21:12:00+07:00
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "SC-5 / WIRE-01: the widget write path was dead (WidgetPublisher.publish had zero live callers). Closed by plan 01-06 (D4 wire branch): guarded save inside StressViewModel.loadCurrentStress. Independently re-verified this session — source call graph live, 5/5 focused tests pass in the verifier's own run, machine-read same-value simulator evidence, frozen contracts byte-identical over 9c2001af..HEAD."
  gaps_remaining: []
  regressions: []
deferred:  # Items addressed in later phases — not actionable gaps

  - truth: "INFOPLIST_KEY_UIBackgroundModes = 'fetch processing' never merges into product plists — background fetch/processing silently absent from every shipped binary"
    addressed_in: "Phase 2 (BUILD-04)"
    evidence: "REQUIREMENTS.md traceability maps BUILD-04 to Phase 2 (Pending); pre-existing condition, unchanged by Phase 1 and provably untouched by 01-06 (no plist/pbxproj file changed over 9c2001af..HEAD)"
human_verification:

  - test: "Physical-device widget parity (WIRE-01 device half, evidence §6): on hardware with real HealthKit data, install the wired build, open the app (foreground refresh saves + publishes + reloadAllTimelines), add/refresh the home-screen widget."
    expected: "MATCH — the widget shows the same stress state the dashboard shows, immediately after the reload (within the 15-minute timeline budget at worst). With the write path now live, the prior expected outcome ('No Data' on a stock install) is superseded; this check closes WIRE-01 end-to-end."
    why_human: "Requires real hardware and real HealthKit data; the agent-executable path (CONTEXT-sanctioned simulator fallback + machine-read suite values) is complete. CONTEXT.md:25 sanctions 'simulator gallery + documented human UAT as fallback evidence' — this is that documented human UAT component."
  - test: "EN↔VI privacy policy semantic parity: human read of docs-site/legal/privacy.md vs docs-site/vi/legal/privacy.md before publication."
    expected: "Vietnamese phrasing natural; semantic parity beyond the grep-verified structural mirroring (both cover all 5 manifest collection types, non-tracking)."
    why_human: "Natural-language quality and cross-language semantic equivalence are not grep-verifiable (carried from prior verification; unrelated to gap closure)."
---

# Phase 1: Binary & Manifest Truth — Verification Report

**Phase Goal:** Everything the shipped archive declares about itself is true — Apple's automated validation accepts the privacy manifest, all three targets agree on one App Group suite, Info.plist keys resolve from a single source, the Release binary leaks no credential, and the widget either renders real data or is not in the build at all.
**Verified:** 2026-09-03T21:12:00+07:00
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plan 01-06, commits f6d813a/c6c82cf/83aef3c/e015f1b)

## Goal Achievement

### Observable Truths

Must-haves merged from ROADMAP.md success criteria (the contract) with plan frontmatter detail. SC-1..SC-4 and SC-6 were verified in the initial verification with live external evidence; this session re-checked each for regression (binary-truth-adjacent files unchanged over the gap-closure range) and confirmed no regression. SC-5 received full 3-level + behavioral re-verification.

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | **SC-1** A Release archive uploads to ASC and clears privacy-manifest validation — no missing required-reason declaration, no missing third-party SDK manifest | ✓ VERIFIED (no regression) | Initial-verification evidence stands: deploy run 33749862925 `success` at `acea984`, fetched log with **0** ITMS-91053 / privacy-manifest errors; TestFlight build 1.0.0 (14) `VALID`/`APP_STORE_ELIGIBLE`; manifest lint + SDK bundles verified in-binary. Regression check this session: **0** files changed over `9c2001af..HEAD` matching `*.xcprivacy`, `*.entitlements`, app `Info.plist`, `*.pbxproj`, `*Package.resolved` — 01-06's changes (StressViewModel/MockServices/tests/docs) cannot alter manifest truth. Boundary note: the ASC-validated artifact is build 14, which predates the 01-06 wiring; the wired binary re-validates at the next upload (deploy lane), and nothing manifest-relevant changed in between (0-line diff above). |
| 2 | **SC-2** App, widget, and watch targets read/write one canonical App Group suite; no target falls back to a placeholder suite or fails to open the shared container | ✓ VERIFIED (no regression) | Initial evidence stands (identical `["group.stress.ai.com"]` ×3 entitlements, constants, typo-grep 0, gate ×3, suite tests). Regression check this session: all three `.entitlements` files + the whole `StressMonitorWidget/` and Watch trees are inside the 0-line frozen-contract diff over `9c2001af..HEAD`. The new write path uses the same canonical constant: `WidgetPublisher.publish` guards on `UserDefaults(suiteName: WidgetConstants.appGroupID)` where `appGroupID = "group.stress.ai.com"` (WidgetSharedData.swift:100). |
| 3 | **SC-3** Every Info.plist key the app depends on resolves from a single source — no orphaned or duplicate plist file contributes keys | ✓ VERIFIED (no regression) | Initial evidence stands (documented empirical inversion; single-home STOREKIT keys; product-level gate PASS). Regression check this session: **0** plist/pbxproj files changed over `9c2001af..HEAD`; no `UIBackgroundModes`/`BGTaskSchedulerPermittedIdentifiers` added anywhere (BUILD-04 deferral intact). |
| 4 | **SC-4** `strings` over the Release binary returns no usable credential | ✓ VERIFIED (no regression) | Initial evidence stands (gate ×2 green, bidirectional harness 5/5, triage table). Regression check this session: the 01-06 diff over the two app-target Swift files contains **0** credential-shaped strings (`api key/secret/token/password/Bearer/sb_/eyJ` grep on the diff — clean). |
| 5 | **SC-5** Per D4: widget shows the app's stress score after refresh on a real device, OR the widget target is absent from the archive — **wire branch now live; simulator fallback branch satisfied; device half = standing human item per CONTEXT-sanctioned path** | ✓ VERIFIED (simulator path; device parity → Human Verification) | **Re-verified end-to-end this session (all four required probes):** (1) **Call graph live** — StressViewModel.swift:83 declares `lastPersistedReadingDate`; :189-192 inside `loadCurrentStress` (the funnel reached from DashboardView.swift:69/:96/:241 → `loadDashboardData`:378, plus :216 `requestHealthKitAccess`, :282, :549 demo timer, :580) guards on `hrvData?.timestamp != lastPersistedReadingDate`, sets the flag **synchronously before the await**, then `try? await repository.save(makeMeasurement(from: result))`; `StressRepository.save` calls `WidgetPublisher.publish(measurement)` (StressRepository.swift:57); `publish` writes all six `latest_*` keys into `UserDefaults(suiteName: "group.stress.ai.com")` then fires `WidgetCenter.shared.reloadAllTimelines()` (WidgetSharedData.swift:132-147). Shared `makeMeasurement(from:)` (:296) also serves `calculateAndSaveStress` (:317). (2) **Behavioral proof** — my own focused run: `xcodebuild test … -only-testing:StressMonitorTests/WidgetPublisherKeyMatchingTests` (iPhone 17/iOS 26.3, `-parallel-testing-enabled NO`, `TEST_RUNNER_GSD_CI=1`) → **TEST SUCCEEDED, 5/5**, including the live-path integration test (real `StressRepository` over an in-memory container: six keys non-nil, `latest_stress_level == 42 == currentStress?.level`) and the dedupe test (same reading → 1 save; +600 s → 2 saves). TDD gate: RED `f6d813a` contains **zero** StressViewModel lines (tests + mock fixture only, +94); GREEN `c6c82cf` carries the wiring. (3) **Same-tick evidence** — §8 machine-read: App Group plist `latest_stress_level = 73.19` / `moderate` / 20:55:45.4; dashboard hero "Elevated" (`.moderate` badge) and widget "Tense" (`WidgetStressTier` 61..<81) are both correct derivations of that one value; frozen-window protocol (app terminated 20:55:49 between captures); PNGs on disk (dashboard-live-value.png 20:55, widget-live-value.png 20:56); demo-mode disclosure retained; §2 empty-state pair marked superseded-historical. (4) **Frozen contracts** — my own `git diff 9c2001af..HEAD --stat` over WidgetSharedData.swift, WidgetDataState(.swift/.Tests), StressContextPayload.swift, HealthBackgroundScheduler.swift, DashboardViewModel.swift, all three entitlements, the entire `StressMonitorWidget/` tree, and the Watch tree = **0 lines**. |
| 6 | **SC-6** A Release archive is producible from the unmodified working tree (SPM proxy migration complete) AND CI's `fastlane match` readonly accepts the App Store profiles without regenerating them | ✓ VERIFIED (no regression) | Initial evidence stands (archives on disk — reconfirmed present this session: `Phase1-Final.xcarchive` + golden in `.asc/artifacts/`; clean-CI runs green; pins exact). Regression check this session: **0** changes over `9c2001af..HEAD` to `*.pbxproj` / `*Package.resolved` / `.github/workflows/` — proxy pinning untouched by gap closure. |

**Score:** 6/6 truths verified (0 present, behavior-unverified). SC-5's write-path behavior is exercised by a passing behavioral test (my own run), not symbol presence alone; the physical-device half of the CONTEXT-sanctioned fallback path (CONTEXT.md:25) is routed to human verification below with an expected-match outcome.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | `INFOPLIST_KEY_UIBackgroundModes` never merges — background modes silently absent from every shipped binary (pre-existing; 01-06 provably added no background execution) | Phase 2 (BUILD-04) | REQUIREMENTS.md traceability (BUILD-04 → Phase 2, Pending); 0-line diff over plists/pbxproj in the gap-closure range |

### Required Artifacts

Prior artifacts re-confirmed present this session; new 01-06 artifacts verified:

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `StressViewModel.swift` (wired) | `makeMeasurement(from:)` + `lastPersistedReadingDate` guard + save in `loadCurrentStress` | ✓ VERIFIED | :83 guard property, :189-192 guarded save (flag before await), :296 shared helper, :317 legacy path refactored onto it |
| `WidgetPublisherKeyMatchingTests.swift` (extended) | 3 new `@MainActor` tests, 2 originals untouched | ✓ VERIFIED | 164 lines; originals at :28-77 unchanged in shape; new tests at :81-163 exactly per plan Task 1; my run 5/5 |
| `MockServices.swift` | `MockHealthKitService.mockHRVTimestamp: Date?` via optional binding | ✓ VERIFIED | :13 property, :25 `if let stamp` (no force-unwrap) |
| `01-WIRE-01-EVIDENCE.md` §8 | Gap-closure section: trigger, RED→GREEN, same-value pair, §2 superseded, §6 open w/ expected-match, demo disclosure | ✓ VERIFIED | All components present; machine-read values quoted (73.19 / moderate / 20:55:45.4); §1-§7 retained unmodified |
| `StressMonitor/build/wire-01/*.png` (new pair) | widget-with-value + dashboard, same capture window | ✓ VERIFIED | `dashboard-live-value.png` (2.17 MB, 20:55) + `widget-live-value.png` (3.02 MB, 20:56) on disk; frozen tick 20:55:45.4 |
| Prior phase artifacts | verify-archive.sh/tests, proxies, watch manifest, docs, audits, archives | ✓ VERIFIED (carried) | Initial-verification table stands; no regression signal (0 changed binary-truth-adjacent files since `9c2001af`) |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `StressViewModel.loadCurrentStress` (live funnel) | `StressRepository.save` | guarded `try? await repository.save(makeMeasurement(from:))` (StressViewModel.swift:191) | ✓ WIRED — LIVE | Reached from every live foreground path (DashboardView :69/:96/:241; requestHealthKitAccess :216; observer :282/:580; demo timer :549); behavior pinned by 2 passing tests |
| `StressRepository.save` | `WidgetPublisher.publish` → six `latest_*` suite keys | direct call (StressRepository.swift:57 → WidgetSharedData.swift:132) | ✓ WIRED — LIVE | Was "wired-but-dead"; now has a live ancestor. Integration test proves keys land in `group.stress.ai.com` with level == dashboard's |
| `WidgetCenter.reloadAllTimelines` | widget timeline refresh | called at end of `publish` (WidgetSharedData.swift:147) | ✓ WIRED — LIVE | Downstream of the same now-live path; reload rides the dedupe guard |
| Widget read path | suite keys → `WidgetDataState.resolve` | `WidgetDataProvider.getLatestStress` | ✓ WIRED — LIVE + RENDERING | Read side now renders a live value (evidence §8: "Tense" from 73.19), not the empty state |
| StoreKit catalog / URL scheme / proxy pins / plist sources | (carried) | (carried) | ✓ WIRED (carried) | Unchanged this range — 0-line diffs |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Widget timeline | `latest_*` suite keys | `WidgetPublisher.publish` ← `repository.save` ← `loadCurrentStress` (live) | **Yes — one write per new underlying HRV reading** | ✓ FLOWING (was DISCONNECTED — the closed gap) |
| Widget rendering | suite values → `WidgetDataState.resolve` | shared UserDefaults | Yes — reads the now-written keys; §8 shows live tier rendered | ✓ FLOWING (was STATIC-by-absence) |
| Dashboard stress | `StressViewModel` → calculator → same `result` that is persisted | HealthKit/demo pipeline | Yes — same object flows to UI and (via `makeMeasurement`) to the widget | ✓ FLOWING (same-value claim machine-checked by test: `latest_stress_level == currentStress?.level`) |
| App/chat privacy payload | `StressContextPayload` | derived scores only | Yes — untouched (0-line diff, D3 zero-churn re-proven) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| **WIRE-01 write path end-to-end (the re-verification hook)** | `TEST_RUNNER_GSD_CI=1 xcodebuild test … -only-testing:StressMonitorTests/WidgetPublisherKeyMatchingTests` (iPhone 17, iOS 26.3, parallel NO) | **TEST SUCCEEDED — 5/5** (my run, 2026-09-03 21:04 xcresult); incl. real-repo six-key integration + same-value equality + dedupe | ✓ PASS |
| Save site inside the live funnel | `grep -n "repository.save\|lastPersistedReadingDate\|makeMeasurement" StressViewModel.swift` | :83/:189-192/:296/:317/:351 — save at :191 inside `loadCurrentStress` | ✓ PASS |
| TDD RED integrity | `git show f6d813a -- StressViewModel.swift \| wc -l` | **0** — RED commit has no production wiring; RED precedes GREEN (20:46 → 20:49) | ✓ PASS |
| Frozen contracts | `git diff 9c2001af..HEAD --stat -- <full frozen set incl. widget/watch trees>` | **0 lines** (my run) | ✓ PASS |
| Background-modes prohibition | range diff over plists/pbxproj + `git grep BGTaskSchedulerPermittedIdentifiers` | 0 plist/pbxproj changes; 0 occurrences | ✓ PASS |
| Evidence files | `ls StressMonitor/build/wire-01/` | 4 PNGs; new pair 20:55/20:56 + historical 17:05 pair | ✓ PASS |
| (carried) archive gates, manifest lint, deploy/match logs, PR state | see initial verification | all PASS (carried; no regression signal) | ✓ PASS (carried) |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| `WidgetPublisherKeyMatchingTests` (focused) | `bash`-launched `xcodebuild test -only-testing:…` per plan Task 1 verify block | exit 0, TEST SUCCEEDED, 5/5 | PASS |
| `scripts/verify-archive-tests.sh` | (carried from initial verification) | 5/5 PASS | PASS (carried) |
| `scripts/verify-archive.sh` golden + phase-final | (carried) | exit 0 both | PASS (carried) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| BUILD-01 | 01, 02, 03, 05 | Privacy manifest passes ASC upload validation | ✓ SATISFIED | Truth 1 (carried evidence; 0 manifest-adjacent changes since) |
| BUILD-02 | 04 | One canonical App Group suite across targets | ✓ SATISFIED | Truth 2 (carried + frozen-entitlements re-proof; new write uses the canonical constant) |
| BUILD-03 | 03 | Info.plist consolidated, single source per key | ✓ SATISFIED | Truth 3 (carried; 0 plist changes in range) |
| AUTH-01 | 04 | Empirical strings check — no extractable credentials | ✓ SATISFIED | Truth 4 (carried + clean diff grep on new code) |
| WIRE-01 | 04, **06** | Widget renders live stress data, not placeholder | ✓ SATISFIED (simulator path closed; device confirmation = standing human item per CONTEXT fallback) | Truth 5: live call graph + 5/5 tests (my run) + §8 machine-read same-value pair + frozen contracts 0-line. REQUIREMENTS.md now `[x]` / traceability Complete |
| ENV-04 | 01 | SPM proxy migration; archive from unmodified working tree | ✓ SATISFIED | Truth 6 (carried; 0 pbxproj/Package.resolved changes in range) |
| ENV-05 | 05 | CI match readonly accepts dual-cert-era App Store profiles | ✓ SATISFIED | Truth 6 (carried) |

Orphaned requirements: none — all 7 phase-mapped IDs appear in plan frontmatter (01-06 claims WIRE-01).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (new, 01-06) `StressViewModel.swift` | 115-204 | `loadCurrentStress` spans ~63 lines (function_body_length 50, opt-in rule) | ℹ️ Info | Advisory only; extraction would not clear the threshold and the plan prescribes inline placement; file already carried advisories — disclosed in 01-06-SUMMARY Deviations |
| (carried) `verify-archive.sh` scan-set/allowlist/comment items IN-01..03 | 29, 35-43, 15-16 | Info-level gate hardening residue | ℹ️ Info | Documented in 01-REVIEW; triage with developer |
| (carried) widget README / CLAUDE.md / proxy pins IN-04..07 | — | Doc-drift + transitive-pin float | ℹ️ Info | Carried; none block the goal |
| (resolved) STATE.md stale decision line | — | Prior note — now moot: STATE.md's wire-vs-descope entries were rewritten by 83aef3c | ℹ️ Info | Closed with the decision record |

Debt-marker gate: **0** `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` hits in the three 01-06 code files (my grep). No stub patterns introduced — the save block is real, guarded, and test-covered.

### Human Verification Required

Two standing end-of-phase items (both survive the phase regardless of status; see frontmatter `human_verification` for the structured copies):

### 1. Physical-device widget parity (WIRE-01 device half — expected MATCH)

**Test:** On hardware with real HealthKit data: install the wired build, open the app (foreground refresh now saves + publishes + reloads timelines), add/refresh the home-screen widget.
**Expected:** **Match** — the widget shows the same stress state the dashboard shows, immediately after the reload. This supersedes the prior expected outcome ("No Data" on a stock install): that expectation was correct for the pre-wiring binary and is now obsolete. Executing this check closes WIRE-01 end-to-end.
**Why human:** Requires real hardware + real HealthKit data. CONTEXT.md:25 sanctioned "simulator gallery + documented human UAT as fallback evidence" — the simulator half is machine-verified (§8); this is the documented human-UAT component.

### 2. EN↔VI privacy policy semantic parity (carried)

**Test:** Human read of `docs-site/legal/privacy.md` vs `docs-site/vi/legal/privacy.md` before publication.
**Expected:** Natural Vietnamese phrasing; semantic parity beyond grep-verified structural mirroring (all 5 manifest collection types covered in both).
**Why human:** Natural-language semantic equivalence is not grep-verifiable (carried from initial verification).

### Gaps Summary

**No gaps remain.** The single failure from the initial verification — SC-5 / WIRE-01, the widget's dead write path — is closed and independently re-proven this session at every level: the call graph is live in source (`loadCurrentStress` → guarded `repository.save` → `WidgetPublisher.publish` → six suite keys + `reloadAllTimelines`), the behavior is pinned by a passing focused suite run executed by the verifier (5/5, including the real-repository integration test asserting `latest_stress_level == currentStress?.level`), the simulator evidence shows both surfaces rendering derivations of one machine-read suite value (73.19), and every frozen contract (resolver, publisher, payload, entitlements, widget/watch trees) is byte-identical over the gap-closure range. TDD discipline held (RED commit contains zero production wiring). The change footprint is exactly the plan's file list; no regression signal on the five previously-verified truths (0 binary-truth-adjacent files changed since `9c2001af`).

Status is `human_needed`, not `passed`, solely because the CONTEXT-sanctioned verification path for WIRE-01 has a documented human-UAT component that requires hardware: the physical-device parity check (expected match now the write path is live), plus the carried EN↔VI policy parity read. These are execution-of-verification items awaiting a human, not defects — the automated half of every truth is verified.

---

_Verified: 2026-09-03T21:12:00+07:00_
_Verifier: the agent (gsd-verifier) — re-verification after plan 01-06 gap closure_
