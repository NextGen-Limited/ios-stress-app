---
phase: 02-credits-system-iap-transition
reviewed: 2026-08-17T08:45:00Z
depth: standard
files_reviewed: 55
files_reviewed_list:
  - ../stress-app-be/.env.example
  - ../stress-app-be/deno.json
  - ../stress-app-be/migrations/20260816120000_redeem.sql
  - ../stress-app-be/migrations/20260816120100_premium_until.sql
  - ../stress-app-be/migrations/20260817120000_purchased_credits.sql
  - ../stress-app-be/scripts/migrate.test.ts
  - ../stress-app-be/src/app.ts
  - ../stress-app-be/src/lib/apple_root_certs.ts
  - ../stress-app-be/src/lib/credits.test.ts
  - ../stress-app-be/src/lib/credits.ts
  - ../stress-app-be/src/lib/cron.test.ts
  - ../stress-app-be/src/lib/cron.ts
  - ../stress-app-be/src/lib/iap.test.ts
  - ../stress-app-be/src/lib/iap.ts
  - ../stress-app-be/src/routes/chat.test.ts
  - ../stress-app-be/src/routes/chat.ts
  - ../stress-app-be/src/routes/credits.test.ts
  - ../stress-app-be/src/routes/credits.ts
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - StressMonitor/StressMonitor/Info.plist
  - StressMonitor/StressMonitor/Models/CreditBalance.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift
  - StressMonitor/StressMonitor/Services/Credits/CreditService.swift
  - StressMonitor/StressMonitor/Services/Credits/CreditServiceProtocol.swift
  - StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift
  - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
  - StressMonitor/StressMonitor/Services/Premium/PaywallController.swift
  - StressMonitor/StressMonitor/Services/StoreKit/CreditPack.swift
  - StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift
  - StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift
  - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
  - StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift
  - StressMonitor/StressMonitor/StressMonitorApp.swift
  - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
  - StressMonitor/StressMonitor/ViewModels/CreditsViewModel.swift
  - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
  - StressMonitor/StressMonitor/Views/Premium/Components/PackCard.swift
  - StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift
  - StressMonitor/StressMonitor/Views/Premium/PaywallView.swift
  - StressMonitor/StressMonitor/Views/Premium/PurchaseSuccessView.swift
  - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
  - StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift
  - StressMonitor/StressMonitorTests/ChatLifecycleTests.swift
  - StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift
  - StressMonitor/StressMonitorTests/CreditServiceTests.swift
  - StressMonitor/StressMonitorTests/CreditsViewModelTests.swift
  - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
  - StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift
  - StressMonitor/StressMonitorTests/PremiumViewModelTests.swift
  - StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift
  - StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientCreditsTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
  - StressMonitor/StressMonitorTests/StressMonitorProducts.storekit
findings:
  critical: 1
  warning: 10
  info: 8
  total: 19
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-08-17 (original) · 2026-08-17 (gap-closure delta appended below)
**Depth:** standard (with cross-repo tracing into the sibling backend repo)
**Files Reviewed:** 55 cumulative (51 original + 4 newly added by the delta; 17 re-reviewed in the delta pass)
**Status:** issues_found

## Summary

The redeem-before-finish ordering for consumables, server-side idempotency on `apple_transaction_id`, the 402 → paywall routing, and the client contract tests are well built. However, the money path has four integrity holes that must be fixed before ship: (1) the monthly credit reset destroys purchased pack credits; (2) the premium-verify endpoint accepts expired and revoked Apple transactions — and the iOS updates-listener actively posts revoked/expired JWS to it; (3) premium expiry is enforced only by a once-a-month cron while every live gate checks `plan_type` alone; (4) the credit-pack product IDs added in this phase have no build-setting (or any) resolution path, so pack purchase throws `missingProductConfiguration` in every real build. Per the review scope note, the two disabled suites (EntitlementForegroundCorrection, StoreKitProductCatalogLive / IAP-01 ASC filing) and the exit-65 CloudKit flake are treated as known and are not re-reported; CR-04 is reported because it is a distinct omission (pack keys absent while premium keys were added).

> **Gap-closure delta (plans 02-05/02-06/02-07 + test-isolation fix 323bf57):** all four original Criticals are verified RESOLVED in code — see the per-finding status lines below and the `## Gap Closure Review` section. One new Critical (CR-05), one new Warning (WR-10), and two new Info items (IN-07, IN-08) were found in the changed code; original Critical counts were decremented accordingly.

