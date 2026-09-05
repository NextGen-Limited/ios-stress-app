---
phase: 01-binary-manifest-truth
plan: 04
subsystem: infra
tags: [app-groups, entitlements, codesign, credential-scan, widgetkit, xcodebuild-archive, simulator]

requires:
  - phase: 01-01
    provides: scripts/verify-archive.sh artifact gate + SPM-proxy archive-from-working-tree proof
  - phase: 01-02
    provides: watch manifest CA92.1 fix + D3 doc truth (included in the phase-final archive this plan builds)
  - phase: 01-03
    provides: plist single-source + media-residue cleanup (included in the phase-final archive this plan builds)
provides:
  - BUILD-02 evidence bundle: one canonical App Group suite (group.stress.ai.com) proven across 3 entitlements files, 6 Swift constants + 1 test pin, runtime suite tests, and the signed build-13 golden archive (codesign dump ×3)
  - AUTH-01 verdict over the phase-final archive (Phase1-Final.xcarchive, Release, includes all plans 01-02/01-03 changes): verify-archive.sh exit 0; raw-strings triage table with every hit dispositioned benign; extra greps zero; fastlane/report.xml clean
  - WIRE-01 simulator evidence + the material discovery that WidgetPublisher.publish has zero live call sites (widget renders No Data on any device until a save trigger is wired — surfaced for user decision, not fixed)
  - StressMonitor/build/Phase1-Final.xcarchive (fresh unsigned Release verification artifact)
affects: [01-05 ASC upload + ENV-05 CI, phase verification, Phase 4 publish flow (entitlements dump mandate), WIRE-01 remediation decision]

actuals:
  tokens: 9200
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Raw-strings triage table recorded pre-allowlist (every hit dispositioned, not just the script verdict) — the AUTH-01 evidence shape"
    - "plutil array extraction via JSON form (numeric key-path indexing unsupported on this plutil) — equivalent single-element proof"
    - "Call-graph audit before claiming a data-flow requirement: grep the writer, then every caller of every saver, before declaring a widget/app flow live"

key-files:
  created:
    - .planning/phases/01-binary-manifest-truth/01-ARTIFACT-AUDIT.md
    - .planning/phases/01-binary-manifest-truth/01-WIRE-01-EVIDENCE.md
  modified:
    - StressMonitor/StressMonitorWidget/README.md

key-decisions:
  - "BUILD-02 audit-only confirmed: repo truth group.stress.ai.com overrides the CONTEXT.md decision-text typo; no rename, no shared-file merge — equality across three separate per-target files is the pass condition"
  - "WIRE-01 write-path gap surfaced as a Rule-4 architectural finding, NOT auto-wired: the widget's data source has no live writer (every repository.save caller is dead code), so the requirement stays open pending a user decision on the save trigger"
  - "Widget evidence uses the contract empty state honestly rather than fabricating suite data — the empty rendering itself proves the entitlement chain and frozen resolver behavior"

patterns-established:
  - "Evidence files quote on-screen values from the accessibility tree (describe), not screenshots-as-pixels — machine-quotable and honest"
  - "Simulator entitlements note: manual codesign re-sign of a built .app breaks SpringBoard launch trust on iOS 26 — use the stock xcodebuild product; simulator builds are permissive for app groups anyway"

requirements-completed: [BUILD-02, AUTH-01]

