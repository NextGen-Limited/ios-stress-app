---
phase: 02-delete-correctness-test-suite-trust
plan: 06
subsystem: data-management
tags: [swiftdata, cloudkit, xctest, swift-testing, trust-gate, evidence]

# Dependency graph
requires:
  - phase: 02-01
    provides: DATA-04 CloudKit truthiness suite + SeededCloudKitResetService double, reused directly as the CloudKit fake for this plan's factory-reset pin
  - phase: 02-04
    provides: final gate state (all GSD_CI/TEST_RUNNER_GSD_CI gates removed; 2 remaining dated dispositions + 2 conditional-by-design) — the trust gate audits this exact state
  - phase: 02-05
    provides: AGENTS.md canonical CI-parity invocation — the exact command this plan's trust gate runs verbatim
provides:
  - Habit deleted in performFactoryReset's local sweep (store-sweep completeness)
  - 02-DATA-01-EVIDENCE.md — execution-ready two-surface verification note (live run is the outstanding end-of-phase human item)
  - 02-TRUST-GATE-RECORD.md — dated phase-end trust gate artifact (full-suite record, suite enumeration, disable-grep mapping)
affects: [phase-end-verification]

# Actuals (#2632)
actuals:
  tokens: 21500
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SwiftData in-memory fixtures that exercise performFactoryReset must register every model the reset now touches (StressMeasurement, CharacterUnlock, Habit) in the ModelContainer's schema, not just the models the fixture seeds — modelContext.delete(model:) crashes (signal abrt) if the type isn't part of the container's schema, even when zero rows of that type exist."
    - "Trust-gate enumeration reads xcresulttool's per-suite/per-test nodes (get test-results tests), not just the summary counts — a skip count matching the expected total is necessary but not sufficient; the per-suite/per-test names must map 1:1 to the dispositioned set."

key-files:
  created:
    - .planning/phases/02-delete-correctness-test-suite-trust/02-DATA-01-EVIDENCE.md
    - .planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md
  modified:
    - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
    - StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift
    - StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift

key-decisions:
  - "Planner decision (per plan frontmatter): FIX the Habit store-sweep gap rather than accept it — Habit is written (HabitViewModel) and synced (AppSchemaV2, cloudKitDatabase .automatic), so certifying a sweep that provably leaves a synced model undeleted would fail the phase's locked record-scope bar. Fixed with one modelContext.delete(model: Habit.self) call mirroring the CharacterUnlock precedent, TDD red-first."
  - "Assumption-delta: no-change (recorded 2026-09-03, orchestrator-resolved) — CloudKit's account-scoped CKRecord identity already generalizes to a second surface (console or second iPhone); no new identity axis or schema generalization needed."
  - "DATA-01 requirement stays Pending in REQUIREMENTS.md, not marked complete — the live two-surface verification (physical iPhone + CloudKit Console) is explicitly an end-of-phase human item this plan could not execute (no physical hardware or CloudKit Console access reachable from this session; Pitfall 7 explicitly rejects simulator-derived evidence). Only the automatable portion (sweep-completeness fix, evidence-note apparatus, unit coverage) is done this session."
  - "Deviation (Rule 1): the Habit fix surfaced a latent SwiftData crash in DataDeleterServerWipeTests' shared performFactoryReset fixture (Habit.self missing from the fixture's ModelContainer schema) — fixed in the same commit as the GREEN change, since it was a direct, immediate consequence of that change."

patterns-established:
  - "Every performFactoryReset-exercising SwiftData fixture across the test target was audited (grep for performFactoryReset + ModelContainer) before declaring the fix complete, not just the fixture in the plan's declared files_modified list — catching the one other affected file (DataDeleterServerWipeTests.swift) before it could crash a later suite run."

requirements-completed: []

