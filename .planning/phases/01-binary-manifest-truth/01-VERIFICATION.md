---
phase: 01-binary-manifest-truth
verified: 2026-09-03T21:05:00+07:00
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC-5 / WIRE-01: per D4, the widget on a real device shows the same stress score the app shows after a refresh, OR the widget target is absent from the archive's bundle list — neither branch holds"
    status: failed
    reason: "WidgetPublisher.publish (the only writer of the widget's latest_* suite keys) has zero live call sites. Independently re-verified by call-graph grep this session: its sole production caller StressRepository.save is invoked only from dead paths — StressViewModel.calculateAndSaveStress (0 call sites), DashboardViewModel.refreshStressLevel (DashboardViewModel constructed only in SwiftUI previews), HealthBackgroundScheduler.fetchAndCalculateStress (class never instantiated; no effective UIBackgroundModes shipped). The widget appex IS present in the phase-final archive, so the exclude-from-build branch is false too. The widget renders its 'No Data' empty state on any device. This failure was discovered and honestly surfaced by plan 01-04 (01-WIRE-01-EVIDENCE.md §7), recorded as a STATE.md blocker, and awaits the user's wire-vs-descope decision — it was never papered over by any SUMMARY."
    artifacts:
      - path: "StressMonitor/StressMonitor/Models/WidgetSharedData.swift"
        issue: "WidgetPublisher.publish (line 132) is implemented and unit-tested but never invoked by any live code path"
      - path: "StressMonitor/StressMonitor/ViewModels/StressViewModel.swift"
        issue: "calculateAndSaveStress() (line 276) has zero call sites — the only live-candidate path that saves a measurement and publishes to the widget"
      - path: "StressMonitor/StressMonitor/Services/Background/HealthBackgroundScheduler.swift"
        issue: "never instantiated anywhere; background-refresh registration has no call sites"
    missing:
      - "User product decision (STATE.md blocker): wire a save trigger (foreground calculateAndSaveStress call, HealthBackgroundScheduler registration, or save-on-loadCurrentStress) OR descope the widget from the v1.2 submitted build (D4 flip)"
      - "If wiring: one live call site invoking WidgetPublisher.publish on real measurements, plus re-captured widget/app same-value evidence (simulator + physical device)"
      - "If descoping: widget target absent from the Release archive's PlugIns/ and no dead widget code shipping"
deferred:  # Items addressed in later phases — not actionable gaps
  - truth: "INFOPLIST_KEY_UIBackgroundModes = 'fetch processing' never merges into product plists — background fetch/processing silently absent from every shipped binary"
    addressed_in: "Phase 2 (BUILD-04)"
    evidence: "REQUIREMENTS.md traceability maps BUILD-04 to Phase 2; phase deferred-items.md names BUILD-04/submission-hardening as candidate owner; pre-existing condition, identical before and after Phase 1 (no key was lost by this phase)"
---

# Phase 1: Binary & Manifest Truth — Verification Report

