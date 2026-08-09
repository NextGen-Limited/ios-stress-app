# IAP / StoreKit 2 Audit — StressMonitor (App Store publish readiness)

**Date:** 2026-08-08
**Scope:** in-app purchase / StoreKit 2 dimension
**Branch:** feature/spm-cache-integration
**Auditor:** axiom iap-auditor

> Persisted by the orchestrator — the audit run had no Write tool available.

**Files audited:** `Services/StoreKit/`, `Services/Premium/PaywallController.swift`,
`ViewModels/PremiumViewModel.swift`, `Views/Premium/**`,
`StressMonitorTests/{PremiumViewModelTests,StoreKitProductCatalogTests}.swift`, `project.pbxproj`,
both `Info.plist` copies, `docs/monetization/entitlement-map.md`,
`docs/plans/B2-REAL-STOREKIT-PREMIUM-IMPLEMENTATION.md`.

## IAP Architecture Map

- **StoreKit version:** StoreKit 2 only (`Product.products`, `Transaction.updates`/`currentEntitlements`, `AppStore.sync`). No StoreKit 1 APIs — promoted-purchase handler pattern is N/A.
- **Product types:** 3 auto-renewable subscriptions (weekly / monthly / annual) in one subscription group. No consumables or non-consumables.
- **Architecture:** Centralized. `StoreKitService` (`@MainActor`, conforms to `StoreKitServiceProtocol`) is the only call site for `Product.products` / `product.purchase()`. `#if DEBUG`-gated `MockStoreKitService` swapped in via `PaywallView.makeStoreKitService()`. Only call site of `PaywallView(reason:)` / `IAPPremiumView` is `MainTabView.swift:106`.
- **Transaction lifecycle:** Listener exists, verification exists (`checkVerified`, `.unverified` throws, never force-unwrapped), `.finish()` is called on both verified and unverified paths. **But** the listener's lifetime is bound to the paywall screen's `@State`, not the app process — see CRITICAL-1.
- **Restore path:** Present and reachable — "Restore" in `IAPFooterLinks` (`IAPUtilityRow.swift:47`) → `PremiumViewModel.restorePurchases()` → `StoreKitService.restorePurchases()` → `AppStore.sync()` + `refreshEntitlements()`.
- **Server validation:** Absent by design (project docs: no external servers for IAP). Not flagged as a gap under the documented architecture.
- **Product ID configuration:** `StoreKitProductCatalog` resolves IDs Bundle Info.plist → `ProcessInfo.environment` → `UserDefaults.standard`. **None of the three resolves in any build configuration** — see CRITICAL-2.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH | 6 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **13** |

## IAP Health Score

| Metric | Value |
|---|---|
| Rejection-risk patterns | 0 missing restore + 0 missing terms-structure, **but** 2 misrepresentation findings (fabricated annual "Save 37%", unconditional "7-day free trial" with no offer backing) |
| Revenue-risk patterns | 1 listener-not-app-lifetime + 1 no-product-IDs-configured + 1 permanent-entitlement-bypass |
| Subscription state coverage | 5/5 states coded in `refreshEntitlements()`, but **0% reachable** — gated behind `subscriptionGroupID`, which never resolves (dead code, same root cause as CRITICAL-2) |
| Server validation | ABSENT — by design |
| Test coverage | PARTIAL — catalog + view model (against a fake) tested; real `StoreKitService` StoreKit-2 surface has **zero** coverage. No `.storekit` file exists. |
| **Health** | **NOT READY** (2 CRITICAL) |

## CRITICAL

### 1. `Transaction.updates` listener and entitlement refresh are bound to the paywall's view lifecycle, not the app process

**Files:** `Services/StoreKit/StoreKitService.swift:14-26` (init/deinit),
`Views/Premium/PaywallView.swift:19-20`, `StressMonitorApp.swift` (no StoreKit/PremiumState
reference anywhere), `Services/Premium/PaywallController.swift:56-60`

`StoreKitService` — the only place `Transaction.updates` is consumed and `refreshEntitlements()`
is called — is constructed *only* inside `PaywallView.body`, held by `IAPPremiumView`'s `@State`.
`StressMonitorApp.swift` never instantiates it, never calls `refreshEntitlements()`, never
presents the paywall at launch. `PremiumState.shared.isPremiumUser` is read straight from
`UserDefaults` with zero entitlement verification for the entire session unless the user happens
to open the paywall.

Worse: `PaywallController.present(reason:)` (`:58`) **no-ops when `isPremiumUser == true`** — so
once a user is flagged premium (correctly or stale-ly), the paywall (the only thing that ever
constructs `StoreKitService`) can never be shown to them again. There is no Settings
"Manage Subscription"/"Refresh" row providing an alternate entry point.

