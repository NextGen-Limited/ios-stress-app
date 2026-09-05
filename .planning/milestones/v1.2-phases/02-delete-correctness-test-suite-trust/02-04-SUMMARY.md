---
phase: 02-delete-correctness-test-suite-trust
plan: 04
subsystem: testing
tags: [swiftdata, xctest, swift-testing, storekit, storekittest, ci, windows-ledger]

# Dependency graph
requires:
  - phase: 02-01
    provides: DATA-04 CloudKit truthiness suite (unrelated to this plan's ENV-01/ENV-02 scope, but shares the DataDeletionConsolidationTests.swift file)
  - phase: 02-02
    provides: WR-04 unverified-transaction reachability audit
  - phase: 02-03
    provides: WR-03 DEBUG real-StoreKit wiring + product-ID registration fix (a precondition this plan verified as still holding via StoreKitProductCatalogLiveTests)
provides:
  - Root cause for WINDOWS.md #8 (container-lifetime bug, not a CI-host defect)
  - CharacterEntitlementSyncTests permanently un-quarantined
  - Confirmed-still-open dispositions for StoreKitServiceTests + EntitlementForegroundCorrectionTests, now proven local-host-reproducible (not CI-only)
  - Verified catch-up closure of WINDOWS #7 (StoreKitProductCatalogLiveTests)
  - Full trust-grep mapping: every disable/gate construct in StressMonitorTests accounted for
affects: [02-05, 02-06, phase-end-trust-gate]

# Actuals (#2632)
actuals:
  tokens: 8879
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SwiftData in-memory test fixtures MUST return (ModelContainer, ModelContext) and keep the container alive for the whole test — returning only the context lets the sole-owner container deallocate and the next SwiftData op on the orphaned context traps (EXC_BREAKPOINT, faulting frame #0 in SwiftData)."
    - "A disable/gate construct's disposition bar: failure signature (exact issue/exit-code shape) + ruled-out causes (including this session's) + residual risk + date, written into the suite's own file header — the ledger entry is a pointer, the header is the authoritative record."

key-files:
  created: []
  modified:
    - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
    - StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift
    - StressMonitor/StressMonitorTests/StoreKitServiceTests.swift
    - StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift
    - .github/workflows/_test.yml
    - AGENTS.md
    - .planning/WINDOWS.md

key-decisions:
  - "Fix-landed (not disposition) for the WINDOWS #8 / ENV-02 lineage: the container-lifetime hypothesis was CONFIRMED root cause, not merely 'best-known cause with accepted coverage loss'. All CI gate + quarantine + dead env plumbing removed."
  - "StoreKitServiceTests/EntitlementForegroundCorrectionTests stay dispositioned: isolation-matrix run this session reproduced productNotFound identically on TWO local simulators (current iPhone 17 + a disposable fresh iPhone 16), ruling out 'CI-runner-specific' as the sole cause and superseding the original disposition's premise."
  - "WINDOWS #7 (StoreKitProductCatalogLiveTests) closed as verified catch-up, independently of StoreKitServiceTests/EntitlementForegroundCorrectionTests' outcome — confirmed enabled with no disable trait and green (6/6, exit 0) before marking fixed."
  - "WINDOWS #6 left open, unchanged, because the `windows fixed`/`waive` CLI verbs carry no update-description action — the authoritative, dated, bar-meeting disposition lives in EntitlementForegroundCorrectionTests.swift's file header instead."

patterns-established:
  - "Isolation-matrix disposition confirmation: re-enable a disabled suite temporarily, run targeted on current + one disposable fresh simulator, and only re-disable (with an updated dated header) if it still fails both times — this converts a stale/unverified disposition into a positively-reconfirmed one instead of leaving it to rot."

requirements-completed: [ENV-01, ENV-02]

coverage:
  - id: D1
    description: "WINDOWS #8 lineage fixed: DataDeleterFailureAndCancellationTests + DataExportFieldSelectionTests ungated, running in the default invocation everywhere"
    requirement: ENV-01
    verification:
      - kind: integration
        ref: "xcodebuild test -only-testing:StressMonitorTests/DataDeleterFailureAndCancellationTests -only-testing:StressMonitorTests/DataExportFieldSelectionTests (env -u TEST_RUNNER_GSD_CI, current iPhone 17 + fresh E004C4FA-20EC-4768-B70F-2815EADE4A04) — both green, zero host restarts (cd5fbf1 evidence)"
        status: pass
      - kind: integration
        ref: "xcodebuild test full suite (TEST_RUNNER_GSD_CI=1, iPhone 16, CI-parity form) — 227 tests / 42 suites passed, exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "CharacterEntitlementSyncTests quarantine permanently lifted, restored to the default run"
    requirement: ENV-02
    verification:
      - kind: integration
        ref: "same targeted run as D1 (CharacterEntitlementSyncTests included) — green on both simulator rounds, zero host restarts"
        status: pass
    human_judgment: false
  - id: D3
    description: "StoreKitServiceTests + EntitlementForegroundCorrectionTests: isolation-matrix run confirms the disposition still holds (not CI-runner-specific); dated headers updated"
    verification:
      - kind: integration
        ref: "xcodebuild test -only-testing:StressMonitorTests/StoreKitServiceTests -only-testing:StressMonitorTests/EntitlementForegroundCorrectionTests (current iPhone 17 + fresh 6D88692A-0811-4FCC-8FD4-735290B348C8) — both rounds exit 65, identical productNotFound failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "WINDOWS #7 (StoreKitProductCatalogLiveTests) verified catch-up: confirmed enabled, no disable trait, green"
    verification:
      - kind: unit
        ref: "xcodebuild test -only-testing:StressMonitorTests/StoreKitProductCatalogLiveTests — 6/6 tests passed, exit 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Trust grep over StressMonitorTests maps every remaining disable/gate construct to a disposition outcome"
    verification:
      - kind: other
        ref: "grep -rn \"disabled(\\|enabled(if\" StressMonitor/StressMonitorTests --include=\"*.swift\" — 4 constructs remain, all accounted for (see mapping table below)"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-09-04
status: complete
---

# Phase 2 Plan 4: Test-Suite Truth Dispositions (ENV-01/ENV-02) Summary

**WINDOWS #8 and the CharacterEntitlementSyncTests quarantine were both a SwiftData container-lifetime bug (fixture returned a context whose owning ModelContainer had already deallocated) — fixed by converting three fixtures to keep-alive `(ModelContainer, ModelContext)` tuples; StoreKitServiceTests/EntitlementForegroundCorrectionTests confirmed still genuinely broken (productNotFound, reproduces on two local simulators, not CI-only) and re-dispositioned with dated evidence.**

## Performance

- **Duration:** ~1h 25m total (Task 1 committed 2026-09-03 23:51:56 UTC+7 in cd5fbf1 by a prior agent session; this continuation covered Tasks 2–3, ~40 min)
- **Started (this continuation):** 2026-09-04T05:55:00Z (approx.)
- **Completed:** 2026-09-04T06:10:50Z
- **Tasks:** 3 (Task 1 by prior session, Tasks 2–3 this session)
- **Files modified:** 7 (2 test-suite files by Task 1; +2 test-suite files, `_test.yml`, `AGENTS.md`, `WINDOWS.md` this session)

## Accomplishments

- Correlated all six live `.ips` crash reports to one signature (EXC_BREAKPOINT, faulting frame #0 in SwiftData, coalition `com.apple.CoreSimulator.SimDevice.5DD825B4-…`) and traced it to a container-lifetime bug never among the suite's five previously-ruled-out hypotheses.
- Converted three return-context-only fixtures to `(ModelContainer, ModelContext)` tuples with container keep-alive; proved the fix on two simulator rounds (current + fresh) with zero host restarts.
- Applied the fix-landed verdict: removed both `.enabled(if: GSD_CI == nil)` gates, permanently lifted the `CharacterEntitlementSyncTests` quarantine, deleted the now-dead `TEST_RUNNER_GSD_CI` CI plumbing, and confirmed the full suite green in the shipped configuration (227 tests / 42 suites, exit 0).
- Ran an isolation-matrix confirmation on the two remaining disabled suites (`StoreKitServiceTests`, `EntitlementForegroundCorrectionTests`): both reproduce `productNotFound` identically on the current simulator AND a disposable fresh simulator, ruling out "CI-runner-specific" as the sole cause — re-dispositioned with dated, bar-meeting headers rather than left stale.
- Independently verified `StoreKitProductCatalogLiveTests` (WINDOWS #7) is enabled and green (6/6) — closed as verified catch-up, kept cleanly separate from `StoreKitServiceTests`' outcome per the ledger-mapping rule.
- Produced a complete trust-grep mapping: all 4 remaining disable/gate constructs in `StressMonitorTests` map 1:1 to {2 dated dispositions, 2 conditional-by-design (`FirebaseBootstrapTests`, unchanged)} — zero unaccounted constructs.

## Task Commits

1. **Task 1: Bounded re-diagnosis — crash-report correlation + container-lifetime hypothesis test** - `cd5fbf1` (test) — *prior session*
2. **Task 2: Decide and apply the fix-or-disposition outcome (checkpoint:decision, verdict: fix-landed)** - `1ab4d01` (fix)
3. **Task 3: Disposition the two remaining disabled suites** - `5a45f7f` (test)

**Plan metadata:** *(pending — this SUMMARY + STATE.md/ROADMAP.md/REQUIREMENTS.md commit follows)*

## Files Created/Modified

- `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` — both `.enabled(if: GSD_CI == nil)` gates removed; headers rewritten with the confirmed root cause + fix date
- `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift` — quarantine permanently lifted; header finalized with root cause + fix date + checkpoint verdict
- `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift` — disposition updated to a dated (2026-09-04), bar-meeting record reflecting this session's local reproduction
- `StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift` — same disposition update, cross-referencing WINDOWS #6 and the now-confirmed product-ID registration fix
- `.github/workflows/_test.yml` — removed the dead `TEST_RUNNER_GSD_CI` env step, left a one-line history note
- `AGENTS.md` — updated the stale "don't fix the gating" testing-quirks note (Rule 1: directly caused by this change)
- `.planning/WINDOWS.md` — #8 fixed, #7 fixed (verified catch-up), #17 added+fixed (CharacterEntitlementSyncTests quarantine, no prior ledger id existed), #18 added (StoreKitServiceTests, no prior ledger id existed), #6 left open unchanged

## Bounded-Session Evidence Pack

### .ips crash-report correlation (Task 1, prior session — cd5fbf1)

All six live `.ips` reports (`StressMonitor-2026-09-03-1505{38,53}/1506{28,48}/1507{05,25}.ips`) share one signature: `EXC_BREAKPOINT SIGTRAP`, faulting frame #0 in SwiftData, coalition `com.apple.CoreSimulator.SimDevice.5DD825B4-FAEC-4A27-BAD4-3EC482889F0E`. The two newest reports name the direct callers: `DataExportFieldSelectionTests.csvExportHonorsToggles()` and `.jsonExportIncludesBaselineWhenRequested()` — both users of the return-context-only `makeContext()` fixture whose owning `ModelContainer` deallocated at fixture return. Container lifetime was never among the five previously ruled-out hypotheses.

### Fixture conversions (Task 1)

- `DataDeletionConsolidationTests.makeContextWithOneMeasurement` (:243-250 → tuple)
- `DataDeletionConsolidationTests.makeContext` (:380-384 → tuple)
- `CharacterEntitlementSyncTests.makeSeededContext` (:31-45 → tuple)

`grep -c "return container.mainContext"` over both files: **0** (confirmed clean).

### Targeted runs (Task 1 — WITHOUT `TEST_RUNNER_GSD_CI`)

- Round 1, current iPhone 17 (`5DD825B4-…`): pre-fix exit 65 (2 JSON assertion issues, zero host restarts — crash lineage already gone); post-fix **exit 0, 10/10 tests, 0.387s**.
- Round 2, fresh simulator `E004C4FA-20EC-4768-B70F-2815EADE4A04`: **exit 0, 10/10 tests, 0.870s, zero host restarts**.

**Verdict:** container-lifetime hypothesis CONFIRMED — all three suites (`DataDeleterFailureAndCancellationTests`, `DataExportFieldSelectionTests`, `CharacterEntitlementSyncTests`) cleared on both simulator rounds.

### Checkpoint record (Task 2)

- **Evidence presented:** the above .ips correlation + fixture conversion + dual-simulator green proof (cd5fbf1).
- **Verdict:** **fix-landed** (not disposition).
- **Date:** 2026-09-04.
- **Basis:** the plan's green-proof bar for fix-landed — "all three suites green on BOTH simulator rounds" — was met exactly by the Task 1 evidence.

### Full-suite verification after applying the fix (Task 2)

```
env: TEST_RUNNER_GSD_CI=1 (CI-parity form per AGENTS.md)
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

Suite "CloudKit Failure & Cancellation Ordering" passed after 0.012 seconds.
Suite "Data Export Field Selection" passed after 0.025 seconds.
Suite CharacterEntitlementSyncTests passed after 0.014 seconds.
Test run with 227 tests in 42 suites passed after 1.351 seconds.
** TEST SUCCEEDED **
EXIT_CODE=0
```

(`TEST_RUNNER_GSD_CI=1` is now inert for these three suites since the gate reads were removed; it was kept in this verification invocation only to match the plan's literal verify command and confirm no other suite still reacts to it.)

### Isolation-matrix run — StoreKitServiceTests / EntitlementForegroundCorrectionTests (Task 3)

Both suites were temporarily re-enabled and run targeted with `GSD_CI` unset, on the current simulator and one disposable fresh simulator (`StoreKitTest` sessions resolve via the committed `StressMonitorProducts.storekit` config through the shared `StoreKitTestSessionProvider`):

**Round 1 — current iPhone 17 (`5DD825B4-…`):**
```
Suite EntitlementForegroundCorrectionTests failed after 2.409 seconds with 1 issue.
  Test "Refresh after refund corrects stale-premium to false" — Caught error: productNotFound
Suite StoreKitServiceTests failed after 0.985 seconds with 9 issues.
  (all 9: Caught error: productNotFound, at purchase/restore/cancel/expiry call sites)
Test run with 11 tests in 2 suites failed after 3.395 seconds with 10 issues.
EXIT_CODE=65
```

**Round 2 — fresh simulator (`6D88692A-0811-4FCC-8FD4-735290B348C8`, created and torn down this session):**
```
Suite StoreKitServiceTests failed after 0.856 seconds with 9 issues (identical productNotFound signature)
Test run with 11 tests in 2 suites failed after 3.306 seconds with 10 issues.
EXIT_CODE=65
```

**Outcome:** identical failure on both rounds — the productNotFound signature is deterministic and host-independent, not a CI-runner-only artifact as the original headers assumed. Both suites restored to `.disabled(...)` with dated 2026-09-04 dispositions.

### WINDOWS #7 verified catch-up (Task 3)

```
xcodebuild test -only-testing:StressMonitorTests/StoreKitProductCatalogLiveTests (current iPhone 17)
Suite StoreKitProductCatalogLiveTests passed after 0.053 seconds.
Test run with 6 tests in 1 suite passed after 0.053 seconds.
EXIT_CODE=0
```
Confirmed enabled (no `.disabled` trait present) and green before marking WINDOWS #7 fixed.

## Trust-Grep Mapping Table

Final state of `grep -rn "disabled(\|enabled(if" StressMonitor/StressMonitorTests --include="*.swift"`:

| File:Line | Construct | Outcome | Ledger |
|---|---|---|---|
| `DataDeletionConsolidationTests.swift:238` (was) | `.enabled(if: GSD_CI == nil)` | **fixed-and-enabled** — gate removed | WINDOWS #8 fixed |
| `DataDeletionConsolidationTests.swift:384` (was) | `.enabled(if: GSD_CI == nil)` | **fixed-and-enabled** — gate removed | WINDOWS #8 fixed |
| `CharacterEntitlementSyncTests.swift:27` (was, already lifted in cd5fbf1) | `@Suite(.disabled)` | **fixed-and-enabled** — quarantine permanently lifted | WINDOWS #17 (new) fixed |
| `EntitlementForegroundCorrectionTests.swift:27` | `@Suite(.serialized, .disabled(...))` | **dated disposition** — reproduces locally on 2 simulators, not CI-only | WINDOWS #6 (unchanged, open) |
| `StoreKitServiceTests.swift:26` | `@Suite(.serialized, .disabled(...))` | **dated disposition** — reproduces locally on 2 simulators, not CI-only | WINDOWS #18 (new, open) |
| `FirebaseBootstrapTests.swift:28` | `.disabled(if: !hostCarriesPlist, ...)` | **conditional-by-design** — unchanged, cited per plan | none (by design) |
| `FirebaseBootstrapTests.swift:42` | `.disabled(if: !hostCarriesPlist, ...)` | **conditional-by-design** — unchanged, cited per plan | none (by design) |

Zero unaccounted constructs. `StoreKitProductCatalogLiveTests.swift` carries no disable/gate trait (confirmed via the same grep — it does not appear) and is independently verified green (WINDOWS #7, verified catch-up).

## Decisions Made

- **Fix-landed, not disposition, for ENV-01/ENV-02:** the plan's checkpoint (Task 2) offered both paths; the Task 1 evidence met the green-proof bar exactly, so the stronger outcome (gates removed, full CI coverage restored) was applied rather than defaulting to the disposition fallback.
- **Re-verify before re-disposition (Task 3):** rather than leaving the two remaining disabled suites' stale headers untouched, both were temporarily re-enabled and run on two simulators this session. This converts an unverified/stale disposition into a positively reconfirmed one and rules out "CI-runner-specific" as the cause (both suites now fail identically on a purely local host too) — a materially different, more precise finding than either suite's original header claimed.
- **Ledger tool-limitation handling:** `gsd-tools windows` has no "update description" verb (only `status`, `append`, `waive`, `fixed`). WINDOWS #6's stale description ("re-enable in 02-03") was left as-is rather than hand-edited (explicitly forbidden); the authoritative, current, bar-meeting disposition lives in `EntitlementForegroundCorrectionTests.swift`'s file header instead. New entries (#17, #18) were used where no prior ledger id existed, per the plan's explicit instruction not to reuse #6/#7's ids for a different suite's outcome.
- **Ledger commit sequencing:** because `.planning/WINDOWS.md` is a single file and all four ledger-verb calls (fixed 8, fixed 7, append+fixed 17, append 18) ran before the Task 2 git commit boundary, the #7/#17/#18 changes landed in commit `1ab4d01` (Task 2) rather than `5a45f7f` (Task 3) — noted in the Task 3 commit message to keep the audit trail honest about *when* the ledger state actually changed vs. which task's *file changes* it accompanies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Doc staleness directly caused by this change] Updated AGENTS.md's stale StoreKit-gate testing-quirk note**
- **Found during:** Task 2
- **Issue:** `AGENTS.md:45` told future agents "don't fix the gating" for `DataDeletionConsolidationTests`' `GSD_CI` check — a note this task's fix made actively wrong (the gate no longer exists).
- **Fix:** Replaced the note with one describing the actual root cause and the fact the suites now run unconditionally.
- **Files modified:** `AGENTS.md`
- **Verification:** Read the updated section; consistent with the code change.
- **Committed in:** `1ab4d01` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1, doc staleness)
**Impact on plan:** In-scope correction of a doc directly contradicted by this plan's own code change. No scope creep — `AGENTS.md` was not in the plan's `files_modified` list but the staleness was a direct, immediate consequence of the fix applied.

## Issues Encountered

- The full-suite verification run (`1ab4d01`'s evidence) started compiling before the Task 3 edits to `StoreKitServiceTests.swift`/`EntitlementForegroundCorrectionTests.swift` landed on disk, so that run's binary reflects those two suites' *original* disabled state (confirmed via the log: both suites show as "skipped", matching their pre-Task-3 headers). This does not affect the Task 2 evidence (`DataDeletionConsolidationTests`/`CharacterEntitlementSyncTests` were already finalized before that run started) and, since both suites ended Task 3 in the same disabled state they started in, the full-suite run's "skipped" result is still consistent with the final committed state — no re-run was needed.
- No `gsd-tools windows` verb exists to update an existing ledger entry's `description`/`reason` in place (only `append`, `waive`, `fixed`). Handled per "Decisions Made" above — WINDOWS #6 stays as originally recorded, with the current disposition living in the suite's file header.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- ENV-01 and ENV-02 fully closed (fix path); the test suite's `DataDeletionConsolidationTests` + `CharacterEntitlementSyncTests` coverage is CI-visible again with zero dead config.
- StoreKitServiceTests + EntitlementForegroundCorrectionTests remain a genuinely open coverage gap (WINDOWS #6, #18) — both need a working local CoreSimulator/XCTestDevices layer (WINDOWS #3) to diagnose the StoreKitTest daemon/session-isolation bug further. Not blocking for 02-05/02-06; carried forward as an accepted, dated coverage loss.
- Trust-grep mapping is complete and ready for the phase-end trust gate (plan 02-06) to re-check: 4 remaining constructs, all accounted for, zero silent disables.
- No blockers for 02-05.

## Self-Check: PASSED

- `git log --oneline --all | grep -E "cd5fbf1|1ab4d01|5a45f7f"` → all three commits found.
- `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`, `CharacterEntitlementSyncTests.swift`, `StoreKitServiceTests.swift`, `EntitlementForegroundCorrectionTests.swift`, `.github/workflows/_test.yml`, `AGENTS.md`, `.planning/WINDOWS.md` — all FOUND, all reflect the described edits (re-read after each edit).
- `.planning/WINDOWS.md` markdown table and JSON mirror agree (`open_count: 12`, `fixed_count: 6`, `total_count: 18` in both the front-matter and the recomputed ledger).
- Trust grep re-run after all edits: 4 constructs, matches the mapping table above exactly.

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-04*
