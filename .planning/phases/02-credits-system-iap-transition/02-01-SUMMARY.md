---
phase: 02-credits-system-iap-transition
plan: 01
subsystem: credits-iap
tags: [credits, paywall, storekit, chat, testing]
requires: [firebase-auth, stress-api-chat, paywall-controller]
provides: [CreditBalance, CreditService, CreditServiceProtocol, StressAPIClient.getBalance, PaywallReason.outOfCredits, credit-environment-injection, repaired-test-substrate, DEC-1, DEC-2]
affects: [StressLLMService, ChatViewModel, PaywallController, PaywallView, StressMonitorApp, ChatBottomSheetView, StressAPIClient]
tech-stack:
  added: []
  patterns:
    - "@MainActor @Observable display-cache service over a server-authoritative resource (CreditService)"
    - "per-call context through the send() chain replacing a static side-channel (CR-01 closure)"
    - "injectable convergence sink (onCreditsRemainingChange) decoupling the chat stream from CreditService"
key-files:
  created:
    - StressMonitor/StressMonitor/Models/CreditBalance.swift
    - StressMonitor/StressMonitor/Services/Credits/CreditServiceProtocol.swift
    - StressMonitor/StressMonitor/Services/Credits/CreditService.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift
    - StressMonitor/StressMonitorTests/CreditServiceTests.swift
    - StressMonitor/StressMonitorTests/StressAPIClientCreditsTests.swift
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift
    - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
    - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
    - StressMonitor/StressMonitor/Services/Premium/PaywallController.swift
    - StressMonitor/StressMonitor/Views/Premium/PaywallView.swift
    - StressMonitor/StressMonitor/StressMonitorApp.swift
    - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
    - StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift
    - StressMonitor/StressMonitorTests/ChatLifecycleTests.swift
    - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
    - StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift
    - StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift
    - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
decisions:
  - DEC-1: free-tier credits + subscription-as-server-premium (user hybrid model); outOfCredits bypasses the premium guard
  - DEC-2: packs-2 (small 10/$1.99, large 150/$19.99); placement-a (chat pill + paywall header + Settings row)
metrics:
  duration: ~80min
  completed: 2026-08-17
actuals:
  tokens: 13000
  tasks: 5
  commits: 6
status: complete
---

# Phase 02 Plan 01: Decision Gates + Credit-Visibility Tracer Summary

Locked DEC-1/DEC-2 monetization decisions, repaired the orphaned test substrate (7 suites registered, 2 disabled-with-reason), closed 01-REVIEW CR-01 (stress context now flows per-call through `send()`), and shipped the balance→paywall tracer: GET /credits → CreditService → chat 402 → paywall presented with the live balance.

## Decision Records (verbatim from coordinator, user-confirmed)

### DEC-1 — Monetization architecture

User's verbatim goal: "my goal is: has free tier credit, then user reach limit then get subscriptions".