**Impact:** Renewals, cancellations, refunds/revocations, Family Sharing changes, and delayed
Ask-to-Buy approvals arriving while the paywall is off-screen (i.e. almost always) are never
observed. A refunded subscriber keeps Premium indefinitely with no self-healing path. Queued
transactions are not permanently lost — they deliver on the next paywall open — but can sit
unresolved for the entire interval between paywall visits.

**Fix:** Own one `StoreKitService` at app scope (`@State` in `StressMonitorApp`, injected via
`.environment`), started once at launch. Remove the per-presentation
`Self.makeStoreKitService()` factory from `PaywallView`. Additionally call `refreshEntitlements()`
on `scenePhase == .active`, mirroring the existing `DashboardView.swift:66-70` HealthKit pattern.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Listener/refresh tied to paywall view lifecycle | Immediate — every subscriber, every session | App-wide: every Premium-gated feature relies on the stale flag | Medium — move ownership to app root + environment injection | Very High |

### 2. No StoreKit product IDs resolve in any build configuration — the purchase button is non-functional in every real build

**Files:** `Services/StoreKit/StoreKitProductCatalog.swift:44-140`,
`Models/SubscriptionPlan.swift:54-94` (`defaultPlans`, all `productID: nil`),
`Services/StoreKit/StoreKitService.swift:30-65,71-76`

**Verdict on the Info.plist lead — confirmed, with an important nuance:**

1. `INFOPLIST_FILE` for the main target (`project.pbxproj:604,655`, both configs) resolves to
   `StressMonitor/StressMonitor/Info.plist`, which is `<dict/>` — confirmed by direct read.
2. The Info.plist with real content lives one directory up, orphaned, at `StressMonitor/Info.plist`,
   referenced by no build setting — confirmed.
3. **However**, the standard privacy/usage keys are *not* missing from the shipped app: they are
   duplicated as `INFOPLIST_KEY_*` build settings in `project.pbxproj:605-617` and `656-668`
   (e.g. `INFOPLIST_KEY_NSCameraUsageDescription`, `INFOPLIST_KEY_UIBackgroundModes`), and
   `GENERATE_INFOPLIST_FILE=YES` merges those into the generated plist regardless of which file
   `INFOPLIST_FILE` names. **The general Info.plist mismatch is currently inert for standard keys.**
4. **For StoreKit it is not inert:** there is no `INFOPLIST_KEY_STOREKIT_PREMIUM_*` build setting
   anywhere, and *neither* Info.plist contains `STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID` /
   `..._MONTHLY_PRODUCT_ID` / `..._ANNUAL_PRODUCT_ID` / `..._SUBSCRIPTION_GROUP_ID`.
   `ProcessInfo.environment` and `UserDefaults.standard` have no write sites outside test code.
   Known gap: `docs/plans/B2-REAL-STOREKIT-PREMIUM-IMPLEMENTATION.md:36,98-146` calls this out as
   a P0 external gate.

So the lead's mechanism is real but is not *currently* the proximate cause — the proximate cause
is that the keys exist in neither file. The mismatch becomes the proximate cause the moment
someone "fixes" this by editing the wrong file (see HIGH-1).

**Impact:** `catalog.allProductIDs` is empty → `availablePlans` returns
`SubscriptionPlan.defaultPlans` (mock prices, `productID: nil`) → user sees a fully rendered
paywall with plans and prices → taps Subscribe → `purchase()` resolves
`plan.productID ?? catalog.productID(for:)`, both nil → **throws
`StoreKitError.missingProductConfiguration` every time**, in Debug, TestFlight, and App Store
builds alike. Guaranteed purchase failure, guaranteed rejection, 100% revenue loss.

**Fix:** (a) create the subscription products in App Store Connect, (b) inject IDs via
`INFOPLIST_KEY_STOREKIT_PREMIUM_*` build settings (or into whichever plist actually wins — verify
with `xcodebuild -showBuildSettings`), (c) create a `.storekit` config for local QA (HIGH-5),
(d) add a CI check that fails a Release archive when `StoreKitProductCatalog.live.allProductIDs`
is empty.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| No product IDs resolve anywhere | Immediate — blocks submission entirely | 100% of purchase attempts, all 3 plans | Low-Med — ASC product creation (external) + one build-setting change | Very High |

## HIGH

### 1. Info.plist mismatch is a landmine for the natural fix to CRITICAL-2

**Files:** `project.pbxproj:604,655`; `StressMonitor/StressMonitor/Info.plist` (empty,
build-referenced); `StressMonitor/Info.plist` (orphaned, has real content, zero build linkage)

