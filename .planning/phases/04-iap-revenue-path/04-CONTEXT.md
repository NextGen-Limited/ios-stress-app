# Phase 4: IAP Revenue Path - Context

**Gathered:** 2026-08-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Make StoreKit purchases actually resolve and complete end-to-end, and keep entitlement in sync with reality. A real user can pay against the local `.storekit` session (and against ASC once products are created), their premium entitlement auto-corrects on every foreground, displayed prices come from `Product.displayPrice` rather than hardcoded fallbacks, and CI fails a Release archive when no product IDs resolve. The phase also fixes a pre-existing Release-compile blocker (`StoreKitServiceEnvironment.swift` references a `#if DEBUG`-gated type unconditionally) that was flagged in Phase 3.

The phase covers six requirements: IAP-01 (product IDs resolve in Release; paywall shows real ASC prices), IAP-02 (`Transaction.updates` owned at app scope; entitlement refreshes on `scenePhase == .active`), IAP-03 (stale-premium user corrected on next foreground even after a no-op'd paywall), IAP-04 (premium character unlocks re-lock after cancellation OR confirmed one-time-permanent), IAP-05 (price = `product.displayPrice`; savings computed not hardcoded; free-trial banner only when eligible), and IAP-06 (purchase/restore/cancel/expiry verified against `.storekit`; CI fails Release archive when `allProductIDs` is empty).

Much of the IAP plumbing already exists and is substantially correct: `StoreKitService` implements purchase/restore/refresh with verified-transaction handling and `finish()` on both paths; the app entry point owns one `StoreKitService` instance for the process lifetime and calls `refreshEntitlements()` on `scenePhase == .active`; `CharacterCollectionViewModel.syncPremiumCharacterEntitlement` re-locks premium characters on lapse; and `StressMonitorProducts.storekit` + `StoreKitServiceTests` already verify purchase/restore/intro-offer via `SKTestSession`. The phase's job is to (1) unblock Release compilation, (2) wire real product IDs into build settings so Release resolves them, (3) close the display-honesty gaps (hardcoded "Save 37%" fallback, free-trial banner driven by product-offer presence rather than per-user eligibility), and (4) add a CI guard plus the cancel/expiry verification tests that are missing.

</domain>

<decisions>
## Implementation Decisions

### Release-Compile Blocker Fix (pre-existing, flagged in Phase 3) — PRE-RESOLVED
- **D-01:** `StoreKitServiceEnvironment.swift:12` unconditionally references `MockStoreKitService` (a type declared inside `#if DEBUG ... #endif` in `MockStoreKitService.swift`). This compiles in Debug but fails to compile any Release build, blocking every Release archive. Fix: wrap the `defaultValue` in `#if DEBUG` returning `MockStoreKitService(premiumState: .shared)` and `#else` returning a real `StoreKitService(premiumState: .shared)`. This mirrors the exact pattern already in `StressMonitorApp.makeStoreKitService()` (lines 197-205), which already does DEBUG→Mock / Release→Real. The environment-key default becomes consistent with the app's own factory. — **Reversibility:** reversible — two-line conditional.

### Product-ID Build Settings (IAP-01, IAP-06) — Claude's discretion, auto-resolved per --auto
- **D-02:** `StoreKitProductCatalog` resolves IDs from Bundle Info.plist → environment → UserDefaults, but `grep "STOREKIT_PREMIUM" project.pbxproj` returns zero hits — no `INFOPLIST_KEY_STOREKIT_PREMIUM_*_PRODUCT_ID` build settings exist in any configuration, so `catalog.allProductIDs` is empty in every real (non-test) build, which is exactly what IAP-06's CI guard must catch. Fix: add `INFOPLIST_KEY_STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID`, `..._MONTHLY_...`, `..._ANNUAL_...`, and `..._SUBSCRIPTION_GROUP_ID` build settings to the app target's Release (and Debug) configuration in `project.pbxproj`, set to the three product IDs already declared in `StressMonitorProducts.storekit` (`com.stressmonitor.app.premium.{weekly,monthly,annual}`) and the subscription group `SMPREMIUM01`. These are the canonical IDs; the `.storekit` file already uses them and `StoreKitServiceTests` already passes against them. The IDs are not secrets — they are public App Store identifiers. — **Reversibility:** reversible — build settings can be changed or removed. **External lead time:** creating the matching products/subscription group in App Store Connect is a separate human task with its own lead time (noted in ROADMAP); until those exist the Release paywall will still fall back to `defaultPlans`, but the CI guard and local `.storekit` verification both work against the local config file, which is the acceptance bar for IAP-01/IAP-06.

### Scheme StoreKit Configuration File (IAP-01, IAP-06) — Claude's discretion, auto-resolved per --auto
- **D-03:** The `StressMonitor.xcscheme` `TestAction` has no `StoreKitConfigurationFile` reference, so `StoreKitServiceTests` relies on the runtime test session loading `StressMonitorProducts.storekit` by name from the test bundle resources. The `.storekit` file is already in the test target's Resources build phase (pbxproj line 407). For local manual purchase/restore verification (IAP-06's "verified against a local `.storekit` session"), set the scheme's `StoreKitConfigurationFile` to `StressMonitorProducts.storekit` in the Run/Test actions so the simulator uses it for the paywall itself, not just the test session. This is an XML edit to `StressMonitor.xcscheme`. — **Reversibility:** reversible.

