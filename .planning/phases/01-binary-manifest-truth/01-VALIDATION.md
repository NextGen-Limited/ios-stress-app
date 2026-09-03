---
phase: 1
slug: binary-manifest-truth
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-03
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing — see 01-RESEARCH.md ## Validation Architecture) |
| **Config file** | StressMonitor/StressMonitor.xcodeproj schemes (StressMonitor, StressMonitorWatch Watch App) |
| **Quick run command** | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO -only-testing:StressMonitorTests/<suite>` |
| **Full suite command** | `python3 scripts/run-tests.py` (finds/boots simulator, passes UUID, results in StressMonitor/build/) |
| **Estimated runtime** | ~300–900 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick suite for touched target
- **After every plan wave:** Run full suite (`python3 scripts/run-tests.py`)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 900 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD at plan time | — | — | BUILD-01..03, AUTH-01, WIRE-01, ENV-04, ENV-05 | — | see RESEARCH ## Validation Architecture | mixed | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers most phase requirements (XCTest suites, pinning tests for App Group suite). Archive/CI-level criteria (BUILD-01 ASC upload, ENV-05 match readonly) are verified via pipeline runs — see RESEARCH.md.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Widget shows same score as app after refresh | WIRE-01 | Physical device / simulator gallery interaction | See 01-CONTEXT.md WIRE-01 verification decision (device first; simulator + documented human UAT fallback) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 900s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
