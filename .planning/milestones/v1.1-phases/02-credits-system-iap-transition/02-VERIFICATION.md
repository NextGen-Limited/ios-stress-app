---
phase: 02-credits-system-iap-transition
verified: 2026-08-23T00:00:00Z
status: passed
score: 29/29 must-haves verified
behavior_unverified: 0 # Both human items validated by user 2026-08-23 (live money-path smoke on deployed backend + design-system visual inspection)
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 20/26
  gaps_closed:
    - "Truth 13 / CR-04 — pack product-ID build settings + verified Info.plist delivery + re-enabled live suite (02-05)"
    - "Truth 24 / CR-01 — purchased_credits bucket, free-first consumption, usage-only reset (02-06)"
    - "Truth 25 / CR-02 — expired/revoked transactions never activate premium; iOS posting guard (02-07), superseded and extended by CR-05 demotion semantics (02-08)"
    - "Truth 26 / CR-03 — effective premium enforced at deductCredit + chat 402 live gates (02-07)"
  gaps_remaining: []
  regressions: []
human_verification: # external deployment/ASC/live-smoke + visual conformance — recorded as human items, not code gaps
  - test: "Deploy stress-app-be (image rebuild with --force, apply all unapplied migrations through 20260817120000_purchased_credits — incl. 20260816120000_redeem, 20260816120100_premium_until — and set APPLE_APP_LE_ID), file the two DEC-2 consumables in App Store Connect, then run the 5-step live money-path smoke on a Release build"
    expected: "Fresh user provisions 50 credits; chat 402 presents outOfCredits paywall; sandbox small-pack purchase increments balance exactly +10 once; relaunch shows server-persisted balance; restore shows packs-era copy. If feasible, a real sandbox refund of a subscription should demote server-side premium (CR-05 end-to-end) and a refunded pack should clear without retry loops (WR-10 end-to-end)"
    why_human: "Requires external deployment, ASC product filing, and a sandbox tester — outward-facing actions with lead time; DEBUG builds route purchases through MockStoreKitService (WR-03), so only a Release build against deployed infra can exercise the live path"
  - test: "Visual design-system inspection of the packs-era paywall (subscription grid + OR TOP UP ONCE section + balance header), chat balance pill, and Settings rows at standard and accessibility Dynamic Type sizes"
    expected: "Dual coding (color always paired with icon/text), accessible type scaling, >=44pt targets, haptic feedback on selection/purchase"
    why_human: "Visual/layout properties grep cannot measure; PackCard and ChatBottomSheetView show zero accessibleDynamicType usages statically"
behavior_unverified_items:
  - truth: "A real sandbox purchase of the small pack against the deployed backend increments the displayed balance exactly once"
    test: "Release-config build on simulator, sandbox-purchase small pack, observe balance; relaunch and re-check (5-step smoke)"
    expected: "Balance increments +10 exactly once; server-persisted after relaunch; 402 mid-chat lands on outOfCredits paywall"
    why_human: "Backend not yet deployed with the new migrations, ASC consumables not filed; DEBUG builds route the money path through MockStoreKitService (purchase no-op), so only a Release build against deployed infra can exercise this"
  - truth: "New paywall UX meets the design system (dual coding, accessibleDynamicType, >=44pt targets, HapticManager feedback)"
    test: "Visual inspection of paywall, chat pill, and Settings rows across Dynamic Type sizes"
    expected: "Color always paired with icon/text; text scales accessibly; all targets >=44pt; selection/purchase haptics fire"
    why_human: "Layout/visual conformance is not measurable by grep; partial static evidence only"
---

# Phase 2: Credits System + IAP Transition — Final Re-Verification Report

**Phase Goal:** Integrate /credits API, transition StoreKit from subscription to consumable credit packs, credits-gated chat access (402 INSUFFICIENT_CREDITS → paywall), new paywall UX with balance display.
**Verified:** 2026-08-17T09:25:00Z
**Status:** human_needed
**Re-verification:** Yes — final, after two gap-closure cycles (02-05..02-08)

