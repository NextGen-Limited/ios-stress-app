---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Backend API Migration
status: "No active milestone — v1.1 closed 2026-08-24 (verified_closeout, tag v1.1); Phase 03 post-merge drift re-test in flight (started 2026-08-30)"
stopped_at: Awaiting user execution of Phase 03 post-merge drift re-test scenarios (.planning/phases/03-*/03-UAT.md); then /gsd-new-milestone (v1.2 submission readiness recommended)
last_updated: "2026-09-01T15:10:00Z"
last_activity: 2026-09-01
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 17
  completed_plans: 17
  percent: 100
current_phase: 3
current_phase_name: Sessions, Preferences, Quick Actions + Cleanup
last_activity_desc: Milestone v1.1 completed and archived
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-23 after v1.1 Phase 03 close — milestone complete)

**Core value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Current focus:** Post-merge drift re-test of Phase 03 UAT (5 scenarios pending), then /gsd-new-milestone — v1.2 submission readiness recommended per v1.1 audit

## Current Position

Phase: Post-milestone — Phase 03 drift re-test
Plan: —
Status: v1.1 closed & tagged (PR #48 squash-merged, CI 6/6); drift re-test awaiting user scenarios
Last activity: 2026-09-01

## Performance Metrics

**Velocity:**

- Total plans completed: 18
- Average duration: - min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01.1 | 1 | - | - |
| 01 | 4 | - | - |
| 2 | 8 | - | - |
| 3 | 5 | - | - |

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
| Phase 02 P02 | ~75min | 5 tasks | 17 files |
| Phase 02 P06 | 10min | 2 tasks | 6 files |
| Phase 02 P07 | 21min | 3 tasks | 9 files |
| Phase 02 P08 | 18min | 3 tasks | 6 files |
| Phase 03 P01 | 2448s | 2 tasks | 11 files |
| Phase 03 P02 | 14min | 3 tasks | 10 files |
| Phase 03 P03 | 14min | 2 tasks | 9 files |
| Phase 03 P04 | 22min | 3 tasks | 9 files |
| Phase 03 P05 | 28min | 3 tasks | 1 files |

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
- [Phase 02]: Backend IAP: @apple/app-store-server-library@3.1.0 user-verified; Apple Root CA G2+G3 embedded; premium endpoint pinned as POST /credits/premium/verify
- [Phase 02]: Grant idempotency keyed on iap_redemptions PK shared by packs and subscriptions; premium_until = greatest(existing, expiry), demoted by monthly cron before free reset
- [Phase 02]: Purchased credits live in purchased_credits (CHECK >= 0); total_credits is the immutable free allotment; API contract preserved via derived-total SQL alias — routes and iOS decode unchanged
- [Phase 02]: Credit consumption is free-first (used_credits pins at total, purchased drains the overflow); monthly reset restores used_credits only — CR-01 closed and pinned by cron test
- [Phase 02]: Revocation policy applied as rejectingRevoked verifier wrapper at the creditsRoutes factory — one seam covers both credit endpoints including injected test verifiers; decode-level throw stays defense-in-depth (02-07)
- [Phase 02]: Effective premium = plan_type AND (premium_until IS NULL OR > now()) enforced at deductCredit (SQL-derived under FOR UPDATE) and the chat 402 gate; cron demoted to janitor; balanceJson unchanged (02-07)
- [Phase 02]: iOS completePurchase evaluates the revocation/expiry guard BEFORE syncSubscriptionEntitlementToServer — revoked/expired JWS never posted, never granted, still finished (02-07)
- [Phase ?]: Refund handling split per route: /credits/premium/verify treats a revoked subscription JWS as a demotion signal (guarded least() UPDATE, convergent on re-post, never an iap_redemptions insert); /credits/redeem keeps absolute revoked rejection (02-08)
- [Phase ?]: No clawback of already-granted pack credits on refund — iOS finishes a revoked pack with zero redemption attempts on both entry points; the fix's contract is queue hygiene, not clawback (WR-10, 02-08)
- [Phase ?]: Replay-window guard on demotion: premium_until <= revoked.expiresAt — an old revocation cannot shorten a newer term granted by a later transaction (02-08)
- [Phase ?]: Phase 3: query-carrying API endpoints must build URLs via URLComponents + authorizedRequest(url:) — appendingPathComponent percent-encodes '?'; pinned by exact-URL assertions
- [Phase ?]: Phase 3: session creation fail-soft inside StressLLMService.send (try? createSession before sendChat); 404 restore -> resetSession clears stressChatSessionId
- [Phase ?]: PreferencesServiceProtocol not needed: same-module consumers + URLProtocol-injected concrete StressAPIClient in tests
- [Phase ?]: Preferences update success keeps the optimistic value (server persisted exactly it); revert only on throw — no response re-mapping
- [Phase ?]: CR-02 closed: StressContextPayload trend computed chronologically from newest-first history, pinned by 4 regression cases
- [Phase ?]: AI Coach pickers closed to backend vocabulary (en/vi; supportive/direct/educational); value text labeled from state so out-of-set server values still display
- [Phase ?]: Server chip ids resolve prompts on-device via a verbatim backend-table mirror (ChatQuickActions.prompt) — server chooses among 7 known prompts, never injects prompt text (T-3-10)
- [Phase ?]: 03-03 chips: instant local fallback at init, one guarded GET per presentation, failure keeps fallback — no loading/empty state; +QuickActions extension structurally GET-only (revenue-bypass guard)
- [Phase ?]: 03-04: factory-reset server wipe — auth-unavailable (LLMServiceError.unavailable / SessionsAPIError.unauthorized 401) skips with log; every other wipe error fails the reset loudly via DeletionError.serverSessionError (CloudKit precedent)
- [Phase ?]: 03-04: in-memory ModelContainer must outlive its mainContext in tests — return-context-only fixtures are the WINDOWS.md #8 crash lineage; suite fixtures return (ModelContainer, ModelContext)
- [Phase ?]: 03-05 gate: full-suite exit 65 classified as accepted WINDOWS.md #8 lineage (209/6/15/230, 0 assertion failures, same family+count as 03-03) — not a new failure
- [Phase ?]: 03-05 GAP-1 (ledger #12): ChatHistoryRestoreTests leaks static responseByPath['/preferences']; preferences suites get stale vi/direct because responseByPath outranks single-response statics — masked in full-suite by #8 restarts between polluter and victims; fix = per-test reset of RequestCaptureURLProtocol statics

### Pending Todos

None yet.

### Blockers/Concerns

Carried into v1.1 (still open at v1.0 close — see PROJECT.md Active requirements for the requirements they gate):

- **D1 (Auth strategy)** — RESOLVED 2026-08-16: real Firebase auth shipped in Phase 01 (Anonymous + Google linking), chat ungated, UAT-verified.
- **D2 (CloudKit encryption)** — Resolved in practice (encryptedValues implemented, verified in v1.0 Phase 2) but never formally closed as a decision record.
- **D3 (Privacy contract authority)** — Root `CLAUDE.md`'s "HealthKit never sent" claim vs. `StressContextPayload.swift`'s actual behavior (derived scores only — mitigated T-01-02). Still gates BUILD-01/SHIP-03.
- **D4 (Widget in v1)** — Ship the widget or exclude the target. Still gates WIRE-01.
- ~~Pre-existing Release-build compile blocker: `StoreKitServiceEnvironment.swift:12` references `MockStoreKitService` unconditionally~~ — RESOLVED in v1.1 Phase 2: `xcodebuild build -configuration Release` exit 0, re-verified 2026-08-17 (BUILD-05 validated).
- ~~Host CoreSimulator cannot complete `xcodebuild test`~~ — PARTIALLY RESOLVED 2026-08-16: full suite runs green with `-parallel-testing-enabled NO`; only parallel clones fail. Pin the flag in CI.
- `CharacterEntitlementSyncTests` remains quarantined (`@Suite(.disabled(...))`) — root cause not diagnosed after 5 ruled-out hypotheses; no dedicated coverage for `syncPremiumCharacterEntitlement` until resolved on a working simulator.
- ~~[Phase 01] REVIEW CR-01: data race + stale context on `StressLLMService.currentStressContext`~~ — CLOSED in v1.1 Phase 2 (stress context flows through `send()`; static side-channel deleted; verification truth 4).
- [Phase 01 → Phase 3] REVIEW CR-02: trend direction inverted in `StressContextPayload.build` (recentHistory newest-first) — DEFERRED to Phase 3 by 02-01 explicit_deferrals; the fix belongs with Phase 3's session/history work that constructs recentHistory inputs. Self-contained one-function fix with an obvious test.
- [Branch] Milestone branch `gsd/v1.1-backend-api-migration` active (strategy resolved); 51 commits ahead of `origin/main`, branch not pushed — decide push timing before milestone close.
- [Phase 2 residue] Advisory review findings WR-02..04/06..09, IN-01..08 recorded in 02-REVIEW.md — none phase must-haves; WR-03 (DEBUG money path uses MockStoreKitService) and WR-04 (`.unverified` consumables finished) are the money-path-relevant ones to consider in later work.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260811-t0l | Fix CI failure in .github/workflows/_test.yml: resolve iPhone Simulator UDID dynamically instead of hardcoding name=iPhone 16 | 2026-08-11 | 7864b95 | [260811-t0l-fix-ci-failure-in-github-workflows-test-](./quick/260811-t0l-fix-ci-failure-in-github-workflows-test-/) |
| 260829-kby | Firebase bootstrap state + AuthServiceError taxonomy (CI provisioning deferred) | 2026-08-29 | 6227803 | [260829-kby-provision-googleservice-info-plist-in-ci](./quick/260829-kby-provision-googleservice-info-plist-in-ci/) |

## Deferred Items

Items acknowledged and deferred at v1.0 milestone close on 2026-08-12:

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 01.1 — 01.1-UAT.md | passed (0 pending scenarios) |
| uat_gap | Phase 02 — 02-UAT.md | testing (3 pending scenarios: two-device CloudKit sync, DataDeletionConsolidationTests execution, CR-01 regression test) |
| verification_gap | Phase 01 — 01-VERIFICATION.md | gaps_found |
| verification_gap | Phase 02 — 02-VERIFICATION.md | human_needed (4/7 must-haves verified) |
| deferred_item | Phase 03 — StoreKitServiceEnvironment.swift:12 references MockStoreKitService unconditionally, but it is #if DEBUG-only; every Release build fails to compile | open (pre-existing, not caused by Phase 3; blocks AUTH-01's local Release strings gate) |

Items acknowledged and deferred at v1.1 milestone close on 2026-08-23: none — the sole audit-open item (google-signin-ui-entry-missing) was verified already resolved by gap-closure plan 01-04 (UI shipped + human-verified 2026-08-16); debug session marked resolved at close.

## Session Continuity

Last session: 2026-09-01T15:10:00Z
Stopped at: v1.1 lifecycle complete (audit → archive → tag). Open: Phase 03 post-merge drift re-test (.planning/phases/03-*/03-UAT.md) awaiting user execution
Resume file: None

## Operator Next Steps

- Finish the Phase 03 post-merge drift re-test (.planning/phases/03-*/03-UAT.md — 5 scenarios, health precheck confirmed green 2026-08-30)
- Start the next milestone with /gsd-new-milestone (v1.2 submission readiness recommended)
