# Phase 2: Credits System + IAP Transition - Pattern Map

**Mapped:** 2026-08-16
**Files analyzed:** 23 (9 new iOS + 12 modified iOS + 1 config + 1 conditional backend)
**Analogs found:** 22 / 23 (1 partial: backend JWS verification has no in-repo analog)

> **Dispatch provenance:** produced under the **generic-agent workaround** (no typed gsd-pattern-mapper dispatch in this harness). The role file `~/.codex/agents/gsd-pattern-mapper.md` was read and adopted; its contract, classification rules, and this structured return follow that role. Source of the file list: `02-RESEARCH.md` (no `02-CONTEXT.md` exists — dispatch constraints stand in for it).

## File Classification

All iOS paths are relative to `StressMonitor/` (Xcode project root). "Self" = the file being modified is its own analog (extension task — copy its own established conventions).

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `StressMonitor/Models/CreditBalance.swift` (NEW) | model | request-response (JSON decode) | `StressMonitor/Services/LLM/SSEParser.swift` (`SSEMetadata`, lines 17-22) | role-match |
| `StressMonitor/Services/API/StressAPIClient+Credits.swift` (NEW) | service (extension) | request-response | `StressMonitor/Services/API/StressAPIClient.swift` (`getHealth`, lines 56-62) | exact |
| `StressMonitor/Services/Credits/CreditServiceProtocol.swift` (NEW) | protocol seam | request-response | `StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift` (whole file, 46 lines) | role-match |
| `StressMonitor/Services/Credits/CreditService.swift` (NEW) | service (@Observable state owner) | event-driven (3-source convergence) + request-response | `StressMonitor/Services/LLM/StressLLMService.swift` (`creditsRemaining` + `apply(metadata:)`, lines 19, 105-113) | role-match |
| `StressMonitor/Services/StoreKit/CreditPack.swift` (NEW) | model (StoreKit display) | n/a (static catalog) | `StressMonitor/Models/SubscriptionPlan.swift` (whole file, 103 lines) | role-match |
| `StressMonitor/ViewModels/CreditsViewModel.swift` (NEW) | viewmodel | request-response | `StressMonitor/ViewModels/AccountViewModel.swift` (whole file, 44 lines) + `PremiumViewModel.swift` (purchase section, lines 39-61) | role-match |
| `StressMonitorTests/CreditServiceTests.swift` (NEW) | test | per-mock | `StressMonitorTests/AccountViewModelTests.swift` + `MockAuthService` (`StressAPIClientTests.swift` lines 11-54) | exact |
| `StressMonitorTests/StressAPIClientCreditsTests.swift` (NEW) | test | per-stub | `StressMonitorTests/StressAPIClientTests.swift` (`RequestCaptureURLProtocol`, lines 59-81) | exact |
| `StressMonitorTests/CreditsViewModelTests.swift` (NEW) | test | per-mock | `StressMonitorTests/AccountViewModelTests.swift` | exact |
| `StressMonitorTests/CreditPurchaseFlowTests.swift` (NEW, optional) | test (StoreKitTest) | event-driven | `StressMonitorTests/StoreKitServiceTests.swift` (header, lines 1-17 — disabled-suite caution) | role-match |
| `StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift` (MOD) | config/service | n/a | self (`resolve` 3-tier, lines 105-132; `clean`, 135-139) | exact |
| `StressMonitor/Services/StoreKit/StoreKitService.swift` (MOD) | service | event-driven + request-response | self (`purchase(_:)` lines 84-138; `handle(transactionVerification:)` lines 237-248) | exact |
| `StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift` (MOD) | protocol | n/a | self (error enum lines 3-36) | exact |
| `StressMonitor/Services/LLM/StressLLMService.swift` (MOD) | service | streaming | self (`apply(metadata:)` lines 105-113) | exact |
| `StressMonitor/Services/LLM/LLMServiceProtocol.swift` (MOD) | error contract | n/a | self (`.insufficientCredits` copy, lines 13, 32-34) | exact |
| `StressMonitor/ViewModels/ChatViewModel.swift` (MOD) | viewmodel | streaming | self (`catch let error as LLMServiceError` block, lines 157-170) | exact |
| `StressMonitor/Services/Premium/PaywallController.swift` (MOD) | service (presentation state) | event-driven | self (`PaywallReason` enum lines 6-13; `present(reason:)` lines 57-60) | exact |
| `StressMonitor/Views/Premium/IAPPremiumView.swift` + `Components/PlanCard.swift` (MOD) | component | n/a | self (plan grid + trial banner, `IAPPremiumView.swift` lines 31-62) | exact |
| `StressMonitor/Views/Settings/SettingsView.swift` (MOD) | component | n/a | self (`navRow` chat row lines 135-145; "StressMonitor Plus" row lines 263-272) | exact |
| `StressMonitor/StressMonitorApp.swift` (MOD) | app wiring | event-driven | self (`storeKitService` ownership, lines 22, 186, 196-205) | exact |
| `StressMonitorTests/StressMonitorProducts.storekit` (MOD) | config | n/a | self (subscription entries — add to `"products" : []`) | exact |
| `StressMonitor.xcodeproj/project.pbxproj` (MOD) | config | n/a | `AccountViewModelTests` registration (lines 41, 121, 268, 500) | exact |
| `stress-app-be/src/routes/credits.ts` (MOD, conditional cross-repo) | route | request-response | self (GET route, lines 9-22) — **JWS-verify half has no analog** | role-match |

