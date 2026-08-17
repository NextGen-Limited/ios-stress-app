---
phase: 02-credits-system-iap-transition
verified: 2026-08-17T05:05:00Z
status: gaps_found
score: 20/26 must-haves verified
behavior_unverified: 2 # Live end-to-end money path (deployment-gated) + design-system visual conformance
overrides_applied: 0
gaps:
  - truth: "Purchasing a credit pack is possible in a real build — pack product IDs resolve through the 3-tier mechanism (Info.plist build setting → env → UserDefaults)"
    status: failed
    reason: "CR-04 (02-REVIEW, independently confirmed): project.pbxproj contains ZERO `STOREKIT_CREDITS_*` keys (grep count 0) while `INFOPLIST_KEY_STOREKIT_PREMIUM_*` keys exist at lines 850-853/905-908. `StoreKitProductCatalog.packID(for:)` therefore returns nil on any real device (no build setting, no env var, no UserDefaults entry), `availablePacks` falls back to `defaultPacks` with `productID: nil`, and `purchase(pack:)` throws `StoreKitError.missingProductConfiguration` (StoreKitService.swift:177). Pack purchase is dead in every real build; even the disabled StoreKitProductCatalogLiveTests documents that custom INFOPLIST_KEY_* values never reach the generated Info.plist, so the premium keys' delivery mechanism is equally unproven. The .storekit file only affects Xcode-run Debug sessions — and Debug sessions use MockStoreKitService (a purchase no-op)."
    artifacts:
      - path: "StressMonitor/StressMonitor.xcodeproj/project.pbxproj"
        issue: "No STOREKIT_CREDITS_SMALL/LARGE_PRODUCT_ID build settings in either configuration; premium subscription keys present but their Info.plist delivery is also unverified"
      - path: "StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift"
        issue: "purchase(pack:) throws missingProductConfiguration when productID is nil — the only outcome possible on-device today"
    missing:
      - "Add pack product-ID build settings in both app-target configurations alongside the premium keys"
      - "Verify the chosen delivery mechanism actually lands in Bundle.main (real Info.plist key or build-phase injection) — custom INFOPLIST_KEY_* never reach the generated Info.plist"
      - "Re-enable StoreKitProductCatalogLiveTests with pack assertions once resolution is real"
  - truth: "Purchased pack credits persist until spent (packs are one-time top-ups per user-confirmed DEC-2)"
    status: failed
    reason: "CR-01 (02-REVIEW, independently confirmed): stress-app-be cron `resetMonthlyCredits` runs `set total_credits = 50, used_credits = 0 where plan_type = 'free'` (src/lib/cron.ts:4-11) while `redeemCredits` adds purchased credits to the SAME `total_credits` column (`total_credits = total_credits + N`, src/lib/credits.ts:95-99). A free-tier user's remaining purchased credits are hard-reset to 50 on the 1st of every month — direct paid-value data loss on the phase's headline feature."
    artifacts:
      - path: "stress-app-be/src/lib/cron.ts"
        issue: "Monthly reset overwrites total_credits, destroying purchased pack credits"
      - path: "stress-app-be/src/lib/credits.ts"
        issue: "Purchased and free credits share the single total_credits column"
    missing:
      - "Separate purchased from granted balances (e.g. purchased_credits column; reset only the free allotment) and derive total accordingly in getBalance/deductCredit"
  - truth: "POST /credits/premium/verify rejects invalid transactions — an expired or revoked Apple transaction never activates server-side premium, and iOS never posts revoked/expired JWS to the server"
    status: failed
    reason: "CR-02 (02-REVIEW, independently confirmed): `VerifiedTransaction` (src/lib/iap.ts:19-23) extracts only transactionId/productId/expiresAt — no revocationDate anywhere. The route (src/routes/credits.ts:103-108) rejects only `expiresAt === null`, so an expired subscription's Apple-signed JWS activates premium and `greatest(premium_until, pastDate)` stores a past expiry; a refunded (revoked) transaction re-activates premium. iOS compounds it: `completePurchase` calls `syncSubscriptionEntitlementToServer` (StoreKitService.swift:368) BEFORE the `revocationDate == nil` / not-expired guard (lines 371-373), so revocations delivered via Transaction.updates are actively POSTed to the server."
    artifacts:
      - path: "stress-app-be/src/lib/iap.ts"
        issue: "No revocationDate extraction/check in verifyAndDecodeTransaction"
      - path: "stress-app-be/src/routes/credits.ts"
        issue: "/premium/verify rejects only null expiry — expired (non-null, past) transactions pass"
      - path: "StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift"
        issue: "Server entitlement sync runs before the revocation/expiry guard in completePurchase"
    missing:
      - "Backend: extract revocationDate, throw on it; reject expiresAt <= now in /premium/verify"
      - "iOS: move the revocationDate == nil && not-expired guard ahead of syncSubscriptionEntitlementToServer"
  - truth: "Premium entitlement is enforced at live gates — an expired premium user does not retain unlimited chat"
    status: failed
    reason: "CR-03 (02-REVIEW, independently confirmed; same root concern as CR-02): `deductCredit` checks only `plan_type === 'premium'` (src/lib/credits.ts:44) and the chat 402 gate checks `credits.plan_type !== 'premium'` (src/routes/chat.ts:34) — neither consults `premium_until`. Demotion happens only in the monthly cron ('0 0 1 * *'), so a subscriber whose term ends mid-month keeps unlimited chat for up to ~31 days."
    artifacts:
      - path: "stress-app-be/src/lib/credits.ts"
        issue: "deductCredit premium branch ignores premium_until"
      - path: "stress-app-be/src/routes/chat.ts"
        issue: "402 gate ignores premium_until"
    missing:
      - "Derive effective premium (plan_type = 'premium' AND premium_until > now()) inside deductCredit and the chat gate; keep the cron as janitor only"
