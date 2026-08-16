---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Backend API Migration
current_phase: 2
current_phase_name: Credits System + IAP Transition
status: planning
stopped_at: context exhaustion at 79% (2026-08-13)
last_updated: "2026-08-16T10:51:51.431Z"
last_activity: 2026-08-16
last_activity_desc: Phase 01 execution started
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 4
  completed_plans: 4
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-16 after v1.1 Phase 01 close)

**Core value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Current focus:** Phase 2 — Credits System + IAP Transition

## Current Position

Phase: 2 — Credits System + IAP Transition
Plan: Not started
Status: Ready to plan
Last activity: 2026-08-16 — Phase 01 complete, transitioned to Phase 2

## Performance Metrics

**Velocity:**

- Total plans completed: 5
- Average duration: - min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01.1 | 1 | - | - |
| 01 | 4 | - | - |

**Recent Trend:**

- Last 5 plans: none yet
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P05 | 3m | 2 tasks | 2 files |
| Phase 02 P01 | 45min | 3 tasks | 8 files |
| Phase 04 P01 | ~26 min | 3 tasks | 16 files |
| Phase 05 P01 | ~11 min | 6 tasks | 19 files |
| Phase 01 P01 | 42m | 3 tasks | 12 files |
| Phase 01 P03 | 32m | 2 tasks | 6 files |

## Accumulated Context

### Decisions

Full v1.0 decision log archived in PROJECT.md Key Decisions table (see "v1.0 Verification Reality Check" for close-time evolution). Cleared here at milestone close per `/gsd-complete-milestone`'s `update_state` step — start fresh for v1.1.

- [Phase 01]: Firebase 11.x API: forcingRefresh label, non-optional expirationDate, FirebaseApp.configure() entry point (verified against resolved SDK)
- [Phase 01]: Added firebase-ios-sdk via standard XCRemoteSwiftPackageReference (existing spm-cache umbrella is unlinked)
- [Phase 01]: Proceeded with Task 2/3 code despite backend /health 404 (deployment down); code+build are backend-independent, end-to-end verify surfaced as checkpoint
- [Phase 01]: mapHTTPError lives on StressLLMService (streaming consumer owning error contract), exposed internal for 402 mapping tests
- [Phase 01]: Task 2 required no production changes - FirebaseAuthService.init was already lazy from Plan 01-01; tests pin the contract
- [Phase 01, closed 2026-08-16]: D1 resolved by execution — real Firebase auth shipped (Anonymous + Google linking), chat ungated, UAT-verified
- [Phase 01, 2026-08-16]: xcodebuild test works with `-parallel-testing-enabled NO` (parallel clones fail: XCTestDevices/Mach -308) — pin this flag in CI/dev docs
- [Phase 01, 2026-08-16]: AccountViewModel/SettingsView Google row pattern established: ViewModel wraps service state, rethrows errors, silent on GIDSignIn code -5 cancellation

### Pending Todos

None yet.

### Blockers/Concerns

Carried into v1.1 (still open at v1.0 close — see PROJECT.md Active requirements for the requirements they gate):

- **D1 (Auth strategy)** — RESOLVED 2026-08-16: real Firebase auth shipped in Phase 01 (Anonymous + Google linking), chat ungated, UAT-verified.
- **D2 (CloudKit encryption)** — Resolved in practice (encryptedValues implemented, verified in v1.0 Phase 2) but never formally closed as a decision record.
- **D3 (Privacy contract authority)** — Root `CLAUDE.md`'s "HealthKit never sent" claim vs. `StressContextPayload.swift`'s actual behavior (derived scores only — mitigated T-01-02). Still gates BUILD-01/SHIP-03.
- **D4 (Widget in v1)** — Ship the widget or exclude the target. Still gates WIRE-01.
- Pre-existing Release-build compile blocker (new, found at v1.0 close): `StoreKitServiceEnvironment.swift:12` references `MockStoreKitService` unconditionally outside `#if DEBUG`.
- ~~Host CoreSimulator cannot complete `xcodebuild test`~~ — PARTIALLY RESOLVED 2026-08-16: full suite runs green with `-parallel-testing-enabled NO`; only parallel clones fail. Pin the flag in CI.
- `CharacterEntitlementSyncTests` remains quarantined (`@Suite(.disabled(...))`) — root cause not diagnosed after 5 ruled-out hypotheses; no dedicated coverage for `syncPremiumCharacterEntitlement` until resolved on a working simulator.
- [Phase 01 → Phase 2] REVIEW CR-01: data race + stale context on `StressLLMService.currentStressContext`; CR-02: trend direction inverted (recentHistory newest-first). Both advisory-open — fold into Phase 2 planning or `$gsd-code-review 01 --fix`.
- [Phase 01 → Phase 2] 27+ commits on `main` unpushed (no milestone branch). Decide branch strategy + push before starting Phase 2.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260811-t0l | Fix CI failure in .github/workflows/_test.yml: resolve iPhone Simulator UDID dynamically instead of hardcoding name=iPhone 16 | 2026-08-11 | 7864b95 | [260811-t0l-fix-ci-failure-in-github-workflows-test-](./quick/260811-t0l-fix-ci-failure-in-github-workflows-test-/) |

## Deferred Items

Items acknowledged and deferred at v1.0 milestone close on 2026-08-12:

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 01.1 — 01.1-UAT.md | passed (0 pending scenarios) |
| uat_gap | Phase 02 — 02-UAT.md | testing (3 pending scenarios: two-device CloudKit sync, DataDeletionConsolidationTests execution, CR-01 regression test) |
| verification_gap | Phase 01 — 01-VERIFICATION.md | gaps_found |
| verification_gap | Phase 02 — 02-VERIFICATION.md | human_needed (4/7 must-haves verified) |
| deferred_item | Phase 03 — StoreKitServiceEnvironment.swift:12 references MockStoreKitService unconditionally, but it is #if DEBUG-only; every Release build fails to compile | open (pre-existing, not caused by Phase 3; blocks AUTH-01's local Release strings gate) |

## Session Continuity

Last session: 2026-08-16
Stopped at: Phase 01 complete (UAT 2/2, SECURITY threats_open 0), ready to plan Phase 2 — Credits System + IAP Transition
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