## Pattern Assignments

### `StressMonitor/Services/API/StressAPIClient+Credits.swift` (service extension, request-response)

**Analog:** `StressMonitor/Services/API/StressAPIClient.swift` — same type, non-streaming GET half

`getBalance()`/`redeemPurchase(jws:)` copy `getHealth`'s shape (request → `session.data` → status check) but go through `authorizedRequest` (Bearer-injected). Note `StressAPIClient` is `@MainActor final class` with an `extension`-friendly surface — extend in a new file, do not fork the client.

**Auth pattern — the Bearer request builder to reuse verbatim** (`StressAPIClient.swift` lines 31-51):
```swift
/// Builds an authenticated URLRequest against the backend. Every
/// non-`/health` endpoint requires a Firebase ID token (backend verifies
/// via Firebase Admin `verifyIdToken`).
func authorizedRequest(
    path: String,
    method: String,
    body: Data? = nil,
    accept: String? = nil
) async throws -> URLRequest {
    let token = try await authService.getIDToken()

    var request = URLRequest(url: baseURL.appendingPathComponent(path))
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let accept {
        request.setValue(accept, forHTTPHeaderField: "Accept")
    }
    request.timeoutInterval = 90
    if let body {
        request.httpBody = body
    }
    return request
}
```

**Non-streaming GET pattern to adapt** (`StressAPIClient.swift` lines 56-62):
```swift
/// Liveness probe — public, no auth. Returns true only on HTTP 200.
func getHealth() async throws -> Bool {
    var request = URLRequest(url: StressAPIConfig.healthURL)
    request.httpMethod = "GET"
    request.timeoutInterval = 15
    let (_, response) = try await session.data(for: request)
    return (response as? HTTPURLResponse)?.statusCode == 200
}
```
Adaptation for `getBalance()`: `try await authorizedRequest(path: "credits", method: "GET")` → `session.data(for:)` → decode `CreditBalance` from `data`; map non-2xx (research: 401/500 possible). For `redeemPurchase(jws:)`: `method: "POST"` with `body` = `{"transaction_jws": <string>}` (body key pinned by 02-02/02-03 contract: `transaction_jws` — keep the pinning test).

**Error handling:** follow `sendChat`'s guard style (lines 99-103): `guard let httpResponse = response as? HTTPURLResponse else { throw … }`. Non-streaming methods should throw `LLMServiceError.unavailable(reason:)`-style errors or decode the backend's `{error, code}` body — mirror what `StressLLMService.mapHTTPError` does for `/chat` but keep it local to the extension (the D-07 mapper is chat-specific).

---

### `StressMonitor/Models/CreditBalance.swift` (model, request-response decode)

**Analog:** `SSEMetadata` in `StressMonitor/Services/LLM/SSEParser.swift` (lines 17-22) — the existing in-repo mirror of the same backend credit fields, parsed by hand:
```swift
struct SSEMetadata: Sendable {
    let sessionId: UUID?
    let creditsRemaining: Int?
    let modelUsed: String?
    let quickActions: [String]?
}
```
`CreditBalance` is the Codable twin of `GET /credits`: `{total: Int, used: Int, remaining: Int, plan_type: String ("free"|"premium"), free_reset_at: String? (ISO8601 or null)}` (research-verified contract, `stress-app-be/src/routes/credits.ts:9-21`). Backend source of truth — `Codable`, `Sendable`, `Decodable`-first. Add a display rule rather than raw formatting: **premium renders "Unlimited", never `999999`** (Pitfall 4). Consider `CodingKeys` none needed if property names match snake_case — they don't (`free_reset_at`), so include `CodingKeys` mapping. Tests assert decode from a fixture `Data`.

