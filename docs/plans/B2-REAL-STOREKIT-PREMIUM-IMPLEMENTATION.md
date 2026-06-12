# B2: Real StoreKit / Premium Implementation Plan

> **Kanban:** B2 (P0 BLOCKER) | **Branch:** `plan/b2-real-storekit-premium`
> **Verified/Corrected:** 2026-06-12 using converted Axiom StoreKit/IAP skills
> **Status:** Plan corrected and ready for implementation, with one external product-ID gate

---

## Goal

Replace the mock-only Premium purchase flow with a production-safe StoreKit 2 implementation that can:

- fetch monthly/annual subscription products,
- purchase subscriptions,
- verify every StoreKit transaction before granting Premium,
- finish every handled transaction,
- restore purchases,
- refresh subscription entitlement state from StoreKit,
- remove release-build `fatalError` crashes in Premium entry points,
- keep the current custom paywall UI with minimal design churn.

---

## Axiom Verification Result

This plan was reviewed against converted Axiom skills:

- `axiom-implement-iap`
- `axiom-audit-iap`
- `axiom-integration` / `references/in-app-purchases.md`
- `axiom-integration` / `references/storekit-ref.md`
- `axiom-testing`

Important corrections from that review:

1. A local `.storekit` configuration should be created before real purchase QA, but this repo currently has no product IDs. The implementer must not invent production product IDs. If product IDs are not available, implement the code with configurable IDs and mark local StoreKit config/manual purchase QA as blocked.
2. Subscription state must handle more than “not expired”: active, grace period, billing retry, expired, and revoked should have explicit semantics.
3. A long-running `Transaction.updates` listener is required, and every verified/unverified handled transaction must be finished after entitlement handling/denial.
4. Product display prices must come from StoreKit `Product.displayPrice`; the paywall must not keep hardcoded production prices as truth.
5. Subscription terms must stay visible before purchase: price, duration/period, auto-renewal, cancellation, Terms of Service, and Privacy Policy.
6. `PremiumState` needs a testable construction/reset path so PremiumViewModel tests do not pollute real `UserDefaults.standard` state.

---

## Evidence / Current State

### Ship blocker from kanban

`docs/KANBAN-SHIP-READINESS.md:16-25` lists B2 as P0 backlog:

- Implement `StoreKitService` conforming to `StoreKitServiceProtocol`
- Product fetching from App Store Connect / StoreKit configuration
- Purchase flow with Apple StoreKit
- Receipt / transaction validation
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
- `PremiumViewModel` already depends on `StoreKitServiceProtocol`:
  - `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift:5-67`
- `SubscriptionPlan` currently stores local mock prices only and has no StoreKit product identifier:
  - `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift:8-56`
- `PlanSelectionCard` hardcodes `/month` in the UI:
  - `StressMonitor/StressMonitor/Views/Premium/Components/PlanSelectionCard.swift:27-35`
- `IAPPremiumView` already loads plans, purchases selected plan, restores purchases, opens manage subscriptions, and shows alerts:
  - `StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift:7-103`
- Current repository scan found no existing `import StoreKit`, `Product.products(for:)`, `Transaction.updates`, `Transaction.currentEntitlements`, or `.storekit` file in the app source.
- The Xcode project uses `PBXFileSystemSynchronizedRootGroup` for `StressMonitor` and `StressMonitorTests`, so new files under those folders should normally be picked up without hand-editing every file reference.

---

## Non-Negotiable Constraints

1. Use StoreKit 2 (`import StoreKit`) for production IAP code.
2. Do not add StoreKit 1 (`SKProductsRequest`, `SKPaymentQueue`, `SKPaymentTransactionObserver`) unless a future App Store promoted-purchase requirement explicitly needs it.
3. Keep `MockStoreKitService` under `#if DEBUG` only.
4. Do not hardcode secrets.
5. Do not invent App Store Connect production product IDs.
6. Product IDs must come from configuration or confirmed public product IDs.
7. Do not add third-party dependencies.
8. Do not move health/stress data to the backend in this task.
9. Keep UI design changes minimal; this is production wiring, not a paywall redesign.
10. Preserve the iOS 17+ target. Do not require `product.purchase(confirmIn:)` unless guarded by availability; plain `product.purchase()` is acceptable for iOS 17.
11. Add tests around testable seams instead of trying to construct StoreKit `Product`/`Transaction` directly.

---

## Product ID / StoreKit Configuration Gate