Backend findings reference the sibling repo `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/`.

## Critical Issues

### CR-01: Monthly free-credit reset destroys purchased pack credits

> **Status (gap-closure delta): RESOLVED** — `purchased_credits` bucket added (`migrations/20260817120000_purchased_credits.sql`), reset touches `used_credits` only (`src/lib/cron.ts:3-12`), free-first consumption under lock (`src/lib/credits.ts:58-71`), derived total preserves the API contract. Verified in code and pinned by tests; details in Gap Closure Review.

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/cron.ts:4-11` (interaction with `src/lib/credits.ts:95-99`)
**Issue:** `resetMonthlyCredits` runs `set total_credits = 50, used_credits = 0 where plan_type = 'free'` on the 1st of each month. `redeemCredits` adds purchased pack credits to the same `total_credits` column (`total_credits = total_credits + ${credits}`). A free-tier user who buys a 150-credit pack and has, say, 120 left at month end is hard-reset to 50 — paid credits are silently destroyed every month. This is direct paid-value data loss on the phase's headline feature, and `cron.test.ts:22` implicitly pins the destructive behavior.
**Fix:** Separate granted from purchased balances so the reset only touches the free allotment, e.g.:

```sql
alter table user_credits add column purchased_credits integer not null default 0;
-- redeemCredits: update user_credits set purchased_credits = purchased_credits + ${credits}
-- resetMonthlyCredits:
update user_credits
set used_credits = 0, free_reset_at = now() + interval '1 month'
where plan_type = 'free';
-- derive total as (50 free allotment + purchased_credits) in getBalance/deductCredit,
-- or keep total_credits as a generated column.
```

### CR-02: `/credits/premium/verify` accepts expired and revoked transactions; iOS syncs them

> **Status (gap-closure delta): RESOLVED as specified** — `revocationDate` extracted and rejected at the verify seam covering BOTH routes (`src/lib/iap.ts:32-48,84-91`; `src/routes/credits.ts:35,76,101`), past-expiry rejection on `/premium/verify` (`src/routes/credits.ts:105-111`), iOS guard moved BEFORE the server sync (`StoreKitService.swift:371-378`, pinned by `CreditPurchaseFlowTests`). Residual refund-clawback gap filed as new CR-05.

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:50-70`, `src/routes/credits.ts:91-118`; iOS `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:357-378`
**Issue:** `verifyAndDecodeTransaction` extracts only `transactionId`, `productId`, `expiresDate`. The route rejects only `expiresAt === null`. Consequences:
- An Apple-signed JWS for an **expired** subscription activates `plan_type = 'premium'`; `greatest(premium_until, pastDate)` stores a past expiry, and demotion happens only at the next monthly cron (see CR-03) — free premium for up to ~31 days per expired transaction.
- There is **no `revocationDate` check anywhere**. A refunded subscription's still-verifiable JWS re-activates server-side premium. The iOS side compounds this: `completePurchase` calls `syncSubscriptionEntitlementToServer(transaction, ...)` at line 368 *before* the `revocationDate == nil` / `expirationDate > Date()` guard at lines 371-373, so a refund revocation delivered through `Transaction.updates` is actively POSTed to the server and re-grants premium until the original expiry.

Full refund-abuse chain with no attacker skill required: buy annual → request refund → Apple revokes → updates-listener syncs the revoked JWS → server keeps `plan_type = 'premium'`.
**Fix (backend):**

```typescript
// iap.ts
export interface VerifiedTransaction {
  transactionId: string;
  productId: string;
  expiresAt: Date | null;
  revocationDate: Date | null;   // new
}
// after decode:
if (payload.revocationDate) throw new InvalidTransactionError("transaction revoked");

// routes/credits.ts /premium/verify — reject expired:
if (transaction.expiresAt === null || transaction.expiresAt.getTime() <= Date.now()) {
  return invalidTransaction(c);
}
```

**Fix (iOS):** in `completePurchase`, move the `revocationDate == nil && not-expired` guard ahead of `syncSubscriptionEntitlementToServer` so revoked/expired transactions are never sent to the server.

### CR-03: Premium expiry is enforced only by a monthly cron; all live gates check `plan_type` alone