## Goal Achievement

All four prior verification gaps (CR-01..CR-04) are closed in code and pinned by tests **that I re-ran in this verification**: the backend suite passed 17 tests / 50 steps against the live local postgres (8 migrations applied), the two behavior-dense iOS suites passed 17 tests / 2 suites on the simulator, and the Release build exited 0. The cycle-2 review findings (CR-05 refund demotion, WR-10 refunded-pack loop) are likewise implemented and test-pinned; the 02-07 pin inversion left no contradictory pair (`revokedSubscriptionNeverSyncs` = 0 occurrences; `revokedSubscriptionPostsDemotionSignalWithoutGranting` passes; the `expiredSubscriptionNeverSyncs` pin is retained and passing). Every code-level must-have of the phase goal is now verified. What remains is external by nature: backend deployment + ASC filing + the live money-path smoke, and visual design-system conformance — both recorded as human verification items, not code gaps.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Authenticated balance from GET /credits visible in paywall header; premium renders "Unlimited", never the 999999 sentinel | ✓ VERIFIED | `StressAPIClient+Credits.getBalance()` present; sentinel literal count in shipped app sources = 0 (re-grepped this run); regression greps green |
| 2 | Chat 402 INSUFFICIENT_CREDITS routes to paywall `present(reason: .outOfCredits)` | ✓ VERIFIED | ChatViewModel :164-168 re-grepped; ChatBottomSheetView closure injection intact |
| 3 | Terminal SSE metadata (credits_remaining) converges balance; no client-side decrement arithmetic | ✓ VERIFIED | StressLLMService `onCreditsRemainingChange` :29/:123 → ChatBottomSheetView :52 `creditService?.apply(creditsRemaining:)`; CreditService has no arithmetic (unchanged) |
| 4 | 01-REVIEW CR-01 closed: stress context flows through send(), static side-channel gone | ✓ VERIFIED | `currentStressContext` count across app sources = 0 (re-grepped) |
| 5 | No orphaned test suites | ✓ VERIFIED | 28 StressMonitorTests files, all pbxproj-registered (re-checked); no new unregistered files |
| 6 | xcodebuild invocations use -parallel-testing-enabled NO | ✓ VERIFIED | Both verifier-run invocations used it |
| 7 | POST /credits/redeem verifies Apple JWS; client-asserted amounts ignored | ✓ VERIFIED | routes/credits.ts reads only `transaction_jws`, PACK_CREDITS server-side map (:84-92); iap rejection tests green in my run |
| 8 | Redeem idempotent on Apple transaction id | ✓ VERIFIED | PK insert first in `sql.begin` (:100-103); "replaying the same jws returns unchanged balance" passed in my backend run |
| 9 | Invalid/unverified JWS → 400 INVALID_TRANSACTION, writes nothing | ✓ VERIFIED | iap.test.ts garbage/empty/forged cases green in my run |
| 10 | Every grant leaves 'purchase' ledger row + idempotency row | ✓ VERIFIED | redeemCredits :104-107; ledger cases green in my run |
| 11 | Pack purchase: redeem → finish only after ack | ✓ VERIFIED | "Pack purchase redeems exactly once with the JWS before finish" passed in my iOS run |
| 12 | Crash between purchase and ack recovered at next launch | ✓ VERIFIED | "Updates-listener path routes a pack through the same redeem-before-finish ordering" + "…leaves the transaction unfinished for redelivery" passed in my iOS run |
| 13 | Pack product IDs resolve through the 3-tier mechanism in real builds (CR-04) | ✓ VERIFIED | pbxproj `INFOPLIST_KEY_STOREKIT_CREDITS_{SMALL,LARGE}_PRODUCT_ID` at :850-851 (Debug) / :907-908 (Release), both inside the `stress.ai.com` app-target blocks (PRODUCT_BUNDLE_IDENTIFIER :868/:925); Info.plist carries 6 literal STOREKIT_* keys, `plutil -lint` OK; `INFOPLIST_FILE` wired :842/:899; **StoreKitProductCatalogLiveTests 6/6 passed in my simulator run — small + large pack IDs and round-trip resolved from the hosted app's Bundle.main** (empirical delivery proof) |
| 14 | Packs appear in StressMonitorProducts.storekit as Consumable entries | ✓ VERIFIED | 2 `"type": "Consumable"` entries, credits.small + credits.large (re-grepped) |
| 15 | Restore copy no longer claims subscription-only semantics | ✓ VERIFIED | Legacy restore-copy grep count = 0 (re-run) |
| 16 | Release-configuration build compiles (BUILD-05) | ✓ VERIFIED | Re-ran in this verification: `xcodebuild build -configuration Release` exit 0 |
| 17 | Transaction.updates listener owned at app scope | ✓ VERIFIED | StoreKitService init :52 `listenForTransactions()` (re-grepped) |
| 18 | Paywall presents pack cards + per-unit savings + live balance header + reset date + premium Unlimited | ✓ VERIFIED | IAPPremiumView "OR TOP UP ONCE" :189, PackCard :197; header/reset lines intact |
| 19 | Purchase success derived from post-purchase server balance | ✓ VERIFIED | CreditsViewModel :112-117 `balanceBefore` comparison (re-read this run) |
| 20 | Balance at every DEC-2 placement (chat pill + paywall header + Settings row) | ✓ VERIFIED | balancePill (2 refs) + CreditBalanceFormatter in SettingsView (2 refs) re-grepped |
| 21 | Real sandbox purchase against deployed backend increments balance exactly once | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code path complete and unit-pinned; blocked on backend deployment + ASC filing (external). See behavior_unverified_items |
| 22 | User who exhausts credits mid-chat lands on paywall, no dead-end | ✓ VERIFIED | ChatViewModel presentation + PaywallView "You're out of credits" :44 (re-grepped) |
| 23 | UI meets design system (dual coding, accessibleDynamicType, >=44pt, Haptics) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Visual conformance unmeasurable by grep; zero accessibleDynamicType usages in PackCard/ChatBottomSheetView. See behavior_unverified_items |
| 24 | Purchased pack credits persist until spent (CR-01, 02-06) | ✓ VERIFIED | Migration `20260817120000_purchased_credits.sql` (ADD COLUMN + `user_credits_purchased_nonnegative` CHECK + legacy normalization — exactly 3 statements); **live DB check: column + constraint present, 8 migrations in schema_migrations**; `redeemCredits` increments `purchased_credits` (:110), `resetMonthlyCredits` sets `used_credits = 0` only; **"resetMonthlyCredits preserves purchased balance", "redeemCredits purchased bucket", "deductCredit free-first consumption" all passed in my backend run** |
| 25 | Premium verify rejects invalid transactions; iOS never posts expired JWS; revoked JWS handled per CR-05 (CR-02, 02-07 + 02-08) | ✓ VERIFIED | `/premium/verify` rejects `expiresAt === null \|\| <= now` (:128-133) and revoked-with-null-expiry (:117); `/redeem` uses `redeemVerify` = rejectingRevoked-wrapped (:39, :80); `verifyAndDecodeTransaction` returns revoked payloads with revocationDate (signature chain untouched); **"expired subscription jws is rejected 400 without activating premium", "revoked pack jws is rejected 400" (both routes), and iOS `expiredSubscriptionNeverSyncs` all passed in my runs** |
| 26 | Premium expiry enforced at live gates, not only the cron (CR-03, 02-07) | ✓ VERIFIED | `deductCredit` selects `(premium_until is null or premium_until > now()) as premium_active` under FOR UPDATE and requires `plan_type === "premium" && premium_active` (:40-50); chat 402 gate mirrors the rule (chat.ts :35-45); **"deductCredit effective premium" and "chat route premium gate" (expired+empty → 402, active+empty → streams) passed in my backend run** |
| 27 | CR-05 backend: revoked subscription JWS DEMOTES premium (`least(premium_until, revocationDate)` under replay-window guard), 200; /redeem still rejects revoked; no idempotency insert on demotion | ✓ VERIFIED | `demotePremiumOnRevocation` (credits.ts :168-187): guarded `least()` UPDATE + plan_type flip, WHERE `premium_until is not null AND premium_until <= expiresAt AND premium_until > revocationDate`, zero `iap_redemptions` inserts; route branch :116-126 before expiry rejection; **all 6 cases passed in my backend run: demotion-to-revocation-date, replay convergent no-op, old-revocation-cannot-shorten-newer-term, dead-term plan_type flip, same-jws activation-then-revocation (no 23505→500), null-until immunity** |
| 28 | CR-05 iOS: revoked known-subscription JWS POSTed before finish, never grants/clears premiumState; 02-07 pin inversion left no contradictory pair | ✓ VERIFIED | completePurchase :386-390 revoked-subscription branch textually precedes `isActive` (:392), calls sync then finish, no premiumState write; **`revokedSubscriptionPostsDemotionSignalWithoutGranting` passed in my iOS run (callCount 1, receivedJWS, finishCountAtVerify == 0 — POST precedes finish —, finish 1, !isPremiumUser)**; `revokedSubscriptionNeverSyncs` grep count = 0 |
| 29 | WR-10: refunded pack finished with ZERO redemption attempts on both entry points; no clawback (pinned decision) | ✓ VERIFIED | Pack-arm guard :371-377 (finish + return before redeemer) with the no-clawback WHY-note; `handle()` routes the updates-listener path through the same `completePurchase`; **"Revoked pack transaction is finished without any redemption attempt" AND "Updates-listener path finishes a revoked pack instead of retrying forever" (redeemer throwing invalidTransaction, finish 1) both passed in my iOS run** |

