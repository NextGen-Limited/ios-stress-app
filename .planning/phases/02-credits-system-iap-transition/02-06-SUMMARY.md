---
phase: 02-credits-system-iap-transition
plan: 06
subsystem: payments
tags: [credits, postgres, migration, iap, cron, tdd, gap-closure]
requires:
  - phase: 02-credits-system-iap-transition plan 02
    provides: redeemCredits single-transaction store, PACK_CREDITS map, iap_redemptions idempotency, CreditBalanceRow contract
provides:
  - user_credits.purchased_credits column (INTEGER NOT NULL DEFAULT 0, CHECK >= 0)
  - derived-total SQL projection (free + purchased aliased as total_credits) preserving the GET /credits + redeem response contract byte-identically
  - free-first deductCredit arithmetic spanning both buckets
  - usage-only resetMonthlyCredits (purchased balance and free allotment never touched)
affects: [stress-app-be/src/lib/credits.ts, stress-app-be/src/lib/cron.ts, 02-07-PLAN (shared credits.ts)]
actuals:
  tokens: 2718
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - "balance-bucket separation with derived projection: derivedTotal as a shared postgres.js sql fragment embedded in select/returning"
    - "immutability pinned by observation: seed an off-canonical value (total_credits 45) so an illicit write by reset is observable in tests"
key-files:
  created:
    - stress-app-be/migrations/20260817120000_purchased_credits.sql
  modified:
    - stress-app-be/src/lib/credits.ts
    - stress-app-be/src/lib/credits.test.ts
    - stress-app-be/src/lib/cron.ts
    - stress-app-be/src/lib/cron.test.ts
    - stress-app-be/scripts/migrate.test.ts
key-decisions:
  - "Purchased credits live in purchased_credits; total_credits is the immutable free allotment; API contract preserved via SQL-level derived alias, so routes/credits.ts, routes/chat.ts, and the iOS CreditBalance decode needed zero changes"
  - "Consumption is free-first: used_credits pins at total_credits and purchased drains by the overflow; the monthly reset restores used_credits only"
requirements-completed: [derived-CR-01]
coverage:
  - id: D1
    description: "Purchased credits in their own bucket: additive migration with non-negative CHECK + legacy-row normalization; redemption increments purchased_credits; balance reporting uses the derived total"
    requirement: derived-CR-01
    verification:
      - kind: integration
        ref: stress-app-be/src/lib/credits.test.ts#redeemCredits purchased bucket (3 steps: grant-into-purchased, replay-no-op, derived getBalance)
        status: pass
      - kind: integration
        ref: stress-app-be/scripts/migrate.test.ts#runMigrations applies all files and is idempotent (8 applied)
        status: pass
    human_judgment: false
  - id: D2
    description: "Free-first consumption: chat deduction drains the free allotment before purchased credits; insufficient balance mutates nothing; purchased can never go negative (check precedes mutation + DB CHECK backstop)"
    requirement: derived-CR-01
    verification:
      - kind: integration
        ref: stress-app-be/src/lib/credits.test.ts#deductCredit free-first consumption (2 steps: drains free before purchased, exhausts purchased then fails without mutating)
        status: pass
    human_judgment: false
  - id: D3
    description: "Monthly reset never touches purchased balance or the free allotment — only used_credits is restored (the CR-01 pin)"
    requirement: derived-CR-01
    verification:
      - kind: integration
        ref: stress-app-be/src/lib/cron.test.ts#resetMonthlyCredits preserves purchased balance
        status: pass
      - kind: integration
        ref: stress-app-be/src/lib/cron.test.ts#resetMonthlyCredits (existing plain-free assertions keep holding)
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-08-17
status: complete
---

# Phase 02 Plan 06: Purchased-Credits Bucket — Gap 2 / CR-01 Closure Summary

**Separated purchased pack credits into their own `purchased_credits` balance with free-first consumption and a usage-only monthly reset, preserving the GET /credits response contract byte-for-byte via a derived-total SQL projection.**

## Performance

