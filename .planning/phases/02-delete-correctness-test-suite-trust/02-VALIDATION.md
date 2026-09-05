---
phase: 2
slug: delete-correctness-test-suite-trust
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-03
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Swift Testing suites) — existing |
| **Config file** | StressMonitor/StressMonitor.xcodeproj scheme StressMonitor; CI-parity env gating TEST_RUNNER_GSD_CI=1 |
| **Quick run command** | `TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/<suite>` |
| **Full suite command** | CI-parity invocation (see AGENTS.md — the canonical BUILD-04 source) |
| **Estimated runtime** | ~300–900 seconds |

---

## Sampling Rate

- **After every task commit:** quick suite for touched target
- **After every plan wave:** full suite (CI-parity, env-var gated)
- **Before `/gsd-verify-work`:** full suite green + trust-gate grep (no new disables)
- **Max feedback latency:** 900 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-T1 | 02-01 | 1 | DATA-04 | T-02-01/02 | Lying CloudKit double detectable; query-based emptiness | unit (DI spy, CI-green) | `-only-testing:StressMonitorTests/DataDeleterCloudKitTruthinessTests` | ⬜ new this phase | ⬜ pending |
| 02-01-T2 | 02-01 | 1 | DATA-04 | T-02-01 | Mutation proof: suite red when orchestrator swallows failures | unit (mutation run) | same -only-testing run (red) + revert + green | ⬜ recorded in SUMMARY | ⬜ pending |
| 02-02-T1 | 02-02 | 1 | ENV-03 | T-02-03 | Unverified transaction finished zero times (RED first) | unit (fake handle) | `-only-testing:StressMonitorTests/CreditPurchaseFlowTests` | ⬜ new test | ⬜ pending |
| 02-02-T2 | 02-02 | 1 | ENV-03 | T-02-03/04 | Finish removed from unverified branch; reachability note | unit + doc | same suite green + swiftlint | ✅ suite exists | ⬜ pending |
| 02-03-T1 | 02-03 | 2 | ENV-03 | T-02-05 | Wiring pin: DEBUG resolves real service absent override (RED first) | unit (#if DEBUG) | `-only-testing:StressMonitorTests/StoreKitServiceWiringTests` | ⬜ new this phase | ⬜ pending |
| 02-03-T2 | 02-03 | 2 | ENV-03 | T-02-05/06 | Both wiring sites flip behind one named opt-in | unit | wiring + CreditPurchaseFlowTests green | ✅ suites exist | ⬜ pending |
| 02-04-T1 | 02-04 | 3 | ENV-01, ENV-02 | T-02-07 | Container-lifetime hypothesis tested (.ips + fixture conversion + targeted runs) | diagnostic | targeted `-only-testing` runs w/o GSD_CI env | ✅ suites exist | ⬜ pending |
| 02-04-T2 | 02-04 | 3 | ENV-01, ENV-02 | T-02-07/08 | Fix-or-disposition applied; no silently disabled suite | checkpoint + suite state | trust grep + full CI-parity run | ✅ (disposition ❌ until written) | ⬜ pending |
| 02-04-T3 | 02-04 | 3 | ENV-01, ENV-02 | T-02-08 | StoreKitServiceTests + EntitlementForegroundCorrection dispositioned | diagnostic | isolation-matrix runs + trust grep | ✅ suites exist | ⬜ pending |
| 02-05-T1 | 02-05 | 4 | BUILD-04 | T-02-09/10 | Canonical CI-parity invocation + INFOPLIST_KEY note | doc verification | grep over AGENTS.md/_test.yml | ✅ files exist | ⬜ pending |
| 02-05-T2 | 02-05 | 4 | BUILD-04 | T-02-09 | docs/TESTING.md pointer-only; no divergence | doc verification | grep + git diff --stat | ✅ file exists | ⬜ pending |
| 02-06-T1 | 02-06 | 5 | DATA-01 | T-02-11 | Factory reset deletes Habit (full store set) | unit (RED→GREEN) | deletion suites -only-testing green | ✅ suites exist | ⬜ pending |
| 02-06-T2 | 02-06 | 5 | DATA-01 | T-02-12 | Evidence note execution-ready with disclosures | doc (manual-apparatus) | file + section greps | ⬜ new this phase | ⬜ pending |
| 02-06-T3 | 02-06 | 5 | DATA-01, DATA-04, BUILD-04, ENV-01, ENV-02, ENV-03 | T-02-13 | Trust gate: full suite green, enumeration, grep mapping | full-suite + xcresulttool | CI-parity full run + `xcresulttool get test-results tests` | ⬜ new this phase | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing XCTest infrastructure covers most needs. New suites (DATA-04 spy suite must run UNGATED — the only existing failure-propagation test is GSD_CI-gated/CI-invisible) + possible container-lifetime fixture migration if ENV-01's hypothesis confirms.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Two-surface CloudKit delete propagation | DATA-01 | Real iCloud account + device + console (see CONTEXT Area 1) | Dated evidence note: delete on device → query-based emptiness on console/second surface after documented propagation wait |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 900s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
