# B2: Real StoreKit / Premium Implementation Plan

> **Kanban:** B2 (P0 BLOCKER) | **Branch:** `plan/b2-real-storekit-premium`
> **Created:** 2026-06-12 | **Status:** Plan ready for implementation
> **For implementer:** Use this as the source of truth. Implement on a new feature branch from latest `main`; do not implement on the plan branch unless explicitly requested.

---

## Goal

Replace the mock-only premium purchase flow with a production StoreKit 2 implementation that can fetch products, purchase subscriptions, restore purchases, validate StoreKit transactions, poll current subscription entitlement state, and remove release-build `fatalError` crashes.

---

## Evidence / Current State

### Ship blocker from kanban

`docs/KANBAN-SHIP-READINESS.md:16-25` lists B2 as P0 backlog:

- Implement `StoreKitService` conforming to `StoreKitServiceProtocol`
- Product fetching from App Store Connect
- Purchase flow with Apple's servers
- Receipt/transaction validation
- Restore purchases flow
- Subscription status polling
- Remove `MockStoreKitService` from production builds

### Current source evidence

- Existing StoreKit service files:
  - `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift:19-25`
  - `StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift:7-19`
  - `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift:3-29`
- No real `StoreKitService.swift` exists under `StressMonitor/StressMonitor/Services/StoreKit/`.
- Release builds still crash when opening Premium from:
  - `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:91-94`
  - `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift:99-102`
- `PremiumViewModel` already depends on `StoreKitServiceProtocol`, so this can be implemented without rewriting the paywall:
  - `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift:5-67`
- `SubscriptionPlan` currently stores local prices only and has no StoreKit product identifier:
  - `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift:8-56`
- `IAPPremiumView` already loads plans, purchases selected plan, restores purchases, and shows an alert:
  - `StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift:7-103`

---

## Non-Negotiable Constraints

1. Use **StoreKit 2** (`import StoreKit`), not StoreKit 1 APIs.
2. Keep `MockStoreKitService` under `#if DEBUG` only.
3. No hardcoded secrets.
4. Do not invent App Store Connect product IDs. Product IDs must come from config or explicit constants that the team confirms.
5. Do not add third-party dependencies.
6. Do not move health/stress data to the backend. This task is only Premium/StoreKit.
7. Keep UI design changes minimal; this is a production wiring task, not a paywall redesign.
8. Prefer TDD where possible; at minimum add unit tests around `PremiumViewModel`, product mapping, and transaction-result handling seams.

---

## Architecture

### Current

```text
SettingsView / TrendsView
  -> IAPPremiumView
      -> PremiumViewModel
          -> StoreKitServiceProtocol
              -> MockStoreKitService only in DEBUG
              -> fatalError in RELEASE
```

### Target

```text
SettingsView / TrendsView
  -> IAPPremiumView
      -> PremiumViewModel
          -> StoreKitServiceProtocol
              -> DEBUG: MockStoreKitService for previews/demo when desired
              -> RELEASE: StoreKitService
                    -> StoreKit Product.products(for:)
                    -> Product.purchase()
                    -> Transaction.currentEntitlements
                    -> Transaction.updates listener
                    -> AppStore.sync()
                    -> PremiumState.shared
```

---

## Product ID Strategy

The repository currently has no product IDs. Do **not** guess them.

Implement a small catalog layer so product IDs can be provided by build settings / Info.plist and optionally overridden in DEBUG.

### Create

`StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`

Requirements:

- Define `StoreKitProductCatalog` with:
  - `monthlyProductID: String?`
  - `annualProductID: String?`
  - `productID(for period: SubscriptionPeriod) -> String?`
  - `allProductIDs: Set<String>`
- Read values in priority order:
  1. `Bundle.main.object(forInfoDictionaryKey:)`
     - `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID`
     - `STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID`
  2. `ProcessInfo.processInfo.environment` for tests:
     - same keys
  3. `UserDefaults.standard.string(forKey:)` for local QA:
     - `storeKitPremiumMonthlyProductID`
     - `storeKitPremiumAnnualProductID`
- Treat empty strings and unresolved build placeholders like `$(...)` as nil.

Acceptance:

- Missing product IDs should not crash.
- Real service should surface `StoreKitError.productNotFound` / user-facing error when attempting to purchase with no configured ID.

---

## Data Model Changes

### Modify `SubscriptionPlan`

File: `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`

Add fields:

- `let productID: String?`
- `let displayPrice: String?` or make existing `priceDisplay` prefer StoreKit formatted display price.
- Optional `let subscriptionDisplayName: String?` only if useful.

Keep existing UI-compatible fields:

- `id`
- `displayName`
- `pricePerMonth`
- `pricePerPeriod`
- `period`
- `savingsPercent`
- `isBestValue`
- `subtitle`
- `priceDisplay`