### Free-Trial Banner Honesty (IAP-05) — PRE-RESOLVED (non-blocking product question)
- **D-04:** The "7-day free trial" is treated as aspirational copy for v1 — there is no ASC introductory offer created yet, so the claim is removed unless an ASC offer exists. The current `.storekit` file DOES define a 1-week free-trial introductory offer on the annual product (`SMINTRO01`, `paymentMode: freeTrial`, `P1W`), so locally the offer exists and the banner should show when the user is actually eligible. The code change: drive the trial banner from the Product's actual `introductoryOffer` AND per-user eligibility (`Product.SubscriptionInfo.isEligibleForIntroOffer`), not just from a hardcoded `hasIntroductoryOffer == true` flag on the plan. Concretely: (a) `SubscriptionPlan.hasIntroductoryOffer` already comes from `product.subscription?.introductoryOffer != nil` (correct — reflects the product definition); (b) the paywall banner must additionally check `isEligibleForIntroOffer` for the selected product so it does not show "7-day free trial" to someone who already used their intro offer. The "7-day" literal in the banner copy is replaced with the offer's actual duration derived from `introductoryOffer.period` (the `.storekit` defines `P1W`, so "7-day" happens to be right, but deriving it keeps it honest if the offer changes). — **Reversibility:** reversible.

### Premium Character Unlocks (IAP-04) — PRE-RESOLVED (non-blocking product question)
- **D-05:** Premium character unlocks are treated as intentional one-time-permanent design for v1, NOT a bug. Rationale: `CharacterCollectionViewModel.syncPremiumCharacterEntitlement(isPremium:in:)` already sets `unlock.isUnlocked = isPremium` for premium characters — meaning a cancellation DOES re-lock them in the current code. But the existing tests (`CharacterEntitlementSyncTests.lapsingReLocksAndResetsActive`) assert re-locking works. So the current behavior already re-locks, which is the strict interpretation. The product decision ("intentional one-time-permanent") would mean the OPPOSITE — unlocks persist after cancellation. Since the pre-resolution says "treat as intentional one-time-permanent", the code change is: make premium character unlocks persist after cancellation (do NOT re-lock them in `syncPremiumCharacterEntitlement`), and update the test to assert persistence rather than re-locking. The streak-gated character (`lumi`) already persists and is unaffected. — **Reversibility:** reversible — flip the sync logic back. **Note:** this is the one place where the pre-resolution and the existing code disagree; the plan honors the pre-resolution (one-time-permanent) and updates tests to match.

