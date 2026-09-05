---
phase: 02-delete-correctness-test-suite-trust
plan: 03
subsystem: payments
tags: [storekit2, iap, wr-03, launch-argument, di-wiring, swift-testing, xcodebuild]

# Dependency graph
requires:
  - phase: 02-delete-correctness-test-suite-trust
    provides: CI-parity test invocation (TEST_RUNNER_GSD_CI=1 env form) and the red/green commit-gate pattern established in plans 02-01/02-02
provides:
  - DEBUG builds default to the REAL StoreKit service at BOTH wiring sites (app factory + environment fallback); MockStoreKitService resolves only behind the explicit -mock-iap launch-argument opt-in
  - MockIAPMode shared decision helper (DemoMode-shaped, injectable arguments) consulted by both wiring sites
  - StoreKitServiceWiringTests — the WR-03 config-resolution pin (3 tests, #if DEBUG, asserts through the factory)
  - Widened factory seam — StressMonitorApp.makeStoreKitService is internal with an arguments parameter
affects: [04-submission-packaging, paywall/premium surfaces, DATA-01 evidence note (suite-trust premise), ENV-03 requirement closure]

# Actuals (#2632) — pairs with the plan's estimate (32000) to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 2690   # git diff 7ed8116^..43a3a13 = 10,760 chars / 4 (production commits only)
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Launch-arg opt-in with an injectable decision helper: MockIAPMode.isEnabled(arguments:) defaults to ProcessInfo.processInfo.arguments so production keeps the DemoMode shape while tests drive both outcomes — the pattern for any future DEBUG-only behavior toggle"
    - "Minimal testability seam for a private factory: widen to internal + add an arguments parameter rather than extracting a resolver type — the pin asserts through the real factory, never by constructing services directly (Pitfall 4)"

key-files:
  created:
    - StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift
  modified:
    - StressMonitor/StressMonitor/StressMonitorApp.swift
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "Seam-widening (planner-flagged discretion): internal static factory + arguments parameter, NOT an extracted resolver type — minimal diff, assertion still goes through the factory; the #else Release branch stays private and byte-unchanged"
  - "Opt-in flag named -mock-iap via MockIAPMode (DemoMode precedent at StressMonitorApp.swift:6-10, placed directly below DemoMode so launch-arg opt-ins live together)"
  - "Site B uses a Swift if-expression in the static let initializer (module-wide default MainActor isolation makes the StoreKitService construction legal, matching how the Release branch already compiled)"

patterns-established:
  - "One named condition per wiring concern: both StoreKit resolution sites consult MockIAPMode; a repo grep proving no other MockStoreKitService construction exists in app sources is the containment check"
  - "Wiring pins wrap in #if DEBUG and assert resolution through the factory/environment — the mock type exists nowhere else, so Release exclusion is by construction"

requirements-completed: [ENV-03]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "WR-03 wiring pin suite: DEBUG factory resolves the real service absent the opt-in, the mock with it, and the environment default resolves the real service absent the opt-in (registered in the StressMonitorTests target, #if DEBUG)"
    requirement: ENV-03
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift#StoreKit Service Wiring (3/3 green: factory absent-flag, factory opt-in, environment default)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both wiring sites flipped behind one named condition: StressMonitorApp.makeStoreKitService and StoreKitServiceKey.defaultValue resolve MockStoreKitService only when -mock-iap is present, real StoreKitService otherwise"
    requirement: ENV-03
    verification:
      - kind: unit
        ref: "combined -only-testing run: StoreKitServiceWiringTests + CreditPurchaseFlowTests = 16/16 passed (no money-path suite depended on the mock default)"
        status: pass
      - kind: other
        ref: "repo grep over StressMonitor/StressMonitor: exactly two MockStoreKitService( constructions, both inside MockIAPMode.isEnabled branches (StressMonitorApp.swift:271, StoreKitServiceEnvironment.swift:19); definition file excepted"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release behavior unchanged and unmockable: both #else branches byte-unchanged (context lines in the GREEN diff); MockStoreKitService stays #if DEBUG-only by construction"
    requirement: ENV-03
    verification:
      - kind: other
        ref: "git diff HEAD~1 43a3a13 inspection: #else branches appear only as unchanged context; single-argument Release factory signature untouched"
        status: pass
    human_judgment: false

# Metrics
duration: 6 min
completed: 2026-09-03
status: complete
---

# Phase 2 Plan 03: DEBUG Real-Default StoreKit Wiring (WR-03) Summary

**Both StoreKit wiring sites (app factory + PaywallView environment fallback) now default DEBUG to the real StoreKitService behind one shared MockIAPMode launch-arg opt-in, pinned red-first by a 3-test wiring suite**

## Performance

- **Duration:** 6 min (started 2026-09-03T16:26:29Z, completed 2026-09-03T16:32:27Z)
- **Tasks:** 2 (both TDD: RED then GREEN)
- **Files modified:** 4 (1 created, 3 modified)
- **Commits:** 2 production + 1 docs

## Accomplishments

- **RED (7ed8116):** `StoreKitServiceWiringTests` (#if DEBUG, registered in the StressMonitorTests target via pbxproj A027/B027) failed exactly as designed against the mock-default wiring — `factory resolves the real service absent the -mock-iap opt-in` and `environment default resolves the real service absent the opt-in` both FAILED (2 issues recorded; `EnvironmentValues().storeKitService → MockStoreKitService` quoted in the failure), while the opt-in case passed. Commit also landed the compile-only seam: `MockIAPMode` decision helper (`-mock-iap`, injectable `arguments`) and `makeStoreKitService` widened to `internal static` with an arguments parameter — zero behavior change.
- **GREEN (43a3a13):** Both wiring sites flipped in ONE commit behind the shared `MockIAPMode.isEnabled` condition — site A `StressMonitorApp.makeStoreKitService(:243-253 region)` and site B `StoreKitServiceKey.defaultValue` (the fallback `PaywallView` reads at :20). The mock resolves only when `-mock-iap` is present; DEBUG otherwise constructs the real `StoreKitService`. Release `#else` branches byte-unchanged.
- **Money-path trust held:** wiring suite + CreditPurchaseFlowTests ran green together (16/16) — no suite depended on the mock default; tests already inject their doubles via DI, per the locked ENV-03 decision.
- **Containment proven by grep:** the only `MockStoreKitService(` constructions in app sources are the two behind `MockIAPMode.isEnabled` — no third site exists.

## Task Commits

Each task was committed atomically (TDD: RED → GREEN; no REFACTOR needed — the seam landed minimal):

1. **Task 1: RED — wiring pin suite asserting the real service resolves absent the override** - `7ed8116` (test)
2. **Task 2: GREEN — flip both wiring sites behind one named opt-in condition** - `43a3a13` (feat)

**Plan metadata:** see final docs commit below.

## Files Created/Modified

- `StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift` (NEW) — the WR-03 config-resolution pin: 3 tests asserting through the factory/environment with injected arguments, `#if DEBUG`-wrapped, plain `@Suite` (no gating constructs — CI must see it)
- `StressMonitor/StressMonitor/StressMonitorApp.swift` — `MockIAPMode` helper below `DemoMode` (:6-10 precedent); `makeStoreKitService` internal + arguments-injectable, flipped to real-default in DEBUG
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift` — site B `defaultValue` flipped behind the same condition (if-expression initializer)
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — suite registered (PBXBuildFile + PBXFileReference + group child + Sources phase, IDs A027/B027)

## Decisions Made

- **Seam mechanism (planner-flagged executor discretion, Open Question 4):** widened the existing factory (`private` → `internal static`, plus `arguments: [String] = ProcessInfo.processInfo.arguments`) rather than extracting a separate resolver type — minimal diff, and the pin still asserts through the real factory (Pitfall 4 honored). The `#else` Release branch stays `private` and byte-identical.
- **Flag/name:** `-mock-iap` via `enum MockIAPMode`, placed directly below `DemoMode` in StressMonitorApp.swift so both launch-arg opt-ins are discoverable together; helper takes injectable arguments because a test process cannot change its own launch args.
- **Site B initializer shape:** Swift if-expression inside the `static let` — legal under the app module's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (the same reason the Release branch's direct `StoreKitService(premiumState:)` construction already compiled).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Compile error: if-expression used the function reference instead of calling it**
- **Found during:** Task 2 (GREEN first run)
- **Issue:** `static let defaultValue = if MockIAPMode.isEnabled { ... }` — `isEnabled` is a static func; Swift reported `function produces expected type 'Bool'; did you mean to call it with '()'?`
- **Fix:** Call it: `if MockIAPMode.isEnabled() { ... }` (default-arguments call site)
- **Files modified:** StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift
- **Verification:** GREEN run went 16/16 green (`** TEST SUCCEEDED **`)
- **Committed in:** 43a3a13 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking compile fix)
**Impact on plan:** None on scope or design — one-call-site syntax fix inside the planned change.

