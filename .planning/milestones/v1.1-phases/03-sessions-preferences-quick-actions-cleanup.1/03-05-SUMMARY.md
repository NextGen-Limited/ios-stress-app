---
phase: 03-sessions-preferences-quick-actions-cleanup
plan: 05
subsystem: testing
tags: [integration-gate, postgres, deno, xcodebuild, uat, release-build, coverage-seal]

# Dependency graph
requires:
  - phase: 03-sessions-preferences-quick-actions-cleanup (plans 01-04)
    provides: all Phase 3 source + test seams being gated (+Sessions/+Preferences/+QuickActions, PreferencesService, restore/chips wiring, DataDeleter wipe, cleanup edits)
provides:
  - 03-UAT.md — five pending live-backend scenarios (history restore, prefs round-trip, chip fetch, 402→paywall, factory-reset server wipe) + token-extraction appendix
  - Gate evidence record: backend suite green on a recreated local 5433 postgres, full-suite counts, Release build exit 0, orphan/remnant/revenue/quarantine gate outputs, #8 classification
  - Recreated local test postgres (127.0.0.1:5433, datadir /tmp/stress-pg-0206, 8 migrations) — left running for reuse
  - Named gap GAP-1 (order-dependent URLProtocol stub pollution) with owning seam + WINDOWS.md ledger entry 12
affects: [v1.1-close, gsd-verify-work, ship gate]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 2700
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate-leg evidence format: exact command + exit code + counts per leg, with failing legs classified against the accepted WINDOWS.md signature before verdict"
    - "Recreate-then-migrate environment recovery: gutted /tmp datadir → fresh initdb → repo's own `deno task migrate` (8/8) — no remote DB ever touched"

key-files:
  created:
    - .planning/phases/03-sessions-preferences-quick-actions-cleanup/03-UAT.md
  modified: []

key-decisions:
  - "Full-suite exit 65 classified as the accepted WINDOWS.md #8 lineage, not a new failure: 6 host-crash restarts all clustered on the pre-existing DataDeletion family, zero assertion failures, and the xcresult shape (6 failed / 15 skipped) is byte-equivalent to 03-03's accepted record with passed grown 203→209 by 03-04's additions"
  - "Orphan-sweep command corrected (deviation): the plan's literal grep for `/* X.swift */` never matches Sources-phase entries (`/* X.swift in Sources */`) and its -A300 window excludes the PBXFileReference lines — corrected sweep scoped to the actual phase block; criterion unchanged (0 orphans)"
  - "Factory-reset UAT scenario verifies server-side emptiness with the PRE-reset token (a post-reset new anonymous uid would read trivially empty) — the plan's intent, made strict"
  - "Order-dependent stub pollution recorded as GAP-1 + ledger entry 12 rather than patched: this plan writes no source/test code (plan prohibition), and the fix belongs to the owning seam (RequestCaptureURLProtocol reset) as a gap-closure decision"

patterns-established:
  - "Pattern: crash-masking analysis — when a suite subset fails where the full suite passed, check whether test-host restarts sat between polluter and victim before calling it flaky"