**Score:** 27/29 truths verified (2 present, behavior-unverified; 0 failed)

### Deferred Items

None. No later phase in the milestone covers the two behavior-unverified items — they are external user actions (deployment/ASC/smoke) and a visual inspection, recorded under Human Verification.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `project.pbxproj` pack build settings | 2 keys x 2 app-target configs | ✓ VERIFIED | 4 lines (:850-851/:907-908) inside the two `stress.ai.com` blocks; watch/widget/test blocks untouched |
| `StressMonitor/StressMonitor/Info.plist` | 6 STOREKIT_* literal keys | ✓ VERIFIED | plutil OK; values match DEC-2 SKUs + premium IDs/group |
| `StressMonitorTests/StoreKitProductCatalogLiveTests.swift` | Enabled, 6 tests incl. pack assertions | ✓ VERIFIED | 0 disabled markers; 6/6 passed in my run |
| `stress-app-be/migrations/20260817120000_purchased_credits.sql` | Additive column + CHECK + normalization | ✓ VERIFIED | Applied in live local DB (psql-confirmed); migrate.test.ts expects 8 and passed |
| `stress-app-be/src/lib/credits.ts` | Purchased bucket + free-first + effective premium + demotion | ✓ VERIFIED | All four behaviors present; pinned by my test run |
| `stress-app-be/src/lib/cron.ts` | Usage-only reset | ✓ VERIFIED | `used_credits = 0` + `free_reset_at` only; pinned by "preserves purchased balance" |
| `stress-app-be/src/lib/iap.ts` | revocationDate extraction; rejectingRevoked (/redeem-only) | ✓ VERIFIED | Decode-level throw removed (revoked payloads returned); signature verification untouched |
| `stress-app-be/src/routes/credits.ts` | Per-route revocation policy + demotion branch | ✓ VERIFIED | redeemVerify on /redeem; raw verifier + demotion branch on /premium/verify |
| `StressMonitor/…/StoreKitService.swift` completePurchase | Revoked-sub demotion post; revoked-pack guard; expired unposted | ✓ VERIFIED | Source read :346-418; ordering verified textually and behaviorally |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| pbxproj/Info.plist STOREKIT_* keys | Bundle.main → StoreKitProductCatalog tier 1 → packID(for:) → purchase | INFOPLIST_FILE merge | ✓ WIRED | Empirically proven by hosted live suite (6/6) reading the app bundle |
| `rejectingRevoked(verifyTransaction)` | `/credits/redeem` ONLY | `redeemVerify` binding at route factory :39 | ✓ WIRED | Pinned by revoked-pack-400 route case |
| Raw verifier + revocation branch | `/credits/premium/verify` → demotePremiumOnRevocation | Branch :116-126 before expiry rejection | ✓ WIRED | Pinned by 6 demotion route cases |
| completePurchase revoked-subscription branch | syncSubscriptionEntitlementToServer → POST → demotion UPDATE | seam :386-390 | ✓ WIRED | Pinned by inverted spy case (finishCountAtVerify == 0) |
| Pack-arm revocation guard | transaction.finish() with redeemer never invoked | :371-377, both entry points (handle → completePurchase) | ✓ WIRED | Pinned by 2 WR-10 cases |
| deductCredit premium_active / chat gate premiumActive | Same effective-premium rule at both gates | SQL-derived under FOR UPDATE / TS-derived from row | ✓ WIRED | Pinned by effective-premium + chat-gate cases |
| redeemCredits → purchased_credits → derivedTotal → balanceJson → iOS CreditBalance | SQL projection | `total_credits + purchased_credits as total_credits` | ✓ WIRED | Route suites unchanged and green; contract byte-identical |
| StressMonitorApp → creditService environment → paywall/chat/settings | `.environment(creditService)` | unchanged from initial verification | ✓ WIRED | Quick regression grep green; Release path composes StoreKitService + creditService (DEBUG branch still mock — WR-03 warning) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| PaywallView balance header / chat pill / Settings rows | creditService.balance | GET /credits via refreshBalance + SSE metadata | Yes (server-authoritative; "—" pre-convergence by design) | ✓ FLOWING |
| Paywall pack cards | packs | storeKit.availablePacks → Product.products | Yes — product IDs now resolve from Bundle.main in real builds (live suite proof); ASC filing still required for sandbox/device purchases | ✓ FLOWING (device-purchasable after ASC filing) |
| CreditsViewModel.showSuccess | balance before/after | redeemer response → creditService.apply | Yes at unit level; end-to-end gated on deployment | ✓ FLOWING (unit-pinned) / live-gated |