coverage:
  - id: D1
    description: "BUILD-02 — one canonical App Group suite across all three targets, audit-only (no rename)"
    requirement: BUILD-02
    verification:
      - kind: other
        ref: "plutil JSON extraction of com.apple.security.application-groups on all three .entitlements files = single-element ['group.stress.ai.com'] each"
        status: pass
      - kind: other
        ref: "grep UserDefaults(suiteName + literal 'group.' strings across real target dirs: 6 constants + 1 test pin, zero divergent literals"
        status: pass
      - kind: unit
        ref: "StressMonitorTests/WidgetPublisherKeyMatchingTests 2/2 TEST SUCCEEDED + suite-writing DataDeletion suites 4/4"
        status: pass
      - kind: other
        ref: "scripts/verify-archive.sh on signed build-13 golden: exit 0, ENTITLEMENTS PASS ×3"
        status: pass
    human_judgment: false
  - id: D2
    description: "AUTH-01 — no extractable credential in the phase-final archive's three binaries or bundled resources"
    requirement: AUTH-01
    verification:
      - kind: other
        ref: "verify-archive.sh StressMonitor/build/Phase1-Final.xcarchive --skip-entitlements → exit 0 (credential scan ×3, AIza resource grep, merged plists, SDK manifests)"
        status: pass
      - kind: other
        ref: "manual raw §7 strings pipeline: app binary shows only documented benign hits (eyJ error constant, 4 supabase Keychain-cleanup literals, STRESS_API_BASE_URL env-var name); widget + watch zero hits; AIza 0/0/0 in binaries, only in GoogleService-Info.plist; sb_* greps zero; fastlane/report.xml clean"
        status: pass
    human_judgment: false
  - id: D3
    description: "WIRE-01 widget evidence — simulator gallery + screenshots + disclosure + physical-device human item (with the write-path finding)"
    requirement: WIRE-01
    verification:
      - kind: other
        ref: "widget added via real gallery flow; renders without crash (suite opens — fatalError path avoided); screenshot pair in build/wire-01/ captured 9s apart; appex present in Phase1-Final.xcarchive"
        status: pass
      - kind: unit
        ref: "WidgetPublisherKeyMatchingTests 2/2 (referenced green result from Task 1)"
        status: pass
    human_judgment: true
    rationale: "WIRE-01's substance ('widget renders live data') is NOT met by the shipped binary — the write-path finding (zero live publish call sites) is a product/architecture decision the user must make (wire a save trigger or descope); automation cannot adjudicate it. The physical-device parity check also remains a human item."

duration: 58min
completed: 2026-09-03
status: complete
---

# Phase 1 Plan 4: Binary & Manifest Truth — evidence bundles Summary

**BUILD-02 one-suite audit and AUTH-01 credential gate both PASS with committed evidence (01-ARTIFACT-AUDIT.md) over a fresh Phase1-Final archive, and WIRE-01's simulator evidence surfaced a material finding: the widget's data source has no live writer — every repository.save caller is dead code, so the widget renders "No Data" on any device until a save trigger is wired (surfaced for user decision, not fixed)**

## Performance

- **Duration:** 58 min
- **Started:** 2026-09-03T09:07:54Z
- **Completed:** 2026-09-03T10:06:38Z
- **Tasks:** 3
- **Files modified:** 2 production/planning-tree files (README fix + 2 new evidence docs); archive + screenshots live under gitignored build/

## Accomplishments

- **BUILD-02 (PASS):** all three per-target entitlements files extract to the identical single-element `['group.stress.ai.com']`; six Swift suite constants + one test pin quote it verbatim with zero divergent literals; suite runtime tests green (WidgetPublisherKeyMatchingTests 2/2, suite-writing DataDeletion suites 4/4); the signed build-13 golden archive passes verify-archive.sh with ENTITLEMENTS PASS ×3 (build-12 regression guard)
- **AUTH-01 (PASS over the phase-final artifact):** fresh unsigned Release archive (ARCHIVE SUCCEEDED, includes all plans 01-02/01-03 changes) passes the full artifact gate (exit 0); a raw-strings triage pass recorded every hit with a benign disposition (Google App Check eyJ error constant, four supabase Keychain-cleanup literals, the STRESS_API_BASE_URL env-var name); AIza appears only in GoogleService-Info.plist; sb_publishable/sb_secret zero; fastlane/report.xml clean; .asc baseline untouched
- **WIRE-01 (evidence + finding):** widget added through the real simulator gallery flow and renders without crashing (shared suite opens — the WidgetDataProvider fatalError path is avoided); same-timestamp screenshot pair + demo-mode disclosure + frozen-contract note + physical-device human item recorded in 01-WIRE-01-EVIDENCE.md — alongside the call-graph proof that no live code path ever writes the widget's `latest_*` keys