---

### `StressMonitor/Services/Credits/CreditServiceProtocol.swift` (protocol seam)

**Analog:** `StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift` — the project's dedicated-file protocol + LocalizedError enum pattern:
```swift
enum StoreKitError: LocalizedError, Equatable {
    case purchaseFailed
    // ...
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        // ...
```
```swift
protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
    func refreshEntitlements() async
    func isEligibleForIntroOffer(for period: SubscriptionPeriod) async -> Bool
}
```
Follow this shape: one file, `CreditServiceError` (or reuse `LLMServiceError`-adjacent naming) + `CreditServiceProtocol` with `Sendable`-annotated protocol (see `AuthServiceProtocol`, `FirebaseAuthService.swift` lines 11-17: `protocol AuthServiceProtocol: Sendable`). Surface: `var balance: CreditBalance? { get }`, `func refreshBalance() async`, `func apply(_ balance: CreditBalance)`, `func apply(creditsRemaining: Int)` — keep it minimal; the VM composes.

---

### `StressMonitor/Services/Credits/CreditService.swift` (service, @Observable state owner)

**Analog:** `StressMonitor/Services/LLM/StressLLMService.swift` — the established pattern of a `@MainActor final class` service that owns per-message credit state and converges it from the metadata event:

State + convergence (`StressLLMService.swift` lines 17-27, 105-113):
```swift
@MainActor
final class StressLLMService: LLMServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private(set) var currentSessionId: UUID?
    private(set) var creditsRemaining: Int?
    private(set) var modelUsed: String?
    private(set) var quickActions: [String]?
```
```swift
    private func apply(metadata: SSEMetadata) {
        if let sessionId = metadata.sessionId {
            currentSessionId = sessionId
            UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        }
        creditsRemaining = metadata.creditsRemaining
        modelUsed = metadata.modelUsed
        quickActions = metadata.quickActions
    }
```
`CreditService` copies this ownership model (research Pattern 3): balance converges from three sources — `GET /credits`, chat metadata (`credits_remaining` → `apply`), redemption response. **Never decrement locally** (anti-pattern, research-verified). Make it `@Observable` (not just `@MainActor final`) since views read it directly — combine `StressLLMService`'s state ownership with `PremiumState`'s observability:
```swift
@MainActor
@Observable
final class PremiumState {
    static let shared = PremiumState()
    // ...
```
(`PremiumState.swift` lines 6-8). Decide singleton vs injected — prefer injected via app-scope ownership (see Shared Pattern: App-scope service) over a second `static let shared` for the credit state, since `CreditService` needs an `StressAPIClient` dependency.

---

### `StressMonitor/Services/StoreKit/CreditPack.swift` (model, StoreKit display)

**Analog:** `StressMonitor/Models/SubscriptionPlan.swift` — the exact same job (StoreKit product → display card model) for subscriptions:
```swift
enum SubscriptionPeriod: String, CaseIterable {
    case annual
    case monthly
    case weekly
}

struct SubscriptionPlan: Identifiable {
    let id: SubscriptionPeriod
    let displayName: String
    let pricePerMonth: Decimal
    let pricePerPeriod: Decimal
    let period: SubscriptionPeriod
    var savingsPercent: Int?
    let isBestValue: Bool
    let subtitle: String?
    // StoreKit-driven fields
    let productID: String?
    let displayPrice: String?
    // ...
```
Copy: `Identifiable` struct, `defaultPacks` fallback (like `SubscriptionPlan.defaultPlans`, lines 56-102) for when no product IDs resolve, `displayPrice` preferred over formatted `Decimal` (lines 44-49), optional `savingsPercent` → `savingsDisplay` (lines 51-54). Pack identity: an enum or stable `id` (e.g. `.small/.medium/.large`) rather than raw product ID, mirroring `SubscriptionPeriod`'s role.

---

### `StressMonitor/ViewModels/CreditsViewModel.swift` (viewmodel, request-response)