## Issues Encountered

None — the RED run failed for exactly the designed reason (2 absent-flag issues against the mock-default wiring), and the GREEN run passed first try after the one compile fix.

## User Setup Required

None — the `-mock-iap` opt-in is a developer convenience (Edit Scheme → Run → Arguments), not a required configuration.

## TDD Gate Compliance

| Gate | Commit | Evidence |
|------|--------|----------|
| RED | 7ed8116 `test(02-03)` | 2 absent-flag tests FAILED pre-flip (xcresult enumeration: `Failed \| factory resolves the real service absent the -mock-iap opt-in`, `Failed \| environment default resolves the real service absent the opt-in`, `Passed \| factory resolves the mock when the -mock-iap opt-in is present`) |
| GREEN | 43a3a13 `feat(02-03)` | Suite 3/3 + CreditPurchaseFlowTests 13/13 = 16/16 passed under TEST_RUNNER_GSD_CI=1, iPhone 17, `-parallel-testing-enabled NO` |
| REFACTOR | — not needed | Seam landed minimal in RED; nothing to clean |

## Next Phase Readiness

- WR-03 closed by fix; with WR-04 (02-02) already landed, **ENV-03 is fully dispositioned — fixed, both advisories** — and ready to mark complete (02-02 held the checkbox on the shared-ID gate until this SUMMARY existed).
- Remaining phase-2 plans: 02-04 (ENV-01/ENV-02 bounded re-diagnosis), 02-05 (BUILD-04 docs), 02-06 (DATA-01 live evidence).
- Note for demo runs: developers wanting the no-op purchase path now pass `-demo-mode -mock-iap` together (DemoMode cycles stress data; MockIAPMode mocks IAP) — worth a line in BUILD-04's doc-truth pass if demo instructions exist.

## Self-Check: PASSED

- Files: `StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift` FOUND; `02-03-SUMMARY.md` FOUND
- Commits: RED `7ed8116` FOUND, GREEN `43a3a13` FOUND, docs `a8cd246` FOUND (contains exactly the 4 metadata files — no unrelated staging)
- Pre-existing working-tree modifications (11 files incl. `.planning/WINDOWS.md`, codebase map, AGENTS.md, CLAUDE.md) left untouched
- TDD gates: `test(02-03)` precedes `feat(02-03)` in git log

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-03*
