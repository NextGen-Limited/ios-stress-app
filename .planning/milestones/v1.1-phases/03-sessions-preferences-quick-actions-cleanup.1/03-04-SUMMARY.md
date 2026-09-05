---
phase: 03-sessions-preferences-quick-actions-cleanup
plan: 04
subsystem: data-management
tags: [factory-reset, server-wipe, sessions-api, protocol-seam, tdd, supabase-cleanup, github-issue]

# Dependency graph
requires:
  - phase: 03-sessions-preferences-quick-actions-cleanup
    plan: 01
    provides: StressAPIClient+Sessions (listSessions/deleteSession with matching signatures), ChatSession DTO
provides:
  - ServerSessionWiping protocol seam + StressAPIClient conformance (DataManagement ↔ Sessions API bridge)
  - Factory-reset Phase 0 server-session wipe (paginated, 50-page cap, Q2 auth-skip classification)
  - DeletionError.serverSessionError(Error) case
  - Unconditional stressChatSessionId clear in clearCredentialsAndSharedCaches (both delete paths)
  - Supabase remnant cleanup (.gitignore + 25-about.html)
  - Backend metering issue https://github.com/phuongddx/stress-app-be/issues/2
affects: [03-05, v1.1-close]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 6739
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Retain the in-memory ModelContainer for the whole test scope — a helper that returns only container.mainContext crashes SwiftData deterministically when the container deallocates (WINDOWS.md #8 lineage made deterministic by a two-model schema)"
    - "Failure classification at the wipe boundary: auth-unavailable errors (LLMServiceError.unavailable from getIDToken, SessionsAPIError.unauthorized 401) skip-with-log; everything else wraps into DeletionError.serverSessionError and fails the reset (CloudKit precedent)"

key-files:
  created:
    - StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
    - StressMonitor/StressMonitor/Services/DataManagement/DataDeleter.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift
    - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - .gitignore
    - design/screens/25-about.html
    - .planning/phases/03-sessions-preferences-quick-actions-cleanup/COVERAGE.md

key-decisions:
  - "ServerSessionWiping protocol declared in DataDeleter.swift beside the error taxonomy (plan offered DataDeleterService.swift as the alternative; the seam and its error case belong together)"
  - "Wipe loop throws plain URLError(.badServerResponse) at the cap and lets wipeServerSessionsOrSkip wrap it once — avoids double-wrapped serverSessionError(serverSessionError(...))"
  - "CancellationError passes through the classifier as operationCancelled so the reset's existing cancellation semantics (CR-01) are preserved"
  - "Test fixtures return (ModelContainer, ModelContext) and hold the container for the test body — the consolidation tests' return-context-only shape is the documented crash-loop lineage; this suite must not add to it"

patterns-established:
  - "Pattern: classification-catch (specific enum-case catch clauses → skip, generic → wrap) for phase-gated server calls inside destructive flows"
  - "Pattern: recording fakes (RecordingCloudKitResetService.databaseResetCallCount) to prove phase ordering — aborted-phase counters stay at zero"

requirements-completed: [derived-SES-03, derived-CLEAN-01]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Factory reset wipes all server chat sessions page-by-page before the local wipe (ordered list→delete→list sequence, 50-page cap)"
    requirement: derived-SES-03
    verification:
      - kind: unit
        ref: "StressMonitorTests/DataDeleterServerWipeTests.swift#factoryResetWipesEveryServerSessionPageByPage + runawayWipeLoopTerminatesAtPageCapAndFailsReset (exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Auth-unavailable skip vs fail-loudly classification (Q2): signed-out/401 skip with log and reset proceeds; network error fails the whole reset before the local wipe"
    requirement: derived-SES-03
    verification:
      - kind: unit
        ref: "StressMonitorTests/DataDeleterServerWipeTests.swift#signedOutSkipsServerWipeAndStillCompletesReset + unauthorizedSkipsServerWipeAndStillCompletesReset + serverWipeNetworkErrorFailsWholeResetBeforeLocalWipe (exit 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "stressChatSessionId cleared unconditionally by clearCredentialsAndSharedCaches on both delete-all and factory-reset paths"
    requirement: derived-SES-03
    verification:
      - kind: unit
        ref: "StressMonitorTests/DataDeletionConsolidationTests.swift (DeleteAllCredentialClearanceTests.clearsStressChatSessionId, exit 0; plus inline asserts in both successful wipe tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Supabase remnant cleanup: .gitignore entry removed, 25-about.html OSS row swapped to Firebase Auth 11, KEEP sites untouched"
    requirement: derived-CLEAN-01
    verification:
      - kind: unit
        ref: "grep -c -i supabase .gitignore design/screens/25-about.html → 0/0; keep-sites = exactly FirebaseAuthService.swift + DataDeletionConsolidationTests.swift, git-diff clean inside them"
        status: pass
    human_judgment: false
  - id: D5
    description: "POST /quick-actions metering gap recorded on phuongddx/stress-app-be and cross-linked from COVERAGE row 17"
    requirement: derived-CLEAN-01
    verification:
      - kind: other
        ref: "gh issue list → #2 OPEN https://github.com/phuongddx/stress-app-be/issues/2; backend repo working tree has no changes from this task"
        status: pass
    human_judgment: false

# Metrics
duration: 22min
completed: 2026-08-23
status: complete
---

# Phase 3 Plan 4: Server-Session Wipe + Supabase Remnant Cleanup Summary

**Factory reset now deletes every server chat session (paginated wipe with auth-skip classification) before the local wipe, clears stressChatSessionId unconditionally, and the two locked Supabase remnants are gone — with the backend metering gap filed as stress-app-be#2**

## Performance

- **Duration:** ~22 min (10:33–10:55 UTC)
- **Started:** 2026-08-23T10:33:18Z
- **Completed:** 2026-08-23T10:54:46Z
- **Tasks:** 3 (Task 1 TDD: RED → GREEN, no refactor needed; Tasks 2-3 auto)
- **Files modified:** 9

## Accomplishments
- Factory-reset Phase 0 server wipe: `ServerSessionWiping` seam (protocol in DataDeleter.swift, `StressAPIClient` conformance in +Sessions) injected into `DataDeleterService` behind a defaulted init parameter; pagination loop (limit 20, offset advance by page count) with a 50-page hard cap that throws instead of looping
- Q2 classification exactly as planned: `LLMServiceError.unavailable` (signed-out shape from `getIDToken()`) and `SessionsAPIError.unauthorized` (401) skip the wipe with a DataManagementLogger line so an offline-of-auth reset stays possible; every other error (URLError, 5xx, cap) fails the whole reset loudly via `DeletionError.serverSessionError` — never a silent partial success
- `stressChatSessionId` (T-3-15) closed: `clearCredentialsAndSharedCaches` now also calls `StressLLMService.clearStoredCredentials()` — previously zero call sites; pinned by the new consolidation case and inline asserts in both successful wipe tests
- Both Supabase remnants removed (.gitignore:164, 25-about.html:207 → "Firebase Auth / 11"); KEEP sites byte-identical
- Backend metering issue filed non-interactively: **https://github.com/phuongddx/stress-app-be/issues/2** (OPEN, verified via `gh issue list`); COVERAGE.md row 17 reason cell now carries the URL; backend repo untouched

## Task Commits

Each task was committed atomically:

1. **Task 1: Server-session wipe phase + unconditional session-id clear (RED → GREEN)** - `20b7da7` (test) → `890530e` (feat); no refactor commit — GREEN landed with the classification helper (`wipeServerSessionsOrSkip`) and loop (`wipeServerSessions`) already split per the plan's refactor suggestion
2. **Task 2: Supabase remnant cleanup** - `8656174` (chore)
3. **Task 3: Backend metering issue + COVERAGE cross-link** - `d19bfa6` (docs)

**Plan metadata:** (this commit)

## Files Created/Modified
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` - serverSessionWiper injection (defaults to `StressAPIClient()`), Phase 0 in performFactoryReset, wipe funcs, StressLLMService.clearStoredCredentials wiring
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleter.swift` - `ServerSessionWiping` protocol + `DeletionError.serverSessionError(Error)`
- `StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift` - `extension StressAPIClient: ServerSessionWiping {}` (methods already existed from 03-01)
- `StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift` - 5 tests (registered at pbxproj A023/B023)
- `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` - added `clearsStressChatSessionId` case; all Supabase-sweep KEEP cases unchanged
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` - 4-line registration (verified purely additive via git diff)
- `.gitignore` - `supabase/.temp/` + orphaned blank removed
- `design/screens/25-about.html` - OSS row "Supabase LLM 2.4" → "Firebase Auth 11"
- `.planning/phases/03-sessions-preferences-quick-actions-cleanup/COVERAGE.md` - row 17 carries the issue URL

## Decisions Made
- **Q2 skip-vs-fail classification as implemented:** `wipeServerSessionsOrSkip()` catches `LLMServiceError.unavailable(reason:)` and `SessionsAPIError.unauthorized` as "no authenticated identity" (log + skip + reset proceeds — airplane-mode/signed-out reset stays possible); `CancellationError` maps to `operationCancelled` (preserves CR-01 semantics); everything else wraps once into `DeletionError.serverSessionError` and aborts before "Factory reset complete". An offline factory reset surfaces an error rather than silently claiming server history was deleted — DATA-01 honesty over convenience, per the plan's locked tradeoff.
- **Wipe runs strictly before sign-out:** Phase 0 executes while the Firebase token is still obtainable; `clearCredentialsAndSharedCaches` remains the LAST step (line ordering verified in the diff).
- **`deleteAllMeasurements` (snapshots-only path) untouched:** verified via `git diff` — no hunks touch it; chat history wipes only on factory reset (least-surprise scope separation).
- **Test-container lifetime:** fixtures return `(ModelContainer, ModelContext)`; each test holds the container until assertions complete (see Deviations #1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Deterministic SwiftData SIGTRAP in the new suite (WINDOWS.md #8 lineage)**
- **Found during:** Task 1 GREEN run
- **Issue:** All 5 wipe tests crashed the test host (EXC_BREAKPOINT in SwiftData, one test per launch, 5 restarts, exit 65). Root cause: the fixture helper returned only `container.mainContext`, letting the in-memory `ModelContainer` deallocate at function exit — the same shape as the pre-existing intermittently-crashing consolidation suites documented in WINDOWS.md entry #8; registering two models (StressMeasurement + CharacterUnlock) made the trap deterministic. Crash reports confirmed the trap fired inside `LocalDataWipeService.deleteAllMeasurements` and inside test-local `ctx.fetch`.
- **Fix:** Helper returns `(ModelContainer, ModelContext)`; each test keeps the container alive for its body (`_ = container` with an explanatory comment)
- **Files modified:** StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift
- **Verification:** re-run exits 0 with zero restarts — 9 tests / 3 suites pass in 0.183s
- **Committed in:** `890530e` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (bug)
**Impact on plan:** Contained to the new test file; production code and the pre-existing suites are unchanged. The root-cause pattern (drop the container, keep the context) remains present in the pre-existing consolidation tests — out of scope here (pre-existing, Rule scope boundary), logged below for the ledger.

## Issues Encountered
- The plan's `<verify>` filter names `-only-testing:StressMonitorTests/DataDeletionConsolidationTests` (the FILE name); the actionable Swift Testing filter is the suite TYPE name. Executed with the three type names in that file that matter for this plan: `DataDeleterServerWipeTests`, `DeleteAllCredentialClearanceTests` (holds the new case + keychain/widget KEEP pins), `DataDeleterConsolidationTests` (refresh-token KEEP pin). All pass, exit 0.
- First GREEN attempt (before the container fix) showed suites "passing" in a final relaunch while the 5 wipe tests had each crashed an earlier launch — the "passed after 0.001 seconds" summary line is the runner abandoning crashed tests, not a real pass. The exit-0 run with all 5 individual ✔ Test lines is the recorded evidence.

## TDD Gate Compliance
- Task 1: RED `20b7da7` (test — build fails on missing `ServerSessionWiping` / `serverSessionWiper:` / `serverSessionError`, exit 65 at RED run) → GREEN `890530e` (feat — 9/9 pass, exit 0). REFACTOR omitted — GREEN landed with the classification/loop helper split the plan's refactor step suggested; nothing left to clean.
- Tasks 2-3 are `type="auto"` (config edits + external issue) — no TDD gates apply.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 03-05 (final integration gate) can proceed: full-suite run, Release build, backend suite, UAT script. The new suite is registered and green; full-suite impact of this plan rides 03-05's gate per the plan's verification note.
- The container-lifetime crash pattern in the PRE-EXISTING consolidation/failure suites remains open as WINDOWS.md #8 (intermittent in full-suite runs) — this plan's suite avoids it; a durable fix (returning containers there too) is a candidate for a future maintenance pass.
- derived-SES-03 and derived-CLEAN-01 are complete; every backend endpoint is now consumed or carries a recorded opt-out with the backend issue tracked server-side.

---
*Phase: 03-sessions-preferences-quick-actions-cleanup*
*Completed: 2026-08-23*

## Self-Check: PASSED

- All key files exist on disk (new suite, SUMMARY, COVERAGE)
- All 4 task commits present in git log (20b7da7, 890530e, 8656174, d19bfa6)
- Acceptance greps re-verified: serverSessionError=2, clearStoredCredentials=2, deleteAllMeasurements untouched, pbxproj diff purely additive, remnant greps 0/0, keep-sites exactly 2