coverage:
  - id: D1
    description: "performFactoryReset deletes Habit rows alongside CharacterUnlock and StressMeasurement — unit-pinned RED (Habit-survives assertion failed pre-fix) then GREEN"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "FactoryResetSweepCompletenessTests (DataDeleterCloudKitTruthinessTests.swift) — 2/2 passed: Habit/StressMeasurement/CharacterUnlock all empty after performFactoryReset; empty-store re-run completes without throwing"
        status: pass
      - kind: integration
        ref: "Targeted 4-suite run (plan's verify command + FactoryResetSweepCompletenessTests): 14 tests / 3 suites (DataDeletionConsolidationTests gated to 0 under TEST_RUNNER_GSD_CI=1, expected), TEST SUCCEEDED, exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "deleteAllMeasurements stays byte-unchanged (scoped path's narrower semantics disclosed, not altered)"
    verification:
      - kind: other
        ref: "git diff shows zero touched lines in deleteAllMeasurements (DataDeleterService.swift:67-130); only performFactoryReset's local sweep (:430-433) changed"
        status: pass
    human_judgment: false
  - id: D3
    description: "02-DATA-01-EVIDENCE.md exists with all seven skeleton sections, execution-ready for the human two-surface run"
    requirement: DATA-01
    verification:
      - kind: other
        ref: "test -f ...02-DATA-01-EVIDENCE.md && grep -c \"Timestamp|propagation\" → 7; grep -n \"deleteAllMeasurements|Habit|CD_StressMeasurement\" → 8 hits across disclosure/procedure/machine-verified sections"
        status: pass
    human_judgment: true
  - id: D4
    description: "Phase trust gate: full suite green in the shipped (un-gated) configuration, xcresulttool enumeration shows zero unexpected skips, disable/gate grep maps 1:1 to the 02-04 disposition set with zero unaccounted/zero new"
    requirement: BUILD-04
    verification:
      - kind: integration
        ref: "Full-suite AGENTS.md canonical invocation: exit 0, 229 tests/43 suites passed (console); xcresulttool summary: 248 passed / 11 skipped / 0 failed / totalTestCount 259"
        status: pass
      - kind: other
        ref: "xcresulttool get test-results tests: 43 suites enumerated by name; only EntitlementForegroundCorrectionTests + StoreKitServiceTests skipped (11 tests total), matching the expected disposition set exactly"
        status: pass
      - kind: other
        ref: "grep -rn \"disabled(|enabled(if\" StressMonitor/StressMonitorTests: 4 constructs, all 4 mapped (2 dated dispositions unchanged since 02-04, 2 conditional-by-design), 0 new"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-09-04
status: complete
---

# Phase 2 Plan 6: Store-Sweep Completeness (Habit), DATA-01 Evidence, Phase Trust Gate Summary

**`performFactoryReset` now deletes `Habit` alongside `CharacterUnlock`/`StressMeasurement` (TDD red-first, mirroring the existing precedent); the DATA-01 two-surface evidence note is execution-ready with every disclosure and procedure step pre-seeded; and the phase-end trust gate is a dated artifact proving the full suite is green with zero unexplained skips and zero unaccounted disable constructs — the live cross-device delete verification remains the explicit outstanding end-of-phase human item.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3
- **Files created:** 2 (`02-DATA-01-EVIDENCE.md`, `02-TRUST-GATE-RECORD.md`)
- **Files modified:** 3 (`DataDeleterService.swift`, `DataDeleterCloudKitTruthinessTests.swift`, `DataDeleterServerWipeTests.swift` — the last as a Rule-1 deviation)

## Accomplishments

- Closed the store-sweep completeness gap the phase research surfaced: `Habit` (`AppSchemaV2`, synced via `cloudKitDatabase: .automatic`) was deleted by no code path in `performFactoryReset` despite being written by `HabitViewModel`. Added the one-line fix mirroring the existing `CharacterUnlock` deletion, with a full TDD cycle: RED confirmed (Habit-survives assertion failed against the pre-fix binary), GREEN confirmed after the fix, plus an empty-store idempotency pin.
- Discovered and fixed (Rule 1) a latent crash the Habit fix exposed in `DataDeleterServerWipeTests`' shared `performFactoryReset` fixture — its `ModelContainer` schema didn't register `Habit.self`, so the new delete call crashed with `signal abrt` across every test in that suite calling `performFactoryReset`. Fixed by adding `Habit.self` to the fixture's container registration.
- Produced `02-DATA-01-EVIDENCE.md`: an execution-ready evidence note (01-WIRE-01-EVIDENCE.md pattern) with the certified factory-reset surface disclosed against the narrower `deleteAllMeasurements` scoped path, a full record-type query list (three `CD_` service types + mandatory live console enumeration of the NSPersistentCloudKitContainer-mirrored types), and a poll-until-stable-empty procedure with propagation-delay computation — every disclosure and procedure step pre-seeded from source-verified facts, with the live run itself left explicitly PENDING for the human executor.
- Ran the phase-end trust gate: the full suite via the AGENTS.md canonical un-gated CI-parity invocation (exit 0, 229 tests/43 suites), `xcresulttool` per-suite/per-test enumeration (zero unexpected skips — the only 11 skipped tests belong to exactly the two 02-04-dispositioned suites), and the disable/gate grep mapped 1:1 to 02-04's final disposition table (4 constructs, 4 accounted, 0 new). Recorded as `02-TRUST-GATE-RECORD.md`.

## Task Commits

1. **Task 1 (TDD RED): pin Habit survives performFactoryReset** — `a900231` (test)
2. **Task 1 (TDD GREEN): delete Habit rows in factory-reset local sweep + fixture crash fix (Rule 1 deviation, same commit)** — `0692e95` (feat)
3. **Task 2: DATA-01 evidence note skeleton** — `cf71839` (docs)
4. **Task 3: Phase trust gate — full-suite record, enumeration, disable-grep mapping** — `65e9f9f` (docs)

## Files Created/Modified

- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` — `performFactoryReset`'s local sweep gained `try modelContext.delete(model: Habit.self)` alongside the existing `CharacterUnlock` deletion (:430-433); `deleteAllMeasurements` untouched
- `StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift` — new `FactoryResetSweepCompletenessTests` suite (2 tests): Habit/StressMeasurement/CharacterUnlock all empty post-reset; empty-store re-run doesn't throw
- `StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift` — `makeContextWithOneMeasurement`'s `ModelContainer` now registers `Habit.self` (Rule 1 deviation, crash fix)
- `.planning/phases/02-delete-correctness-test-suite-trust/02-DATA-01-EVIDENCE.md` — new, execution-ready two-surface evidence note
- `.planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md` — new, phase trust-gate artifact

## Verification Evidence

### Task 1 — RED (quoted)

```
✘ Test "performFactoryReset empties Habit, StressMeasurement, and CharacterUnlock"
  recorded an issue at DataDeleterCloudKitTruthinessTests.swift:329:9:
  Expectation failed: try ctx.fetch(FetchDescriptor<Habit>()).isEmpty
✘ Test run with 2 tests in 1 suite failed after 0.178 seconds with 1 issue.
```

### Task 1 — GREEN + regression (quoted)

```
✔ Suite "Factory Reset Sweep Completeness" passed after 0.064 seconds.
✔ Test run with 2 tests in 1 suite passed after 0.064 seconds.
```

Combined targeted run (plan's literal verify command + the new suite):
```
✔ Test run with 14 tests in 3 suites passed after 0.386 seconds.
** TEST SUCCEEDED **
EXIT_CODE=0
```
(`DataDeletionConsolidationTests` contributes 0 tests under `TEST_RUNNER_GSD_CI=1` — expected per 02-04's outcome; the var is now inert for the gates 02-04 already removed but still zero-effect-verified here as the plan's verify command literally specifies it.)

### Task 2 (quoted)

```
$ test -f .../02-DATA-01-EVIDENCE.md && grep -c "Timestamp|propagation" ... && grep -n "deleteAllMeasurements|Habit|CD_StressMeasurement" ... | head -8; echo NOTE_OK
7
16:| `performFactoryReset` | ... |
17:| `deleteAllMeasurements` (scoped ...) | ... |
19:**Byte-unchanged confirmation:** ...
25:1. `CD_StressMeasurement`
31:4. **The NSPersistentCloudKitContainer-mirrored types** ...
50:1. **Before deleting:** ...
77:- **`FactoryResetSweepCompletenessTests`** ...
92:**Expected outcome:** ...
NOTE_OK
```

### Task 3 (quoted)

```
$ xcodebuild test [AGENTS.md canonical invocation, un-gated, iPhone 16]
✔ Test run with 229 tests in 43 suites passed after 1.805 seconds.
** TEST SUCCEEDED **
EXIT_CODE=0

$ xcrun xcresulttool get test-results summary --path TestResults-trustgate.xcresult
totalTestCount: 259, passedTests: 248, skippedTests: 11, failedTests: 0, result: "Passed"

$ grep -rn "disabled(|enabled(if" StressMonitor/StressMonitorTests --include="*.swift" | grep -v FirebaseBootstrap
EntitlementForegroundCorrectionTests.swift:27, StoreKitServiceTests.swift:26
GREP_DONE
```

## Decisions Made

- **FIX, not accept, for the Habit gap** — per the plan's pre-recorded planner decision, mirroring the existing `CharacterUnlock` precedent exactly (one `modelContext.delete(model:)` call). Certifying a sweep that provably leaves a synced model undeleted would have failed the phase's locked "full store set the app writes" bar.
- **DATA-01 stays Pending in REQUIREMENTS.md** — this plan closes DATA-01 "to the extent automatable" per its own objective text; the live two-surface verification (physical iPhone signed into the team iCloud account + CloudKit Console or a second iPhone) requires hardware and account access unreachable from this session, and Pitfall 7 explicitly forbids substituting simulator evidence. Marking DATA-01 complete now would misrepresent an unexecuted human verification step as done. The evidence note (§6) names this as the explicit outstanding end-of-phase human item; `/gsd-verify-work` for this phase is the expected place that item gets executed and the requirement subsequently marked complete (mirroring how Phase 1's WIRE-01 physical-device item was validated at that phase's verification step, not preemptively).
- **Reused `SeededCloudKitResetService` (from 02-01) and `FakeServerSessionWiper` (from `DataDeleterServerWipeTests.swift`, same test target, no explicit access modifier so internally visible) for the new factory-reset fixture** rather than duplicating equivalent fakes — both were already exactly the right shape (`.draining` behavior; empty-first-page wiper) for a factory-reset test that needs no real network access.
- **Habit-fix fixture audit was done target-wide, not just on the plan's declared file** — grepped every `performFactoryReset` call site across `StressMonitorTests` before declaring Task 1 done, which is how the `DataDeleterServerWipeTests.swift` crash was caught and fixed in the same commit rather than surfacing later in Task 3's full-suite run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug directly caused by this change] `DataDeleterServerWipeTests`'s shared factory-reset fixture crashed after the Habit fix**
- **Found during:** Task 1, immediately after applying the GREEN fix and re-running the plan's targeted verify command.
- **Issue:** the new `modelContext.delete(model: Habit.self)` call in `performFactoryReset` crashed with `signal abrt` on every `DataDeleterServerWipeTests` test that calls `performFactoryReset`, because that suite's `ModelContainer` fixture registered only `StressMeasurement.self, CharacterUnlock.self` — `Habit` was absent from the container's schema.
- **Fix:** added `Habit.self` to the fixture's `ModelContainer(for:...)` call, mirroring the existing `CharacterUnlock` registration.
- **Files modified:** `StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift`
- **Verification:** re-ran the combined 4-suite targeted command — 14/14 tests passed, exit 0.
- **Committed in:** `0692e95` (same commit as the GREEN fix)

---

**Total deviations:** 1 auto-fixed (Rule 1, latent test-fixture crash)
**Impact on plan:** In-scope correction directly caused by this plan's own code change; the file was not in the plan's declared `files_modified` list but the crash was an immediate, unavoidable consequence of the Habit fix (SwiftData requires the deleted model type to be part of the container's schema).

## Issues Encountered

- The plan's Task 1 verify command (`-only-testing:StressMonitorTests/DataDeleterCloudKitTruthinessTests -only-testing:...`) does not name the new `FactoryResetSweepCompletenessTests` struct (added inside `DataDeleterCloudKitTruthinessTests.swift` but as a separate `@Suite`) — `xcodebuild -only-testing:` filters by type name, so the new suite was silently excluded from the first targeted run. Caught by cross-checking the xcresult enumeration against expectations; resolved by adding `-only-testing:StressMonitorTests/FactoryResetSweepCompletenessTests` to every subsequent targeted run and the record's citations. No impact on Task 3's full-suite run (which has no `-only-testing` filter and includes every suite).

## User Setup Required

None automatable from this session. **The plan's `user_setup` block (iCloud physical device + CloudKit Console access) is apparatus for the end-of-phase human verification session**, not a precondition for this plan's Tasks 1-3 — no task-level precondition depended on it, so execution proceeded through all three tasks as designed.

## Next Phase Readiness

- **Outstanding human item (explicit, not dropped):** the live two-surface DATA-01 verification — delete on a physical iPhone signed into the team iCloud account, observe stable-empty on the CloudKit Console (or a second physical iPhone) after a documented propagation wait, and fill in `02-DATA-01-EVIDENCE.md`'s §2/§4 with real timestamps, counts, and screenshots. This is the sole remaining item before DATA-01 can be marked complete.
- Phase trust gate passes cleanly: the suite is a believable gate (full-suite green, every skip enumerated and dispositioned, zero unaccounted disable constructs) — ready input for `/gsd-verify-work 2`.
- All 6 plans in Phase 2 (02-01 through 02-06) are now executed. ROADMAP.md and STATE.md updated accordingly (see below); phase-level verification (including the DATA-01 human item) is the next step, not part of this plan.

## Self-Check: PASSED

- `git log --oneline --all | grep -E "a900231|0692e95|cf71839|65e9f9f"` → all four commits found.
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`, `StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift`, `StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift`, `.planning/phases/02-delete-correctness-test-suite-trust/02-DATA-01-EVIDENCE.md`, `.planning/phases/02-delete-correctness-test-suite-trust/02-TRUST-GATE-RECORD.md` — all FOUND, all reflect the described edits (re-read after each edit).
- Task 1's verify command (as literally specified) re-run: `TEST_RUNNER_GSD_CI=1 xcodebuild test ... -only-testing:StressMonitorTests/DataDeleterCloudKitTruthinessTests -only-testing:StressMonitorTests/DataDeleterServerWipeTests -only-testing:StressMonitorTests/DataDeletionConsolidationTests -only-testing:StressMonitorTests/FactoryResetSweepCompletenessTests` → 14 tests/3 suites, TEST SUCCEEDED, exit 0.
- Task 2 and Task 3 verify commands re-run above with quoted, matching output.

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-04*