**Analog 1 — state/rethrow pattern:** `StressMonitor/ViewModels/AccountViewModel.swift` (whole file, 44 lines):
```swift
@MainActor
@Observable
final class AccountViewModel {

    var linkedEmail: String?
    var isSigningIn = false
    var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
    }
```
```swift
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        do {
            try await authService.signInWithGoogle(presenting: viewController)
            refreshAccountState()
        } catch {
            errorMessage = GoogleSignInCancellation.isUserCancellation(error)
                ? nil
                : error.localizedDescription
            throw error
        }
    }
```
Copy: guard-against-reentry, `defer` reset, silent classification of user cancellation, **rethrow so the view decides presentation** while owning `errorMessage`.

**Analog 2 — purchase state machine:** `StressMonitor/ViewModels/PremiumViewModel.swift` `purchaseSelectedPlan()` (lines 39-61):
```swift
    func purchaseSelectedPlan() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let plan = selectedPlanDetails else {
                errorMessage = "Plan not available. Please try again."
                showError = true
                return
            }
            try await storeKit.purchase(plan)
            // Derive success from premium state, not from purchase call alone
            showSuccess = premiumState.isPremiumUser
        } catch StoreKitError.purchaseCancelled {
            // User cancelled — silent
        } catch StoreKitError.purchasePending {
            errorMessage = StoreKitError.purchasePending.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
```
Copy: silent `.purchaseCancelled`, explicit `.purchasePending` message, success derived from post-state (for packs: derive from `CreditService.balance` after redemption ack, not from the `purchase()` return).

---

### `StressMonitor/Services/StoreKit/StoreKitService.swift` (MOD — pack purchase + deferred grant)

**Analog:** itself. Current subscription purchase flow, lines 84-138 — the pack version keeps steps 1-3 identical and changes step 4:
```swift
    func purchase(_ plan: SubscriptionPlan) async throws {
        // 1. Resolve product ID
        let productID = plan.productID ?? catalog.productID(for: plan.period)
        guard let productID else {
            throw StoreKitError.missingProductConfiguration
        }

        // 2. Fetch / cache product
        let product: Product
        if let cached = productsByID[productID] {
            product = cached
        } else {
            let fetched = try await Product.products(for: [productID])
            guard let first = fetched.first else {
                throw StoreKitError.productNotFound
            }
            product = first
            productsByID[product.id] = product
        }

        // 3. Purchase with availability guard
        let result: Product.PurchaseResult
        if #available(iOS 18.2, *),
           let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            result = try await product.purchase(confirmIn: scene)
        } else {
            result = try await product.purchase()
        }

        // 4. Handle result
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Only grant entitlement for known products with active transaction
            if catalog.period(for: transaction.productID) != nil,
               transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > Date() }) ?? true {
                premiumState.isPremiumUser = true
            }

            await transaction.finish()
            await refreshEntitlements()
```
Pack flow replaces the grant block (research Pattern 2): on `.success` → `checkVerified` → **POST JWS to backend redeem → only `await transaction.finish()` after server ack** → `creditService.apply(newBalance)`. Do NOT touch `premiumState` for packs.

**Verification gate to reuse** (lines 252-259):
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

**Retry path to reuse** — the `Transaction.updates` listener must route pack transactions through the same deferred-grant flow so a mid-flow crash retries at next launch (lines 229-248):
```swift
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionVerification: result)
            }
        }
    }

    private func handle(transactionVerification result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // Refresh entitlements (handles revoke/grant)
            await refreshEntitlements()
            await transaction.finish()

        case .unverified(let transaction, _):
            // Do not grant entitlement. Finish to clear the queue.
            await transaction.finish()
        }
    }
```
⚠️ `handle` currently finishes unconditionally — for consumables it must first redeem server-side (unfinished redelivery is the crash-recovery mechanism). Keep `refreshEntitlements()` honoring subscriptions (grandfathering decision governs; research Pitfall 1 / Open Q2).

**Also modify:** `restorePurchases()` error copy — `StoreKitError.noActiveSubscription` ("No active subscription was found for this Apple ID.", `StoreKitServiceProtocol.swift` line 33) is wrong copy in a packs world; `AppStore.sync()` cannot restore consumables.

---

### `StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift` (MOD — pack IDs)