behavior_unverified_items:
  - truth: "A real sandbox purchase of the small pack against the deployed backend increments the displayed balance exactly once"
    test: "Release-config build on simulator, sandbox-purchase small pack, observe balance; relaunch and re-check (5-step smoke from 02-04-SUMMARY)"
    expected: "Balance increments +10 exactly once; server-persisted after relaunch; 402 mid-chat lands on outOfCredits paywall; restore shows packs-era copy"
    why_human: "Backend (stress-api.dropitx.site) is not deployed with the new migrations, ASC consumables are not filed, and the deployed auth middleware 401s every /credits/* path so route presence is indistinguishable without a Firebase token; DEBUG builds route the money path through MockStoreKitService (purchase no-op), so only a Release build against deployed infra can exercise this"
  - truth: "New paywall UX meets the design system (dual coding, accessibleDynamicType, >=44pt targets, HapticManager feedback)"
    test: "Visual inspection of paywall (subscription grid + OR TOP UP ONCE pack section + balance header), chat pill, and Settings rows across Dynamic Type sizes"
    expected: "Color always paired with icon/text; text scales accessibly; all targets >=44pt; selection/purchase haptics fire"
    why_human: "Grep shows PaywallView/IAPPremiumView carry dynamicType+haptics and PackCard/pill carry accessibility labels, but PackCard and ChatBottomSheetView show zero accessibleDynamicType usages and 44pt conformance is a layout property grep cannot measure"
human_verification: # surfaced for the end-of-phase checkpoint even though overall status is gaps_found
  - test: "Deploy stress-app-be (image rebuild + migrations 20260816120000/20260816120100 + APPLE_APPLE_ID), file the two DEC-2 consumables in ASC, then run the 5-step live money-path smoke on a Release build"
    expected: "Fresh user provisions 50 credits; chat 402 presents outOfCredits paywall; sandbox small-pack purchase increments balance exactly +10 once; relaunch shows server-persisted balance; restore shows packs-era copy"
    why_human: "Requires external deployment + App Store Connect filing + a sandbox tester — outward-facing actions with lead time that cannot be executed or observed from the codebase"
  - test: "Visual design-system inspection of the packs-era paywall, chat balance pill, and Settings balance rows"
    expected: "Dual coding, accessible Dynamic Type, >=44pt targets, haptic feedback on selection/purchase"
    why_human: "Visual/layout conformance is not measurable by grep; partial static evidence only"
---

# Phase 2: Credits System + IAP Transition Verification Report

