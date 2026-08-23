---
phase: 02-credits-system-iap-transition
plan: 07
subsystem: payments
tags: [credits, iap, storekit-jws, premium-entitlement, revocation, gap-closure, tdd]
requires:
  - phase: 02-credits-system-iap-transition plan 02
    provides: verifyAndDecodeTransaction seam, VerifiedTransaction contract, /credits/redeem + /credits/premium/verify routes, premium_until column, creditsRoutes(verifier) injection
  - phase: 02-credits-system-iap-transition plan 03
    provides: completePurchase orchestration, PurchaseTransactionHandle, CreditPurchaseFlowTests spy seams
  - phase: 02-credits-system-iap-transition plan 06
    provides: purchased_credits bucket, free-first deductCredit arithmetic (composed with, not reverted)
provides:
  - VerifiedTransaction.revocationDate + decode-level INVALID_TRANSACTION throw on revoked payloads
  - rejectingRevoked(verify) wrapper applied once in creditsRoutes — one revocation policy covering both /credits/redeem and /credits/premium/verify, including injected test verifiers
  - /credits/premium/verify rejects past (non-null) expiry — only a future expiry may activate premium
  - Effective premium at live gates: deductCredit requires plan_type AND SQL-derived premium_active under the FOR UPDATE lock; chat 402 gate applies the same rule; cron demoted to janitor
  - iOS completePurchase guard-before-sync ordering — revoked/expired JWS never posted, never granted, still finished
affects:
  - stress-app-be/src/lib/iap.ts
  - stress-app-be/src/lib/credits.ts
  - stress-app-be/src/routes/credits.ts
  - stress-app-be/src/routes/chat.ts
  - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
actuals:
  tokens: 5063   # chars/4 over the 6 realized commits (backend 16161 + iOS 4094)
  tasks: 3
  commits: 6     # 4 backend + 2 iOS, excluding docs
tech-stack:
  added: []
  patterns:
    - "verifier-policy wrapper: rejectingRevoked(verify) decorates the injected TransactionVerifier once at the route factory so the seam policy binds even when the real decode is faked out in tests"
    - "SQL-derived gate booleans: (premium_until is null or premium_until > now()) as premium_active computed inside the FOR UPDATE row snapshot, mirrored in TS at the chat gate"
key-files:
  created: []
  modified:
    - stress-app-be/src/lib/iap.ts
    - stress-app-be/src/routes/credits.ts
    - stress-app-be/src/routes/credits.test.ts
    - stress-app-be/src/lib/credits.ts
    - stress-app-be/src/lib/credits.test.ts
    - stress-app-be/src/routes/chat.ts
    - stress-app-be/src/routes/chat.test.ts
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
    - StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift
key-decisions:
  - "Revocation enforcement as a verifier wrapper (rejectingRevoked) applied once in creditsRoutes rather than inline route checks — satisfies both the behavior spec (resolving fake with revocationDate must 400 at each route) and the one-seam key-link; the decode-level throw in verifyAndDecodeTransaction remains defense-in-depth"
  - "Legacy-null rule kept: premium_until IS NULL counts as active premium, so pre-premium_until rows never regress; the cron stays the only writer of demotions (janitor)"
  - "premium_until added to CreditBalanceRow/getBalance for internal gate use only — balanceJson untouched (IN-02 stays out of scope)"
requirements-completed: [derived-CR-02, derived-CR-03]   # IAP-06 deliberately NOT marked: live E2E money path remains deployment-gated
coverage:
  - id: D1
    description: "Revoked and expired Apple transactions never activate server-side premium or grant pack credits"
    requirement: derived-CR-02
    verification:
      - kind: integration
        ref: stress-app-be/src/routes/credits.test.ts#credits premium verify route (revoked sub 400 no-write; expired sub 400 no-write)
        status: pass
      - kind: integration
        ref: stress-app-be/src/routes/credits.test.ts#credits redeem route (revoked pack 400, purchased_credits unchanged)
      - kind: integration
        ref: stress-app-be/src/lib/iap.test.ts (real-library rejection paths still green)
        status: pass
    human_judgment: false
  - id: D2
    description: "iOS never posts revoked or expired JWS: guard precedes syncSubscriptionEntitlementToServer in completePurchase"
    requirement: derived-CR-02
    verification:
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#Revoked/Expired subscription transaction is never synced and still finishes (spy callCount 0, finish 1, no grant)
        status: pass
    human_judgment: false
  - id: D3
    description: "Premium expiry enforced at both live gates (deductCredit under FOR UPDATE + chat 402), not only the monthly cron"
    requirement: derived-CR-03
    verification:
      - kind: integration
        ref: stress-app-be/src/lib/credits.test.ts#deductCredit effective premium (expired fails as free-tier; expired charged from buckets; null-until still bypasses)
        status: pass
      - kind: integration
        ref: stress-app-be/src/routes/chat.test.ts#chat route premium gate (expired+empty 402; active+empty still streams)
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-08-17
status: complete
---

