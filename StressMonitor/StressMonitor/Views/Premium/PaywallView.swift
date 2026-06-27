import SwiftUI

/// Thin wrapper around `IAPPremiumView` that centralizes the StoreKit service
/// factory (removing the DEBUG/Release `makeStoreKitService()` duplication that
/// previously lived in DashboardView, SettingsView, and TrendsView).
///
/// Presented **full-screen from anywhere** via `PaywallController.present(reason:)`,
/// which drives the root `.fullScreenCover(item:)` (see `MainTabView`).
///
/// `reason` is captured for future per-reason copy / analytics; it does not
/// change layout today.
struct PaywallView: View {
    let reason: PaywallReason

    init(reason: PaywallReason = .general) {
        self.reason = reason
    }

    var body: some View {
        IAPPremiumView(storeKit: Self.makeStoreKitService(), premiumState: PremiumState.shared)
    }

    // MARK: - StoreKit factory (DEBUG vs Release)

    #if DEBUG
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        MockStoreKitService(premiumState: PremiumState.shared)
    }
    #else
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        StoreKitService(premiumState: PremiumState.shared)
    }
    #endif
}