A developer fixing CRITICAL-2 will most likely open `StressMonitor/Info.plist` — the file that
*looks* real because it has genuine content — and add the `STOREKIT_PREMIUM_*` keys there. That
edit has **zero effect**: the build reads the empty stub, and the project's actual pattern for
custom keys is `INFOPLIST_KEY_*` build settings.

**Fix:** Either delete the orphaned `StressMonitor/Info.plist` and consolidate on
`INFOPLIST_KEY_*` (matching the existing pattern), or repoint `INFOPLIST_FILE` at the file with
content and fold the build-setting duplicates back in. Either way, add a CI assertion that greps
the *compiled* `Info.plist` inside the built `.app` for `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID`.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Wrong Info.plist referenced by build | High — bites the *next* product-ID attempt | Whole IAP feature, again, after apparent fix | Low | High |

### 2. Premium characters permanently unlocked on purchase, no relock on expiry/cancel/refund

**Files:** `Views/Premium/PurchaseSuccessView.swift:14,77,159-181` (`unlockPremiumCharacters()`,
called from `.task` on every appearance), `ViewModels/CharacterCollectionViewModel.swift:30-40`
(gates purely on `CharacterUnlock.isUnlocked`)

`PurchaseSuccessView` shows after every successful purchase *and* restore
(`IAPPremiumView.swift:130-141`). Its `.task` sets `CharacterUnlock.isUnlocked = true` for
`["ember","zephyr","lumi"]` — additively, permanently. **No code path anywhere sets `isUnlocked`
back to `false`.** The consumer never re-checks `PremiumState.isPremiumUser`.

**Impact:** Subscribe → trigger the screen once → cancel/refund within Apple's window → the
premium characters stay unlocked forever, fully decoupled from the subscription. A reproducible
entitlement bypass, independent of CRITICAL-1/2.

**Fix:** Either make the read-side check live (`unlock.isUnlocked && premiumState.isPremiumUser`),
or add a relock pass in `refreshEntitlements()` / the `Transaction.updates` handler that clears
`isUnlocked` for `unlockedByPremium` characters when `hasActive` goes false.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Permanent local unlock bypasses subscription | High — refund abuse | Character collection, 100% reproducible per user | Low-Med | High |

### 3. Annual plan shows a per-month price under a "/year" label, plus a hardcoded "Save 37%"

**Files:** `Views/Premium/Components/PlanCard.swift:110-120`, `:149-156`, `:158-164`;
`Models/SubscriptionPlan.swift:25-31`; `Services/StoreKit/StoreKitService.swift:259-261`

For the annual plan the price line renders `plan.pricePerMonth` (e.g. `$14.99`) next to
`periodUnitDisplay` (`"/year"`) — displaying **"$14.99/year"** when the real annual charge
(`pricePerPeriod`) is ~$179.88. Separately, `planFromProduct` never computes a real
`savingsPercent` (explicitly left nil: "We'd need both prices for savings calc"), so
`leftFooter(for:)` always falls back to the literal string **"Save 37%"** in production — a number
unrelated to whatever is configured in ASC.

**Impact:** Guideline 3.1.2(a) misrepresentation risk, plus "I was charged $179.88, the app said
$14.99/year" refund tickets.

**Fix:** Show `plan.priceDisplay` (`product.displayPrice`) next to `/year`, with an optional
"≈ $14.99/mo" caption; compute `savingsPercent` for real by loading monthly and annual together
and comparing normalized per-month prices.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Misleading annual price + fabricated savings % | High — seen at the moment of purchase | Annual tier, which is flagged "Best Value" and pre-selected | Medium | High |

### 4. "7-day free trial" shown unconditionally with no offer configuration or eligibility check

**File:** `Views/Premium/IAPPremiumView.swift:58-59,151-182` (`trialBanner`, always rendered,
static text)

The banner is hardcoded copy, not driven by `product.subscription?.introductoryOffer` nor gated on
`isEligibleForIntroOffer`. No introductory offer is referenced anywhere, and per CRITICAL-2 no real
products exist yet.

**Impact:** Either the app advertises a trial it will not deliver (charge on tap — clear 3.1.2(a)
violation), or ineligible users who already used the trial see it and are charged with no warning.

**Fix:** Drive the banner from the product's `introductoryOffer` and gate on
`try await product.subscription?.isEligibleForIntroOffer` per selected plan.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Unconditional trial claim | High — first thing every prospect sees | Every plan, every first-time paywall visit | Medium | High |

### 5. No `.storekit` configuration file exists anywhere in the repository