### Behavioral Spot-Checks (all run by this verifier, 2026-08-17)

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Backend full gap-closure suite (CR-01/02/03/05: purchased bucket, free-first, reset preservation, revocation/expiry rejection, effective premium at both gates, demotion 6-case block, chat premium gate, idempotency, migrations) | `DATABASE_URL=…5433/stress_app deno test src/lib/credits.test.ts src/lib/cron.test.ts src/lib/iap.test.ts src/routes/credits.test.ts src/routes/chat.test.ts scripts/migrate.test.ts` | **17 passed (50 steps), 0 failed** | ✓ PASS |
| iOS money-path flow: redeem-before-finish, redelivery, revoked-pack loop break (both paths), revoked-sub demotion post, expired never synced, active grants | `xcodebuild test -only-testing:…/CreditPurchaseFlowTests …` | **11/11 passed** | ✓ PASS |
| iOS real-build product-ID resolution (Bundle.main delivery tier) | `xcodebuild test -only-testing:…/StoreKitProductCatalogLiveTests …` | **6/6 passed** (incl. small/large pack + round-trip) | ✓ PASS |
| Live DB schema state | `psql -h 127.0.0.1 -p 5433 …` | 8 rows in schema_migrations (incl. 20260817120000); `purchased_credits` column + `user_credits_purchased_nonnegative` constraint present | ✓ PASS |
| Release build (BUILD-05) | `xcodebuild build -configuration Release` | exit 0, BUILD SUCCEEDED | ✓ PASS |
| Backend type/lint/format | `deno task check` / `deno lint` / `deno fmt --check` | all clean (39 files) | ✓ PASS |

