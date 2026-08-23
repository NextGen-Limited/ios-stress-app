---
phase: 02-credits-system-iap-transition
plan: 02
subsystem: credits-iap
tags: [credits, iap, storekit-jws, backend, subscriptions, idempotency]
requires: [02-01-decisions, DEC-1, DEC-2, backend-credit-system, firebase-auth-middleware]
provides: [POST-/credits/redeem, POST-/credits/premium/verify, redeemCredits, activatePremium, PACK_CREDITS, SUBSCRIPTION_PRODUCT_IDS, verifyAndDecodeTransaction, InvalidTransactionError, iap_redemptions-table, premium_until-column, cron-premium-demotion]
affects: [stress-app-be/src/routes/credits.ts, stress-app-be/src/lib/credits.ts, stress-app-be/src/lib/iap.ts, stress-app-be/src/lib/cron.ts, stress-app-be/src/app.ts]
tech-stack:
  added:
    - "@apple/app-store-server-library@3.1.0 (npm, pinned) — Apple JWS chain verification"
  patterns:
    - "PK-keyed idempotency insert as the first statement of a grant transaction (conflict aborts everything atomically)"
    - "server-authoritative product maps (PACK_CREDITS / SUBSCRIPTION_PRODUCT_IDS) — client-asserted amounts never read"
    - "verifier injection seam (creditsRoutes(verifier) / createApp(verify, verifyTransaction)) mirroring the TokenVerifier pattern"
key-files:
  created:
    - stress-app-be/migrations/20260816120000_redeem.sql
    - stress-app-be/migrations/20260816120100_premium_until.sql
    - stress-app-be/src/lib/iap.ts
    - stress-app-be/src/lib/iap.test.ts
    - stress-app-be/src/lib/apple_root_certs.ts
  modified:
    - stress-app-be/src/lib/credits.ts
    - stress-app-be/src/lib/credits.test.ts
    - stress-app-be/src/lib/cron.ts
    - stress-app-be/src/lib/cron.test.ts
    - stress-app-be/src/routes/credits.ts
    - stress-app-be/src/routes/credits.test.ts
    - stress-app-be/src/app.ts
    - stress-app-be/deno.json
    - stress-app-be/deno.lock
    - stress-app-be/scripts/migrate.test.ts
    - stress-app-be/.env.example
    - stress-app-be/CLAUDE.md
decisions:
  - "JWS library: @apple/app-store-server-library@3.1.0 — user-verified publisher (app-store-server-library-auto@group.apple.com) and official repo (github.com/apple/app-store-server-library-node)"
  - "Root cert bundle: Apple Root CA G2+G3 (both valid to 2039-04-30) embedded as base64 DER in src/lib/apple_root_certs.ts — legacy AppleIncRootCertificate.cer URL now serves HTML"
  - "Subscription endpoint named POST /credits/premium/verify (02-03 plans name no route; this pins the contract)"
  - "One shared iap_redemptions idempotency table for packs and subscriptions (credits_granted=0 for subscription activations)"
  - "premium_until = greatest(existing, transaction expiry) — out-of-order renewals can extend but never shorten entitlement"
  - "Cron demotion runs before the free reset in the same monthly job so demoted users get fresh free credits immediately"
metrics:
  duration: ~75min active (excludes overnight Task-1 checkpoint wait)
  completed: 2026-08-17
actuals:
  tokens: 10100
  tasks: 5
  commits: 9
status: complete
---

# Phase 02 Plan 02: Backend Credit Redemption + Subscription Premium Verification Summary

Built the backend half of purchased credits and server-side premium on the Deno/Hono backend: `POST /credits/redeem` verifies an Apple StoreKit 2 transaction JWS and grants pack credits exactly once; `POST /credits/premium/verify` (DEC-1 amendment) activates `plan_type='premium'` from a verified subscription JWS with expiry-tracked entitlement and cron demotion.

## Package Verification Record (Task 1 — blocking-human checkpoint, resolved)

