---
phase: 02-credits-system-iap-transition
plan: 08
subsystem: payments
tags: [credits, iap, storekit-jws, premium-entitlement, revocation, refund, gap-closure, tdd]
requires:
  - phase: 02-credits-system-iap-transition plan 07
    provides: rejectingRevoked seam, VerifiedTransaction.revocationDate, effective-premium rule, completePurchase guard ordering (this plan splits the seam policy per route and INVERTS the 02-07 iOS revoked-subscription pin)
  - phase: 02-credits-system-iap-transition plan 02
    provides: /credits/redeem + /credits/premium/verify routes, iap_redemptions PK idempotency pattern, creditsRoutes(verifier) injection seam
  - phase: 02-credits-system-iap-transition plan 06
    provides: purchased_credits bucket arithmetic (composed with — the demotion UPDATE touches neither bucket)
provides:
  - /credits/premium/verify treats a revoked SUBSCRIPTION JWS as a demotion signal — premium_until = least(premium_until, revocationDate) under the replay-window guard (premium_until IS NOT NULL AND premium_until <= revoked.expiresAt AND premium_until > revocationDate), 200 with the current balance
  - demotePremiumOnRevocation in credits.ts — convergent guarded UPDATE with terminal plan_type flip, NO iap_redemptions insert (same-jws activation-then-revocation cannot 500 on 23505)
  - rejectingRevoked scoped to /credits/redeem only; verifyAndDecodeTransaction returns revoked payloads (Apple signature verification untouched)
  - iOS completePurchase posts a revoked known-subscription JWS via the entitlement-sync seam BEFORE finish, never touching premiumState (refreshEntitlements stays the sole local corrector)
  - iOS pack-arm revocation guard — a refunded pack finishes with zero redemption attempts on both the purchase path and the Transaction.updates listener path (WR-10 loop break)
affects:
  - stress-app-be/src/lib/iap.ts
  - stress-app-be/src/lib/credits.ts
  - stress-app-be/src/routes/credits.ts
  - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
actuals:
  tokens: 4050   # chars/4 over the 6 realized code commits (backend 11890 + iOS 4310 chars)
  tasks: 3
  commits: 6     # 2 backend + 4 iOS, excluding docs
tech-stack:
  added: []
  patterns:
    - "per-route verifier policy: the rejectingRevoked wrapper binds the injected verifier at the /redeem call site only, while /premium/verify consumes the raw verifier and branches on revocationDate — one verification chain, two revocation policies"
    - "convergent UPDATE as idempotency: re-post safety comes from a WHERE that matches zero rows on replay, never from an idempotency-table insert that a legitimately re-presented transaction id would violate"
key-files:
  created: []
  modified:
    - stress-app-be/src/lib/iap.ts
    - stress-app-be/src/lib/credits.ts
    - stress-app-be/src/routes/credits.ts
    - stress-app-be/src/routes/credits.test.ts
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
    - StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift
key-decisions:
  - "No clawback of already-granted pack credits on refund — a clawback needs a new server surface and risks negative balances against partially-spent credits; the WR-10 fix's contract is queue hygiene. Pinned in the pack-arm guard's WHY-note and here"
  - "Demotion re-post safety via the convergent UPDATE WHERE, never an iap_redemptions insert — the same apple_transaction_id legitimately holds an earlier activation row (activated while valid, revoked later, re-posted), and a PK insert there aborts 23505 into a 500"
  - "Replay-window guard premium_until <= revoked.expiresAt added on top of the reviewer's literal SQL — an old revocation cannot shorten a newer term granted by a later transaction (pinned by the +60d-annual vs revoked-monthly case)"
  - "Dead-term demotion keeps the dated premium_until and flips plan_type to 'free' only when least(premium_until, revocationDate) <= now() — mirrors demoteExpiredPremium's terminal state, stays inert under the 02-07 effective-premium gates"
  - "A revoked subscription JWS with null expiresAt is rejected 400 — the replay guard cannot evaluate without the revoked transaction's own expiry (boundary the plan left open)"
  - "iOS revoked-subscription branch performs no premiumState write in either direction — refreshEntitlements (run right after handle()) stays the single authoritative local corrector, so a user holding a different still-active subscription keeps local premium"