Note: the executor-reported full-suite figure (97 tests / 17 suites on the merged branch) was not re-run in full per the single-run constraint; the targeted runs above are the independent evidence for every behavior-dependent truth.

### Probe Execution

No probe scripts declared in plans and no `scripts/*/tests/probe-*.sh` found — SKIPPED (not a probe-based phase).

### Requirements Coverage

No active `.planning/REQUIREMENTS.md` (v1.0 archive only); plans declare requirement IDs directly.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| AUTH-02 | 02-01, 02-04 | Live-session probe via credit surface, typed 401 | ✓ SATISFIED (live kill-check rides gated smoke) | unchanged from initial verification |
| IAP-01 | 02-03, 02-05 | Product IDs resolve in Release configuration | ✓ SATISFIED (ID-resolution half empirically closed; sandbox purchase rides the gated smoke) | Live suite 6/6 against hosted Bundle.main |
| IAP-02 | 02-03 | Transaction.updates listener app-scope lifetime | ✓ SATISFIED | init :52 |
| IAP-03 | 02-03 | Foreground entitlement refresh | ✓ SATISFIED | refreshEntitlements at entry points |
| IAP-04 | 02-01, 02-04 | Premium gating semantics intentional | ✓ SATISFIED | unchanged |
| IAP-05 | 02-04 | Pricing display accuracy | ✓ SATISFIED | computed per-unit savings (unchanged) |
| IAP-06 | 02-02..02-08 | E2E money path verified | ? NEEDS HUMAN | Deployment-gated live smoke (see Human Verification) |
| BUILD-05 | 02-03, 02-05..08 | Release build compiles | ✓ SATISFIED | Re-ran: exit 0 |
| derived-CR-01 (02-06) | Purchased credits persist | ✓ SATISFIED | Backend suite green in my run |
| derived-CR-02/CR-03 (02-07) | Revocation/expiry rejection; effective premium at gates | ✓ SATISFIED | Backend + iOS suites green in my runs |
| derived-CR-05 / derived-WR-10 (02-08) | Refund demotion; refunded-pack loop break | ✓ SATISFIED | 6 backend demotion cases + 3 iOS cases green in my runs |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| StressMonitor/StressMonitor/StressMonitorApp.swift | 239 | DEBUG money path routes to MockStoreKitService (WR-03, review) | ⚠️ Warning | Debug/simulator UAT of purchases is a no-op; live smoke must use Release config |
| StressMonitor/StressMonitor/Views/Settings/SettingsView.swift | 549-559 | `SettingsView_Previews` injects AppRouter/PaywallController but not CreditService (WR-06, review) | ⚠️ Warning | Dead/crashing preview; outside gap-closure scope, unchanged |
| StressMonitor/…/StoreKitService.swift | ~314-318 | `.unverified` consumables finished (WR-04, review — open) | ⚠️ Warning | Paid pack unrecoverable on transient verification failure |
| stress-app-be/src/routes/chat.ts | 78 | `getMaxTokens(remaining, credits.plan_type)` uses raw plan_type while gates use effective premium (IN-07, review) | ℹ️ Info | Expired-premium user gets premium-sized token budget funded from finite buckets |
| stress-app-be/src/routes/credits.ts | 117 | Revoked-subscription-with-null-expiresAt 400 guard has no dedicated test case (verifier disconfirmation pass) | ℹ️ Info | Guard exists in code; untested edge |
| stress-app-be — iap coverage | — | Demotion/rejection cases use injected fake verifiers; no real Apple-signed revoked fixture exists (IN-05, review — open) | ℹ️ Info | Policy logic fully pinned; real-decode-of-revoked-payload unproven until a sandbox refund |
| StressMonitor/…/ChatBottomSheetView.swift | 387, 437 | "not yet implemented" comment + "coming soon" copy | ℹ️ Info | Pre-existing v1.0 baseline (commit 4405668), not phase-introduced |