The repository currently has no product IDs. This creates an external gate.

### Required decision before full manual QA

The team must provide or approve values for:

- monthly product ID
- annual product ID
- subscription group ID, if subscription status should use `Product.SubscriptionInfo.status(for:)`

Recommended naming shape, **not to be committed as production truth unless confirmed**:

- `com.<team>.<app>.premium.monthly`
- `com.<team>.<app>.premium.annual`
- `premium` or ASC-provided subscription group ID

### If product IDs are available

Create and commit a StoreKit configuration file:

- `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`

It should include:

- monthly auto-renewable subscription,
- annual auto-renewable subscription,
- both in the same subscription group,
- real/confirmed product IDs,
- test prices suitable for StoreKit testing.

Then configure the scheme in Xcode when possible:

- Scheme → Edit Scheme → Run → Options → StoreKit Configuration

### If product IDs are not available

Do not invent them. Still implement:

- configurable product catalog,
- real StoreKit service,
- view-model handling,
- release crash removal,
- unit tests for catalog and `PremiumViewModel`.

But completion must explicitly report:

- “StoreKit local purchase QA blocked: product IDs/subscription group not provided.”

---

## Target Architecture

```text
SettingsView / TrendsView
  -> IAPPremiumView
      -> PremiumViewModel
          -> StoreKitServiceProtocol
              -> DEBUG: MockStoreKitService for previews/demo when desired
              -> RELEASE: StoreKitService
                    -> StoreKitProductCatalog
                    -> Product.products(for:)
                    -> Product.purchase()
                    -> VerificationResult<Transaction>
                    -> Transaction.currentEntitlements
                    -> Product.SubscriptionInfo.status(for:) when group ID exists
                    -> Transaction.updates listener
                    -> AppStore.sync()
                    -> PremiumState
```

---

## Files to Create / Modify

### Create

- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`
- `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`
- `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift`
- Optional if IDs are confirmed: `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`

### Modify

- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`
- `StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift`
- `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift`
- `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`
- `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`
- `StressMonitor/StressMonitor/Views/Premium/Components/PlanSelectionCard.swift`
- `StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift` only if needed for terms/error copy
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`
- `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`

---

## StoreKitProductCatalog

Create `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`.

Required API:

```swift
struct StoreKitProductCatalog: Sendable {
    let monthlyProductID: String?
    let annualProductID: String?
    let subscriptionGroupID: String?

    var allProductIDs: Set<String> { get }
    func productID(for period: SubscriptionPeriod) -> String?
    func period(for productID: String) -> SubscriptionPeriod?
}
```

Lookup order:

1. `Bundle.main.object(forInfoDictionaryKey:)`
   - `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID`
   - `STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID`
   - `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID`
2. `ProcessInfo.processInfo.environment` with same keys for tests/CI.
3. `UserDefaults.standard.string(forKey:)` for local QA:
   - `storeKitPremiumMonthlyProductID`
   - `storeKitPremiumAnnualProductID`
   - `storeKitPremiumSubscriptionGroupID`

Testability requirement:

- Provide an initializer that accepts explicit bundle/env/defaults source values or dictionaries so tests do not mutate process-wide environment.
- Treat empty strings and unresolved build setting placeholders like `$(STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID)` as nil.

Acceptance:

- Missing product IDs never crash.
- Missing product IDs make purchase fail with a user-safe configuration error.
- The catalog can map annual/monthly product IDs back to `SubscriptionPeriod`.

---

## SubscriptionPlan Changes

Modify `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`.

Add:

```swift
let productID: String?
let displayPrice: String?
let billingSummary: String?
let periodUnitDisplay: String
```

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

Rules:

- `priceDisplay` should prefer StoreKit `displayPrice` if available.
- `SubscriptionPlan.defaultPlans` remains available only as mock/fallback display data.
- Avoid importing StoreKit in the model if possible; map StoreKit `Product` to `SubscriptionPlan` inside `StoreKitService`.
- Annual plan copy must not imply the user is charged monthly only. Show a billing summary such as “Billed annually” or “Renews yearly” when available.

Update `PlanSelectionCard`:

- Replace the hardcoded `/month` with `plan.periodUnitDisplay` or a richer period label.
- Ensure annual and monthly cards disclose period and billing summary clearly.

---

## PremiumState Testability

Modify `StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift`.

Current singleton persists `isPremiumUser` to `UserDefaults.standard` with a fixed key. Keep this for production, but add a testable path.

Preferred shape:

```swift
@MainActor
@Observable
final class PremiumState {
    static let shared = PremiumState()

