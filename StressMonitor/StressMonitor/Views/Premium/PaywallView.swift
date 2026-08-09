import SwiftUI

/// Thin wrapper around `IAPPremiumView`.
///
/// Presented **full-screen from anywhere** via `PaywallController.present(reason:)`,
/// which drives the root `.fullScreenCover(item:)` (see `MainTabView`).
///
/// The `StoreKitServiceProtocol` instance comes from the environment —
/// `StressMonitorApp` owns exactly one for the app's process lifetime, so
/// its `Transaction.updates` listener runs continuously instead of only
/// while this view happens to be on screen. This view must never construct
/// its own instance; that was the original bug.
///
/// `reason` is captured for future per-reason copy / analytics; it does not
/// change layout today.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.storeKitService) private var storeKitService

    init(reason: PaywallReason = .general) {
        self.reason = reason
    }

    var body: some View {
        IAPPremiumView(storeKit: storeKitService, premiumState: PremiumState.shared)
    }
}