Concrete architecture (user-confirmed model — a deliberate amendment to the plan's option-a assumption):

- Free tier: 50 credits/month, already live server-side (provisioning + monthly cron reset) — no backend change needed for the free tier itself.
- Chat consumes 1 credit/message for free-tier users; server 402 remains the only gate (never gate on cached balance).
- On depletion, the paywall LEADS WITH THE SUBSCRIPTION as the conversion path; credit packs are the secondary one-time option.
- Subscription = server-side premium: unlimited chat (`plan_type='premium'`, 999999-credit/maxTokens-2048 semantics already in backend). Implementation shape: purchase-time JWS verification (same verification lib plan 02-02 builds for redeem) through a verify endpoint setting `plan_type='premium'` with expiry from the transaction's `expirationDate`; the existing monthly cron demotes expired premium; the client re-verifies on launch/foreground via `Transaction.updates`/`currentEntitlements`. Zero existing subscribers → no backfill. **The full endpoint work belongs to plans 02-02/02-03/02-04, NOT this plan.**
- iOS `PremiumState` stays client-side for characters/premium UI gating (unchanged).

Paywall guard consequence implemented here: `PaywallReason.outOfCredits` presents regardless of local premium state — a server-side premium user never receives 402, so any 402 reaching the client means the server does not consider the user premium, and the resubscribe-led paywall is the correct path. Pinned by `PaywallOutOfCreditsGuardTests`.

### DEC-2 — Product parameters

- Pack set: **packs-2**. small = **10 credits $1.99**; large = **150 credits $19.99**. SKUs: `com.stressmonitor.app.credits.small` / `com.stressmonitor.app.credits.large`.
- Balance placement (DEC-2b): **placement-a** — chat sheet pill + paywall header + Settings row value. This plan ships the paywall header surface only (tracer scope); the chat pill and Settings row are plan 02-04's expansion.

### Pre-flight (branch strategy)

RESOLVED by the orchestrator: `main` pushed; work continues on `gsd/v1.1-backend-api-migration`.

## What Was Built

| Commit | Task | Content |
|---|---|---|
| 8b91cad | 3 | Test substrate repair: 7 orphaned suites registered (A007–B013), ChatAvailabilityTests rewritten to the D-02 pin, ChatLifecycle wait-race fixed, DataDeletion isolation aligned, 2 suites disabled-with-reason |
| ef26c45 | 4 (RED) | CR-01 failing tests: fake conforms to extended `send(stressContext:)` signature; per-call payload freshness case |
| 963d723 | 4 (GREEN) | CR-01 closed: protocol parameter, Task-closure capture, static `currentStressContext` deleted; REFACTOR concluded with no changes needed |
| e948e3e | 5 (RED) | Tracer failing suites: CreditServiceTests, StressAPIClientCreditsTests (pbxproj A014/B015, A015/B015), 402→paywall case, guard-bypass pin |
| 06f77ae | 5 (GREEN) | Tracer: CreditBalance/CreditService/getBalance/402 routing/guard bypass/balance line/app wiring/sink |
| 7499ddd | 5 (REFACTOR) | `CreditsAPIError.invalidResponse` replaces the magic -1 status |

The single tracer path: `StressMonitorApp` owns app-scope `CreditService` (environment-injected, refreshed on foreground = AUTH-02 probe) → `StressAPIClient.getBalance()` decodes GET /credits → `PaywallView` renders the live balance (remaining count or "Unlimited" for premium — the 999999 sentinel is never formatted) → a chat 402 maps to `LLMServiceError.insufficientCredits` → `ChatViewModel` sets a one-line message and fires the injected presentation closure → `PaywallController.present(reason: .outOfCredits)` (premium guard bypassed for this reason) → every chat's terminal SSE metadata `credits_remaining` converges the displayed balance through the `StressLLMService.onCreditsRemainingChange` sink. No client-side decrement arithmetic exists anywhere (pinned by CreditServiceTests).

## Verification Results

- Orphan count: **0** (every `StressMonitorTests/*.swift` is in Sources phase 3828578ADDAD4AC5925394DB — 26 files / 26 entries)
- Tracer suites (targeted run): **14 tests / 4 suites passed, exit 0** — CreditServiceTests 5, StressAPIClientCreditsTests 3, ChatLifecycleTests 5, PaywallOutOfCreditsGuardTests 1
- Task 3 core suites (plan verify command): **9 tests / 4 suites passed, exit 0** — SSEParser, LLMServiceError, ChatLifecycle, ChatAvailability
- Full suite: **84 tests / 17 suites, all passing, zero test failures** across two independent runs — but see Deviation D6 for the exit-code caveat
- `grep -c 'case outOfCredits'` PaywallController.swift = 1; `getBalance`/`authorizedRequest` in StressAPIClient+Credits.swift = 1/1; `999999` across `StressMonitor/StressMonitor/` = 0
- CR-01: zero `currentStressContext` references remain (comment-filtered grep = 0)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan's orphan-check verify command was broken**
- **Found during:** Task 3 verification
- **Issue:** The plan's check greps for `/* <name> */` within `-A200` of the Sources-phase anchor, but Sources entries read `/* <name> in Sources */` — the pattern matches nothing and reported 24 orphans even for long-registered files
- **Fix:** Rewrote the check scoped to the actual phase block: awk from `3828578ADDAD4AC5925394DB /* Sources */ = {` to `runOnlyForDeploymentPostprocessing`, matching `/* <name> in Sources */`. Same intent (every test file appears in the Sources phase), correct mechanics
- **Files modified:** none (command-only)

**2. [Rule 3 - Blocking] Test target missing SWIFT_APPROACHABLE_CONCURRENCY**
- **Found during:** Task 3 (compile failure registering DataDeletionConsolidationTests)
- **Issue:** The app target compiles with `SWIFT_APPROACHABLE_CONCURRENCY = YES`; the StressMonitorTests target does not. Protocol requirements with closure parameters canonicalize to `nonisolated(nonsending)` under the flag, so cross-target conformance (FakeCloudKitResetService → CloudKitResetServiceProtocol) fails to compile
- **Fix:** Added `SWIFT_APPROACHABLE_CONCURRENCY = YES` to both StressMonitorTests build configurations, matching the app target
- **Files modified:** StressMonitor/StressMonitor.xcodeproj/project.pbxproj
- **Commit:** 8b91cad

**3. [Rule 1 - Bug] ChatLifecycleTests network-error case had a TOCTOU race**
- **Found during:** Task 3 (failed 3/3 standalone runs; the suite had never executed before — it was orphaned)
- **Issue:** `waitFor { viewModel.isLoading == false }` returns immediately in the gap between `send()` returning and the streaming task setting `isLoading = true`, so assertions ran before the stream delivered anything
- **Fix:** Wait for the terminal state (`errorMessage` non-nil — set only in the catch block) instead; same pinned behavior, deterministic
- **Files modified:** StressMonitor/StressMonitorTests/ChatLifecycleTests.swift
- **Commit:** 8b91cad

**4. [Rule 2 - Missing critical functionality] ChatBottomSheetView production wiring**
- **Issue:** The plan's file list omits ChatBottomSheetView, but it is the sole production constructor of ChatViewModel (via convenience init, where the SwiftUI environment is unreachable). Without wiring there, `presentPaywall` and the credits convergence sink stay nil in every real build and the plan's own must-have truth ("402 routes the user to the paywall") fails at runtime
- **Fix:** Added environment reads (PaywallController, CreditService) and an `.onAppear` that injects both closures before any message can be sent
- **Files modified:** StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
- **Commit:** 06f77ae

**5. [Rule 3 - Blocking] StressAPIClient.session visibility**
- **Issue:** `getBalance()` lives in a separate extension file (per plan) but `session` was `private`, so the extension could not perform the request (and injected test URLProtocol sessions would be bypassed with `URLSession.shared`)
- **Fix:** `private let session` → `let session` (internal); one-word change
- **Files modified:** StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
- **Commit:** 06f77ae

### Documented Deviations

**6. [Environment] Full-suite exit code 65 despite all tests passing**
- Two independent full-suite runs: **84 tests / 17 suites, 0 failures**, but xcodebuild exits 65 because the test host hits 6 "unexpected exit / crash / test timeout" events — all clustered on cold launches of the v1.0-era "CloudKit Failure & Cancellation Ordering" (4) and "Data Export Field Selection" (2) suites inside DataDeletionConsolidationTests.swift. Each suite passes once a launch survives. This is the documented TEST-01 host/CoreSimulator flakiness lineage, not a regression from this plan (targeted runs of every suite, including those two, exit 0). Recorded in the broken-windows ledger.

**7. [Scope amendment] DEC-1 differs from the plan's option-a assumption**
- The user's model keeps subscriptions as the primary conversion path AND makes them server-side premium (option-c's server semantics with option-a's pack coexistence). Per coordinator instruction, 02-01's tasks were implemented as planned; the only semantics touched were the paywall presentation (outOfCredits bypasses the guard — see DEC-1 record). Downstream executors (02-02/02-03/02-04) inherit the decision record above: the subscription verify endpoint (JWS → `plan_type='premium'` with expiry, cron demotion, client re-verify) is THEIR scope.

## Suites Disabled With Reason

| Suite | Reason | Re-enable path |
|---|---|---|
| `EntitlementForegroundCorrectionTests` | `purchase(annual)` throws productNotFound — the same StoreKitTest session-isolation failure documented in StoreKitServiceTests.swift (product IDs resolve in no build configuration; IAP-01) | Phase 02 plan 02-03 (StoreKit configuration work) |
| `StoreKitProductCatalogLiveTests` | The contract it pins does not hold: custom `INFOPLIST_KEY_STOREKIT_*` build settings are not among Xcode's recognized INFOPLIST_KEY set and never reach the generated Info.plist, so `StoreKitProductCatalog.live` resolves empty in every configuration. This is the known-open requirement IAP-01 (v1.0 audit: "zero product IDs resolve in any build configuration") — a genuine pre-existing production gap, escalated here rather than weakened | Phase 02 plan 02-03 must make product IDs actually resolvable (Info.plist entries or another mechanism), then re-enable |

## Known Stubs

None blocking. The PaywallView balance line is the deliberate minimal DEC-2 tracer surface (paywall header only); the chat-sheet pill and Settings row from placement-a are plan 02-04's expansion, and pack purchases/redemption are 02-02/02-03 by design. `MockCreditService` (listed in the plan's artifacts table) was not created — no test in this plan needs a CreditServiceProtocol double yet; creating an unused mock would be speculative.

## Deferred Issues

- 01-REVIEW CR-02 (trend direction inverted in StressContextPayload.build) — deferred to Phase 3 per the plan's explicit_deferrals; untouched here
- IAP-01 product-ID resolution gap — escalated to 02-03 (see disabled suites)
- CoreSimulator cold-launch flakiness on the two CloudKit-heavy suites (Deviation 6) — pre-existing host issue; a different host or CI runner remains the fix per TEST-01

## Self-Check: PASSED

All 7 created files verified present on disk; all 6 task commits (8b91cad, ef26c45, 963d723, e948e3e, 06f77ae, 7499ddd) verified in git log.