Debt-marker gate: 0 `TBD`/`FIXME`/`XXX` across all 33 phase-modified code files (iOS + backend). Stub-language hits in phase files all resolve to loading skeletons overwritten by fetch, documented neutral labels, or #Preview fixtures.

> ✅ **Human validation completed 2026-08-23** — user confirmed both items: live money-path smoke on the deployed backend (balance increments once and persists, 402 → paywall, restore copy) and design-system visual inspection (dual coding, type scaling, ≥44pt targets, haptics). Status advanced to passed.

### Human Verification Required

### 1. Live money-path smoke (deployment + ASC gated)

**Test:** Deploy stress-app-be (image rebuild, apply all unapplied migrations through `20260817120000_purchased_credits`, set `APPLE_APP_LE_ID`), file the two DEC-2 consumables (`com.stressmonitor.app.credits.small` $1.99/10, `.large` $19.99/150) in App Store Connect, then on a Release build: fresh user → 50 credits everywhere; chat to 402 → outOfCredits paywall; sandbox small-pack purchase → +10 exactly once; relaunch → server-persisted balance; restore → packs-era copy. If feasible: sandbox-refund a subscription (expect server-side demotion at the refund date, CR-05) and a pack (expect one-pass queue clear, WR-10).
**Expected:** Balance increments exactly once and persists; paywall carries balance/reset date; refund demotes server-side premium; refunded pack never wedges the queue.
**Why human:** Requires deployed backend, ASC products, sandbox tester, and a Release build (Debug routes purchases through a no-op mock) — none observable from the codebase.