> **Status (gap-closure delta): RESOLVED** — effective premium (`premium_until is null or premium_until > now()`) enforced inside `deductCredit` under `for update` (`src/lib/credits.ts:40-56`) and in the chat 402 gate (`src/routes/chat.ts:35-45`); cron demotion retained as janitor only. Both paths pinned by tests. Minor residual filed as IN-07 (token budget still keyed on raw `plan_type`).

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/credits.ts:44-50`, `src/routes/chat.ts:34`, `src/lib/cron.ts:29`
**Issue:** `deductCredit` (`if (row.plan_type === "premium")`) and the chat 402 gate (`credits.plan_type !== "premium"`) never consult `premium_until`. `demoteExpiredPremium` runs once per month (`"0 0 1 * *"`). Every subscriber whose term ends mid-month retains unlimited chat for up to ~31 days at zero cost — independent of (and amplifying) CR-02, this alone leaks free premium to every churning subscriber.
**Fix:** Enforce expiry inline; keep the cron only as a janitor:

```sql
-- deductCredit, inside the transaction:
select total_credits, used_credits, plan_type,
       (premium_until is null or premium_until > now()) as premium_active
from user_credits where user_id = ${uid} for update
-- treat as premium only when plan_type = 'premium' and premium_active
```

Mirror the same effective-plan derivation in `chat.ts` (or return it from `getBalance` so the 402 gate uses one source of truth).

### CR-04: Credit-pack product IDs cannot resolve in any build configuration — pack purchase is dead in real builds

> **Status (gap-closure delta): RESOLVED** — `INFOPLIST_KEY_STOREKIT_CREDITS_{SMALL,LARGE}_PRODUCT_ID` present in both configurations (`project.pbxproj:850-851` Debug, `907-908` Release), literal keys with matching values in `StressMonitor/Info.plist:18-21`, `INFOPLIST_FILE = StressMonitor/Info.plist` wired (`project.pbxproj:841-842,898-899`), catalog resolves both pack IDs, live suite re-enabled with pack assertions, `.storekit` fixture carries both pack products.

**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (build settings at lines 850-853, 905-908); `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift:111-127`
**Issue:** The project defines only `INFOPLIST_KEY_STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID` and `..._SUBSCRIPTION_GROUP_ID`. `STOREKIT_CREDITS_SMALL_PRODUCT_ID` / `STOREKIT_CREDITS_LARGE_PRODUCT_ID` — the exact keys `StoreKitProductCatalog` resolves for packs — are set nowhere (grep over the whole pbxproj confirms zero matches). On a device there is no env var and no UserDefaults entry, so `smallPackProductID`/`largePackProductID` are nil → `availablePacks` returns `CreditPack.defaultPacks` with `productID: nil` → `purchase(pack:)` throws `StoreKitError.missingProductConfiguration`. Even after ASC filing completes (IAP-01), buying a pack can never succeed. This is distinct from the accepted IAP-01 item: the premium keys were added in this phase, the pack keys were not. Note also the disabled `StoreKitProductCatalogLiveTests` header documents that custom `INFOPLIST_KEY_*` values never reach the generated Info.plist — so even the premium keys' delivery mechanism needs verification (the scheme-level `.storekit` reference at `StressMonitor.xcscheme:45-46, 75-76` only applies to Xcode-run sessions).
**Fix:** Add the pack keys alongside the premium keys in both configurations of the app target, and verify the chosen delivery mechanism actually lands in `Bundle.main` (e.g., a real Info.plist key or a build-phase injection), then re-enable the live-catalog suite with pack assertions:

```
INFOPLIST_KEY_STOREKIT_CREDITS_SMALL_PRODUCT_ID = com.stressmonitor.app.credits.small;
INFOPLIST_KEY_STOREKIT_CREDITS_LARGE_PRODUCT_ID = com.stressmonitor.app.credits.large;
```

## Warnings

### WR-01: No appAccountToken binding between purchaser and redeeming account

> **Status (gap-closure delta): ACCEPTED** — recorded as accepted threat T-2-705; not re-reviewed.

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:338-343`; backend `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:19-25`
**Issue:** Purchases run as bare `product.purchase()` with no `appAccountToken` option, and the backend never checks one. The JWS carries no user binding, so redemption is first-come-first-served on the transaction ID: a JWS obtained by any means (shared device, proxy/log capture, support ticket) can be redeemed into any account, and there is no server-side evidence tying a grant to the purchaser. Apple's consumable guidance is to set `appAccountToken` and verify it server-side.
**Fix:** Generate a stable UUID per Firebase uid (store server-side and on device), pass `Product.PurchaseOption.appAccountToken(uuid)` in both purchase entry points, and reject in `/credits/redeem` and `/credits/premium/verify` when `payload.appAccountToken` does not match the authenticated user's token.

