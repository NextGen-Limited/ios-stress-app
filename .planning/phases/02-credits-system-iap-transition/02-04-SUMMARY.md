---
phase: 02-credits-system-iap-transition
plan: 04
subsystem: credits-iap
tags: [credits, paywall, storekit, pack-purchases, balance-surfaces, iap]
requires: [CreditBalance, CreditService, CreditServiceProtocol, DEC-1, DEC-2, StoreKitServiceProtocol.purchase(pack:), CreditPack, deferred-grant-orchestration]
provides: [CreditsViewModel, CreditBalanceFormatter, PackCard, availablePacks, packs-era-paywall, outOfCredits-contextual-copy, pack-mode-PurchaseSuccessView, chat-balance-pill, settings-balance-rows, creditService-storekit-wiring, credits/premium/verify-path-fix]
affects: [IAPPremiumView, PaywallView, PurchaseSuccessView, ChatBottomSheetView, SettingsView, StressMonitorApp, StoreKitServiceProtocol, StoreKitService, MockStoreKitService, CreditPack, StressAPIClient+Credits]
tech-stack:
  added: []
  patterns:
    - "success derived from observed service-state change, not purchase-call return (PremiumViewModel pattern applied to packs)"
    - "caseless-enum display formatter as the single source of balance strings across every surface"
    - "app-init composition: CreditService built once and injected into both the environment and the app-scope StoreKitService"
key-files:
  created:
    - StressMonitor/StressMonitor/ViewModels/CreditsViewModel.swift
    - StressMonitor/StressMonitor/Views/Premium/Components/PackCard.swift
    - StressMonitor/StressMonitorTests/CreditsViewModelTests.swift
  modified:
    - StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift
    - StressMonitor/StressMonitor/Views/Premium/PaywallView.swift
    - StressMonitor/StressMonitor/Views/Premium/PurchaseSuccessView.swift
    - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
    - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
    - StressMonitor/StressMonitor/StressMonitorApp.swift
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift
    - StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift
    - StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift
    - StressMonitor/StressMonitor/Services/StoreKit/CreditPack.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift
    - StressMonitor/StressMonitorTests/StressAPIClientCreditsTests.swift
    - StressMonitor/StressMonitorTests/PremiumViewModelTests.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
decisions:
  - "DEC-1 paywall layout: subscription grid stays the LEADING section; packs render as a secondary one-time section below it (per the recorded user-confirmed model, which amended the plan's option-a/b wording)"
  - "Pack purchase = select card + explicit section CTA (never tap-to-buy) — mirrors the subscription select-then-CTA pattern and avoids accidental purchase taps"
  - "availablePacks added to StoreKitServiceProtocol mirroring availablePlans (catalog+Product resolution with DEC-2 fallback) so pack prices are locale-accurate when products resolve"
  - "Plus row 'Active' derives from server plan_type (balance.isUnlimited), not local PremiumState — server is the authority for chat-premium semantics"
metrics:
  duration: ~108min
  completed: 2026-08-17
actuals:
  tokens: 15000    # chars/4 over the realized diff (60372 chars)
  tasks: 3
  commits: 5
status: complete
---

# Phase 02 Plan 04: Packs-Era Paywall + Balance Surfaces + E2E Sweep Summary

Shipped the packs-era user experience on top of the 02-01/02-03 machinery: a CreditsViewModel whose purchase success is derived from the observed server-balance change, a DEC-1 paywall (subscription-led, packs secondary) with live balance/reset-date header and out-of-credits contextual copy, the balance pill + Settings rows at every DEC-2 placement-a surface, and the app-scope CreditService→StoreKitService wiring — plus the mandated `/credits/premium/verify` endpoint reconciliation. The live money-path smoke is deployment-gated and surfaced as a blocking-human checkpoint (see Deferred Issues).

## What Was Built

| Commit | Task | Content |
|---|---|---|
| fc9476e | pre-Task-1 | Endpoint reconciliation: client verifySubscription path `/premium/verify` → `/credits/premium/verify` (backend authoritative); pinned URL test updated, suite 7/7 |
| ce1ad77 | 1 (RED) | Failing CreditsViewModelTests (pbxproj A017/B017): purchase state machine + display-rule cases |
| 8a63d63 | 1 (GREEN) | CreditsViewModel + CreditBalanceFormatter, packs-era IAPPremiumView (PackCard, pack CTA, per-unit savings), PaywallView balance header + outOfCredits variant + low-credits line, PurchaseSuccessView pack mode, availablePacks protocol surface + conformers, CreditPack.pricePerPack, StressMonitorApp creditService wiring |
| dc57672 | 2 (RED) | Failing surface-string cases: chatRowValue / plusRowValue |
| 64e7393 | 2 (GREEN) | Chat sheet balance pill (informational >0 credits, paywall tap-through at 0), Settings chat-row + Plus-row live values, balance refresh onAppear |

