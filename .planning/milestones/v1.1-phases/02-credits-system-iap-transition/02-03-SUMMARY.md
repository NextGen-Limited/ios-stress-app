---
phase: 02-credits-system-iap-transition
plan: 03
subsystem: credits-iap
tags: [storekit, consumables, deferred-grant, credits, testing]
requires: [CreditBalance, CreditServiceProtocol, StressAPIClient.getBalance, DEC-1, DEC-2]
provides: [CreditPack, CreditPackID, pack-catalog-resolution, StoreKitServiceProtocol.purchase(pack:), deferred-grant-orchestration, PurchaseTransactionHandle, PurchaseRedeemer, StressAPIClient.redeemPurchase, StressAPIClient.verifySubscription, CreditsAPIError.invalidTransaction, consumable-storekit-entries, BUILD-05-closed]
affects: [StoreKitService, StoreKitProductCatalog, StoreKitServiceProtocol, MockStoreKitService, StressAPIClient+Credits, StressMonitorProducts.storekit]
tech-stack:
  added: []
  patterns:
    - "deferred grant: server redeem BEFORE transaction.finish(), unfinished redelivery as the crash-retry path"
    - "PurchaseTransactionHandle protocol seam so StoreKit ordering is unit-pinnable without StoreKitTest"
    - "JWS travels as an explicit parameter sourced from VerificationResult.jwsRepresentation (not Transaction)"
key-files:
  created:
    - StressMonitor/StressMonitor/Services/StoreKit/CreditPack.swift
    - StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift
    - StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift
    - StressMonitor/StressMonitorTests/StressMonitorProducts.storekit
    - StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift
    - StressMonitor/StressMonitorTests/StressAPIClientCreditsTests.swift
    - StressMonitor/StressMonitorTests/PremiumViewModelTests.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
decisions:
  - "DEC-1 amendment (user-confirmed model): subscriptions stay in the catalog AND sync server-side premium via POST /premium/verify from all three detection points (purchase success, Transaction.updates, currentEntitlements refresh) — best-effort, never blocks finish"
  - "completePurchase is pure grant/finish orchestration; the authoritative refreshEntitlements stays at entry points so the grant is unit-pinnable"
  - "CreditPackID enum covers exactly DEC-2 packs-2 (small/large); no medium"
metrics:
  duration: "~50min active (split by a host-sleep interruption; wall-clock span ~8.3h)"
  completed: 2026-08-17
actuals:
  tokens: 11600
  tasks: 3
  commits: 4
status: complete
---

# Phase 02 Plan 03: Consumable Credit Packs + Deferred-Grant Purchase Flow Summary

Transitioned the iOS purchase surface from subscription-only to consumable credit packs with the funds-safe ordering (verify → server redeem → finish-only-after-ack, redelivery as the retry path), plus the DEC-1 amendment syncing subscription purchases to server-side premium — every ordering guarantee pinned by protocol-level tests, not convention.

## What Was Built

| Commit | Task | Content |
|---|---|---|
| cbe3211 | 1 (RED) | Failing catalog/pack tests: 3-tier pack resolution, DEC-2 defaultPacks, pack(for:)/packID(for:) round-trips |
| f2383a5 | 1 (GREEN) | CreditPack model + CreditPackID, catalog pack keys (STOREKIT_CREDITS_{SMALL,LARGE}_PRODUCT_ID, additive), 2 Consumable entries in StressMonitorProducts.storekit (SMCP0010 $1.99 / SMCP0150 $19.99) — subscription groups untouched per DEC-1 |
| 28f89b3 | 2 (RED) | Failing CreditPurchaseFlowTests (pbxproj A016/B016) + StressAPIClientCreditsTests redemption/verify contract pins |
| 04f8e9e | 2 (GREEN) | purchase(pack:) with deferred grant, unified completePurchase choke point, pack-aware Transaction.updates handling, redeemPurchase/verifySubscription clients, packs-era restore copy, conformer updates |

Task 3 (Release build proof) changed no code — its outcome is recorded below.

### The flow this plan pins