**Analog:** itself. Add pack resolution following the exact 3-tier pattern (lines 47-90 init + lines 105-132 resolve):
```swift
        self.weeklyProductID = Self.resolve(
            infoKey: "STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID",
            envKey: "STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID",
            defaultsKey: "storeKitPremiumWeeklyProductID",
            bundle: bundle,
            environment: env,
            defaults: defs
        )
```
Add e.g. `smallPackProductID`/`mediumPackProductID`/`largePackProductID` (+ `pack(for:)`/`packID(for:)` lookups mirroring `period(for:)`, lines 35-40). Keys are additive — no migration. Test initializer variant mirrors the direct one at lines 93-101.

---

### `StressMonitor/Services/LLM/StressLLMService.swift` (MOD — convergence hookup)

**Analog:** itself. `apply(metadata:)` (lines 105-113) currently writes `creditsRemaining` into service-local state with no observer. Phase 2 routes the same value into `CreditService` (inject a callback/closure or the service itself — keep `StressLLMService` free of a hard `CreditService` dependency if the seam stays protocol-shaped). The 402 mapping (lines 127-137) is **already correct — do not rebuild**:
```swift
    static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
        switch statusCode {
        case 200...299: return nil
        case 401: return .unavailable(reason: "Please sign in to use AI Chat.")
        case 402: return .insufficientCredits
```

---

### `StressMonitor/Services/LLM/LLMServiceProtocol.swift` (MOD — error copy)

**Analog:** itself. `.insufficientCredits` copy (lines 32-34 area):
```swift
        case .insufficientCredits:
            return "Out of credits. Monthly credits reset automatically."
```
Becomes wrong once packs exist (research "current dead end"). Rewrite to a short nudge ("You're out of credits.") since the chat sheet will route to the paywall rather than rely on this string (anti-pattern: duplicating paywall content in both surfaces).

---

### `StressMonitor/ViewModels/ChatViewModel.swift` (MOD — 402 → paywall routing)

**Analog:** itself, the catch block (lines 157-170) that currently only renders text:
```swift
        } catch let error as LLMServiceError {
            if case .exceededContext = error {
                // Intentionally discards any partial text — the whole
                // conversation is being cleared to recover from overflow.
                messages.removeAll()
                errorMessage = error.localizedDescription
            } else {
                preservePartialResponseIfNeeded()
                errorMessage = error.localizedDescription
            }
        } catch {
            preservePartialResponseIfNeeded()
            errorMessage = error.localizedDescription
        }
```
Add a branch: `if case .insufficientCredits = error { /* trigger paywall via injected presentation closure or PaywallController */ }` — keep `errorMessage` short and route presentation to `PaywallController` (see Shared Pattern: Paywall presentation). Note `ChatViewModel` takes dependencies via its test-injectable init (lines 68-79) — add the paywall trigger there, never by constructing UI inside the VM. Test with the `FakeLLMService` double (`ChatLifecycleTests.swift` lines 96-125 — currently **orphaned from the build**, see Test Registration).

---

### `StressMonitor/Services/Premium/PaywallController.swift` (MOD — `.outOfCredits` reason)

**Analog:** itself. Reason enum (lines 6-13) + presentation with premium guard (lines 57-60):
```swift
enum PaywallReason: Hashable {
    case general
    case trendsLongRange
    case bioAgeDetail
    case characters
    case breathingAdvanced
    case feature(named: String)
}
```
```swift
    /// Present the paywall full-screen for `reason`.
    /// No-ops when the user already has premium.
    func present(reason: PaywallReason) {
        guard !premiumState.isPremiumUser else { return }
        presentation = PaywallPresentation(reason: reason)
    }
```
Add `case outOfCredits`. ⚠️ The premium guard suppresses the credit paywall for premium users — correct **iff** the grandfathering decision maps premium ⇒ server `plan_type='premium'` (research Open Q5, tied to Q2). Flag in plan; do not silently change the guard.

---

### `StressMonitor/Views/Premium/IAPPremiumView.swift` + `Components/PlanCard.swift` (MOD — pack UI)

**Analog:** itself. Plan grid + skeleton pattern (lines 31-62):
```swift
                        VStack(spacing: 10) {
                            ForEach(Array(orderedPlans.enumerated()), id: \.offset) { _, plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: viewModel.selectedPlan == plan?.period,
                                    isLoading: isLoadingPlans,
                                    onSelect: {
                                        if let period = plan?.period {
                                            viewModel.selectedPlan = period
                                            HapticManager.shared.buttonPress()
                                        }
                                    }
                                )
                            }
                        }
```
Pack cards reuse `PlanCard` (or a sibling `PackCard` sharing its tokens: `Typography.iap*`, `Color.iap*`). `orderedPlans` nil-placeholder skeleton trick (lines 190-199) carries over. The trial banner (lines 153-186) and fine print ("Subscription auto-renews. Cancel anytime…", lines 87-105) become dead/wrong for packs — repurpose or gate by mode. Follow UI rules: dual coding, `.accessibleDynamicType()`, ≥44pt targets, `HapticManager` (AGENTS.md design system).

