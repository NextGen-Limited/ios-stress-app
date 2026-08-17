---
phase: 02-credits-system-iap-transition
reviewed: 2026-08-17T00:00:00Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - ../stress-app-be/.env.example
  - ../stress-app-be/deno.json
  - ../stress-app-be/migrations/20260816120000_redeem.sql
  - ../stress-app-be/migrations/20260816120100_premium_until.sql
  - ../stress-app-be/scripts/migrate.test.ts
  - ../stress-app-be/src/app.ts
  - ../stress-app-be/src/lib/apple_root_certs.ts
  - ../stress-app-be/src/lib/credits.test.ts
  - ../stress-app-be/src/lib/credits.ts
  - ../stress-app-be/src/lib/cron.test.ts
  - ../stress-app-be/src/lib/cron.ts
  - ../stress-app-be/src/lib/iap.test.ts
  - ../stress-app-be/src/lib/iap.ts
  - ../stress-app-be/src/routes/credits.test.ts
  - ../stress-app-be/src/routes/credits.ts
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
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
  critical: 4
  warning: 9
  info: 6
  total: 19
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-08-17
**Depth:** standard (with cross-repo tracing into the sibling backend repo)
**Files Reviewed:** 51 (15 backend + 23 iOS app/project + 13 tests/config)
**Status:** issues_found

## Summary

The redeem-before-finish ordering for consumables, server-side idempotency on `apple_transaction_id`, the 402 → paywall routing, and the client contract tests are well built. However, the money path has four integrity holes that must be fixed before ship: (1) the monthly credit reset destroys purchased pack credits; (2) the premium-verify endpoint accepts expired and revoked Apple transactions — and the iOS updates-listener actively posts revoked/expired JWS to it; (3) premium expiry is enforced only by a once-a-month cron while every live gate checks `plan_type` alone; (4) the credit-pack product IDs added in this phase have no build-setting (or any) resolution path, so pack purchase throws `missingProductConfiguration` in every real build. Per the review scope note, the two disabled suites (EntitlementForegroundCorrection, StoreKitProductCatalogLive / IAP-01 ASC filing) and the exit-65 CloudKit flake are treated as known and are not re-reported; CR-04 is reported because it is a distinct omission (pack keys absent while premium keys were added).

Backend findings reference the sibling repo `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/`.

## Critical Issues

### CR-01: Monthly free-credit reset destroys purchased pack credits

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

**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (build settings at lines 850-853, 905-908); `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift:111-127`
**Issue:** The project defines only `INFOPLIST_KEY_STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID` and `..._SUBSCRIPTION_GROUP_ID`. `STOREKIT_CREDITS_SMALL_PRODUCT_ID` / `STOREKIT_CREDITS_LARGE_PRODUCT_ID` — the exact keys `StoreKitProductCatalog` resolves for packs — are set nowhere (grep over the whole pbxproj confirms zero matches). On a device there is no env var and no UserDefaults entry, so `smallPackProductID`/`largePackProductID` are nil → `availablePacks` returns `CreditPack.defaultPacks` with `productID: nil` → `purchase(pack:)` throws `StoreKitError.missingProductConfiguration`. Even after ASC filing completes (IAP-01), buying a pack can never succeed. This is distinct from the accepted IAP-01 item: the premium keys were added in this phase, the pack keys were not. Note also the disabled `StoreKitProductCatalogLiveTests` header documents that custom `INFOPLIST_KEY_*` values never reach the generated Info.plist — so even the premium keys' delivery mechanism needs verification (the scheme-level `.storekit` reference at `StressMonitor.xcscheme:45-46, 75-76` only applies to Xcode-run sessions).
**Fix:** Add the pack keys alongside the premium keys in both configurations of the app target, and verify the chosen delivery mechanism actually lands in `Bundle.main` (e.g., a real Info.plist key or a build-phase injection), then re-enable the live-catalog suite with pack assertions:

```
INFOPLIST_KEY_STOREKIT_CREDITS_SMALL_PRODUCT_ID = com.stressmonitor.app.credits.small;
INFOPLIST_KEY_STOREKIT_CREDITS_LARGE_PRODUCT_ID = com.stressmonitor.app.credits.large;
```