requirements-completed: [derived-CR-05, derived-WR-10]
coverage:
  - id: D1
    description: "A revoked subscription JWS posted to POST /credits/premium/verify demotes server-side premium to the revocation date; replays are convergent no-ops; an old revocation cannot shorten a newer term; dead-term demotion flips plan_type; same-jws activation-then-revocation returns 200 (not 500); null premium_until rows are untouched"
    requirement: derived-CR-05
    verification:
      - kind: integration
        ref: stress-app-be/src/routes/credits.test.ts#credits premium verify route (demotion, replay no-op, newer-term guard, dead-term plan_type flip, same-jws activation-then-revocation, null-until immunity)
        status: pass
      - kind: integration
        ref: stress-app-be/src/routes/credits.test.ts#regression pins (revoked pack 400 on BOTH routes with purchased_credits unchanged, expired sub 400, valid sub activation 200, every pre-existing case)
        status: pass
    human_judgment: false
  - id: D2
    description: "iOS posts a revoked known-subscription JWS as the demotion signal BEFORE finish and never grants local premium; expired transactions remain unposted; active-subscription grants unchanged"
    requirement: derived-CR-05
    verification:
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#Revoked subscription transaction is posted as a demotion signal before finish, never grants premium (callCount 1, finishCountAtVerify 0, finish 1, isPremiumUser false)
        status: pass
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#expiredSubscriptionNeverSyncs + subscriptionTakesLegacyPath + subscriptionFinishSurvivesVerifyFailure (unchanged pins)
        status: pass
    human_judgment: false
  - id: D3
    description: "A refunded (revoked) pack transaction is finished WITHOUT any redemption attempt on both the purchase path and the updates-listener path — the permanent-400 silent retry loop is broken; already-granted credits are not clawed back"
    requirement: derived-WR-10
    verification:
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#Revoked pack transaction is finished without any redemption attempt (redeemer 0, finish 1, applyBalance 0)
        status: pass
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#Updates-listener path finishes a revoked pack instead of retrying forever (redeemer 0, finish 1 with the redeemer throwing invalidTransaction)
        status: pass
      - kind: unit
        ref: StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift#non-revoked pack pins (redeem-before-finish once, failure leaves unfinished for redelivery)
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-17
status: complete
---

# Phase 02 Plan 08: Refund Demotion + Refunded-Pack Loop Break — CR-05/WR-10 Closure Summary

**Revocation became a demotion signal instead of a rejection: /credits/premium/verify shortens premium_until to the refund date under a replay-safe guard (while /credits/redeem keeps absolute revoked rejection), iOS delivers that signal before finish, and a refunded pack now clears the StoreKit queue in one pass with zero redemption attempts.**

## Performance

- **Duration:** ~18 min active (2026-08-17T08:33:14Z → 08:50:48Z)
- **Tasks:** 3 (all TDD: strict RED → GREEN alternation, per repo where the behavior lives)
- **Files modified:** 6 (4 backend, 2 iOS)

## What Was Built

Backend commits in **stress-app-be on `main`**; iOS commits in **this repo on `gsd/v1.1-backend-api-migration`** (cross-repo protocol, mirroring 02-02/02-06/02-07):

