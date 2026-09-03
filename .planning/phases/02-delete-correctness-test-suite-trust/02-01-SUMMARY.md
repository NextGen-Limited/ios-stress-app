---
phase: 02-delete-correctness-test-suite-trust
plan: 01
subsystem: testing
tags: [cloudkit, swift-testing, regression-suite, di-seams, mutation-testing, swiftdata]

# Dependency graph
requires:
  - phase: 01-binary-manifest-truth
    provides: CI-parity test invocation (TEST_RUNNER_GSD_CI=1 env form) and the red/green-gated tooling pattern (verify-archive.sh)
provides:
  - Ungated, CI-visible regression suite that fails when DataDeleterService stops propagating CloudKit reset failures (the v1.0 CR-01 shape)
  - SeededCloudKitResetService test double (lying / throwing / draining behaviors + exact remainingRecords count) for the CloudKitResetServiceProtocol DI seam
  - Mutation red/green proof that the suite catches a swallowed CloudKit failure
affects: [02-delete-correctness-test-suite-trust, 04-submission-packaging, DATA-01 live verification (plan 02-06)]

# Actuals (#2632) — pairs with the plan's estimate (38000) to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 5900
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deletion-aware protocol double with behavior enum (.lying/.throwing/.draining) + exact-Int survivor accessor (remainingRecords) — extends the FakeServerSessionWiper/FakeCloudKitResetService family"
    - "Mutation red-proof as the TDD red gate for regression suites guarding already-fixed bugs (suite green on HEAD, red under the reintroduced bug, green after revert)"

key-files:
  created:
    - StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "Suite landed as a new sibling file (not inside DataDeletionConsolidationTests.swift) so the ungated suite stays clear of the #8-gated file; pbxproj registration required (A026/B026)"
  - "One SeededCloudKitResetService double covers all three prongs via a behavior enum; remainingRecords is an exact Int sum keyed by CloudKitRecordType"
  - "Tracer end-to-end gate executed as Task 2's mutation run (the plan's own design) rather than a mid-plan human checkpoint — plan frontmatter autonomous: true, and Task 2 IS the gate"

patterns-established:
  - "Query-based emptiness contract in tests: survivors are only ever observed by querying the double's store (remainingRecords), never by trusting a success return"
  - "Doc comments in ungated suites must not contain the literal gating constructs — the phase-end trust-gate grep would false-positive on them"

requirements-completed: [DATA-04]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Ungated CloudKit delete-truthiness regression suite (3 prongs + boundary + idempotency) pinning the v1.0 CR-01 signal through the CloudKitResetServiceProtocol DI seam"
    requirement: DATA-04
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift#CloudKit Delete Truthiness (5 tests, -only-testing run)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mutation red-proof: the suite goes red when the orchestrator swallows a CloudKit failure (CR-01 reintroduced), green after revert"
    requirement: DATA-04
    verification:
      - kind: other
        ref: "mutation run: swallowing do/catch around DataDeleterService.swift:97-100 → xcodebuild -only-testing exit 65 (prong 1 failed, 2 issues at :140/:149); revert → exit 0, 5/5 green"
        status: pass
    human_judgment: false
  - id: D3
    description: "Suite is CI-visible by construction and registered in the StressMonitorTests target"
    requirement: DATA-04
    verification:
      - kind: other
        ref: "grep gating constructs in new suite = 0; grep RequestCaptureURLProtocol = 0; pbxproj has PBXBuildFile (line 48) + PBXFileReference (line 143) + group child + Sources phase entries; suite ran under TEST_RUNNER_GSD_CI=1 (CI-parity env)"
        status: pass
    human_judgment: false

# Metrics
duration: 10 min
completed: 2026-09-03
status: complete
---

# Phase 2 Plan 1: CloudKit Delete-Truthiness Regression Suite Summary

**Ungated 3-prong spy suite pinning the v1.0 CR-01 CloudKit delete-truthiness signal via the CloudKitResetServiceProtocol DI seam, with a mutation red-proof proving CI catches a swallowed failure**

## Performance

- **Duration:** 10 min (571s)
- **Started:** 2026-09-03T15:52:43Z
- **Completed:** 2026-09-03T16:02:14Z
- **Tasks:** 2 (Task 2 = verification-only, no committed changes by design)
- **Files modified:** 2

## Mutation proof (tracer end-to-end gate — Task 2 record)

The red side of this plan's TDD gate is a mutation run: the v1.0 CR-01 swallow
was temporarily reintroduced into production code, the suite had to go red,
then green after revert. Mirrors the Phase-1 verify-archive.sh red/green pattern.

**Mutation (temporary, NEVER committed):** wrapped the CloudKit reset call in
`deleteAllMeasurements` — `try await cloudKitResetService.deleteRecords(ofType:
.stressMeasurement, expectedProgress: 0.1...0.4)` (DataDeleterService.swift:97-100) —
in a swallowing `do { … } catch {}` (failure caught, success reported): the CR-01 shape.

**RED run** (same invocation as the green run):

```text
TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:StressMonitorTests/DataDeleterCloudKitTruthinessTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
→ MUTATION_RUN_EXIT_CODE=65
```

Failing test (the genuine-failure prong) — quoted from the run log:

```text
✘ Test "a genuine CloudKit failure propagates as DeletionError.cloudKitError with the underlying error preserved" recorded an issue at DataDeleterCloudKitTruthinessTests.swift:140:25: Issue recorded
✘ Test "a genuine CloudKit failure propagates as DeletionError.cloudKitError with the underlying error preserved" recorded an issue at DataDeleterCloudKitTruthinessTests.swift:149:9: Expectation failed: (remaining.count → 0) == 1
✘ Test "a genuine CloudKit failure propagates as DeletionError.cloudKitError with the underlying error preserved" failed after 0.044 seconds with 2 issues.
✘ Suite "CloudKit Delete Truthiness" failed after 0.165 seconds with 2 issues.
✘ Test run with 5 tests in 1 suite failed after 0.167 seconds with 2 issues.
** TEST FAILED **
```