    private let defaults: UserDefaults
    private let key: String

    var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: key) }
    }

    init(defaults: UserDefaults = .standard, key: String = "isPremiumUser") {
        self.defaults = defaults
        self.key = key
        self.isPremiumUser = defaults.bool(forKey: key)
    }
}
```

If keeping `init` private is required, add an internal `makeForTesting(defaults:key:)` helper under `#if DEBUG` or test target visibility.

Acceptance:

- Tests can create isolated premium state without writing to the real app’s `UserDefaults.standard` key.

---

## StoreKitServiceProtocol and Error Model

Modify `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`.

Keep the existing protocol if possible:

```swift
protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
}
```

Add only if useful:

```swift
func refreshEntitlements() async
```

If added, update `StoreKitService`, `MockStoreKitService`, and tests.

Extend `StoreKitError` with user-safe cases:

```swift
enum StoreKitError: LocalizedError, Equatable {
    case purchaseFailed
    case purchaseCancelled
    case purchasePending
    case restoreFailed
    case productNotFound
    case productFetchFailed
    case receiptValidationFailed
    case missingProductConfiguration
    case noActiveSubscription
}
```

Descriptions must be actionable and safe for users, e.g.:

- purchase pending: “Your purchase is pending approval. Premium will unlock after Apple completes it.”
- missing configuration: “Premium purchases are not configured for this build.”
- no active subscription: “No active subscription was found for this Apple ID.”

---

## StoreKitService Implementation

Create `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`.

### Required structure

```swift
import Foundation
import StoreKit

@MainActor
final class StoreKitService: StoreKitServiceProtocol {
    private let premiumState: PremiumState
    private let catalog: StoreKitProductCatalog
    private var productsByID: [String: Product] = [:]
    private var transactionUpdatesTask: Task<Void, Never>?
}
```

Recommended init:

```swift
init(
    premiumState: PremiumState = .shared,
    catalog: StoreKitProductCatalog = .live
) {
    self.premiumState = premiumState
    self.catalog = catalog
    transactionUpdatesTask = listenForTransactions()
    Task { await refreshEntitlements() }
}
```

`deinit` must cancel the transaction listener.

### Transaction listener

Axiom guidance: do not leave the `Transaction.updates` loop as an accidental main-actor-bound UI task.

Use one of these safe patterns:

```swift
private func listenForTransactions() -> Task<Void, Never> {
    Task.detached { [weak self] in
        for await result in Transaction.updates {
            await self?.handle(transactionVerification: result)
        }
    }
}
```

or a regular `Task` only if the compiler/actor isolation is verified and the loop does not block main-actor UI work.

### Verification helper

```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let safe):
        return safe
    case .unverified:
        throw StoreKitError.receiptValidationFailed
    }
}
```

### Product fetching

`availablePlans` should:

1. Read `catalog.allProductIDs`.
2. If empty, return `SubscriptionPlan.defaultPlans` for display only.
3. Fetch `try await Product.products(for: Array(productIDs))`.
4. Detect missing loaded products by comparing requested IDs to loaded IDs.
5. Map products to `SubscriptionPlan` using:
   - `product.id`
   - `product.displayName`
   - `product.displayPrice`
   - `product.price`
   - `product.subscription?.subscriptionPeriod`
6. Sort annual before monthly.
7. Cache `productsByID`.
8. If fetch fails, return fallback display plans but purchases must still fail clearly if no cached StoreKit product exists.

### Purchase flow

`purchase(_ plan:)` should:

1. Resolve product ID from `plan.productID` or `catalog.productID(for: plan.period)`.
2. Throw `.missingProductConfiguration` if no ID exists.
3. Fetch/cache the product if needed.
4. Call `try await product.purchase()` for iOS 17 compatibility.
5. Switch over `Product.PurchaseResult`:
   - `.success(let verification)`:
     - verify transaction,
     - apply entitlement only if product is known and transaction is active,
     - finish transaction,
     - refresh entitlements.
   - `.userCancelled`: throw `.purchaseCancelled`.
   - `.pending`: throw `.purchasePending`.
   - `@unknown default`: throw `.purchaseFailed`.

Do not set Premium based only on the purchase call returning success. Premium must be derived from verified transaction/entitlement state.