## Task Commits

Each task was committed atomically:

1. **Task 1: BUILD-02 App Group audit** - `4894d95` (fix — includes the README typo correction)
2. **Task 2: AUTH-01 credential scan over phase-final archive** - `f437a9f` (docs)
3. **Task 3: WIRE-01 widget evidence** - `a272f04` (docs)

## Files Created/Modified

- `.planning/phases/01-binary-manifest-truth/01-ARTIFACT-AUDIT.md` - BUILD-02 audit + AUTH-01 verdict with raw command output, triage table, report.xml spot-check
- `.planning/phases/01-binary-manifest-truth/01-WIRE-01-EVIDENCE.md` - widget evidence note with demo-mode disclosure, screenshot pair reference, write-path finding
- `StressMonitor/StressMonitorWidget/README.md` - 3 typo-string sites corrected to the canonical suite (see Deviation 1)
- `StressMonitor/build/Phase1-Final.xcarchive` - verification artifact (local, gitignored)
- `StressMonitor/build/wire-01/{app-dashboard,widget-home-screen}.png` - screenshot pair (local, gitignored)

## Decisions Made

- **Suite truth = repo truth, audit-only** (orchestrator-settled): `group.stress.ai.com` everywhere; the CONTEXT.md decision-text string is a documented typo. No entitlements file was touched by this phase (git diff proves it).
- **WIRE-01 write-path gap is a Rule-4 finding, not an auto-fix**: wiring a foreground/background save trigger changes app behavior; the plan is evidence-only. Surfaced in the evidence file, STATE.md blockers, and this summary's coverage block (human judgment).
- **Honest empty-state evidence over fabricated data**: the widget screenshot shows the contract `empty` state; no suite data was hand-seeded to manufacture a matching-value pair (T-04-03 threat model — demo/synthetic data must not be presented as live evidence).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Widget README carried the CONTEXT typo string — acceptance criterion required zero source-tree matches**
- **Found during:** Task 1 (step 3 typo grep)
- **Issue:** The research's "zero matches" claim missed `StressMonitor/StressMonitorWidget/README.md` — a tracked v1.0-era setup doc carrying `group.com.stressmonitor.app` at 3 sites (lines 30, 88, 92). The file also ships inside the .appex as a copied resource.
- **Fix:** Corrected the 3 sites to `group.stress.ai.com` (docs move toward code — same direction as the plan-01-02 D3 precedent). Source-tree grep now returns zero; the fresh Phase1-Final archive's .appex carries the corrected copy (verified).
- **Files modified:** StressMonitor/StressMonitorWidget/README.md
- **Verification:** `grep -rn "group.com.stressmonitor" StressMonitor/ --include=… (source types)` → 0; fresh .appex README shows `group.stress.ai.com` ×3
- **Committed in:** 4894d95

**2. [Rule 3 - Blocking] plutil numeric key-path indexing unsupported — plan's literal verify form fails**
- **Found during:** Task 1 (step 1)
- **Issue:** `plutil -extract com.apple.security.application-groups.0` errors ("No value at that key path") on this plutil build — array indexing in key paths is not accepted.
- **Fix:** Used the equivalent `plutil -extract "com.apple.security.application-groups" json` (prints the whole array — proves value AND single-element shape, covering the empty/missing edge in the same output).
- **Verification:** JSON extraction returns `["group.stress.ai.com"]` for each file
- **Committed in:** evidence recorded in 4894d95's audit file

