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
| TBD at plan time | — | — | DATA-01, DATA-04, BUILD-04, ENV-01, ENV-02, ENV-03 | — | see RESEARCH ## Validation Architecture | mixed | TBD | TBD | ⬜ pending |

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