## Warnings

### WR-01: No appAccountToken binding between purchaser and redeeming account

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:338-343`; backend `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:19-25`
**Issue:** Purchases run as bare `product.purchase()` with no `appAccountToken` option, and the backend never checks one. The JWS carries no user binding, so redemption is first-come-first-served on the transaction ID: a JWS obtained by any means (shared device, proxy/log capture, support ticket) can be redeemed into any account, and there is no server-side evidence tying a grant to the purchaser. Apple's consumable guidance is to set `appAccountToken` and verify it server-side.
**Fix:** Generate a stable UUID per Firebase uid (store server-side and on device), pass `Product.PurchaseOption.appAccountToken(uuid)` in both purchase entry points, and reject in `/credits/redeem` and `/credits/premium/verify` when `payload.appAccountToken` does not match the authenticated user's token.

### WR-02: Unbounded silent retry of permanently-failing redemptions

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:309-318, 383-394`
**Issue:** The updates-listener path swallows every error and leaves the transaction unfinished by design. For retryable failures (network, 5xx) that is correct; for a permanent 400 `INVALID_TRANSACTION` (e.g., product/ledger mismatch) the transaction redelivers on every launch forever, with no retry cap, no log, and no user-visible surface (only the `purchase(pack:)` path surfaces errors). The user has paid, never receives credits, and nothing ever tells them.
**Fix:** Branch on error type in `handle(transaction:)` — retryable failures keep the leave-unfinished contract; permanent failures (`CreditsAPIError.invalidTransaction`) should be logged/surfaced (and after N attempts, finish to clear the queue and escalate to support copy).

### WR-03: DEBUG builds route the whole money path to a no-op mock

**File:** `StressMonitor/StressMonitor/StressMonitorApp.swift:237-245`; `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift:24-28`
**Issue:** `#if DEBUG` returns `MockStoreKitService` and discards the `creditService` parameter. `MockStoreKitService.purchase(pack:)` sleeps 1 second and does nothing — no purchase sheet, no redemption, no balance change. Consequently `CreditsViewModel.purchaseSelectedPack()` shows neither success nor error (balance nil → nil), i.e., in every Debug build (including all simulator UAT) the "Buy 10 Credits · $1.99" button silently does nothing, and the deferred-grant/recovery path is unexercisable in Debug.
**Fix:** Gate the mock on an explicit opt-in (launch argument like `-mock-iap`, or DEBUG + a settings toggle) instead of the entire Debug configuration, so Debug builds with the `.storekit` scheme config can run the real StoreKit flow; the unused `creditService:` parameter then also stops being misleading.

### WR-04: Unverified consumable transactions are finished, destroying the only proof of purchase

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:314-318`
**Issue:** `.unverified` results are immediately `finish()`ed with the comment that no grant occurred. For a consumable, the unfinished transaction is the only redeliverable proof a user paid; finishing an unverified payload permanently destroys the recovery path (Apple's own sample code errors rather than finishing). If verification fails transiently (e.g., on-device cert chain issue), a paid pack is lost with no recourse.
**Fix:** Do not finish `.unverified` transactions; log and leave them for redelivery, matching the retry contract used for redemption failures.

### WR-05: "Restore purchases" button on the purchase-success screen does nothing

**File:** `StressMonitor/StressMonitor/Views/Premium/PurchaseSuccessView.swift:198-206, 217-221`
**Issue:** The button labeled "Restore purchases" only calls `dismiss()` — `restoreOrDismiss()` contains no restore logic (the comment admits it). Misleading UI on a paid flow invites support contacts and App Review scrutiny.
**Fix:** Wire it to the shared `StoreKitServiceProtocol.restorePurchases()` via environment injection, or delete the button (pack-mode already correctly omits it).

### WR-06: SettingsView preview crashes — CreditService missing from preview environment

**File:** `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:549-558`
**Issue:** `SettingsView` reads `@Environment(CreditService.self)` (line 9) but the preview injects only `AppRouter`, `PaywallController`, and a model container. Accessing `creditService.balance` in body traps at runtime ("No Observable object of type CreditService found"), so the preview is dead.
**Fix:** Add `.environment(CreditService())` to the preview (and `ChatBottomSheetView` previews if similarly affected).

### WR-07: SettingsView.init force-unwraps ModelContainer creation

**File:** `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:24-27`
**Issue:** `(try? ModelContainer(for: StressMeasurement.self, configurations: ...))!` — `try?` + `!` crashes at view construction if container creation ever fails. In-memory configs rarely fail, but this is a gratuitous crash vector on every SettingsView instantiation.
**Fix:** Use `makeContainer(at:)`-style recovery or a non-optional in-memory container constructed with `try!`-free fallback (e.g., reuse `StressMonitorApp.makeContainer(at: tempURL)`).

### WR-08: IAP_ENVIRONMENT parsing silently fails closed to Production

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:32-34`, `.env.example:7`
**Issue:** Only the exact string `"Sandbox"` selects `Environment.SANDBOX`; `"sandbox"`, `"SANDBOX"`, `"Development"`, or any typo silently becomes PRODUCTION, and every sandbox test purchase then fails verification with `INVALID_TRANSACTION` — an opaque failure mode during UAT exactly when the team will be testing purchases.
**Fix:** Accept case-insensitive `"sandbox"` and throw at startup (or log loudly) on any unrecognized value other than `Production`.

