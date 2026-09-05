---
phase: 02-delete-correctness-test-suite-trust
plan: "02"
subsystem: payments
tags: [storekit, storekit2, iap, consumables, tdd, swift-testing, transaction-lifecycle]

requires:
  - phase: v1.1-02-credits-system-iap-transition
    provides: PurchaseTransactionHandle protocol seam, CreditPurchaseFlowTests pinning home (FakePurchaseTransaction.finishCallCount), completePurchase grant choke point
provides:
  - WR-04 fix — the updates-listener .unverified branch no longer finishes transactions (Apple-canonical ignore-without-finish, log on the ignore path)
  - Internal protocol-typed seam handleUnverifiedTransaction(_:) (@testable-visible) driving the unverified branch with FakePurchaseTransaction
  - Two red-first pins: unverified delivery -> finishCallCount == 0; redelivered unverified -> still 0
  - Five-site finish-reachability audit (doc comment on the listener entry + this SUMMARY)
affects: [02-03 (WR-03 DEBUG mock wiring), ENV-03 disposition, Phase 4 submission readiness, TestFlight money path]

actuals:
  tokens: 1362   # chars/4 over the realized diff (5447 chars across the 2 files, 5ff33e2..HEAD)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Protocol-typed branch-extraction seam: a VerificationResult<Transaction> branch that tests must drive extracts into an internal method typed on the existing handle protocol, because VerificationResult<Transaction> has no test-constructible payload (no public Transaction init)"

key-files:
  created: []
  modified:
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
    - StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift

key-decisions:
  - "Extracted internal protocol-typed handleUnverifiedTransaction(_:) instead of widening handle(transactionVerification:) — widening alone is a dead end: VerificationResult<Transaction> cannot be constructed in unit tests, so a widened signature still could not be driven by FakePurchaseTransaction"
  - "The four completePurchase finish sites are verified-only by construction (checkVerified throws on .unverified before reachability; handle(transaction:) entered only from .verified) — delivered as a written reachability note, zero code change to those sites (Pitfall 5)"
  - "Ignore-path observability via the repo Logger convention (subsystem com.stressmonitor.app, category StoreKitService) — warning level: an unverified delivery is a validation-failure signal"

patterns-established:
  - "Red-first pinning of irreversible-action prohibitions: assert the forbidden call count stays 0 across single and repeated deliveries (idempotent observation), then delete the offending call"

requirements-completed: []   # ENV-03 is declared by this plan AND 02-03 (shared) — shared-ID gate holds the checkbox until 02-03 lands; nothing this plan alone completes

coverage:
  - id: D1
    description: "Red-first WR-04 pinning tests — an unverified transaction delivered through the listener entry finishes zero times, and stays at zero across redelivery"
    requirement: ENV-03
    verification:
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#unverifiedDeliveryNeverFinishesTransaction
        status: pass
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#redeliveredUnverifiedStillFinishedZeroTimes
        status: pass
    human_judgment: false
  - id: D2
    description: "The fix — the .unverified branch contains no finish call; it logs and leaves the transaction unfinished for Transaction.updates redelivery (Apple-canonical)"
    requirement: ENV-03
    verification:
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift (suite 13/13, -only-testing run)
        status: pass
      - kind: other
        ref: git diff 5ff33e2..HEAD — only finish() removal is the unverified branch; completePurchase byte-identical
        status: pass
    human_judgment: false
  - id: D3
    description: "Five-site finish reachability audit — why the four completePurchase finishes execute only for verified transactions and only the listener's .unverified branch was the defect"
    requirement: ENV-03
    verification:
      - kind: other
        ref: git diff — completePurchase function body byte-identical across the plan (awk-extracted, diff empty)
        status: pass
    human_judgment: true
    rationale: "The verified-only-by-construction argument is static reachability reasoning (checkVerified throws; .verified-only entry); the byte-diff machine-checks that the four sites are untouched and the existing pins cover their behavior, but the construction argument itself is a code-reading claim no test executes end-to-end without a StoreKitTest session (disabled in this repo)"
  - id: D4
    description: "No regressions — all existing verified-path pins (CreditPurchaseFlowTests :181-357 legacy pins) stay green"
    verification:
      - kind: unit
        ref: TEST_RUNNER_GSD_CI=1 xcodebuild test … -only-testing:StressMonitorTests/CreditPurchaseFlowTests — Test run with 13 tests in 1 suite passed
        status: pass
      - kind: other
        ref: swiftlint — StoreKitService.swift violation classes identical pre/post plan (pre-existing cyclomatic_complexity + file_length only)
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-03
status: complete
---

# Phase 2 Plan 2: Unverified Transactions Are Never Finished (WR-04) Summary

**StoreKit updates-listener's `.unverified` branch no longer finishes transactions — Apple-canonical ignore-without-finish (log + redelivery retry contract), pinned red-first by two `finishCallCount == 0` tests through an extracted `@testable` seam, with a five-site finish-reachability audit delivered as a doc comment.**