### WR-02: Unbounded silent retry of permanently-failing redemptions

> **Status (gap-closure delta): OPEN** — `handle(transaction:)` still swallows every error and leaves the transaction unfinished (`StoreKitService.swift:390-395`). The delta makes one failure class guaranteed rather than hypothetical — see new WR-10.

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:309-318, 383-394`
**Issue:** The updates-listener path swallows every error and leaves the transaction unfinished by design. For retryable failures (network, 5xx) that is correct; for a permanent 400 `INVALID_TRANSACTION` (e.g., product/ledger mismatch) the transaction redelivers on every launch forever, with no retry cap, no log, and no user-visible surface (only the `purchase(pack:)` path surfaces errors). The user has paid, never receives credits, and nothing ever tells them.
**Fix:** Branch on error type in `handle(transaction:)` — retryable failures keep the leave-unfinished contract; permanent failures (`CreditsAPIError.invalidTransaction`) should be logged/surfaced (and after N attempts, finish to clear the queue and escalate to support copy).

### WR-03: DEBUG builds route the whole money path to a no-op mock

> **Status (gap-closure delta): NOT RECHECKED** — outside the delta's changed files.

**File:** `StressMonitor/StressMonitor/StressMonitorApp.swift:237-245`; `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift:24-28`
**Issue:** `#if DEBUG` returns `MockStoreKitService` and discards the `creditService` parameter. `MockStoreKitService.purchase(pack:)` sleeps 1 second and does nothing — no purchase sheet, no redemption, no balance change. Consequently `CreditsViewModel.purchaseSelectedPack()` shows neither success nor error (balance nil → nil), i.e., in every Debug build (including all simulator UAT) the "Buy 10 Credits · $1.99" button silently does nothing, and the deferred-grant/recovery path is unexercisable in Debug.
**Fix:** Gate the mock on an explicit opt-in (launch argument like `-mock-iap`, or DEBUG + a settings toggle) instead of the entire Debug configuration, so Debug builds with the `.storekit` scheme config can run the real StoreKit flow; the unused `creditService:` parameter then also stops being misleading.

### WR-04: Unverified consumable transactions are finished, destroying the only proof of purchase

> **Status (gap-closure delta): OPEN** — `.unverified` results are still immediately finished (`StoreKitService.swift:314-318`).

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:314-318`
**Issue:** `.unverified` results are immediately `finish()`ed with the comment that no grant occurred. For a consumable, the unfinished transaction is the only redeliverable proof a user paid; finishing an unverified payload permanently destroys the recovery path (Apple's own sample code errors rather than finishing). If verification fails transiently (e.g., on-device cert chain issue), a paid pack is lost with no recourse.
**Fix:** Do not finish `.unverified` transactions; log and leave them for redelivery, matching the retry contract used for redemption failures.

### WR-05: "Restore purchases" button on the purchase-success screen does nothing

> **Status (gap-closure delta): NOT RECHECKED** — outside the delta's changed files.

**File:** `StressMonitor/StressMonitor/Views/Premium/PurchaseSuccessView.swift:198-206, 217-221`
**Issue:** The button labeled "Restore purchases" only calls `dismiss()` — `restoreOrDismiss()` contains no restore logic (the comment admits it). Misleading UI on a paid flow invites support contacts and App Review scrutiny.
**Fix:** Wire it to the shared `StoreKitServiceProtocol.restorePurchases()` via environment injection, or delete the button (pack-mode already correctly omits it).

### WR-06: SettingsView preview crashes — CreditService missing from preview environment

> **Status (gap-closure delta): NOT RECHECKED** — outside the delta's changed files.

**File:** `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:549-558`
**Issue:** `SettingsView` reads `@Environment(CreditService.self)` (line 9) but the preview injects only `AppRouter`, `PaywallController`, and a model container. Accessing `creditService.balance` in body traps at runtime ("No Observable object of type CreditService found"), so the preview is dead.
**Fix:** Add `.environment(CreditService())` to the preview (and `ChatBottomSheetView` previews if similarly affected).

### WR-07: SettingsView.init force-unwraps ModelContainer creation

> **Status (gap-closure delta): NOT RECHECKED** — outside the delta's changed files.

**File:** `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:24-27`
**Issue:** `(try? ModelContainer(for: StressMeasurement.self, configurations: ...))!` — `try?` + `!` crashes at view construction if container creation ever fails. In-memory configs rarely fail, but this is a gratuitous crash vector on every SettingsView instantiation.
**Fix:** Use `makeContainer(at:)`-style recovery or a non-optional in-memory container constructed with `try!`-free fallback (e.g., reuse `StressMonitorApp.makeContainer(at: tempURL)`).

### WR-08: IAP_ENVIRONMENT parsing silently fails closed to Production

> **Status (gap-closure delta): OPEN** — still exact-match `=== "Sandbox"` (`src/lib/iap.ts:51-53`).

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:32-34`, `.env.example:7`
**Issue:** Only the exact string `"Sandbox"` selects `Environment.SANDBOX`; `"sandbox"`, `"SANDBOX"`, `"Development"`, or any typo silently becomes PRODUCTION, and every sandbox test purchase then fails verification with `INVALID_TRANSACTION` — an opaque failure mode during UAT exactly when the team will be testing purchases.
**Fix:** Accept case-insensitive `"sandbox"` and throw at startup (or log loudly) on any unrecognized value other than `Production`.