- **Duration:** ~10 min active
- **Started:** 2026-08-17T06:58:26Z
- **Completed:** 2026-08-17T07:08:17Z
- **Tasks:** 2 (both TDD: strict RED → GREEN alternation)
- **Files modified:** 6 (1 created, 5 modified — all in stress-app-be)

## What Was Built

All code commits in the **stress-app-be repo on `main`** (per cross-repo protocol, mirroring 02-02):

| Commit | Gate | Content |
|---|---|---|
| fbfd352 | Task 1 RED | Failing purchased-bucket cases: grant-into-purchased (raw row total 50 / purchased 10, derived 60), replay-no-op in both buckets, getBalance derived total |
| e383f3b | Task 1 GREEN | Migration `20260817120000_purchased_credits.sql` (ADD COLUMN + CHECK `user_credits_purchased_nonnegative` + legacy-row normalization), redeemCredits → `purchased_credits` increment, derived-total projection in getBalance/redeemCredits/activatePremium, migrate count 7→8 |
| 88b1a89 | Task 2 RED | Failing free-first consumption case (drain free before purchased; exhaust; insufficient mutates nothing) + failing reset-preservation case |
| 8f66698 | Task 2 GREEN | deductCredit free-first arithmetic (available = total + purchased − used; used pins at total, purchased drains the overflow), resetMonthlyCredits reduced to usage-only |

TDD gate verified in git log: strict `test:` → `feat:` pairs, no skipped gates.

### Combined end-to-end trace (ran against the live functions, exactly the plan's `<verification>` sequence)

```
provisioned: 50/0/0        (total/used/purchased)
after small pack: 50/0/10  (derived total 60)
after spending 51: 50/50/9 (50 free drained, 1 from purchased)
after monthly reset: 50/0/9 (purchased preserved — CR-01 closed)
getBalance derived total: 59 (= 50 + 9 − 0)
```

## Contract Preservation Proof

- `routes/credits.ts` and `routes/chat.ts`: **zero changes**; both route suites re-ran green after the model change (12 tests / 32 steps across credits + cron + routes/credits + routes/chat)
- `balanceJson` still reads `total_credits` / `used_credits` off `CreditBalanceRow`; the derivation lives entirely in the SQL projection (`total_credits + purchased_credits as total_credits`), so `remaining = total − used` still equals free + purchased − used
- iOS `CreditBalance` decode untouched (no field added, no type changed)

## Migration Invariant Verification

Legacy-row normalization preserves derived remaining for every legal pre-migration shape — verified on paper AND empirically via a VALUES-matrix query over 8 shapes (50/10, 60/30, 60/55, 75/60, 50/50, 80/80, 52/50, 55/52): `new_total + new_purchased − new_used === old_total − old_used` in every row, and every normalized row satisfies both CHECKs (`total ≥ used`, `purchased ≥ 0`). Migration contains exactly the three specified statements; no ALTER modifies or drops an existing column.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Local postgres unavailable as previously configured**
- **Found during:** Task 1 precondition check
- **Issue:** 02-02's Docker container `stress-app-pg-0202` no longer exists and the Docker daemon cannot start on this machine (no Docker Desktop/colima); port 5432 also free
- **Fix:** started a dedicated local homebrew `postgresql@15` instance on exactly `127.0.0.1:5433` (fresh initdb, trust auth, database `stress_app`), applied the 7 existing migrations, then ran all suites against it. Same URL shape as 02-02 (`postgresql://postgres:postgres@127.0.0.1:5433/stress_app`); no remote database touched
- **Files modified:** none (environment only; datadir under `/tmp/stress-pg-0206`)
- **Verification:** baseline suites green before RED; all suites green at both GREEN gates