**3. [Rule 3 - Blocking] Simulator build signing experiments blocked app launch (self-inflicted, reverted)**
- **Found during:** Task 3 (attempting to embed entitlements into the Debug simulator build)
- **Issue:** (a) my first build used CI-parity unsigned flags; (b) a manual `codesign --force --sign - --entitlements` re-sign produced a bundle SpringBoard refuses to launch (SBMainWorkspace denial persisting across uninstall/reinstall/reboot); (c) mid-session the argent simulator-server touch pipeline wedged (taps delivered but ignored system-wide).
- **Fix:** Reverted to the stock xcodebuild Debug product (which launches fine — simulator builds are permissive for app groups; the entitlements chain is proven at source + golden-signed-artifact + runtime-test level regardless); restored the touch pipeline via the skill-documented `stop-simulator-server` remedy.
- **Files modified:** none in the repo (build-dir churn only)
- **Verification:** app relaunches, onboarding walk completes, gallery flow works, screenshot pair captured
- **Committed in:** n/a (no repo changes)

**4. [Rule 4 - Architectural] WIRE-01 acceptance criterion "widget value matches dashboard" is unachievable in the shipped binary — surfaced, NOT auto-fixed**
- **Found during:** Task 3 (steps 1-4)
- **Issue:** `WidgetPublisher.publish` has zero live call sites: `calculateAndSaveStress` (no callers since bba996a), `DashboardViewModel.refreshStressLevel` (preview-only VM), `HealthBackgroundScheduler` (never instantiated; no UIBackgroundModes shipped). The watch writes different keys (`watch.*`). Demo mode's 15 s loop updates UI only. Consequence: the iOS widget renders "No Data" on ANY device — simulator or physical.
- **Fix (surface only):** documented with call-graph evidence in 01-WIRE-01-EVIDENCE.md §7; WIRE-01 left unchecked; STATE.md blocker added. Wiring a save trigger is a user decision (candidates listed in the evidence file).
- **Verification:** repo-wide call-graph greps quoted in the evidence file; on-device expectation stated for the human item
- **Committed in:** a272f04

---

**Total deviations:** 4 auto-fixed/handled (1× Rule 1, 2× Rule 3, 1× Rule 4 surfaced)
**Impact on plan:** Task 1 and Task 2 fully met as written (with equivalent-form command substitutions). Task 3 met in its executable path (gallery flow, disclosure, archive check, contract note, human item) with one acceptance criterion honestly unmet and escalated — no scope creep, no fabricated evidence.

## Issues Encountered

- The WIRE-01 write-path discovery reframes the requirement (see Deviation 4) — carried into Next Phase Readiness and STATE.md as a blocker requiring a user decision.
- `await-ui-element` argent tool unavailable in this Code Mode runtime; describe-gated sequencing used instead (tapping rule still honored — discovery before every tap).
- This session's model runtime cannot render images into context; on-screen values were verified through the accessibility tree and quoted textually in the evidence docs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BUILD-02 and AUTH-01 are evidence-complete; 01-05 (ASC upload validation + ENV-05 CI) can proceed against `StressMonitor/build/Phase1-Final.xcarchive` semantics (its own signed build is the upload surface).
- **WIRE-01 is blocked on a user decision**: wire a save trigger (recommended candidates in 01-WIRE-01-EVIDENCE.md §7) or descope the widget for v1.2. This gates the phase's "widget true" claim and D4's intent.
- The physical-device WIRE-01 check remains a pending human item (end-of-phase) — expected to confirm the "No Data" finding on hardware, then re-verify post-fix.

## Self-Check: PASSED

- Commits 4894d95, f437a9f, a272f04 exist on gsd/v1.2-submission-readiness (verified via git log)
- 01-ARTIFACT-AUDIT.md and 01-WIRE-01-EVIDENCE.md exist on disk (8.9 KB + 8.8 KB, committed)
- Screenshot pair exists (2.1 MB + 2.9 MB, >0 bytes); appex present in Phase1-Final.xcarchive
- Re-ran consolidated post-commit verification: three entitlements extracts identical, suite tests green (earlier this session), verify-archive.sh exit 0 on both golden and phase-final archives
