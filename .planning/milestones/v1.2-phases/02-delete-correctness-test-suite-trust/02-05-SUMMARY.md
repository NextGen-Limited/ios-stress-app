---
phase: 02-delete-correctness-test-suite-trust
plan: 05
subsystem: docs
tags: [documentation, ci-parity, agents-md, testing-docs]

# Dependency graph
requires:
  - phase: 02-04
    provides: final gate state (GSD_CI/TEST_RUNNER_GSD_CI gates removed, un-gated form is canonical) — determined which invocation form this plan had to document
provides:
  - BUILD-04 closed — AGENTS.md canonical CI-parity xcodebuild test block (flag-for-flag mirror of _test.yml), docs/TESTING.md reduced to a one-liner cross-reference, INFOPLIST_KEY doc-truth note
affects: [02-06]

# Actuals (#2632)
actuals:
  tokens: 6500
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single canonical invocation + pointer-only cross-references: AGENTS.md owns the full xcodebuild command; docs/TESTING.md and _test.yml comments only point at it — prevents the two-invocations-that-diverge failure mode (T-02-09)."

key-files:
  created: []
  modified:
    - AGENTS.md
    - docs/TESTING.md

key-decisions:
  - "AGENTS.md All-tests block extended to full flag-for-flag CI parity (added -derivedDataPath, -resultBundlePath, -skipPackagePluginValidation, -maximum-concurrent-test-simulator-destinations 1) rather than just the previously-present destination/parallel-testing subset — the plan's objective and prohibition ('no documented invocation diverges from what CI runs') read as requiring the full flag set, not just the three flags named in the truths list."
  - "Reconciled with, rather than duplicated, the existing Testing quirks GSD_CI history note (added by the 02-04 executor as a Rule-1 deviation) — the new All-tests block carries a short inline comment pointing at that note instead of repeating the TEST_RUNNER_GSD_CI history."
  - "docs/TESTING.md Overview section's stale 5-file coverage list and wrong bundle path (`StressMonitorTests/` — the orphaned root-level dir, not the real `StressMonitor/StressMonitorTests/`) were also replaced, not just the 3 plan-named regions (command recipe, file table, CI-validation claim) — same staleness pattern the plan explicitly targeted, directly adjacent to content already being rewritten under the locked 'replace, not extend' decision; not scope creep since the Overview text was making the identical false claim the file table made two sections later."
  - "_test.yml required no edit: its existing comment (:177-180, added by 02-04) already accurately reflects the post-02-04 gate-removal reality — verified by direct read, not assumed."

requirements-completed: [BUILD-04]

coverage:
  - id: D1
    description: "AGENTS.md All-tests xcodebuild block mirrors _test.yml's Run Tests step flag-for-flag (project, scheme, destination, derivedDataPath, resultBundlePath, skipPackagePluginValidation, parallel-testing-enabled NO, maximum-concurrent-test-simulator-destinations, signing-off pair)"
    requirement: BUILD-04
    verification:
      - kind: other
        ref: "grep -n \"parallel-testing-enabled NO\" AGENTS.md .github/workflows/_test.yml — hits in both (AGENTS.md:35, _test.yml:191)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every GSD_CI mention in AGENTS.md is the TEST_RUNNER_-prefixed exported-env-var form, never an xcodebuild argument"
    verification:
      - kind: other
        ref: "grep -n \"TEST_RUNNER_GSD_CI\" AGENTS.md .github/workflows/_test.yml — AGENTS.md:55 (Testing quirks history note), _test.yml:177 (comment); neither shows it as a CLI arg"
        status: pass
    human_judgment: false
  - id: D3
    description: "INFOPLIST_KEY doc-truth note exists in AGENTS.md, folding in the Phase-1 UIBackgroundModes finding"
    verification:
      - kind: other
        ref: "grep -c \"INFOPLIST_KEY\" AGENTS.md → 1 (new doc-truth paragraph at AGENTS.md:51)"
        status: pass
    human_judgment: false
  - id: D4
    description: "docs/TESTING.md invocation content reduced to a one-liner AGENTS.md cross-reference; no divergent command recipe remains"
    requirement: BUILD-04
    verification:
      - kind: other
        ref: "grep -n \"AGENTS.md\" docs/TESTING.md → 5 hits (Overview x2, Running Tests x2, CI Testing x1); grep -c \"xcodebuild test\" docs/TESTING.md → 1 (pointer-context prose only, zero command blocks)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Falsified 'CI runs build validation, not full test execution' claim removed from docs/TESTING.md"
    verification:
      - kind: other
        ref: "grep -c \"build validation (not full test execution\" docs/TESTING.md → 0"
        status: pass
    human_judgment: false
  - id: D6
    description: "_test.yml diff is comment-only (if any) — no step/env/flag changes beyond what 02-04 already applied"
    verification:
      - kind: other
        ref: "git diff --stat .github/workflows/_test.yml → empty (no changes made; existing :177-180 comment already accurate post-02-04)"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-09-04