| Repo | Commit | Gate | Content |
|---|---|---|---|
| stress-app-be | c77a5dc | Task 1 RED | 6 failing route cases (all currently 400): demotion-to-revocation-date, replay convergent no-op, newer-term guard, dead-term plan_type flip, same-jws activation-then-revocation, null-until immunity + revoked-pack-on-verify pin. Fixture ordering pinned per the plan-checker warning (revoked expiresAt strictly later than the valid activation's) |
| stress-app-be | 291bb4b | Task 1 GREEN | `verifyAndDecodeTransaction` returns revoked payloads (decode-level throw removed; `rejectingRevoked` comment scoped to /redeem); `demotePremiumOnRevocation` guarded least() UPDATE + plan_type flip, no idempotency insert; /premium/verify raw-verifier demotion branch (200) before the expiry rejection |
| ios-stress-app | 0285081 | Task 2 RED | Inverted the 02-07 `revokedSubscriptionNeverSyncs` pin into the demotion-signal case (failed `verifier.callCount → 0 == 1`, proving the skip-entirely defect); added `finishCountAtVerify` probe to `SubscriptionVerifySpy` |
| ios-stress-app | 000a557 | Task 2 GREEN | `completePurchase` revoked-known-subscription branch textually before `isActive`: sync the demotion POST, finish, return — no premiumState write; doc comment rewritten to state the posting policy truthfully |
| ios-stress-app | c5eddc3 | Task 3 RED | Two failing pack cases: completePurchase redeems a revoked pack today (`callCount → 1`); the updates-listener path leaves it unfinished at `finish → 0` — the exact WR-10 redelivery-loop shape |
| ios-stress-app | 6becb8f | Task 3 GREEN | Pack-arm revocation guard — finish and return before the redeemer call, with the no-clawback WHY-note; non-revoked pack path byte-identical |

TDD gate verified in both repos' git logs: strict `test:` → `feat:` pairs, every RED run demonstrated the exact predicted failures (6 backend steps at 400-vs-200; iOS callCount 0≠1 / finish 0≠1), no skipped gates.

## Deviations from Plan

None — plan executed exactly as written.

Notes (within plan intent, recorded for the audit trail):
- The plan listed `stress-app-be/src/lib/credits.test.ts` under files_modified with lib-level cases explicitly **optional** ("only if a route case does not already cover the arithmetic") — the route block covers all demotion arithmetic via direct SELECTs, so no lib-level file was touched.
- The plan-checker's two warnings were honored: (1) all iOS verify runs captured xcodebuild's real exit code (no `| tail -5` masking — TEST_EXIT/BUILD_EXIT echoed separately, including the expected 65s at RED); (2) the RED 1 fixture ordering (valid activation expiresAt strictly EARLIER than the revoked fake's expiresAt) is pinned explicitly with a WHY-comment at the `revokedMonthlyDemotion` fake.

## Contract Preservation Proof

- `balanceJson` untouched — the demotion branch returns the same `total/used/remaining/plan_type/free_reset_at` envelope via `getBalance`; no response-shape change, no new endpoints, no schema change, cron untouched
- `redeemCredits`, `activatePremium`, `deductCredit`, and the purchased-bucket arithmetic are byte-identical — the demotion is a new isolated UPDATE touching only `premium_until`/`plan_type`
- 02-06/02-07 composition: purchased-bucket, free-first consumption, reset-preservation, seam-rejection, effective-premium, and chat-gate suites all green in the same run (16 tests / 50 steps)
- iOS: no protocol change — `completePurchase` internals only; `refreshEntitlements` placement and the non-revoked flows untouched

## Verification Results

- **Backend final pass:** `deno test` on credits.test.ts (routes), credits.test.ts (lib), iap.test.ts, cron.test.ts, chat.test.ts → **16 passed (50 steps), 0 failed**; `deno task check`, `deno lint`, `deno fmt --check` all exit 0
- **iOS final pass:** CreditPurchaseFlowTests **11/11 passed** (`xcodebuild test … -only-testing:StressMonitorTests/CreditPurchaseFlowTests -parallel-testing-enabled NO`, exit 0); Release build **exit 0** (BUILD-05 holds)
- **Acceptance greps:** `/redeem` → `redeemVerify` (rejectingRevoked-wrapped, line 80); `/premium/verify` → raw `verifyTransaction` (line 105) with the `revocationDate !== null` branch (line 116) before the expiry rejection (line 130); `demotePremiumOnRevocation` contains zero `iap_redemptions` inserts; `verifyAndDecodeTransaction` contains zero `ensureNotRevoked` calls; `rejectingRevoked` still exported and referenced by the route factory
- **Cross-check of the pairing:** the backend demotion route accepts (200) exactly what iOS now posts — a revoked subscription JWS; `/redeem`'s absolute revoked rejection is pinned on both sides (backend route case + the untouched revoked-pack-on-redeem case)
- **Threat register:** T-2-801 mitigated (verification chain untouched — forged JWS still 400s, pinned by the invalid-jws cases), T-2-802 mitigated (replay-window guard, pinned by newer-term + replay cases), T-2-805 mitigated (listener-path finish==1/redeemer==0 case), T-2-803/804/806 accepted as registered

## Known Stubs

None. No placeholder code, no skipped tests, every `<verify>` ran to green with real exit codes.

## Deferred Issues

- IAP-06 (live E2E money path) remains deployment-gated on the user's setup — unchanged from 02-06/02-07; a real sandbox refund is the only way to observe the demotion end-to-end, and both halves are independently pinned until then
- Migration application to production + deploy: nothing deployed, nothing pushed (local test DB on 127.0.0.1:5433 only)
- Out-of-scope review items (WR-01..WR-09 except WR-10, IN-01..IN-08) remain at their recorded 02-REVIEW statuses — untouched

## Threat Flags

None — no new endpoints, auth paths, or trust boundaries beyond the plan's registered threat model (T-2-801..806).

## Self-Check: PASSED

All 6 modified files verified present on disk; all 6 code commits (backend c77a5dc, 291bb4b; iOS 0285081, 000a557, c5eddc3, 6becb8f) verified in the respective repos' logs.

## Next Phase Readiness

- Gap closure cycle 2 complete: CR-05 (Critical) and WR-10 (Warning) closed in code, both halves test-pinned per repo
- Phase 02 open review residue after this plan: WR-01 (accepted), WR-02..WR-09, IN-01..IN-08 — all advisory, none on the money path
- Local test postgres on 127.0.0.1:5433 left running (8 migrations applied) for reuse

---
*Phase: 02-credits-system-iap-transition, Plan 08*
*Completed: 2026-08-17*