### WR-09: Unvalidated pagination on GET /credits?history

> **Status (gap-closure delta): OPEN** — `parseInt` without clamping and `select *` unchanged (`src/routes/credits.ts:57-64`).

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/routes/credits.ts:55-62`
**Issue:** `parseInt(c.req.query("limit") ?? "20")` yields `NaN` for non-numeric input and accepts negatives/huge values; `NaN`/negative parameters produce a Postgres error → 500 instead of a 4xx. Also `select *` leaks the full row shape.
**Fix:** Clamp: `const limit = Math.min(Math.max(parseInt(q ?? "20") || 20, 1), 100)` (same for offset ≥ 0), and select explicit columns.

## Info

### IN-01: Premium chat writes fake deduction rows into the ledger

> **Status (gap-closure delta): OPEN** — premium path still inserts `amount = -amount, type = 'chat'` (`src/lib/credits.ts:51-55`).

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/credits.ts:44-50`
**Issue:** Every premium-user message inserts `amount = -1, type = 'chat'` even though no credits were deducted. The transaction history shown by `GET /credits?history` is falsified for premium users and the table grows unbounded.
**Fix:** Skip the ledger insert on the premium path (or record a zero-amount audit row with a distinct type).

### IN-02: `premium_until` is never exposed to clients

> **Status (gap-closure delta): PARTIALLY ADDRESSED** — `premium_until` now selected in `getBalance` and added to `CreditBalanceRow` (`src/lib/credits.ts:13,84`), but `balanceJson` still omits it, and the `returning` clauses in `redeemCredits`/`activatePremium` (`:112`, `:147`) don't select it, so the typed `CreditBalanceRow.premium_until` is `undefined` on those paths while the type claims `Date | null`.

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/credits.ts:6-11, 71-75`; `StressMonitor/StressMonitor/Models/CreditBalance.swift`
**Issue:** The migration adds `premium_until` but `CreditBalanceRow`/`balanceJson` never select or return it, and `CreditBalance` has no field for it — the app can never show "Premium renews <date>".
**Fix:** Add `premium_until` to the select list, the JSON envelope, and `CreditBalance` (optional String, like `freeResetAt`).

### IN-03: Migration test pins the exact migration count

> **Status (gap-closure delta): NOT RECHECKED** — outside the delta's changed files.

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/scripts/migrate.test.ts:33`
**Issue:** `assertEquals(applied.length, 7)` breaks with the next added migration file — a maintenance landmine.
**Fix:** Assert `applied.length >= 7`, or derive the expected count from the migrations directory listing.

### IN-04: Dead nil-coalescing on a non-optional

> **Status (gap-closure delta): OPEN** — `product.price ?? .zero` unchanged (`StoreKitService.swift:432`).

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:429`
**Issue:** `product.price ?? .zero` — `Product.price` is non-optional `Decimal`; the right side is never used and this emits a compiler warning.
**Fix:** `let pricePerPeriod = product.price`.

### IN-05: No positive-path JWS verification test

> **Status (gap-closure delta): NOT RECHECKED** — `iap.test.ts` outside the delta's changed files. The delta's route-level fakes still do not exercise the real decode path, so this remains relevant.

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.test.ts`
**Issue:** Only rejection paths (garbage/empty/forged) are tested. The root-cert embedding, `expiresDate` conversion, and (missing) revocation handling have no fixture-based positive test — which is exactly how CR-02's gaps went uncaught.
**Fix:** Add a fixture generated with Apple's test certificates (or the library's own test utils) covering valid decode, expired expiry, and revoked rejection.

### IN-06: SignedDataVerifier built with online revocation checks disabled