requirements-completed: [derived-CLEAN-01, AUTH-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Integration gate matrix executed with recorded evidence: backend deno suite green on recreated local 5433 postgres (29 tests / 100 steps, exit 0), full iOS suite with accepted #8 signature (209/6/15/230, zero assertion failures, all Phase-3 + AUTH-03 fence suites green in-run), Release build exit 0, orphan 0/34, remnant 0/0 + 2 KEEP sites, revenue single-GET, quarantine intact"
    requirement: AUTH-03
    verification:
      - kind: integration
        ref: "DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/stress_app deno test --allow-env --allow-net --allow-read src/ → ok | 29 passed (100 steps) | 0 failed, exit 0"
        status: pass
      - kind: unit
        ref: "xcodebuild test … -parallel-testing-enabled NO → xcresult 209 passed / 6 failed (#8 family, 0 assertion failures) / 15 skipped; xcodebuild build -configuration Release → BUILD SUCCEEDED exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "03-UAT.md authored — five executable live-backend scenarios with preconditions, numbered steps, expected results, server-side checks, and pass/fail column; all marked pending"
    requirement: derived-CLEAN-01
    verification:
      - kind: manual_procedural
        ref: "grep -c scenario-completeness pattern over 03-UAT.md → 13; 11 [pending] markers; GET /health → 200 re-checked before handover"
        status: pass
    human_judgment: true
    rationale: "The five scenarios are by design the end-of-phase human verification (human_verify_mode: end-of-phase); this plan authors, does not execute them"

# Metrics
duration: 28min
completed: 2026-08-23
status: complete
---

# Phase 3 Plan 5: Milestone Integration Gate Summary

**Full v1.1 integration matrix green — backend 29 tests/100 steps on a recreated 5433 postgres, iOS full suite 209 passed with only the accepted WINDOWS.md #8 crash-family failures, Release build exit 0, every grep gate clean — plus the five-scenario live-backend 03-UAT.md, and one named gap: order-dependent URLProtocol stub pollution unmasked by a crash-free suite ordering (ledger #12)**

## Performance

- **Duration:** ~28 min (10:58–11:27 UTC)
- **Started:** 2026-08-23T10:58:58Z
- **Completed:** 2026-08-23T11:27:00Z
- **Tasks:** 3
- **Files created:** 1 (03-UAT.md); everything else is command evidence below

## Gate Evidence Record

### Task 1 — Local postgres + backend deno suite

**Precheck:** `pg_isready -h 127.0.0.1 -p 5433` → `no response`, exit 2 (down as expected).

**Restart provenance — recreation was required.** The datadir at `/tmp/stress-pg-0206` was gutted by macOS's periodic /tmp cleanup: every directory survived but **zero files remained** (`find /tmp/stress-pg-0206 -type f | wc -l` → 0; `du -sh` → 0B; `PG_VERSION` and `postgresql.conf` gone; dir mtimes 2026-08-22 00:00 marking the purge). Unrecoverable → executed the plan's recorded contingency:

1. `rm -rf /tmp/stress-pg-0206 && mkdir -p /tmp/stress-pg-0206` (empty husks only; 0 files lost)
2. `/opt/homebrew/opt/postgresql@15/bin/initdb -D /tmp/stress-pg-0206/data -U postgres --auth=trust --encoding=UTF8`
3. `postgresql.conf` += `port = 5433`, `listen_addresses = '127.0.0.1'`
4. `pg_ctl -D …/data -l /tmp/stress-pg-0206/pg.log -w start` → server started
5. `pg_isready -h 127.0.0.1 -p 5433` → **accepting connections, exit 0**
6. `createdb -h 127.0.0.1 -p 5433 -U postgres stress_app`
7. `DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/stress_app deno task migrate` (repo's own migrator) → applied exactly the 8 migrations in order: `20260812000001_enums_and_helpers`, `20260812000002_users`, `20260812000003_user_preferences`, `20260812000004_chat_tables`, `20260812000005_credit_system`, `20260816120000_redeem`, `20260816120100_premium_until`, `20260817120000_purchased_credits`
8. Schema verified via psql: `schema_migrations` = **8 rows**; public tables = `chat_messages, chat_sessions, credit_transactions, iap_redemptions, schema_migrations, user_credits, user_preferences, users` (chat + user_preferences present per the plan's requirement)

**Backend suite:** `cd /Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be && DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/stress_app deno test --allow-env --allow-net --allow-read src/` → **`ok | 29 passed (100 steps) | 0 failed`**, **exit 0**. vs the Phase-2 close baseline 17/50: the suite has grown in the backend repo (its own route/lib suites) — **29 ≥ 17** as required. No DATABASE_URL other than local `127.0.0.1:5433` was used at any point. Instance left running for reuse.

### Task 2 — Full iOS suite + Release build + coverage/orphan/remnant/revenue/quarantine gates

**Leg 1 — Full suite** (canonical command, from repo root):
`xcodebuild test -scheme StressMonitor -project StressMonitor/StressMonitor.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO`
→ **exit 65**, classified as the **accepted WINDOWS.md #8 lineage** — not a new failure:

- xcresult summary: **209 passed / 6 failed / 15 skipped / 230 total**
- Swift Testing: **118 tests in 21 suites passed** (0.746s); XCTest: **28 tests / 2 suites** passed (BioAgeCalculatorTests 21, StressContextPayloadTests 7)
- **Zero assertion failures** (no ✘ test lines in the Swift Testing body; no XCTest failure lines)
- **6 cold-launch host restarts**, all clustered on the pre-existing DataDeletion family (log-verified contexts: CloudKit cancellation ×2, CloudKitResetError mapping, scoped deleteMeasurements cancellation, CSV export, JSON export)
- The 6 failed tests: `deleteAllMeasurements surfaces a CloudKitResetError…`, `cancelling after CloudKit deletion has started…`, `cancelling before CloudKit deletion starts…`, `scoped deleteMeasurements… cancelled mid-flight`, `CSV export omits fields whose toggle is disabled`, `JSON export includes a baseline section…` — every one inside `DataDeletionConsolidationTests.swift`'s suites (untouched by Phase 3), all host crashes
- Signature equivalence to the accepted record: 03-03 closed with **203 passed / 6 failed / 15 skipped** with the identical failure set shape; passed grew 203→209 exactly by 03-04's additions (5 wipe tests + 1 consolidation case). 02-01/02-03/02-04/03-01 accepted the same signature. Same suites, same crash mechanism (SwiftData host trap), same count — **no new-failure signature**
- **Every Phase-3 suite green in-run**: StressAPIClientSessionsTests, ChatHistoryRestoreTests, StressAPIClientPreferencesTests, PreferencesServiceTests, StressAPIClientQuickActionsTests, DataDeleterServerWipeTests (`Suite "Data Deleter Server Session Wipe" passed after 0.086 seconds`), extended StressContextPayloadTests (7/7), extended consolidation cases (DeleteAllCredentialClearanceTests not among failures)
- **AUTH-03 regression closed in-run**: ChatLifecycleTests, SSEParserTests, PaywallOutOfCreditsGuardTests, CreditPurchaseFlowTests all in the passed set
- 15 skipped = the two quarantined suites only (see Leg 6)

**Leg 2 — Release build:**
`xcodebuild build -scheme StressMonitor -project StressMonitor/StressMonitor.xcodeproj -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17'` → **BUILD SUCCEEDED, exit 0** (BUILD-05 bar held under Phase 3 changes).

**Leg 3 — Orphan sweep:** every `StressMonitorTests/*.swift` appears in Sources phase `3828578ADDAD4AC5925394DB` → **0 orphans across 34 files / 34 in-Sources entries** (via the corrected command — see Deviation 1).

**Leg 4 — Remnant gate:** `grep -c -i supabase .gitignore design/screens/25-about.html` → **0 / 0**; app-source file-level sweep `grep -rli supabase StressMonitor StressMonitorTests` → **exactly 2 files** (the KEEP sites: `FirebaseAuthService.swift`, `DataDeletionConsolidationTests.swift`).

**Leg 5 — Revenue gate:** `StressAPIClient+QuickActions.swift`: `authorizedRequest` count **1**, `"POST"` count **0**, `method: "GET"` count **1**; `grep -rn '"quick-actions"' StressMonitor/StressMonitor --include='*.swift'` → single hit at the GET path construction (`StressAPIClient+QuickActions.swift:44: url: baseURL.appendingPathComponent("quick-actions")`). Single-GET confirmed; the unmetered POST route remains unwired.

**Leg 6 — Quarantine check:** `CharacterEntitlementSyncTests` carries `@Suite(.disabled("Reliable test-host hang on this toolchain — see file header"))` (line 27) and appears in the run log as `skipped: "Reliable test-host hang…"`; `EntitlementForegroundCorrectionTests` likewise skipped with its IAP-01 reason. Still excluded with reason — not silently re-enabled.

**Extra probe (not a plan gate leg) — targeted 10-suite fence run** (ChatLifecycle/SSEParser/PaywallOutOfCreditsGuard/CreditPurchaseFlow/ChatHistoryRestore + the three API-client suites + StressAPIClientTests + StressContextPayloadTests): **FAILED, exit 65, 10 assertion failures** (7 in PreferencesServiceTests, 3 in StressAPIClientPreferencesTests) → this is **GAP-1**, recorded below, not a regression of the gate: the same suites all passed inside the full-suite run minutes earlier.

### Task 3 — 03-UAT.md authored

Five pending scenarios (history restore w/ single-titled-session + no-duplication assertions; prefs round-trip vi/direct with server-side GET /preferences check and restore-to-defaults; chip fetch instant-fallback→server-swap with metered-tap assertion; 402→paywall AUTH-03 regression; factory-reset server wipe verified with the **pre-reset token** so a fresh anonymous uid cannot fake emptiness). Includes the `GET /health` → 200 precheck (re-checked → **200** before handover) and a curl-free verification appendix (token via proxy capture or Xcode debugger; any HTTP client). Verify grep → **13**; 11 `[pending]` markers, none pre-marked passed. Commit `a512dcd`.

## Named Gaps (for orchestrator triage)

**GAP-1 — Order-dependent URLProtocol stub pollution (WINDOWS.md ledger #12, open).**
- **Found during:** Task 2 extra probe (crash-free targeted run)
- **Mechanism:** `ChatHistoryRestoreTests` sets static `RequestCaptureURLProtocol.responseByPath` including a `/preferences → 200 vi/direct` entry and never clears it; `responseByPath` takes precedence over the single-response statics (`StressAPIClientTests.swift:80-81`), so suites that stub via `statusCode`/`responseBody` (`PreferencesServiceTests`, `StressAPIClientPreferencesTests`) receive the stale success response — their 400/401 fixtures never fire and seeded-state assertions see vi/direct instead of their fixtures
- **Why the full suite passes anyway:** log-line proof — `◇ Suite ChatHistoryRestoreTests started` at line 1102 (launch 1), the **6 crash-restarts** at lines 1289–1374, then `PreferencesServiceTests` (1883) / `StressAPIClientPreferencesTests` (2006) run in a **later launch** with fresh process state. The #8 crash cycle currently masks the pollution; suite greenness depends on that coincidence
- **Candidate fix (owning seam):** per-test reset of `RequestCaptureURLProtocol` statics (clear `responseByPath`/`capturedRequests` in a teardown), or reset in `ChatHistoryRestoreTests.makeStubbedClient` teardown — a test-only change in `StressMonitorTests/`
- **Not patched here:** this plan writes no source/test code (plan prohibition: gaps get recorded with a candidate-fix pointer, not silently patched)

## Task Commits

1. **Task 3: 03-UAT.md** - `a512dcd` (docs)
2. Tasks 1-2 are environment + command evidence (no repo files by design) — recorded above and in this SUMMARY

**Plan metadata:** (this commit)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Orphan-sweep command corrected**
- **Found during:** Task 2 leg 3
- **Issue:** the plan's literal check greps for `/* X.swift */` inside a `-A300` window after the first `3828578ADDAD4AC5925394DB /* Sources */` match; Sources-phase entries carry the `in Sources` suffix and the PBXFileReference lines (bare form) sit before the marker — so the command false-flagged **all 34 files** as orphans against a manifestly registered project
- **Fix:** swept the actual phase block (pbxproj lines 531–571) for `/* X.swift in Sources */` per file — acceptance criterion unchanged
- **Files modified:** none (verification command only)
- **Verification:** 0 orphans / 34 files; 34 in-Sources entries in the phase
- **Committed in:** n/a (evidence only)

**2. [Rule 3 - Blocking/environment] Postgres datadir recreated (plan-anticipated contingency)**
- **Found during:** Task 1 precheck
- **Issue:** /tmp cleanup gutted `/tmp/stress-pg-0206` (0 files remained — unrecoverable, not merely stopped)
- **Fix:** full recreation per the plan's own contingency text — initdb + port/listen config + createdb + `deno task migrate` (8/8); steps and migration list recorded in the Gate Evidence Record above
- **Files modified:** none (host environment)
- **Verification:** pg_isready exit 0; 8 rows in schema_migrations; suite 29/100 green exit 0
- **Committed in:** n/a (environment)

---

**Total deviations:** 2 auto-fixed (1 verification-command correction, 1 environment recreation)
**Impact on plan:** Both required to execute the gate at all; neither touches app source. The orphan criterion was enforced, not weakened.

## Issues Encountered

- Full-suite exit 65 with 6 host-crash restarts — classified against WINDOWS.md #8 as the accepted lineage (evidence in the Gate Evidence Record); no new ledger entry (entry #8 covers this family), consistent with 02-01/02-03/02-04/03-01/03-03 precedent.
- An isolation probe of the crash family alone (all 8 suites in `DataDeletionConsolidationTests.swift` + `DataDeleterServerWipeTests`) also crash-looped (6 restarts, exit 65, only CloudKitEncryptionTests completing) — same defect, further confirming the family's failures are host/environment-level, not assertion-level. At 03-04 (10:45 UTC) a subset of these suites passed in isolation; intermittence is the documented #8 behavior.
- GAP-1 discovered and recorded (see Named Gaps).

## Authentication Gates

None.

## User Setup Required

**Handover — 03-UAT.md scenarios are pending human execution** (end-of-phase verify, `human_verify_mode: end-of-phase`): five scenarios against the deployed backend `https://stress-api.dropitx.site` (health → 200 re-verified at handover). No external service configuration otherwise.

## Next Phase Readiness

- Phase 3 execution is complete; the phase is ready for `/gsd-verify-work` and the end-of-phase human verification (03-UAT.md)
- GAP-1 (ledger #12) needs a gap-closure decision: a one-file test-double reset would make the preferences suites order-independent and stop the greenness depending on the #8 crash cycle
- The recreated 5433 postgres is left running (datadir `/tmp/stress-pg-0206`, 8 migrations) — note /tmp purges will require the same recreation again (recorded procedure above)
- v1.1 close-out residue (STATE.md carry-overs): branch push decision, Windows ledger open entries

---
*Phase: 03-sessions-preferences-quick-actions-cleanup*
*Completed: 2026-08-23*

## Self-Check: PASSED

- 03-UAT.md and 03-05-SUMMARY.md exist on disk
- Task commit a512dcd present in git log
- Acceptance re-verified: UAT scenario grep 13; pg_isready exit 0; deno 29/100 exit 0; Release build exit 0; orphan 0/34; remnant 0/0 + 2 KEEP; revenue 1/0/1; quarantine disabled-with-reason