**Phase Goal:** Everything the shipped archive declares about itself is true — Apple's automated validation accepts the privacy manifest, all three targets agree on one App Group suite, Info.plist keys resolve from a single source, the Release binary leaks no credential, and the widget either renders real data or is not in the build at all.
**Verified:** 2026-09-03T21:05:00+07:00
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Must-haves merged from ROADMAP.md success criteria (the contract) with plan frontmatter detail. Plan truths were checked and are folded into the evidence column; none reduced scope.

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | **SC-1** A Release archive uploads to ASC and clears privacy-manifest validation — no missing required-reason declaration, no missing third-party SDK manifest | ✓ VERIFIED | Live external evidence, re-checked this session: deploy run 33749862925 `success` at `acea984` (gh); fetched full run log — **0** occurrences of `ITMS-91053`, **0** "required reason"/privacy-manifest error strings, **20** match-readonly/profile lines. CI record documents TestFlight build 1.0.0 (14) `state=VALID`, `APP_STORE_ELIGIBLE` (asc CLI output recorded). Manifest content: `plutil -lint` OK ×3 (this session); watch reasons = `["CA92.1","1C8F.1"]` (this session). SDK PrivacyInfo.xcprivacy bundles present in both golden and phase-final archives (my own `verify-archive.sh` runs, exit 0). Boundary note: build 14 anchored at `acea984`; all subsequent commits are provably non-binary-affecting for manifest truth (pbxproj diff after `acea984` is deletion-only — 0 additions; remainder is scripts/tests/docs/planning). |
| 2 | **SC-2** App, widget, and watch targets read/write one canonical App Group suite; no target falls back to a placeholder suite or fails to open the shared container | ✓ VERIFIED | All three `.entitlements` files read directly: identical single-element `["group.stress.ai.com"]` (widget's only capability; app/watch + healthkit/iCloud). Six Swift constants + 1 test pin quote the suite verbatim (grep this session); `group.com.stressmonitor` typo = **0 in tracked sources** (`git grep`; 9 hits are stale build products under `build/`, exactly as the audit documented — the phase-final archive's appex README carries the corrected copy, verified 3/0). Gate `ENTITLEMENTS PASS ×3` on the signed golden (my run). Runtime: `WidgetPublisherKeyMatchingTests` 2/2 + suite-writing DataDeletion suites 4/4 recorded TEST SUCCEEDED (audit; full suite green at current tree per 01-REVIEW final verification — not re-executed here, no long builds). No placeholder fallback exists by construction — `WidgetDataProvider` fatalError's on nil suite rather than degrading, and the widget rendered without crashing on simulator (evidence §3, screenshot pair on disk). |
| 3 | **SC-3** Every Info.plist key the app depends on resolves from a single source — no orphaned or duplicate plist file contributes keys | ✓ VERIFIED | Criterion's substance holds via the documented empirical inversion (custom `INFOPLIST_KEY_STOREKIT_*` never merge on Xcode 26.3; plan's literal mechanism inverted, recorded in 01-03-SUMMARY + STATE.md decision). This session: app source plist = `CFBundleURLTypes` + exactly the six STOREKIT keys (single home, `plutil -p`); pbxproj `INFOPLIST_KEY_STOREKIT` count = **0** (dead duplicates deleted); widget plist retained one-key, `NSExtensionPointIdentifier = com.apple.widgetkit-extension` (plutil). Product-level: my own `verify-archive.sh` run on `Phase1-Final.xcarchive` — all six keys + URL scheme + widget ext point PASS in the **built** plists. |
| 4 | **SC-4** `strings` over the Release binary returns no usable credential | ✓ VERIFIED | My own runs: gate on golden `.asc/artifacts` archive exit 0 (all 11 checks, post-CR-01-hardened URL-scheme check); gate on phase-final `Phase1-Final.xcarchive` exit 0. Bidirectional probe `verify-archive-tests.sh` **5/5 PASS** including red-on-planted-secret and anti-vacuous URL-scheme pair (my run). Raw-strings triage table in 01-ARTIFACT-AUDIT.md: every hit dispositioned benign (eyJ error constant, 4 supabase Keychain-cleanup names, env-var name); AIza only in GoogleService-Info.plist; `sb_*` 0; `fastlane/report.xml` re-checked this session — two lane stubs only, no token material. `.asc/artifacts/` untouched (mtimes Sep 3 00:24, pre-session). |
| 5 | **SC-5** Per D4: widget shows the app's stress score after refresh on a real device, OR the widget target is absent from the archive | ✗ FAILED | **Neither branch true.** Call-graph independently re-verified this session: `WidgetPublisher.publish` production callers = `StressRepository.swift:57` only; its callers are `StressViewModel.calculateAndSaveStress` (**0 call sites**), `DashboardViewModel.refreshStressLevel` (constructed only in previews via `PreviewDataFactory`), `HealthBackgroundScheduler` (**never instantiated**). Widget appex IS in the archive (`PlugIns/StressMonitorWidgetExtension.appex` present). Widget renders "No Data" on any device. See gap in frontmatter + 01-WIRE-01-EVIDENCE.md §7 + STATE.md blocker. |
| 6 | **SC-6** A Release archive is producible from the unmodified working tree (SPM proxy migration complete) AND CI's `fastlane match` readonly accepts the App Store profiles without regenerating them | ✓ VERIFIED | `Phase1-Verify.xcarchive` + `Phase1-Final.xcarchive` on disk (final passes my gate run). Proxy migration: 9 package files tracked (`git ls-files`); exactly one `XCLocalSwiftPackageReference` ("proxy"), **0** `XCRemoteSwiftPackageReference` (no revert); `_proxied` productNames ×3; exact-revision pins in shims + umbrella + project `Package.resolved` (firebase-ios-sdk `fdc352f…`, googlesignin-ios `08d8dce…`); no floating requirements. Clean-machine CI: run 33745603902 `success` at `fcd4c87` (live gh), later runs green at `acea984` including post-review head. ENV-05: deploy run 33749862925 `success` (live gh); match readonly + `force:false` + three `match AppStore` profiles in the actual fetched log (20 matching lines); zero regeneration strings; setup_match never touched (`.github/workflows/` diff vs origin/main = empty). |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | `INFOPLIST_KEY_UIBackgroundModes` never merges — background modes silently absent from every shipped binary (pre-existing) | Phase 2 (BUILD-04) | REQUIREMENTS.md traceability; phase `deferred-items.md` names BUILD-04 as candidate owner |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `scripts/verify-archive.sh` | 5-check read-only artifact gate, allowlist comments, `--skip-entitlements` | ✓ VERIFIED | 11,713 B, executable; 8 allowlist/triage comment anchors; green on golden + phase-final (my runs) |
| `scripts/verify-archive-tests.sh` | Bidirectional harness (green/red/entitlements ×3 + URL-scheme pair) | ✓ VERIFIED | 5/5 PASS (my run); golden-absent SKIP guard per WR-01 fix |
| `.proxies/Firebase_proxy/` (Package.swift + 2 shims) | Firebase shim package, revision-pinned | ✓ VERIFIED | Tracked; pin `fdc352f…` exact; `@_exported import` shims |
| Watch `PrivacyInfo.xcprivacy` | CA92.1 + 1C8F.1 reasons | ✓ VERIFIED | plutil extract = `["CA92.1","1C8F.1"]`; lint OK |
| `CLAUDE.md` + EN/VI privacy policies | Real contract (stress-api.dropitx.site, Firebase Auth), zero Supabase-era claims | ✓ VERIFIED | `supabase` count 0 in all three at HEAD and working tree; endpoint ×3, "Firebase Auth" ×2 (CLAUDE.md), ×2 each locale; WR-04 collection-type coverage landed (5 manifest types in both locales) |
| `project.pbxproj` | Migration + cleanup: no STOREKIT settings, no Giphy phase, `_proxied` names, local-proxy-only | ✓ VERIFIED | All greps this session: 0 / 0 / ×3 / 1 ref / 0 remote |
| Project `Package.resolved` | firebase-ios-sdk 11.15.0 pin regained, googlesignin pinned | ✓ VERIFIED | JSON parse: revisions `fdc352f…` / `08d8dce…` |
| `01-ARTIFACT-AUDIT.md` | BUILD-02 + AUTH-01 evidence | ✓ VERIFIED | 135 lines; all 7 required sections present; raw output + triage table |
| `01-WIRE-01-EVIDENCE.md` | Widget evidence + disclosure + human item + write-path finding | ✓ VERIFIED | All sections incl. demo-mode disclosure, §7 call-graph finding, §6 pending device check |
| `01-ENV-05-CI-RECORD.md` | Push/PR/CI + approval + match verdict + ASC verdict | ✓ VERIFIED | All sections; run URLs live-rechecked via gh this session |
| `Phase1-Final.xcarchive` + `wire-01/*.png` | Final archive + screenshot pair | ✓ VERIFIED | On disk; appex present; 2 PNGs (2.1 MB / 2.9 MB) |
| `StressMonitorWidget/README.md` | Typo strings corrected | ✓ VERIFIED | 3× canonical / 0× typo in source and in final archive's appex |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| `StressRepository.save` | `WidgetPublisher.publish` → suite keys | direct call (WidgetSharedData.swift:132 ← StressRepository.swift:57) | ⚠️ WIRED-BUT-DEAD (call exists; **no live caller of save** — the SC-5 gap) |
| `WidgetCenter.reloadAllTimelines` | widget timeline refresh | called by `publish` | ⚠️ WIRED-BUT-DEAD (downstream of the same dead path) |
| StoreKit catalog (3-tier resolution) | merged app plist STOREKIT keys | `StoreKitProductCatalog` tier-1 Info.plist read | ✓ WIRED (keys present in built product plists — gate check 2, my run) |
| GoogleSignIn callback | `CFBundleURLSchemes` in plist file | retained plist key (no build-setting equivalent) | ✓ WIRED (gate check: non-empty array, hardened post-CR-01) |
| Widget read path | suite keys → `WidgetDataState.resolve` | `WidgetDataProvider.getLatestStress` | ✓ WIRED (read side live and rendering — the empty state, honestly) |
| pbxproj ↔ proxy packages ↔ upstream pins | 3-place `_proxied` naming + XCLocalSwiftPackageReference | atomic rename | ✓ WIRED (resolution proven on clean CI hardware, run 33745603902) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Widget timeline | `latest_*` suite keys | `WidgetPublisher.publish` (write) | **No — zero live invocations** | ✗ DISCONNECTED (the gap) |
| Widget rendering | suite values → `WidgetDataState.resolve` | shared UserDefaults | Reads real (empty) suite; displays contract empty state | ⚠️ STATIC (by absence of writer, disclosed honestly) |
| Dashboard stress | `StressViewModel` → `MultiFactorStressCalculator` | HealthKit/demo pipeline | Yes (real pipeline; screenshot shows live demo-mode reading) | ✓ FLOWING |
| App/chat privacy payload | `StressContextPayload` | derived scores only | Yes (untouched this phase — D3 zero-churn proven) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Gate green on signed golden | `bash scripts/verify-archive.sh .asc/artifacts/StressMonitor.xcarchive` | exit 0, 11× PASS | ✓ PASS |
| Gate green on phase-final archive | `bash scripts/verify-archive.sh StressMonitor/build/Phase1-Final.xcarchive --skip-entitlements` | exit 0, all PASS | ✓ PASS |
| Bidirectional gate (red/green) | `bash scripts/verify-archive-tests.sh` | 5/5 PASS incl. planted-secret red | ✓ PASS |
| Manifest lint + reasons | `plutil -lint` ×3; extract watch reasons | OK ×3; `["CA92.1","1C8F.1"]` | ✓ PASS |
| Widget ext point in source plist | `plutil -extract NSExtension.NSExtensionPointIdentifier` | `com.apple.widgetkit-extension` | ✓ PASS |
| Deploy run + match + ITMS absence | `gh run view 33749862925 --log \| grep` | success; 20 match lines; 0 ITMS-91053 | ✓ PASS |
| PR state / main untouched | `gh pr view 49`; `git log origin/main -1` | OPEN + isDraft:true; `fed4b6b` | ✓ PASS |
| WIRE-01 write-path liveness | call-graph greps (publish / save / calculateAndSaveStress / DashboardViewModel( / HealthBackgroundScheduler) | zero live writers | ✗ CONFIRMS GAP |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| `scripts/verify-archive-tests.sh` | `bash scripts/verify-archive-tests.sh` | 5/5 PASS, 0 failures | PASS |
| `scripts/verify-archive.sh` (golden) | `bash … .asc/artifacts/StressMonitor.xcarchive` | exit 0 | PASS |
| `scripts/verify-archive.sh` (phase-final) | `bash … Phase1-Final.xcarchive --skip-entitlements` | exit 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| BUILD-01 | 01, 02, 03, 05 | Privacy manifest passes ASC upload validation | ✓ SATISFIED | Truth 1 (SC-1): live run log clean of ITMS-91053; build 14 VALID recorded; manifest content + SDK bundles verified in-binary |
| BUILD-02 | 04 | One canonical App Group suite across targets | ✓ SATISFIED | Truth 2 (SC-2): entitlements ×3, constants, typo-grep 0, gate ×3, suite tests recorded |
| BUILD-03 | 03 | Info.plist consolidated, single source per key | ✓ SATISFIED | Truth 3 (SC-3): inversion documented; source + product-level proof (my gate run) |
| AUTH-01 | 04 | Empirical strings check — no extractable credentials | ✓ SATISFIED | Truth 4 (SC-4): my gate runs ×2 + harness red-proof + triage table |
| WIRE-01 | 04 | Widget renders live stress data on a real device, not placeholder | ✗ NOT SATISFIED | Truth 5 (SC-5) FAILED — the gap. REQUIREMENTS.md consistently shows WIRE-01 unchecked/"Pending" |
| ENV-04 | 01 | SPM proxy migration; archive from unmodified working tree | ✓ SATISFIED | Truth 6 (SC-6): archives on disk + gate; pins verified; clean-CI success live-rechecked |
| ENV-05 | 05 | CI match readonly accepts dual-cert-era App Store profiles | ✓ SATISFIED | Truth 6: run success live; match readonly + 3 profiles in fetched log; zero regeneration |

Orphaned requirements: none — all 7 phase-mapped IDs appear in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (carried) `scripts/verify-archive.sh` | 29 | IN-01: scan pattern set misses AWS/GitHub/Slack token shapes | ℹ️ Info | Documented in 01-REVIEW; triage with developer |
| (carried) `scripts/verify-archive.sh` | 35-43 | IN-02: stale supabase allowlist could mask reintroduction | ℹ️ Info | Documented; same |
| (carried) `scripts/verify-archive.sh` | 15-16 | IN-03: stale STOREKIT merge-mechanism comment | ℹ️ Info | Cosmetic doc drift |
| (carried) `StressMonitorWidget/README.md` | 5,79-83,114-137 | IN-04: name/iOS-version truth gaps, unimplemented snippet | ℹ️ Info | Doc-only; ships in appex |
| (carried) `CLAUDE.md` / root `AGENTS.md` | 207,480 | IN-05: "Dependencies: None" + "plist committed" contradictions | ℹ️ Info | Doc drift |
| (carried) pbxproj + `spm_cache_root.swift` | — | IN-06: 0-byte tracked proxy root file; pbxproj re-serialization churn risk | ℹ️ Info | Verified 0 bytes this session |
| (carried) `proxy/Package.resolved` | 74-82 | IN-07: only 2 direct deps revision-pinned; 15 transitive pins float | ℹ️ Info | GoogleUtilities drifted 8.1.2→8.1.3 in-phase |
| `.planning/STATE.md` | decisions | "spm-cache/ package sources stay uncommitted" superseded by 01-05's scoped-exception commit (483f270) — stale decision line | ℹ️ Info | Later decision documented in 01-05 summary; STATE.md line is historical |

No `TBD`/`FIXME`/`XXX` debt markers in any phase-modified production file (scanned this session). The single "placeholder" grep hit in the widget README is WidgetKit's legitimate placeholder-timeline API concept, not a stub. Code review state: 0 critical / 0 warning open, 5/5 in-scope findings verified FIXED (CR-01 hardening re-proven by my harness run).

### Human Verification Required

Surfaced for the end-of-phase human checkpoint (survives the gaps_found status):

### 1. WIRE-01 disposition — wire the widget write path or descope the widget

**Test:** Decide (product decision, STATE.md blocker): add a live save trigger (foreground `calculateAndSaveStress` call, `HealthBackgroundScheduler` registration, or save-on-`loadCurrentStress`) or remove the widget from the v1.2 submitted build.
**Expected:** Either the widget renders the app's current stress score after a refresh, or the appex is absent from the Release archive.
**Why human:** App-behavior change / scope decision; automation cannot adjudicate intent. Every candidate wiring was deliberately left unwired (Rule 4 in plan 01-04).

### 2. Physical-device widget check (confirm the finding on hardware)

**Test:** On a physical device with real HealthKit data: install, add the widget, take a measurement, refresh the widget.
**Expected:** Per the call-graph evidence, the widget will show "No Data" on a stock install until the write path is wired; re-verify parity after the D4 disposition lands.
**Why human:** Requires real hardware + real HealthKit data; simulator evidence already captured (empty-state rendering, honestly disclosed as demo-mode).

### 3. EN↔VI privacy policy semantic parity

**Test:** Human read of `docs-site/legal/privacy.md` vs `docs-site/vi/legal/privacy.md` before publication.
**Expected:** Vietnamese phrasing natural; semantic parity beyond the grep-verified structural mirroring (both now cover all 5 manifest collection types, non-tracking).
**Why human:** Natural-language quality and cross-language semantic equivalence are not grep-verifiable (plan 02 coverage flagged human_judgment).

### Gaps Summary

One gap blocks the phase goal, and it is exactly the one the phase itself surfaced: **SC-5 / WIRE-01**. Everything else the archive declares about itself is now true and independently re-verified — the manifest validates at ASC (live log evidence, zero ITMS-91053), one suite spans all three targets (source, constants, signed-artifact, and recorded runtime proof), every plist key has exactly one home (the empirically-correct one, achieved via the documented inversion), no credential is extractable (bidirectional gate re-run green), and the tree archives cleanly with CI match-readonly green.

The widget's write→read path is fully built, unit-tested, and entitlement-wired — but nothing live ever invokes it, so the widget ships in the build rendering "No Data." Success criterion 5 is a disjunction and both branches are false. The phase's executors handled this honestly (evidence file §7, STATE.md blocker, unchecked requirement); the verification confirms it as the sole blocker. Resolution is one user decision away: wire one call site or exclude the target. If the owner instead chooses to accept/defer the widget gap beyond v1.2 Phase 1, record it as a frontmatter override or roadmap change — it cannot silently pass.

---

_Verified: 2026-09-03T21:05:00+07:00_
_Verifier: the agent (gsd-verifier)_