---

### `StressMonitor/Views/Settings/SettingsView.swift` (MOD — balance display)

**Analog:** itself — the `navRow(value:)` pattern. Chat row (lines 135-145):
```swift
                navRow(
                    icon: AppIconSystem.Setting.rippleCoach.sfSymbol,
                    setting: .rippleCoach,
                    tint: .settingsIconPurple,
                    title: "Ripple Coach",
                    value: chatAvailabilityLabel,
                    action: {
                        guard ChatAvailability.current.isAvailable else { return }
                        showChatSheet = true
                    }
                )
```
Plus row (lines 263-272):
```swift
                navRow(
                    icon: AppIconSystem.Setting.stressMonitorPlus.sfSymbol,
                    setting: .stressMonitorPlus,
                    tint: .premiumGold,
                    title: "StressMonitor Plus",
                    value: "Try free",
                    valueTint: .premiumGold,
                    action: { paywall.present(reason: .general) }
                )
```
Balance placement options (research Open Q4): value text on the Ripple Coach row (e.g. `"12 credits"` replacing/next to `chatAvailabilityLabel`, computed at lines 483+), the Plus row value ("Try free" → live balance), and/or chat sheet header pill. `MeHeroCard.onPlusTap: { paywall.present(reason: .general) }` (line 108) is the existing entry-point hook pattern.

---

### `StressMonitor/StressMonitorApp.swift` (MOD — CreditService app-scope ownership)

**Analog:** itself — the `storeKitService` ownership pattern (lines 17-22, 184-205):
```swift
    // Owned once for the app's process lifetime so the Transaction.updates
    // listener started in its init runs the whole time, not just while the
    // paywall happens to be on screen. See StoreKitServiceEnvironment.swift.
    @State private var storeKitService: StoreKitServiceProtocol = Self.makeStoreKitService()
```
```swift
            OnboardingContainerView()
                .environment(appRouter)
                .environment(paywall)
                .environment(\.storeKitService, storeKitService)
```
```swift
        .onChange(of: scenePhase) { _, newPhase in
            // Self-correct entitlement state on every foreground, not only
            // when Transaction.updates happens to deliver something while
            // the app is already running.
            guard newPhase == .active else { return }
            Task { @MainActor in
                await storeKitService.refreshEntitlements()
```
Copy for `CreditService`: `@State private var creditService` + `.environment(...)` + add `creditService.refreshBalance()` to the same foreground `scenePhase` block (research Pattern 3 source (a); doubles as the AUTH-02 live-session probe). DEBUG/Release factory split (`makeStoreKitService`, lines 213-221) is the template if a `MockCreditService` enters DEBUG default. BUILD-05: while touching these files, run one `-configuration Release` build checkpoint (research Runtime State Inventory).

---

### `StressMonitorTests/StressMonitorProducts.storekit` (MOD — consumable entries)