User signal: `verified: @apple/app-store-server-library@3.1.0`. Evidence gathered read-only before approval: npm publisher/maintainer `appstoreserverlibraryautomation <app-store-server-library-auto@group.apple.com>`; repository `https://github.com/apple/app-store-server-library-node` (official `apple` org); dependencies pure-JS (`jsonwebtoken`, `jsrsasign`, `base64url`, `node-fetch@2`) — Deno npm-compat confirmed empirically (the library really executes in the test suite's rejection paths). Pinned at exactly `3.1.0` in `deno.json`; `deno install --frozen` exits 0. Exact API pinned from the package's own types: `new SignedDataVerifier(appleRootCertificates: Buffer[], enableOnlineChecks: boolean, environment: Environment, bundleId: string, appAppleId?: number)` and `verifyAndDecodeTransaction(jws): Promise<JWSTransactionDecodedPayload>` (field `expiresDate?: number` ms).

## What Was Built

All commits in the **stress-app-be repo on `main`** (per orchestrator direction — see Deviation 8).

| Commit | Task | Content |
|---|---|---|
| 0d3935c | 2 (RED) | Failing `redeemCredits` cases: grant-once, replay-no-op, unknown-product-no-write |
| 6bb9a6f | 2 (GREEN) | `iap_redemptions` migration (PK on `apple_transaction_id`), `redeemCredits` single-transaction store, real `PACK_CREDITS` map in new `iap.ts` |
| ab7bbea | 3 (RED) | Failing verifier cases: garbage/empty/forged-JWS rejection with `INVALID_TRANSACTION`; pack-map exactness |
| 3268b1c | 3 (GREEN) | `verifyAndDecodeTransaction` behind `SignedDataVerifier`, Apple Root CA G2+G3 embedded, `InvalidTransactionError`, env knobs (`APP_BUNDLE_ID` default `stress.ai.com`, `APPLE_APPLE_ID`, `IAP_ENVIRONMENT`) |
| 37b68cf | 4 (RED) | Failing route cases: 200+balance, replay 200, forged-amounts-ignored, invalid 400, missing-field 400 |
| fe32ade | 4 (GREEN) | `POST /credits/redeem` with injected verifier seam (`creditsRoutes(verifier)`, `createApp(verify, verifyTransaction)`), shared `balanceJson`, `migrate.test` bumped |
| 02693bf | 5 (RED) | Failing premium cases across lib/cron/route: activation, replay no-op, renewal-never-shortens, pack-rejected, cron demotion, route contract |
| 38ffcc6 | 5 (GREEN) | `POST /credits/premium/verify`, `activatePremium` (greatest-expiry), `premium_until` migration, `demoteExpiredPremium` cron step, `SUBSCRIPTION_PRODUCT_IDS` |
| 394576c | docs | Backend CLAUDE.md API surface line updated |

TDD gate: the 8 code commits alternate strict `test:` → `feat:` pairs (verified in git log).

## Response JSON Records (for 02-03 / 02-04 cross-checking)

First grant (small pack on a fresh 50-credit user) — **200**:

```json
{"total": 60, "used": 0, "remaining": 60, "plan_type": "free", "free_reset_at": "<ISO timestamp>"}
```

Replay of the same `transaction_jws` — **200**, byte-same shape, `total` unchanged at 60, single `credit_transactions` row of `{amount: 10, type: "purchase"}`. Premium activation — **200** with `"plan_type": "premium"` and `remaining = total - used`; replay stays premium, expiry untouched.

Pinned contract (both endpoints): request `POST {base}/credits/redeem` | `POST {base}/credits/premium/verify`, Bearer Firebase ID token, body `{"transaction_jws": "<JWS string>"}`; success 200 CreditBalance shape identical to GET /credits; every failure mode 400 `{"error": "Invalid transaction", "code": "INVALID_TRANSACTION"}`; 401 via existing auth middleware; 500 via existing onError. **02-03 codes against exactly this.**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] jsr.io hard-blocked this machine (Cloudflare 403 on all UAs)**
- **Found during:** baseline test run (before Task 2)
- **Issue:** Deno's empty module cache + jsr.io serving CF challenges → `deno task test` could not resolve `jsr:@std/assert`; npm registry unaffected
- **Fix:** local `ssh -D` SOCKS relay to a reachable host + local Python HTTP CONNECT proxy; `HTTPS_PROXY`/`NO_PROXY` env for test runs only. Zero repo changes; `@std/assert` is not on npm so no import substitution existed
- **Files modified:** none (environment only)