status: complete
---

# Phase 2 Plan 5: BUILD-04 Documentation Truth (CI-Parity Invocation) Summary

**AGENTS.md is now the single canonical, flag-for-flag CI-parity `xcodebuild test` invocation with an INFOPLIST_KEY doc-truth note; docs/TESTING.md's three stale command recipes and file table were replaced with pointer-only cross-references — zero divergence risk between what CI runs and what the docs tell a human to run.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2
- **Files modified:** 2 (AGENTS.md, docs/TESTING.md — `.github/workflows/_test.yml` required no change)

## Accomplishments

- Rewrote AGENTS.md's "All tests" xcodebuild block to match `.github/workflows/_test.yml`'s Run Tests step flag-for-flag: added `-derivedDataPath build`, `-resultBundlePath TestResults.xcresult`, `-skipPackagePluginValidation`, `-maximum-concurrent-test-simulator-destinations 1` alongside the previously-present destination form and `-parallel-testing-enabled NO`.
- Reconciled the new block with the existing (02-04-added) Testing quirks GSD_CI history note via an inline comment cross-reference, avoiding duplication.
- Added a doc-truth paragraph: custom `INFOPLIST_KEY_*` build settings never merge into product plists on this project's toolchain — the `Info.plist` file is the source of truth — citing the Phase-1 `INFOPLIST_KEY_UIBackgroundModes` finding (background fetch/processing has silently never shipped).
- Gutted docs/TESTING.md's three divergent `xcodebuild test` command blocks (Running Tests + Running Specific Tests) and the stale 5-file Test Files table, replacing them with a single AGENTS.md cross-reference plus prose for the `-only-testing:` single-class/single-method pattern.
- Removed the falsified CI Testing claim ("GitHub Actions runs build validation (not full test execution yet)") and replaced it with an accurate one-liner: CI runs the full `StressMonitorTests` suite via the same AGENTS.md-documented invocation.
- Verified `.github/workflows/_test.yml`'s existing comment (:177-180, added by the 02-04 executor) already accurately describes the post-02-04 gate-removal state — no edit required.

## Task Commits

1. **Task 1: AGENTS.md canonical CI-parity invocation (env-var form) + INFOPLIST_KEY doc-truth note** — `0b0b5e6` (docs)
2. **Task 2: docs/TESTING.md replace-by-reference + _test.yml cross-reference verification** — `e3a4b87` (docs)

## Files Created/Modified

- `AGENTS.md` — "Build & test" All-tests block rewritten to flag-for-flag CI parity (13 insertions, 3 deletions); new doc-truth paragraph on `INFOPLIST_KEY_*` non-merging behavior
- `docs/TESTING.md` — Overview/Running Tests/Running Specific Tests/Test Files sections collapsed into a pointer-only Overview + Running Tests pointing at AGENTS.md; CI Testing section's falsified claim replaced (7 insertions, 78 deletions)

## Verification Evidence

### Task 1 grep (quoted)