> **Status (gap-closure delta): OPEN** — `enableOnlineChecks` still `false` (`src/lib/iap.ts:59-66`).

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:40-46`
**Issue:** `enableOnlineChecks = false` skips OCSP/CRL consultation, so a compromised/revoked intermediate would not be detected. Acceptable in many serverless setups, but on a purchase-verification path it deserves an explicit decision.
**Fix:** Document the tradeoff in the code, or enable online checks if the deploy environment permits egress.

---

## Gap Closure Review

**Delta reviewed:** 2026-08-17 · plans 02-05 (purchased-credits bucket), 02-06 (revoked/expired transaction rejection + effective premium), 02-07 (pack product-ID build settings), plus iOS test-isolation fix `323bf57`. Backend commits `e383f3b…ad01767` (TDD pairs) and the iOS counterparts were read file-by-file, not test-claimed.

**Delta file scope (17):** iOS — `project.pbxproj`, `Info.plist`, `StoreKitProductCatalog.swift`, `StoreKitService.swift`, `CreditPurchaseFlowTests.swift`, `StoreKitProductCatalogLiveTests.swift`, `StoreKitProductCatalogTests.swift`; backend — `migrations/20260816120100_premium_until.sql`, `migrations/20260817120000_purchased_credits.sql`, `src/lib/credits.ts`, `src/lib/credits.test.ts`, `src/lib/cron.ts`, `src/lib/cron.test.ts`, `src/lib/iap.ts`, `src/routes/chat.ts`, `src/routes/chat.test.ts`, `src/routes/credits.test.ts` (+ `src/routes/credits.ts` and `src/app.ts` read for cross-checks).

### Per-Critical resolution verdicts

**CR-01 — RESOLVED (verified in code, arithmetic traced by hand).**
- `migrations/20260817120000_purchased_credits.sql` adds `purchased_credits INTEGER NOT NULL DEFAULT 0` with a `>= 0` CHECK, and normalizes legacy single-bucket rows. The normalization was hand-traced across shapes (e.g., total=200/used=120 → purchased=80, total=50, used=50 → remaining 80 = legacy remaining; total=200/used=10 → remaining 190 = legacy remaining; total=60/used=55 → remaining 5). The `LEAST(total,50)`/`LEAST(used,50)` clamps restore the `used ≤ total` invariant the new consumption math relies on. Rows with embedded pack credits always have `total > 50` (old provisioning started at 50), so the `WHERE total_credits > 50 OR used_credits > 50` filter catches exactly the right rows. Balance-preserving in every traced case.
- `resetMonthlyCredits` (`cron.ts:3-12`) sets only `used_credits = 0` and `free_reset_at`; `purchased_credits` untouched — pinned by `cron.test.ts` "preserves purchased balance".
- Free-first consumption (`credits.ts:58-71`): `usedAfter = min(used + amount, total)` caps free-bucket usage; `purchasedSpend` overflows into the purchased bucket only after the free allotment is exhausted; the `available < amount` gate runs before any mutation, so no negative-balance write is possible. Boundary traced at used=49/total=50/purchased=5 and at exhaustion; matches the `u-ff` test sequence.
- Derived-total contract: `total_credits + purchased_credits as total_credits` (`credits.ts:6`) keeps `GET /credits` `total`/`remaining` semantics identical (`remaining = derived_total − used` equals bucket arithmetic because `used ≤ total` under the new invariant). `deductCredit`'s returned `remaining` and `getBalance`'s are consistent by the same derivation.

**CR-02 — RESOLVED as specified (residual gap filed as CR-05 below).**
- `iap.ts:84-91` extracts `revocationDate`; `ensureNotRevoked`/`rejectingRevoked` (`:32-48`) enforce rejection at the seam, and `creditsRoutes` applies the wrapper once at the factory (`routes/credits.ts:35`) so **both** `/credits/redeem` (`:76`) and `/credits/premium/verify` (`:101`) are covered — including injected test verifiers.
- Past-expiry rejection on `/premium/verify`: `routes/credits.ts:105-111` rejects `expiresAt === null || expiresAt <= now`. Consumable `/redeem` correctly has no expiry requirement.
- iOS: `completePurchase` (`StoreKitService.swift:371-378`) computes `isActive` (known product + `revocationDate == nil` + not expired) and only calls `syncSubscriptionEntitlementToServer` inside that branch; `refreshEntitlements` (`:244-258`) likewise only re-syncs non-revoked, non-expired entitlements. Pinned by `revokedSubscriptionNeverSyncs` / `expiredSubscriptionNeverSyncs` (`verifier.callCount == 0`).

**CR-03 — RESOLVED (verified in code, both gates).**
- `deductCredit` selects `(premium_until is null or premium_until > now()) as premium_active` under `for update` and requires `plan_type = 'premium' && premium_active` (`credits.ts:40-56`) — enforcement is inline and locked, not cron-dependent. An expired-premium user falls through to bucket charging or a clean failure.
- Chat 402 gate mirrors the same effective-premium rule from `getBalance` (`chat.ts:35-45`); both directions pinned (`expired premium → 402`, `active premium with 0 credits → streams` in `chat.test.ts`).
- Cron retained as janitor only (`demoteExpiredPremium` + monthly reset, `cron.ts:27-39`). `premium_until` monotonicity preserved via `greatest(premium_until, ${expiresAt})` (`credits.ts:145`) — and, since the route now rejects past expiries, the old "store a past expiry via greatest" vector is gone. Renewals-never-shorten is pinned by the `activatePremium` test.
- `plan_type = 'premium'` with `premium_until IS NULL` is treated as perpetual premium (by design for manual grants; nothing in the activation path can produce it — the route requires a non-null future expiry). Not a defect; noted for the record.

**CR-04 — RESOLVED (verified against the built artifact's inputs).**
- `INFOPLIST_KEY_STOREKIT_CREDITS_SMALL/LARGE_PRODUCT_ID` present in **both** configurations: `project.pbxproj:850-851` (Debug) and `907-908` (Release), values `com.stressmonitor.app.credits.{small,large}`.
- The same keys exist as literal entries in `StressMonitor/Info.plist:18-21` with identical values, and the app target wires `INFOPLIST_FILE = StressMonitor/Info.plist` with `GENERATE_INFOPLIST_FILE = YES` (`project.pbxproj:841-842, 898-899`) — Xcode merges `INFOPLIST_KEY_*` into the file-based plist, so the keys reach `Bundle.main` through two redundant mechanisms that agree.
- `StoreKitProductCatalog` resolves both keys (`StoreKitProductCatalog.swift:116-134`) into `smallPackProductID`/`largePackProductID`; `availablePacks` and `purchase(pack:)` therefore get real product IDs in Release builds. `StressMonitorProducts.storekit` contains both pack products (`credits.small` 10 credits, `credits.large` 150) matching `PACK_CREDITS` on the backend.
- `StoreKitProductCatalogLiveTests` re-enabled with pack assertions (`liveCatalogResolvesSmallPack/LargePack`, round-trip through `pack(for:)`). The 323bf57 test-isolation fix (explicit `infoDictionary`/`environment` injection) correctly decouples the injection tests from the now-populated Info.plist tier.

### New findings from the delta

#### CR-05: Refunded subscriptions never lose server-side premium — entitlement persists to the original term end

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/routes/credits.ts:99-104` (revoked JWS rejected as `INVALID_TRANSACTION`), `src/lib/credits.ts:142-148` (`activatePremium` only ever extends via `greatest`), `src/lib/cron.ts:14-25` (demotion keyed solely on `premium_until`); iOS `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:371-380` (refuses to send revoked JWS, finishes silently)
**Issue:** CR-02's fix ensures a revoked JWS can never *activate or re-activate* premium — but it also destroys the only revocation signal the server ever receives. The original purchase legitimately set `premium_until` to the term end; when Apple later revokes (refund), the iOS client deliberately never posts the revoked JWS (`isActive == false` → skip sync → finish), and even if it did, the server would reject it with 400. `demoteExpiredPremium` only shortens on `premium_until < now()`, which the refund does not change. Result: buy annual → request refund (EU: 14-day no-questions) → Apple revokes → local entitlement correctly drops (client checks `revocationDate`) **but server-side premium — which is what gates unlimited chat — persists for up to 12 months at zero cost**. This is the same no-skill abuse chain CR-02 was filed against, now bounded only by the original term length instead of closed. The app UI can even show non-premium while the server keeps granting premium chat, since the two checks use different sources of truth.
**Fix:** Make revocation a demotion signal instead of a rejection on the subscription path. Keep `rejectingRevoked` on `/credits/redeem` (packs: never grant), but on `/credits/premium/verify` decode the revoked payload and shorten:

