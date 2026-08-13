---
phase: 1
slug: firebase-auth-api-client-chat-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-13
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) + XCTest |
| **Config file** | `StressMonitor/StressMonitor.xcodeproj` (scheme: `StressMonitor`) |
| **Quick run command** | `xcodebuild test -scheme StressMonitor -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:StressMonitorTests` |
| **Full suite command** | `xcodebuild test -scheme StressMonitor -destination "platform=iOS Simulator,name=iPhone 16"` |
| **Estimated runtime** | ~60 seconds (unit only); ~120 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme StressMonitor -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:StressMonitorTests`
- **After every plan wave:** Run full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01 | 1 | D-05, D-07 | T-01-01 | SSE metadata parsed; 402 mapped to error | unit (TDD) | `xcodebuild test -only-testing:StressMonitorTests/SSEParserTests` | ❌ W0 | ⬜ pending |
| 01-01-T2 | 01 | 1 | D-01, D-03 | T-01-02 | Firebase SDK links; config resolves | build | `xcodebuild build -scheme StressMonitor` | ✅ | ⬜ pending |
| 01-01-T3 | 01 | 1 | D-02, D-06 | T-01-03 | Chat streams via new backend end-to-end | integration | manual: launch app, send chat message, verify SSE tokens appear | ✅ | ⬜ pending |
| 01-02-T1 | 02 | 2 | D-02 | T-02-01 | Google Sign-In credential links anonymous account | build | `xcodebuild build -scheme StressMonitor` | ✅ | ⬜ pending |
| 01-02-T2 | 02 | 2 | D-04 | — | No "Supabase" string remains in source | static | `grep -rn 'Supabase' StressMonitor/StressMonitor/ --include='*.swift' \| wc -l` = 0 | ✅ | ⬜ pending |
| 01-03-T1 | 03 | 3 | D-03, D-07 | — | StressAPIConfig + StressAPIClient unit tests pass | unit (TDD) | `xcodebuild test -only-testing:StressMonitorTests/StressAPIConfigTests` | ❌ W0 | ⬜ pending |
| 01-03-T2 | 03 | 3 | D-03 | — | FirebaseAuthService unit tests pass | unit (TDD) | `xcodebuild test -only-testing:StressMonitorTests/FirebaseAuthServiceTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `StressMonitorTests/StressAPIConfigTests.swift` — stubs for 3-tier config resolution (D-03)
- [ ] `StressMonitorTests/StressAPIClientTests.swift` — stubs for request construction, Bearer header, 402 error mapping (D-07)
- [ ] `StressMonitorTests/FirebaseAuthServiceTests.swift` — stubs for token retrieval + refresh (D-01)
- [ ] `StressMonitorTests/SSEParserTests.swift` — stubs for terminal metadata event + quick_actions field (D-05)

*Note: Wave 0 test stubs are created by Plan 03 (TDD tasks). Plans 01 and 02 carry build/manual verification in the interim — sampling continuity holds because Wave 1 has 3 automated-or-build checks and Wave 2 has 2.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Chat streams SSE tokens from live backend | D-06 | Requires Firebase auth + live backend + simulator UI | Launch app on simulator → open Chat → send message → verify streaming tokens appear in ChatView |
| Google Sign-In presents OAuth flow | D-02 | Requires Google Sign-In UI entry point + simulator | (If UI button added) Settings → Sign in with Google → verify OAuth sheet presents |
| `GoogleService-Info.plist` present | D-01 | File is gitignored, user-provided | `ls StressMonitor/StressMonitor/GoogleService-Info.plist` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (Plan 03 creates test stubs)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter (set after execution)

**Approval:** pending