### 2. Design-system conformance of the new surfaces

**Test:** Visually inspect paywall (subscription-led grid + OR TOP UP ONCE section + balance header), chat pill, Settings rows at standard and accessibility Dynamic Type sizes.
**Expected:** Dual coding everywhere, accessible type scaling, >=44pt targets, haptics on selection/purchase.
**Why human:** Layout/visual properties; static grep found zero accessibleDynamicType usages in PackCard and ChatBottomSheetView.

### Gaps Summary

No code gaps. All four previously failed truths (CR-01..CR-04) and both cycle-2 review findings (CR-05, WR-10) are implemented, wired, and pinned by tests this verifier independently re-ran: backend 17 tests / 50 steps green against the live local postgres (8 migrations applied, purchased_credits schema confirmed in-database), iOS 17 tests / 2 suites green on the simulator (including the live catalog suite proving Bundle.main product-ID delivery and the three refund-path flow cases), Release build exit 0, deno check/lint/fmt clean. The 02-07→02-08 pin inversion is clean: the contradictory `revokedSubscriptionNeverSyncs` pin is deleted, its replacement passes, and the retained `expiredSubscriptionNeverSyncs` pin still passes.

The phase goal is achieved at the code level for a real build. Remaining items are external by definition — backend deployment + ASC filing + live sandbox smoke, and visual design-system conformance — carried as the two human verification items above. Advisory review residue (WR-02..04, WR-06..09, IN-01..IN-08) remains at its recorded 02-REVIEW status; none is a phase must-have, and the money-path-relevant ones (WR-03/WR-04) are flagged above.

---

_Verified: 2026-08-17T09:25:00Z_
_Verifier: Claude (gsd-verifier)_