Two independent detections fired on the swallow: (1) :140 — `Issue.record("Expected
deleteAllMeasurements to throw…")` because the swallowed failure never propagated;
(2) :149 — the split-brain check `(remaining.count → 0) == 1` because the swallowed
failure let the local wipe proceed. The other 4 tests (spy-contract prongs) stayed
green, exactly as designed.

**Revert:** `git checkout -- StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`
→ `git status --porcelain` for the file = 0 lines; `git diff HEAD -- <file>` = 0 lines
(byte-identical to the committed tree; the mutation never appears in any commit).

**GREEN run** (identical command): `FINAL_GREEN_EXIT_CODE=0` —
`✔ Suite "CloudKit Delete Truthiness" passed`, `✔ Test run with 5 tests in 1 suite passed`,
`** TEST SUCCEEDED **`.

## Accomplishments

- New ungated suite `DataDeleterCloudKitTruthinessTests` (5 tests, all green) carrying the three DATA-04 prongs: genuine failure (throwing double → `DeletionError.cloudKitError`, underlying error preserved), truthiness canary (lying double reports success while `remainingRecords` observes survivors — emptiness established only by querying, never by the success return), honest drain (seeded store empties through the seam)
- Boundary prong distinguishes zero survivors from exactly one survivor by exact integer count; idempotency prong proves an empty-store re-run of `deleteAllMeasurements` completes without throwing
- `SeededCloudKitResetService` double: `@MainActor final class`, `CloudKitResetServiceProtocol` + `@unchecked Sendable`, seeded store keyed by `CloudKitRecordType`, all five protocol methods routed through one behavior resolver, `remainingRecords` as an exact `Int` sum — constructor-injected only, no statics (WINDOWS #12)
- Mutation red/green proof recorded above: the suite is a real regression gate, not a green rubber stamp
- File registered in the StressMonitorTests target (PBXBuildFile + PBXFileReference + group child + Sources phase; IDs A026/B026) — orphaned-dirs trap avoided

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the ungated truthiness spy suite and prove it green** — `77698de` (test)
2. **Task 2: Mutation red-proof** — no committed changes by design (temporary mutation reverted; evidence recorded in this SUMMARY)

**Plan metadata:** (see docs commit below)

## Files Created/Modified

- `StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift` — the DATA-04 regression home: ungated suite + SeededCloudKitResetService double
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — registered the new file in the StressMonitorTests target

## Decisions Made

- Suite placement: new sibling file rather than a new suite inside `DataDeletionConsolidationTests.swift` — the plan allowed either; the sibling keeps the ungated suite clear of the #8-gated file's GSD_CI lineage and of its WINDOWS-#8-crash-associated host behavior
- One double instead of three: a single `SeededCloudKitResetService` with `.lying`/`.throwing`/`.draining` behaviors covers all prongs while keeping the survivor semantics (store + `remainingRecords`) in one place
- Tracer feedback gate: executed as Task 2's mutation run (the plan's own end-to-end gate design; plan is `autonomous: true`) rather than pausing for a mid-plan human verify — Task 1's `<verify>` had already run green and Task 2 proves the slice mechanically
- Suite doc comment wording avoids the literal `.enabled(if:)`/`.disabled(` strings so the phase-end trust-gate grep stays signal-clean

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 1 acceptance grep for gating constructs initially returned 1 — the suite's own doc comment contained the literal `.enabled(if:)` while explaining that the suite is ungated. Reworded the comment ("no enable/disable trait on the @Suite"); re-check returned 0. Caught and fixed inside the acceptance-criteria loop before the task commit.
- The plan's Task 2 verify one-liner (`wc -l | grep -q '^0$'`) fails spuriously on macOS: BSD `wc` pads its output with leading spaces, so `^0$` never matches. Ran the same check as `[ "$(… | wc -l | tr -d ' ')" = "0" ]` (semantically identical assertion); the plan's `<verification>` intent (0 = file clean) is fully met.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DATA-04's regression seam exists and is proven: a lying/throwing CloudKit double is injectable through `DataDeleterService.init`, the ungated suite detects both failure modes, and the mutation run shows the suite goes red when the orchestrator swallows failures
- The suite is CI-visible by construction (no gate trait; ran green under `TEST_RUNNER_GSD_CI=1`)
- Ready for the wave-1 sibling plans (WR-04/WR-03 money-path fixes in 02-02/02-03); DATA-01's live two-surface verification (02-06) can cite this suite's green run as its machine-verified backstop
- Live propagation of real CloudKit failures remains backstopped by DATA-01 evidence at phase end (per the plan's threat-model note — the canary prong enforces the query-based contract; the live path is separately verified)

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-03*

## Self-Check: PASSED

- Created files exist on disk: DataDeleterCloudKitTruthinessTests.swift, project.pbxproj (modified), 02-01-SUMMARY.md
- Task commit exists: 77698de (test(02-01))
- `git log --oneline --all --grep="02-01"` ≥ 1 commit after the docs commit
- All task acceptance criteria re-run and passing: suite green under -only-testing with TEST_RUNNER_GSD_CI=1 (5/5); pbxproj PBXBuildFile + PBXFileReference entries present; gating-construct grep = 0; RequestCaptureURLProtocol grep = 0; swiftlint clean on the new file; DataDeleterService.swift porcelain = 0 (mutation never committed)
- Plan-level verification: mutation red (exit 65, prong 1 failed) recorded above; suite green post-revert (exit 0)