```typescript
// routes/credits.ts /premium/verify — revoked sub shortens instead of 400
const verified = await verifyAndDecodeTransaction(jws); // unwrapped, revocationDate visible
if (SUBSCRIPTION_PRODUCT_IDS.has(verified.productId) && verified.revocationDate) {
  await sql`
    update user_credits
    set premium_until = least(premium_until, ${verified.revocationDate})
    where user_id = ${uid} and premium_until > ${verified.revocationDate}
  `;
  return c.json(balanceJson(await getBalance(uid)));
}
```

Mirror on iOS: in `completePurchase`, when a known subscription transaction has `revocationDate != nil`, still POST the JWS to the verify endpoint (which now demotes) before finishing, instead of skipping the sync entirely.

#### WR-10: Refunded credit pack → guaranteed permanent-failure retry loop on every launch

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:364-368` (pack path has no revocation guard) interacting with the new backend rejection (`src/routes/credits.ts:76-79` via `rejectingRevoked`)
**Issue:** The delta's backend now (correctly) rejects a revoked pack JWS with 400 `INVALID_TRANSACTION`, and `credits.test.ts` pins that. But the iOS pack path in `completePurchase` never checks `transaction.revocationDate`: a refunded consumable redelivered through `Transaction.updates` is POSTed to `/credits/redeem`, gets a permanent 400, `handle(transaction:)` swallows the error and leaves the transaction unfinished — so StoreKit redelivers it on every launch, forever, with no log and no user surface. WR-02 described this class as hypothetical; the delta makes it a production certainty for every refunded pack (no grant is correct — the infinite silent retry is not).
**Fix:**

```swift
if catalog.pack(for: transaction.productID) != nil {
    if transaction.revocationDate != nil {
        await transaction.finish() // refunded pack: no grant, and clear the queue
        return
    }
    let balance = try await redeemer(jwsRepresentation)
    ...
}
```

#### IN-07: Token budget keyed on raw `plan_type` while the gates use effective premium

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/routes/chat.ts:78`
**Issue:** `getMaxTokens(remaining, credits.plan_type)` returns the 2048 premium budget whenever `plan_type === "premium"`. An expired-premium user (not yet demoted by the cron, correctly charged from finite buckets by the new gate) still gets the premium-sized output budget funded by a single credit — the delta split "premium" into plan vs effective, and this call site kept the raw plan.
**Fix:** `getMaxTokens(remaining, premiumActive ? "premium" : "free")`.

