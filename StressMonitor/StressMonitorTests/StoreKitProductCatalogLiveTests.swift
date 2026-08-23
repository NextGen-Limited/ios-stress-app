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

    @Test("Live catalog resolves the small credit-pack product ID")
    func liveCatalogResolvesSmallPack() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.packID(for: .small) == "com.stressmonitor.app.credits.small",
            "Small pack product ID missing from live catalog. Add STOREKIT_CREDITS_SMALL_PRODUCT_ID = com.stressmonitor.app.credits.small to StressMonitor/Info.plist."
        )
    }

    @Test("Live catalog resolves the large credit-pack product ID")
    func liveCatalogResolvesLargePack() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.packID(for: .large) == "com.stressmonitor.app.credits.large",
            "Large pack product ID missing from live catalog. Add STOREKIT_CREDITS_LARGE_PRODUCT_ID = com.stressmonitor.app.credits.large to StressMonitor/Info.plist."
        )
    }

    @Test("Resolved small pack product ID round-trips through pack(for:)")
    func liveSmallPackIDRoundTrips() {
        let catalog = StoreKitProductCatalog.live
        #expect(
            catalog.pack(for: "com.stressmonitor.app.credits.small") == .small,
            "pack(for:) does not recognize the small pack product ID. STOREKIT_CREDITS_SMALL_PRODUCT_ID must be present in StressMonitor/Info.plist."
        )
    }
}