Add mapping helpers:

- `static func plan(for product: Product, period: SubscriptionPeriod) -> SubscriptionPlan`
- Or keep mapping in `StoreKitService` if using StoreKit types in model is undesirable.

Important:

- If importing `StoreKit` inside the model is considered too wide, create mapping in `StoreKitService` and keep `SubscriptionPlan` Foundation-only.
- Preserve `SubscriptionPlan.defaultPlans` for DEBUG/mock/fallback only.

---

## Protocol Changes

File: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`

Current protocol:

```swift
protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
}
```

Preferred minimal change:

- Keep existing methods to avoid large UI churn.
- Add only if needed:
  - `func refreshEntitlements() async`

If adding `refreshEntitlements()`, update:

- `StoreKitService`
- `MockStoreKitService`
- `PremiumViewModel`

Do not add callback-based APIs.

---

## StoreKitService Implementation

### Create

`StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`

### Skeleton behavior

- Annotate `@MainActor` because it updates `PremiumState`.
- Use `final class StoreKitService: StoreKitServiceProtocol`.
- Hold:
  - `private let premiumState: PremiumState`
  - `private var productsByID: [String: Product] = [:]`
  - `private var transactionUpdatesTask: Task<Void, Never>?`
  - `private let catalog: StoreKitProductCatalog`
- Start a transaction update listener in init.
- Cancel listener in deinit.

### Product fetching

`availablePlans` should:

1. Read `catalog.allProductIDs`.
2. If empty, return `SubscriptionPlan.defaultPlans` only as display fallback, but purchases must still fail clearly because no product ID exists.
3. Fetch `let products = try await Product.products(for: Array(productIDs))`.
4. Map monthly/annual product IDs back to `SubscriptionPeriod`.
5. Sort annual first, monthly second to preserve current UI.
6. Cache `productsByID` for purchase.
7. Return fallback defaults if fetch fails, but log/store a user-facing error through `PremiumViewModel` when purchase is attempted.

### Purchase flow

`purchase(_ plan:)` should:

1. Resolve `plan.productID` or catalog product ID for `plan.period`.
2. Fetch product if cache is empty.
3. Call `let result = try await product.purchase()`.
4. Switch result:
   - `.success(let verification)` -> verify with `checkVerified(verification)`.
   - `.userCancelled` -> throw `StoreKitError.purchaseCancelled`.
   - `.pending` -> throw a new localized error, e.g. `.purchasePending`.
   - `@unknown default` -> throw `.purchaseFailed`.
5. On verified transaction:
   - set `premiumState.isPremiumUser = true` when entitlement is active and not revoked/expired.
   - finish transaction with `await transaction.finish()`.
   - call `await refreshEntitlements()` after finishing.

### Receipt / transaction validation

For StoreKit 2, local verification means checking `VerificationResult<Transaction>`.

Add helper:

```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw StoreKitError.receiptValidationFailed
    case .verified(let safe):
        return safe
    }
}
```

Add error case in `StoreKitError`:

- `case receiptValidationFailed`
- `case purchasePending`
- `case missingProductConfiguration`

### Restore purchases

`restorePurchases()` should:

1. Call `try await AppStore.sync()`.
2. Call `await refreshEntitlements()`.
3. If `premiumState.isPremiumUser == false`, throw `StoreKitError.restoreFailed` with a localized message like “No active subscription was found.”

### Subscription status polling

`refreshEntitlements()` should:

1. Iterate `for await result in Transaction.currentEntitlements`.
2. Verify each transaction.
3. Check if product ID is in catalog.
4. Treat premium as active only if:
   - transaction belongs to known product ID
   - `revocationDate == nil`
   - expiration date is nil or future
5. Update `premiumState.isPremiumUser`.

### Transaction update listener

Start in init:

```swift
transactionUpdatesTask = Task { [weak self] in
    for await result in Transaction.updates {
        await self?.handle(transactionVerification: result)
    }
}
```

The handler should verify, refresh entitlements, then finish the transaction if verified.

---

## Error Model

File: `StoreKitServiceProtocol.swift`

Current errors are too coarse:

```swift
enum StoreKitError: LocalizedError {
    case purchaseFailed
    case purchaseCancelled
    case restoreFailed
    case productNotFound
}
```

Add:

- `case receiptValidationFailed`
- `case purchasePending`
- `case missingProductConfiguration`
- Optional: `case productFetchFailed`

Each must have a user-safe `errorDescription`.

No raw Apple error details should leak to users unless useful and safe.

---

## PremiumViewModel Changes

File: `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`

Keep the public UI state mostly unchanged.

Required changes:

1. `loadInitialData()`:
   - Fetch plans.
   - If empty, show an error and use fallback UI safely.
   - Set `selectedPlan` to annual if present, otherwise first available plan.
2. `purchaseSelectedPlan()`:
   - Keep current selected-plan guard.
   - Surface `.purchasePending` as a non-fatal alert.
   - Do not set premium blindly unless service updates state or service guarantees success after verified transaction.
   - After purchase, set `showSuccess = premiumState.isPremiumUser`.
3. `restorePurchases()`:
   - Use service result and show an error if nothing restored.
4. Optional: expose `purchaseHistory: [String]` only if UI will use it now. Otherwise leave `fetchPurchaseHistory()` implemented but unused.

---

## Replace Release fatalError Paths

### SettingsView

File: `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`

Replace release factory:

```swift
#else
private static func makeStoreKitService() -> StoreKitServiceProtocol {
    StoreKitService(premiumState: PremiumState.shared)
}
#endif
```

### TrendsView

File: `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`

Make the same replacement.

Acceptance:

- `git grep -n 'Live StoreKit service not yet implemented' -- StressMonitor/StressMonitor` returns no matches.
- `fatalError` remains only for unrecoverable model-container/app-group setup, not premium flow.

---

## Tests

This repo uses Swift Testing in at least:

- `StressMonitor/StressMonitorTests/CharacterCollectionViewModelTests.swift`

Add tests under `StressMonitor/StressMonitorTests/` unless project membership requires the root `StressMonitorTests/` target. If Xcode target membership is uncertain, inspect `project.pbxproj` and match nearby tests.

### Create `PremiumViewModelTests.swift`

Use a fake service rather than StoreKit network calls:

```swift
@MainActor
final class FakeStoreKitService: StoreKitServiceProtocol { ... }
```

Test cases:

1. `loadInitialData` loads plans into `PremiumViewModel.plans`.
2. `purchaseSelectedPlan` calls purchase and sets `showSuccess` only after premium state is true.
3. Purchase cancellation does not set `showError`.
4. Purchase failure sets `showError` and `errorMessage`.
5. Restore success sets `showSuccess` when premium state is true.
6. Restore failure sets `showError`.

### Create `StoreKitProductCatalogTests.swift`

Test cases:

1. Empty/missing Info.plist/env/defaults values produce empty `allProductIDs`.
2. UserDefaults override produces monthly/annual IDs.
3. Placeholder value `$(STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID)` is ignored.

### StoreKitService tests

Full StoreKit 2 tests need a `.storekit` configuration and Xcode scheme setup. If practical, add:

- `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift`
- `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`

But do not block the first implementation on complex StoreKit automation if local Xcode tooling is unavailable. Cover business logic through fakes first.

---

## Local StoreKit Testing Configuration

If App Store Connect product IDs are not available yet, create a local `.storekit` config with placeholder product IDs chosen by the team, not invented silently.

Suggested file path if IDs are confirmed:

- `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`

Suggested products:

- Monthly auto-renewable subscription
- Annual auto-renewable subscription
- Same subscription group
- Intro offers disabled initially unless product requires them

Do not commit real App Store Connect secrets. Product IDs are public identifiers and can be committed if confirmed.

---

## Backend / Credit System Follow-up

The StressMonitor backend has a credit system, but this B2 task should not require backend writes unless the team explicitly wants server-side subscription mirroring now.

If backend mirroring is required later, create a separate task after StoreKit purchase works locally:

- On verified premium entitlement, call Supabase `/preferences` or a new subscription endpoint to mark plan tier.
- Never send receipts/JWS to a generic endpoint without a defined backend contract.
- Keep StoreKit transaction verification on-device for this task.

---

## Implementation Tasks

### Task 1 — Product catalog and errors

**Objective:** Add product ID configuration and user-safe StoreKit errors.

**Files:**

- Create: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- Modify: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`
- Test: `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`