Task 3 changed no code — verification outcomes below.

### The shipped UX

- **Paywall (DEC-1, subscription-led):** plan grid leads with its sticky CTA; below it a secondary "OR TOP UP ONCE" pack section (small/large DEC-2 packs, skeleton placeholders while unresolved, per-unit price + "Save 33%" on large, Best Value badge, one-time-purchase fine print). Header shows live balance ("43 credits"/"Unlimited", placeholder "—" pre-convergence — never a sentinel, never a fake zero), the free reset date, the dual-coded low-credits expectation line under 20 credits (Pitfall 5), and the "You're out of credits" heading variant when presented from a chat 402.
- **Purchase flow:** select pack (haptic) → section CTA → `purchaseSelectedPack()` → `StoreKitService.purchase(pack:)` deferred grant (02-03) redeems server-side → the app-scope CreditService (now wired into the app-scope StoreKitService) converges → VM derives `showSuccess` from the observed balance change → pack-mode success view ("150 Credits Added", "New balance: …", no restore affordance — consumables are non-restorable).
- **Balance surfaces (placement-a complete):** chat sheet header pill (all states, tap→paywall(.outOfCredits) at zero, dual-coded icon+color), Settings Ripple Coach row ("Active · 43 credits" / "Active · Unlimited" / "Active" / "Coming soon"), Settings Plus row (server-premium "Active" / "43 credits left" / "Try free"), refreshed onAppear. Every string routes through `CreditBalanceFormatter` (4 usages across the two surface files).

## Endpoint Reconciliation (coordinator-mandated)

02-03's client called `POST /premium/verify`; 02-02's backend serves `POST /credits/premium/verify`. Backend is authoritative → `StressAPIClient+Credits.verifySubscription` now posts `credits/premium/verify`; `StressAPIClientCreditsTests` URL pin + test name updated. CreditPurchaseFlowTests injects a verifier spy (no URL pin) — no change needed there. Suite re-run green before any Task-1 work.

## Verification Results

