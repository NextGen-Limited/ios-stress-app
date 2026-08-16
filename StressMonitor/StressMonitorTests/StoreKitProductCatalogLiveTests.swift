import Foundation
import Testing
@testable import StressMonitor

// DISABLED: the contract this suite pins — INFOPLIST_KEY_STOREKIT_* build
// settings resolving through Bundle.main — does not hold. Xcode's generated
// Info.plist only emits KNOWN INFOPLIST_KEY_* settings; custom ones like
// INFOPLIST_KEY_STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID never reach the plist,
// so StoreKitProductCatalog.live resolves empty in every configuration.
// This is requirement IAP-01 (known open since the v1.0 audit: "zero
// product IDs resolve in any build configuration"). Product-ID resolution
// is owned by phase 02 plan 02-03; re-enable this suite there.
@Suite(.disabled("Live catalog resolves empty — custom INFOPLIST_KEY_* settings never reach the generated Info.plist (IAP-01)"))
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