**Steps:**

1. Write catalog tests for missing values, UserDefaults values, and unresolved placeholders.
2. Implement `StoreKitProductCatalog`.
3. Extend `StoreKitError` cases/descriptions.
4. Run targeted tests.

---

### Task 2 — SubscriptionPlan StoreKit mapping

**Objective:** Allow real StoreKit products to drive plan IDs and display prices without breaking existing UI.

**Files:**

- Modify: `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`
- Test: `StressMonitor/StressMonitorTests/SubscriptionPlanTests.swift` if mapping logic lives outside StoreKit types, otherwise cover through StoreKit service/fakes.

**Steps:**

1. Add optional `productID` and formatted-display support.
2. Keep `defaultPlans` compiling for mock and fallback paths.
3. Confirm `PlanSelectionCard` still compiles and uses `priceDisplay`.

---

### Task 3 — Real StoreKitService

**Objective:** Implement product fetch, purchase, restore, validation, and entitlement refresh.

**Files:**

- Create: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`
- Modify: `StoreKitServiceProtocol.swift` only if `refreshEntitlements()` is added.

**Steps:**

1. Implement product fetch and plan mapping.
2. Implement `purchase(_:)` with `Product.purchase()` and verified transaction handling.
3. Implement `restorePurchases()` with `AppStore.sync()`.
4. Implement `refreshEntitlements()` over `Transaction.currentEntitlements`.
5. Implement transaction update listener.
6. Ensure missing config/product fetch failure does not crash.

---

### Task 4 — PremiumViewModel behavior

**Objective:** Make the view model production-safe around real StoreKit states.

**Files:**

- Modify: `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`
- Test: `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift`

**Steps:**

1. Add fake protocol-backed service in tests.
2. Test load, purchase success, cancellation, failure, restore success/failure.
3. Update implementation to pass tests.

---

### Task 5 — Replace release factories

**Objective:** Remove production crashes.

**Files:**

- Modify: `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`
- Modify: `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`

**Steps:**

1. In `#else`, return `StoreKitService(premiumState: PremiumState.shared)`.
2. Keep DEBUG using `MockStoreKitService` unless local StoreKit testing wants the real service in DEBUG too.
3. Verify no `Live StoreKit service not yet implemented` string remains.