# Phase 02 Plan 07: Premium Entitlement Integrity — Gaps 3+4 / CR-02+CR-03 Closure Summary

**Closed the refund-abuse and expiry-drift chain in both layers: revoked/expired Apple JWS are rejected at the one verify seam both credit endpoints share (and never posted by iOS — the guard now precedes the entitlement sync), and premium expiry is enforced at the live gates (deductCredit + chat 402) instead of only the monthly cron.**

## Performance

- **Duration:** ~21 min active (2026-08-17T07:36:32Z → 07:57:20Z)
- **Tasks:** 3 (all TDD: strict RED → GREEN alternation, per repo where the behavior lives)
- **Files modified:** 9 (7 backend, 2 iOS)

## What Was Built

Backend commits in **stress-app-be on `main`**; iOS commits in **this repo on `gsd/v1.1-backend-api-migration`** (cross-repo protocol, mirroring 02-02/02-06):

| Repo | Commit | Gate | Content |
|---|---|---|---|
| stress-app-be | 301e3c9 | Task 1 RED | Failing route cases: revoked sub → 400 (no activation), revoked pack → 400 (purchased_credits untouched), expired sub → 400 (current code accepts past expiry) |
| stress-app-be | 308bf36 | Task 1 GREEN | `VerifiedTransaction.revocationDate`; `ensureNotRevoked` + `rejectingRevoked` in iap.ts; decode-level INVALID_TRANSACTION throw; wrapper applied once in `creditsRoutes`; `/premium/verify` rejects `expiresAt <= now`; existing fakes widened with `revocationDate: null` |
| stress-app-be | bd97ec8 | Task 2 RED | Failing effective-premium cases: expired premium w/ nothing → deduction fails (not 999999); expired premium w/ credits → charged from buckets; chat expired premium + empty → 402; pins (null-until bypass, active premium streams) |
| stress-app-be | ad01767 | Task 2 GREEN | `premium_active` SQL derivation under the FOR UPDATE lock in deductCredit; same effective-premium rule at the chat 402 gate; `premium_until` in `CreditBalanceRow` + `getBalance` (internal only) |
| ios-stress-app | d3c8dc0 | Task 3 RED | Failing ordering cases: revoked and expired subscription transactions must never reach `subscriptionVerifier` (failed `verifier.callCount → 1 == 0` — proving the sync-before-guard defect) |
| ios-stress-app | c187052 | Task 3 GREEN | `completePurchase` evaluates `isActive` BEFORE any server call; sync + local grant only when active; revoked/expired are finished without posting; doc comment states the ordering constraint |

TDD gate verified in both repos' git logs: strict `test:` → `feat:` pairs, no skipped gates, no unexpected passes at RED (each RED run demonstrated the exact predicted failures).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — reconciliation of conflicting plan lines] Revocation policy applied as a verifier wrapper, not "no route change"**
- **Found during:** Task 1 GREEN design
- **Issue:** The action text said "/redeem needs no route change: the lib-level revocation throw surfaces through its existing catch" — but the behavior spec (RED 1/RED 2) requires a *resolving* fake carrying `revocationDate` to yield 400 at both routes. With an injected fake the lib-level decode is bypassed, so the route (or the verifier it uses) must enforce the policy; with a *rejecting* fake the cases would have passed at RED, breaking TDD.
- **Fix:** `rejectingRevoked(verify)` in iap.ts — a one-line decoration applied once at the top of `creditsRoutes`, so both routes share literally one revocation policy that also binds injected test verifiers; the decode-level throw in `verifyAndDecodeTransaction` remains as defense-in-depth (both layers use the same `ensureNotRevoked`). Satisfies the behavior spec, the must_haves truth, and the "one seam protects both endpoints" key-link.
- **Files modified:** stress-app-be/src/lib/iap.ts, stress-app-be/src/routes/credits.ts
- **Commit:** 308bf36

