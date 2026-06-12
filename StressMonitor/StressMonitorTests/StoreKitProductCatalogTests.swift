import Foundation
import Testing
@testable import StressMonitor

@MainActor
struct StoreKitProductCatalogTests {

    // MARK: - Missing values

    @Test("Missing values produce empty allProductIDs")
    func missingValuesProduceEmptyIDs() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: nil,
            annualProductID: nil,
            subscriptionGroupID: nil
        )
        #expect(catalog.allProductIDs.isEmpty)
        #expect(catalog.monthlyProductID == nil)
        #expect(catalog.annualProductID == nil)
    }

    // MARK: - Empty strings

    @Test("Empty strings are ignored")
    func emptyStringsAreIgnored() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: "",
            annualProductID: "",
            subscriptionGroupID: ""
        )
        #expect(catalog.allProductIDs.isEmpty)
        #expect(catalog.monthlyProductID == nil)
        #expect(catalog.annualProductID == nil)
    }

    // MARK: - Placeholder values

    @Test("Placeholder build-setting values are ignored")
    func placeholderValuesAreIgnored() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: "$(STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID)",
            annualProductID: "$(STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID)",
            subscriptionGroupID: "$(STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID)"
        )
        #expect(catalog.allProductIDs.isEmpty)
    }

    // MARK: - Explicit values

    @Test("Explicit monthly/annual/group values are returned")
    func explicitValuesAreReturned() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: "com.example.app.premium.monthly",
            annualProductID: "com.example.app.premium.annual",
            subscriptionGroupID: "premium"
        )
        #expect(catalog.monthlyProductID == "com.example.app.premium.monthly")
        #expect(catalog.annualProductID == "com.example.app.premium.annual")
        #expect(catalog.subscriptionGroupID == "premium")
        #expect(catalog.allProductIDs.count == 2)
        #expect(catalog.allProductIDs.contains("com.example.app.premium.monthly"))
        #expect(catalog.allProductIDs.contains("com.example.app.premium.annual"))
    }

    // MARK: - productID(for:) mapping

    @Test("productID(for:) maps periods correctly")
    func productIDForPeriod() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: "monthly.id",
            annualProductID: "annual.id",
            subscriptionGroupID: nil
        )
        #expect(catalog.productID(for: .monthly) == "monthly.id")
        #expect(catalog.productID(for: .annual) == "annual.id")
    }

    // MARK: - period(for:) mapping

    @Test("period(for:) maps product IDs back to periods")
    func periodForProductID() {
        let catalog = StoreKitProductCatalog(
            monthlyProductID: "monthly.id",
            annualProductID: "annual.id",
            subscriptionGroupID: nil
        )
        #expect(catalog.period(for: "monthly.id") == .monthly)
        #expect(catalog.period(for: "annual.id") == .annual)
        #expect(catalog.period(for: "unknown.id") == nil)
    }

    // MARK: - Injectable sources

    @Test("Catalog resolves from injected environment dictionary")
    func resolvesFromInjectedEnvironment() {
        let catalog = StoreKitProductCatalog(
            bundle: Bundle.main,
            environment: [
                "STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID": "env.monthly",
                "STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID": "env.annual",
                "STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID": "env.group"
            ],
            defaults: nil
        )
        #expect(catalog.monthlyProductID == "env.monthly")
        #expect(catalog.annualProductID == "env.annual")
        #expect(catalog.subscriptionGroupID == "env.group")
    }

    @Test("Catalog resolves from injected UserDefaults")
    func resolvesFromInjectedDefaults() {
        let defaults = UserDefaults(suiteName: "StoreKitProductCatalogTests")!
        defaults.set("defaults.monthly", forKey: "storeKitPremiumMonthlyProductID")
        defaults.set("defaults.annual", forKey: "storeKitPremiumAnnualProductID")
        defaults.set("defaults.group", forKey: "storeKitPremiumSubscriptionGroupID")

        defer {
            defaults.removeSuite(named: "StoreKitProductCatalogTests")
        }

        let catalog = StoreKitProductCatalog(
            bundle: Bundle.main,
            environment: [:],
            defaults: defaults
        )
        #expect(catalog.monthlyProductID == "defaults.monthly")
        #expect(catalog.annualProductID == "defaults.annual")
        #expect(catalog.subscriptionGroupID == "defaults.group")
    }

    // MARK: - Bundle Info.plist takes priority over environment

    @Test("Bundle Info.plist key takes priority over environment")
    func bundlePriorityOverEnvironment() {
        // Since Bundle.main won't have the Info.plist keys in tests,
        // environment values should be used as fallback
        let catalog = StoreKitProductCatalog(
            bundle: Bundle.main,
            environment: [
                "STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID": "env.monthly"
            ],
            defaults: nil
        )
        #expect(catalog.monthlyProductID == "env.monthly")
    }
}