- **Task 1:** CreditsViewModelTests 12/12 + PremiumViewModelTests 13/13, exit 0; sentinel-literal count in shipped sources **0** (comment-filtered); orphan count **0** (28/28 test files in the Sources phase — awk-scoped check from 02-01).
- **Task 2:** CreditsViewModelTests 14/14 (incl. 2 surface-string cases), exit 0; full app build exit 0; shared-formatter usage across ChatBottomSheetView + SettingsView = **4** (≥2 required).
- **Task 3 (runnable subset):** full suite — **all 28 distinct suites passed, 0 test failures**, including both new suites; exit 65 from 6 "unexpected exit" cold-launch host events (the pre-existing TEST-01 lineage, WINDOWS.md entry #8 — identical signature to 02-01 D6 / 02-03 D5; targeted runs all exit 0). Release-configuration build **exit 0** (fresh DerivedData path). Backend `/health` **200**.
- TDD gates: strict `test:` → `feat:` pairs for both tasks (ce1ad77→8a63d63, dc57672→64e7393); REFACTOR pass done (shared `successSeal` extraction intra-GREEN; PackCard kept as a PlanCard sibling per the plan's explicit allowance; formatter single-source by construction — suites re-run green, zero behavior change).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Protocol ripple from `availablePacks` beyond the plan's file list**
- **Issue:** Pack cards must render "from the catalog with accurate prices" but `StoreKitServiceProtocol` had no pack accessor; adding one breaks every conformer, including `MockStoreKitService` (DEBUG app double) and `FakeStoreKitService` (PremiumViewModelTests) — neither in the plan's files
- **Fix:** Added `var availablePacks: [CreditPack] { get async }`; StoreKitService resolves catalog IDs → `Product.products` (locale price, displayName, numeric `pricePerPack`) with DEC-2 `defaultPacks` fallback; Mock + Fake return `defaultPacks`; `CreditPack` gained `var pricePerPack: Decimal? = nil` (additive, memberwise-compatible)
- **Files modified:** StoreKitServiceProtocol.swift, StoreKitService.swift, MockStoreKitService.swift, CreditPack.swift, PremiumViewModelTests.swift
- **Commit:** 8a63d63

**2. [Rule 2 - Missing critical functionality] App-scope CreditService not injected into the app-scope StoreKitService**
- **Issue:** 02-03's recorded open integration point: both were inline-`@State` properties that cannot reference each other. Without wiring, purchase-path and `Transaction.updates` redelivery grants (`completePurchase` → `creditService?.apply`) never reach the displayed balance, and this plan's own must-have ("success derived from the post-purchase server balance") would be unreliable in production
- **Fix:** `StressMonitorApp.init` now builds `CreditService` once and composes both `@State` values from it; `makeStoreKitService(creditService:)` passes it to the Release `StoreKitService` (DEBUG keeps the mock unchanged). StressMonitorApp.swift was not in the plan's file list
- **Files modified:** StressMonitor/StressMonitor/StressMonitorApp.swift
- **Commit:** 8a63d63

**3. [Rule 1 - Bug] `/premium/verify` vs `/credits/premium/verify`**
- **Issue:** Coordinator-mandated reconciliation (02-03 client vs 02-02 authoritative backend)
- **Fix:** See "Endpoint Reconciliation" above; folded into Task 1 as a discrete pre-commit
- **Commit:** fc9476e

### Documented Deviations

**4. [Plan wording] Paywall layout followed the recorded DEC-1, not the task's option-a/b sentence**
- The task text ("pack cards replace (option-b) or lead (option-a) the plan grid") predates the user-confirmed DEC-1 amendment recorded in 02-01-SUMMARY: "the paywall LEADS WITH THE SUBSCRIPTION; credit packs are the secondary one-time option." Implemented per the recorded decision — subscription grid leads (unchanged position + sticky CTA), packs render as the secondary section. Trial banner and auto-renew fine print stay with the subscription (they describe the subscription, which is still sold); the pack section carries its own one-time-purchase fine print.

**5. [Files-touched] ChatViewModel listed in Task 2 files but required no change**
- 02-01 already wired both channels the pill reads (`presentPaywall` injection + `setCreditsConvergenceSink` into the app-scope CreditService). The pill observes `@Environment(CreditService.self)` directly, so messages converge the displayed value with zero VM changes.

**6. [Environment] Full-suite exit 65 despite all suites passing**
- Pre-existing TEST-01 cold-launch lineage (see Verification Results); reproducing identically to 02-01 D6 / 02-03 D5. No new ledger entry — WINDOWS.md entry #8 covers it.

## Deferred Issues (deployment-gated — the plan's Task 3 live smoke)

**BLOCKING-HUMAN CHECKPOINT — the five-step live money-path smoke could not run.** Both user_setup preconditions are unmet:

1. **Backend deploy:** 02-02's work is committed on stress-app-be `main` but NOT deployed; migrations 20260816120000/20260816120100 not applied to production. A read-only probe cannot confirm route presence: the deployed auth middleware returns 401 for ANY `/credits/*` path (verified — a nonexistent `/credits/definitely-not-a-route-xyz` also 401s), so deployment status is indistinguishable without a Firebase token. Needed from the user: deploy the image (same-tag update needs the documented `--force`), apply both migrations, set `APPLE_APPLE_ID` at deploy time.
2. **ASC consumables:** the DEC-2 products are still not filed in App Store Connect (user_setup pending from 02-03). Local `.storekit` covers Debug/test; Release-configuration product resolution (IAP-01) stays gated until filed.

To run the smoke once unblocked: a **Release-configuration** build must be installed on the simulator (the DEBUG app uses `MockStoreKitService`, which bypasses StoreKit entirely — the scheme's `.storekit` file only affects real StoreKit calls). Then walk: (1) fresh anonymous user provisions 50, surfaces show 50; (2) chat until 402 → paywall outOfCredits context, balance zero, reset date; (3) sandbox-purchase the small pack → balance increments exactly +10 once, success view shows granted credits; (4) relaunch → server-persisted balance (no phantom local credit); (5) restore → packs-era copy; kill session + foreground → typed unavailable state, not a phantom balance (AUTH-02 residual live close). Capture screenshots of the paywall before/after purchase + the balance pill. This is also the IAP-06 evidence item.

## Known Stubs

None. All code paths implemented against the pinned backend contract; the only unexecuted piece is the live end-to-end smoke above (recorded in WINDOWS.md as `unrun-verify`).

## Threat Flags

None beyond the plan's threat model. Register check: T-2-13 mitigated (nil→neutral placeholder pinned by test), T-2-14 mitigated (pack-mode success view omits restore; restore copy packs-era from 02-03; live confirmation rides the gated smoke step 5), T-2-15 mitigated in code (foreground refresh as session probe; typed 401; placeholder rendering — live session-kill check rides the gated smoke step 5).

## Self-Check: PASSED

All 3 created files verified present on disk; all 5 commits (fc9476e, ce1ad77, 8a63d63, dc57672, 64e7393) verified in git log.