```
$ grep -n "parallel-testing-enabled NO" AGENTS.md .github/workflows/_test.yml
AGENTS.md:35:  -parallel-testing-enabled NO \
.github/workflows/_test.yml:191:            -parallel-testing-enabled NO \

$ grep -n "TEST_RUNNER_GSD_CI" AGENTS.md .github/workflows/_test.yml
AGENTS.md:55:- `DataDeletionConsolidationTests`/`CharacterEntitlementSyncTests` no longer gate on `GSD_CI`/`TEST_RUNNER_GSD_CI` (removed 2026-09-04, 02-04/ENV-01/ENV-02): ...
.github/workflows/_test.yml:177:      # 2026-09-04 (02-04/ENV-01): TEST_RUNNER_GSD_CI env gate removed here —

$ grep -c "INFOPLIST_KEY" AGENTS.md
1
GREP_DONE
```

### Task 2 grep (quoted)

```
$ grep -n "AGENTS.md" docs/TESTING.md
10:...(see `AGENTS.md` → "Orphaned code").
12:...see `AGENTS.md` for the current build/test setup rather than a fixed file list here.
18:...is documented once, in `AGENTS.md` under "Build & test"...
21:...append `-only-testing:StressMonitorTests/<Suite>` ... to the AGENTS.md command...
87:...the same invocation documented in `AGENTS.md`. CI does not skip test execution.

$ grep -c "xcodebuild test" docs/TESTING.md
1

$ grep -c "build validation (not full test execution" docs/TESTING.md
0

$ git diff --stat .github/workflows/_test.yml
(empty — no changes)
VERIFY_DONE
```

## Decisions Made

- **Full flag-for-flag parity, not just the 3 named flags:** the plan's `must_haves.truths` explicitly names project/scheme/destination/parallel-testing/env-var as the minimum bar, but the objective and prohibition text ("no documented invocation diverges from what CI runs") and the action text ("Do not invent new commands; mirror _test.yml exactly") point at the fuller CI block. Added all 4 additional flags CI actually passes (`-derivedDataPath`, `-resultBundlePath`, `-skipPackagePluginValidation`, `-maximum-concurrent-test-simulator-destinations 1`) so a human running the documented command gets byte-identical xcodebuild behavior to CI, not just a matching destination/parallelism subset.
- **docs/TESTING.md Overview staleness treated as in-scope:** the plan named 3 specific line ranges (command recipe, file table, CI-validation claim) as falsified. The Overview section's "Current test coverage focuses on: [5 files]" bullet list and its `StressMonitorTests/` bundle-path claim (the orphaned root-level directory per AGENTS.md, not the real `StressMonitor/StressMonitorTests/`) make the identical false claim the file table makes two sections later. Since the plan's own action text instructs "point at AGENTS.md" for still-true-content-outside-scope and this content was not still-true, replacing it was execution of the plan's stated rule, not scope creep.
- **No _test.yml edit:** read the existing comment at :177-180 before touching anything; it already states the post-02-04 reality accurately (env gate removed, container-lifetime bug was the real cause). Left byte-unchanged per the plan's explicit "if kept, leave as-is" branch.

## Deviations from Plan

None — plan executed exactly as written (with the two in-scope scoping calls documented above under Decisions Made, both explicitly licensed by the plan's own action text).

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- BUILD-04 fully closed: AGENTS.md is the canonical CI-parity invocation source, docs/TESTING.md is pointer-only with zero divergence risk, `.github/workflows/_test.yml`'s comment already matches reality, and the INFOPLIST_KEY doc-truth note is recorded.
- No blockers for 02-06 (DATA-01 + phase trust gate) — this plan's doc-truth work is a prerequisite input the phase-end trust gate references but does not itself gate.

## Self-Check: PASSED

- `git log --oneline --all | grep -E "0b0b5e6|e3a4b87"` → both commits found.
- `AGENTS.md`, `docs/TESTING.md` — both FOUND, both reflect the described edits (re-read after each edit).
- Task 1 and Task 2 `<verify>` grep commands re-run above with quoted, matching output.

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-04*