#### IN-08: Boundary TOCTOU between the 402 gate and the post-stream deduction (pre-existing, unchanged by delta)

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/routes/chat.ts:39-45` vs `:106`
**Issue:** The 402 gate runs before streaming; `deductCredit` runs after the model stream completes. Two concurrent requests at `remaining == 1` both pass the gate and both stream; the second `deductCredit` then fails atomically under the lock (no negative balance — the delta's bucket math holds), but one unbilled model call slips through. The structure predates the delta; noted because the free/purchased boundary was explicitly re-traced and it holds everywhere except this pre-existing race.
**Fix (if desired):** reserve the credit before streaming (deduct first, refund on stream failure) or accept the single-message bound.

### Original-findings status after the delta

| ID | Status | Evidence |
|----|--------|----------|
| CR-01..CR-04 | RESOLVED | see verdicts above |
| WR-01 | Accepted (T-2-705) | — |
| WR-02 | Open | `StoreKitService.swift:390-395` still swallows all errors |
| WR-03, WR-05, WR-06, WR-07 | Not rechecked | outside delta scope |
| WR-04 | Open | `.unverified` still finished (`StoreKitService.swift:314-318`) |
| WR-08 | Open | `iap.ts:51-53` exact-match `"Sandbox"` |
| WR-09 | Open | `routes/credits.ts:57-64` unclamped `parseInt`, `select *` |
| IN-01 | Open | `credits.ts:51-55` still writes fake premium ledger rows |
| IN-02 | Partially addressed | row type/select updated; JSON envelope + `returning` clauses still omit `premium_until` |
| IN-03, IN-05 | Not rechecked | outside delta scope |
| IN-04 | Open | `StoreKitService.swift:432` |
| IN-06 | Open | `iap.ts:59-66` online checks still disabled |

Known/accepted and not re-reported: exit-65 CloudKit host-restart flake; ASC filing + deployment pending (user actions); two disabled suites re-enabled is expected.

**Open count after delta:** 1 Critical (CR-05), 10 Warnings (WR-01 accepted, WR-02..WR-09 + WR-10), 8 Info (IN-01..IN-08).

---

_Reviewed: 2026-08-17 (original) · 2026-08-17 (gap-closure delta)_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