**2. [TDD discipline] Strengthened the Task-2 cron RED seed**
- **Found during:** Task 2 RED authoring
- **Issue:** the plan's specified seed (total 50, used 30, purchased 10) PASSES against the still-destructive reset once Task 1's schema lands — `set total_credits = 50` is a no-op on a row whose total is already 50, so RED would not fail
- **Fix:** seeded `total_credits = 45` (a legal value under the new model) so the illicit `total_credits = 50` write is observable; assertions otherwise per plan (used → 0, purchased byte-identical, total unchanged). Confirmed genuine RED before the fix, green after
- **Files modified:** stress-app-be/src/lib/cron.test.ts
- **Committed in:** 88b1a89

**3. [Rule 2 - Contract consistency] Derived projection applied to activatePremium too**
- **Found during:** Task 1 GREEN
- **Issue:** plan named only getBalance and redeemCredits for the derived alias; activatePremium's RETURNING feeds the same `balanceJson`, so a raw total there would report free-only totals on the same contract field for a premium user holding purchased credits
- **Fix:** same `returning ${derivedTotal}, …` projection; zero test changes required (existing premium suite green)
- **Files modified:** stress-app-be/src/lib/credits.ts
- **Committed in:** e383f3b

**4. [Refactor pass] Deduped the derived-total aliasing**
- **Found during:** Task 1 REFACTOR gate (acceptance criterion "dedupe if repetition appears")
- **Fix:** extracted `const derivedTotal = sql\`total_credits + purchased_credits as total_credits\`` — a shared postgres.js fragment embedded at all three projection sites; re-ran green, zero behavior change
- **Files modified:** stress-app-be/src/lib/credits.ts
- **Committed in:** e383f3b

---

**Total deviations:** 4 auto-fixed (1 blocking-environment, 1 TDD-strengthening, 1 contract consistency, 1 refactor-gate)
**Impact on plan:** All within plan intent; no scope creep. The API-contract and no-deployment constraints are fully honored.

## Known RED Behavior Note

Task 1's `seedUser` extension (inserting `purchased_credits`) made the pre-existing cases fail at RED alongside the new ones — expected collateral of the shared helper against a schema lacking the column; all restored green at GREEN (5 tests / 14 steps, then 12 / 32 with route suites at Task 2).

## Verification Results

- `deno test` on credits.test.ts, cron.test.ts, routes/credits.test.ts, routes/chat.test.ts: **12 passed (32 steps), 0 failed**
- `scripts/migrate.test.ts`: green, expects 8 applied migrations
- `deno task check`, `deno lint`, `deno fmt --check`: all exit 0 (39 files)
- Threat register: T-2-601 mitigated (available check precedes mutation; `user_credits_purchased_nonnegative` backstops), T-2-602 mitigated (usage-only reset pinned by cron test — regression of the exact CR-01 defect now fails CI), T-2-603 unchanged-serialization confirmed (FOR UPDATE lock + single-statement redeem + one consistent derived snapshot), T-2-604 accepted (no new field exposed)

## Known Stubs

None. No placeholder code, no skipped tests, no unrun verify commands. Every `<verify>` in the plan ran to green.

## Deferred Issues

- Migration application to production + image deploy: still deferred user setup (unchanged from 02-04; nothing deployed, nothing pushed)
- IAP-06 (live E2E money path) remains human-gated on deployment + ASC filing — this plan deliberately did not mark it complete; only the lib-layer portion (`derived-CR-01`) is closed here

## Threat Flags

None — no new endpoints, auth paths, or trust boundaries beyond the plan's registered threat model.

## Self-Check: PASSED

Migration file and SUMMARY present on disk; all 4 backend commits (fbfd352, e383f3b, 88b1a89, 8f66698) verified in `git -C stress-app-be log`.

## Next Phase Readiness

- 02-07 (CR-02+CR-03: revocation/expiry rejection, effective premium at live gates) builds on the shared `credits.ts` — its `deductCredit` premium early-return is untouched and ready for the effective-premium derivation
- Local test postgres on 127.0.0.1:5433 left running (datadir `/tmp/stress-pg-0206`, 8 migrations applied) for immediate reuse by 02-07

---
*Phase: 02-credits-system-iap-transition, Plan 06*
*Completed: 2026-08-17*