### Entitlement refresh

`refreshEntitlements()` should use both transaction entitlements and subscription status when available.

Minimum:

1. Iterate `Transaction.currentEntitlements`.
2. Verify every result.
3. Ignore unknown product IDs.
4. Treat a transaction as active only if:
   - known product ID,
   - `revocationDate == nil`,
   - `expirationDate == nil || expirationDate > Date()`.
5. Update `premiumState.isPremiumUser` from the result.

If `catalog.subscriptionGroupID` is available, also check:

```swift
let statuses = try await Product.SubscriptionInfo.status(for: groupID)
```

Handle states:

- `.subscribed`: Premium active.
- `.inGracePeriod`: Premium active, optionally surface billing issue later.
- `.inBillingRetryPeriod`: Premium active for now, optionally surface billing retry later.
- `.expired`: Premium inactive unless another active status exists.
- `.revoked`: Premium inactive unless another active status exists.
- `@unknown default`: do not grant new access from unknown state.

### Transaction update handling

For each `Transaction.updates` result:

- `.verified(let transaction)`:
  - if revoked/refunded, revoke entitlement via `refreshEntitlements()`.
  - otherwise refresh entitlements.
  - finish transaction.
- `.unverified(let transaction, _)`:
  - do not grant entitlement.
  - finish transaction to clear the queue.
  - optionally log a debug message.

### Restore purchases

`restorePurchases()` should:

1. Call `try await AppStore.sync()`.
2. Call `await refreshEntitlements()`.
3. If no active Premium entitlement exists, throw `.noActiveSubscription` or `.restoreFailed` with a user-safe message.

### Purchase history

`fetchPurchaseHistory()` should return lightweight support strings from `Transaction.all` if feasible:

- product ID,
- purchase date,
- expiration/revocation date when available,
- transaction ID.

If not used by UI yet, keep implementation simple but real. Do not leave a production stub returning `[]` in `StoreKitService`.

---

## PremiumViewModel Changes

Modify `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`.

Required behavior:

1. `loadInitialData()`:
   - set loading while fetching if UI should reflect it,
   - fetch plans,
   - if no plans, show a clear error,
   - select annual if present, otherwise first available plan.
2. `purchaseSelectedPlan()`:
   - keep selected-plan guard,
   - call service purchase,
   - do not blindly set `premiumState.isPremiumUser = true`,
   - set `showSuccess = premiumState.isPremiumUser` after service returns,
   - silently ignore `.purchaseCancelled`,
   - show user-safe alert for `.purchasePending`, `.missingProductConfiguration`, `.productNotFound`, etc.
3. `restorePurchases()`:
   - call service restore,
   - set success only if `premiumState.isPremiumUser` is true,
   - show “no active subscription” as a friendly recoverable alert.
4. `dismissError()` remains as-is.

---

## Premium UI / Subscription Terms

Existing `IAPPremiumView` already includes:

- Restore Purchases,
- Manage Subscriptions,
- Terms of Service link,
- Privacy Policy link,
- auto-renew/cancel-anytime copy.

Keep that, and ensure product-driven terms remain visible before purchase:

- StoreKit display price,
- period (`/month`, `/year`, or equivalent),
- annual billing summary when annual is selected,
- auto-renewal copy,
- cancellation/manage subscriptions path.

Update `PlanSelectionCard` so it does not hardcode `/month` for every plan.

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
- `fatalError` remains only for unrecoverable app setup, not Premium flow.

---

## Tests

This repo uses Swift Testing in:

- `StressMonitor/StressMonitorTests/CharacterCollectionViewModelTests.swift`

The Xcode project uses synchronized groups for `StressMonitorTests`, so add new test files under:

- `StressMonitor/StressMonitorTests/`

### StoreKitProductCatalogTests

Create `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`.

Test cases:

1. Missing values produce empty `allProductIDs`.
2. Empty strings are ignored.
3. Placeholder values like `$(STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID)` are ignored.
4. Explicit monthly/annual/group values are returned.
5. `productID(for:)` maps periods correctly.
6. `period(for:)` maps product IDs back to periods.

Use injected dictionaries/sources instead of mutating global environment.

### PremiumViewModelTests

Create `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift`.

Use a fake `StoreKitServiceProtocol` and isolated `PremiumState`.

Test cases:

1. `loadInitialData` loads plans.
2. `loadInitialData` selects annual when present.
3. `purchaseSelectedPlan` calls purchase and sets success only if Premium state becomes true.
4. Purchase cancellation does not set `showError`.
5. Purchase failure sets `showError` and `errorMessage`.
6. Pending purchase shows a friendly alert but does not mark Premium active.
7. Restore success sets success when Premium state is true.
8. Restore with no active subscription sets `showError`.

### StoreKitService tests

Full StoreKit 2 transaction tests are optional until product IDs / `.storekit` config are confirmed. Do not block unit-test coverage on unconstructible StoreKit `Product` values.

If a `.storekit` file is added and Xcode supports it locally, add StoreKit integration/manual QA notes instead of overfitting unit tests around Apple framework internals.

---

## Implementation Tasks

### Task 0 — Product ID / StoreKit config gate

**Objective:** Determine whether local StoreKit purchase QA can be configured now.

**Files:**

- Optional create: `StressMonitor/StressMonitor/Configuration/StressMonitor.storekit`

**Steps:**

1. Search repo for existing product IDs and `.storekit` files.
2. If confirmed product IDs exist, create `.storekit` first and document scheme setup.
3. If not, do not invent IDs. Continue code implementation and report the QA gate.

---

### Task 1 — Product catalog and errors

**Objective:** Add product ID configuration and StoreKit error cases.

**Files:**

- Create: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- Modify: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`
- Test: `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`

**Steps:**

1. Write catalog tests first.
2. Implement catalog with injectable sources.
3. Extend `StoreKitError` cases/descriptions.
4. Run targeted tests if Xcode available; otherwise parse Swift files.

---

### Task 2 — Make PremiumState testable

**Objective:** Let tests use isolated premium state.

**Files:**

- Modify: `StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift`

**Steps:**

1. Add injected defaults/key initializer or test factory.
2. Keep `PremiumState.shared` production behavior unchanged.
3. Use isolated state in `PremiumViewModelTests`.

---

### Task 3 — SubscriptionPlan StoreKit display model

**Objective:** Allow StoreKit products to drive display price and period copy.

**Files:**

- Modify: `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`
- Modify: `StressMonitor/StressMonitor/Views/Premium/Components/PlanSelectionCard.swift`

**Steps:**

1. Add optional `productID`, StoreKit display price storage, period label, and billing summary.
2. Preserve `defaultPlans` for fallback/mock.
3. Remove hardcoded `/month` from `PlanSelectionCard`.
4. Ensure annual plan has clear annual billing copy.

---

### Task 4 — Real StoreKitService

**Objective:** Implement product fetch, purchase, restore, validation, transaction listener, entitlement refresh, and purchase history.

**Files:**

- Create: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`
- Modify: `StoreKitServiceProtocol.swift` only if `refreshEntitlements()` is added.

**Steps:**

1. Implement product fetch and plan mapping.
2. Implement `purchase(_:)` with `Product.purchase()` and verified transaction handling.
3. Implement `restorePurchases()` with `AppStore.sync()`.
4. Implement `refreshEntitlements()` using `Transaction.currentEntitlements` and subscription group status when configured.
5. Implement transaction update listener.
6. Finish verified and unverified handled transactions.
7. Ensure missing config/product fetch failure never crashes.

---

### Task 5 — PremiumViewModel tests and behavior

**Objective:** Make view-model behavior production-safe and covered by tests.

**Files:**

- Modify: `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`
- Test: `StressMonitor/StressMonitorTests/PremiumViewModelTests.swift`

**Steps:**

1. Add fake StoreKit service in tests.
2. Test load, purchase success, cancellation, pending, failure, restore success/failure.
3. Update implementation to pass tests.
4. Ensure purchase success does not blindly set Premium true.

---

### Task 6 — Replace release factories

**Objective:** Remove production crashes.

**Files:**

- Modify: `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`
- Modify: `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`

**Steps:**

1. In release `#else`, return `StoreKitService(premiumState: PremiumState.shared)`.
2. Keep DEBUG using `MockStoreKitService` unless local StoreKit QA needs the real service in DEBUG.
3. Verify no `Live StoreKit service not yet implemented` string remains.

---

## Verification Checklist

Run as much as the host supports.

### Static checks

