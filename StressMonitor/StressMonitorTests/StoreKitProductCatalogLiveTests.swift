import Foundation
import Testing
@testable import StressMonitor

@MainActor
struct StoreKitProductCatalogLiveTests {

    @Test("Live catalog resolves non-empty product IDs from build settings")
    func liveCatalogNonEmpty() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.allProductIDs.isEmpty == false,
            "StoreKitProductCatalog.live.allProductIDs is empty. Add INFOPLIST_KEY_STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID build settings to the app target in project.pbxproj."
        )
    }

    @Test("Live catalog contains the annual product ID")
    func liveCatalogContainsAnnual() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.allProductIDs.contains("com.stressmonitor.app.premium.annual"),
            "Annual product ID missing from live catalog. Add INFOPLIST_KEY_STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID = com.stressmonitor.app.premium.annual to the app target build settings."
        )
    }

    @Test("Live catalog resolves the subscription group ID")
    func liveCatalogResolvesGroupID() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.subscriptionGroupID == "SMPREMIUM01",
            "Subscription group ID missing or mismatched. Add INFOPLIST_KEY_STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID = SMPREMIUM01 to the app target build settings."
        )
    }
}
