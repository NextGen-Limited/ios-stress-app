import Foundation
import StoreKit

@MainActor
final class StoreKitService: StoreKitServiceProtocol {

    private let premiumState: PremiumState
    private let catalog: StoreKitProductCatalog
    private var productsByID: [String: Product] = [:]
    private var transactionUpdatesTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init(
        premiumState: PremiumState? = nil,
        catalog: StoreKitProductCatalog? = nil
    ) {
        self.premiumState = premiumState ?? .shared
        self.catalog = catalog ?? .live
        self.transactionUpdatesTask = listenForTransactions()
        Task { await refreshEntitlements() }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    // MARK: - StoreKitServiceProtocol

    var availablePlans: [SubscriptionPlan] {
        get async {
            let productIDs = catalog.allProductIDs
            guard !productIDs.isEmpty else {
                // No product IDs configured — return fallback display plans.
                return SubscriptionPlan.defaultPlans
            }

            do {
                let products = try await Product.products(for: Array(productIDs))
                guard !products.isEmpty else {
                    return SubscriptionPlan.defaultPlans
                }

                // Cache products by ID
                for product in products {
                    productsByID[product.id] = product
                }

                // Map to SubscriptionPlan, sorted annual first, then monthly, then weekly
                var plans = products.compactMap { [catalog] product -> SubscriptionPlan? in
                    guard let period = catalog.period(for: product.id) else { return nil }
                    return Self.planFromProduct(product, period: period, catalog: catalog)
                }
                .sorted { lhs, rhs in
                    Self.periodSortOrder(lhs.period) < Self.periodSortOrder(rhs.period)
                }

                // Real savings, not a hardcoded guess — needs both prices loaded
                // together, which is only true here, after all products fetched.
                if let monthly = plans.first(where: { $0.period == .monthly }),
                   let annualIndex = plans.firstIndex(where: { $0.period == .annual }),
                   monthly.pricePerMonth > 0 {
                    let annualPricePerMonth = plans[annualIndex].pricePerMonth
                    let savings = (monthly.pricePerMonth - annualPricePerMonth) / monthly.pricePerMonth
                    let percent = Int((savings as NSDecimalNumber).doubleValue * 100)
                    if percent > 0 {
                        plans[annualIndex].savingsPercent = percent
                    }
                }

                return plans.isEmpty ? SubscriptionPlan.defaultPlans : plans
            } catch {
                // Fetch failed — return fallback display plans.
                // Purchases will still fail clearly since no cached product exists.
                return SubscriptionPlan.defaultPlans
            }
        }
    }

    var isPremiumUser: Bool {
        premiumState.isPremiumUser
    }

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

        case .userCancelled:
            throw StoreKitError.purchaseCancelled

        case .pending:
            throw StoreKitError.purchasePending

        @unknown default:
            throw StoreKitError.purchaseFailed
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
        if !premiumState.isPremiumUser {
            throw StoreKitError.noActiveSubscription
        }
    }

    func fetchPurchaseHistory() async -> [String] {
        var entries: [String] = []
        for await result in Transaction.all {
            switch result {
            case .verified(let transaction):
                let productID = transaction.productID
                let date = transaction.purchaseDate.formatted(date: .abbreviated, time: .shortened)
                var entry = "\(productID) — \(date)"
                if let exp = transaction.expirationDate {
                    entry += " (expires: \(exp.formatted(date: .abbreviated, time: .shortened)))"
                }
                if let rev = transaction.revocationDate {
                    entry += " (revoked: \(rev.formatted(date: .abbreviated, time: .shortened)))"
                }
                entries.append(entry)
            case .unverified:
                break
            }
        }
        return entries
    }

    func refreshEntitlements() async {
        var hasActive = false

        // 1. Check current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Only consider known products
                guard catalog.period(for: transaction.productID) != nil else { continue }

                // Active if not revoked and not expired
                let notRevoked = transaction.revocationDate == nil
                let notExpired = transaction.expirationDate.map { $0 > Date() } ?? true

                if notRevoked && notExpired {
                    hasActive = true
                }
            case .unverified:
                break
            }
        }

        // 2. Check subscription group status if configured
        if let groupID = catalog.subscriptionGroupID {
            do {
                let statuses = try await Product.SubscriptionInfo.status(for: groupID)
                for status in statuses {
                    switch status.state {
                    case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                        hasActive = true
                    case .expired, .revoked:
                        break
                    default:
                        break
                    }
                }
            } catch {
                // Subscription status check failed — rely on entitlement check above
            }
        }

        premiumState.isPremiumUser = hasActive
    }

    func isEligibleForIntroOffer(for period: SubscriptionPeriod) async -> Bool {
        guard let productID = catalog.productID(for: period) else { return false }
        let product: Product?
        if let cached = productsByID[productID] {
            product = cached
        } else {
            product = (try? await Product.products(for: [productID]))?.first
        }
        guard let product else { return false }
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    // MARK: - Transaction listener

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

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitError.receiptValidationFailed
        }
    }

    private static func planFromProduct(
        _ product: Product,
        period: SubscriptionPeriod,
        catalog: StoreKitProductCatalog
    ) -> SubscriptionPlan {
        let pricePerPeriod = product.price ?? .zero
        // Months per billing cycle for pricePerMonth normalization
        let months: Decimal
        switch period {
        case .annual:  months = 12
        case .monthly: months = 1
        case .weekly:  months = 12.0 / 52.0  // ~0.23 months per week
        }
        let pricePerMonth = pricePerPeriod / months

        let isAnnual = period == .annual
        let billingSummary: String? = {
            switch period {
            case .annual:  return "Billed annually"
            case .monthly: return "Billed monthly"
            case .weekly:  return "Billed weekly"
            }
        }()

        // Computed after all products load — see availablePlans. A lone
        // product (e.g. only the annual tier configured) leaves this nil,
        // which is honest; a hardcoded guess here was not.
        let savingsPercent: Int? = nil

        return SubscriptionPlan(
            id: period,
            displayName: product.displayName,
            pricePerMonth: NSDecimalNumber(decimal: pricePerMonth) as Decimal,
            pricePerPeriod: pricePerPeriod,
            period: period,
            savingsPercent: savingsPercent,
            isBestValue: isAnnual,
            subtitle: isAnnual ? "Best value option" : nil,
            productID: product.id,
            displayPrice: product.displayPrice,
            billingSummary: billingSummary,
            hasIntroductoryOffer: product.subscription?.introductoryOffer != nil,
            introOfferPeriodUnit: Self.introOfferPeriodUnit(from: product)
        )
    }

    /// Display sort order: annual (0) -> monthly (1) -> weekly (2).
    private static func periodSortOrder(_ period: SubscriptionPeriod) -> Int {
        switch period {
        case .annual:  0
        case .monthly: 1
        case .weekly:  2
        }
    }

    private static func introOfferPeriodUnit(from product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer else { return nil }
        let value = offer.period.value
        switch offer.period.unit {
        case .day:   return "\(value)-day"
        case .week:  return "\(value * 7)-day"
        case .month: return "\(value)-month"
        case .year:  return "\(value)-year"
        @unknown default: return nil
        }
    }
}