`purchase(pack:)` shares steps 1–3 with subscriptions via `purchaseProduct(resolving:)` (resolve ID → fetch/cache Product → purchase sheet). Step 4 is the deferred grant: `checkVerified` → `redeemer(VerificationResult.jwsRepresentation)` → `transaction.finish()` → `creditService.apply(balance)`. A redeemer failure propagates to the purchase UI and leaves the transaction unfinished — `Transaction.updates` redelivers it and `handle(transaction:jwsRepresentation:)` runs the identical orchestration with failures swallowed (redelivery is the retry). Subscription productIDs keep the legacy immediate finish (restorable via currentEntitlements) plus the DEC-1 server-verify call. PremiumState is never flipped by pack purchases (pinned by test).

## Verification Results

- **JWS property spelling (research A1) — closed by compile:** `jwsRepresentation` exists on `VerificationResult`, NOT on `Transaction` (the compiler rejected the Transaction conformance; the plan's fallback guidance was followed). The handle protocol deliberately excludes it; the JWS is sourced from the `VerificationResult` at each call site and travels as an explicit parameter.
- **BUILD-05 — empirically CLOSED:** `xcodebuild build -scheme StressMonitor -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17'` exits **0**. The `#if DEBUG`/`#else` guards in StoreKitServiceEnvironment.swift are intact at HEAD; the historical MockStoreKitService-in-Release blocker does not reproduce. This also proves all new code compiles in Release.
- Targeted suites (all `-parallel-testing-enabled NO`): StoreKitProductCatalogTests **16/16** (10 pre-existing unmodified + 6 new), CreditPurchaseFlowTests **7/7**, StressAPIClientCreditsTests **7/7** (3 pre-existing + 4 new), PremiumViewModelTests **13/13**.
- Contract cross-check vs 02-02's pinned block: path `credits/redeem`, body key `transaction_jws` (only field — asserted `json.count == 1`), Bearer header, 200 → CreditBalance, 400 `INVALID_TRANSACTION` → typed `CreditsAPIError.invalidTransaction`, 401 → unauthorized. Byte-level match.
- Acceptance pins: `grep -c 'storeKitCredits' StoreKitProductCatalog.swift` = **2**; comment-filtered legacy restore copy = **0** occurrences; `grep -c 'refreshEntitlements' StressMonitorApp.swift` = **1** (IAP-03 foreground path); `grep -c 'storeKitService' StressMonitorApp.swift` = **3** (IAP-02 ownership/environment/refresh unchanged).
- Full suite: **94 tests / 17 suites, 0 test failures** — exit 65, see Deviation 5.
- `.storekit` JSON validates: exactly 2 Consumable products with credits-bearing IDs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test host crashed at launch — gitignored GoogleService-Info.plist missing from the worktree**
- **Found during:** Task 1 GREEN run
- **Issue:** `FirebaseApp.configure()` aborted the test host before any test ran; the Firebase config is gitignored so it exists in the main checkout but not in this isolated worktree
- **Fix:** Copied the file from the main checkout into the worktree (stays gitignored, zero commit impact)

**2. [Rule 3 - Blocking] Protocol-conformance ripple beyond the plan's file list**
- **Issue:** Adding `purchase(pack:)` to `StoreKitServiceProtocol` breaks every conformer; the plan lists FakeStoreKitService (tests) but not `MockStoreKitService.swift` (DEBUG app-target double), which would not compile in Debug builds
- **Fix:** Added `purchase(pack:)` to both doubles; the mock never flips premium for packs (packs grant credits, not premium)
- **Files modified:** StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift

**3. [Rule 1 - Bug] Authoritative refresh inside the shared orchestration made the grant unpinnable**
- **Found during:** Task 2 GREEN (2 tests failing: `state.isPremiumUser == false` after subscription grant)
- **Issue:** Ending `completePurchase` with `refreshEntitlements()` (mirroring the original inline ordering) wipes the just-granted premium whenever StoreKit's `currentEntitlements` is empty — invisible in production (real entitlements exist post-purchase) but it also meant the unit suite could only ever observe the wiped state
- **Fix:** `completePurchase` is now pure grant/finish orchestration; the authoritative `refreshEntitlements()` moved to the calling entry points (`purchase(_ plan:)` after completePurchase — byte-identical production ordering to the original grant→finish→refresh — and `handle(transaction:)` after the do/catch). Net production behavior unchanged; the grant is now honestly observable in tests
- **Files modified:** StoreKitService.swift
- **Commit:** 04f8e9e

### Documented Deviations

**4. [Scope amendment — DEC-1 user model] Subscription server-premium verify implemented against a minimal mirrored contract**
- 02-02-PLAN.md was checked per the amendment instructions: it builds ONLY `POST /credits/redeem` — no `/premium/verify` endpoint contract exists yet. Per the amendment's fallback, `StressAPIClient.verifySubscription(jws:)` codes to `POST /premium/verify` mirroring the pinned redeem contract exactly (same `transaction_jws`-only body, Bearer auth, CreditBalance response decode, same error mapping). Called from all three amendment detection points (purchase success, updates listener, currentEntitlements refresh); best-effort — a failure never blocks finish and converges on the next foreground refresh. Pinned by StressAPIClientCreditsTests + 3 CreditPurchaseFlowTests cases. **Open dependency:** the backend endpoint itself (02-02 successor work or 02-04) — recorded in WINDOWS.md.
- Production wiring note: the app-scope `CreditService` instance is not yet injected into the app-scope `StoreKitService` (both are inline-initialized `@State` properties that cannot reference each other; wiring requires the App-init refactor that belongs with the pack-purchase UI). The seam is init-injectable and tested; the server grant — the money-critical half — does not depend on it. Balance display converges via the existing foreground/paywall `GET /credits`. This is 02-04's integration point, not a silent stub.

**5. [Environment] Full-suite exit 65 despite 94/94 tests passing**
- 6 "Restarting after unexpected exit, crash, or test timeout" host events, each executing 0 tests before relaunch. Identical signature to 02-01 Deviation 6 / WINDOWS.md entry #8 (pre-existing TEST-01 CoreSimulator cold-launch lineage; every suite passes once a launch survives; all targeted runs exit 0). Confirmed reproducing; no new ledger entry needed — entry #8 covers it.

**6. [Research A1 resolution] JWS is on VerificationResult, not Transaction**
- The plan's action text said "the verified transaction's JWS representation property" — compile-verified as `VerificationResult.jwsRepresentation`; `Transaction` has no such member. The handle protocol excludes JWS and call sites source it from the verification result. Closes A1 with the corrected spelling.

## Suites Disabled With Reason

Unchanged from 02-01: `EntitlementForegroundCorrectionTests` and `StoreKitProductCatalogLiveTests` remain disabled-with-reason. Re-enabling them is tied to IAP-01 (Release-config product-ID resolution via real Info.plist keys / ASC products), which is the ASC-side user_setup item below — not resolvable from this plan's code-only scope.

## Known Stubs

None blocking. Two deliberate, tested-seam deferrals, both 02-04's scope by design:
1. App-scope `CreditService` injection into the app's `StoreKitService` instance (see Deviation 4) — the redeem path still grants server-side without it; only instant local balance refresh waits for 02-04's pack-purchase UI.
2. Live StoreKit purchase-path coverage (`Product.purchase` steps 1–3) requires a StoreKitTest session — the disabled-suite issue documented in StoreKitServiceTests.swift; the ordering logic those runs would exercise is pinned by CreditPurchaseFlowTests at the handle seam.

## Deferred Issues

- ASC filing (user_setup) **pending**: the two DEC-2 consumable products must be created in App Store Connect before Release-configuration product resolution (IAP-01) is claimable; local `.storekit` covers Debug/test meanwhile. Human dashboard action, same-day filing recommended.
- `/premium/verify` backend endpoint does not exist yet (Deviation 4) — client calls will 404 harmlessly (best-effort semantics) until it ships.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: new-endpoint | StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift | `verifySubscription` adds a client→backend surface not in the plan's threat model (DEC-1 amendment). Same mitigations as /credits/redeem: Bearer-authenticated, server independently verifies the JWS, client never asserts amounts; response is advisory display state only. |

## Self-Check: PASSED

Both created files verified present on disk; all 4 task commits (cbe3211, f2383a5, 28f89b3, 04f8e9e) verified in `git log`.