**2. [Rule 3 - Blocking] Backend local Postgres unavailable as configured**
- **Issue:** `docker compose up` fails (`env_file .env` missing) and host port 5432 is already occupied by a different postgres with different credentials
- **Fix:** dedicated `postgres:17-alpine` container on `127.0.0.1:5433`; `DATABASE_URL` exported per command; migrations applied locally (the plan forbids only *remote* migration application — local migrate-then-test is the repo's CI-shaped workflow)
- **Files modified:** none (environment only)

**3. [Rule 3 - Blocking] Plan's verify command form is incompatible with deno.json's task**
- **Issue:** `deno task test --allow-env … <file>` double-passes flags the task already carries ("cannot be used multiple times")
- **Fix:** targeted runs use the repo-documented raw form `deno test --allow-env --allow-net --allow-read <file>`; full suites use plain `deno task test`

**4. [Rule 1 - Bug] `scripts/migrate.test.ts` hardcoded the migration count**
- **Issue:** expected exactly 5 applied migrations; each new migration breaks it by design
- **Fix:** bumped to 6 then 7 and added `iap_redemptions` to expected tables
- **Commit:** fe32ade / 38ffcc6

### Documented Deviations

**5. [Schema conformance] Idempotency `user_id` is TEXT, not the plan's UUID**
- `users.id` (and every FK in the schema) is TEXT holding Firebase UIDs; a UUID column could not reference it. Migration stays additive with zero ALTERs to existing tables, per plan.

**6. [Process] `iap.ts` created in Task 2 with the real map instead of a stub**
- The plan intended a Task-3-replaced stub; creating the real `PACK_CREDITS` immediately avoids throwaway work. Consequence: Task 3's RED covered only the verifier (the pack-map case passed at RED — expected, not an unexpected pass).

**7. [Scope - user-confirmed DEC-1 amendment] Subscription premium-verify endpoint added as Task 5**
- Per the coordinator's decision-record amendment: same verification library, `plan_type='premium'` with `premium_until` from the transaction's `expiresDate`, monthly cron demotion, idempotent re-verification, zero-subscriber baseline (no backfill). 02-03's plans name no route, so this plan pins `POST /credits/premium/verify`.

**8. [Branch] Backend work committed on `stress-app-be` `main`, not the plan's `feat/credits-redeem`**
- Orchestrator instruction (sequential executor, cross-repo) overrode the plan's branch note. Nothing pushed anywhere.

**9. [Artifact form] Root CAs embedded as base64 DER constants, not .cer files**
- `https://www.apple.com/certificateauthority/AppleIncRootCertificate.cer` now returns an HTML page (dead); G2 and G3 both download fine and are valid to 2039. Embedding in `src/lib/apple_root_certs.ts` (with fingerprints) removes runtime file reads — Docker/allow-read safe. Same public material, committed either way.

## Auth Gates

Task 1 was a `blocking-human` package-legitimacy checkpoint (not an auth gate proper). Executor stopped with read-only npm evidence; user replied `verified: @apple/app-store-server-library@3.1.0`; execution resumed. No other gates hit.

## Verification Results

- `deno task test`: **25 passed (81 steps), 0 failed**; `deno task check`, `deno lint`, `deno fmt:check`, `deno install --frozen`: all exit 0, in stress-app-be on `main` at 394576c
- Contract grep: routes `/redeem` + `/premium/verify` under `/credits`; body key `transaction_jws` (single read site via `readTransactionJws`); response fields exactly `total/used/remaining/plan_type/free_reset_at`
- Threat register mitigations implemented and pinned by tests: T-2-05 (chain verification + PK idempotency + ledger row), T-2-06 (forged `credits`/`amount`/`uid` body fields ignored — test asserts grant equals map value), T-2-07 (uid only from auth context), T-2-08 unchanged posture
- Apple-crypto single-site: `grep -rn "app-store-server-library" src/ scripts/` → only `src/lib/iap.ts`

## Known Stubs

None. One honest testing boundary: the *success* path of the real Apple verifier cannot be unit-tested without an Apple-signed JWS fixture — it is exercised at the route seam via injected fakes (per plan design), the rejection paths run the real library under Deno, and live-transaction verification happens in 02-04/UAT. No placeholder code exists.

## Deferred Issues

- Migration application to production + image deploy: deferred to 02-04 user_setup with explicit user confirmation (by design; nothing deployed, nothing pushed)
- `APPLE_APPLE_ID` numeric value must be set at deploy time for production verification (documented in `.env.example`; default 0)
- T-2-08 rate-limiting hardening for redemption flood: accepted residual per plan threat model, noted for follow-up

## Threat Flags

None beyond the plan's threat model — no new endpoints, auth paths, or trust boundaries beyond those registered.

## Self-Check: PASSED

All 5 created backend files verified present; all 9 backend commits (0d3935c, 6bb9a6f, ab7bbea, 3268b1c, 37b68cf, fe32ade, 02693bf, 38ffcc6, 394576c) verified in `git -C stress-app-be log`.