**Phase Goal:** Integrate /credits API, transition StoreKit from subscription to consumable credit packs, credits-gated chat access (402 INSUFFICIENT_CREDITS → paywall), new paywall UX with balance display.
**Verified:** 2026-08-17T05:05:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The client-side credits spine, the 402→paywall routing, the packs-era paywall UX, and the backend redemption endpoint are genuinely built, wired, and test-pinned — every targeted suite I ran passed and the Release build compiles. However, the money path has four verified integrity holes (02-REVIEW CR-01..CR-04, each independently re-confirmed in code during this verification): pack purchases cannot succeed in ANY real build (CR-04), purchased credits are destroyed by the monthly reset (CR-01), and the premium path accepts expired/revoked transactions with expiry enforced only monthly (CR-02/CR-03). "Transition StoreKit to consumable credit packs" is not yet achieved end-to-end for a real user.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Authenticated balance fetched from GET /credits, visible in paywall header; premium renders "Unlimited", never the 999999 sentinel | ✓ VERIFIED | `StressAPIClient+Credits.getBalance()` (authorizedRequest "credits" → CreditBalance decode, :32-46); `CreditBalance.displayDescription` premium→"Unlimited" (Model:35-37); PaywallView balanceHeader :41-70; sentinel literal count in shipped sources = 0; CreditServiceTests + StressAPIClientCreditsTests ran green in this verification (26 tests/3 suites) |
| 2 | Chat 402 INSUFFICIENT_CREDITS routes to paywall `present(reason: .outOfCredits)` | ✓ VERIFIED | ChatViewModel :164-168 (`insufficientCredits` → message + `presentPaywall?(.outOfCredits)`); PaywallController :68-69 (outOfCredits bypasses premium guard); ChatBottomSheetView :50 injects the closure; ChatLifecycleTests ran green in this verification (12 tests/2 suites) |
| 3 | Terminal SSE metadata (credits_remaining) converges the balance; no client-side decrement arithmetic | ✓ VERIFIED | StressLLMService `apply(metadata:)` → `onCreditsRemainingChange` sink (:114-123); ChatBottomSheetView :51-52 wires sink → `creditService.apply(creditsRemaining:)`; CreditService.swift contains only refresh/apply — no arithmetic |
| 4 | 01-REVIEW CR-01 closed: stress context flows through send(), static side-channel gone | ✓ VERIFIED | `currentStressContext` count across app sources = 0; `LLMServiceProtocol.send(stressContext:)` parameter present (:59-62) |
| 5 | No orphaned test suites; new suites pbxproj-registered | ✓ VERIFIED | Orphan check re-run: 28/28 StressMonitorTests files in Sources phase 3828578ADDAD4AC5925394DB |
| 6 | Every xcodebuild invocation uses -parallel-testing-enabled NO | ✓ VERIFIED | Both verifier-run test invocations used it; plan-pinned |
| 7 | POST /credits/redeem verifies Apple JWS; credits from server-side map; client-asserted amounts ignored | ✓ VERIFIED | routes/credits.ts :66-89 (reads only `transaction_jws`; PACK_CREDITS lookup); iap.ts SignedDataVerifier with embedded Apple Root CA G2+G3; iap.test.ts ran green in this verification (rejection paths); route test cases enumerated on disk ("forged amount fields in the body are ignored") |
| 8 | Redeem idempotent on Apple transaction id; replay 200, no double-credit | ✓ VERIFIED | credits.ts :85-109: PK insert into `iap_redemptions` is the FIRST statement of one `sql.begin` — unique violation aborts the grant atomically; replay catch returns current balance without writes; migration has `apple_transaction_id TEXT PRIMARY KEY`. Test existence proven ("replaying the same jws returns unchanged balance", "grants pack credits once with a purchase ledger row"); DB-backed re-run blocked at verification time (executor's local postgres on :5433 is down — environment, not code) |
| 9 | Invalid/unverified JWS → 400 INVALID_TRANSACTION, writes nothing | ✓ VERIFIED | iap.ts wraps all verifier failures in InvalidTransactionError; route catches → 400 before any write; iap.test.ts ran green (garbage/empty/forged rejection) |
| 10 | Every grant leaves a 'purchase' ledger row + idempotency row | ✓ VERIFIED | credits.ts :87-94 inserts both rows inside the transaction; test case enumerated |
| 11 | Pack purchase: Product.purchase → verify → server redeem → finish() only after ack | ✓ VERIFIED | StoreKitService `completePurchase` :361-364 (redeemer → finish → apply); CreditPurchaseFlowTests ran green in this verification incl. "redeems exactly once with the JWS before finish" and "Redeem failure propagates and never finishes the transaction" |
| 12 | Crash between purchase and server-ack recovered at next launch via Transaction.updates | ✓ VERIFIED | `handle(transaction:jwsRepresentation:)` :383-394 runs identical orchestration; suite cases "Updates-listener path routes a pack through the same redeem-before-finish ordering" + "leaves the transaction unfinished for redelivery" ran green |
| 13 | Pack product IDs resolve through the 3-tier mechanism in real builds | ✗ FAILED | CR-04 (see gaps): `grep -c STOREKIT_CREDITS project.pbxproj` = 0; packID nil on device → `purchase(pack:)` throws missingProductConfiguration (StoreKitService.swift:177). Pack purchase dead in every real build |
| 14 | Packs appear in StressMonitorProducts.storekit as Consumable entries | ✓ VERIFIED | JSON parses: 2 Consumable products, `com.stressmonitor.app.credits.small` $1.99 + `.large` $19.99 (matches DEC-2 packs-2) |
| 15 | Restore copy no longer claims subscription-only semantics | ✓ VERIFIED | Comment-filtered restore copy in StoreKitService = 0 legacy occurrences; pack-mode success view omits restore affordance |
| 16 | Release-configuration build compiles (BUILD-05) | ✓ VERIFIED | Re-ran in this verification: `xcodebuild build -configuration Release` exit 0 |
| 17 | Transaction.updates listener owned at app scope for process lifetime | ✓ VERIFIED | StoreKitService init :52 starts `listenForTransactions()`; single app-scope service built in StressMonitorApp.init |
| 18 | Paywall presents pack cards with prices + per-unit savings, live balance header, reset date, premium Unlimited | ✓ VERIFIED | IAPPremiumView "OR TOP UP ONCE" :189, PackCard :197, `savingsPercent(for:)` computed per-unit (:277-279, not hardcoded — the "33" literal is a #Preview fixture); PaywallView header + reset line :41-70; CreditsViewModelTests display-rule cases ran green |
| 19 | Purchase success derived from post-purchase server balance, not the call's return | ✓ VERIFIED | CreditsViewModel.purchaseSelectedPack compares `creditService.balance` before/after; CreditsViewModelTests ran green (part of 26-test run) |
| 20 | Balance at every DEC-2 placement (chat pill + paywall header + Settings row) | ✓ VERIFIED | ChatBottomSheetView balancePill :149-195 (tap→paywall at 0); SettingsView :144-146 + :273 via shared `CreditBalanceFormatter` |
| 21 | Real sandbox purchase against deployed backend increments balance exactly once | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code path complete and unit-pinned; blocked on backend deployment + ASC filing (external). See behavior_unverified_items |
| 22 | User who exhausts credits mid-chat lands on paywall, no dead-end | ✓ VERIFIED | ChatViewModel one-line message + presentation; PaywallView "You're out of credits" heading variant :43-44 |
| 23 | UI meets design system (dual coding, accessibleDynamicType, >=44pt, Haptics) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | PaywallView/IAPPremiumView: dynamicType + haptics present; PackCard/ChatBottomSheetView: 0 accessibleDynamicType usages; 44pt/visual conformance unmeasurable by grep |
| 24 | Purchased pack credits persist until spent (one-time top-ups) | ✗ FAILED | CR-01 (see gaps): monthly cron resets total_credits to 50, destroying purchased credits |
| 25 | Premium verify rejects expired/revoked transactions; iOS never syncs them | ✗ FAILED | CR-02 (see gaps): no revocationDate check; only null-expiry rejected; iOS syncs before the revocation guard |
| 26 | Premium expiry enforced at live gates (not only monthly cron) | ✗ FAILED | CR-03 (see gaps): deductCredit + chat 402 gate check plan_type alone |

**Score:** 20/26 truths verified (2 present, behavior-unverified; 4 failed)

### Deferred Items

None. Phase 3 (Sessions, Preferences, Quick Actions + Cleanup) does not cover any of the four failed truths — they are not scheduled in any later phase and remain actionable gaps. The deployment/ASC/live-smoke items are external user actions recorded under Human Verification, not later-phase work.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `StressMonitor/StressMonitor/Models/CreditBalance.swift` | Codable balance model with premium display rule | ✓ VERIFIED | 38 lines, CodingKeys for snake_case, isUnlimited/displayDescription |
| `StressMonitor/StressMonitor/Services/Credits/CreditServiceProtocol.swift` | Protocol | ✓ VERIFIED | 21 lines |
| `StressMonitor/StressMonitor/Services/Credits/CreditService.swift` | @MainActor @Observable display cache, no arithmetic | ✓ VERIFIED | 41 lines; wired via StressMonitorApp environment + foreground refresh (:180-221) |
| `StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift` | getBalance/redeemPurchase/verifySubscription | ✓ VERIFIED | 81 lines; verifySubscription posts `credits/premium/verify` (reconciled to backend) |
| `StressMonitor/StressMonitor/Services/StoreKit/CreditPack.swift` | Pack model + defaultPacks | ✓ VERIFIED | 42 lines, packs-2 small/large |
| `StressMonitor/StressMonitor/ViewModels/CreditsViewModel.swift` | Purchase state machine + formatter | ✓ VERIFIED | 136 lines; success from observed balance |
| `StressMonitor/StressMonitor/Views/Premium/Components/PackCard.swift` | Pack card view | ✓ VERIFIED | 183 lines |
| `StressMonitorTests/CreditServiceTests.swift` etc. (5 suites) | pbxproj-registered test suites | ✓ VERIFIED | All present; 38 tests across 5 suites ran green in this verification |
| `stress-app-be/src/lib/iap.ts` | JWS verification + product maps | ✓ VERIFIED (with CR-02 defect) | 70 lines; see gap 3 |
| `stress-app-be/src/routes/credits.ts` | POST /credits/redeem + /premium/verify | ✓ VERIFIED (with CR-02/CR-03 defects) | 121 lines; see gaps 3-4 |
| `stress-app-be/migrations/20260816120000_redeem.sql` | Idempotency table | ✓ VERIFIED | PK on apple_transaction_id, additive |
| `stress-app-be/migrations/20260816120100_premium_until.sql` | premium_until column | ✓ VERIFIED | Single ALTER ADD COLUMN |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| StressMonitorApp (@State creditService) | PaywallView/ChatViewModel/SettingsView/ChatBottomSheetView | `.environment(creditService)` + init-composed StoreKitService | ✓ WIRED | StressMonitorApp :180-200; Release path passes creditService into StoreKitService (:242-243); NOTE DEBUG branch discards it (MockStoreKitService — WR-03) |
| StressLLMService.apply(metadata:) | CreditService.apply(creditsRemaining:) | onCreditsRemainingChange sink injected by ChatBottomSheetView | ✓ WIRED | StressLLMService :114-123; ChatBottomSheetView :51-52 |
| ChatViewModel catch insufficientCredits | PaywallController.present(.outOfCredits) | injected presentPaywall closure | ✓ WIRED | ChatViewModel :164-168; ChatBottomSheetView :50 |
| StressAPIClient.getBalance() | GET credits, Bearer auth, CreditBalance decode | authorizedRequest(path: "credits") | ✓ WIRED | StressAPIClient+Credits :32-46 |
| StoreKitService.completePurchase | POST /credits/redeem → finish only after ack | redeemer seam → apiClient.redeemPurchase | ✓ WIRED | :50, :361-364; pinned by CreditPurchaseFlowTests (ran green) |
| CreditsViewModel | StoreKitService.purchase(pack:) + CreditService | injected protocols | ✓ WIRED | purchaseSelectedPack; CreditsViewModelTests ran green |
| Pack product IDs | Real-build resolution (build settings) | INFOPLIST_KEY_STOREKIT_CREDITS_* | ✗ NOT WIRED | CR-04: keys absent from pbxproj entirely — packs unresolvable on device |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| PaywallView balance header | creditService.balance | GET /credits via refreshBalance (foreground/paywall) | Yes (server-authoritative; nil renders "—" placeholder) | ✓ FLOWING |
| Chat pill / Settings rows | creditService.balance | Same source + SSE metadata convergence | Yes | ✓ FLOWING |
| Paywall pack cards | packs | storeKit.availablePacks → Product.products | Local .storekit only in Xcode-run Debug; nil-ID fallback on device | ⚠️ STATIC on device (CR-04) |
| CreditsViewModel.showSuccess | balance before/after | redeemer response → creditService.apply | Yes at unit level; end-to-end gated on deployment | ✓ FLOWING (unit-pinned) / ⚠️ live-gated |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Deferred-grant ordering (redeem-before-finish, exactly once, redelivery) | `xcodebuild test -only-testing:.../CreditPurchaseFlowTests -only-testing:.../ChatLifecycleTests` | 12 tests / 2 suites passed, TEST SUCCEEDED | ✓ PASS |
| 402→paywall routing + lifecycle | (same run) | ChatLifecycleTests green | ✓ PASS |
| Balance decode/no-arithmetic/sentinel + purchase-success-from-balance + API contracts | `xcodebuild test -only-testing:.../CreditsViewModelTests -only-testing:.../CreditServiceTests -only-testing:.../StressAPIClientCreditsTests` | 26 tests / 3 suites passed, TEST SUCCEEDED | ✓ PASS |
| Backend JWS rejection paths | `deno test src/lib/iap.test.ts` | 2 passed (4 steps), 0 failed | ✓ PASS |
| Backend type integrity | `deno task check` | exit 0 | ✓ PASS |
| Backend DB-backed suites (idempotency, routes, cron) | not re-runnable | local postgres :5433 down at verification time; test cases enumerated on disk; executor reported 25 passed | ? SKIP (environment) |
| Release build (BUILD-05) | `xcodebuild build -configuration Release` | exit 0 | ✓ PASS |

### Probe Execution

No probe scripts declared in plans and no `scripts/*/tests/probe-*.sh` found — SKIPPED (not a probe-based phase).

### Requirements Coverage

No active `.planning/REQUIREMENTS.md` exists (v1.0 archive at `.planning/milestones/v1.0-REQUIREMENTS.md`); plans declare requirement IDs directly.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| AUTH-02 | 02-01, 02-04 | Live-session probe via credit surface, typed 401 | ✓ SATISFIED (live kill-check rides gated smoke) | Foreground refreshBalance; CreditsAPIError.unauthorized |
| IAP-01 | 02-03 | Product IDs resolve in Release configuration | ✗ BLOCKED | CR-04 + ASC consumables not filed; StoreKitProductCatalogLiveTests still disabled-with-reason |
| IAP-02 | 02-03 | Transaction.updates listener app-scope lifetime | ✓ SATISFIED | StoreKitService init :52 |
| IAP-03 | 02-03 | Foreground entitlement refresh | ✓ SATISFIED | refreshEntitlements at entry points |
| IAP-04 | 02-01, 02-04 | Premium gating semantics intentional | ✓ SATISFIED | outOfCredits bypasses guard; PremiumState stays client-side |
| IAP-05 | 02-04 | Pricing display accuracy (computed savings) | ✓ SATISFIED | savingsPercent(for:) computed per-unit; "33" is a preview fixture |
| IAP-06 | 02-02, 02-04 | E2E money path verified | ? NEEDS HUMAN | Deployment-gated live smoke (see Human Verification) |
| BUILD-05 | 02-03 | Release build compiles | ✓ SATISFIED | Re-ran: exit 0 |
| derived-CR-01..07 | 02-01/02-02/02-03 | Contract/integrity pins | ✓ SATISFIED (CR-05/07 via suites ran green; CR-06 formatter pinned) | Test cases enumerated + targeted runs |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| project.pbxproj | 850-853, 905-908 | Pack product-ID keys absent (CR-04) | 🛑 Blocker | Pack purchase impossible in real builds |
| stress-app-be/src/lib/cron.ts | 4-11 | Monthly reset destroys purchased credits (CR-01) | 🛑 Blocker | Paid-value data loss |
| stress-app-be/src/lib/iap.ts + routes/credits.ts | 19-23, 103-108 | No revocation/expiry enforcement (CR-02) | 🛑 Blocker | Free premium from expired/refunded transactions |
| stress-app-be/src/lib/credits.ts + routes/chat.ts | 44, 34 | plan_type-only premium gates (CR-03) | 🛑 Blocker | Up to ~31 days free premium after expiry |
| StressMonitor/StressMonitor/StressMonitorApp.swift | 237-240 | DEBUG money path is a no-op mock (WR-03, review) | ⚠️ Warning | All Debug/simulator UAT of purchases silently does nothing; Release-only verification required |
| StressMonitor/Services/StoreKit/StoreKitService.swift | 314-318 | .unverified consumables finished, destroying recovery proof (WR-04, review) | ⚠️ Warning | Paid pack unrecoverable on transient verification failure |
| StressMonitor/Views/Settings/SettingsView.swift | 549-558 | Preview missing CreditService environment (WR-06, confirmed: preview injects only AppRouter/PaywallController) | ⚠️ Warning | Dead preview |
| StressMonitor/Views/Chat/ChatBottomSheetView.swift | 387, 437 | "not yet implemented" comment + "coming soon" copy | ℹ️ Info | Pre-existing v1.0 baseline (commit 4405668), not phase-introduced |

### Human Verification Required

### 1. Live money-path smoke (deployment + ASC gated)

**Test:** Deploy stress-app-be (image rebuild with `--force`, apply migrations 20260816120000 + 20260816120100, set APPLE_APPLE_ID), file the two DEC-2 consumables in App Store Connect, then on a Release build: fresh user → 50 credits everywhere; chat to 402 → outOfCredits paywall; sandbox small-pack purchase → +10 exactly once; relaunch → server-persisted balance; restore → packs-era copy.
**Expected:** Balance increments exactly once and persists; paywall carries balance/reset date; no phantom local credit.
**Why human:** Requires deployed backend, ASC products, sandbox tester, and a Release build (Debug routes purchases through a no-op mock) — none observable from the codebase.

### 2. Design-system conformance of the new surfaces

**Test:** Visually inspect paywall (subscription-led grid + OR TOP UP ONCE section), chat pill, Settings rows at standard and accessibility Dynamic Type sizes.
**Expected:** Dual coding everywhere, accessible type scaling, >=44pt targets, haptics on selection/purchase.
**Why human:** Layout/visual properties; static grep found zero accessibleDynamicType usages in PackCard and ChatBottomSheetView.

### Gaps Summary

Four verified defects block the phase goal, all cited from 02-REVIEW and independently re-confirmed in code during this verification:

1. **CR-04 — packs unpurchasable in any real build** (gap 1). The 3-tier resolution code exists and the .storekit entries are correct, but the build-settings tier was never configured: zero `STOREKIT_CREDITS_*` keys in the pbxproj, and the delivery mechanism itself (custom INFOPLIST_KEY_*) is unproven even for the premium keys added this phase. On device, `purchase(pack:)` throws `missingProductConfiguration`. This is the direct blocker for "transition StoreKit to consumable credit packs".
2. **CR-01 — monthly reset destroys purchased credits** (gap 2). Free and purchased credits share `total_credits`; the cron hard-resets it to 50 on the 1st of each month. Directly contradicts the user-confirmed "one-time top-ups" model.
3. **CR-02 — premium verify accepts expired/revoked transactions; iOS syncs them** (gap 3). No `revocationDate` anywhere; only null-expiry rejected; iOS posts the JWS before checking revocation/expiry.
4. **CR-03 — premium expiry enforced only by the monthly cron** (gap 4). Same entitlement-integrity concern as CR-02; grouped for the planner.

Gaps 3+4 share a root cause (server-side premium entitlement integrity) and could be planned as one fix sweep; gaps 1 and 2 are independent (iOS build configuration; backend balance schema).

What IS solid: the balance spine (GET /credits → CreditService → three placement-a surfaces), the 402→paywall routing with premium-guard bypass, SSE metadata convergence with zero client arithmetic, the deferred-grant ordering pinned by passing protocol tests, backend idempotency by PK construction, and a green Release build — 38 tests across 5 iOS suites plus backend rejection-path tests all ran green during this verification.

---

_Verified: 2026-08-17T05:05:00Z_
_Verifier: Claude (gsd-verifier)_