## Performance

- **Duration:** 9 min (518s)
- **Started:** 2026-09-03T16:06:49Z
- **Completed:** 2026-09-03T16:15:27Z
- **Tasks:** 2
- **Files modified:** 2

## TDD Cycle

### RED — failing pin (commit `b60d396`)

Compile-only seam first (no behavior change): the `.unverified` branch of `handle(transactionVerification:)` extracts into internal `handleUnverifiedTransaction(_:)` typed on `PurchaseTransactionHandle`, body moved verbatim (finish included).

Two pins added to `CreditPurchaseFlowTests` (constructor-injected fakes only, per-test UserDefaults suite isolation via `makeState()` — no `RequestCaptureURLProtocol` statics):

- **`unverifiedDeliveryNeverFinishesTransaction`** — FAILED as required:
  `Expectation failed: (fake.finishCallCount → 1) == 0` (CreditPurchaseFlowTests.swift:264:9)
- **`redeliveredUnverifiedStillFinishedZeroTimes`** — FAILED as required:
  `Expectation failed: (fake.finishCallCount → 2) == 0` (CreditPurchaseFlowTests.swift:275:9)

RED run: `Test run with 13 tests in 1 suite failed … with 2 issues` — only the two new pins failed; all 11 pre-existing tests passed; no existing test was modified or deleted.

### GREEN — the fix + reachability note (commit `9598de6`)