### WR-09: Unvalidated pagination on GET /credits?history

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/routes/credits.ts:55-62`
**Issue:** `parseInt(c.req.query("limit") ?? "20")` yields `NaN` for non-numeric input and accepts negatives/huge values; `NaN`/negative parameters produce a Postgres error → 500 instead of a 4xx. Also `select *` leaks the full row shape.
**Fix:** Clamp: `const limit = Math.min(Math.max(parseInt(q ?? "20") || 20, 1), 100)` (same for offset ≥ 0), and select explicit columns.

## Info

### IN-01: Premium chat writes fake deduction rows into the ledger

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/credits.ts:44-50`
**Issue:** Every premium-user message inserts `amount = -1, type = 'chat'` even though no credits were deducted. The transaction history shown by `GET /credits?history` is falsified for premium users and the table grows unbounded.
**Fix:** Skip the ledger insert on the premium path (or record a zero-amount audit row with a distinct type).

### IN-02: `premium_until` is never exposed to clients

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/credits.ts:6-11, 71-75`; `StressMonitor/StressMonitor/Models/CreditBalance.swift`
**Issue:** The migration adds `premium_until` but `CreditBalanceRow`/`balanceJson` never select or return it, and `CreditBalance` has no field for it — the app can never show "Premium renews <date>".
**Fix:** Add `premium_until` to the select list, the JSON envelope, and `CreditBalance` (optional String, like `freeResetAt`).

### IN-03: Migration test pins the exact migration count

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/scripts/migrate.test.ts:33`
**Issue:** `assertEquals(applied.length, 7)` breaks with the next added migration file — a maintenance landmine.
**Fix:** Assert `applied.length >= 7`, or derive the expected count from the migrations directory listing.

### IN-04: Dead nil-coalescing on a non-optional

**File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift:429`
**Issue:** `product.price ?? .zero` — `Product.price` is non-optional `Decimal`; the right side is never used and this emits a compiler warning.
**Fix:** `let pricePerPeriod = product.price`.

### IN-05: No positive-path JWS verification test

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.test.ts`
**Issue:** Only rejection paths (garbage/empty/forged) are tested. The root-cert embedding, `expiresDate` conversion, and (missing) revocation handling have no fixture-based positive test — which is exactly how CR-02's gaps went uncaught.
**Fix:** Add a fixture generated with Apple's test certificates (or the library's own test utils) covering valid decode, expired expiry, and revoked rejection.

### IN-06: SignedDataVerifier built with online revocation checks disabled

**File:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/src/lib/iap.ts:40-46`
**Issue:** `enableOnlineChecks = false` skips OCSP/CRL consultation, so a compromised/revoked intermediate would not be detected. Acceptable in many serverless setups, but on a purchase-verification path it deserves an explicit decision.
**Fix:** Document the tradeoff in the code, or enable online checks if the deploy environment permits egress.

---

_Reviewed: 2026-08-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