```bash
git diff --check
git grep -n 'Live StoreKit service not yet implemented' -- StressMonitor/StressMonitor || true
git grep -n 'MockStoreKitService' -- StressMonitor/StressMonitor
git grep -n 'SKProductsRequest\|SKPaymentQueue\|SKPaymentTransactionObserver' -- StressMonitor/StressMonitor || true
git grep -n 'Product\.products\|Product\.purchase\|Transaction\.updates\|Transaction\.currentEntitlements\|VerificationResult\|AppStore\.sync' -- StressMonitor/StressMonitor
```

Expected:

- No whitespace errors.
- No Premium release `fatalError` remains.
- No StoreKit 1 APIs introduced.
- StoreKit 2 product/purchase/transaction/verification/sync calls exist in `StoreKitService.swift`.

### Swift parse fallback when full Xcode is unavailable

```bash
swiftc -parse \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift \
  StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift \
  StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift \
  StressMonitor/StressMonitor/Models/SubscriptionPlan.swift \
  StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift \
  StressMonitor/StressMonitor/Views/Premium/Components/PlanSelectionCard.swift
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

If the host has `xcode-select` pointed to CommandLineTools instead of full Xcode, report that blocker and run `swiftc -parse` plus static checks.

### Manual QA when product IDs / StoreKit config exist

1. Select `StressMonitor.storekit` in scheme Run options.
2. Launch app in DEBUG.
3. Open Premium from Settings.
4. Products load from StoreKit display prices.
5. Annual card does not say only `/month` without annual billing context.
6. Purchase monthly succeeds in StoreKit test session.
7. Purchase annual succeeds in StoreKit test session.
8. Cancel purchase leaves Premium inactive and shows no error.
9. Pending purchase leaves Premium inactive and shows pending copy.
10. Restore purchases succeeds when subscription exists.
11. Restore purchases shows friendly “no active subscription” when none exists.
12. Refund/revocation in StoreKit transaction manager removes Premium after transaction update/refresh.
13. Relaunch app; Premium reflects current entitlement state.
14. Build in RELEASE configuration; opening Premium from Settings/Trends does not crash.

---

## Acceptance Criteria

### Code acceptance

- [ ] `StoreKitProductCatalog.swift` exists and has configurable product IDs.
- [ ] `StoreKitService.swift` exists and conforms to `StoreKitServiceProtocol`.
- [ ] Product fetching uses `Product.products(for:)`.
- [ ] Purchase flow uses StoreKit 2 `Product.purchase()` or an availability-guarded `purchase(confirmIn:)` path.
- [ ] Verified transactions update `PremiumState`; unverified transactions do not grant Premium.
- [ ] Handled transactions are finished.
- [ ] Restore purchases uses `AppStore.sync()` and entitlement refresh.
- [ ] Subscription state handles active, grace, billing retry, expired, and revoked when subscription group ID is configured.
- [ ] Release `fatalError("Live StoreKit service not yet implemented")` is removed.
- [ ] `MockStoreKitService` remains DEBUG-only.
- [ ] `PremiumViewModel` tests cover load, success, cancel, pending, failure, restore success, and restore failure.
- [ ] Product display prices and period labels are not hardcoded as production truth.
- [ ] Subscription terms remain visible before purchase.

### Release readiness gate

- [ ] Confirmed App Store Connect product IDs are configured.
- [ ] `.storekit` config exists or App Store Connect sandbox QA is documented.
- [ ] Manual StoreKit purchase/restore/refund QA completed.
- [ ] TestFlight purchase test completed before App Store submission.

If the release readiness gate is blocked by missing product IDs, the code can still be merged as infrastructure but B2 should remain not fully closed.

---

## Out of Scope

- App Store Connect product creation.
- Backend subscription mirroring / Supabase credit upgrade.
- App Store Server API validation.
- Paywall redesign.
- Analytics/telemetry.
- Family Sharing UI, promo offers, intro offers, win-back offers.
- Localization beyond preserving existing strings.

---

## Notes for the stress_app Implementer

1. Start from latest `main`, not from an old feature branch.
2. Create/use implementation branch `fix/b2-real-storekit-premium`.
3. Read this plan fully before editing.
4. Follow TDD for `StoreKitProductCatalog`, `PremiumState` testability, and `PremiumViewModel` behavior.
5. Do not invent production product IDs. If IDs are unavailable, implement the configurable path and report the StoreKit QA gate.
6. Keep commits focused:
   - `feat(storekit): add product catalog and real service`
   - `fix(premium): replace release StoreKit fatal errors`
   - `test(premium): cover purchase and restore states`
7. Before final response, report exact validation output and any Xcode/tooling/product-ID blockers.