`handleUnverifiedTransaction(_:)` drops `await transaction.finish()`, replacing it with a `Logger.warning` and a doc comment citing `Transaction.updates` redelivery as the retry path (mirroring the `handle(transaction:jwsRepresentation:)` contract, Apple's canonical observer sample, and the in-file `.unverified: break` arms of `fetchPurchaseHistory()`/`refreshEntitlements()`). Reachability-audit doc comment added on the listener entry (full text below). Adds `import os` + `private static let logger` per the repo's FirebaseBootstrap convention.

GREEN run: `Test run with 13 tests in 1 suite passed` (11 existing pins + 2 new pins).

### REFACTOR

Not needed — the seam landed in its final shape during RED/GREEN; nothing to clean.

## TDD Gate Compliance

- RED gate: `b60d396` `test(02-02): add failing pin for unverified transactions` ✓
- GREEN gate: `9598de6` `feat(02-02): stop finishing unverified transactions` ✓
- Both gates present, in order, author `Phuong Doan`, no AI attribution. Compliant.

## WR-04 reachability audit

All five `finish()` sites in `StoreKitService` and their reachability:

| # | Site (pre-plan line) | Reached by | Verified-only? | Disposition |
|---|---|---|---|---|
| 1 | `:317` — listener `.unverified` branch | `Transaction.updates` delivering an unverified result | **No — unverified-reachable: the bug** | FIXED: finish deleted; log + ignore; redelivery is the retry path |
| 2 | `:375` — `completePurchase` revoked-pack arm | `completePurchase` | Yes, by construction | Byte-unchanged; pinned by `revokedPackFinishesWithoutRedemption` / `updatesListenerRevokedPackBreaksRetryLoop` |
| 3 | `:379` — `completePurchase` pack-after-redeem arm | `completePurchase` | Yes, by construction | Byte-unchanged; pinned by `packPurchaseRedeemsBeforeFinishAndAppliesBalance` (redeem-before-finish ordering) |
| 4 | `:388` — `completePurchase` revoked-subscription arm | `completePurchase` | Yes, by construction | Byte-unchanged; pinned by `revokedSubscriptionPostsDemotionSignalWithoutGranting` |
| 5 | `:401` — `completePurchase` subscription tail | `completePurchase` | Yes, by construction | Byte-unchanged; pinned by `subscriptionTakesLegacyPath` / `expiredSubscriptionNeverSyncs` |

**The construction argument (why sites 2–5 are verified-only):** `purchase(_:)` and `purchase(pack:)` run `checkVerified` (`:158`/`:189`, implementation `:439-446`) which **throws** `StoreKitError.receiptValidationFailed` on `.unverified` before `completePurchase` is ever reached; `handle(transaction:jwsRepresentation:)` (`:407`) — the only other route into `completePurchase` — is entered **only from the `.verified` case** of the listener entry (`:311-312`). Therefore no code path can deliver an unverified transaction to sites 2–5; their finishes are intentional queue hygiene (drain revoked/refunded/legacy-subscription transactions) and remain test-pinned. The single unverified-reachable finish was site 1 — the defect this plan removes. No runtime verification was added inside `completePurchase` (the four sites are not bugs — RESEARCH Pitfall 5; adding checks there would re-architect the grant choke point).

Machine-check of the confinement: `git diff 5ff33e2..HEAD` over `StoreKitService.swift` contains exactly one removed `await transaction.finish()` (site 1); the `completePurchase` function body, awk-extracted from both revisions, diffs **empty** (37 lines identical).

The same audit lives as a doc comment on `handle(transactionVerification:)` (the listener entry) in `StoreKitService.swift`.

## Accomplishments

- WR-04 closed: unverified transactions are never finished anywhere in the service — the only unverified-reachable finish site is deleted
- Red-first pins prove the prohibition (single delivery + idempotent redelivery observation), all existing verified-path pins stay green (13/13)
- Five-site reachability audit delivered as the ENV-03 written deliverable (doc comment + this record), with the four verified-only sites proven byte-unchanged
- No new SwiftLint violations (pre/post comparison on the touched file: identical violation classes — pre-existing `cyclomatic_complexity` on untouched `refreshEntitlements()` and `file_length`, already violated at 529 lines pre-plan)

## Task Commits

1. **Task 1: RED — pin test asserting an unverified transaction is never finished** - `b60d396` (test)
2. **Task 2: GREEN — remove the finish from the unverified branch + five-site reachability note** - `9598de6` (feat)

**Plan metadata:** see final docs commit below.

## Files Created/Modified

- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` — unverified branch fixed (finish → log), reachability-audit doc comment on the listener entry, `import os` + static logger, extracted `handleUnverifiedTransaction(_:)` seam
- `StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift` — two new pin tests under "Unverified deliveries are never finished (listener entry)" MARK; existing tests untouched

## Decisions Made

- **Extracted internal protocol-typed seam over access widening** (executor's discretion granted by the plan): widening `handle(transactionVerification:)` to `internal` alone cannot work — `VerificationResult<Transaction>` has no test-constructible payload (no public `Transaction` initializer), so the fake could never drive the branch. The extracted `handleUnverifiedTransaction(_:)` is the minimal seam the real listener delegates to; additive and `@testable`-visible only.
- **The four `completePurchase` finish sites stay untouched** — verified-only by construction; the deliverable for them is this written audit, not code changes (Pitfall 5 prohibition honored: diff machine-verified).
- **Logger over silent break** — the plan asked for a log on the ignore path; used the repo's `Logger(subsystem: "com.stressmonitor.app", category:)` convention at `warning` level (an unverified delivery is a validation-failure signal worth surfacing).

## Deviations from Plan

**1. [Compliance — user AGENTS.md rule] Finding-code label kept out of Swift comments**
- **Found during:** Task 2 (reachability note)
- **Issue:** The plan titles the deliverable "WR-04 reachability audit" and the natural rendering would put the `WR-04` finding code into the Swift doc comment and a test MARK comment. The governing user rule (stable code artifacts) forbids audit labels/finding codes in code comments and test names.
- **Fix:** The doc comment is titled "Finish-site reachability audit" and explains the invariant directly; the labeled audit lives in this SUMMARY (the planning artifact) under "WR-04 reachability audit" as the plan requires. One test MARK comment written with the label during RED was relabeled in GREEN.
- **Files modified:** StoreKitService.swift (comment text only), CreditPurchaseFlowTests.swift (MARK comment only)
- **Verification:** suite 13/13 green after relabel; `grep -c "WR-04"` over both Swift files = 0
- **Committed in:** `9598de6` (comment-only rider on the GREEN commit)

---

**Total deviations:** 1 (compliance adjustment, comment-only)
**Impact on plan:** None on behavior or deliverables — the audit content is identical; only the label placement differs. No scope creep.

## Issues Encountered

None.

## Known Stubs

None — the seam is production code the live listener delegates to, not a test stub.

## Threat Model Disposition

- **T-02-03 (Repudiation/DoS — finish of unverified consumable): MITIGATED** — finish removed; pinned by both tests (finishCallCount == 0 across deliveries).
- **T-02-04 (Tampering — forged JWS forcing a grant): accepted (existing)** — `checkVerified` still throws on `.unverified` for all grant paths; this plan removes the evidence-destroying finish without weakening any verification check.

## Next Phase Readiness

- Ready for 02-03 (WR-03 — DEBUG money-path mock wiring), which shares ENV-03; that plan's SUMMARY flips the ENV-03 checkbox when the shared-ID gate clears.
- ENV-03 checkbox deliberately not marked: `requirements.ready-ids` returned 0/1 (sibling 02-03 declares ENV-03 with no SUMMARY yet).

---
*Phase: 02-delete-correctness-test-suite-trust*
*Completed: 2026-09-03*

## Self-Check: PASSED

- Files: StoreKitService.swift, CreditPurchaseFlowTests.swift, 02-02-SUMMARY.md — all FOUND
- Commits: `b60d396` (test/RED), `9598de6` (feat/GREEN) — both FOUND on gsd/v1.2-submission-readiness
- `handleUnverifiedTransaction` contains zero `finish()` calls; both Swift files contain zero "WR-04" strings
- TDD gates present in order (test → feat), author Phuong Doan, no AI attribution