---

### Task 6 — Optional StoreKit local config

**Objective:** Enable manual StoreKit testing in Xcode.

**Files:**

- Optional create: `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`
- Optional modify: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` if adding the config to the project/scheme is required.

**Steps:**

1. Only create if product IDs are confirmed or team accepts placeholder local-only IDs.
2. Document how to select the `.storekit` file in the scheme.

---

## Verification Checklist

Run as much as the host supports.

### Static checks

```bash
git diff --check
git grep -n 'Live StoreKit service not yet implemented' -- StressMonitor/StressMonitor || true
git grep -n 'MockStoreKitService' -- StressMonitor/StressMonitor
```

Expected:

- `git diff --check` clean.
- No `Live StoreKit service not yet implemented` matches.
- `MockStoreKitService` only in DEBUG/previews/tests.

### Swift parse fallback when full Xcode is unavailable

```bash
swiftc -parse \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift \
  StressMonitor/StressMonitor/Models/SubscriptionPlan.swift \
  StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift
```

### Xcode build/tests when full Xcode is available

Per `AGENTS.md`, prefer MCP xc-all tools if available. Otherwise:

```bash
xcodebuild -list -project StressMonitor/StressMonitor.xcodeproj
xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

If the host has `xcode-select` pointed to CommandLineTools instead of a full Xcode developer dir, report that blocker and run `swiftc -parse` plus unit-level checks.

### Manual QA

1. Launch app in DEBUG with StoreKit config or mock.
2. Open Premium from Settings.
3. Product list loads without crash.
4. Purchase monthly/annual succeeds in StoreKit test session.
5. Cancel purchase does not show an error.
6. Restore purchases succeeds when subscription exists.
7. Restore purchases shows a friendly error when no subscription exists.
8. Relaunch app; premium state persists based on current entitlements.
9. Build in RELEASE configuration; opening Premium must not crash.

---

## Acceptance Criteria

- [ ] `StoreKitService.swift` exists and conforms to `StoreKitServiceProtocol`.
- [ ] Product IDs are configurable and not guessed silently.
- [ ] Product fetching uses `Product.products(for:)`.
- [ ] Purchase flow uses `Product.purchase()`.
- [ ] Verified transactions update `PremiumState`.
- [ ] Restore purchases uses `AppStore.sync()` and entitlement refresh.
- [ ] Subscription status polling uses `Transaction.currentEntitlements` and `Transaction.updates`.
- [ ] Receipt/transaction validation uses `VerificationResult` and rejects unverified transactions.
- [ ] Release `fatalError("Live StoreKit service not yet implemented")` is removed.
- [ ] `MockStoreKitService` remains DEBUG-only.
- [ ] `PremiumViewModel` tests cover success/cancel/failure/restore behavior.
- [ ] Build/tests or best available verification pass and are documented.

---

## Out of Scope

- App Store Connect setup.
- Backend subscription mirroring / Supabase credit upgrade.
- Paywall redesign.
- New analytics/telemetry.
- Family Sharing, promo offers, intro offers, win-back offers.
- Localization of purchase copy beyond existing strings.

---

## Notes for the stress_app Implementer

1. Start from latest `main`, not from an old feature branch.
2. Create a feature branch such as `fix/b2-real-storekit-premium`.
3. Read this plan fully before editing.
4. Follow TDD for `PremiumViewModel` and catalog behavior.
5. Keep commits focused:
   - `feat(storekit): add product catalog and real service`
   - `fix(premium): replace release StoreKit fatal errors`
   - `test(premium): cover purchase and restore states`
6. Before final response, report exact validation output and any Xcode/tooling blockers.