**Analog:** itself. `"products" : []` (top of file) receives entries shaped per research; subscription entries in `"subscriptionGroups"` stay as the structural reference:
```json
        {
          "displayPrice" : "2.99",
          "internalID" : "SMWK0001",
          "localizations" : [ { "description" : "StressMonitor Plus weekly", "displayName" : "Weekly", "locale" : "en_US" } ],
          "productID" : "com.stressmonitor.app.premium.weekly",
          "recurringSubscriptionPeriod" : "P1W",
          "referenceName" : "Weekly",
          "subscriptionGroupID" : "SMPREMIUM01",
          "type" : "RecurringSubscription"
        }
```
Consumable entries use `"type" : "Consumable"` + `"internalID"` (e.g. `SMCP0010`) with no period/group fields (research Code Examples; IDs/prices are the user's open decision — shape only). Scheme wiring already points both Test and Launch actions at this file (`StressMonitor.xcscheme` lines 46, 76 — verified). Plain JSON — manual edit is the fallback if the Xcode editor mangles it (research A6).

---

### Test files (NEW — 3 required + 1 optional)

**Analog A — Swift Testing + mock seam:** `StressMonitorTests/AccountViewModelTests.swift` (whole file) — `@Test("…")` descriptions, `#expect`, `@MainActor struct` suite, constructor-injected mock.

**Analog B — the mock itself:** `MockAuthService` (`StressMonitorTests/StressAPIClientTests.swift` lines 11-54):
```swift
/// Test double for `AuthServiceProtocol`, pinned to the test target so it
/// never ships in the Release app (threat T-03-01). Returns a fixed token so
/// `StressAPIClient.authorizedRequest` can be asserted without a live Firebase
/// session, and records sign-out / sign-in calls for the FirebaseAuthService
/// seam test. Reused by `FirebaseAuthServiceTests` — do not duplicate.
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    let token: String
    // ...call counters: private(set) var tokenCallCount = 0
```
`MockCreditService` follows: test-target-only, fixed `CreditBalance`, call counters, `@unchecked Sendable`. Doc comment convention: state the threat-model reason and "do not duplicate" reuse note.

**Analog C — URLProtocol stub:** `RequestCaptureURLProtocol` (`StressAPIClientTests.swift` lines 59-81):
```swift
final class RequestCaptureURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var statusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let code = Self.statusCode
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
```
For `StressAPIClientCreditsTests`: extend the stub to return a body (add `nonisolated(unsafe) static var bodyData: Data`), configure ephemeral session with `config.protocolClasses = [RequestCaptureURLProtocol.self]` (usage at lines 111-121).

**Analog D — throwing fake for chat routing:** `FakeLLMService` (`ChatLifecycleTests.swift` lines 96-125) — make it throw `.insufficientCredits` for the 402-routing test. File is currently **orphaned** — registration repair is part of this phase (below).

**StoreKitTest caution** (`StoreKitServiceTests.swift` lines 14-20, verified):
```swift
@Suite(.serialized, .disabled("StoreKitTest session-isolation bug on CI — see file header"))
```
New StoreKitTest-based suites inherit this risk — prefer protocol-mock tests (`MockStoreKitService` is DEBUG-gated in the app target, `MockStoreKitService.swift` lines 3-4; `PremiumViewModelTests`' `FakeStoreKitService` is the compiled production-path double). If StoreKitTest is used: single serialized suite, shared `StoreKitTestSessionProvider.session()` (lines 30-33).

**Every new test file MUST be registered in `project.pbxproj`** — the 4-line pattern (verified anchors for `AccountViewModelTests`):
```
line  41:  F1A1B2C3D4E500000000B006 /* AccountViewModelTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = F1A1B2C3D4E500000000A006 /* AccountViewModelTests.swift */; };
line 121:  F1A1B2C3D4E500000000A006 /* AccountViewModelTests.swift */ = {isa = PBXFileReference; ...; path = StressMonitorTests/AccountViewModelTests.swift; sourceTree = "<group>"; };
line 268:  (group children entry)
line 500:  F1A1B2C3D4E500000000B006 /* AccountViewModelTests.swift in Sources */,
```
ID scheme `F1A1B2C3D4E5…A00x` (file ref) / `…B00x` (build file); next free suffix must be checked against existing entries. Orphaned files needing the same repair: `ChatLifecycleTests`, `SSEParserTests`, `LLMServiceErrorTests`, `EntitlementForegroundCorrectionTests`, `DataDeletionConsolidationTests`, `StoreKitProductCatalogLiveTests`; `ChatAvailabilityTests` references deleted Supabase symbols (delete/rewrite).

---

### `stress-app-be/src/routes/credits.ts` (MOD — conditional, cross-repo)

**Analog:** itself — the GET route (whole file, 36 lines):
```typescript
  app.get("/", async (c) => {
    const uid = c.get("uid");

    if (c.req.query("history") === undefined) {
      const balance = await getBalance(uid);
      if (!balance) return c.json({ error: "Failed to fetch credits" }, 500);
      return c.json({
        total: balance.total_credits,
        used: balance.used_credits,
        remaining: balance.total_credits - balance.used_credits,
        plan_type: balance.plan_type,
        free_reset_at: balance.free_reset_at,
      });
    }
```
A `POST /credits/redeem` copies the route-group shell (`Hono<AppEnv>`, `c.get("uid")` from auth middleware, `sql` template inserts into `credit_transactions` with `type='purchase'`, unique on transaction id for idempotency, return the same balance shape so iOS can `CreditBalance`-decode the response). **The JWS-verification half has no analog anywhere in either repo** — see No Analog Found.

## Shared Patterns

### Authentication (Bearer token on every /credits call)
**Source:** `StressMonitor/Services/API/StressAPIClient.swift` lines 31-51; token lifecycle `FirebaseAuthService.getIDToken` lines 47-58 (60s refresh margin)
**Apply to:** `StressAPIClient+Credits.swift` (all methods), any redemption call
Never build a raw `URLRequest` for authenticated endpoints — always `authorizedRequest(path:method:body:accept:)`.

### Protocol seam + test-target mock
**Source:** `AuthServiceProtocol` (`FirebaseAuthService.swift` lines 11-17) + `MockAuthService` (`StressAPIClientTests.swift` lines 11-54) + `StoreKitServiceProtocol.swift` (dedicated-file variant)
**Apply to:** `CreditServiceProtocol` + `MockCreditService`; `StoreKitServiceProtocol` pack additions
Convention: mocks live in the test target (never ship), carry call counters (`private(set) var …CallCount`), doc comment states reuse policy.

### @MainActor @Observable ViewModel contract
**Source:** `AccountViewModel.swift` (whole file); `PremiumViewModel.swift` lines 39-61
**Apply to:** `CreditsViewModel`
Rules: guard reentry, `defer` reset flags, rethrow for view-side presentation, silent user-cancellation, success derived from post-state.

### App-scope service ownership + environment injection
**Source:** `StressMonitorApp.swift` lines 17-22, 184-187, 196-205; `StoreKitServiceEnvironment.swift` (whole file, 24 lines — `#if DEBUG` default)
**Apply to:** `CreditService` (and any `creditService` EnvironmentKey if views read it directly)
Foreground refresh belongs in the existing `scenePhase == .active` block.

### Error enums as LocalizedError with user-facing copy
**Source:** `StoreKitServiceProtocol.swift` lines 3-29; `LLMServiceProtocol.swift` lines 6-40
**Apply to:** any `CreditServiceError`; the `.insufficientCredits` and `.noActiveSubscription` copy rewrites

### Paywall presentation
**Source:** `PaywallController.present(reason:)` lines 57-60; mounted root cover consumed in `MainTabView`; entry points: `SettingsView` lines 108, 270
**Apply to:** `ChatViewModel` 402 branch, Settings/chat-sheet entry points
`present` is the only API; never present a sheet directly for monetization UI.

### StoreKit verified-transaction handling
**Source:** `StoreKitService.swift` — `checkVerified` lines 252-259, `listenForTransactions`/`handle` lines 229-248
**Apply to:** pack purchase + updates listener
Throw on `.unverified`; finish only after the server ack (deferred grant); `Transaction.updates` is the retry path.

### Test registration (pbxproj 4-line edit)
**Source:** `project.pbxproj` lines 41, 121, 268, 500
**Apply to:** every new test file. Without it the file silently doesn't compile (research Pitfall 7).

### Verify commands
Every `xcodebuild test` in every task plan carries `-parallel-testing-enabled NO` (host constraint; research Pitfall 8):
`xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:StressMonitorTests/<Suite> -parallel-testing-enabled NO`

## No Analog Found

| File/Element | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `stress-app-be` JWS verification (inside `POST /credits/redeem`) | middleware (route guard) | request-response | No server-side Apple-signature verification exists in either repo. Use Apple's App Store Server Library (or `jsonwebtoken` + Apple root certs) per research "Don't Hand-Roll"; do NOT hand-roll X.509/OCSP. Planner: gate this behind the cross-repo checkpoint decision (research Open Q1). |
| `VerificationResult.jwsRepresentation` exact API spelling | — | — | [ASSUMED per research A1] — compile-verify against iOS 18.6 SDK headers during implementation; Phase 1 hit the same class of Firebase-API-drift issue. |

## Metadata

**Analog search scope:** `StressMonitor/StressMonitor/**` (services, models, viewmodels, views, app), `StressMonitor/StressMonitorTests/**`, `StressMonitor/StressMonitor.xcodeproj/**` (pbxproj + scheme), `stress-app-be/src/routes/**`
**Files scanned:** ~30 Swift files read in full or targeted; grep coverage over both repos
**Pattern extraction date:** 2026-08-16
**Provenance note:** generic-agent workaround dispatch; gsd-pattern-mapper role file adopted verbatim (`~/.codex/agents/gsd-pattern-mapper.md`).