### CI Release-Archive Guard (IAP-06) — Claude's discretion, auto-resolved per --auto
- **D-06:** Add a CI step (or a dedicated test) that fails when `StoreKitProductCatalog.live.allProductIDs` is empty in a Release archive. Two options: (a) a unit test that builds `StoreKitProductCatalog.live` and asserts `allProductIDs.isEmpty == false` (runs in the existing test job, fails if build settings are missing), or (b) a CI step in the GitHub Actions workflow that greps the Release-built `Info.plist` for the `STOREKIT_PREMIUM_*_PRODUCT_ID` keys. Option (a) is simpler and runs inside the existing `xcodebuild test` job already wired in Phase 1's BUILD-04; it directly exercises the same catalog code the app uses. Choose option (a): a test `StoreKitProductCatalogLiveTests` that asserts `StoreKitProductCatalog.live.allProductIDs` is non-empty, with a clear failure message. This test will fail until D-02's build settings land, then pass. — **Reversibility:** reversible.

### Claude's Discretion
- Whether the `MockStoreKitService` DEBUG default in `StoreKitServiceEnvironment` should stay or be removed entirely. Default: keep the DEBUG→Mock / Release→Real split so local development and previews keep instant premium toggling without hitting StoreKit; only the Release path changes.
- Whether the savings-percent computation should account for weekly-vs-annual or only monthly-vs-annual. Default: monthly-vs-annual only (the current computation), because weekly is a "try it" tier, not a comparison anchor; computing weekly-vs-annual savings is misleading given the different commitment lengths.
- Whether the CI guard test belongs in `StoreKitProductCatalogTests` (existing) or a new `StoreKitProductCatalogLiveTests` file. Default: new file — the existing tests inject explicit values and should not depend on the host bundle's build settings; a separate file scoped to `.live` makes the CI contract explicit and keeps the unit tests hermetic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Primary scope source
- `.planning/ROADMAP.md` lines 116-130 — Phase 4 goal, 5 success criteria, dependency framing (Phase 1 build config + external ASC lead time)
- `.planning/REQUIREMENTS.md` lines 34-40 — IAP-01 through IAP-06 acceptance criteria
- `plans/0808-2042-appstore-submission-remediation/plan.md` — Phase 5 section (file-level detail and acceptance criteria; the source plan's IAP phase is its Phase 5)

### Codebase state — the Release-compile blocker
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift` line 12 — `defaultValue: StoreKitServiceProtocol = MockStoreKitService(...)` references a `#if DEBUG`-only type unconditionally; blocks Release
- `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift` lines 3,33 — the `MockStoreKitService` type is entirely inside `#if DEBUG ... #endif`
- `StressMonitor/StressMonitor/StressMonitorApp.swift` lines 197-205 — the existing DEBUG→Mock / Release→Real factory pattern to mirror

### Codebase state — entitlement wiring (already correct)
- `StressMonitor/StressMonitor/StressMonitorApp.swift` lines 16-20 — `storeKitService` owned once at app scope; line 170 injects via `.environment(\.storeKitService, ...)`; lines 180-192 `scenePhase == .active` calls `refreshEntitlements()` (IAP-02 already done)
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` lines 170-212 — `refreshEntitlements()` iterates `Transaction.currentEntitlements` + subscription group status; lines 216-235 `listenForTransactions()` owns `Transaction.updates` for the process lifetime
- `StressMonitor/StressMonitor/Services/Premium/PaywallController.swift` lines 57-60 — `present()` no-ops when already premium (the guard IAP-03 concerns)

### Codebase state — product catalog and config resolution
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift` — 3-tier resolver (Bundle → env → UserDefaults); `clean()` rejects empty/`$(…)` placeholders; `allProductIDs` is the set the CI guard checks
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — grep `STOREKIT_PREMIUM` returns ZERO hits (no build settings exist — this is the IAP-01/IAP-06 root cause)
- `StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme` — no `StoreKitConfigurationFile` in TestAction/RunAction (D-03 adds it)

### Codebase state — paywall display honesty gaps
- `StressMonitor/StressMonitor/Views/Premium/Components/PlanCard.swift` line 164 — `leftFooter` returns hardcoded `"Save 37%"` fallback when `plan.savingsDisplay` is nil (IAP-05 gap)
- `StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift` lines 58, 152-183 — trial banner gated on `hasIntroductoryOffer == true` only, not per-user `isEligibleForIntroOffer`; "7-day" literal hardcoded (IAP-05 gap)
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` lines 58-69 — savings already computed (monthly vs annual), not hardcoded in the service; the gap is the UI fallback at PlanCard:164
- `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift` lines 50-53 — `savingsDisplay` derived from `savingsPercent`; lines 55-98 `defaultPlans` has hardcoded `savingsPercent: 37`

### Codebase state — character entitlement (IAP-04)
- `StressMonitor/StressMonitor/ViewModels/CharacterCollectionViewModel.swift` lines 81-93 — `syncPremiumCharacterEntitlement(isPremium:in:)` sets premium-char `isUnlocked = isPremium` (re-locks on lapse); D-05 changes this to one-time-permanent
- `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift` lines 41-58 — `lapsingReLocksAndResetsActive` asserts re-locking; D-05 updates this to assert persistence

### Codebase state — existing IAP tests (the verification substrate)
- `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift` — already verifies availablePlans (all 3), intro-offer flag, purchase grants entitlement, restore recovers (IAP-06 partially covered)
- `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` — local StoreKit config with weekly/monthly/annual + 1-week free-trial intro offer on annual
- `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift` — catalog resolution tests (hermetic, inject explicit values)

### Project-level
- `.planning/PROJECT.md` §Context — D1-D4 decision framing (none directly gate Phase 4)
- `.planning/REQUIREMENTS.md` — IAP-01..06 acceptance criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### The Release-compile blocker (D-01) — the hard prerequisite
`StoreKitServiceEnvironment.swift` line 12 declares the `EnvironmentKey.defaultValue` as `MockStoreKitService(premiumState: .shared)`. `MockStoreKitService` is declared inside `#if DEBUG ... #endif` (`MockStoreKitService.swift` lines 3 and 33). So the `defaultValue` compiles in Debug but references an undefined symbol in Release — every Release build fails at link/compile time. This was flagged in Phase 3 as a pre-existing blocker and must be fixed first because nothing else in Phase 4 can be verified in a Release configuration until it compiles. The fix mirrors `StressMonitorApp.makeStoreKitService()` (lines 197-205), which already correctly splits DEBUG→Mock / Release→Real.

### What is already correct (do not rebuild)
- **App-scope ownership (IAP-02):** `StressMonitorApp` line 20 owns `storeKitService` in `@State` for the whole process lifetime; line 170 injects it. The `Transaction.updates` listener started in `StoreKitService.init` (line 21 → `listenForTransactions()`, lines 216-222) therefore runs the entire time, not just while the paywall is on screen. This is the fix the comment at `StoreKitServiceEnvironment.swift:3-10` describes — it is already applied.
- **Foreground refresh (IAP-02/IAP-03):** `StressMonitorApp` lines 180-192 `.onChange(of: scenePhase)` calls `refreshEntitlements()` when `.active`. This is the auto-correction IAP-03 requires — even if `PaywallController.present()` no-op'd because the user was (stale-)premium at the time, the next foreground re-runs `refreshEntitlements()` and corrects `PremiumState.isPremiumUser`.
- **Verified-transaction handling:** `StoreKitService` `checkVerified` (lines 239-246) throws on `.unverified`; `purchase()` calls `transaction.finish()` on success (line 126) and `handle(transactionVerification:)` finishes on both verified/unverified paths (lines 229, 233). Sound.
- **Purchase/restore against `.storekit`:** `StoreKitServiceTests` already passes against `StressMonitorProducts.storekit` via `SKTestSession` — purchase grants entitlement, restore recovers it, intro-offer flag is correct. This is the IAP-06 substrate; the phase adds cancel/expiry cases.

### The product-ID gap (IAP-01/IAP-06 root cause)
`StoreKitProductCatalog.live` reads `STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID` from Bundle Info.plist → env → UserDefaults. None of those keys exist in `project.pbxproj` (grep-confirmed zero hits). So in every non-test build, `allProductIDs` is empty, `availablePlans` falls back to `SubscriptionPlan.defaultPlans` (hardcoded mock prices), and any purchase attempt throws `StoreKitError.missingProductConfiguration`. The `.storekit` file defines the IDs (`com.stressmonitor.app.premium.{weekly,monthly,annual}`) — they just need to be wired into build settings so Release resolves them. Tests bypass this by constructing `StoreKitProductCatalog` with explicit IDs.

### The display-honesty gaps (IAP-05)
1. **Hardcoded savings fallback:** `PlanCard.leftFooter` (line 164) returns `"Save 37%"` when `plan.savingsDisplay` is nil. The service (`StoreKitService` lines 58-69) computes real savings but only when both monthly AND annual are loaded; if only annual is configured (or loading is partial), `savingsPercent` stays nil and the UI lies with a hardcoded 37%. Fix: return `nil`/empty when savings is unknown, or hide the footer — never fabricate a number.
2. **Trial banner without eligibility check:** `IAPPremiumView` line 58 shows the trial banner when `selectedPlanDetails?.hasIntroductoryOffer == true`. `hasIntroductoryOffer` is set from `product.subscription?.introductoryOffer != nil` (StoreKitService line 289) — it reflects whether the PRODUCT has an offer, not whether THIS USER is eligible (a user who already used a free trial is not eligible, but the banner would still show). IAP-05 requires the banner only when `isEligibleForIntroOffer` is true. StoreKit exposes this via `Product.SubscriptionInfo.isEligibleForIntroOffer`.
3. **"7-day" literal:** the banner copy hardcodes "7-day free trial" (line 158). The offer duration should be derived from `introductoryOffer.period` (`P1W` → "7-day", `P1M` → "1-month") to stay honest if the offer changes.

### The IAP-04 disagreement (D-05)
The existing code re-locks premium characters on subscription lapse (`syncPremiumCharacterEntitlement` sets `isUnlocked = isPremium`). The pre-resolution says treat one-time-permanent as intentional — so unlocks should persist after cancellation. This means changing the sync logic to NOT re-lock premium characters (only update `isActive` fallback to Ripple if the active char got locked some other way), and updating `CharacterEntitlementSyncTests.lapsingReLocksAndResetsActive` to assert persistence instead of re-locking. The streak-gated `lumi` already persists and its test (`lumiStreakUnlockSurvivesLapse`) is unaffected.

</code_context>

<verification_focus>
## Phase 4 Success-Criteria Mapping

| SC# | Criterion | Requirement(s) | Key Change |
|-----|-----------|----------------|------------|
| 1 | Paywall shows real ASC prices in Release; purchase completes against `.storekit` | IAP-01 | D-01 (Release compile), D-02 (build settings), D-03 (scheme config) |
| 2 | Entitlement auto-corrects on foreground | IAP-02, IAP-03 | Already done (verify via TDD) |
| 3 | Premium char unlocks re-lock OR confirmed one-time-permanent | IAP-04 | D-05 (one-time-permanent + test update) |
| 4 | Price = `displayPrice`; savings computed; free-trial only when eligible | IAP-05 | Remove hardcoded "Save 37%", add `isEligibleForIntroOffer` gate, derive trial duration |
| 5 | Purchase/restore/cancel/expiry verified against `.storekit`; CI fails Release when no IDs | IAP-06 | Add cancel/expiry tests, add `StoreKitProductCatalogLiveTests` guard |
</verification_focus>