**2. [Regression pin added] "Active premium with no credits still streams" chat case**
- **Found during:** Task 2 RED authoring
- **Issue:** The acceptance criterion "an active premium still streams (existing chat case green)" had no existing premium streaming case to lean on — chat.test.ts only had free-tier cases. Without a pin, the gate flip (`plan_type !== premium` → `!premiumActive`) could regress active-premium streaming unnoticed.
- **Fix:** Added the pin step to the new "chat route premium gate" block (active premium, zero remaining → 200 stream, metadata `credits_remaining` 999999). Passed at RED and GREEN — a pin, not a RED case.
- **Files modified:** stress-app-be/src/routes/chat.test.ts
- **Commit:** bd97ec8

---

**Total deviations:** 2 (both within plan intent; no scope creep, no contract changes)

## Contract Preservation Proof

- `balanceJson` untouched: `premium_until` is selected by `getBalance` but never serialized — `grep premium_until src/routes/credits.ts` returns zero occurrences; response shape remains exactly `total/used/remaining/plan_type/free_reset_at` (all pre-existing route cases green)
- 02-06 composition proof: every purchased-bucket, free-first consumption, and reset-preservation case passed in the same runs as the new gates (16 tests / 44 steps final combined pass); `deductCredit`'s free-branch arithmetic is byte-identical — only the premium early-return condition changed
- iOS: no protocol change — `PurchaseTransactionHandle` already exposed `revocationDate`/`expirationDate`; `completePurchase` is the only production function touched

## Verification Results

- **Backend final pass:** `deno test` on credits.test.ts, cron.test.ts, routes/credits.test.ts, routes/chat.test.ts, iap.test.ts → **16 passed (44 steps), 0 failed**; `deno task check`, `deno lint`, `deno fmt --check` all exit 0 (39 files)
- **iOS:** CreditPurchaseFlowTests **9/9 passed** (`xcodebuild test … -only-testing:StressMonitorTests/CreditPurchaseFlowTests -parallel-testing-enabled NO`, TEST SUCCEEDED); Release build **exit 0** (BUILD-05 holds)
- **Read-order check:** in `completePurchase` source, the `isActive` evaluation textually precedes the `syncSubscriptionEntitlementToServer` call; the pack arm and `refreshEntitlements` placement are untouched
- **Revoked transactions never write:** direct SELECTs in the route tests assert `plan_type` stays free and `purchased_credits` stays 0 after rejected verifications
- **Threat register:** T-2-701 mitigated (seam rejection + past-expiry route policy, pinned by 3 route cases), T-2-702 mitigated (guard-before-sync pinned by spy cases), T-2-703 mitigated (effective premium at both gates, pinned by 5 cases); T-2-704/705/706 accepted as registered (revocation race bounded by original expiry; JWS replay remains WR-01 out-of-scope; no new ledger surface)

## Known Stubs

None. No placeholder code, no skipped tests, every `<verify>` ran to green, both pre-existing suites re-ran as regression gates.

## Deferred Issues

- IAP-06 (live E2E money path) remains deployment-gated on the user's setup (image rebuild + migrations + ASC filing + sandbox smoke) — deliberately NOT marked complete, mirroring 02-06's precedent; the entitlement-integrity portion of the money path is what this plan closed
- Migration application to production + deploy: unchanged from 02-02/02-06 (nothing deployed, nothing pushed)
- IN-02 (exposing premium expiry to the client) and IN-05 (real Apple-signed success-path fixture) remain out of gap scope as planned

## Threat Flags

None — no new endpoints, auth paths, or trust boundaries beyond the plan's registered threat model.

## Self-Check: PASSED

All 9 modified files verified present on disk; all 6 code commits (backend 301e3c9, 308bf36, bd97ec8, ad01767; iOS d3c8dc0, c187052) verified in the respective repos' logs.

## Next Phase Readiness

- Phase 02 plan execution is complete (7/7); all four CR gaps from 02-VERIFICATION are closed at the code level: CR-04 (02-05, pack product-ID resolution), CR-01 (02-06, purchased-credits bucket), CR-02+CR-03 (this plan)
- Local test postgres on 127.0.0.1:5433 left running (8 migrations applied) for reuse

---
*Phase: 02-credits-system-iap-transition, Plan 07*
*Completed: 2026-08-17*
