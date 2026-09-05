---
phase: 1
slug: binary-manifest-truth
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-03
validated: 2026-09-03
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Swift Testing suites) + bash harness (scripts/verify-archive-tests.sh) |
| **Config file** | StressMonitor/StressMonitor.xcodeproj schemes; scripts/verify-archive.sh |
| **Quick run command** | `TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/WidgetPublisherKeyMatchingTests` |
| **Full suite command** | `TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` |
| **Estimated runtime** | ~300 seconds (full suite 217 tests / 40 suites measured) |

---

## Sampling Rate

- **After every task commit:** Quick suite for touched target (executors ran `<automated>` verify per plan task)
- **After every plan wave:** Full suite (`TEST_RUNNER_GSD_CI=1` env-var gating for WINDOWS.md #8 suites)
- **Before `/gsd-verify-work`:** Full suite green (217/217 at 01-06 completion)
- **Max feedback latency:** ~900 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | ENV-04 | T-01-01 supply-chain | exact-revision pins, no floating reqs | tdd (bash harness) | `bash scripts/verify-archive-tests.sh` (5/5) | ✅ scripts/verify-archive-tests.sh | ✅ green |
| 01-01-02 | 01 | 1 | ENV-04 | T-01-01 | proxy resolve + pinned lockfile | execute | `swift package resolve` + pbxproj greps | ✅ | ✅ green |
| 01-01-03 | 01 | 1 | ENV-04/AUTH-01 | T-03-01 | archive-from-tree gate | execute | `xcodebuild archive … && verify-archive.sh --skip-entitlements` | ✅ Phase1-Verify.xcarchive | ✅ green |
| 01-02-01 | 02 | 2 | BUILD-01 | — | manifest truth | execute | `plutil -lint` ×3 + reasons JSON extract | ✅ | ✅ green |
| 01-02-02 | 02 | 2 | BUILD-01 | — | docs-toward-code, zero churn | execute | greps (supabase=0, dropitx.site present) + payload byte-identical | ✅ | ✅ green |
| 01-03-01 | 03 | 2 | BUILD-03 | T-03-01 | merged-plist key equality | execute | 6× `plutil -extract` on built product + key-set diff vs build-13 | ✅ | ✅ green |
| 01-03-02 | 03 | 2 | BUILD-01 | — | dead machinery removal | execute | pbxproj greps (Giphy=0) + app/widget BUILD SUCCEEDED | ✅ | ✅ green |
| 01-04-01 | 04 | 3 | BUILD-02 | — | one suite, no placeholder | execute | entitlements plutil ×3 + constants grep + ENTITLEMENTS PASS ×3 | ✅ 01-ARTIFACT-AUDIT.md | ✅ green |
| 01-04-02 | 04 | 3 | AUTH-01 | T-04-01 (critical) | no extractable credential | execute | `verify-archive.sh Phase1-Final.xcarchive --skip-entitlements` exit 0 + triage table | ✅ | ✅ green |
| 01-04-03 | 04 | 3 | WIRE-01 | — | widget evidence (simulator) | execute+UI | argent AX-tree same-value proof + screenshots | ✅ build/wire-01/ | ✅ green |
| 01-05-01 | 05 | 4 | ENV-04 | — | clean-CI proof | execute | ci.yml runs 33745603902 / 33746936991 green | ✅ 01-ENV-05-CI-RECORD.md | ✅ green |
| 01-05-02 | 05 | 4 | ENV-05, BUILD-01 | — | match readonly + ASC gate | checkpoint→execute | deploy run 33749862925: match readonly green; build 14 VALID | ✅ | ✅ green |
| 01-06-01 | 06 | 5 | WIRE-01 | T-06-01 | one save per reading | tdd | 3 tests in WidgetPublisherKeyMatchingTests (RED→GREEN) | ✅ | ✅ green |
| 01-06-02 | 06 | 5 | WIRE-01 | — | frozen contracts + regression | execute | range-diff 0 lines + full suite 217/217 | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 (tracer, plan 01-01) created `scripts/verify-archive.sh` + harness before plans 03/04 consumed it. Existing infrastructure covered all phase requirements; no additional Wave 0 installs needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Result |
|----------|-------------|------------|-------------------|--------|
| EN↔VI policy parity read | BUILD-01 | Natural-language parity judgment | UAT Test 1 | ✅ pass (UAT 2026-09-03) |
| Physical-device widget parity | WIRE-01 | Hardware + TestFlight install | UAT Test 2 | ✅ pass (UAT 2026-09-03) |

---

## Validation Audit 2026-09-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 7 requirement IDs (BUILD-01/02/03, AUTH-01, WIRE-01, ENV-04, ENV-05) classified COVERED by green automated verification; sampling continuity holds (every task carries `<automated>` verify); both manual-only items closed via UAT pass.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 900s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-03
