---
phase: "3"
slug: "accessibility-compliance"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-05"
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Filled from 03-01..03-06 PLANs at plan time (2026-09-05).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, primary for new suites) + XCTest (legacy/root suites); both hosted in the app binary (TEST_HOST verified in pbxproj) |
| **Config file** | none — canonical invocation pinned in `AGENTS.md:27-38` and `.github/workflows/_test.yml` |
| **Quick run command** | `TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/ContrastComplianceTests CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 \| tail -5` (swap the `-only-testing:` suite per task) |
| **Full suite command** | the AGENTS.md canonical invocation: `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -derivedDataPath build -skipPackagePluginValidation -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` |
| **Estimated runtime** | ~3-6 min per `-only-testing` run (simulator boot dominated); ~15-25 min full suite (baseline 229 tests / 43 suites) |

---

## Sampling Rate

- **After every task commit:** Run the task's `-only-testing` quick command (or its build/grep gate) from the plan's `<verify>` block
- **After every plan wave:** Full app-scheme build + the touched suites; 03-06 Task 3 additionally runs the full canonical suite and all three scheme builds
- **Before `/gsd-verify-work`:** Full suite green, both grep trust gates recorded against the final tree (03-TRUST-GATE-RECORD.md), 03-A11Y-UAT.md apparatus complete
- **Max feedback latency:** ~6 min (single-suite run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | A11Y-02 | T-03-01 / T-03-02 | N/A (view tokens; no auth surface) | unit (hosted, RED→GREEN + mutation red-proof) | `-only-testing:StressMonitorTests/ContrastComplianceTests` | created by this task (RED-first) | ⬜ pending |
| 3-01-02 | 01 | 1 | A11Y-02 | T-03-02 | N/A | unit + source grep | same suite green + retuned-hex greps | ✅ (after 3-01-01) | ⬜ pending |
| 3-01-03 | 01 | 1 | A11Y-02 | — | N/A | build + grep | app-scheme build + caption-hue grep | ✅ | ⬜ pending |
| 3-02-01 | 02 | 1 | A11Y-04 | T-03-03 | N/A | build + grep | app build + deleted-symbol + cap greps | ✅ | ⬜ pending |
| 3-02-02 | 02 | 1 | A11Y-04 | T-03-03 | N/A | build + grep + measured parity | app build + fixed-size/modifier greps | ✅ | ⬜ pending |
| 3-02-03 | 02 | 1 | A11Y-04 | — | N/A | grep gate (trust-gate shape) + build | 14-file adoption loop (`grep -q … \|\| echo MISSING`) | ✅ | ⬜ pending |
| 3-03-01 | 03 | 2 | A11Y-01 | T-03-04 | N/A | build + adoption enumeration | app build + `minimumTouchTarget(` count + lint | ✅ | ⬜ pending |
| 3-03-02 | 03 | 2 | A11Y-01/A11Y-02 | — | N/A | build + grep | app build + `stressDualCoding` count | ✅ | ⬜ pending |
| 3-03-03 | 03 | 2 | A11Y-01/A11Y-02 | — | N/A | build + triage greps | app build + error-copy/NoDataCard/character-label greps | ✅ | ⬜ pending |
| 3-04-01 | 04 | 2 | A11Y-04 | — | N/A | unit RED proof | `-only-testing:StressMonitorTests/ChartAccessibilityTests` failing-count grep | created by this task (RED-first) | ⬜ pending |
| 3-04-02 | 04 | 2 | A11Y-04 | T-03-05 | labels restate on-screen data only | unit GREEN + build | same suite 5/5 + app build | ✅ (after 3-04-01) | ⬜ pending |
| 3-05-01 | 05 | 3 | A11Y-03 | T-03-06 | DEBUG seam never in Release (`#if DEBUG`, MockIAPMode precedent) | build + grep | app build + transition/seam greps | ✅ | ⬜ pending |
| 3-05-02 | 05 | 3 | A11Y-03 | — | N/A | grep gate (trust-gate shape) + build | RM gate grep (zero raw reads outside helper) + build | ✅ | ⬜ pending |
| 3-05-03 | 05 | 3 | A11Y-03 | T-03-07 | fallback keeps session feedback (haptic+text) | build + copy/haptic greps | app build + fallback-string greps | ✅ | ⬜ pending |
| 3-06-01 | 06 | 4 | A11Y-05 | T-03-09 | extension-member screen prevents breaking live code | record greps | `test -f` + disposition greps on 03-ORPHAN-AUDIT-RECORD.md | created by this task | ⬜ pending |
| 3-06-02 | 06 | 4 | A11Y-05 | T-03-10 | decision recorded before any deletion | record grep | decision-entry grep on the audit record | ✅ (after 3-06-01) | ⬜ pending |
| 3-06-03 | 06 | 4 | A11Y-05 + all | T-03-08 | dead code out of all three binaries | 3-scheme clean builds + both gate greps + full suite | build x3 + adoption/RM gate loops + canonical full suite | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `StressMonitor/StressMonitorTests/ContrastComplianceTests.swift` — created RED-first by 3-01-01 (covers A11Y-02; manual 4-point pbxproj registration, A026/B026 precedent)
- [x] `StressMonitor/StressMonitorTests/ChartAccessibilityTests.swift` — created RED-first by 3-04-01 (covers the A11Y-04 chart-series copy contract; same registration pattern)
- [x] No framework install needed — infra exists (hosted Swift Testing target, canonical invocation pinned in AGENTS.md)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hit areas ≥44pt rendered truth per surface | A11Y-01 | hit-area geometry is a rendered-tree property; no unit seam | Accessibility Inspector scan per the 14 surface rows in 03-A11Y-UAT.md, checked against 03-03-SUMMARY's enumeration |
| Zero truncation/overlap at AX5, light+dark | A11Y-04 (D-08/D-10 layer 2) | layout-at-AX5 is a rendered property; `simctl ui content_size` sets it but only eyes/screenshots judge | Per-surface rows in 03-A11Y-UAT.md: set AX5, screenshot both appearances, verify wrap/stack/scroll, reset to large |
| Reduce Motion behavior on device | A11Y-03 | no `simctl` toggle exists on Xcode 26.3; env value is read-only | Settings → Accessibility → Motion → Reduce Motion ON (or the `-a11y-reduce-motion` DEBUG launch arg), walk manifest surfaces; breathing fallback walkthrough row |
| Dual-coding legibility judgment (hue+symbol+name) | A11Y-02 | final visual judgment per surface | Per-surface rows in 03-A11Y-UAT.md |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (both Wave-0 files are created RED-first by their own plan's first task)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no pre-existing-file references; both new suites self-created red-first)
- [x] No watch-mode flags
- [x] Feedback latency < 6 min per task commit (quick runs); full-suite latency bounded by test_gate_timeout 3600
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (set by validate-phase or first executor run)