Confirmed absent via glob across `StressMonitor/` and repo root. Combined with CRITICAL-2, the
purchase/restore/entitlement flow has **never been exercised**, even locally, against real
StoreKit 2 mechanics. `docs/plans/B2-REAL-STOREKIT-PREMIUM-IMPLEMENTATION.md:844-859` documents
manual QA steps that are currently blocked by this.

**Fix:** Create `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit` with the 3
subscriptions in one group and wire it into the scheme's Run → Options → StoreKit Configuration.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| No local StoreKit test config | High — blocks all pre-submission QA | Entire IAP surface | Low | High |

### 6. Zero test coverage of the real StoreKit 2 integration surface

`PremiumViewModelTests` tests against `FakeStoreKitService`, never `StoreKitService`.
`StoreKitProductCatalogTests` covers ID-resolution logic only. `purchase()`, `restorePurchases()`,
`refreshEntitlements()`, `handle(transactionVerification:)`, and `planFromProduct` have no coverage.

**Impact:** No regression safety net for the refactor that CRITICAL-1 requires.

**Fix:** Once HIGH-5 lands, add `StoreKitTest`-based integration tests for purchase
success/cancel/pending, verified/unverified handling, and `refreshEntitlements()`.

## MEDIUM

- **`PaywallView.body` recreates a full `StoreKitService` on every body evaluation**
  (`Views/Premium/PaywallView.swift:19-33`). `Self.makeStoreKitService()` runs on each body
  invocation even though `@State` only honors the first; each discarded instance spawns its own
  `Transaction.updates` loop. Self-limiting (deinit cancels), but wasteful and a race source once
  CRITICAL-1 is fixed. Mostly disappears with the CRITICAL-1 fix.
- **Subscription-group status lookup is dead code**
  (`Services/StoreKit/StoreKitService.swift:180-196`). `Product.SubscriptionInfo.status(for:)` is
  guarded by `if let groupID = catalog.subscriptionGroupID`, always nil today. The
  `.subscribed/.inGracePeriod/.inBillingRetryPeriod → active`, `.expired/.revoked → inactive`
  mapping is correct on paper but never executes.
- **Raw StoreKit/network errors fall through to `error.localizedDescription`**
  (`ViewModels/PremiumViewModel.swift:54-56,72-74`). The app's own `StoreKitError` cases have good
  copy; Apple's `StoreKitError`/`URLError` produce "The operation couldn't be completed…". Add a
  translation layer in `StoreKitService`.

## LOW

- **No App Group entitlement + Watch/Widget read no premium state.** Confirmed via grep that
  nothing under `StressMonitorWatch Watch App/` or `StressMonitorWidget/` references
  `PremiumState`/`isPremiumUser`; per `docs/monetization/entitlement-map.md` watch complications
  are explicitly free. No current bug; blocks any *future* premium-gated Watch/Widget feature.
- **`default: break` instead of `@unknown default`**
  (`Services/StoreKit/StoreKitService.swift:184-191`) — loses the future-case compiler warning; a
  new OS status case would silently fall into "inactive".

## Recommendations

1. **Immediate (blocks submission):** CRITICAL-1 (move `StoreKitService` ownership to app launch,
   inject via environment, add `scenePhase` refresh) and CRITICAL-2 (create ASC products, wire IDs
   through a build setting — verify with `xcodebuild -showBuildSettings`). Fix HIGH-1 *as part of*
   CRITICAL-2 so the trap doesn't reappear. Fix HIGH-2 before any subscriber can exploit it.
2. **Short-term:** HIGH-3 and HIGH-4 (both direct 3.1.2(a) risks) before submission. Add the
   `.storekit` file (HIGH-5) and use it for real integration tests (HIGH-6).
3. **Long-term:** Tidy the `PaywallView` re-instantiation (MEDIUM-1), wire the subscription-group
   status path once `subscriptionGroupID` is configured (MEDIUM-2), translate raw StoreKit/network
   errors (MEDIUM-3).

## Unresolved Questions

1. Are the real ASC product IDs / subscription group ID already decided outside this repo, or does
   CRITICAL-2 represent the first time they need to be created? The B2 plan doc treats this as an
   open external gate.
2. Is the "7-day free trial" a real product decision (create the offer in ASC to match the copy),
   or aspirational copy written before StoreKit wiring existed? Determines whether HIGH-4's fix is
   "wire the eligibility check" or "remove the claim".
3. Should the Ember/Zephyr/Lumi unlocks be permanent one-time grants by product design — in which
   case HIGH-2 is a docs gap in `entitlement-map.md` (which currently frames them as
   subscription-gated) rather than a code fix — or should they track live subscription state?
4. Any plan to move entitlement checks server-side (the backend already handles credits/auth), or
   is client-only StoreKit verification an accepted risk for this threat model?
